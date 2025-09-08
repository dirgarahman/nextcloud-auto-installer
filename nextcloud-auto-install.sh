#!/bin/bash
# Auto install Nextcloud 31.0.0 with PHP 8.2 on Ubuntu 20.04
# Run as root (sudo -i)

set -e

# Variables (change if needed)
DB_NAME=nextcloud
DB_USER=nextclouduser
DB_PASS=StrongPassword123
NEXTCLOUD_VERSION=31.0.0
NEXTCLOUD_URL="https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.zip"
NEXTCLOUD_DIR=/var/www/nextcloud
SERVER_NAME=cloud.brighton
SERVER_IP=192.168.1.50

# Update system
echo "Updating system..."
apt update && apt upgrade -y

# Add PHP PPA for newer versions
echo "Adding PHP repository..."
apt install -y software-properties-common
add-apt-repository ppa:ondrej/php -y
apt update

# Install Apache, MariaDB, PHP 8.2, Redis, and required modules
echo "Installing Apache, MariaDB, PHP 8.2, and Redis..."
apt install -y apache2 mariadb-server redis-server php-redis \
    libapache2-mod-php8.2 php8.2 php8.2-cli php8.2-common php8.2-mysql \
    php8.2-gd php8.2-curl php8.2-mbstring php8.2-intl php8.2-xml \
    php8.2-zip php8.2-bz2 php8.2-gmp php8.2-imagick unzip wget

# Secure MariaDB (basic hardening)
echo "Securing MariaDB..."
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
mysql -e "FLUSH PRIVILEGES;"

# Create Nextcloud database and user
echo "Creating Nextcloud database..."
mysql -e "CREATE DATABASE ${DB_NAME};"
mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Download Nextcloud
echo "Downloading Nextcloud ${NEXTCLOUD_VERSION}..."
wget ${NEXTCLOUD_URL} -P /tmp
unzip /tmp/nextcloud-${NEXTCLOUD_VERSION}.zip -d /var/www/
chown -R www-data:www-data ${NEXTCLOUD_DIR}
chmod -R 755 ${NEXTCLOUD_DIR}

# Apache configuration
echo "Configuring Apache..."
cat >/etc/apache2/sites-available/nextcloud.conf <<EOF
<VirtualHost *:80>
    ServerName ${SERVER_NAME}
    DocumentRoot ${NEXTCLOUD_DIR}

    <Directory ${NEXTCLOUD_DIR}/>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews

        <IfModule mod_headers.c>
            Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains; preload"
        </IfModule>

        <IfModule mod_dav.c>
            Dav off
        </IfModule>

        RewriteEngine On
        RewriteRule ^/\.well-known/carddav https://%{SERVER_NAME}/remote.php/dav/ [R=301,L]
        RewriteRule ^/\.well-known/caldav https://%{SERVER_NAME}/remote.php/dav/ [R=301,L]
        RewriteRule ^/\.well-known/host-meta https://%{SERVER_NAME}/public.php?service=host-meta [QSA,L]
        RewriteRule ^/\.well-known/host-meta\.json https://%{SERVER_NAME}/public.php?service=host-meta-json [QSA,L]
        RewriteRule ^/\.well-known/webfinger https://%{SERVER_NAME}/public.php?service=webfinger [QSA,L]
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

a2ensite nextcloud.conf
a2enmod rewrite headers env dir mime ssl
systemctl restart apache2

# Update PHP config
echo "Updating PHP memory limit..."
sed -i 's/^memory_limit = .*/memory_limit = 512M/' /etc/php/8.2/apache2/php.ini
sed -i 's/^memory_limit = .*/memory_limit = 512M/' /etc/php/8.2/cli/php.ini
systemctl restart apache2

# Nextcloud config.php adjustments
echo "Updating Nextcloud config.php..."
sudo -u www-data php ${NEXTCLOUD_DIR}/occ config:system:set trusted_domains 0 --value=${SERVER_IP}:80
sudo -u www-data php ${NEXTCLOUD_DIR}/occ config:system:set trusted_domains 1 --value=${SERVER_NAME}
sudo -u www-data php ${NEXTCLOUD_DIR}/occ config:system:set default_phone_region --value="ID"
sudo -u www-data php ${NEXTCLOUD_DIR}/occ config:system:set filelocking.enabled --value="true" --type=boolean
sudo -u www-data php ${NEXTCLOUD_DIR}/occ config:system:set memcache.local --value="\OC\Memcache\APCu"
sudo -u www-data php ${NEXTCLOUD_DIR}/occ config:system:set memcache.locking --value="\OC\Memcache\Redis"
sudo -u www-data php ${NEXTCLOUD_DIR}/occ config:system:set redis host --value="127.0.0.1"
sudo -u www-data php ${NEXTCLOUD_DIR}/occ config:system:set redis port --value="6379" --type=integer

# Setup cron for background jobs
echo "Configuring cron..."
(crontab -u www-data -l 2>/dev/null; echo "*/5 * * * * php -f ${NEXTCLOUD_DIR}/cron.php") | crontab -u www-data -

# Enable firewall
echo "Setting up firewall..."
ufw allow OpenSSH
ufw allow 'Apache Full'
ufw --force enable

echo "==================================================="
echo "Nextcloud ${NEXTCLOUD_VERSION} installed successfully!"
echo "PHP version: $(php -v | head -n 1)"
echo "Access your Nextcloud at: http://${SERVER_NAME}/"
echo "Database Name: ${DB_NAME}"
echo "Database User: ${DB_USER}"
echo "Database Password: ${DB_PASS}"
echo "==================================================="
