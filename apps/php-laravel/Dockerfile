FROM php:8.2-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    mysql-client

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql mysqli gd xml

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY ./app /var/www/html

# Install Laravel dependencies (only if composer.json exists)
RUN if [ -f composer.json ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction; \
    else \
        echo "<?php phpinfo(); ?>" > index.php; \
        echo "No Laravel application found. Please install Laravel in the app directory."; \
        echo "Visit the documentation for setup instructions."; \
    fi

# Set permissions (only if Laravel directories exist)
RUN if [ -d storage ] && [ -d bootstrap/cache ]; then \
        chown -R www-data:www-data storage bootstrap/cache && \
        chmod -R 775 storage bootstrap/cache; \
    else \
        mkdir -p storage bootstrap/cache && \
        chown -R www-data:www-data storage bootstrap/cache && \
        chmod -R 775 storage bootstrap/cache; \
    fi

# Copy nginx configuration
COPY nginx.conf /etc/nginx/http.d/default.conf

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

CMD ["/start.sh"]
