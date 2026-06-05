# Grimmory Decisions

## 2026-06-04: Reset to a Home Assistant-native Grimmory host

Reason:
The previous repository shape was a generic API/worker prototype and did not
host the actual Grimmory application.

Decision:
- Remove the placeholder API, worker, and publishing workflows.
- Rebuild around the Home Assistant base image plus `config.yaml`,
  `Dockerfile`, S6 services under `etc/services.d`, `run.sh`, `README.md`,
  `DOCS.md`, `CHANGELOG.md`, and translations.

Consequence:
The repository now hosts the real Grimmory app inside Home Assistant with a
Supervisor-friendly service layout.

## 2026-06-04: MariaDB via Home Assistant service discovery

Reason:
Users should not need to duplicate DB host and credential details already known
by Home Assistant.

Decision:
- Depend on the `mysql` service exposed by the MariaDB add-on.
- Resolve host, port, username, and password through Bashio.
- Pass the resolved settings into Grimmory's `DATABASE_URL`,
  `DATABASE_USERNAME`, and `DATABASE_PASSWORD` variables.

Consequence:
The add-on is more aligned with Home Assistant while still using Grimmory's
native database contract.

## 2026-06-04: MariaDB as a soft startup dependency

Reason:
The add-on should not block boot just because the database add-on is still
starting.

Decision:
- Change the Supervisor service requirement from `mysql:need` to `mysql:want`.
- Start Grimmory immediately even if Supervisor has not yet published MariaDB
    service metadata.
- Export database settings whenever Supervisor metadata is available, even if the
    MariaDB server is still booting.
- Let Grimmory retry database connectivity in-app.

Consequence:
The add-on can boot independently of MariaDB startup timing, which is cleaner
for Home Assistant OS semantics and restarts.

## 2026-06-04: `/media` as the source of truth for the bookdrop

Reason:
Bookdrop files are user-managed content and belong in Home Assistant's media
area, not in `/data`.

Decision:
- Map `media` read/write.
- Mount the bookdrop under `/media/grimmory/bookdrop`.
- Mount Grimmory's library folder from `/share`.
- Reserve `/data` for internal state only.

Consequence:
Users can inspect and manage source files directly from the Home Assistant host.

## 2026-06-04: Phase 1 scope limited to hosting Grimmory correctly

Reason:
The add-on first needs a reliable contract for startup, storage, database
integration, and health monitoring before more customization.

Decision:
- Use the upstream Grimmory jar as the application runtime payload.
- Use `ghcr.io/hassio-addons/base` as the final image base.
- Add a `cont-init.d` bootstrap script for filesystem preparation.
- Add S6 services for MariaDB readiness and the Grimmory runner.
- Add a Home Assistant wrapper to adapt MariaDB discovery, storage mounts,
  ingress, and watchdog behavior.

Consequence:
The add-on now starts the real Grimmory app under Home Assistant, and future work
can focus on polish instead of bootstrapping.

## 2026-06-05: Expose focused Grimmory-native options

Reason:
The add-on should expose the most useful upstream Grimmory runtime settings
through Home Assistant without dumping the full environment surface into add-on
options.

Decision:
- Add `timezone` mapped to `TZ`.
- Add `disk_type` mapped to `DISK_TYPE`.
- Add `api_docs_enabled` mapped to `API_DOCS_ENABLED`.

Consequence:
Users can control storage mode, timezone handling, and API docs visibility from
the add-on UI while keeping the option set small and deliberate.

## 2026-06-05: Use dbcheck for post-start DB recovery

Reason:
If Grimmory starts before MariaDB service metadata is available, it may need a
clean restart later so database environment variables are present from process
start.

Decision:
- Mark DB-less Grimmory startups in `/run/grimmory`.
- Let `dbcheck` request a one-time supervised Grimmory restart when MariaDB
    becomes reachable afterward.

Consequence:
The add-on still boots softly, but it also has a recovery path that re-launches
Grimmory with proper DB settings once MariaDB is ready.

## 2026-06-05: Add a custom AppArmor profile

Reason:
The add-on should follow Home Assistant add-on security best practices and make
its filesystem and execution surface explicit.

Decision:
- Add `apparmor.txt` scoped to S6 startup, Bashio, Grimmory runtime binaries,
  Java, and the mapped `/data`, `/media`, and `/share` paths.

Consequence:
The add-on gets a tighter default security posture and a clearer basis for
runtime troubleshooting if additional permissions are needed later.
