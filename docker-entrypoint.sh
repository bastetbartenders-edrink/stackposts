#!/bin/bash
set -e

# Gera o .env a partir das variaveis de ambiente do Railway
cat > /var/www/html/.env << EOF
CI_ENVIRONMENT = production

app.baseURL = '${APP_BASE_URL}'

app.sessionCookieName = 'stackpost_session'
app.sessionExpiration = 2592000
app.sessionMatchIP = false
app.sessionTimeToUpdate = 300

database.default.hostname = ${MYSQLHOST}
database.default.database = ${MYSQLDATABASE}
database.default.username = ${MYSQLUSER}
database.default.password = ${MYSQLPASSWORD}
database.default.port = ${MYSQLPORT}
database.default.DBDriver = MySQLi
database.default.DBPrefix =

encryption.key = ${ENCRYPTION_KEY:-6228678fdcbf5}
encryption.driver = OpenSSL
encryption.blockSize = 16
encryption.digest = SHA512

security.tokenName = 'csrf'
security.headerName = 'X-CSRF-TOKEN'
security.cookieName = 'csrf_cookie'
security.expires = 2592000
security.regenerate = true
security.redirect = true
security.samesite = 'Lax'
EOF

echo ".env gerado com sucesso"

# Inicia php-fpm em background
php-fpm -D

# Inicia nginx em foreground
exec nginx -g 'daemon off;'
