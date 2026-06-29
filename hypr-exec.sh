#! /bin/bash

# sleep 2;

DEFAULT_USER=$USER

if nmcli -t -f active,ssid dev wifi | grep -q "^yes:i-wxxy$"; then /usr/bin/login-wifi-service.sh && notify-send "i-wxxy 欢迎回来" "桌面加载完毕，校园网已就绪！" -i "/home/${DEFAULT_USER}/.local/share/icons/i-wxxy-login/success.png" || notify-send "i-wxxy 认证异常" "请检查网络连接" -i "/home/${DEFAULT_USER}/.local/share/icons/i-wxxy-login/fail.png"; fi



