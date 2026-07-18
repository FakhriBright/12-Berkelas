FROM node:20-alpine AS assets

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY resources resources
COPY public public
COPY vite.config.js tailwind.config.js postcss.config.js ./

RUN npm run build


FROM php:8.2-fpm-alpine

WORKDIR /var/www/html

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

RUN apk add --no-cache bash git unzip curl \
    && install-php-extensions gd pdo_mysql zip bcmath exif pcntl opcache

COPY . .
COPY --from=assets /app/public/build public/build

RUN composer install --no-dev --prefer-dist --optimize-autoloader --no-interaction \
    && mkdir -p bootstrap/cache storage/framework/{cache,sessions,views} storage/logs \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm"]
