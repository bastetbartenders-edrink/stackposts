FROM php:8.1-apache

# System dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libzip-dev \
    libicu-dev \
    libcurl4-openssl-dev \
    unzip \
    git \
    curl \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        mysqli \
        gd \
        zip \
        intl \
        curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Apache: allow .htaccess overrides
RUN echo '<Directory /var/www/html>\n\
    AllowOverride All\n\
    Options -Indexes +FollowSymLinks\n\
    Require all granted\n\
</Directory>' > /etc/apache2/conf-available/ci4.conf \
    && a2enconf ci4

# Copy application files
COPY . /var/www/html/

# Install PHP dependencies
RUN cd /var/www/html && composer install --no-dev --optimize-autoloader --no-interaction

# Writable folder permissions
RUN chown -R www-data:www-data /var/www/html/writable \
    && chmod -R 775 /var/www/html/writable

# PHP config
RUN echo "upload_max_filesize = 50M\npost_max_size = 50M\nmemory_limit = 256M\nmax_execution_time = 120" \
    > /usr/local/etc/php/conf.d/custom.ini

# Entrypoint script
RUN chmod +x /var/www/html/docker-entrypoint.sh

EXPOSE 80

CMD ["/var/www/html/docker-entrypoint.sh"]
