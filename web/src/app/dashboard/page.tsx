"use client";

import { SubmitEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createNudge, deleteNudge, listNudges, updateNudge } from "@/lib/api";
import { clearStoredToken, getStoredToken } from "@/lib/auth";
import type { Nudge } from "@/lib/types";

interface NudgeFormValues {
  title: string;
  message: string;
  scheduledAt: string;
}

const emptyForm: NudgeFormValues = { title: "", message: "", scheduledAt: "" };

function toDatetimeLocal(iso: string): string {
  const d = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export default function DashboardPage() {
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const [nudges, setNudges] = useState<Nudge[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<NudgeFormValues>(emptyForm);
  const [creating, setCreating] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editForm, setEditForm] = useState<NudgeFormValues>(emptyForm);

  useEffect(() => {
    if (!getStoredToken()) {
      router.replace("/");
      return;
    }
    // localStorage isn't available during SSR, so this can only be known post-mount.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setReady(true);
  }, [router]);

  useEffect(() => {
    if (!ready) return;
    refresh();
  }, [ready]);

  async function refresh() {
    setLoading(true);
    setError(null);
    try {
      setNudges(await listNudges());
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load nudges");
    } finally {
      setLoading(false);
    }
  }

  async function handleCreate(e: SubmitEvent) {
    e.preventDefault();
    setCreating(true);
    setError(null);
    try {
      await createNudge({
        title: form.title.trim(),
        message: form.message.trim(),
        scheduledAt: new Date(form.scheduledAt).toISOString(),
      });
      setForm(emptyForm);
      await refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to create nudge");
    } finally {
      setCreating(false);
    }
  }

  function startEdit(nudge: Nudge) {
    setEditingId(nudge.id);
    setEditForm({
      title: nudge.title,
      message: nudge.message,
      scheduledAt: toDatetimeLocal(nudge.scheduledAt),
    });
  }

  async function handleUpdate(e: SubmitEvent, id: string) {
    e.preventDefault();
    setError(null);
    try {
      await updateNudge(id, {
        title: editForm.title.trim(),
        message: editForm.message.trim(),
        scheduledAt: new Date(editForm.scheduledAt).toISOString(),
      });
      setEditingId(null);
      await refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to update nudge");
    }
  }

  async function handleDelete(id: string) {
    setError(null);
    try {
      await deleteNudge(id);
      await refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to delete nudge");
    }
  }

  function handleSignOut() {
    clearStoredToken();
    router.replace("/");
  }

  if (!ready) return null;

  return (
    <main className="flex-1 max-w-2xl mx-auto w-full p-6 space-y-8">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Nudges</h1>
        <button onClick={handleSignOut} className="text-sm text-neutral-500 hover:underline">
          Sign out
        </button>
      </div>

      <form
        onSubmit={handleCreate}
        className="space-y-3 border border-neutral-200 dark:border-neutral-800 rounded-lg p-4"
      >
        <h2 className="font-medium">New nudge</h2>
        <input
          type="text"
          required
          placeholder="Title"
          value={form.title}
          onChange={(e) => setForm({ ...form, title: e.target.value })}
          className="w-full border border-neutral-300 dark:border-neutral-700 rounded-md px-3 py-2 bg-transparent"
        />
        <textarea
          required
          placeholder="Message"
          rows={2}
          value={form.message}
          onChange={(e) => setForm({ ...form, message: e.target.value })}
          className="w-full border border-neutral-300 dark:border-neutral-700 rounded-md px-3 py-2 bg-transparent"
        />
        <input
          type="datetime-local"
          required
          value={form.scheduledAt}
          onChange={(e) => setForm({ ...form, scheduledAt: e.target.value })}
          className="w-full border border-neutral-300 dark:border-neutral-700 rounded-md px-3 py-2 bg-transparent"
        />
        <button
          type="submit"
          disabled={creating}
          className="bg-neutral-900 dark:bg-white dark:text-neutral-900 text-white rounded-md px-4 py-2 text-sm font-medium disabled:opacity-50"
        >
          {creating ? "Adding..." : "Add nudge"}
        </button>
      </form>

      {error && <p className="text-sm text-red-600">{error}</p>}

      <div className="space-y-3">
        {loading && <p className="text-sm text-neutral-500">Loading...</p>}
        {!loading && nudges.length === 0 && (
          <p className="text-sm text-neutral-500">No nudges yet.</p>
        )}
        {nudges.map((nudge) =>
          editingId === nudge.id ? (
            <form
              key={nudge.id}
              onSubmit={(e) => handleUpdate(e, nudge.id)}
              className="space-y-3 border border-neutral-200 dark:border-neutral-800 rounded-lg p-4"
            >
              <input
                type="text"
                required
                value={editForm.title}
                onChange={(e) => setEditForm({ ...editForm, title: e.target.value })}
                className="w-full border border-neutral-300 dark:border-neutral-700 rounded-md px-3 py-2 bg-transparent"
              />
              <textarea
                required
                rows={2}
                value={editForm.message}
                onChange={(e) => setEditForm({ ...editForm, message: e.target.value })}
                className="w-full border border-neutral-300 dark:border-neutral-700 rounded-md px-3 py-2 bg-transparent"
              />
              <input
                type="datetime-local"
                required
                value={editForm.scheduledAt}
                onChange={(e) => setEditForm({ ...editForm, scheduledAt: e.target.value })}
                className="w-full border border-neutral-300 dark:border-neutral-700 rounded-md px-3 py-2 bg-transparent"
              />
              <div className="flex gap-3">
                <button
                  type="submit"
                  className="bg-neutral-900 dark:bg-white dark:text-neutral-900 text-white rounded-md px-4 py-2 text-sm font-medium"
                >
                  Save
                </button>
                <button
                  type="button"
                  onClick={() => setEditingId(null)}
                  className="text-sm text-neutral-500"
                >
                  Cancel
                </button>
              </div>
            </form>
          ) : (
            <div
              key={nudge.id}
              className="border border-neutral-200 dark:border-neutral-800 rounded-lg p-4"
            >
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="font-medium">{nudge.title}</p>
                  <p className="text-sm text-neutral-600 dark:text-neutral-400">{nudge.message}</p>
                  <p className="text-xs text-neutral-400 mt-1">
                    {new Date(nudge.scheduledAt).toLocaleString()} · {nudge.sent ? "Sent" : "Pending"}
                  </p>
                </div>
                <div className="flex gap-3 shrink-0">
                  <button onClick={() => startEdit(nudge)} className="text-sm text-neutral-500 hover:underline">
                    Edit
                  </button>
                  <button onClick={() => handleDelete(nudge.id)} className="text-sm text-red-600 hover:underline">
                    Delete
                  </button>
                </div>
              </div>
            </div>
          )
        )}
      </div>
    </main>
  );
}
