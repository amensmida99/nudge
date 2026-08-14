# Nudge web

Next.js (App Router, TypeScript, Tailwind) dashboard for Nudge. Real
accounts — register with email/password, sign in, manage your nudges. The
JWT from the backend is stored in `localStorage` and sent as a bearer token
on every API call; there's no server-side session.

- `/` — sign in (redirects to `/dashboard` if already signed in)
- `/register` — create an account
- `/dashboard` — list, create, edit, delete nudges

Fully client-rendered — every request goes straight from the browser to the
backend API in `/backend`.

## Local development

### Prerequisites

- Node.js 20+
- The backend running locally (see `/backend/README.md`)

### Setup

```bash
npm install
cp .env.local.example .env.local
# edit .env.local if the backend isn't at http://localhost:4000
npm run dev
```

Open http://localhost:3000.

### Commands

```bash
npm run dev     # dev server
npm run build   # production build (.next/standalone)
npm start       # serve the last build
npm run lint    # eslint
npx tsc --noEmit  # typecheck
```

## Deployment

`next.config.ts` sets `output: "standalone"` so the Docker image only ships
a minimal self-contained server, not the full `node_modules`.
`NEXT_PUBLIC_API_BASE_URL` is inlined into the client bundle at **build**
time, so it has to be passed as a Docker build arg pointing at the backend's
address, not just set as a container env var at runtime:

```bash
docker build --build-arg NEXT_PUBLIC_API_BASE_URL=http://<backend-ip>:4000 -t nudge-web .
docker run -p 3000:3000 nudge-web
```

See `/k8s` for the manifests that run this on AKS, and `/infra` for the
Terraform that provisions the cluster and registry.
