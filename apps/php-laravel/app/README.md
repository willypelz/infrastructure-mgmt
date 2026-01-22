# PHP Laravel Application

This is a sample Laravel application structure. To use a real Laravel application:

1. Install Laravel in the `app` directory:
```bash
composer create-project laravel/laravel app
```

2. Or copy your existing Laravel application to the `app` directory.

3. Configure `.env` file in the `app` directory with database credentials.

4. Deploy:
```bash
docker-compose up -d
```

## Quick Laravel Setup

If starting fresh:

```bash
# Remove this README
rm app/README.md

# Create new Laravel project
composer create-project laravel/laravel app

# Or clone existing project
git clone your-laravel-repo app
cd app
composer install
cp .env.example .env
php artisan key:generate
```

## Database Migration

```bash
docker-compose exec laravel-app php artisan migrate
```

## Access Application

- URL: https://shop.yourdomain.com
- Admin: Configure in Laravel

## Logs

```bash
docker-compose logs -f laravel-app
```
