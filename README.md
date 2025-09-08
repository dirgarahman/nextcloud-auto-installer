# 🚀 Nextcloud Auto Installer (Ubuntu)

Automated script to install **Nextcloud 31.0.0** on **Ubuntu**.  
Easy to use, includes configuration for **Apache, MariaDB, PHP 8.2, Redis, APCu, cronjob, and optimized config.php**.

---

## ✨ Features

- Install **Apache2**, **MariaDB**, **PHP 8.2** (via Ondřej Surý PPA)
- Install & configure **Redis** + **APCu** for caching & file locking
- Auto-configure **Nextcloud `config.php`** with:
  - `trusted_domains`
  - `default_phone_region`
  - `filelocking.enabled`
  - `memcache.local`, `memcache.locking`
- Optimized **PHP** (`memory_limit = 512M`)
- Setup **cronjob** (`cron.php` every 5 minutes)
- Secure **Apache VirtualHost** with `.well-known` redirects

---

## 📥 Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/nextcloud-auto-installer.git
   cd nextcloud-auto-installer/scripts
   ```

2. Edit important variables in the script:
   ```bash
   nano nextcloud-auto-install.sh
   ```

   Update values as needed:

   - `SERVER_NAME="cloud.brighton"`  
     → your domain (e.g. `cloud.mydomain.com`)

   - `SERVER_IP="192.168.1.50"`  
     → your server IP (local or public)

   - `DB_NAME="nextcloud"`  
     → database name (optional)

   - `DB_USER="nextclouduser"`  
     → database username (optional)

   - `DB_PASS="StrongPassword123"`  
     → database password (**MUST** be changed to a strong password)

3. Run the script:
   ```bash
   chmod +x nextcloud-auto-install.sh
   sudo ./nextcloud-auto-install.sh
   ```

---

## 🌐 After Installation

1. Open your browser and go to:
   ```
   http://cloud.brighton/
   ```
   (or your configured domain/IP)

2. Follow the Nextcloud setup wizard.  
   Enter the **Database Name, User, Password** you configured in the script.

---

## ⚠️ Notes

- Ensure your **domain DNS** (`SERVER_NAME`) is pointing to the server IP.
- Always use a **strong database password**.
- For production security, enable **HTTPS** (Let’s Encrypt / Certbot).

---

## 📄 License

Free to use & modify. 🙌
