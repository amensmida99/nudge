import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Self-contained server bundle for the Docker image (see Dockerfile).
  output: "standalone",
  // Don't auto-generate AGENTS.md/CLAUDE.md in this folder.
  agentRules: false,
};

export default nextConfig;
