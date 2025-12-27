#!/bin/bash

IP=$(ip -4 addr show | grep -oP '(?<=inet ).*(?=/)' | grep -v '127.0.0.1' | head -n 1)

curl "http://10.1.99.100:801/eportal/portal/login?callback=dr1003&login_method=运营商编号&user_account=%2C0%2C这里填学号%40cmcc&user_password=这里填连校园网的密码&wlan_user_ip=${IP}&wlan_user_ipv6=&wlan_user_mac=000000000000&wlan_ac_ip=&wlan_ac_name=&jsVersion=4.1.3&terminal_type=1&lang=zh-cn&v=520&lang=zh" \
  -H 'Accept: */*' \
  -H 'Accept-Language: zh-CN,zh;q=0.9' \
  -H 'Connection: keep-alive' \
  -H 'Referer: http://10.1.99.100/' \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36' \
  --insecure

