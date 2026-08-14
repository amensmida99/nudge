# Nudge backend

Express (Node 20, TypeScript) API for Nudge, backed by Postgres. Real
accounts this time — email + password, JWT bearer tokens, no device pairing.

## Endpoints

| Method | Route              | Auth | Description                                    |
|--------|--------------------|------|-------------------------------------------------|
| POST   | `/api/auth/register` | —  | `{ email, password }` → creates the account, returns `{ token }` |
| POST   | `/api/auth/login`    | —  | `{ email, password }` → returns `{ token }`     |
| GET    | `/api/nudges`         | Bearer | List the caller's nudges                    |
| POST   | `/api/nudges`         | Bearer | Create `{ title, message, scheduledAt }`    |
| PUT    | `/api/nudges/{id}`    | Bearer | Update `{ title?, message?, scheduledAt? }` |
| DELETE | `/api/nudges/{id}`    | Bearer | Delete a nudge                              |
| GET    | `/api/health`         | —  | Liveness check                                  |

Send the JWT from register/login as `Authorization: Bearer <token>` on every
`/api/nudges` request. Tokens expire after 7 days — there's no refresh flow,
just log in again.

## Local development

### Prerequisites

- Node.js 20
- A local Postgres instance:

```bash
docker run --name nudge-postgres -e POSTGRES_USER=nudge -e POSTGRES_PASSWORD=nudge \
  -e POSTGRES_DB=nudge -p 5432:5432 -d postgres:16-alpine
```

### Setup

```bash
npm install
cp .env.example .env
# edit .env if your Postgres/JWT_SECRET differs from the defaults
npm run dev
```

The backend creates its own tables (`users`, `nudges`) on startup if they
don't exist yet — no separate migration step.

### Commands

```bash
npm run dev     # tsx watch src/index.ts
npm run build   # tsc -> dist/
npm start       # node dist/index.js (run build first)
npm test        # tsc --noEmit
```

### Env vars

| Var | Description |
|-----|-------------|
| `PORT` | HTTP port (default `4000`) |
| `DATABASE_URL` | Postgres connection string |
| `JWT_SECRET` | Signing secret for auth tokens — required |
| `CORS_ORIGIN` | Allowed origin for the web app (default `*`) |

## Container

```bash
docker build -t nudge-backend .
docker run -p 4000:4000 --env-file .env nudge-backend
```

See `/k8s` for the Kubernetes manifests that run this (plus Postgres) on
AKS, and `/infra` for the Terraform that provisions the cluster and registry.

## Data model (Postgres)

- `users`: `id (uuid pk)`, `email (unique)`, `password_hash`, `created_at`
- `nudges`: `id (uuid pk)`, `user_id (fk -> users, cascade delete)`, `title`, `message`, `scheduled_at`, `sent`, `created_at`
