# dev-pulse-api

A lightweight TypeScript API used to test deploying to OpenShift. It's an Express server backed by PostgreSQL (through Prisma) that tracks the name and status of services.

## Stack

- Node.js + TypeScript
- Express
- Prisma ORM with PostgreSQL
- Docker image on GitHub Container Registry
- Helm chart deployed to OpenShift by GitHub Actions

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
| `PORT`         | Port for the server to listen on (e.g. `8080`)   |

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

To check the production image before pushing:

```bash
docker build -t dev-pulse-api .
docker run --rm -p 8080:8080 --env-file .env dev-pulse-api
```

Inside the container, `localhost` is the container itself. If your database runs on your machine, use `host.docker.internal` in place of `localhost` in `DATABASE_URL`.

## API

| Endpoint                 | Description                                                                  |
| ------------------------ | ---------------------------------------------------------------------------- |
| `GET /api/v1/services`   | Lists services. Filter with `?id=1` or `?name=auth` (case-insensitive).       |
| `POST /api/v1/services`  | Creates a service from `{"name", "status"}`, or updates it if `id` is given.  |

```bash
curl -X POST http://localhost:8080/api/v1/services \
  -H "Content-Type: application/json" \
  -d '{"name": "auth-service", "status": "Healthy"}'
```

## Deployment to OpenShift

Every push to `main` runs `.github/workflows/deploy.yml` on GitHub Actions. It builds the Docker image, pushes it to `ghcr.io/gurungsh/dev-pulse-api`, and deploys the Helm chart in `chart/dev-pulse-api` (the app plus PostgreSQL) to the `gurungsh-dev` namespace. You can also start it by hand with **Run workflow** on the Actions tab.

Add these secrets to the GitHub repository:

| Secret              | Description                                 |
| ------------------- | ------------------------------------------- |
| `OPENSHIFT_SERVER`  | OpenShift API server URL                    |
| `OPENSHIFT_TOKEN`   | Token used to log in with `oc`              |
| `POSTGRES_USER`     | Database user name                          |
| `POSTGRES_PASSWORD` | Password for the database user              |

Use only letters and digits in `POSTGRES_USER` and `POSTGRES_PASSWORD`. The workflow passes them with `helm --set-string`, which fails on a comma, and the chart puts them in the `DATABASE_URL` connection string, where a space turns into `+`.

See [`chart/notes.md`](chart/notes.md) for the architecture diagram, the resources the chart creates, and how to work with a running release.
