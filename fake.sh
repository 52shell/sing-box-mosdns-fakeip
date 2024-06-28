#!/bin/bash

# 检查是否为root用户执行
[[ $EUID -ne 0 ]] && echo -e "错误：必须使用root用户运行此脚本！\n" && exit 1

# 定义函数提示用户输入
prompt_user() {
    echo -e "
   Herozmy 自用脚本
   请选择需要管理的程序
————————————————
  1. sing-box
  2. mosdns
  3. 更新脚本
  0. 退出脚本
 "

}

checksingbox_core(){
    echo -e "
   请选择sing-box核心
————————————————
  1. sing-box 官方核心
  2. sing-box puer核心
 "
while true; do
    read -p "请输入选择 (1 或 2): " choice
    
    if [[ $choice == 1 ]]; then
        check_uninstall && install_singbox
        break
    elif [[ $choice == 2 ]]; then
        check_uninstall && install_singbox_p
        break
    else
        echo "无效选择，请重新输入。"
    fi
done
  }

checkcore() {
    if [[ $system == "sing-box" ]]; then
        show_menu_singbox
    elif [[ $system == "mosdns" ]]; then
        show_menu_mosdns
    fi
}

show_status() {
    check_status
    case $? in
    0)
        echo -e "$system: 已运行"
        
        ;;
    1)
        echo -e "$system: 未运行"
        
        ;;
    2)
        echo -e "$system: 未安装"
        ;;
    esac
}

check_status() {
    if [[ ! -f /etc/systemd/system/$system.service ]]; then
        return 2
    fi
    temp=$(systemctl is-active $system)
    if [[ $temp == "active" ]]; then
        return 0
    else
        return 1
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo "$system已安装，即将安装最新版本内核"
        if [[ $# == 0 ]]; then
            install_singbox
        fi
        return 1
    else
        return 0
    fi
}

check_uninstall_p() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo "$system已安装，即将安装最新版本内核"
        if [[ $# == 0 ]]; then
            install_singbox_p
        fi
        return 1
    else
        return 0
    fi
}

install_singbox() {

    echo -e "编译Sing-Box 最新版本"
    sleep 1
    apt -y install curl git build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64
    echo -e "开始编译Sing-Box 最新版本"
    rm -rf /root/go/bin/*
    Go_Version=$(curl https://github.com/golang/go/tags | grep '/releases/tag/go' | head -n 1 | gawk -F/ '{print $6}' | gawk -F\" '{print $1}')
    # 判断 **CPU 架构
    if [[ $(uname -m) == "aarch64" ]]; then
        arch="arm64"
    elif [[ $(uname -m) == "x86_64" ]]; then
        arch="amd64"
    else
        arch="未知"
        exit 0
    fi
    echo "系统架构是：$arch"
    wget -O ${Go_Version}.linux-$arch.tar.gz https://go.dev/dl/${Go_Version}.linux-$arch.tar.gz
    tar -C /usr/local -xzf ${Go_Version}.linux-$arch.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/golang.sh
    source /etc/profile.d/golang.sh
    if ! go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@latest; then
        echo -e "Sing-Box 编译失败！退出脚本"
        exit 1
    fi
    echo -e "编译完成，开始安装"
    sleep 1
    # 检查是否存在旧版本的 sing-box
    if [ -f "/usr/local/bin/sing-box" ]; then
        echo "检测到已安装的 sing-box"
        read -p "是否替换升级？(y/n): " replace_confirm
        if [ "$replace_confirm" = "y" ]; then
            echo "正在替换升级 sing-box"
            cp "$(go env GOPATH)/bin/sing-box" /usr/local/bin/
            echo "正在重启sing-box"
            systemctl restart sing-box
            echo "=================================================================="
            echo -e "\t\t\tSing-Box 内核升级完毕"
            echo -e "\t\t\tPowered by www.herozmy.com 2024"
            echo "=================================================================="
            exit 0  # 替换完成后停止脚本运行
        else
            echo "用户取消了替换升级操作"
        fi
    else
        # 如果不存在旧版本，则直接安装新版本
        wget https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/install-sing-box.sh && bash install-sing-box.sh
    fi
}

install_singbox_p() {
    echo -e "开始安装P_sing-box"
    sleep 1
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
    wget -O sing-box-linux-$arch.tar.gz  https://raw.githubusercontent.com/52shell/herozmy-private/main/sing-box-puernya/sing-box-linux-$arch.tar.gz
    sleep 1
    echo -e "下载完成，开始安装"
    sleep 1
    tar -zxvf sing-box-linux-$arch.tar.gz
    if [ -f "/usr/local/bin/sing-box" ]; then
        echo "检测到已安装的 sing-box"
        read -p "是否替换升级？(y/n): " replace_confirm
        if [ "$replace_confirm" = "y" ]; then
            echo "正在替换升级 sing-box"
            mv sing-box /usr/local/bin/
            systemctl restart sing-box
            echo "=================================================================="
            echo -e "\t\t\tSing-Box P核升级完毕"
            echo -e "\t\t\tPowered by www.herozmy.com 2024"
            echo "=================================================================="
            exit 0  # 替换完成后停止脚本运行
        else
            echo "用户取消了替换升级操作"
        fi
    else
        # 如果不存在旧版本，则直接安装新版本
        wget https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/install-sing-box-p.sh && bash install-sing-box-p.sh
    fi
}

del_singbox() {
    echo "开始卸载sing-box核心程序及其相关配置文件"
    echo "关闭sing-box"
    systemctl stop sing-box
    echo "卸载sing-box自启动"
    systemctl disable sing-box
    echo "关闭nftables防火墙规则"
    systemctl stop nftables
    echo "nftables防火墙规则"
    systemctl disable nftables
    echo "关闭sing-box路由规则"
    systemctl stop sing-box-router
    echo "卸载sing-box路由规则"
    systemctl disable sing-box-router


    echo "删除相关配置文件"
    rm -rf /etc/systemd/system/sing-box*

    rm -rf /etc/sing-box
    rm -f /usr/local/bin/sing-box
    echo "卸载完成"
}

del_cache() {
    echo "停止sing-box"
    systemctl stop sing-box
    rm -rf /etc/sing-box/cache.db
    echo "sing-box缓存清理完成"
    systemctl start sing-box
    echo "sing-box启动"
}
sub_config(){
  sub_host="https://sub-singbox.herozmy.com"
    read -p "输入订阅连接：" suburl
    suburl="${suburl:-https://}"
    echo "已设置订阅连接地址：$suburl"
    echo "请选择："
    echo "1. tproxy_fake_ip O大原版 <适用机场多规则分流>"
    echo "2. tproxy_fake_ip O大原版 <适用VPS自建模式>"
    read -p "请输入选项 [默认: 1]: " choice
    # 如果用户没有输入选择，则默认为1
    choice=${choice:-1}
    if [ $choice -eq 1 ]; then
        json_file="&file=https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/tproxy.json"
    elif [ $choice -eq 2 ]; then
        json_file="&file=https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/fake-ip.json"
    else
        echo "无效的选择。"
        return 1
    fi
    curl -o config.json "${sub_host}/config/${suburl}${json_file}"    
    # 检查下载是否成功
    if [ $? -eq 0 ]; then
        # 移动文件到目标位置
        mv config.json /etc/sing-box/config.json
        echo "Sing-box配置文件写入成功！"
    else
        echo "下载文件失败，请检查网络连接或者URL是否正确。"
    fi    
  }
before_show_menu() {
    echo && echo -n -e "按回车返回主菜单: " && read temp
    checkcore
}

show_menu_singbox() {
    echo -e "
   面板管理脚本
  0. 退出脚本
————————————————
  1. 安装/更新 sing-box | sing-box-puer核心
  2. 卸载 sing-box
  3. 清理 sing-box缓存
  4. 更新官核节点配置 
 "
show_status
    echo && read -p "请输入选择 [0-5]: " num
		
    case "${num}" in
    0)
        exit 0
        ;;
    1)
        checksingbox_core
        ;;
    2)
        del_singbox
        ;;
    3)
        del_cache
        ;;
    4)
        sub_config
        ;;
    *)
        echo "请输入正确的数字 [0-4]"
        ;;
    esac
}

show_menu_mosdns() {
    echo -e "
   面板管理脚本
  0. 退出脚本
————————————————
  1. 安装mosdns
  4. 卸载 mosdns
  5. 清理 mosdns 缓存
  6. 启动 sing-box 
 "
    echo && read -p "请输入选择 [0-6]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        check_uninstall && install_mosdns
        ;;
    2)
        check_install && update_mosdns
        ;;
    3)
        check_install && uninstall_mosdns
        ;;
    4)
        check_install && reset_mosdns_cache
        ;;
    5)
        check_install && toggle_service_mosdns
        ;;
    *)
        echo "请输入正确的数字 [0-6]"
        ;;
    esac
}

toggle_service() {
    if systemctl is-active --quiet sing-box; then
        systemctl stop sing-box
        echo "sing-box 已停止"
    else
        systemctl start sing-box
        echo "sing-box 已启动"
    fi
}

install_mosdns() {
    echo "安装mosdns的代码未提供"
}

update_mosdns() {
    echo "更新mosdns的代码未提供"
}

uninstall_mosdns() {
    echo "卸载mosdns的代码未提供"
}

reset_mosdns_cache() {
    echo "重置mosdns缓存的代码未提供"
}

toggle_service_mosdns() {
    if systemctl is-active --quiet mosdns; then
        systemctl stop mosdns
        echo "mosdns 已停止"
    else
        systemctl start mosdns
        echo "mosdns 已启动"
    fi
}

system=""

# 循环直到用户输入正确的值或选择退出
while true; do
    prompt_user
    read -p "请输入选择 [0-2]: " choice

    if [[ $choice -eq 1 ]]; then
        system="sing-box"
        break
    elif [[ $choice -eq 2 ]]; then
        system="mosdns"
        break
    elif [[ $choice -eq 3 ]]; then
        rm -rf /usr/bin/fake
        wget -O /usr/bin/fake https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/fake.sh
        chmod +x /usr/bin/fake
        exit 0
    elif [[ $choice -eq 0 ]]; then
        echo "退出脚本"
        exit 0
    else
        echo "无效输入，请输入1、2或0。"
    fi
done
echo "进入 $system 管理菜单"
sleep 1

checkcore
