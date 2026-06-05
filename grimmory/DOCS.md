# Home Assistant Add-on: Grimmory

## What this add-on does

Grimmory hosts the upstream Grimmory application inside Home Assistant with a
clean S6 service layout.

The add-on adapts Grimmory to Home Assistant conventions:

- A `cont-init.d` script prepares the filesystem layout before services start.
- A `dbcheck` S6 service monitors MariaDB readiness and can restart Grimmory
    once after DB recovery.
- The main `grimmory` S6 service launches the upstream Grimmory jar.
- The wrapper passes discovered MariaDB settings to Grimmory's
    `DATABASE_URL`, `DATABASE_USERNAME`, and `DATABASE_PASSWORD` variables.
- The wrapper passes selected Grimmory-native options such as `TZ`,
    `DISK_TYPE`, and `API_DOCS_ENABLED`.
- It mounts the bookdrop into `/share/grimmory/bookdrop`.
- It mounts Grimmory's books folder into `/share/grimmory/books`.
- It exposes Grimmory directly on port 6060.
- It declares a watchdog URL that points to Grimmory's health endpoint.

This makes the add-on a real Grimmory host instead of a placeholder wrapper.

## Requirements

- Home Assistant with Supervisor.
- The MariaDB add-on installed and running.
- A writable `share` mount for the library folder.

## Configuration

### Option: `bookdrop_folder`

Relative path under `/share` that Grimmory uses as its bookdrop.

Default: `grimmory/bookdrop`

Resulting container path:

`/share/grimmory/bookdrop`

### Option: `books_folder`

Relative path under `/share` that Grimmory uses as its books library folder.

Default: `grimmory/books`

Resulting container path:

`/share/grimmory/books`

### Option: `timezone`

Timezone passed through to Grimmory as `TZ`.

Default: `Etc/UTC`

### Option: `disk_type`

Storage mode passed through to Grimmory as `DISK_TYPE`.

Allowed values:

- `LOCAL`
- `NETWORK`

Default: `LOCAL`

Use `NETWORK` when Grimmory runs against network-mounted storage and should
avoid direct file operations like rename, move, or delete from the UI.

### Option: `api_docs_enabled`

Controls Grimmory API docs exposure via `API_DOCS_ENABLED`.

Default: `false`

When enabled, Grimmory exposes API docs and OpenAPI JSON endpoints.

## MariaDB usage

Grimmory does not ask for database host, port, username, or password in its
options. Those values are discovered via the Home Assistant service API.

On startup, the wrapper:

1. Queries the `mysql` service from Supervisor.
2. Exports Grimmory database settings whenever Supervisor provides MariaDB
    connection metadata.
3. Starts Grimmory immediately even if the `mysql` service metadata or the
    database process is not yet available.
4. Marks that startup as DB-less when no database settings are available.
5. Lets `dbcheck` request a supervised Grimmory restart once MariaDB becomes
    reachable later.
6. Launches the upstream Grimmory runtime on port 6060.

The upstream Grimmory container is responsible for starting the web app, reading
the database configuration, and exposing the UI.

## Storage model

- `/share/grimmory/bookdrop` is the auto-import bookdrop.
- `/share/grimmory/books` is the main library storage path.
- `/data` is persistent application state.

## Watchdog and access

The add-on uses Grimmory's health endpoint for watchdog monitoring:

`/api/v1/healthcheck`

The web UI is exposed over direct HTTP on port 6060.

## Runtime layout

- Base image: `ghcr.io/hassio-addons/base:14.3.1`
- Custom AppArmor profile: `apparmor.txt`
- S6 service: `dbcheck`
- S6 service: `grimmory`
- Launch wrapper: `/usr/local/bin/grimmory-run.sh`

## Translations

- English: `translations/en.yaml`
- Dutch: `translations/nl.yaml`

## Local development notes

This repository has not been published yet. The future public repository target
is `aritmeester/hass-grimory-addon`, but local implementation comes first.

Use `../docs/TESTING.md` for an end-to-end Home Assistant validation checklist.


See `../docs/DECISIONS.md` for the architecture record.
