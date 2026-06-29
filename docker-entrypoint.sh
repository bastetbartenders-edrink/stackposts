#!/bin/bash
set -e

# Gera o .env a partir das variaveis de ambiente do Railway
cat > /var/www/html/.env << EOF
CI_ENVIRONMENT = ${CI_ENVIRONMENT:-production}

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

# Importa o banco de dados na primeira inicialização
echo "Verificando banco de dados..."
MYSQL_CMD="mysql --skip-ssl -h ${MYSQLHOST} -P ${MYSQLPORT} -u ${MYSQLUSER} -p${MYSQLPASSWORD} ${MYSQLDATABASE}"

DB_CHECK=$(${MYSQL_CMD} -e "SHOW TABLES LIKE 'sp_users';" 2>/dev/null | grep -c sp_users || true)

if [ "$DB_CHECK" -eq "0" ]; then
    echo "Banco vazio — importando DATABASE.sql..."
    ${MYSQL_CMD} < /var/www/html/DATABASE.sql && echo "Banco importado com sucesso!" || echo "Aviso: erro ao importar banco."
else
    echo "Banco já configurado — pulando importação."
fi

# Inicia php-fpm em background
php-fpm -D

# Inicia nginx em foreground
exec nginx -g 'daemon off;'
