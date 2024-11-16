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
    apk update || { echo "更新失败！退出脚本"; exit 1; }
    apk add curl wget git tar gawk sed  unzip nano  || { echo "更新失败！退出脚本"; exit 1; }
    echo -e "\n设置时区为Asia/Shanghai"
    setup-timezone -z Asia/Shanghai || { echo "时区设置失败！退出脚本"; exit 1; }
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
    echo "配置mosdns规则"
    sleep 1
    git init
    git remote add -f origin https://github.com/herozmy/sing-box-mosdns-fakeip.git
    git config core.sparsecheckout true
    echo 'mosdns' > .git/info/sparse-checkout
    git pull origin main
    cd /root && mv mosdns /etc/
    echo "配置mosdns"
    sed -i "s/- addr: 10.10.10.147:6666/- addr: ${uiport}/g" /etc/mosdns/config.yaml
    echo "设置mosdns开机自启动"
    echo '#!/sbin/openrc-run

name=$RC_SVCNAME
description="mosdns service"
supervisor="supervise-daemon"
command="/usr/bin/mosdns"
command_args="start -c /etc/mosdns/config.yaml -d /etc/mosdns"
extra_started_commands="reload"

depend() {
        after net 
}

reload() {
        ebegin "Reloading $RC_SVCNAME"
        $supervisor "$RC_SVCNAME" --signal HUP
        eend $?
}' > /etc/init.d/mosdns
chmod +x /etc/init.d/mosdns && rc-update add mosdns && rc-service mosdns restart
    echo "mosdns开机启动完成"