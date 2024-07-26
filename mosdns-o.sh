    
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
    apt install curl wget git tar gawk sed cron unzip nano -y || { echo "更新失败！退出脚本"; exit 1; }
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
    echo "关闭53端口监听"
    sed -i '/^#*DNSStubListener/s/#*DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
    systemctl restart systemd-resolved.service
    echo "配置mosdns规则"
    sleep 1
    git init
    git remote add -f origin https://github.com/52shell/sing-box-mosdns-fakeip.git
    git config core.sparsecheckout true
    echo 'mosdns' > .git/info/sparse-checkout
    git pull origin main
    cd /root && mv mosdns /etc/
    echo "配置mosdns"
    sed -i "s/- addr: 10.10.10.147:6666/- addr: ${uiport}/g" /etc/mosdns/config.yaml
    echo "设置mosdns开机自启动"
    mosdns service install -d /etc/mosdns -c /etc/mosdns/config.yaml
    echo "mosdns开机启动完成"
    sleep 1
    systemctl restart mosdns
    sleep 2
    echo "是否安装 mosdns webui y/n"
    read choice
    if [ "$choice" = "y" ]; then
cd /root
wget https://github.com/grafana/loki/releases/download/v3.1.0/loki_3.1.0_amd64.deb

dpkg -i loki_3.1.0_amd64.deb    

# 安装必需的软件包
apt-get install -y adduser libfontconfig1 musl

# 下载并安装 Grafana Enterprise
wget https://dl.grafana.com/enterprise/release/grafana-enterprise_11.0.0_amd64.deb
dpkg -i grafana-enterprise_11.0.0_amd64.deb

# 重新加载 systemd 并启用/启动 Grafana 服务器
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server
apt-get install -y prometheus
# 添加 mosdns 任务配置
cat << EOF | tee -a /etc/prometheus/prometheus.yml
  - job_name: mosdns
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:8338']
EOF
# 重启 Prometheus
systemctl restart prometheus

curl --proto '=https' --tlsv1.2 -sSfL https://sh.vector.dev | bash

rm -f /root/.vector/config/vector.yaml

curl -L https://github.com/KHTdhl/AIO/releases/download/v1.0/vector.yaml -o /root/.vector/config/vector.yaml

cd /etc/systemd/system/

touch vector.service

cat << 'EOF' > vector.service
[Unit]
Description=Vector Service
After=network.target

[Service]
Type=simple
User=root
ExecStartPre=/bin/sleep 10
ExecStartPre=/bin/mkdir -p /tmp/vector
ExecStart=/root/.vector/bin/vector --config /root/.vector/config/vector.yaml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

sudo systemctl enable vector

echo "Vector 配置文件已更新"
(crontab -l 2>/dev/null; echo "0 0 * * 0 sudo truncate -s 0 /etc/mosdns/mosdns.log && /etc/mosdns/mos_rule_update.sh") | crontab -

echo "定时更新规则与清理日志添加完成"

local_ip=$(hostname -I | awk '{print $1}')

# 打印 IP 地址
echo "机器将在5秒后重启，重启后打开：$local_ip:3000,进入ui管理界面，后续参考孔佬教程"

sleep 6

reboot
    
elif [ "$choice" = "n" ]; then
    install_over
fi

install_over(){   
echo "=================================================================="
echo -e "\t\t\Mosdns fake安装完成"
echo -e "\t\t\tPowered by www.herozmy.com 2024"
echo -e "\n"
echo -e "温馨提示:\nMosdns网关自行配置为sing-box，dns随意"
echo -e "本脚本仅适用于学习与研究等个人用途，请勿用于任何违反国家法律的活动！"
echo "=================================================================="
}


