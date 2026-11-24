# NeoLA common test database

A minimal, independently deployed PostgreSQL 16 server for testing all NeoLA apps.
One server, three separate databases: `authguard`, `mmms`, `neola_subscriptions`.
Storage and frontends do not connect directly to PostgreSQL.

## Configure once

```sh
[ -f .env ] || cp .env.example .env
```

Set `POSTGRES_PASSWORD` in `.env`. The database role defaults to `postgres`.
This password is for database connections, not the ERP/Console login password.
Keep `.env` private; commit only `.env.example`.

## Start

```sh
docker compose up -d --wait
```

List databases:

```sh
docker compose exec postgres sh -c 'psql -U "$POSTGRES_USER" -d postgres -c "\l"'
```

Listens on `0.0.0.0:5433` by default. App connection destination is the database
host's actual IP/DNS, not `0.0.0.0`. No shared Docker network or custom image is
needed. Allow port 5433 only from trusted test machines; do not publish it to the
internet. Set POSTGRES_PORT if you deliberately choose a different host port.

## Connect test APIs

Put these values in the test API's `.env.container`:

```dotenv
DB_HOST=YOUR_TEST_DATABASE_SERVER_IP
DB_PORT=5433
DB_USER=postgres
DB_PASSWORD=YOUR_TEST_DATABASE_PASSWORD
DB_SSL=false
```

IAM: `DB_NAME=authguard`.
MMMS: `MMMS_DB_NAME=mmms`.
Subscription API: `CONTROL_DB_NAME=neola_subscriptions`.

Set API destinations such as IAM_API_URL and CONTROL_API_URL to the appropriate
server IP and published port, separately from database settings. Every service
can listen on 0.0.0.0 while connecting to another server's actual address.
Customer release licensing requires HTTPS and provider-signed leases; never
substitute an unsigned local test profile for the signed release profile.

## Keep test and production data separate

The default volume is `neola-test-pgdata`; the default host port is 5433 to avoid
replacing an existing/restored PostgreSQL on 5432. If port 5433 is occupied,
choose another free port in .env and update test API DB_PORT to match.

Initialization creates empty databases only on the first empty-volume start.
It never resets accounts or populates app tables. Apply each API's migrations,
or restore existing database backups into these new test databases before
migrating to retain copied users/password hashes and records. Do not point this
test profile at a live customer/provider data volume. Changing POSTGRES_PASSWORD
does not change a password already stored in a volume.

Data survives normal restarts. Never use `down -v` or delete volumes to resolve
configuration problems. This shared test server is not a shared multi-customer
production database; each customer installation retains its own isolated data.

Fresh app accounts are explicit API-owned seeds, not PostgreSQL init scripts.
After migrations, configure each identity API's private `.env.seed` from
`seed.env.example`, then run this command in IAM and Subscription API:

```sh
docker compose --env-file .env.deploy -f compose.independent.yaml --profile maintenance run --rm --build seed
```

Restored databases keep their existing users and must not be bootstrapped again.
