# Настройка заббикс-агента

На Linux-сервере.

## Устанавливаем заббикс-агент

```
zabbix_version=3.4
wget https://repo.zabbix.com/zabbix/${zabbix_version}/debian/pool/main/z/zabbix-release/zabbix-release_${zabbix_version}-1+`lsb_release -cs`_all.deb
dpkg -i zabbix-release_${zabbix_version}-1+stretch_all.deb
rm zabbix-release_${zabbix_version}-1+stretch_all.deb
apt update

apt -yy install zabbix-agent git
systemctl enable zabbix-agent.service
```

## Скачиваем дефолтные настройки

```cd /etc/zabbix
git clone https://github.com/maxvgi/zabbix-agent-settings.git
cp -r /etc/zabbix/zabbix-agent-settings/* /etc/zabbix
rm -r /etc/zabbix/zabbix-agent-settings/
/etc/zabbix/install-dependencies.sh
```

## Настраиваем мониторинг mysql

Генерируем случайный пароль, добавляем пользователя для мониторинга в базу. Возможно, в конце к команде `mysql -uroot` нужно будет добавить опцию `-p`

```
pwd=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32}`
sed -e 's/PASSWORD/'$pwd'/' userparameter_mysql.conf > userparameter_mysql.conf.new
mv userparameter_mysql.conf.new userparameter_mysql.conf

echo CREATE USER \'zabbix-agent\'@\'localhost\' IDENTIFIED BY \"$pwd\"\; GRANT REPLICATION CLIENT ON \*.\* TO \'zabbix-agent\'@\'localhost\'\;FLUSH PRIVILEGES\; | mysql -uroot
```

## Перезапускаем заббикс-агент

Одно из двух:

```
/etc/init.d/zabbix-agent restart
systemctl restart zabbix-agent.service
```

## Настраиваем nginx

Обязательно **проверяем конфиг** перед применением. Чтобы не было конфликтов добавляемого хоста localhost с тем, что уже есть.

Также проверяем корректность настройки пыха в localhost-zabbix - чтобы был правильно указан сокет для fpm.

```
grep '#' nginx.conf | cut -c 2- > /etc/nginx/sites-available/localhost-zabbix
ln -s ../sites-available/localhost-zabbix /etc/nginx/sites-enabled/localhost-zabbix
#nginx -t && nginx -s reload
```

## Настраиваем php-fpm

Идём в `/etc/php/{$php_version}/pool.d/www.conf`. Раскомментируем и меняем строку (с номером 238?)
`;pm.status_path = /status` на `pm.status_path = /fpm/status`

Перезапускаем fpm:

```
/etc/init.d/php{$version}-fpm restart
```

## Добавляем хост в zabbix

Идём в заббикс. Configuration->Hosts->Create host

Заполняем Host name, выбираем группу Linux servers. Вписываем в Agent interfaces ip-адрес добавляемого в заббикс севера.

На вкладке Templates выбираем следующие шаблоны и жмём ссылку Add:

* Template App MySQL
* Template php-fpm
* Template Nginx
* Template Linux Disk IO
* Template OS Linux
* Template Iostat-Disk-Utilization

На вкладке Macros добавляем макрос:

`{$PHP_FPM_STATUS_URL}` => `http://localhost/fpm/status`


Сохраняем хост. Всё.
