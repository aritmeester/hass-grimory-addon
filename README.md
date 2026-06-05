# Grimmory Home Assistant Repository

Local development repository for the Grimmory Home Assistant add-on.

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_addon_repository/?repository_url=https://github.com/aritmeester/hass-grimory-addon)

## Status

This repository now hosts the real Grimmory application inside Home Assistant
using a clean S6 add-on layout on top of the Home Assistant base image.
The installation button above targets the intended public repository URL and will
work after the repository is published.

## Included add-ons

- `grimmory`: Hosts Grimmory, runs a `dbcheck` S6 service, launches the main
  Grimmory service, mounts a `/media` bookdrop, mounts a books folder from
  `/share`, and connects to the MariaDB add-on through Home Assistant.

## Local design choices

- The image base is `ghcr.io/hassio-addons/base`.
- The runtime uses S6 services under `etc/services.d`.
- The upstream Grimmory jar is copied into the final image.
- User-supplied bookdrop files live in `/media`; the library folder is mounted
  from `/share`; persistent runtime state lives in `/data`.

## Next milestones

- Verify the first local boot against a real MariaDB add-on instance.
- Add icon and logo assets.
- Reintroduce CI once the runtime contract is stable.

See `grimmory/DOCS.md` for the add-on behavior and `docs/DECISIONS.md` for the
recorded architecture decisions.

Use `docs/TESTING.md` for the runtime validation checklist.
