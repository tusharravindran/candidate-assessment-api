# Candidate Assessment API

Multi-tenant Rails API backend for the Candidate Assessment Platform. Manages recruiter workflows, assessment lifecycle, candidate test sessions, asynchronous result scoring, and Elasticsearch-backed dashboard search. The companion frontend is at [candidate-assessment-web](https://github.com/tusharravindran/candidate-assessment-web).

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Browser                                                      │
│  ┌──────────────────┐    ┌──────────────────────────────┐   │
│  │  Recruiter UI     │    │  Candidate UI (token link)   │   │
│  │  (Next.js)        │    │  (Next.js)                   │   │
│  └────────┬─────────┘    └──────────────┬───────────────┘   │
└───────────┼──────────────────────────────┼───────────────────┘
            │ HTTPS + JWT                  │ HTTPS (no auth)
            ▼                              ▼
┌───────────────────────────────────────────────────────────────┐
│  Rails API  (candidate-assessment-api)                         │
│  Pundit · Devise JWT · AASM · Blueprinter · Pagy               │
└──────┬──────────────┬─────────────────┬──────────────────────┘
       │              │                  │
       ▼              ▼                  ▼
  PostgreSQL       Redis           Elasticsearch
  (row-level     (Sidekiq        (recruiter search,
  tenancy)        queues)         fuzzy + facets)
                    │
                    ▼
           Sidekiq Worker
           (scoring · indexing · aggregation)
```

## Features

| Concern | Implementation |
|---|---|
| Multi-tenancy | Shared DB · `organization_id` row-level scoping · `TenantScoped` concern · Pundit policies · job-time tenant restoration |
| Auth | Devise JWT (JTI revocation) |
| Assessment lifecycle | AASM state machine: `draft → published → archived` |
| Candidate sessions | Single-use token · server-side deadline · autosave · idempotent submit |
| Async processing | Sidekiq jobs: finalize → score → aggregate → index |
| Scoring | Auto-score multiple-choice/true-false · `pending_manual_review` for free-text |
| Search | Elasticsearch with fuzzy match, faceted filters, tenant-safe queries, SQL fallback |
| API contract | OpenAPI 3.0 spec at `docs/openapi.yaml` |

## Repository Structure

```
app/
  controllers/api/v1/   – assessments, invitations, candidate sessions, dashboard, search
  models/               – Assessment, CandidateSession, Invitation, Result, …
  models/concerns/      – TenantScoped (default scope + class-level for_tenant)
  policies/             – Pundit: AssessmentPolicy, ResultPolicy, …
  jobs/                 – FinalizeSubmission, ScoreObjective, AggregateResults, Index
  services/             – ScoringService, Elasticsearch::CandidateResultIndexer/Searcher
  serializers/          – Blueprinter serializers for all resources
config/
  routes.rb             – full API surface
  initializers/         – CORS, Devise, Elasticsearch, Sidekiq, Pagy
db/
  migrate/              – all migrations
  schema.rb             – current schema
  seeds.rb              – demo org + recruiter + assessment
docs/
  openapi.yaml          – OpenAPI 3.0 contract
  adr/001-system-design.md – Architecture Decision Record
```

## Local Setup

### Prerequisites

- Ruby 3.2.2 (`.ruby-version` set)
- Bundler
- Docker + Docker Compose (for infrastructure)

### One-command start (recommended)

Run the full stack from the **API repo** root:

```bash
cp .env.example .env          # edit secrets if needed
docker-compose up --build
```

This starts:

| Service | URL |
|---|---|
| Next.js frontend | http://localhost:3000 |
| Rails API | http://localhost:3001/api/v1 |
| PostgreSQL | localhost:5432 |
| Redis | localhost:6379 |
| Elasticsearch | http://localhost:9200 |

> The Compose file expects the frontend project at `../candidate-assessment-web`.

After the first boot, seed the database:

```bash
docker-compose exec backend bundle exec rails db:seed
```

Create the Elasticsearch index:

```bash
docker-compose exec backend bundle exec rails elasticsearch:create_indices
```

### Manual boot (without Docker)

```bash
bundle install
cp .env.example .env           # update DATABASE_URL, REDIS_URL, ELASTICSEARCH_URL
bundle exec rails db:create db:migrate db:seed
bundle exec rails elasticsearch:create_indices
bundle exec rails server -p 3001
bundle exec sidekiq -C config/sidekiq.yml   # separate terminal
```

## Environment Variables

| Variable | Required | Notes |
|---|---|---|
| `DATABASE_URL` | Yes | PostgreSQL connection string |
| `REDIS_URL` | Yes | Redis connection string |
| `ELASTICSEARCH_URL` | Yes | Elasticsearch-compatible endpoint |
| `DEVISE_JWT_SECRET_KEY` | Yes | Randomly generated secret |
| `SECRET_KEY_BASE` | Yes | Rails secret key |
| `FRONTEND_URL` | Yes | Comma-separated allowed CORS origins |
| `ELASTICSEARCH_INDEX_NAME` | No | Default: `candidate_results` |
| `SIDEKIQ_CONCURRENCY` | No | Default: `2` |
| `RAILS_MAX_THREADS` | No | Default: `5` |

## Elasticsearch Tasks

```bash
# Create index mapping
bundle exec rails elasticsearch:create_indices

# Reindex all existing results in batches of 100
bundle exec rails elasticsearch:reindex
```

## Seed Data

Running `db:seed` creates:

- **Organization:** Demo Corp
- **Recruiter:** `admin@demo.com` / `password123` (admin role)
- **Assessment:** "Ruby Developer Assessment" with 3 questions (multiple choice, true/false, free text)

## API Contract

Full OpenAPI 3.0 spec: [`docs/openapi.yaml`](docs/openapi.yaml)

Endpoint groups:

- `POST /auth/sign_up` · `POST /auth/sign_in` · `DELETE /auth/sign_out`
- `GET/PUT /organization`
- `GET/POST/PUT/DELETE /assessments` · `POST /assessments/:id/publish` · `POST /assessments/:id/archive`
- `GET/POST/PUT/DELETE /assessments/:assessment_id/questions`
- `GET/POST/DELETE /invitations`
- `GET /candidate/session/:token` · `POST /candidate/session/:token/start`
- `POST /candidate/session/:token/autosave` · `POST /candidate/session/:token/submit`
- `GET /dashboard/stats`
- `GET/PATCH /dashboard/results` (with manual review)
- `GET /search/candidates`

## Render Deployment

`render.yaml` defines:

| Service | Type | Plan |
|---|---|---|
| `candidate-assessment-api` | Ruby web | Free |
| `candidate-assessment-api-worker` | Ruby worker | Starter |
| `candidate-assessment-postgres` | PostgreSQL | Free |
| `candidate-assessment-redis` | Key Value | Free |

### Steps

1. Push this repo to GitHub (`tusharravindran/candidate-assessment-api`)
2. In [Render Dashboard](https://dashboard.render.com), create a new **Blueprint** from this repo
3. Provide environment values not auto-generated:
   - `FRONTEND_URL` — your deployed frontend URL
   - `ELASTICSEARCH_URL` — hosted Elasticsearch endpoint (e.g. Bonsai free tier)
4. Deploy the Blueprint
5. After first deploy, run via Render shell or one-off job:
   ```bash
   bundle exec rails db:seed
   bundle exec rails elasticsearch:create_indices
   ```
6. Deploy the frontend service from `candidate-assessment-web`

### Elasticsearch on Render

Render does not provide a managed Elasticsearch. Use a hosted provider:

- **Bonsai** — free tier available, compatible with ES 7.x client
- **Elastic Cloud** — 14-day free trial
- Set `ELASTICSEARCH_URL` to the provider's endpoint

## Architecture Decision Record

[`docs/adr/001-system-design.md`](docs/adr/001-system-design.md) covers:

- Why Rails API + Next.js
- Why row-level multi-tenancy over schema-per-tenant
- Why Sidekiq for async result processing
- Why Elasticsearch for dashboard search
- State machine design decisions
- Failure recovery and idempotency strategy
- What changes at 10x scale
