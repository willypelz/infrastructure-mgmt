# 🚀 Laravel Application Setup Guide

## Problem Fixed

The Laravel Dockerfile was failing with:
```
failed to solve: process "/bin/sh -c composer install --no-dev --optimize-autoloader --no-interaction" did not complete successfully: exit code: 1
```

**Root Cause:** The `app` directory was empty (only contained README.md), but the Dockerfile tried to run `composer install` without checking if a Laravel application exists.

**Solution:** Updated Dockerfile to conditionally run composer install only when `composer.json` exists.

---

## ✅ What I Fixed

### 1. Updated `apps/php-laravel/Dockerfile`

**Before:**
```dockerfile
COPY ./app /var/www/html
RUN composer install --no-dev --optimize-autoloader --no-interaction
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
```

**After:**
```dockerfile
COPY ./app /var/www/html

# Install Laravel dependencies (only if composer.json exists)
RUN if [ -f composer.json ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction; \
    else \
        echo "No Laravel application found."; \
    fi

# Set permissions (create directories if they don't exist)
RUN if [ -d storage ] && [ -d bootstrap/cache ]; then \
        chown -R www-data:www-data storage bootstrap/cache && \
        chmod -R 775 storage bootstrap/cache; \
    else \
        mkdir -p storage bootstrap/cache && \
        chown -R www-data:www-data storage bootstrap/cache && \
        chmod -R 775 storage bootstrap/cache; \
    fi
```

### 2. Created `apps/php-laravel/app/index.php`

A beautiful placeholder page that:
- ✅ Shows setup instructions
- ✅ Displays PHP version info
- ✅ Provides step-by-step Laravel installation guide
- ✅ Professional design with clear instructions

---

## 🎯 Now You Can Deploy

The container will now build successfully **even without Laravel installed**:

```bash
cd /root/infrastructure-mgmt
./scripts/deploy.sh --app php-laravel
```

This will:
- ✅ Build the Docker image successfully
- ✅ Start the container
- ✅ Show a setup page at `https://shop.gmcloudworks.org`

---

## 📋 How to Install Laravel

### Option 1: Fresh Laravel Installation

```bash
# SSH into your server
ssh root@your-server-ip

# Navigate to Laravel app directory
cd /root/infrastructure-mgmt/apps/php-laravel/app

# Remove placeholder files
rm -rf *

# Install Laravel (this will take a few minutes)
composer create-project laravel/laravel .

# Configure environment
cp .env.example .env
php artisan key:generate

# Update database settings in .env
nano .env
# Set:
# DB_HOST=laravel-db
# DB_DATABASE=laravel
# DB_USERNAME=laraveluser
# DB_PASSWORD=<from your main .env file>

# Rebuild container
cd /root/infrastructure-mgmt
./scripts/deploy.sh --app php-laravel

# Run migrations
docker exec laravel-app php artisan migrate
```

### Option 2: Use Existing Laravel Project

```bash
# SSH into server
ssh root@your-server-ip

# Navigate to app directory
cd /root/infrastructure-mgmt/apps/php-laravel/app

# Remove placeholder files
rm -rf *

# Clone your Laravel project
git clone https://github.com/your-username/your-laravel-app.git .

# Install dependencies
composer install --no-dev

# Configure environment
cp .env.example .env
php artisan key:generate

# Update .env with database credentials
nano .env

# Rebuild container
cd /root/infrastructure-mgmt
./scripts/deploy.sh --app php-laravel

# Run migrations
docker exec laravel-app php artisan migrate
```

---

## 🔧 Database Configuration

Your Laravel `.env` file should have these database settings:

```env
DB_CONNECTION=mysql
DB_HOST=laravel-db
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laraveluser
DB_PASSWORD=change_this_laravel_password
```

**Note:** The database password comes from your main `.env` file at:
`/root/infrastructure-mgmt/.env` → `LARAVEL_DB_PASSWORD`

---

## ✅ Verification

### 1. Check Container Status
```bash
docker ps | grep laravel
```

Should show:
- `laravel-app` - Running
- `laravel-db` - Running

### 2. Check Logs
```bash
docker logs laravel-app --tail 50
```

### 3. Access Application

**Without Laravel Installed:**
- Visit: `https://shop.gmcloudworks.org`
- See: Setup instructions page

**With Laravel Installed:**
- Visit: `https://shop.gmcloudworks.org`
- See: Laravel welcome page

---

## 🚨 Common Issues

### Issue 1: Composer Install Fails

**Error:** "Your requirements could not be resolved"

**Solution:**
```bash
# Use PHP 8.2 compatible Laravel version
composer create-project laravel/laravel:^10.0 .
```

### Issue 2: Permission Denied

**Solution:**
```bash
# Fix permissions
cd /root/infrastructure-mgmt/apps/php-laravel/app
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
```

### Issue 3: Database Connection Failed

**Solution:**
```bash
# Verify database is running
docker exec laravel-db mysql -u laraveluser -p -e "SHOW DATABASES;"

# Update .env with correct credentials
nano .env
```

### Issue 4: "No application encryption key has been specified"

**Solution:**
```bash
docker exec laravel-app php artisan key:generate
```

---

## 📊 What Each File Does

| File | Purpose |
|------|---------|
| `Dockerfile` | Builds PHP 8.2 + Nginx + Laravel environment |
| `docker-compose.yml` | Configures Laravel app + MySQL database |
| `nginx.conf` | Nginx configuration for Laravel routing |
| `start.sh` | Startup script (runs PHP-FPM + Nginx) |
| `app/index.php` | Placeholder page (shown when Laravel not installed) |
| `app/README.md` | Setup instructions |

---

## 🎉 Summary

### Before Fix:
❌ Dockerfile failed to build  
❌ Couldn't deploy Laravel container  
❌ Required Laravel to be pre-installed  

### After Fix:
✅ Dockerfile builds successfully  
✅ Container runs even without Laravel  
✅ Shows helpful setup page  
✅ Easy Laravel installation  
✅ Clear instructions provided  

---

## 🚀 Deploy Now

```bash
# On your server:
cd /root/infrastructure-mgmt
./scripts/deploy.sh --app php-laravel
```

Then visit: **https://shop.gmcloudworks.org**

You'll see the setup page with full instructions! 🎊

---

## 📚 Next Steps

1. **Deploy the container** (works now!)
2. **Visit the setup page** to see instructions
3. **Install Laravel** following the guide
4. **Rebuild the container** with your Laravel app
5. **Run migrations** to set up database
6. **Enjoy your Laravel application!** 🎉

The Laravel container is now **production-ready** and **beginner-friendly**! ✨
