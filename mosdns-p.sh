
    if [[ $(uname -m) == "aarch64" ]]; then
        arch="arm64"
    elif [[ $(uname -m) == "x86_64" ]]; then
        arch="amd64"
    else
        arch="未知"
        exit 0
    fi
    echo "系统架构是：$arch"
    mosdns_host="https://github.com/IrineSistiana/mosdns/releases/download/v5.3.1/mosdns-linux-$arch.zip"
    apt update && apt -y upgrade || { echo "更新失败！退出脚本"; exit 1; }
    apt install curl wget tar gawk sed cron unzip nano -y || { echo "更新失败！退出脚本"; exit 1; }
    echo -e "\n设置时区为Asia/Shanghai"
    timedatectl set-timezone Asia/Shanghai || { echo -e "\e[31m时区设置失败！退出脚本\e[0m"; exit 1; }
    echo -e "\e[32m时区设置成功\e[0m"
    echo "开始下载 mosdns"
    wget "${mosdns_host}" || { echo -e "\e[31m下载失败！退出脚本\e[0m"; exit 1; }
    echo "开始解压"
    unzip ./mosdns-linux-$arch.zip 
    echo "复制 mosdns 到 /usr/bin"
    sleep 1
    cp -rv ./mosdns /usr/bin
    chmod 0777 /usr/bin/mosdns 
    echo -e "\n自定义设置（以下设置可直接回车使用默认值）"
    read -p "输入sing-box入站地址端口（默认10.10.10.147:6666）：" uiport
    uiport="${uiport:-10.10.10.147:6666}"
    echo -e "已设置Singbox入站地址：\e[36m$uiport\e[0m"
    read -p "输入sing-box sock5地址端口（默认10.10.10.147:7891）：" sock5port
    uiport="${sock5port:-10.10.10.147:7891}"
    echo -e "已设置sock5：\e[36m$sock5port\e[0m"
    echo "关闭53端口监听"
    sed -i '/^#*DNSStubListener/s/#*DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
    systemctl restart systemd-resolved.service
    echo "配置mosdns规则"
    sleep 1
    mkdir /etc/mosdns
    cd /etc/mosdns
    wget -O mosdns.zip https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/mosdns-p.zip
    unzip mosdns.zip
    echo "配置mosdns"
    sed -i "s/- addr: 10.10.10.147:6666/- addr: ${uiport}/g" /etc/mosdns/config.yaml
    sed -i "s/socks5: 10.10.10.147:7891/socks5: ${sock5port}/g" /etc/mosdns/config.yaml
    echo "设置mosdns开机自启动"
    mosdns service install -d /etc/mosdns -c /etc/mosdns/config.yaml
    echo "mosdns开机启动完成"
    sleep 1
    systemctl restart mosdns
    sleep 2
echo "=================================================================="
echo -e "\t\t\Mosdns fake安装完成"
echo -e "\t\t\tPowered by www.herozmy.com 2024"
echo -e "\n"
echo -e "本脚本仅适用于学习与研究等个人用途，请勿用于任何违反国家法律的活动！"
echo "=================================================================="
