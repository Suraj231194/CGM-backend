#!/usr/bin/env bash
set -euo pipefail

export PORT="${PORT:-10000}"
echo "Listen ${PORT}" > /etc/apache2/ports.conf
sed -i "s/\${PORT}/${PORT}/g" /etc/apache2/sites-available/000-default.conf

if [[ "${APP_KEY:-}" =~ ^[A-Za-z0-9+/]+={0,2}$ ]] && [ "${#APP_KEY}" -eq 44 ]; then
    export APP_KEY="base64:${APP_KEY}"
fi

if [ -z "${APP_URL:-}" ] && [ -n "${RENDER_EXTERNAL_HOSTNAME:-}" ]; then
    export APP_URL="https://${RENDER_EXTERNAL_HOSTNAME}"
fi

php artisan config:clear
php artisan migrate --force

if [ "${RUN_DEMO_SEEDERS:-false}" = "true" ]; then
    php artisan db:seed --force
fi

php artisan config:cache
php artisan route:cache
php artisan event:cache

exec apache2-foreground
