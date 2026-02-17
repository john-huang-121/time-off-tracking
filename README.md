# README

### Setup instructions

#### Prerequisites

- Ruby (recommended: 3.4.x)
- Rails (recommended: 8.x)
- PostgreSQL
- Redis (for Sidekiq)

#### 1) Install dependencies

```bash
bundle install
```

#### 2) Configure environment variables

Set these in your shell or a .env file:

```
POSTGRES_PASSWORD=your_postgres_password
REDIS_URL=redis://localhost:6379/0
```

#### 3) Create + migrate + seed the database

```bash
bin/rails db:create db:migrate db:seed
```

#### 4) Run the app

Terminal 1:

```bash
bin/rails s
```

Terminal 2:

```bash
sudo service redis-server start
bundle exec sidekiq -C config/sidekiq.yml
```

#### 5) Useful URLs

App: http://localhost:3000
Dashboard: http://localhost:3000/dashboard
Sidekiq UI (admin-only): http://localhost:3000/sidekiq
Swagger / Rswag UI: http://localhost:3000/api-docs

To use swagger endpoints first signup/login a user account through normal route to have a session. Then in the same browser you can use `api-docs` to try out endpoints.

#### 6) Tests

```bash
bundle exec rspec
```

#### Where AI-assisted coding was most useful

Rails conventions and velocity: quickly iterating on controllers, routes, mailers, and policies (Devise + Pundit).
Debugging: identifying common causes for issues (enum backing columns, Devise test mapping, ActiveJob vs Sidekiq testing, Rswag server config).
Test scaffolding: generating baseline RSpec + FactoryBot patterns and improving assertions to be less brittle.
Architecture tradeoffs: deciding what belongs in models vs services vs jobs given MVP time constraints.

#### Trade-offs due to time constraints

- Enum-based roles vs a roles table
  - Chose enum roles (employee/manager/admin) because roles aren’t expected to change frequently.
  - A role table is more flexible but adds UI/admin complexity and more moving parts.
- Rails views + RESTful endpoints vs api/v1 integration endpoints
  - Built a functional web app with views and standard RESTful controllers.
  - Requirements leaned toward a working UI over an integration-first API surface.
- Mailer + Sidekiq as proof-of-concept
  - Implemented a mailer and a background job pattern to demonstrate async capability.
  - Did not fully expand the full notification suite (reminders/escalations/digests) due to time.
- Local dev vs Dockerized environment
  - Stayed local to avoid Docker networking/config friction and speed up iteration.
  - Docker would improve repeatability but increases setup/debug overhead.
- Unlimited PTO placeholder vs accrued balances
  - Chose a simple “unlimited PTO” approach because accrual rules weren’t specified.
  - A real balance system needs policy decisions (accrual rate, carryover, caps, expiration, proration).

#### Future improvements

- Dockerize the app
  - Add docker-compose for Rails + Postgres + Redis to simplify onboarding and multi-device dev.
- More JSON and JSON:API compatibility
  - Add versioned endpoints (/api/v1/...) and consistent payload schemas for integrations.
- Token-based auth for JSON usage
  - Implement devise-jwt for API consumers while keeping session auth for the web UI.
- Expand background jobs
  - Accrual/expiration of PTO at intervals
  - Pending approval reminders + escalation to admins/HR
  - Upcoming time-off reminders + return-to-work nudges
  - Weekly manager digest / monthly summaries
- Introduce real PTO balance
  - Add accrual policy model + usage ledger for auditable balances.
- Role table (if requirements change)
  - Move from enum to role records + assignments if roles become configurable or org-specific.
- UX + hardening
  - Improve dashboard review list display (show requester info correctly)
  - Enhance status badges and action buttons
  - Add overlap validation, limits, and stricter workflow rules
  - Reduce brittle HTML assertions in request specs (prefer key selectors or JSON responses for API specs)
