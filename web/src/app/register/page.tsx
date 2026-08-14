"use client";

import Link from "next/link";
import { SubmitEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { register } from "@/lib/api";
import { getStoredToken, setStoredToken } from "@/lib/auth";

export default function RegisterPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    if (getStoredToken()) {
      router.replace("/dashboard");
    } else {
      // localStorage isn't available during SSR, so this can only be known post-mount.
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setChecking(false);
    }
  }, [router]);

  async function handleSubmit(e: SubmitEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      const { token } = await register(email.trim(), password);
      setStoredToken(token);
      router.replace("/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to register");
    } finally {
      setSubmitting(false);
    }
  }

  if (checking) return null;

  return (
    <main className="flex-1 flex items-center justify-center p-6">
      <div className="w-full max-w-sm">
        <h1 className="text-2xl font-semibold mb-6">Create your Nudge account</h1>
        <form onSubmit={handleSubmit} className="space-y-4">
          <input
            type="email"
            required
            autoFocus
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full border border-neutral-300 dark:border-neutral-700 rounded-md px-3 py-2 bg-transparent"
          />
          <input
            type="password"
            required
            minLength={8}
            placeholder="Password (min 8 characters)"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full border border-neutral-300 dark:border-neutral-700 rounded-md px-3 py-2 bg-transparent"
          />
          {error && <p className="text-sm text-red-600">{error}</p>}
          <button
            type="submit"
            disabled={submitting}
            className="w-full bg-neutral-900 dark:bg-white dark:text-neutral-900 text-white rounded-lg py-2.5 font-medium disabled:opacity-50"
          >
            {submitting ? "Creating account..." : "Create account"}
          </button>
        </form>
        <p className="text-sm text-neutral-500 mt-4">
          Already have an account?{" "}
          <Link href="/" className="underline">
            Sign in
          </Link>
        </p>
      </div>
    </main>
  );
}
