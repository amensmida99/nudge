# nudge

Save anything. Deal with it when it matters.

A simple reminders app: Express + Postgres backend, Next.js web dashboard,
both running as containers on EKS. Email/password accounts, JWT auth.

- [`/infra`](infra) — Terraform: EKS cluster + ECR repositories
- [`/k8s`](k8s) — Kubernetes manifests: Postgres, backend, web
- [`/backend`](backend) — Express API (Node 20, TypeScript)
- [`/web`](web) — Next.js dashboard (App Router, TypeScript, Tailwind)
- `/ios` — existing iOS app (not part of this stack yet)

## Quickstart

```bash
cd infra && terraform init && terraform apply   # EKS + ECR
cd ../k8s                                       # build/push images, create secrets, apply manifests
```

See `/infra/README.md` and `/k8s/README.md` for the full sequence, and
`/backend/README.md` / `/web/README.md` for local development without a
cluster.
