#!/bin/bash

if [[ -z "$RUN_AS" ]]; then
	RUN_AS=prosody
fi

if [[ -z "$RUN_AS_GROUP" ]]; then
	RUN_AS_GROUP=$RUN_AS
fi

sed -e "s/user \+nginx;/user $RUN_AS;/" -i /etc/nginx/nginx.conf
sed -e "s/user=prosody/user=$RUN_AS/" -i /etc/supervisord.conf

mkdir -p /etc/prosody/certs
cp -r /certs/$LETSENCRYPT_HOST/* /etc/prosody/certs

mkdir -p /run/prosody
mkdir -p /var/log/prosody

chown -R $RUN_AS:$RUN_AS_GROUP /srv/www
chown -R $RUN_AS:$RUN_AS_GROUP /etc/prosody
chown -R $RUN_AS:$RUN_AS_GROUP /run/prosody
chown -R $RUN_AS:$RUN_AS_GROUP /var/log/prosody

sed -Eei "s/@JABBER_HOST@/$JABBER_HOST/g" /srv/www/index.html
sed -Eei "s/@JABBER_HOST@/$JABBER_HOST/g" /etc/nginx/nginx.conf

if [[ -f /pre_exec_hook.sh ]]; then
	/pre_exec_hook.sh $RUN_AS $RUN_AS_GROUP
fi

exec /usr/bin/supervisord -c /etc/supervisord.conf
