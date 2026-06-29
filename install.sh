#!/bin/bash

echo "请选择运营商："
echo "1. 中国移动"
echo "2. 中国电信"
echo "3. 中国联通"
echo "4. 无锡学院"

read -p "请输入运营商编号: " id
read -p "请输入学号: " acc
read -sp "请输入校园网密码: " pwd
echo

DEFAULT_USER=$USER

read -p "请输入电脑的系统用户名 (用于桌面通知) [默认: ${DEFAULT_USER}]: " sys_user
sys_user=${sys_user:-$DEFAULT_USER}

case "$id" in
    1)
        suffix="%40cmcc"
        ;;
    2)
        suffix="%40telecom"
        ;;
    3)
        suffix="%40unicom"
        ;;
    4)
        suffix=""
        ;;
    *)
        echo "运营商编号错误！"
        exit 1
        ;;
esac

# ================= 1. 生成核心认证脚本 =================
cat > login-wifi-service.sh <<EOF
#!/bin/bash

IP=\$(ip -4 addr show | grep -oP '(?<=inet ).*(?=/)' | grep -v '127.0.0.1' | head -n 1)

result=\$(curl -sS "http://10.1.99.100:801/eportal/portal/login?callback=dr1003&login_method=1&user_account=%2C0%2C${acc}${suffix}&user_password=${pwd}&wlan_user_ip=\${IP}&wlan_user_ipv6=&wlan_user_mac=000000000000&wlan_ac_ip=&wlan_ac_name=&jsVersion=4.1.3&terminal_type=1&lang=zh-cn&v=\$(date +%s)&lang=zh" \\
  -H 'Accept: */*' \\
  -H 'Accept-Language: zh-CN,zh;q=0.9' \\
  -H 'Connection: keep-alive' \\
  -H 'Referer: http://10.1.99.100/' \\
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36' \\
  --insecure)

echo "\$(date)"
echo "\$result" 

if [[ "\$result" == *fail* ]]; then
    exit 1
fi

exit 0
EOF

echo "已生成 login-wifi-service.sh"

# ================= 2. 生成 NetworkManager 触发脚本 =================
cat > wxxy-wifi-login.sh <<EOF
#!/bin/bash

INTERFACE=\$1
ACTION=\$2

# 如果不是 i-wxxy 连接成功，直接退出
if [ "\$ACTION" != "up" ] || [ "\$CONNECTION_ID" != "i-wxxy" ]; then
    exit 0
fi

# 用 ( ) & 将任务丢到后台，防止阻塞 NetworkManager
(
    # 读取系统运行时间（秒），去除小数部分
    SYS_UPTIME=\$(cut -d. -f1 /proc/uptime)

    # 如果开机不足 120 秒，判定为刚开机，强制休眠 5 秒等网络底层彻底就绪
    if [ "\$SYS_UPTIME" -lt 120 ]; then
        sleep 5
    fi

    SCRIPT_PATH="/usr/bin/login-wifi-service.sh"
    USERNAME="${sys_user}"
    USER_ID=\$(id -u "\$USERNAME") 

    START_TIME=\$(date +%s)
    LOGIN_SUCCESS=0

    # 2分钟内连接失败就一直不断尝试 (加入 sleep 1 防止 CPU 满载和过度请求)
    while [ \$((\$(date +%s) - START_TIME)) -lt 10 ]; do
        su - "\$USERNAME" -c "bash \$SCRIPT_PATH" >> /var/log/wxxy-script.log 2>&1
        if [ \$? -eq 0 ]; then
            LOGIN_SUCCESS=1
            break
        fi
        # sleep 1
    done

    echo LOGIN_SUCCESS \${LOGIN_SUCCESS} >> /var/log/wxxy-script.log 2>&1

    # 根据登录结果动态分配通知内容
    if [ \$LOGIN_SUCCESS -eq 1 ]; then
        NOTIFY_TITLE="i-wxxy 欢迎回来"
        NOTIFY_MSG="桌面加载完毕，校园网已就绪！"
        NOTIFY_ICON="/home/${sys_user}/.local/share/icons/i-wxxy-login/success.png"
    else
        NOTIFY_TITLE="i-wxxy 认证异常"
        NOTIFY_MSG="请检查网络连接，查看 /var/log/wxxy-script.log"
        NOTIFY_ICON="/home/${sys_user}/.local/share/icons/i-wxxy-login/fail.png"
    fi

    sudo -u "\$USERNAME" env \\
                DISPLAY=:0 \\
                DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/\${USER_ID}/bus" \\
                notify-send "\$NOTIFY_TITLE" "\$NOTIFY_MSG" -i "\$NOTIFY_ICON"

) &
EOF


echo "已生成 wxxy-wifi-login.sh"

# ================= 3. 部署并赋权 =================
mkdir -p ~/.local/share/icons/i-wxxy-login
cp fail.png ~/.local/share/icons/i-wxxy-login
cp success.png ~/.local/share/icons/i-wxxy-login

sudo mv login-wifi-service.sh /usr/bin/
sudo mv wxxy-wifi-login.sh /etc/NetworkManager/dispatcher.d/

sudo chmod +x /usr/bin/login-wifi-service.sh
sudo chmod +x /etc/NetworkManager/dispatcher.d/wxxy-wifi-login.sh

sudo chown root:root /etc/NetworkManager/dispatcher.d/wxxy-wifi-login.sh

sudo systemctl enable --now NetworkManager-dispatcher.service

echo "部署完成！"



# # ================= 4. 配置用户登录自启 (XDG Autostart) =================
# # 针对在登录界面停留较久，或者注销后重新登录的情况
# echo "正在配置用户登录自启..."

# # 确保自启目录存在
# AUTOSTART_DIR="/home/${sys_user}/.config/autostart"
# sudo -u "${sys_user}" mkdir -p "$AUTOSTART_DIR"

# # 创建桌面自启动项
# # 登录时检查当前 Wi-Fi 是不是 i-wxxy，如果是，直接执行认证并弹窗
# sudo -u "${sys_user}" tee "$AUTOSTART_DIR/wxxy-wifi-login.desktop" > /dev/null <<EOF
# [Desktop Entry]
# Type=Application
# Name=WXXY WiFi Auto Login
# Comment=用户登录时自动认证校园网

# Exec=bash -c 'sleep 2;if nmcli -t -f active,ssid dev wifi | grep -q "^yes:i-wxxy$"; then /usr/bin/login-wifi-service.sh && notify-send "i-wxxy 欢迎回来" "桌面加载完毕，校园网已就绪！" -i network-wireless-connected || notify-send "i-wxxy 认证异常" "请检查网络连接" -i dialog-error; fi'
# Hidden=false
# NoDisplay=false
# X-GNOME-Autostart-enabled=true
# EOF

# echo "用户登录自启配置完成！"
