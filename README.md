# dnscrpyt-wraper-renew.sh Automatically renew certificates and keys in dnscrypt-wrapper.


**dnscrypt-wrapper**: https://github.com/cofyc/dnscrypt-wrapper

The shellscript dnscrpyt-wraper-renew.sh renews the certificates and keys indicating the path to the dnscrypt-wrapper directory and the path to a directory to create / renew  the keys and certificates. 
You may use this script by itself, with no accompanying scripts. This fork does all the tasks required. 

You may configure it in its header and create a cronjob to run it every 12 hours. DNS clients with the old certificates will suffer no service disruption on renewals as they will still be valid for 12 more hours.
The script will start dnscrypt-wrapper if it is not running.

To use an unprivileged user you must adapt the paths or configure the permissions.

Crontab example.
```bash
* */12 * * * /opt/dnscrypt-wrapper/dnscrpyt-wraper-renew.sh 1>&1
```
