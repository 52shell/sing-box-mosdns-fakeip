#!/bin/bash

read -ep "是否执行网络静态设置部分脚本 ( y or n):" other
if [ y == $other ]; then
other=`cat /etc/network/interfaces | grep 'static' | wc -l`
if [ "$other" -eq "1" ]; then
  read -ep "已是静态ip分配，是否继续修改 ( y or n):" other
  if [ y == $other ]; then
	 sed -i '/address/d' /etc/network/interfaces
      sed -i '/netmask/d' /etc/network/interfaces
      sed -i '/gateway/d' /etc/network/interfaces
      sed -i '/nameserver/d' /etc/resolv.conf
      read -ep "请输入ip地址  如( 192.168.1.100 ):" other
      read -ep "请输入子网掩码  如( 255.255.255.0 ):" other1
      read -ep "请输入网关地址  如( 192.168.1.1 ):" other2
      read -ep "请输入dns地址  如( 223.5.5.5 ):" other3
      echo "address $other
netmask $other1
gateway $other2" >> /etc/network/interfaces
      echo "nameserver $other3" >> /etc/resolv.conf
      systemctl restart networking.service
      echo '已完成重启网络'
  else
      echo '已退出静态ip分配部分'
  fi 
else
    addressname=`cat /proc/net/dev | awk '{i++; if(i>2){print $1}}' | sed 's/^[\t]*//g' | sed 's/[:]*$//g' | grep -v 'lo'`
    sed -i 's/^allow-hotplug/#allow-hotplug/' /etc/network/interfaces
    sed -i "s/^iface.*inet dhcp/#iface $addressname inet dhcp/" /etc/network/interfaces
    sed -i '/nameserver/d' /etc/resolv.conf
    read -ep "请输入ip地址  如( 192.168.1.100 ):" other
    read -ep "请输入子网掩码  如( 255.255.255.0 ):" other1
    read -ep "请输入网关地址  如( 192.168.1.1 ):" other2
    read -ep "请输入dns地址  如( 223.5.5.5 ):" other3
    echo "auto $addressname
iface $addressname inet static
address $other
netmask $other1
gateway $other2" >> /etc/network/interfaces
    echo "nameserver $other3" >> /etc/resolv.conf
    systemctl restart networking.service
    echo '已完成重启网络'
fi
fi