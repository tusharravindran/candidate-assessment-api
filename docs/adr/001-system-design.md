# ADR 001: Candidate Assessment Platform System Design

## Status

Accepted

## Context

The platform must support:

- Multiple organizations with strict isolation
- Recruiter-facing assessment management and dashboard analytics
- Candidate-facing timed assessment sessions
- Async result processing
- Search-heavy recruiter workflows
- Deployment on low-cost Render infrastructure

## Decision

### Rails API + Next.js

Rails API was chosen for the backend because the domain is workflow-heavy, relational, and policy-driven. Active Record, Sidekiq, Devise JWT, and Pundit reduce the amount of custom plumbing needed for invitations, sessions, scoring, and authorization.

Next.js was chosen for the frontend because the product has two clear surfaces:

- recruiter dashboards and review tools
- candidate invitation and test-taking flows

This split keeps the browser UI independently deployable from the backend repository and allows each service to evolve on its own deployment cadence.

### Row-Level Multi-Tenancy

Multi-tenancy uses a shared Postgres database with `organization_id` row-level scoping.

Why this approach:

- Free-tier and early-stage infrastructure stays simple
- One schema is easier to migrate and operate than per-tenant databases
- Query plans remain predictable
- It maps directly to recruiter session-derived tenant context

Enforcement layers:

- model-level scoping via `TenantScoped`
- controller-level `Current` tenant context
- policy-level authorization through Pundit
- explicit query scoping for reads
- background job tenant restoration using `organization_id`
- Elasticsearch `tenant_id` filters in every search query

### Sidekiq for Result Processing

Result processing is asynchronous because finalization touches multiple subsystems:

- answer scoring
- free-text review state
- result aggregation
- dashboard refresh hooks
- Elasticsearch indexing

Sidekiq was chosen because it is well-understood in Rails deployments, integrates directly with Active Job, and works cleanly with Redis-backed queueing.

### Elasticsearch for Dashboard Search

Recruiter result browsing requires:

- fuzzy text search on candidate identity fields
- filter combinations
- facet buckets
- sorting
- pagination

Those are significantly better served by Elasticsearch than ad hoc SQL `LIKE` queries. The API still includes a SQL fallback for resilience, but Elasticsearch is the intended search engine for production dashboard use.

### State Machine Decisions

Assessments use a formal lifecycle:

- `draft`
- `published`
- `archived`

This prevents mutation of live tests and makes recruiter behavior predictable.

Candidate sessions use a separate lifecycle:

- `not_started`
- `in_progress`
- `submitted`
- `auto_submitted`
- `expired`

That split keeps assessment authoring rules independent from candidate execution rules.

## Failure Recovery and Idempotency

### Candidate Submission

The final submit endpoint is idempotent:

- repeated submits return the accepted session state
- timeout-triggered submits converge into the same finalization pipeline
- autosave persists answers before timeout checks so late answers are not dropped

### Background Jobs

Each job restores tenant context from `organization_id` before touching scoped records. Finalization fans out into smaller jobs so retries happen at narrow failure boundaries instead of replaying the entire workflow blindly.

### Search Indexing

Index creation and reindexing are explicit tasks. Bulk reindexing is batched to reduce memory use and avoid large payload spikes on free-tier infrastructure.

## Security Boundaries

- Recruiter tenant context comes from the authenticated recruiter session only
- Candidate access is token-bound and invitation-scoped
- Invitation links are single-use and cannot reopen a completed attempt
- Published assessments are immutable
- Free-text manual review remains admin-gated through policy checks
- Elasticsearch queries always include tenant filters

## Caching Strategy

- Redis is used primarily for Sidekiq and lightweight cache entries
- Dashboard refresh jobs can warm cache keys without adding heavy cron work
- Current implementation avoids aggressive caching to keep behavior transparent during early iteration

At higher volume, cache candidates include:

- dashboard summary payloads
- assessment list aggregates
- recent result drill-down payloads

## What Changes at 10x Scale

At roughly 10x traffic and tenant count, the likely bottlenecks become:

- aggregate-heavy assessment list queries
- high-cardinality result search and indexing
- Sidekiq queue latency during submission bursts
- PostgreSQL contention on result and answer writes

Expected changes:

- move more dashboard aggregates into materialized rollups
- increase Sidekiq workers and isolate critical queues
- tune Elasticsearch index mappings and shard counts
- add read replicas for dashboard-heavy reads
- move from free-tier Redis and Postgres to persistent paid plans

## Horizontal Scaling Path

- scale Rails API web horizontally behind Render web services
- scale Sidekiq workers independently by queue pressure
- keep frontend stateless so it can scale separately
- move Elasticsearch to a larger hosted cluster when search volume grows

Because tenant isolation is row-scoped instead of schema-scoped, horizontal scaling does not require per-tenant service routing.

## Consequences

### Positive

- Strong early-stage ergonomics
- Clear separation of recruiter and candidate concerns
- Low operational overhead for a multi-tenant product
- Search and async processing patterns are already in place for growth

### Tradeoffs

- Shared-database tenancy requires disciplined scoping everywhere
- Free Render constraints are not enough for a true background worker, so the worker uses the smallest paid plan
- Assessment list metrics can become query-heavy without later aggregation work
