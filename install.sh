#!/bin/bash
################################入口################################

# check root
[[ $EUID -ne 0 ]] && echo -e "错误:必须使用root用户运行此脚本！\n" && exit 1
main() {
    home
}
################################主菜单################################
home() {
    clear
    echo "=================================================================="
    echo -e "\t\tLinux | 一键搭建脚本"
    echo -e "\t\tPowered by www.herozmy.com 2024 1"
    echo -e "\t\\n"
    echo -e "温馨提示：\n本脚本推荐使用ububtu22.04环境，其他环境未经验证，仅供个人使用"
    echo -e "本脚本仅适用于学习与研究等个人用途，请勿用于任何违反国家法律的活动！"
    echo "=================================================================="
    read -p "按Enter键继续~" -r
    sleep 1
    choose_singbox
}
################################选择安装################################
choose_singbox() {
echo "欢迎使用脚本安装程序"
echo "请选择要安装的版本："
echo "1. 编译官方sing-box Core/升级"
echo "2. Mosdns-O佬 fakeip分流配置"
echo "3. P版sing-box Core/升级"
#echo "4. Mosdns-PH佬 fakeip分流配置"
echo "5. hysteria2 回家"
echo "6. mihomo (clash meta)"
read choice
case $choice in
    1)
wget https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/install-sing-box.sh >/dev/null 2>&1
bash install-sing-box.sh
        ;;
    2)
wget https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/mosdns-o.sh >/dev/null 2>&1
bash mosdns-o.sh
        ;;
    3)
wget https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/install-sing-box-p.sh >/dev/null 2>&1
bash install-sing-box-p.sh
        ;;
    #4)
#wget https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/mosdns-p.sh >/dev/null 2>&1
#bash mosdns-p.sh
       # ;;
    5)
wget https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/hy2-gohome.sh >/dev/null 2>&1
bash hy2-gohome.sh
        ;;
    6)
wget https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/clash.sh >/dev/null 2>&1
bash clash.sh
        ;;
    *)
        echo "无效的选项，请重新运行脚本并选择有效的选项."
        ;;
esac
}
main
