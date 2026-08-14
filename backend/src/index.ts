import "dotenv/config";
import cors from "cors";
import express, { NextFunction, Request, Response } from "express";
import { initSchema } from "./db";
import authRouter from "./routes/auth";
import nudgesRouter from "./routes/nudges";

const app = express();
const port = Number(process.env.PORT ?? 4000);

app.use(cors({ origin: process.env.CORS_ORIGIN ?? "*" }));
app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.json({ status: "ok" });
});

app.use("/api/auth", authRouter);
app.use("/api/nudges", nudgesRouter);

app.use((_req, res) => {
  res.status(404).json({ error: "Not found" });
});

app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  console.error(err);
  res.status(500).json({ error: "Internal server error" });
});

async function start(): Promise<void> {
  await initSchema();
  app.listen(port, () => {
    console.log(`nudge-backend listening on port ${port}`);
  });
}

start().catch((err) => {
  console.error("Failed to start server", err);
  process.exit(1);
});
