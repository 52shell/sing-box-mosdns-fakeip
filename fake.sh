#!/bin/bash
# check root执行
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1
show_status() {
    check_sing-box_status
    case $? in
    0)
        echo -e "sing-box: 已运行"
        show_enable_status
        ;;
    1)
        echo -e "sing-box: 未运行"
        show_enable_status
        ;;
    2)
        echo -e "sing-box: 未安装"
        ;;
    esac
  check_mosdns_status
}
show_menu() {
    echo -e "
   面板管理脚本
  0. 退出脚本
————————————————
  1. 安装 sing-box
  2. 更新 sing-box核心
  3. 更新 Puer-sing-box核心
  4. 卸载 sing-box
  5. 清理 sing-box缓存
————————————————
  6. 安装 mosdns
  7. 卸载 mosdns
  8. 更新 mosdns表地址
  9. 清理 mosdns缓存
 "
    show_status
    echo && read -p "请输入选择 [0-16]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        check_uninstall && install
        ;;
    2)
        check_install && update
        ;;
    3)
        check_install && uninstall
        ;;
    4)
        check_install && reset_user
        ;;
    5)
        check_install && reset_config
        ;;
    6)
        check_install && set_port
        ;;
    7)
        check_install && check_config
        ;;
    8)
        check_install && start
        ;;
    9)
        check_install && stop
        ;;
    *)
        echo "请输入正确的数字 [0-16]"
        ;;
    esac
}

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
