# AutoLoginToSchoolWIFI

用systemd写的后台自动连接校园网的



目前是只写了开机自动登陆认证，还没有设置timer



> service放在 `/etc/systemd/system/` 路径，shell脚本放在`/usr/local/bin/`



## 记得shell脚本中自己的学号和密码,运行商填进去,不然没法认证
## 根据运营商填 login_method 的值
> 中国移动`login_method=1`,中国电信`login_method=2`,中国联通`login_method=3`,无锡学院`login_method=4`

```bash
sudo chmod +x /usr/local/bin/loginWifi.sh  #添加可执行权限

sudo systemctl daemon-reload  #重新加载服务配置文件
sudo systemctl enable loginToSchoolWifi.service #设置服务为开机自启
sudo systemctl start loginToSchoolWifi.service  #立即启动该服务
sudo systemctl status loginToSchoolWifi.service  #查看该服务的当前状态和最近日志

journalctl -u loginToSchoolWifi.service  #查看所有日志

journalctl -u loginToSchoolWifi.service -b #查看启动后的日志

ip -4 addr show | grep -oP '(?<=inet ).*(?=/)' | grep -v '127.0.0.1' | head -n 1  #获取ipv4地址
```


```bash
[wanli@archlinux ~]$ cd /etc/systemd/system/
[wanli@archlinux system]$ sudo touch loginToSchoolWifi.service
[sudo] wanli 的密码：
[wanli@archlinux system]$ nano
[wanli@archlinux system]$ sudo nano loginToSchoolWifi.service
[wanli@archlinux system]$ cd /usr/local/bin/
[wanli@archlinux bin]$ sudo touch loginWifi.sh
[wanli@archlinux bin]$ sudo nano loginWifi.sh
[wanli@archlinux bin]$ sudo chmod +x /usr/local/bin/loginWifi.sh 
[wanli@archlinux bin]$ sudo systemctl daemon-reload  #重新加载服务配置文件
sudo systemctl enable loginToSchoolWifi.service #设置服务为开机自启
sudo systemctl start loginToSchoolWifi.service
Created symlink '/etc/systemd/system/multi-user.target.wants/loginToSchoolWifi.service' → '/etc/systemd/system/loginToSchoolWifi.service'.
[wanli@archlinux bin]$ 
```
