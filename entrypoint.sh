#!/bin/sh
set -e

cd /var/www/html

[ -f .env ] || cp .env.example .env

grep -q "^APP_KEY=base64:" .env || php artisan key:generate --force

until php -r "
try{
new PDO(
'mysql:host='.getenv('DB_HOST').';port='.getenv('DB_PORT').';dbname='.getenv('DB_DATABASE'),
getenv('DB_USERNAME'),
getenv('DB_PASSWORD'));
}catch(Exception \$e){exit(1);}
"; do
    sleep 2
done

php artisan migrate --force || true

[ -e public/storage ] || php artisan storage:link

php artisan config:cache
php artisan route:cache || true
php artisan view:cache

chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

exec "$@"

