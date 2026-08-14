import { Router } from "express";
import pool from "../db";
import { requireAuth, type AuthedRequest } from "../auth";

const router = Router();
router.use(requireAuth);

function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

function isValidISODate(value: unknown): value is string {
  return typeof value === "string" && !Number.isNaN(Date.parse(value));
}

interface NudgeRow {
  id: string;
  title: string;
  message: string;
  scheduled_at: Date;
  sent: boolean;
  created_at: Date;
}

function toNudgeJson(row: NudgeRow) {
  return {
    id: row.id,
    title: row.title,
    message: row.message,
    scheduledAt: new Date(row.scheduled_at).toISOString(),
    sent: row.sent,
    createdAt: new Date(row.created_at).toISOString(),
  };
}

router.get("/", async (req: AuthedRequest, res) => {
  const result = await pool.query<NudgeRow>(
    "SELECT id, title, message, scheduled_at, sent, created_at FROM nudges WHERE user_id = $1 ORDER BY scheduled_at ASC",
    [req.userId]
  );
  res.json(result.rows.map(toNudgeJson));
});

router.post("/", async (req: AuthedRequest, res) => {
  const { title, message, scheduledAt } = (req.body ?? {}) as Record<string, unknown>;

  if (!isNonEmptyString(title)) {
    res.status(400).json({ error: "title is required" });
    return;
  }
  if (!isNonEmptyString(message)) {
    res.status(400).json({ error: "message is required" });
    return;
  }
  if (!isValidISODate(scheduledAt)) {
    res.status(400).json({ error: "scheduledAt must be a valid ISO 8601 date string" });
    return;
  }

  const result = await pool.query<NudgeRow>(
    "INSERT INTO nudges (user_id, title, message, scheduled_at) VALUES ($1, $2, $3, $4) RETURNING id, title, message, scheduled_at, sent, created_at",
    [req.userId, title, message, new Date(scheduledAt).toISOString()]
  );
  res.status(201).json(toNudgeJson(result.rows[0]));
});

router.put("/:id", async (req: AuthedRequest, res) => {
  const { id } = req.params;
  const { title, message, scheduledAt } = (req.body ?? {}) as Record<string, unknown>;

  if (title !== undefined && !isNonEmptyString(title)) {
    res.status(400).json({ error: "title must be a non-empty string" });
    return;
  }
  if (message !== undefined && !isNonEmptyString(message)) {
    res.status(400).json({ error: "message must be a non-empty string" });
    return;
  }
  if (scheduledAt !== undefined && !isValidISODate(scheduledAt)) {
    res.status(400).json({ error: "scheduledAt must be a valid ISO 8601 date string" });
    return;
  }

  const existing = await pool.query<NudgeRow>("SELECT * FROM nudges WHERE id = $1 AND user_id = $2", [
    id,
    req.userId,
  ]);
  const current = existing.rows[0];
  if (!current) {
    res.status(404).json({ error: "Nudge not found" });
    return;
  }

  const result = await pool.query<NudgeRow>(
    "UPDATE nudges SET title = $1, message = $2, scheduled_at = $3 WHERE id = $4 RETURNING id, title, message, scheduled_at, sent, created_at",
    [
      isNonEmptyString(title) ? title : current.title,
      isNonEmptyString(message) ? message : current.message,
      isValidISODate(scheduledAt) ? new Date(scheduledAt).toISOString() : current.scheduled_at,
      id,
    ]
  );
  res.json(toNudgeJson(result.rows[0]));
});

router.delete("/:id", async (req: AuthedRequest, res) => {
  const { id } = req.params;
  const result = await pool.query("DELETE FROM nudges WHERE id = $1 AND user_id = $2", [id, req.userId]);
  if (result.rowCount === 0) {
    res.status(404).json({ error: "Nudge not found" });
    return;
  }
  res.status(204).send();
});

export default router;
