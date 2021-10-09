dnf install epel-release wget unzip

wget https://hostboxcp.com/lighttpd/lighttpd.repo -P /etc/yum.repos.d/
dnf install -y lighttpd
dnf install -y php php-mysqlnd php-json php-xml php-pdo php-gd php-mbstring
dnf install -y php-fpm lighttpd-fastcgi
mv /etc/lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf.orig
wget https://hostboxcp.com/lighttpd/lighttpd.conf -P /etc/lighttpd/
mv /etc/lighttpd/modules.conf /etc/lighttpd/modules.conf.orig
wget https://hostboxcp.com/lighttpd/modules.conf -P /etc/lighttpd/
systemctl enable --now lighttpd

dnf install -y mariadb-server
systemctl enable --now mariadb

mysql -u root <<-EOF
UPDATE mysql.user SET Password=PASSWORD('$mysqlrootpass') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF

systemctl restart mariadb

mysql -u root -p$mysqlrootpass <<-EOF
CREATE DATABASE box;
CREATE USER 'box'@'localhost' IDENTIFIED BY '$boxdbpass';
GRANT ALL PRIVILEGES ON box.* TO 'box'@'localhost';
FLUSH PRIVILEGES;
EOF

wget -O - https://get.acme.sh | sh
source ~/.bashrc

dnf install -y firewalld
systemctl enable --now firewalld
firewall-cmd --add-port 80/tcp --permanent
firewall-cmd --add-port 443/tcp --permanent
firewall-cmd --reload

mkdir -p /etc/lighttpd/ssl
openssl req -newkey rsa:2048 -new -nodes -x509 -days 365 -subj "/C=BD/ST=Dhaka Division/L=Dhaka Zilla/O=BoxBilling/CN=boxbilling.org" -keyout /etc/lighttpd/ssl/key.pem -out /etc/lighttpd/ssl/cert.pem

cp /etc/lighttpd/vhosts.d/vhosts.template /etc/lighttpd/vhosts.d/boxbilling.conf
mkdir -p /srv/www/vhosts/irepo.istiak.com/htdocs
mkdir -p /var/log/lighttpd/irepo.istiak.com
touch /var/log/lighttpd/irepo.istiak.com/access.log
touch /var/log/lighttpd/irepo.istiak.com/error.log
chown -R lighttpd:lighttpd /var/log/lighttpd/irepo.istiak.com
systemctl restart lighttpd

wget https://github.com/boxbilling/boxbilling/releases/download/v4.22-beta.1/BoxBilling.zip
unzip BoxBilling.zip
chown -R lighttpd:lighttpd /srv/www/vhosts/irepo.istiak.com/htdocs/
cp bb-config-sample.php bb-config.php
