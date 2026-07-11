FROM composer:2 AS dependencies

WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts

FROM php:8.4-cli-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libicu-dev \
        libonig-dev \
        libpq-dev \
        libzip-dev \
        unzip \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        intl \
        mbstring \
        pdo_mysql \
        pdo_pgsql \
        zip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY --from=dependencies /app/vendor ./vendor
COPY . ./

RUN chmod +x docker/railway/start.sh \
    && mkdir -p bootstrap/cache storage/framework/{cache,sessions,views} storage/logs \
    && chown -R www-data:www-data bootstrap/cache storage

ENV APP_ENV=production \
    APP_DEBUG=false

EXPOSE 8080

CMD ["sh", "docker/railway/start.sh"]
