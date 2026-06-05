# Home Assistant Add-on: Grimmory

_Home Assistant add-on that hosts Grimmory with a bookdrop under `/media` and a MariaDB backend._

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_addon_repository/?repository_url=https://github.com/aritmeester/hass-grimory-addon)

![Supports aarch64 Architecture](https://img.shields.io/badge/aarch64-yes-green.svg)
![Supports amd64 Architecture](https://img.shields.io/badge/amd64-yes-green.svg)

## About

This add-on launches the upstream Grimmory application image and adapts it to
the Home Assistant runtime. It connects to the MariaDB add-on via the Home
Assistant `mysql` service, exposes Grimmory over ingress, and maps the bookdrop
to a subfolder under `/media`.

The current local implementation is intended to host the real Grimmory service,
not a placeholder API.

## Features

- Uses the upstream Grimmory application container.
- Discovers MariaDB through the Home Assistant `mysql` service.
- Maps the bookdrop into `/media/grimmory/bookdrop`.
- Maps Grimmory's books folder into `/share/grimmory/books`.
- Uses `/data` for app state.

## Installation

See `DOCS.md` for setup and behavior.
