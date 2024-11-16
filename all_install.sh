#!/bin/bash
##定义地址
rm -rf $0
script_host=https://raw.githubusercontent.com/herozmy/sing-box-mosdns-fakeip
tag=main
sub_host="https://sub-singbox.herozmy.com"
file_host="https://file.herozmy.com"
#del_sys="rm -rf /root/"
mkdir -p /tmp/install
tmpcache=tmp/install
download_dir="/tmp/moddnsui"
mkdir -p "$download_dir"
github_fake="https://github.com/herozmy/sing-box-mosdns-fakeip.git"
prometheus_url="https://github.com/prometheus/prometheus/releases"
loki_url="https://github.com/grafana/loki/releases"
local_ip=$(hostname -I | awk '{print $1}')
cleanup() {
     #eval $del_sys
     rm -rf /root/.git
     rm -rf /root/*
     exit 0
}
trap cleanup EXIT SIGINT

## 判断当前系统
check_os(){
 #获取系统发行版信息
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo -e "${red_text}无法确定当前系统，请使用Debian/Ubuntu/Alpine/armbian运行此脚本${reset}" >&2
    exit 1
fi

# 支持的系统
supported_systems=("ubuntu" "debian" "alpine")

# 未测试兼容性的系统
untested_systems=("arch" "armbian")

# 不支持的系统
unsupported_systems=("parch" "manjaro" "opensuse-tumbleweed" "centos" "fedora" "almalinux" "rocky" "oracle")

# 检测系统
if [[ " ${supported_systems[@]} " =~ " ${release} " ]]; then
    echo -e "${green_text}系统检测通过${reset}"
    main
elif [[ " ${untested_systems[@]} " =~ " ${release} " ]]; then
    echo -e "${red_text}${release}: 未测试兼容性${reset}"
    main
elif [[ " ${unsupported_systems[@]} " =~ " ${release} " ]]; then
    echo -e "${red_text}${release}: 系统检测未通过，不支持${reset}"
    exit 1
else
    echo -e "${red_text}你的系统不支持当前脚本，未通过兼容性测试${reset}\n"
    echo "请重新安装系统，推荐:"
    echo "- Ubuntu 20.04+"
    echo "- Debian 11+"
    echo "- Alpine 3.14+"
    exit 1
fi
}
# 定义颜色
red() {
    echo -e "\e[31m$1\e[0m"  # 红色文本
}

green() {
    echo -e "\n\e[1m\e[37m\e[42m$1\e[0m\n"  # 绿色背景，白色粗体文本
}

white() {
    echo -e "$1"  # 默认颜色文本
}

# 导出颜色函数，已供其他脚本使用
export -f red
export -f green
export -f white
export reset
# 定义颜色变量
export yellow='\e[1m\e[33m'  # 粗体黄色文本
export red_text='\e[31m'  # 红色文本
export green_text='\e[32m'  # 绿色文本
export reset='\e[0m'  # 重置颜色
export SYSTEM_RELEASE="$release" #导出系统变量
######### 脚本主菜单
main () {
#eval $del_sys
# 使用之前定义的颜色
green "========================================================================="
echo -e "\t\t╔════════════════════════════════════╗"
echo -e "\t\t       \e[1mLinux   Herozmy综合脚本\e[0m        "
echo -e "\t\t╚════════════════════════════════════╝"
echo -e "\t\t       Powered by www.herozmy.com 2024"
echo -e "\n"

echo "
-------------------------------------------------
    "
echo -e "         ${red_text}软路由透明代理方案 sing-box/mihomo + Mosdns${reset}"
echo "
-------------------------------------------------
    "
echo -e "1. ${yellow}TProxy Sing-Box | Mihomo Fake-ip ${reset}<官方内核 | Puer喵佬/Mihomo内核，原生支持机场订阅>"
echo -e "2. ${yellow}Mosdns Fake-ip分流 ${reset}"
echo -e "3. ${yellow}Metacube*WEBUI更新 ${reset}"
echo -e "4. ${yellow}Mosdns*WEBUI${reset}"
echo -e "5. ${yellow}卸载:Sing-BOX | Mihomo | MosDNS ${reset}"
echo -e "6. ${yellow}卸载: MosDNS*WEBUI卸载 ${reset}"
echo "
-------------------------------------------------
    "
echo -e "         ${green_text}自用小脚本${reset}"
echo "
-------------------------------------------------
    "
echo -e "11. ${yellow}Debian/Ubuntu设置静态ip${reset}"
echo -e "12. ${yellow}PVE一键创建VM虚拟机 (BY:飞叶)${reset}"
echo -e "13. ${yellow}PVE Cloud-init开启ssh远程登录${reset}"
echo -e "当前系统: ${green_text}${release}
ip地址:${local_ip}${reset}"
green "========================================================================="
    echo -e "${green_text}请选择${reset}:"
    read choice
    selected_option=""
    case $choice in
        1) 
        check_singbox && customize_settings && singbox_ui_install && install_singbox_service && install_singbox_tproxy ;;
        2) 
        selected_option="mosdns"
        check_singbox ;;
        3) singbox_ui_install ;;
        4) ui_install;;
        5) delect_singbox ;;
        6) uninstall_ui ;;
        11) cloud_vm_make ;;
        12) cloud_vm_make ;;
        13) ssh_config ;;
         *)
        echo "无效的选项，请重新运行脚本并选择有效的选项."
    ;;
esac
}
check_singbox(){
found_files=$(find /usr/local/bin/ -type f \( -name "mihomo" -o -name "sing-box" -o -name "sing-box-p" -o -name "mosdns" \))
if [ -n "$found_files" ]; then
    for file in $found_files; do
        filename=$(basename "$file")
    done
fi
if [ -f "/usr/local/bin/${filename}" ]; then
    echo -e "检测到已安装 ${green_text}${filename}${reset}"
  if [ "$selected_option" = "mosdns" ]; then
  red "回车继续${green_text}${selected_option}${reset} <y/n>"
  read -p "" which_mosdns
  if [ -z "$which_mosdns" ]; then
  install_mosdns && install_mosdns_config
  exit 0
  fi
  elif [ -f "/usr/local/bin/mosdns" ]; then
    echo -e "请问是想继续安装${green_text}sing-box/mihomo${reset}吗。
${green_text}回车确定${reset}
${yellow}否则停止脚本${reset}"
    read -p "" choice
    if [ -z "$choice" ]; then
    check_enter
    else
    exit 0
    fi   
  fi
    read -p "是否选择升级？(y/n): " which_singbox
    if [ "$which_singbox" = "y" ]; then  
        if [[ "${filename}" == "sing-box" ]]; then
            echo -e "请选择 编译安装或者二进制升级"
            echo -e "1. 编译"
            echo -e "2. 二进制"
            read -p "请输入选择 (1/2/0): " choice
            case "$choice" in
                1)
                    install_make_singbox
                    cp "$(go env GOPATH)/bin/sing-box" /usr/local/bin/ || { echo "复制文件失败！退出脚本"; exit 1; }
                    chmod +x /usr/local/bin/sing-box
                    ;;
                2)
                    install_singbox
                    mv sing-box-${VERSION}-linux-${ARCH}/sing-box /usr/local/bin/${selected_option} || { echo "移动 sing-box 失败！"; exit 1; }
                    chmod +x /usr/local/bin/${selected_option}
                    ;;
                0)
                    main
                    ;;
                *)
                    echo -e "无效选择，退出脚本"
                    exit 1
                    ;;
            esac
        elif [[ "${filename}" == "sing-box-p" ]]; then
            install_singbox_p
            mv ${tmpcache}/sing-box-p /usr/local/bin/ || { echo "移动 sing-box-p 失败！"; exit 1; }
            chmod +x /usr/local/bin/sing-box-p
        elif [[ "${filename}" == "mihomo" ]]; then
            install_mihomo
            mv /clash /usr/local/bin/mihomo
            chmod +x /usr/local/bin/mihomo
        elif [[ "${filename}" == "mosdns" ]]; then
            install_mosdns
            
        fi
        
        # 替换完成，重启服务
        if [[ "$SYSTEM_RELEASE" == "alpine" ]]; then
            rc-service ${filename} restart
        else
        echo -e "${green_text}重启服务程序${reset}"
            systemctl restart ${filename}
        fi
        exit 0
    else
        echo "已选择不升级，退出脚本。"
        exit 0  # 退出脚本
    fi
else
    if [[ "${selected_option}" == "mosdns" ]]; then
    install_mosdns && install_mosdns_config
    else
    check_enter

fi
fi

}
check_enter(){
    choose_singbox
    if [[ "$choice" == "1" ]]; then
        update_version
        install_make_singbox
        cp "$(go env GOPATH)/bin/sing-box" /usr/local/bin/ || { echo "复制文件失败！退出脚本"; exit 1; }
        chmod +x /usr/local/bin/sing-box
    elif [[ "$choice" == "2" ]]; then
        update_version
        install_singbox
        mv sing-box-${VERSION}-linux-${ARCH}/sing-box /usr/local/bin/${selected_option} || { echo "移动 sing-box 失败！"; exit 1; }
        chmod +x /usr/local/bin/${selected_option}
    elif [[ "$choice" == "3" ]]; then
        update_version
        install_singbox_p
        
        mv /${tmpcache}/sing-box-p /usr/local/bin/${selected_option} || { echo "移动 sing-box-p 失败！"; exit 1; }
        chmod +x /usr/local/bin/sing-box-p
        echo -e "${green_text}${selected_option} 安装完成${reset}"
    elif [[ "$choice" == "4" ]]; then
        update_version
        install_mihomo
        mv clash /usr/local/bin/mihomo
        chmod +x /usr/local/bin/mihomo
    else
        echo "无效的选择，退出脚本"
        exit 1
    fi

}
choose_singbox(){
    echo -e "请选择${green_text}程序${reset}"
    echo -e "${yellow}1. Sing-box 官核编译${reset}"
    echo -e "${yellow}2. Sing-box官核二进制文件${reset}"
    echo -e "${yellow}3. Sing-boxPuer喵佬二进制文件${reset}"
    echo -e "${yellow}4. Mihomo${reset}"
    echo -e "${yellow}0. 返回主菜单${reset}"
    read -p "请输入选择 (1/2/3/4/0): " choice
  
    case "$choice" in
        1)
            echo -e "当前选择: ${green_text}Sing-BOX${reset}编译安装"        
            selected_option="sing-box"
            #check_singbox
            ;;
        2)
            echo -e "当前选择: ${green_text} Sing-BOX${reset} Deb文件安装"
            selected_option="sing-box"
            #check_singbox
            ;;
        3)
            echo -e "当前选择: ${green_text}Sing-BOX ${reset}puer喵佬二进制文件安装"
            selected_option="sing-box-p"
            #check_singbox
            ;;
        4)
            echo -e "当前选择: ${green_text}Mihomo ${reset}"
            selected_option="mihomo"
            #check_singbox
            ;;
        0)
            main
            ;;
        *)
            echo -e "无效选择，退出脚本"
            exit 1
            ;;
    esac
}

update_version(){
    if [[ "${release}" == "alpine" ]]; then
        apk update
        apk add curl git build-base openssl-dev libevent-dev gawk nftables || { 
            echo "软件包安装失败！退出脚本"; 
            exit 1; 
        }
        setup-timezone -z Asia/Shanghai || { 
            echo "时区设置失败！退出脚本"; 
            exit 1; 
        }
    else
        apt update && apt -y upgrade || { 
            echo "更新失败！退出脚本"; 
            exit 1; 
        }
        apt -y install curl git gawk build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64 nftables || { 
            echo "软件包安装失败！退出脚本"; 
            exit 1; 
        }
        echo -e "\n设置时区为Asia/Shanghai"
        timedatectl set-timezone Asia/Shanghai || { 
            echo -e "\e[31m时区设置失败！退出脚本\e[0m"; 
            exit 1; 
        }
        echo -e "\e[32m时区设置成功\e[0m"
    fi

}

install_make_singbox(){
    echo -e "编译Sing-Box 最新版本"
    sleep 1
    echo -e "开始编译Sing-Box 最新版本"
    rm -rf /root/go/bin/*

    # 获取 Go 版本
    Go_Version=$(curl -s https://github.com/golang/go/tags | grep '/releases/tag/go' | head -n 1 | gawk -F/ '{print $6}' | gawk -F\" '{print $1}')
    if [[ -z "$Go_Version" ]]; then
        echo "获取 Go 版本失败！退出脚本"
        exit 1
    fi

    # 判断 CPU 架构
    case $(uname -m) in
        aarch64)
            arch="arm64"
            ;;
        x86_64)
            arch="amd64"
            ;;
        armv7l)
            arch="armv7"
            ;;
        armhf)
            arch="armhf"
            ;;
        *)
            echo "未知的 CPU 架构: $(uname -m)，退出脚本"
            exit 1
            ;;
    esac

    echo "系统架构是：$arch"
    wget -O /${tmpcache}/${Go_Version}.linux-$arch.tar.gz https://go.dev/dl/${Go_Version}.linux-$arch.tar.gz || { 
        echo "下载 Go 版本失败！退出脚本"; 
        exit 1; 
    }
    tar -C /usr/local -xzf /${tmpcache}/${Go_Version}.linux-$arch.tar.gz || { 
        echo "解压 Go 文件失败！退出脚本"; 
        exit 1; 
    }
    rm -f /${tmpcache}/${Go_Version}.linux-$arch.tar.gz  # 清理下载的文件

    # 设置 Go 环境变量
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/golang.sh
    source /etc/profile.d/golang.sh  # 立即生效

    # 编译 Sing-Box
    if ! go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@latest; then
        echo -e "Sing-Box 编译失败！退出脚本"
        exit 1
    fi
    echo -e "编译完成"
    sleep 1
}
install_singbox(){
set -e -o pipefail

ARCH_RAW=$(uname -m)
case "${ARCH_RAW}" in
    'x86_64')    ARCH='amd64';;
    'x86' | 'i686' | 'i386')     ARCH='386';;
    'aarch64' | 'arm64') ARCH='arm64';;
    'armv7l')   ARCH='armv7';;
    's390x')    ARCH='s390x';;
    *)          echo "Unsupported architecture: ${ARCH_RAW}"; exit 1;;
esac

VERSION=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep tag_name | cut -d ":" -f2 | sed 's/[\",v ]//g')
curl -Lo sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/download/v${VERSION}/sing-box-${VERSION}-linux-${ARCH}.tar.gz"
tar -zxvf sing-box.tar.gz

}
install_singbox_p(){
     # 判断 CPU 架构
if [[ $(uname -m) == "aarch64" ]]; then
    arch="armv8"
elif [[ $(uname -m) == "x86_64" ]]; then
    arch="amd64"
else
    arch="未知"
    exit 0
fi
echo "系统架构是：$arch"
    #拉取github每日凌晨自动编译的核心
    wget -O /${tmpcache}/sing-box-linux-$arch.tar.gz  https://raw.githubusercontent.com/herozmy/herozmy-private/main/sing-box-puernya/sing-box-linux-$arch.tar.gz
    sleep 1
    echo -e "下载完成，开始安装"
    sleep 1
    tar -zxvf /${tmpcache}/sing-box-linux-$arch.tar.gz -C /${tmpcache}/
    mv /${tmpcache}/sing-box /${tmpcache}/sing-box-p 



}

### 
singbox_ui_install(){
found_files=$(find /usr/local/bin/ -type f \( -name "mihomo" -o -name "sing-box" -o -name "sing-box-p"  \))
if [ -n "$found_files" ]; then
    for file in $found_files; do
        filename=$(basename "$file")
    done
fi
    UI_DIR="/etc/${filename}/ui"
    if [ -d "$UI_DIR" ]; then
        echo "更新 WEBUI..."
        rm -rf /etc/sing-box/ui
        git_ui
    else
        git_ui
    fi
}

# 检测并拉取 UI
git_ui(){
    if git clone https://github.com/metacubex/metacubexd.git -b gh-pages /etc/${filename}/ui; then
        echo -e "UI 源码拉取${green_text}成功${reset}。"
    else
        echo "拉取源码失败，请手动下载源码并解压至 /etc/${filename}/ui."
        echo "地址: https://github.com/metacubex/metacubexd"
    fi
}

### 输入订阅
customize_settings() {
    echo -e "是否选择生成配置？(y/n) ${green_text}生成配置文件需要添加机场订阅，如自建vps请选择n${reset}"
    read choice
if [ "$choice" = "y" ]; then
    read -p "输入订阅连接：" suburl
    suburl="${suburl:-https://}"
    echo "已设置订阅连接地址：$suburl"
    check_interfaces
if [ "$selected_option" = "sing-box" ]; then
    install_singbox_config
elif [ "$selected_option" = "mihomo" ]; then
    install_mihomo_config
else
    install_singbox_p_config
fi
elif [ "$choice" = "n" ]; then
    echo "请手动编写config配置文件"
fi    

}
install_mihomo_config() {  
    echo "创建 ${selected_option} 目录"
    sleep 1
    mkdir -p /etc/${selected_option}
    cd /etc/${selected_option}
    wget -O config.yaml https://github.com/herozmy/sing-box-mosdns-fakeip/raw/refs/heads/main/config/clash-fake-ip.yaml
    sed -i "s|url: '机场订阅'|url: '$suburl'|" /etc/mihomo/config.yaml
    sed -i "s|interface-name: eth0|interface-name: $selected_interface|" /etc/mihomo/config.yaml
}


install_singbox_config() {   
    echo "请选择："
    echo "1. tproxy_fake_ip O大原版 <适用机场多规则分流> 配合O大mosdns食用"
    echo "2. tproxy_fake_ip O大原版 <适用VPS自建模式>配合O大mosdns食用"
    read -p "请输入选项 [默认: 1]: " choice
    # 如果用户没有输入选择，则默认为1
    choice=${choice:-1}
    if [ $choice -eq 1 ]; then
        json_file="&file=https://raw.githubusercontent.com/herozmy/sing-box-mosdns-fakeip/main/config/fake-ip.json"
    elif [ $choice -eq 2 ]; then
        json_file="&file=https://raw.githubusercontent.com/herozmy/sing-box-mosdns-fakeip/main/fake-ip.json"
    else
        echo "无效的选择。"
        return 1
    fi
    curl -o config.json "${sub_host}/config/${suburl}${json_file}"    
    # 检查下载是否成功
    if [ $? -eq 0 ]; then
        # 移动文件到目标位置
        mkdir -p /etc/sing-box
        mv config.json /etc/sing-box/config.json
        echo "Sing-box配置文件写入成功！"
    else
        echo "下载文件失败，请检查网络连接或者URL是否正确。"
    fi    
}

install_singbox_p_config(){
# git拉取 srs文件，防止启动失败
(
    git init >/dev/null 2>&1 &&
    git remote add -f origin https://github.com/herozmy/sing-box-mosdns-fakeip.git &&
    git config core.sparsecheckout true &&
    echo 'singbox_rule' > .git/info/sparse-checkout &&
    git pull origin main
)
if [ $? -ne 0 ]; then
    echo "规则拉取失败"
    exit 1
fi
green "规则文件拉取成功"
rm -rf .git
mkdir -p /etc/${selected_option}/providers
mv /root/singbox_rule /etc/${selected_option}/rule
## 写入sing-box json配置文件
 if curl -o /etc/${selected_option}/config.json $file_host/script/config/sing-box_p.json; then
    green "配置文件下载成功"
    sed -i "s|\"download_url\": \"机场订阅\"|\"download_url\": \"$suburl\"|g" /etc/${selected_option}/config.json
else
    red "配置文件下载失败，请检查网络"
    exit 1
fi
}
#####sing-box自启动脚本
install_singbox_service() {
echo -e "配置系统服务文件"
sleep 1

if [[ "${release}" == "alpine" ]]; then
    # 检查 /etc/init.d/${selected_option} 是否存在
    if [ ! -f "/etc/init.d/${selected_option}" ]; then
        # 写入 sing-box 开机启动
        cat << EOF > /etc/init.d/${selected_option}
#!/sbin/openrc-run
name=\$RC_SVCNAME
description="${selected_option} service"

command="/usr/local/bin/${selected_option}"
command_args="-D /etc/${selected_option} -C /etc/${selected_option} run"
supervisor="supervise-daemon"

extra_started_commands="reload"

depend() {
    after net dns
}

reload() {
    ebegin "Reloading \$RC_SVCNAME"
    supervise-daemon "\$RC_SVCNAME" --signal HUP
    eend \$?
}
EOF

        if [ "$selected_option" = "mihomo" ]; then
            sed -i 's/command_args="-D \/etc\/mihomo -C \/etc\/mihomo run"/command_args="-d \/etc\/mihomo\/"/' /etc/init.d/mihomo
            chmod +x /etc/init.d/mihomo
            rc-service mihomo start
        fi

        chmod +x /etc/init.d/${selected_option}
        echo -e "${green_text}${selected_option} 服务脚本已创建"
    else
        echo "警告：${selected_option} 服务文件已存在，无需创建"
    fi
else
    # 检查服务文件是否存在，如果不存在则创建
    sing_box_service_file="/etc/systemd/system/${selected_option}.service"
    if [ ! -f "$sing_box_service_file" ]; then
        # 如果服务文件不存在，则创建
        cat << EOF > "$sing_box_service_file"
[Unit]
Description=$selected_option service

[Service]
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/${selected_option} run -c /etc/${selected_option}/config.json
Restart=on-failure
RestartSec=1800s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

        # 如果是 mihomo，则修改服务文件
        if [ "$selected_option" = "mihomo" ]; then
            sed -i '/CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE/,/LimitNOFILE=infinity/c\Type=simple\nExecStart=/usr/local/bin/mihomo -d /etc/mihomo/' "$sing_box_service_file"
            systemctl start mihomo
        fi

        echo "${selected_option} 服务创建完成"
    else
        # 如果服务文件已经存在，则给出警告
        echo "警告：${selected_option} 服务文件已存在，无需创建"
    fi
    systemctl daemon-reload
fi



        
}

install_singbox_tproxy() {
if [ "${release}" = "ubuntu" ]; then
    echo "当前系统为 ${green_text}Ubuntu 系统${reset}"
    
    ## 检查 /etc/systemd/resolved.conf 中是否已设置 DNSStubListener=no
    #if grep -q "^DNSStubListener=no" /etc/systemd/resolved.conf; then
        #echo "DNSStubListener 已经设置为 no, 无需修改"
    #else
        ## 修改 DNSStubListener 设置为 no
        #sed -i '/^#*DNSStubListener/s/#*DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
        #echo "DNSStubListener 已被设置为 no"
        
        ## 重启 systemd-resolved 服务
        #systemctl restart systemd-resolved.service
        #sleep 1
    #fi
    
    
    
   check_resolved 
fi


    echo "创建系统转发"
# 判断是否已存在 net.ipv4.ip_forward=1
    if ! grep -q '^net.ipv4.ip_forward=1$' /etc/sysctl.conf; then
        echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    fi

# 判断是否已存在 net.ipv6.conf.all.forwarding = 1
    if ! grep -q '^net.ipv6.conf.all.forwarding = 1$' /etc/sysctl.conf; then
        echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
    fi
    echo "系统转发创建完成"
    sleep 1
    echo -e "${green_text}开始创建nftables tproxy转发"

# 写入tproxy rule    

if [[ "${release}" == "alpine" ]]; then

    if [ ! -f "/etc/init.d/${selected_option}-route" ]; then
            # 创建 Alpine 的服务脚本
        cat << EOF > /etc/init.d/${selected_option}-route
#!/sbin/openrc-run

description="${selected_option}-route service"

depend() {
    need net
    after net
}

start() {
    echo "启动 ${selected_option}-route 服务"
    route_service_start_command
}

stop() {
    echo "停止 ${selected_option}-route 服务"
    route_service_stop_command
}

route_service_start_command() {
    /sbin/ip rule add fwmark 1 table 100
    /sbin/ip route add local default dev lo table 100
    /sbin/ip -6 rule add fwmark 1 table 101
    /sbin/ip -6 route add local ::/0 dev lo table 101
}

route_service_stop_command() {
    /sbin/ip rule del fwmark 1 table 100
    /sbin/ip route del local default dev lo table 100
    /sbin/ip -6 rule del fwmark 1 table 101
    /sbin/ip -6 route del local ::/0 dev lo table 101
}
EOF

        chmod +x /etc/init.d/${selected_option}-route
        echo -e "${green_text}已完成路由表添加"
    else
        echo -e"警告：${selected_option}-route 服务文件已存在，无需创建"
    fi
else

    if [ ! -f "/etc/systemd/system/${selected_option}-router.service" ]; then
        # 创建其他系统的服务文件
        cat <<EOF > "/etc/systemd/system/${selected_option}-router.service"
[Unit]
Description=sing-box TProxy Rules
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
WantedBy=multi-user.target
EOF
        echo -e "${green_text}${selected_option}-router 服务创建完成"
    else
        echo -e "${red_text}警告：${selected_option}-router 服务文件已存在，无需创建"
    fi
fi

####写入nftables

echo "" > "/etc/nftables.conf"
cat <<EOF > "/etc/nftables.conf"
#!/usr/sbin/nft -f
flush ruleset
table inet $selected_option {
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

  chain ${selected_option}-tproxy {
    fib daddr type { unspec, local, anycast, multicast } return
    ip daddr @local_ipv4 return
    ip6 daddr @local_ipv6 return
    udp dport { 123 } return
    meta l4proto { tcp, udp } meta mark set 1 tproxy to :7896 accept
  }

  chain ${selected_option}-mark {
    fib daddr type { unspec, local, anycast, multicast } return
    ip daddr @local_ipv4 return
    ip6 daddr @local_ipv6 return
    udp dport { 123 } return
    meta mark set 1
  }

  chain mangle-output {
    type route hook output priority mangle; policy accept;
    meta l4proto { tcp, udp } skgid != 1 ct direction original goto ${selected_option}-mark
  }

  chain mangle-prerouting {
    type filter hook prerouting priority mangle; policy accept;
    iifname { wg0, lo, $interface_name } meta l4proto { tcp, udp } ct direction original goto ${selected_option}-tproxy
  }
}
EOF
    echo -e "${green_text}nftables规则写入完成${reset}"
    if [[ "${release}" == "alpine" ]]; then
    cp /etc/nftables.nft /etc/nftables.nft.bak
    mv /etc/nftables.conf /etc/nftables.nft
    fi
    install_over
}
install_over() {
    echo -e "${green_text}启用相关服务${reset}"
    if [[ "${release}" == "alpine" ]]; then
   rc-update add ${selected_option}-route && rc-service ${selected_option}-route start
   rc-update add ${selected_option} && rc-service ${selected_option} start  >/dev/null 2>&1
   nft flush ruleset && nft -f /etc/nftables.nft && rc-service nftables restart && rc-update add nftables 
   else
    nft flush ruleset && nft -f /etc/nftables.conf && systemctl enable --now nftables && systemctl enable --now ${selected_option}-router && systemctl enable --now ${selected_option}
    fi
}

check_resolved(){
    if [ -f /etc/systemd/resolved.conf ]; then
        # 检测是否有未注释的 DNSStubListener 行
        dns_stub_listener=$(grep "^DNSStubListener=" /etc/systemd/resolved.conf)
        if [ -z "$dns_stub_listener" ]; then
            # 如果没有找到未注释的 DNSStubListener 行，检查是否有被注释的 DNSStubListener
            commented_dns_stub_listener=$(grep "^#DNSStubListener=" /etc/systemd/resolved.conf)
            if [ -n "$commented_dns_stub_listener" ]; then
                # 如果找到被注释的 DNSStubListener，取消注释并改为 no
                sed -i 's/^#DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
                systemctl restart systemd-resolved.service
                green "53端口占用已解除"
            else
                green "未找到53端口占用配置，无需操作"
            fi
        elif [ "$dns_stub_listener" = "DNSStubListener=yes" ]; then
            # 如果找到 DNSStubListener=yes，则修改为 no
            sed -i 's/^DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
            systemctl restart systemd-resolved.service
            green "53端口占用已解除"
        elif [ "$dns_stub_listener" = "DNSStubListener=no" ]; then
            # 如果 DNSStubListener 已为 no，提示用户无需修改
            green "53端口未被占用，无需操作"
        fi
    else
        green "/etc/systemd/resolved.conf 不存在，无需操作"
    fi

}
check_interfaces() {
    interfaces=$(ip -o link show | awk -F': ' '{print $2}')
    # 输出物理网卡名称
    for interface in $interfaces; do
        # 检查是否为物理网卡（不包含虚拟、回环等），并排除@符号及其后面的内容
        if [[ $interface =~ ^(en|eth).* ]]; then
            interface_name=$(echo "$interface" | awk -F'@' '{print $1}')  # 去掉@符号及其后面的内容
            echo -e "您的网卡是：${yellow}$interface_name${reset}"
            valid_interfaces+=("$interface_name")  # 存储有效的网卡名称
        fi
    done
    # 提示用户选择
    
    #read -p "脚本自行检测的是否是您要的网卡？(y/n): " confirm_interface
    #if [ "$confirm_interface" = "y" ]; then
        #selected_interface="$interface_name"
        #echo -e "您选择的网卡是: ${green_text}$selected_interface${reset}"
    #elif [ "$confirm_interface" = "n" ]; then
        #read -p "请自行输入您的网卡名称: " selected_interface
        #echo -e "您输入的网卡名称是: ${green_text}$selected_interface${reset}"
    #else
        #echo "无效的选择"
    #fi
}

install_mihomo(){

echo -e "Mihomo一键安装"
    case $(uname -m) in
        aarch64)
            arch="arm64"
            ;;
        x86_64)
            arch="amd64"
            ;;
        armv7l)
            arch="armv7"
            ;;
        armhf)
            arch="armhf"
            ;;
        *)
            echo "未知的 CPU 架构: $(uname -m)，退出脚本"
            exit 1
            ;;
    esac
    echo "系统架构是：$arch"
    #拉取github每日凌晨自动编译的核心
    wget -O mihomo-linux-$arch.tar.gz  https://raw.githubusercontent.com/herozmy/herozmy-private/main/mihomo-alpha/mihomo-linux-$arch.tar.gz
    sleep 1
    echo -e "下载完成，开始安装"
    sleep 1
    tar -zxvf mihomo-linux-$arch.tar.gz


}

################################sing-box安装结束################################
install_singbox_over() {
echo "=================================================================="
echo -e "\t\t\tSing-Box 安装完毕"
echo -e "\t\t\tPowered by www.herozmy.com 2024"
echo -e "\n"
echo -e "singbox运行目录为/etc/sing-box"
echo -e "singbox WebUI地址:http://ip:9090"
echo -e "Mosdns配置脚本：wget https://raw.githubusercontent.com/herozmy/sing-box-mosdns-fakeip/main/mosdns-o.sh && bash mosdns-o.sh"
echo -e "温馨提示:\n本脚本仅在 LXC ubuntu22.04 环境下测试，其他环境未经验证，仅供个人使用"
echo -e "本脚本仅适用于学习与研究等个人用途，请勿用于任何违反国家法律的活动！"
echo "=================================================================="
}
delect_singbox(){

if [ -f /usr/bin/loki ]; then
    echo -e "检测到系统已安装Mosdns UI面板，确定卸载? (y/n)"
    read -r check_ui
    case "$check_ui" in
        [yY])
    echo "开始卸载 MosdnsUi..."
    echo "停止MosDNS UI服务并删除"
    systemctl stop loki
    systemctl disable loki
    dpkg -r loki
    rm -rf /etc/loki /var/lib/loki /var/log/loki
    systemctl stop vector
    systemctl disable vector
    rm -rf /etc/vector
    rm -rf /etc/systemd/system/vector.service
    systemctl stop prometheus
    systemctl disable prometheus
    rm -rf /opt/prometheus
    systemctl stop grafana-server
    systemctl disable grafana-server
    dpkg -r grafana-server
    rm -rf /etc/grafana
    rm -rf /lib/systemd/system/grafana-server.service
    rm -rf /etc/systemd/system/grafana-server.service
    rm -rf /etc/systemd/system/multi-user.target.wants/grafana-server.service
    rm  -rf /etc/init.d/grafana-server
    apt autoremove --purge -y prometheus loki
    systemctl daemon-reload
    #systemctl reset-failed
    green "卸载Mosdns UI已完成"
    exit 0
            ;;
        [nN])
            echo "取消卸载，保留当前安装。"
            echo "返回主菜单"
            check_os
            ;;
        *)
            echo "无效输入，请输入 y 或 n。"
            ;;
    esac
elif [ -f /usr/local/bin/mosdns ]; then
    selected_option="mosdns"
else
    choose_singbox
fi



if [[ "${release}" == "alpine" ]]; then

    echo "关闭${selected_option}"
    rc-service ${selected_option} stop
    echo "卸载${selected_option}自启动"
    rc-update del ${selected_option}
    echo "关闭nftables防火墙规则" >/dev/null 2>&1
    rc-service nftables stop >/dev/null 2>&1
    rc-update del nftables >/dev/null 2>&1
    echo "关闭${selected_option}路由规则" >/dev/null 2>&1
    rc-service ${selected_option}-route stop >/dev/null 2>&1
    echo "卸载${selected_option}路由规则" >/dev/null 2>&1
    rc-update del ${selected_option}-route >/dev/null 2>&1
    rm -rf /etc/init.d/${selected_option}*
    rm -rf /etc/${selected_option}
    rm -rf /usr/local/bin/${selected_option}
    apk del sing-box  >/dev/null 2>&1
    green "卸载完成"
else
    echo "关闭${selected_option}"
    systemctl stop ${selected_option}
    echo "卸载${selected_option}自启动" >/dev/null 2>&1
    systemctl disable ${selected_option} >/dev/null 2>&1
    echo "关闭nftables防火墙规则" >/dev/null 2>&1
    systemctl stop nftables >/dev/null 2>&1
    echo "nftables防火墙规则" >/dev/null 2>&1
    systemctl disable nftables >/dev/null 2>&1
    echo "关闭${selected_option}路由规则" >/dev/null 2>&1
    systemctl stop ${selected_option}-router >/dev/null 2>&1
    echo "卸载${selected_option}路由规则" >/dev/null 2>&1
    systemctl disable ${selected_option}-router >/dev/null 2>&1
    echo "删除相关配置文件"
    apt autoremove sing-box -y >/dev/null 2>&1
    rm -rf /etc/systemd/system/${selected_option}*
    rm -rf /etc/${selected_option}
    rm -rf /usr/local/bin/${selected_option}
    green "卸载完成"
    fi
    echo "=================================================================="
    echo -e "\t\t\t ${selected_option} 卸载完成"
    echo -e "\n"
    echo "=================================================================="
exit 0
}


install_mosdns(){
if [[ $(uname -m) == "aarch64" ]]; then
        arch="arm64"
    elif [[ $(uname -m) == "x86_64" ]]; then
        arch="amd64"
    else
        arch="未知"
        exit 0
    fi
    echo "系统架构是：$arch"
    mosdns_host="https://github.com/IrineSistiana/mosdns/releases/download/v5.3.3/mosdns-linux-$arch.zip"
 if [[ "${release}" == "alpine" ]]; then
    apk update || { echo "更新失败！退出脚本"; exit 1; }
    apk add curl wget git tar gawk sed  unzip nano  || { echo "更新失败！退出脚本"; exit 1; }
    setup-timezone -z Asia/Shanghai || { echo "时区设置失败！退出脚本"; exit 1; }
    echo -e "\e[32m时区设置成功\e[0m"    
        else
    apt update && apt -y upgrade || { echo "更新失败！退出脚本"; exit 1; }
    apt install curl wget git tar gawk sed cron unzip nano -y || { echo "更新失败！退出脚本"; exit 1; }
    echo -e "\n设置时区为Asia/Shanghai"
    timedatectl set-timezone Asia/Shanghai || { echo -e "\e[31m时区设置失败！退出脚本\e[0m"; exit 1; }
    echo -e "\e[32m时区设置成功\e[0m"
        fi
    wget "${mosdns_host}" || { echo -e "\e[31m下载失败！退出脚本\e[0m"; exit 1; }
    echo "开始解压"
    unzip ./mosdns-linux-$arch.zip 
sleep 1
    mv -v ./mosdns /usr/local/bin/
    rm -rf mosdns-linux-$arch.zip
    chmod 0777 /usr/local/bin/mosdns    
}
 
install_mosdns_config(){   
    echo -e "\n自定义设置（以下设置可直接回车使用默认值）"
    read -p "输入sing-box入站地址端口（默认10.10.10.147:6666）：" uiport
    uiport="${uiport:-10.10.10.147:6666}"
    echo -e "已设置Singbox入站地址：\e[36m$uiport\e[0m"
    #echo "关闭53端口监听"
    #sed -i '/^#*DNSStubListener/s/#*DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
    #systemctl restart systemd-resolved.service
    check_resolved
    echo "配置mosdns规则"
    sleep 1
    echo -e "请选择Mosdns规则"
    echo -e "
   分流规则:
  0. 退出脚本
————————————————
  1. O佬分流规则
  2. PH佬分流规则
 "
    echo && read -p "请输入选择 [0-2]: " num
    case "${num}" in
    0)
        exit 0
        ;;
    1)
   (
    git init >/dev/null 2>&1 &&
    git remote add -f origin https://github.com/herozmy/sing-box-mosdns-fakeip.git &&
    git config core.sparsecheckout true &&
    echo 'mosdns' > .git/info/sparse-checkout &&
    git pull origin main
   )
        ;;
    2)
 (
    git init >/dev/null 2>&1 &&
    git remote add -f origin https://github.com/herozmy/sing-box-mosdns-fakeip.git &&
    git config core.sparsecheckout true &&
    echo 'mosdns-ph' > .git/info/sparse-checkout &&
    git pull origin main
    mv mosdns-ph mosdns
)
        ;;
    *)
        echo "请输入正确的数字 [0-2]"
        ;;
    esac

if [ $? -ne 0 ]; then
    echo "拉取失败，请重新拉取"
    exit 1
fi
    green "Mosdns规则拉取成功"
    cd /root && mv mosdns /etc/
    echo "配置mosdns"
    sed -i "s/- addr: 10.10.10.147:6666/- addr: ${uiport}/g" /etc/mosdns/config.yaml
    echo "设置mosdns开机自启动"
    mosdns service install -d /etc/mosdns -c /etc/mosdns/config.yaml
    echo "mosdns开机启动完成"
    sleep 1
    if [[ "${release}" == "alpine" ]]; then
    rc-update add mosdns && rc-service mosdns restart
    else    
    systemctl restart mosdns
    fi
    rm -rf /root/*
}

####pve cloud-init

ubuntu_VERSION_CHOOSE() {

    declare -A ubuntu_check_versions=(
        ["oracular"]="24.10"
        ["noble"]="24.04"
        ["jammy"]="22.04"
        ["focal"]="20.04"
        ["bionic"]="18.04"
    )

    ubuntu_check_order=("oracular" "noble" "jammy" "focal" "bionic")

    ubuntu_check_options=()
    for version in "${ubuntu_check_order[@]}"; do
        ubuntu_check_options+=("${version} (${ubuntu_check_versions[$version]})")
    done

    white "请选择Ubuntu版本："
    select ubuntu_check_choice in "${ubuntu_check_options[@]}"; do
        if [[ -n "${ubuntu_check_choice}" ]]; then
            ubuntu_check_version=$(echo "${ubuntu_check_choice}" | awk '{print $1}')
            ubuntu_check_version_number="${ubuntu_check_versions[$ubuntu_check_version]}"
            white "您选择了 ${ubuntu_check_version} (${ubuntu_check_version_number})"
            break
        else
            red "无效选择，请重试"
        fi
    done

    ubuntu_check_URL="https://cloud-images.ubuntu.com/${ubuntu_check_version}/"

    ubuntu_check_latest_date=$(curl -s ${ubuntu_check_URL} | grep -Eo 'href="[0-9]{8}/"' | sed 's/href="//;s/\///' | sort -r | head -n 1 | tr -d '"')

    if [ -z "$ubuntu_check_latest_date" ]; then
        red "无法获取最新版本日期"
    else
        white "最新版本日期: ${yellow}${ubuntu_check_latest_date} (Ubuntu ${ubuntu_check_version} ${ubuntu_check_version_number})"
        white "版本号: ${yellow}${ubuntu_check_version_number}${reset}"
    fi 

    UBUNTU_URL="https://cloud-images.ubuntu.com/${ubuntu_check_version}/${ubuntu_check_latest_date}/${ubuntu_check_version}-server-cloudimg-amd64.img"
    UBUNTU_FILENAME="/var/lib/vz/template/iso/cloud_ubuntu${ubuntu_check_version_number}.img"
    URL=$UBUNTU_URL
    FILENAME=$UBUNTU_FILENAME

}

#################################### debian 版本选择 #############################################
debian_VERSION_CHOOSE() {
    DEBIAN_URL="https://cloud.debian.org/images/cloud/bookworm/20231013-1532/debian-12-generic-amd64-20231013-1532.qcow2"
    DEBIAN_FILENAME="/var/lib/vz/template/iso/cloud_debian12.qcow2"

    URL=$DEBIAN_URL
    FILENAME=$DEBIAN_FILENAME
}   

#################################### 执行程序 #############################################
cloud_vm_make() {
    total_cpu_cores=$(grep -c '^processor' /proc/cpuinfo)

    # 询问用户选择镜像类型，默认选择Ubuntu
    while true; do
        white "请选择镜像类型:"
        white "1) Ubuntu [默认选项]"
        white "2) Debian 12"
        read -p "请选择: " os_choice
        os_choice=${os_choice:-1}
        if [[ $os_choice =~ ^[1-2]$ ]]; then
            break
        else
            red "无效选择，请输入1或2"
        fi
    done
    case $os_choice in
        1) ubuntu_VERSION_CHOOSE ;;
        2) debian_VERSION_CHOOSE ;;
    esac
    # 检查并输入虚拟机 ID
    while true; do
        read -p "请输入虚拟机ID (大于100): " vm_id
        if qm status $vm_id &>/dev/null || pct status $vm_id &>/dev/null; then
            red "虚拟机或LXC编号已存在，请输入其他编号"
        elif [ "$vm_id" -gt 100 ]; then
            break
        else
            red "请输入大于100的虚拟机ID"
        fi
    done

    # 询问用户输入虚拟机名称
    while true; do
        read -p "请输入虚拟机名称: " vm_name
        if [[ -n "$vm_name" ]]; then
            break
        else
            red "虚拟机名称不能为空，请重新输入。"
        fi
    done

    read -p "请输入虚拟机 SSH 登录用户名: " vm_ssh_name
    read -p "请输入虚拟机 SSH 登录密码: " vm_ssh_password
    export vm_ssh_password="$vm_ssh_password"

    # 询问用户输入内存大小，确保是有效数字
    while true; do
        read -p "请输入虚拟机内存大小 (MB) [默认2048MB]: " memory_size
        memory_size=${memory_size:-2048}
        if [[ "$memory_size" =~ ^[0-9]+$ && "$memory_size" -gt 0 ]]; then
            break
        else
            red "无效的内存大小，请输入正整数"
        fi
    done

    # 询问用户输入CPU核心数，同时确保核心数不超过系统总核心数
    while true; do
        read -p "请输入CPU核心数 (当前系统的 CPU 核心总数为 $total_cpu_cores ，最大不可超过 $total_cpu_cores ) [默认$total_cpu_cores]: " cpu_cores
        cpu_cores=${cpu_cores:-$total_cpu_cores}
        if [ "$cpu_cores" -le "$total_cpu_cores" ]; then
            break
        else
            red "输入的 CPU 核心数超过了系统的最大核心数，请重新输入"
        fi
    done

    # 询问存储位置
    while true; do
        white "请选择存储类型:"
        white "1) local [默认选项]"
        white "2) local-lvm"
        white "3) local-btrfs"
        white "4) 自行输入存储地址"
        
        read -p "请选择: " storage_choice
        storage_choice=${storage_choice:-1}
        if [ "$storage_choice" -eq 1 ]; then
            storage="local"
            break
        elif [ "$storage_choice" -eq 2 ]; then
            storage="local-lvm"
            break
        elif [ "$storage_choice" -eq 3 ]; then
            storage="local-btrfs"
            break    
        elif [ "$storage_choice" -eq 4 ]; then
        read -p "输入自定义存储地址: " storage_path
            storage="$storage_path"
            break
        else
            red "无效选择，请输入1、2、3或4"
        fi
    done

    # 检查是否需要扩容磁盘
    while true; do
        read -p "是否需要扩容磁盘? (y/n) [默认y]: " expand_disk
        expand_disk=${expand_disk:-y}
        if [[ "$expand_disk" == "y" || "$expand_disk" == "n" ]]; then
            if [ "$expand_disk" == "y" ]; then
                read -p "请输入扩容大小，仅需输入扩容数字，默认扩容大小为8（单位：GB）: " resize_size_num
                resize_size_num=${resize_size_num:-8}
                resize_size=${resize_size_num}G
            fi
            break
        else
            red "无效选择，请输入 y 或 n"
        fi
    done

    # 询问IP地址，默认IP改为10.10.10.70
    read -p "请输入虚拟机的IP地址 [默认10.10.10.70]: " ip_address
    ip_address=${ip_address:-10.10.10.70}

    # 询问网关地址，默认网关改为10.10.10.1
    read -p "请输入网关地址 [默认10.10.10.1]: " gateway_address
    gateway_address=${gateway_address:-10.10.10.1}

    if [[ -f "$FILENAME" && $(stat -c%s "$FILENAME") -gt $((200 * 1024 * 1024)) ]]; then
        white "${yellow}镜像文件已存在，跳过下载...${reset}"
    else
        white "${yellow}正在下载镜像文件...${reset}"
        wget --quiet --show-progress -O "$FILENAME" "$URL"
        if [[ -f "$FILENAME" && $(stat -c%s "$FILENAME") -gt $((200 * 1024 * 1024)) ]]; then
            green "镜像文件下载完成"
        else
            red "文件不存在或大小小于200MB，请检查镜像文件"
            [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete  
            exit 1
        fi

    fi

    command="qm create $vm_id --name $vm_name --cpu host --cores $cpu_cores --memory $memory_size --net0 virtio,bridge=vmbr0 --machine q35 --scsihw virtio-scsi-single --bios ovmf --efidisk0 $storage:1,format=raw,efitype=4m,pre-enrolled-keys=1"
    white "开始创建${yellow}${vm_id} ${vm_name}虚拟机${reset}..."
    eval $command

    qm set $vm_id --ciuser "$vm_ssh_name" --cipassword "$vm_ssh_password"

    qm set $vm_id --scsi1 $storage:0,import-from=$FILENAME

    if [ "$expand_disk" == "y" ]; then
        qm resize $vm_id scsi1 "+${resize_size}"
        white "磁盘已扩容 ${yellow}${resize_size}${reset}"
    fi

    qm set $vm_id --ide2 $storage:cloudinit

    qm set $vm_id --ipconfig0 ip=$ip_address/24,gw=$gateway_address

    qm set $vm_id --boot c --bootdisk scsi1

    qm set $vm_id --tablet 0
    
    [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete  
    green "虚拟机创建完成，ID为 $vm_id，名称为 $vm_name "
}
ssh_config(){
CONFIG="
PasswordAuthentication yes
PermitEmptyPasswords no
UseDNS no
"

# 将配置写入 /etc/ssh/sshd_config.d/10-server-sshd.conf 文件
echo "$CONFIG" | sudo tee /etc/ssh/sshd_config.d/10-server-sshd.conf > /dev/null

# 重启 SSH 服务
sudo systemctl restart ssh.service

# 输出完成信息
echo "SSH 配置已更新并重启服务。"
}

install_prometheus(){
    echo -e "开始安装普罗米修斯"
    prometheus_latest_version=$(curl -s "$prometheus_url" | grep -oP 'tag\/v?\K[0-9]+\.[0-9]+\.[0-9]+[^\s]*' | grep -vE 'rc|beta' | sort -V | tail -n 1 | tr -d '"')
    if [ -n "$prometheus_latest_version" ]; then
        prometheus_download_url="${prometheus_url}/download/v${prometheus_latest_version}/prometheus-${prometheus_latest_version}.linux-amd64.tar.gz"
        echo "获取最新版本: $prometheus_latest_version"
        echo "开始安装"
        sleep 1
        wget -O "${download_dir}/prometheus-${prometheus_latest_version}.linux-amd64.tar.gz" "$prometheus_download_url"
        tar zxf "${download_dir}/prometheus-${prometheus_latest_version}.linux-amd64.tar.gz" -C /opt
        mv /opt/prometheus-${prometheus_latest_version}.linux-amd64 /opt/prometheus
        sleep 1
        echo "prometheus安装完成"
    else
        echo "没有找到有效版本"
        exit 1
    fi

    # 写入普罗米修斯启动文件
    prometheus_service_file="/usr/lib/systemd/system/prometheus.service"

    # 备份 prometheus.service 文件（如果存在）
    if [ -f "$prometheus_service_file" ]; then
        backup_file="${prometheus_service_file}.bak_$(date +%F_%T)"
        cp "$prometheus_service_file" "$backup_file"
        echo "备份已创建: $backup_file"
        > "$prometheus_service_file"
        echo "清空了 $prometheus_service_file 文件"
    else
        echo "$prometheus_service_file 文件不存在，跳过备份。"
    fi

    # 写入新的 prometheus.service 配置
    cat <<EOF > "$prometheus_service_file"
[Unit]
Description=Prometheus service

[Service]
User=root
ExecStart=/opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml --storage.tsdb.path=/opt/prometheus/data
TimeoutStopSec=10
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    echo "新的 prometheus.service 配置已写入。"

    # 写入普罗米修斯配置文件
    prometheus_config_file="/opt/prometheus/prometheus.yml"

    # 检查配置文件是否存在
    if [ -f "$prometheus_config_file" ]; then
        backup_file="${prometheus_config_file}.bak_$(date +%F_%T)"
        cp "$prometheus_config_file" "$backup_file"
        echo "备份已创建: $backup_file"
    else
        echo "$prometheus_config_file 文件不存在，跳过备份。"
    fi

    wget -O $prometheus_config_file $file_host/script/config/prometheus.yml

    echo "新的 prometheus.yml 配置已写入。"
    systemctl daemon-reload
    systemctl enable prometheus --now
}

install_loki(){
    
    loki_latest_version=$(curl -s "$loki_url" | grep -oP 'tag\/v?\K[0-9]+\.[0-9]+\.[0-9]+' | grep -vE 'rc|beta' | sort -V | tail -n 1)

    if [ -n "$loki_latest_version" ]; then
        echo "最新版本: $loki_latest_version"
        
        wget -P "$download_dir" "https://raw.githubusercontent.com/grafana/loki/v${loki_latest_version}/cmd/loki/loki-local-config.yaml"
        if [ $? -eq 0 ]; then
            echo "loki-local-config.yaml 下载成功"
        else
            echo "loki-local-config.yaml 下载失败"
            exit 1
        fi

        wget -P "$download_dir" "https://github.com/grafana/loki/releases/download/v${loki_latest_version}/loki_${loki_latest_version}_amd64.deb"
        if [ $? -eq 0 ]; then
            echo "loki_${loki_latest_version}_amd64.deb 下载成功"
        else
            echo "loki_${loki_latest_version}_amd64.deb 下载失败"
            exit 1
        fi
        echo "loki-local-config.yaml 和 Loki .deb 包已成功下载到 $download_dir！"
        echo "开始安装 loki"
        dpkg -i "${download_dir}/loki_${loki_latest_version}_amd64.deb"
        systemctl daemon-reload
    systemctl enable loki --now
    else
        echo "没有找到有效版本"
        exit 1
    fi
}

install_vector(){
    install -d -m 777 /opt/vector
    bash -c "$(curl -L https://setup.vector.dev)"
    apt install vector -y
    wget -O /etc/vector/vector.yaml https://file.herozmy.com/script/config/vector.yaml
    sed -i "s|/tmp/vector|/opt/vector/|g" /etc/vector/vector.yaml
    sed -i '/^Group=vector/a ExecStartPre=/bin/sleep 5' /lib/systemd/system/vector.service
    systemctl daemon-reload
    systemctl enable vector --now >/dev/null 2>&1
}

install_grafana(){
    apt-get install -y adduser libfontconfig1 musl
    wget -O grafana_11.2.0_amd64.deb https://dl.grafana.com/oss/release/grafana_11.2.0_amd64.deb
    dpkg -i grafana_11.2.0_amd64.deb
    systemctl daemon-reload
    systemctl enable grafana-server --now
}


ui_install (){
    install_grafana    
    install_loki
    install_vector
    install_prometheus
    ui_over
}
ui_over(){
echo "=================================================================="
echo -e "\t\tMosdns WEBUI安装完成"
echo -e "\n"
echo -e "请打开：${yellow}http://$local_ip:3000${reset}\n进入ui管理界面，默认账号及密码均为：\n${yellow}admin${reset}"
echo -e "Grafana配置修改:\n${yellow}Loki${reset}：\n默认地址：${yellow}http://localhost:3100${reset}\nMaximum lines：${yellow}5000${reset}"
echo -e "${yellow}Prometheus${reset}：\n默认地址：${yellow}http://localhost:9090${reset}"
echo -e "仪表盘导入${yellow}22005${reset}，并选择${yellow}Loki${reset}和${yellow}Prometheus${reset}即可"
echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，正在\n查询程序运行状态，如出现\e[1m\e[32m active (running)\e[0m，程序已启动成功。\n网关自行配置为sing-box，dns为Mosdns地址"
echo "=================================================================="
}


check_os