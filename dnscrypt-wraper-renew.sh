#! /bin/sh

# This  script renews the certificates and keys indicating the path to the  dnscrypt-wrapper directory and the path to a directory to create / renew  the keys and certificates. 
# You may use this script by itself, with no accompanying scripts. This fork does all the tasks required. You may configure it in its header and create a cronjob to run it every
# 12 hours. DNS clients with the old certificates will suffer no service disruption on renewals as they will still be valid for 12 more hours.
# The script will start dnscrypt-wrapper if it is not running. To use an unprivileged user you must adapt the paths or configure the permissions.

# Crontab every 12 hours: * */12 * * * /opt/dnscrypt-wrapper/dnscrpyt-wraper-renew.sh 1>&1

######### CONFIGURATION #########

KEYS_DIR="/opt/dnscrypt-wrapper"         # Public and private server keys (Never renew these two files): /opt/dnscrypt-wrapper
STKEYS_DIR="${KEYS_DIR}/keys"            # Certificate and private key to renew: /opt/dnscrypt-wrapper/keys
PORT="553"                               # DNSCrpyt server port.
RESOLVER="8.8.4.4:53"                    # DNS server that will receive the DNS query.
LOGS="/var/log/dnscrypt-wrapper"	 # Logs.

################################

prune() {
    find "$STKEYS_DIR" -type f -mtime 1 -exec rm -f {} \;
}

rotation_needed() {
    if [ ! -f "${STKEYS_DIR}/dnscrypt.cert" ]; then
        echo true
    else
        if [ $(find "$STKEYS_DIR" -type f -cmin -720 -print -quit | wc -l | sed 's/[^0-9]//g') -le 0 ]; then
            echo true
        else
            echo false
        fi
    fi
}

new_key() {
    ts=$(date '+%s')
    /opt/dnscrypt-wrapper/dnscrypt-wrapper --gen-crypt-keypair \
        --crypt-secretkey-file="${STKEYS_DIR}/${ts}.key" &&
    /opt/dnscrypt-wrapper/dnscrypt-wrapper --gen-cert-file \
        --provider-publickey-file="${KEYS_DIR}/public.key" \
        --provider-secretkey-file="${KEYS_DIR}/secret.key" \
        --crypt-secretkey-file="${STKEYS_DIR}/${ts}.key" \
        --provider-cert-file="${STKEYS_DIR}/${ts}.cert" \
        --cert-file-expire-days=1 && \
    mv -f "${STKEYS_DIR}/${ts}.cert" "${STKEYS_DIR}/dnscrypt.cert"
    chown -R dnscrypt:dnscrypt /opt/dnscrypt-wrapper/
    echo "$(date) New key and certificate generated: ${ts}.cert y ${ts}.key" >> /var/log/dnscrypt-wrapper
}

stkeys_files() {
    res=""
    for file in $(ls "$STKEYS_DIR"/[0-9]*.key); do
        res="${res}${file},"
    done
    echo "$res"
}

renew(){
   if [ ! -f "$KEYS_DIR/provider_name" ]; then
   	exit 1
   fi


   mkdir -p "$STKEYS_DIR"
   prune

   if [ $(rotation_needed) = true ]; then
	new_key
	/usr/bin/killall dnscrypt-wrapper
	echo "$(date) Rotation of keys: $(stkeys_files)" >> /var/log/dnscrypt-wrapper
	exec /opt/dnscrypt-wrapper/dnscrypt-wrapper -d --logfile=$LOGS --user=dnscrypt --listen-address=[::]:$PORT --resolver-address=$RESOLVER --provider-name="$provider_name"  --provider-cert-file="${STKEYS_DIR}/dnscrypt.cert" --crypt-secretkey-file=$(stkeys_files)
fi
}

provider_name=$(cat "$KEYS_DIR/provider_name")
pids=`ps ax|egrep "$provider_name" | grep -v grep | awk ' { print $1 }'`

if [ "$pids" != "" ]; then
        renew
else   
	stkeys_files
	echo "$(date) Service dnscrypt-wrapper started." >> /var/log/dnscrypt-wrapper
	exec /opt/dnscrypt-wrapper/dnscrypt-wrapper -d --logfile=$LOGS --user=dnscrypt --listen-address=[::]:$PORT --resolver-address=$RESOLVER --provider-name="$provider_name"  --provider-cert-file="${STKEYS_DIR}/dnscrypt.cert" --crypt-secretkey-file=$(stkeys_files)
fi
