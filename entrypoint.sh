#!/bin/sh
set -e

cd /var/www/html

echo "===== SkyLine Airways Startup ====="

# Copy .env jika belum ada
if [ ! -f .env ]; then
    cp .env.example .env
fi

# Generate APP_KEY jika belum ada
if ! grep -q "^APP_KEY=base64:" .env; then
    php artisan key:generate --force
fi

echo "Waiting for MySQL..."

until php -r "
try{
    new PDO(
        'mysql:host='.getenv('DB_HOST').';port='.getenv('DB_PORT').';dbname='.getenv('DB_DATABASE'),
        getenv('DB_USERNAME'),
        getenv('DB_PASSWORD')
    );
}catch(Exception \$e){
    exit(1);
}
"; do
    sleep 2
done

echo "Database connected."

# Jalankan migrate
php artisan migrate --force

# Storage link
if [ ! -L public/storage ]; then
    php artisan storage:link
fi

# Cache
php artisan config:cache
php artisan route:cache || true
php artisan view:cache

# Permission
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

echo "Laravel ready."

exec "$@"
