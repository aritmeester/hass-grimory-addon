# Changelog

## 0.1.3

- Added upstream MariaDB JDBC URL parameters in startup (`createDatabaseIfNotExist=true` plus timezone/session settings) so manual database creation is no longer required.

## 0.1.2

- Fixed startup permissions by mapping `/app/data` to the writable Home Assistant data volume (`/data`).

## 0.1.1

- Fixed the upstream Grimmory container source tag in the add-on Docker build.

## 0.1.0

- Rebuilt the repository as a Home Assistant-native Grimmory host.
- Replaced the placeholder API/worker model with the upstream Grimmory payload on top of the Home Assistant base image.
- Added S6 services for MariaDB readiness and Grimmory startup.
- Added MariaDB service discovery through Home Assistant.
- Added automatic Grimmory recovery restart when MariaDB becomes available after a DB-less startup.
- Added `/media` bookdrop and `/share` books-folder wiring.
- Added Grimmory-native options for timezone, disk type, and API docs.
- Added a custom AppArmor profile.
- Added Dutch option translations (`translations/nl.yaml`).
- Added ingress, watchdog, documentation, and recorded architecture decisions.
