# WordPress Application

WordPress blog hosted at `blog.${DOMAIN}`

## Quick Start

1. Copy environment variables:
```bash
cp ../../.env.example ../../.env
# Edit .env with your domain and database credentials
```

2. Deploy:
```bash
docker-compose up -d
```

3. Access:
- Site: https://blog.yourdomain.com
- Admin: https://blog.yourdomain.com/wp-admin

## Database Backup

Manual backup:
```bash
docker-compose exec wordpress-db mysqldump -u root -p${WORDPRESS_DB_ROOT_PASSWORD} ${WORDPRESS_DB_NAME} > db-backup/wordpress-$(date +%Y%m%d-%H%M%S).sql
```

## Restore Database

```bash
docker-compose exec -T wordpress-db mysql -u root -p${WORDPRESS_DB_ROOT_PASSWORD} ${WORDPRESS_DB_NAME} < db-backup/your-backup.sql
```

## Logs

```bash
docker-compose logs -f wordpress
```

## Health Check

WordPress container includes a health check at `/wp-admin/install.php`
