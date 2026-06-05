# Grimmory Add-on Testing Guide

This checklist validates runtime behavior for the Home Assistant Grimmory add-on.

## Scope

This guide covers:

- Basic startup
- Ingress and watchdog behavior
- MariaDB startup ordering (including DB-late recovery)
- Mount path behavior for `/media` and `/share`
- AppArmor regressions

## Preconditions

- Home Assistant with Supervisor is running.
- The MariaDB add-on is installed.
- This repository is added as an add-on repository.
- Grimmory add-on is installed but not yet assumed to be healthy.

## Test 1: Baseline boot with MariaDB already running

1. Start MariaDB add-on.
2. Confirm MariaDB health in Home Assistant.
3. Start Grimmory add-on.
4. Open Grimmory add-on logs.

Expected result:

- Grimmory process starts without crash loop.
- Logs include startup context (bookdrop, books path, timezone, disk type).
- Logs indicate database settings were resolved.
- Ingress opens and the Grimmory UI loads.

Fail indicators:

- Add-on repeatedly restarts.
- Ingress page does not load.
- No DB settings line when MariaDB is known healthy.

## Test 2: Soft startup when MariaDB is unavailable

1. Stop MariaDB add-on.
2. Start Grimmory add-on.
3. Observe Grimmory logs.

Expected result:

- Grimmory still starts (no hard failure).
- Logs warn about DB-less startup.
- Add-on remains running while DB is down.

Fail indicators:

- Grimmory exits immediately because DB is unavailable.
- Supervisor marks add-on failed during startup.

## Test 3: Post-start DB recovery restart

1. Leave Grimmory running from Test 2.
2. Start MariaDB add-on.
3. Watch Grimmory and dbcheck logs.

Expected result:

- `dbcheck` detects MariaDB readiness.
- A one-time Grimmory restart is requested.
- Grimmory relaunches and logs DB settings as resolved.
- No repeated restart loop occurs.

Fail indicators:

- No recovery restart after DB becomes healthy.
- Continuous restart loop once DB is healthy.

## Test 4: Ingress and watchdog behavior

1. With Grimmory running, open Web UI from add-on page.
2. Verify UI serves through ingress.
3. Keep Grimmory running for several minutes.

Expected result:

- Ingress is functional.
- Watchdog endpoint remains healthy.
- Supervisor does not restart add-on unexpectedly.

Fail indicators:

- Ingress fails while container is up.
- Frequent watchdog-triggered restarts.

## Test 5: Path and mount validation

1. Confirm configured defaults:
   - `bookdrop_folder: grimmory/bookdrop`
   - `books_folder: grimmory/books`
2. Place sample files in Home Assistant media path under `grimmory/bookdrop`.
3. Confirm Grimmory can read/write expected paths.

Expected result:

- `/media/grimmory/bookdrop` behaves as drop target.
- `/share/grimmory/books` is accessible to Grimmory.
- No permission errors in logs.

Fail indicators:

- File access denied on `/media` or `/share`.
- Path mismatch between config and runtime logs.

## Test 6: Option behavior checks

### 6a. `disk_type`

1. Set `disk_type: NETWORK` and restart Grimmory.
2. Verify app behavior aligns with network-storage mode expectations.

Expected result:

- Grimmory runs with `DISK_TYPE=NETWORK`.
- Network-safe behavior is applied where relevant.

### 6b. `api_docs_enabled`

1. Set `api_docs_enabled: true` and restart Grimmory.
2. Test API docs endpoints.

Expected result:

- API docs endpoints are available.

## Test 7: AppArmor verification

1. Start Grimmory with current AppArmor profile.
2. Use core Grimmory flows (UI, scan/import path, DB access).
3. If errors occur, inspect host audit logs for AppArmor denies.

Expected result:

- No blocking AppArmor denials for normal operation.

Fail indicators:

- Denied file/exec access for required runtime paths.

## Suggested pass criteria

- Tests 1 through 4 pass fully.
- No critical AppArmor denial remains unresolved.
- DB recovery restart happens at most once per DB-less startup event.
- Add-on remains stable for at least one extended run period after recovery.

## Known environment dependency

These checks require an actual Home Assistant Supervisor runtime and cannot be fully validated by static code inspection alone.
