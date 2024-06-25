#!/bin/bash
# check root执行
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

check_sing-box_status() {
    if [[ ! -f /etc/systemd/system/sing-box.service ]]; then
        return 2
    fi
    temp=$(systemctl status sing-box | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_mosdns_status() {
    if [[ ! -f /etc/systemd/system/mosdns.service ]]; then
        return 2
    fi
    temp=$(systemctl status mosdns | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
