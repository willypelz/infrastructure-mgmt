<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Laravel Setup Required</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 10px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 800px;
            width: 100%;
            padding: 40px;
        }
        h1 {
            color: #333;
            margin-bottom: 20px;
            font-size: 2em;
        }
        .logo {
            font-size: 4em;
            margin-bottom: 20px;
        }
        p {
            color: #666;
            line-height: 1.6;
            margin-bottom: 15px;
        }
        .code-block {
            background: #f5f5f5;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin: 20px 0;
            font-family: 'Courier New', monospace;
            overflow-x: auto;
        }
        .code-block code {
            color: #333;
            display: block;
        }
        .steps {
            margin-top: 30px;
        }
        .step {
            margin-bottom: 20px;
            padding-left: 30px;
            position: relative;
        }
        .step-number {
            position: absolute;
            left: 0;
            top: 0;
            background: #667eea;
            color: white;
            width: 24px;
            height: 24px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 12px;
            font-weight: bold;
        }
        .alert {
            background: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .success {
            background: #d4edda;
            border-left: 4px solid #28a745;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🚀</div>
        <h1>Laravel Application Setup Required</h1>

        <div class="alert">
            <strong>⚠️ Notice:</strong> No Laravel application detected in the app directory.
        </div>

        <p>This container is ready to run Laravel, but you need to install a Laravel application first.</p>

        <div class="steps">
            <h2 style="margin-bottom: 20px;">Setup Instructions:</h2>

            <div class="step">
                <span class="step-number">1</span>
                <strong>SSH into your server:</strong>
                <div class="code-block">
                    <code>ssh root@your-server-ip</code>
                </div>
            </div>

            <div class="step">
                <span class="step-number">2</span>
                <strong>Navigate to the Laravel app directory:</strong>
                <div class="code-block">
                    <code>cd /root/infrastructure-mgmt/apps/php-laravel/app</code>
                </div>
            </div>

            <div class="step">
                <span class="step-number">3</span>
                <strong>Install Laravel:</strong>
                <div class="code-block">
                    <code># Remove placeholder files<br>
rm -rf *<br>
<br>
# Create new Laravel project<br>
composer create-project laravel/laravel .<br>
<br>
# Or clone your existing Laravel project<br>
git clone https://github.com/your-repo/your-laravel-app.git .<br>
composer install</code>
                </div>
            </div>

            <div class="step">
                <span class="step-number">4</span>
                <strong>Configure environment:</strong>
                <div class="code-block">
                    <code>cp .env.example .env<br>
php artisan key:generate</code>
                </div>
            </div>

            <div class="step">
                <span class="step-number">5</span>
                <strong>Rebuild and restart the container:</strong>
                <div class="code-block">
                    <code>cd /root/infrastructure-mgmt<br>
./scripts/deploy.sh --app php-laravel</code>
                </div>
            </div>
        </div>

        <div class="alert success" style="margin-top: 30px;">
            <strong>✅ After Setup:</strong> Your Laravel application will be accessible at <strong>https://shop.gmcloudworks.org</strong>
        </div>

        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">

        <h3 style="margin-bottom: 15px;">Quick Info:</h3>
        <p><strong>PHP Version:</strong> <?php echo phpversion(); ?></p>
        <p><strong>Container Status:</strong> Running ✅</p>
        <p><strong>Database Host:</strong> laravel-db</p>
        <p><strong>Documentation:</strong> <a href="https://laravel.com/docs" target="_blank">laravel.com/docs</a></p>

    </div>
</body>
</html>
