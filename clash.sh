#!/bin/bash



install_clash_config() {

    echo "创建 /etc/clash 目录"
    sleep 1
    mkdir /etc/clash >/dev/null 2>&1
    cd /etc/clash
    wget -O config.yaml https://file.herozmy.com/File/sing-box/config_json/clash_config.yaml
    sed -i "s|^external-controller: :.*|external-controller: :$uiport|" /etc/clash/config.yaml
    
# 如果设置的端口是53，则关闭系统的53端口并重启systemd-resolved服务
    if [ "$dnsport" -eq 53 ]; then
        echo "关闭系统53端口..."
        sed -i '/^#*DNSStubListener/s/#*DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
        systemctl restart systemd-resolved.service
        echo "系统53端口已关闭，systemd-resolved服务已重启。"
    fi
    sed -i "s/listen: 0.0.0.0:53/listen: 0.0.0.0:$dnsport/" /etc/clash/config.yaml
    sed -i "s|^subscribe-url:.*|subscribe-url: $suburl|" /etc/clash/config.yaml
    sed -i "s|url=机场订阅|url=$suburl|" /etc/clash/config.yaml
    #安装metacubexd面板
wget https://github.com/MetaCubeX/metacubexd/releases/download/v1.138.1/compressed-dist.tgz
mkdir -p /etc/clash/ui/metacubexd
tar -xzvf compressed-dist.tgz -C /etc/clash/ui/metacubexd
rm compressed-dist.tgz
systemctl start clash
sleep 1
}
    
check_interfaces() {
    interfaces=$(ip -o link show | awk -F': ' '{print $2}')
    # 输出物理网卡名称
    for interface in $interfaces; do
        # 检查是否为物理网卡（不包含虚拟、回环等），并排除@符号及其后面的内容
        if [[ $interface =~ ^(en|eth).* ]]; then
            interface_name=$(echo "$interface" | awk -F'@' '{print $1}')  # 去掉@符号及其后面的内容
            echo "您的网卡是：$interface_name"
            valid_interfaces+=("$interface_name")  # 存储有效的网卡名称
        fi
    done
    # 提示用户选择
    read -p "脚本自行检测的是否是您要的网卡？(y/n): " confirm_interface
    if [ "$confirm_interface" = "y" ]; then
        selected_interface="$interface_name"
        echo "您选择的网卡是: $selected_interface"
    elif [ "$confirm_interface" = "n" ]; then
        read -p "请自行输入您的网卡名称: " selected_interface
        echo "您输入的网卡名称是: $selected_interface"
    else
        echo "无效的选择"
    fi
}
    
customize_settings() {
    echo "自定义设置（以下设置可直接回车使用默认值）"
    read -p "输入clash webui端口（默认9090）：" uiport
    uiport="${uiport:-9090}"
    echo "已设置ui端口：$uiport"
    
    read -p "请输入DNS监听端口 (默认53) ：" dnsport
    dnsport="${dnsport:-53}"
# 显示已设置的DNS监听端口
    echo "已设置DNS监听端口：$dnsport"

    read -p "输入订阅连接：" suburl
    suburl="${suburl:-https://}"
    echo "已设置订阅连接地址：$suburl"
    
}

apt update
apt install unzip git nftables make curl wget gzip -y

    # 判断 CPU 架构
if [[ $(uname -m) == "aarch64" ]]; then
    arch="armv8"
elif [[ $(uname -m) == "x86_64" ]]; then
    arch="amd64"
else
    arch="未知"
    exit 0
fi

customize_settings
check_interfaces
echo "系统架构是：$arch"

    #拉取github每日凌晨自动编译的核心
    wget -O mihomo-linux-$arch.tar.gz  https://raw.githubusercontent.com/52shell/herozmy-private/main/mihomo-alpha/mihomo-linux-$arch.tar.gz
    sleep 1
    echo -e "下载完成，开始安装"
    sleep 1
    tar -zxvf mihomo-linux-$arch.tar.gz
    chmod u+x clash
    echo "复制 clash 到 /usr/bin"
    cp clash /usr/bin 
    sleep 1
    echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
    sleep 1
    touch /etc/systemd/system/clash.service
echo "[Unit]
Description=clash auto run
 
[Service]
Type=simple
 
ExecStart=/usr/bin/clash -d /etc/clash/
 
[Install]
WantedBy=default.target" >> /etc/systemd/system/clash.service
install_clash_config
#创建clash-route服务
sleep 1
touch /etc/systemd/system/clash-route.service
echo "[Unit]
Description=Clash TProxy Rules
After=network.target
Wants=network.target

[Service]
User=root
Type=oneshot
RemainAfterExit=yes
# there must be spaces before and after semicolons
ExecStart=/sbin/ip rule add fwmark 1 table 100 ; /sbin/ip route add local default dev lo table 100 ; /sbin/ip -6 rule add fwmark 1 table 101 ; /sbin/ip -6 route add local ::/0 dev lo table 101
ExecStop=/sbin/ip rule del fwmark 1 table 100 ; /sbin/ip route del local default dev lo table 100 ; /sbin/ip -6 rule del fwmark 1 table 101 ; /sbin/ip -6 route del local ::/0 dev lo table 101

[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/clash-route.service
#写入nftables配置文件
sleep 1
echo "table inet clash {
	set local_ipv4 {
		type ipv4_addr
		flags interval
		elements = {
			10.0.0.0/8,
			127.0.0.0/8,
			169.254.0.0/16,
			172.16.0.0/12,
			192.168.0.0/16,
			240.0.0.0/4
		}
	}

	set local_ipv6 {
		type ipv6_addr
		flags interval
		elements = {
			::ffff:0.0.0.0/96,
			64:ff9b::/96,
			100::/64,
			2001::/32,
			2001:10::/28,
			2001:20::/28,
			2001:db8::/32,
			2002::/16,
			fc00::/7,
			fe80::/10
		}
	}

	chain clash-tproxy {
		fib daddr type { unspec, local, anycast, multicast } return
		ip daddr @local_ipv4 return
		ip6 daddr @local_ipv6 return
		udp dport { 123 } return
		meta l4proto { tcp, udp } meta mark set 1 tproxy to :7896 accept
	}

	chain clash-mark {
		fib daddr type { unspec, local, anycast, multicast } return
		ip daddr @local_ipv4 return
		ip6 daddr @local_ipv6 return
		udp dport { 123 } return
		meta mark set 1
	}

	chain mangle-output {
		type route hook output priority mangle; policy accept;
		meta l4proto { tcp, udp } skgid != 997 ct direction original jump clash-mark
	}

	chain mangle-prerouting {
		type filter hook prerouting priority mangle; policy accept;
		iifname { lo, $selected_interface } meta l4proto { tcp, udp } ct direction original jump clash-tproxy
	}
}" >> /etc/nftables.conf
    sleep 1
    echo "Nftables规则生效"
    sleep 1
    nft -f /etc/nftables.conf
    echo "设置相关服务自启动"
    systemctl enable --now clash-route
    systemctl enable clash
    
    