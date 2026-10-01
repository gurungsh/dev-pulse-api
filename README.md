# dev-pulse-api

A lightweight TypeScript API used to test deploying to OpenShift. It's an Express server backed by PostgreSQL (through Prisma) that tracks the name and status of services.

## Stack

- Node.js + TypeScript
- Express
- Prisma ORM with PostgreSQL
- GitHub Actions → OpenShift (Source-to-Image build)

## Getting started

### Prerequisites

- Node.js 20+
- A PostgreSQL database

### Setup

```bash
npm install                # also runs `prisma generate`
```

Set these environment variables:

| Variable       | Description                                      |
| -------------- | ------------------------------------------------ |
| `DATABASE_URL` | PostgreSQL connection string                     |
| `PORT`         | Port for the server to listen on (e.g. `3000`)   |

Create the `services` table by applying the migrations in `prisma/migrations`:

```bash
npx prisma migrate deploy
```

To change the schema, edit `prisma/schema.prisma`, run `npx prisma migrate dev --name <change>`, and commit the new migration folder. Deployed instances apply it on their next start.

### Run

```bash
npm run dev                # run with ts-node
npm run build && npm start # compile to dist/, apply pending migrations, and run
```

## API

### `GET /api/v1/services`

Lists services, ordered by id. Optional query parameters:

- `id`: return only the service with this id
- `name`: case-insensitive partial match on the name

```bash
curl "http://localhost:3000/api/v1/services?name=auth"
```

### `POST /api/v1/services`

Creates a service, or updates it if the body includes an `id`.

```bash
# create
curl -X POST http://localhost:3000/api/v1/services \
  -H "Content-Type: application/json" \
  -d '{"name": "auth-service", "status": "Healthy"}'

# update
curl -X POST http://localhost:3000/api/v1/services \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "name": "auth-service", "status": "Degraded"}'
```

A service looks like this:

```json
{ "id": 1, "name": "auth-service", "status": "Healthy", "updatedAt": "2026-09-30T12:00:00.000Z" }
```

## Deployment to OpenShift

`.github/workflows/deploy.yml` runs on every push to `main`. You can also start it by hand with **Run workflow** on the Actions tab. It sets up everything, including the database, so it works against an empty project:

1. Logs in to the OpenShift cluster with `oc`.
2. Deploys PostgreSQL from `openshift/postgres.yaml`, which defines a deployment, a service and a 1Gi persistent volume, with credentials in the `postgres-credentials` secret. Re-running it leaves the existing database and its data in place.
3. Creates or updates the `api-db-secret` secret with `DATABASE_URL` (pointing at the in-cluster `postgresql` service) and `PORT=3000`.
4. Creates the app with `oc new-app` from this repo (on the first run only), injects the secret as environment variables, starts a Source-to-Image build, and exposes a route.

When the app container starts, `npm start` runs `prisma migrate deploy`, which creates or updates the tables before the server starts listening.

Add these secrets to the GitHub repository:

| Secret              | Description                                                        |
| ------------------- | ------------------------------------------------------------------ |
| `OPENSHIFT_SERVER`  | OpenShift API server URL                                           |
| `OPENSHIFT_TOKEN`   | Token used to log in with `oc`                                     |
| `POSTGRES_PASSWORD` | Password for the database user. Use letters and digits only, since it is placed in a URL. |

The app deploys to the `gurungsh-dev` namespace. To find the public URL:

```bash
oc get route dev-pulse-api
```
