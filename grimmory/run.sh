#!/usr/bin/with-contenv bashio
set -euo pipefail

OPTIONS_PATH=/data/options.json
APP_VERSION=${APP_VERSION:-development}
APP_REVISION=${APP_REVISION:-unknown}
DEFAULT_BOOKDROP_FOLDER=grimmory/bookdrop
DEFAULT_BOOKS_FOLDER=grimmory/books
DEFAULT_USER_ID=1000
DEFAULT_GROUP_ID=1000
DEFAULT_TZ=Etc/UTC
DEFAULT_DISK_TYPE=LOCAL
DEFAULT_API_DOCS_ENABLED=false
NEEDS_DB_RESTART_FILE=/run/grimmory/needs-db-restart
DB_RESTART_TRIGGERED_FILE=/run/grimmory/db-restart-triggered

json_value() {
    jq -r "$1 // empty" "$OPTIONS_PATH"
}

get_mysql_service_info() {
    curl -sSL -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" http://supervisor/services/mysql 2>/dev/null || true
}

get_mysql_service_value() {
    local response=$1
    local field=$2

    printf '%s' "$response" | jq -r ".data.${field} // empty" 2>/dev/null || true
}

BOOKDROP_FOLDER=$(json_value '.bookdrop_folder' || true)
BOOKS_FOLDER=$(json_value '.books_folder' || true)
TIMEZONE=$(json_value '.timezone' || true)
DISK_TYPE=$(json_value '.disk_type' || true)
API_DOCS_ENABLED=$(json_value '.api_docs_enabled' || true)

BOOKDROP_FOLDER=${BOOKDROP_FOLDER:-$DEFAULT_BOOKDROP_FOLDER}
BOOKS_FOLDER=${BOOKS_FOLDER:-$DEFAULT_BOOKS_FOLDER}
TIMEZONE=${TIMEZONE:-$DEFAULT_TZ}
DISK_TYPE=${DISK_TYPE:-$DEFAULT_DISK_TYPE}
API_DOCS_ENABLED=${API_DOCS_ENABLED:-$DEFAULT_API_DOCS_ENABLED}

case "$BOOKDROP_FOLDER" in
    /*|*..*)
    echo "Invalid bookdrop_folder: must be relative to /share" >&2
        exit 1
        ;;
esac

case "$BOOKS_FOLDER" in
    /*|*..*)
        echo "Invalid books_folder: must be relative to /share" >&2
        exit 1
        ;;
esac

USER_ID=${USER_ID:-$DEFAULT_USER_ID}
GROUP_ID=${GROUP_ID:-$DEFAULT_GROUP_ID}
TZ=${TZ:-$TIMEZONE}
APP_USER=${APP_USER:-grimmory}
BOOKLORE_PORT=${BOOKLORE_PORT:-6060}
BOOKDROP_PATH="/share/${BOOKDROP_FOLDER}"
BOOKS_PATH="/share/${BOOKS_FOLDER}"

MYSQL_SERVICE_INFO=$(get_mysql_service_info)
MYSQL_HOST=$(get_mysql_service_value "$MYSQL_SERVICE_INFO" host)
MYSQL_PORT=$(get_mysql_service_value "$MYSQL_SERVICE_INFO" port)
MYSQL_USER=$(get_mysql_service_value "$MYSQL_SERVICE_INFO" username)
MYSQL_PASSWORD=$(get_mysql_service_value "$MYSQL_SERVICE_INFO" password)
MYSQL_DATABASE=$(get_mysql_service_value "$MYSQL_SERVICE_INFO" database)

MYSQL_DATABASE=${MYSQL_DATABASE:-grimmory}
MYSQL_URL_PARAMS='createDatabaseIfNotExist=true&connectionTimeZone=UTC&forceConnectionTimeZoneToSession=true'

export USER_ID GROUP_ID TZ APP_USER APP_VERSION APP_REVISION BOOKLORE_PORT
export DISK_TYPE API_DOCS_ENABLED
export JAVA_HOME=/opt/java/openjdk
export PATH=/opt/java/openjdk/bin:${PATH}

if [ -n "$MYSQL_HOST" ] && [ -n "$MYSQL_PORT" ] && [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_PASSWORD" ]; then
    export DATABASE_URL="jdbc:mariadb://${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}?${MYSQL_URL_PARAMS}"
    export DATABASE_USERNAME="$MYSQL_USER"
    export DATABASE_PASSWORD="$MYSQL_PASSWORD"
    rm -f "$NEEDS_DB_RESTART_FILE" "$DB_RESTART_TRIGGERED_FILE"
    bashio::log.info "MariaDB settings resolved; launching Grimmory with database connectivity enabled"
else
    unset DATABASE_URL DATABASE_USERNAME DATABASE_PASSWORD
    touch "$NEEDS_DB_RESTART_FILE"
    rm -f "$DB_RESTART_TRIGGERED_FILE"
    bashio::log.warning "MariaDB is not available yet; starting Grimmory without database settings so the app can retry internally"
fi

bashio::log.info "Starting Grimmory"
bashio::log.info "Bookdrop folder: ${BOOKDROP_PATH}"
bashio::log.info "Books folder: ${BOOKS_PATH}"
bashio::log.info "Timezone: ${TZ}"
bashio::log.info "Disk type: ${DISK_TYPE}"
bashio::log.info "API docs enabled: ${API_DOCS_ENABLED}"

if [ -n "$MYSQL_HOST" ] && [ -n "$MYSQL_PORT" ]; then
    bashio::log.info "Database: ${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}"
fi

if ! getent group "$GROUP_ID" >/dev/null 2>&1; then
    addgroup -g "$GROUP_ID" -S "$APP_USER"
fi

if ! getent passwd "$APP_USER" >/dev/null 2>&1; then
    adduser -u "$USER_ID" -G "$(getent group "$GROUP_ID" | cut -d: -f1)" -S -D "$APP_USER"
fi

mkdir -p /data "$BOOKDROP_PATH" "$BOOKS_PATH"
chown -R "$USER_ID:$GROUP_ID" /data "$BOOKDROP_PATH" "$BOOKS_PATH" /bookdrop /books 2>/dev/null || true
chmod -R u+rwX,g+rwX "$BOOKDROP_PATH" "$BOOKS_PATH" 2>/dev/null || true

exec su-exec "$USER_ID:$GROUP_ID" java --enable-native-access=ALL-UNNAMED --enable-preview -jar /app/app.jar
