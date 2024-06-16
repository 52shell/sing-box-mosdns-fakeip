#!/bin/bash
    echo -e "hysteria2 回家 自签证书"
    echo -e "开始创建证书存放目录"
    mkdir -p /root/hysteria 
    echo -e "自签bing.com证书100年"
    openssl ecparam -genkey -name prime256v1 -out /root/hysteria/private.key && openssl req -new -x509 -days 36500 -key /root/hysteria/private.key -out /root/hysteria/cert.pem -subj "/CN=bing.com"
    while true; do
        # 提示用户输入域名
        read -p "请输入家庭DDNS域名: " domain
        # 检查域名格式是否正确
        if [[ $domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            echo "域名格式不正确，请重新输入"
        fi
    done  
    # 输入端口号
    while true; do
        read -p "请输入端口号: " hyport

        # 检查端口号是否为数字
        if [[ $hyport =~ ^[0-9]+$ ]]; then
            break
        else
            echo "端口号格式不正确，请重新输入"
        fi
    done
    read -p "请输入密码: " password
    echo "您输入的域名是: $domain"
    echo "您输入的端口号是: $hyport"
    echo "您输入的密码是: $password"
    sleep 2
    echo "开始生成配置文件"
    # 检查sb配置文件是否存在
    config_file="/etc/sing-box/config.json"
    if [ ! -f "$config_file" ]; then
        echo "错误：配置文件 $config_file 不存在"
        echo "请选择生成singbox或者P核singbox config.json脚本"
        
        exit 1
    fi   
    hy_config='{
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": '"${hyport}"',
      "sniff": true,
      "sniff_override_destination": false,
      "sniff_timeout": "100ms",
      "users": [
        {
          "password": "'"${password}"'"
        }
      ],
      "ignore_client_bandwidth": true,
      "tls": {
        "enabled": true,
        "alpn": [
          "h3"
        ],
        "certificate_path": "/root/hysteria/cert.pem",
        "key_path": "/root/hysteria/private.key"
      }
    },
'
line_num=$(grep -n 'inbounds' /etc/sing-box/config.json | cut -d ":" -f 1)
# 如果找到了行号，则在其后面插入 JSON 字符串，否则不进行任何操作
if [ ! -z "$line_num" ]; then
    # 将文件分成两部分，然后在中间插入新的 JSON 字符串
    head -n "$line_num" /etc/sing-box/config.json > tmpfile
    echo "$hy_config" >> tmpfile
    tail -n +$(($line_num + 1)) /etc/sing-box/config.json >> tmpfile
    mv tmpfile /etc/sing-box/config.json
fi
    echo "HY2回家配置写入完成"
    echo "开始重启sing-box"
    systemctl restart sing-box
    echo "开始生成sing-box回家-手机配置"
    cat << EOF >  "/root/go_home.json"
{
    "log": {
        "level": "info",
        "timestamp": false
    },
    "dns": {
        "servers": [
            {
                "tag": "dns_proxy",
                "address": "tls://1.1.1.1:853",
                "strategy": "ipv4_only",
                "detour": "proxy"
            },
            {
                "tag": "dns_direct",
                "address": "https://223.5.5.5/dns-query",
                "strategy": "prefer_ipv6",
                "detour": "direct"
            },
            {
                "tag": "dns_resolver",
                "address": "223.5.5.5",
                "detour": "direct"
            },
            {
                "tag": "dns_success",
                "address": "rcode://success"
            },
            {
                "tag": "dns_refused",
                "address": "rcode://refused"
            },
            {
                "tag": "dns_fakeip",
                "address": "fakeip"
            }
        ],
        "rules": [
            {
                "domain_suffix": [
                    "${domain}"         
                ],
                "server": "dns_direct",
                "disable_cache": true
            },
            {
                "rule_set": "geosite-cn",
                "query_type": [
                    "A",
                    "AAAA"
                ],
                "server": "dns_direct"
            },
            {
                "rule_set": "geosite-cn",
                "query_type": [
                    "CNAME"
                ],
                "server": "dns_direct"
            },      
            {
                "rule_set": "geosite-geolocation-!cn",
                "query_type": [
                    "A"          
                ],
                "server": "dns_fakeip"
            },
            {
                "rule_set": "geosite-geolocation-!cn",
                "query_type": [
                    "CNAME"
                ],
                "server": "dns_proxy"
            },
            {
                "query_type": [
                    "A",
                    "AAAA",
                    "CNAME"
                ],
                "invert": true,
                "server": "dns_refused",
                "disable_cache": true
            }
        ],
        "final": "dns_proxy",
        "independent_cache": true,
        "fakeip": {
            "enabled": true,
            "inet4_range": "198.18.0.0/15",
	    "inet6_range": "fc00::/18"
        }
    },
    "route": {
        "rule_set": [
            {
                "tag": "geosite-category-ads-all",
                "type": "remote",
                "format": "binary",
                "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs",
                "download_detour": "proxy"
            },
        {
                "tag": "geosite-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-cn.srs",
                "download_detour": "proxy"
            },  
            {
                "tag": "geosite-geolocation-!cn",
                "type": "remote",
                "format": "binary",
                "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-geolocation-!cn.srs",
                "download_detour": "proxy"
            },
            {
                "tag": "geoip-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs",
                "download_detour": "proxy"
            }
        ],
        "rules": [
            {
                "protocol": "dns",
                "outbound": "dns-out"
            },
            {
            "ip_cidr": [   
                 "10.10.10.0/24"
               ],
                "outbound": "telecom_home" 
            },
            {
              "network": "udp",
              "port": 443,
              "outbound": "block"
           },
         {
             "domain_suffix": [ 
          ".cn"
		 ],
        "outbound": "direct"
        },
        {
      "domain_suffix": [ 
          "office365.com"
        ],
        "outbound": "direct"
        },
        {
        "domain_suffix": [
          "push.apple.com",
          "iphone-ld.apple.com",
          "lcdn-locator.apple.com",
          "lcdn-registration.apple.com"
        ],
        "outbound": "direct"
        },
        {
                "rule_set": "geosite-cn",
                "outbound": "direct"
            },
            {
                "rule_set": "geosite-geolocation-!cn",
                "outbound": "proxy"
            },
            {
                "rule_set": "geoip-cn",
                "outbound": "direct"
            },
            {
                "ip_is_private": true,
                "outbound": "direct"
            }
        ],
        "final": "proxy",
        "auto_detect_interface": true
    },
    "inbounds": [
        {
            "type": "tun",
            "tag": "tun-in",
            "inet4_address": "172.16.0.1/30",
            "inet6_address": "fd00::1/126",
            "mtu": 1400,
            "auto_route": true,
            "strict_route": true,
            "stack": "gvisor",
            "sniff": true,
            "sniff_override_destination": false
        }
    ],
    "outbounds": [
        {
            "tag":"proxy",
            "type":"selector",
            "outbounds":[
            "telecom_home"
          ]
        },
       {
         "type": "hysteria2",
         "server": "${domain}",       
         "server_port": ${hyport}, 
         "tag": "telecom_home", 
         "up_mbps": 50,
         "down_mbps": 500,
         "password": "${password}",
         "tls": {
         "enabled": true,
         "server_name": "bing.com",   
         "insecure": true,
         "alpn": [
          "h3"
            ]
          }
        },
     
        {
            "type": "direct",
            "tag": "direct"
        },
        {
            "type": "block",
            "tag": "block"
        },
        {
            "type": "dns",
            "tag": "dns-out"
        }
    ],
    "experimental": {
        "cache_file": {
            "enabled": true,
            "path": "cache.db",
            "store_fakeip": true
        }
    }
}
EOF
sleep 1
echo "=================================================================="
echo -e "\t\t\tSing-Box 回家配置生成完毕"
echo -e "\t\t\tPowered by www.herozmy.com 2024"
echo -e "\n"
echo -e "sing-box 回家配置生成路径为: /root/go_home.json\t\t请自行复制至 sing-box 客户端"
echo -e "温馨提示:\n本脚本仅在 LXC ubuntu22.04 环境下测试，其他环境未经验证，仅供个人使用"
echo -e "本脚本仅适用于学习与研究等个人用途，请勿用于任何违反国家法律的活动！"
echo "================================================================="