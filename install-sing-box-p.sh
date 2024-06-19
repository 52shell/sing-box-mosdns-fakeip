#!/bin/bash
################################编译 Sing-Box 的最新版本################################
install_singbox() {
    apt update && apt -y upgrade || { echo "更新失败！退出脚本"; exit 1; }
    apt install curl wget tar gawk sed cron unzip nano -y || { echo "更新失败！退出脚本"; exit 1; }
    echo -e "\n设置时区为Asia/Shanghai"
    timedatectl set-timezone Asia/Shanghai || { echo -e "\e[31m时区设置失败！退出脚本\e[0m"; exit 1; }
    echo -e "\e[32m时区设置成功\e[0m"
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
            mv  sing-box /usr/local/bin/
            systemctl restart sing-box
echo "=================================================================="
echo -e "\t\t\tSing-Box P核升级完毕"
echo -e "\t\t\tPowered by www.herozmy.com 2024"
echo -e "\n"
echo -e "温馨提示:\n本脚本仅在 LXC ubuntu22.04 环境下测试，其他环境未经验证，仅供个人使用"
echo -e "本脚本仅适用于学习与研究等个人用途，请勿用于任何违反国家法律的活动！"
echo "=================================================================="
       exit 0  # 替换完成后停止脚本运行
        else
            echo "用户取消了替换升级操作"
        fi
    else
        # 如果不存在旧版本，则直接安装新版本
        mv  sing-box /usr/local/bin/
        echo -e "Sing-Box 安装完成"
    fi
    mkdir -p /etc/sing-box
    sleep 1

}

################################用户自定义设置################################
customize_settings() {
    echo "是否选择生成配置？(y/n)"
    echo "生成配置文件需要添加机场订阅，如自建vps请选择n"
    read choice
if [ "$choice" = "y" ]; then
    read -p "输入订阅连接：" suburl
    suburl="${suburl:-https://}"
    echo "已设置订阅连接地址：$suburl"
    install_config
    
elif [ "$choice" = "n" ]; then
    echo "请手动配置config.json."
fi
    
}

################################开始创建config.json################################
install_config() {
 mkdir  /etc/sing-box/providers
 echo '

{
  "log": {
    "disabled": true,
    "level": "debug",
    "timestamp": true
  },
  "experimental": {
    "clash_api": {
      "external_controller": "0.0.0.0:9090",
      "external_ui": "/etc/sing-box/ui",
      "secret": "",
      "external_ui_download_url": "https://mirror.ghproxy.com/https://github.com/MetaCubeX/metacubexd/archive/gh-pages.zip",
      "external_ui_download_detour": "direct",
      "default_mode": "rule"
    },
    "cache_file": {
      "enabled": true,
      "path": "/etc/sing-box/cache.db",
      "store_fakeip": true
    }
  },
  "dns": {
    "servers": [
      {
        "tag": "nodedns",
        "address": "tls://223.5.5.5:853",
        "detour": "direct"
      },
      {
        "tag": "fakeipDNS",
        "address": "fakeip"
      }
    ],
    "rules": [
      {
        "inbound": "in-dns",
        "server": "fakeipDNS",
        "rewrite_ttl": 5,
        "disable_cache": false
      },
    {
        "domain_suffix": [
            "herozmy.com"
         ],
        "server": "nodedns",
        "disable_cache": true
    },
      {
        "outbound": "any",
        "server": "nodedns",
        "disable_cache": false
      }
    ],
    "fakeip": {
      "enabled": true,
      "inet4_range": "28.0.0.1/8"
    },
    "independent_cache": true,
    "disable_expire": false,
    "reverse_mapping": false,
    "strategy": "ipv4_only",
    "final": "nodedns"
  },
  "inbounds": [
    {
      "type": "direct",
      "tag": "in-dns",
      "sniff": true,
      "listen": "::",
      "listen_port": 6666
    },
    {
      "type": "tproxy",
      "tag": "tproxy-in",
      "listen": "::",
      "listen_port": 7896,
      "tcp_multi_path": false,
      "tcp_fast_open": false,
      "udp_fragment": true,
      "sniff": true,
      "sniff_override_destination": false,
      "sniff_timeout": "50ms",
      "udp_disable_domain_unmapping": false,
      "udp_timeout": "5m"
    },
    {
      "type": "mixed",
      "listen": "0.0.0.0",
      "listen_port": 7893,
      "sniff": false,
      "users": []
    },
    {
      "type": "http",
      "listen": "0.0.0.0",
      "listen_port": 7890,
      "sniff": false,
      "users": []
    },
    {
      "type": "socks",
      "listen": "0.0.0.0",
      "listen_port": 7891,
      "tcp_multi_path": true,
      "tcp_fast_open": true,
      "udp_fragment": true,
      "sniff": true,
      "users": []
    }
  ],
    "outbound_providers": [
        {
            "type": "remote",
            "path": "/etc/sing-box/providers/1.yaml",
            "tag": "机场",
            "healthcheck_url": "http://www.gstatic.com/generate_204",
            "healthcheck_interval": "10m0s",
            "download_url": "$suburl",
            "download_ua": "clash.meta",
            "download_interval": "24h0m0s",
            "download_detour": "direct"
        }
    ],
  "outbounds": [
      {
         "type": "selector",
         "tag": "🚀 节点选择",
         "outbounds": [
            "🔄 自动选择",
            "♻️ 手动选择", 
            "🇯🇵 日本节点",
            "✨台湾节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点",
            "🎯 全球直连"
         ]
      },
      {
         "type": "selector",
         "tag": "♻️ 手动选择",
         "providers": [
            "机场"
         ]
      },
      {
        "tag":"🤖 OpenAI",
        "type":"selector",
        "outbounds":[
            "🚀 节点选择",
            "♻️ 手动选择",
            "✨台湾节点",
            "🇯🇵 日本节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点"
        ],
        "default": "🇺🇲 美国节点"
      },
      {
         "type": "urltest",
         "tag": "🔄 自动选择",
         "providers": [
          "机场"
         ],
         "idle_timeout": "30001h",
         "interval": "30000h",
         "tolerance": 50
      },
      {
         "type": "selector",
         "tag": "📲 电报消息",
         "outbounds": [
            "🚀 节点选择",
            "♻️ 手动选择",
            "✨台湾节点",
            "🇯🇵 日本节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点"
         ]
      },
      {
         "type": "selector",
         "tag": "🍎 苹果服务",
         "outbounds": [
            "🎯 全球直连",
            "direct", 
            "🚀 节点选择",
            "♻️ 手动选择",
            "🇯🇵 日本节点",
            "✨台湾节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点"
         ],
         "default": "direct"
      },
      {
         "type": "selector",
         "tag": "🐟 漏网之鱼",
         "outbounds": [
          "🎯 全球直连",
          "direct", 
          "🚀 节点选择",
          "♻️ 手动选择",
          "🇯🇵 日本节点",
          "✨台湾节点",
          "🇸🇬 狮城节点",
          "🇭🇰 香港节点",
          "🇺🇲 美国节点",
          "🔰 其它节点"
       ],
       "default": "🚀 节点选择"
    },
      {
        "tag": "🌌 Google",
        "type": "selector",
        "outbounds": [
            "🚀 节点选择",
            "♻️ 手动选择", 
            "✨台湾节点",
            "🇯🇵 日本节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点"
        ],
        "default": "🇭🇰 香港节点"
      },
      {
        "tag": "🐦 Twitter",
        "type": "selector",
        "outbounds": [
            "🚀 节点选择",
            "♻️ 手动选择",
            "✨台湾节点",
            "🇯🇵 日本节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点"
        ],
        "default": "🚀 节点选择"
      },
      {
        "tag": "👤 Facebook",
        "type": "selector",
        "outbounds": [
            "🚀 节点选择",
            "♻️ 手动选择",
            "✨台湾节点",
            "🇯🇵 日本节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点"
        ],
        "default": "🚀 节点选择"
      },
      {
        "tag": "🛍️ Amazon",
        "type": "selector",
        "outbounds": [
            "🚀 节点选择",
            "♻️ 手动选择",
            "✨台湾节点",
            "🇯🇵 日本节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点"
        ],
        "default": "🚀 节点选择"
      },
      {
        "tag": "🧩 Microsoft",
        "type": "selector",
        "outbounds": [
            "direct",
            "🚀 节点选择",
            "♻️ 手动选择", 
            "✨台湾节点",
            "🇯🇵 日本节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点"
        ],
        "default": "direct"
      },
      {
        "tag": "🎮 Game",
        "type": "selector",
        "outbounds": [
            "direct",
            "🚀 节点选择",
            "♻️ 手动选择",
            "🇯🇵 日本节点",
            "✨台湾节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点"
        ],
        "default": "direct"
      },
      {
        "tag": "📺 Bilibili",
        "type": "selector",
        "outbounds": [
            "direct",
            "🚀 节点选择",
            "♻️ 手动选择", 
            "✨台湾节点",
            "🇯🇵 日本节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点"
        ],
        "default": "direct"
      },
      {
        "tag": "🎬 MediaVideo",
        "type": "selector",
        "outbounds": [
            "🚀 节点选择",
            "♻️ 手动选择", 
            "✨台湾节点",
            "🇯🇵 日本节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点"
        ],
        "default": "🚀 节点选择"
      },
      {
        "tag": "🌏 !cn",
        "type": "selector",
        "outbounds": [
            "🚀 节点选择",
            "♻️ 手动选择",
            "✨台湾节点",
            "🇯🇵 日本节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点"
        ],
        "default": "🚀 节点选择"
      },
      {
         "type": "selector",
         "tag": "🎯 全球直连",
        "outbounds": [
            "direct",
            "♻️ 手动选择",
            "🇯🇵 日本节点",
            "✨台湾节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点"
        ],
        "default": "direct"
      },
      {
         "type": "selector",
         "tag": "GLOBAL",
         "outbounds": [
            "🎯 全球直连",
            "🇯🇵 日本节点",
            "✨台湾节点",
            "🇸🇬 狮城节点",
            "🇭🇰 香港节点",
            "🇺🇲 美国节点",
            "🔰 其它节点"
         ]
      },
      {
         "tag": "block",
         "type": "block"
      },
      {
         "tag": "direct",
         "type": "direct",
         "tcp_fast_open": true,
         "udp_fragment": true,
         "tcp_multi_path": true
      },
      {
         "tag": "dns-out",
         "type": "dns"
      },
      {
         "type": "selector",
         "tag": "🇯🇵 日本节点",
         "use_all_providers": true,
         "includes": "(?i)日本|东京|大阪|[^-]日|JP|Japan"
      },
      {
         "type": "selector",
         "tag": "🇸🇬 狮城节点",
         "use_all_providers": true,
         "includes": "(?i)新加坡|坡|狮城|SG|Singapore"
      },
      {
         "type": "selector",
         "tag": "🇭🇰 香港节点",
         "use_all_providers": true,
         "includes": "(?i)香港|HK|hk|Hong Kong|HongKong|hongkong"
      },
      {
         "type": "selector",
         "tag": "✨台湾节点",
         "use_all_providers": true,
         "includes": "(?i)🇹🇼|TW|tw|台湾|臺灣|台|Taiwan"
      },
      {
         "type": "selector",
         "tag": "🇺🇲 美国节点",
         "use_all_providers": true,
         "includes": "(?i)美|达拉斯|洛杉矶|圣何塞|US|United States"
      },
      {
         "type": "selector",
         "tag": "🔰 其它节点",
         "use_all_providers": true,
         "includes": "(?i)德国|DE|brd|germany|荷兰|NL|Netherlands|法国|FR|France|French Republic|澳大利亚|AU|Australia|迪拜|UAE|Dubai|印度|IN|India|KR|Korea|KOR|首尔|韩|韓|英国|UnitedKingdom|UK|英|瑞典|Sweden|SE|巴西|Brazil|BR|非洲|Africa|AF"
      }
    ],
    "route": {
     "final": "🐟 漏网之鱼",
     "auto_detect_interface": true,
     "default_mark": 1,
      "rules": [

      {
        "inbound": "in-dns",
        "outbound": "dns-out"
      },
      {
        "port": 53,
        "outbound": "dns-out"
      },
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
      {
        "protocol": "quic",
        "outbound": "block"
      },
      {
        "protocol": "stun",
        "outbound": "block"
      },
      {
        "clash_mode": "direct",
        "skip_resolve": true,
        "outbound": "direct"
      },
      {
        "clash_mode": "global",
        "skip_resolve": true,
        "outbound": "GLOBAL"
      },
      {
        "domain": [
          "clash.razord.top",
          "yacd.metacubex.one",
          "yacd.haishan.me",
          "d.metacubex.one"
        ],
        "skip_resolve": true,
        "outbound": "direct"
      },
      {
        "domain_suffix": [
          "microsoft.com",
          "browserleaks.com"
        ],
        "outbound": "🌌 Google"
      },
      {
        "domain_suffix": [
          "googleapis.com",
          "googleapis.cn",
          "gstatic.com"
        ],
        "outbound": "🌌 Google"
      }, 
      {
        "rule_set": "geosite-openai",
        "skip_resolve": true,
        "outbound": "🤖 OpenAI"
      },
      {
        "rule_set": "geosite-youtube",
        "skip_resolve": true,
        "outbound": "🌌 Google"
      },
      {
        "rule_set": [
          "geosite-google",
          "geosite-github"
        ],
        "skip_resolve": true,
        "outbound": "🌌 Google"
      },
      {
        "rule_set": "geosite-telegram",
        "skip_resolve": true,
        "outbound": "📲 电报消息"
      },
      {
        "rule_set": "geosite-twitter",
        "skip_resolve": true,
        "outbound": "🐦 Twitter"
      },
      {
        "rule_set": [
          "geosite-facebook",
          "geosite-instagram"
        ],
        "skip_resolve": true,
        "outbound": "👤 Facebook"
      },
      {
        "rule_set": "geosite-amazon",
        "skip_resolve": true,
        "outbound": "🛍️ Amazon"
      },
      {
        "rule_set": "geosite-apple",
        "skip_resolve": true,
        "outbound": "🍎 苹果服务"
      },
      {
        "rule_set": "geosite-microsoft",
        "skip_resolve": true,
        "outbound": "🧩 Microsoft"
      },
      {
        "rule_set": "geosite-category-games-cn",
        "skip_resolve": true,
        "outbound": "direct"
      },
      {
        "rule_set": "geosite-category-games",
        "skip_resolve": true,
        "outbound": "🎮 Game"
      },
      {
        "rule_set": "geosite-bilibili",
        "skip_resolve": true,
        "outbound": "📺 Bilibili"
      },
      {
        "rule_set": [
          "geosite-tiktok",
          "geosite-netflix",
          "geosite-hbo",
          "geosite-disney",
          "geosite-primevideo"
        ],
        "skip_resolve": true,
        "outbound": "🎬 MediaVideo"
      },
      {
        "rule_set": "geosite-geolocation-!cn",
        "skip_resolve": true,
        "outbound": "🚀 节点选择"
      },
      {
        "ip_is_private": true,
        "skip_resolve": true,
        "outbound": "direct"
      },
      {
        "rule_set": "geoip-netflix",
        "skip_resolve": true,
        "outbound": "🎬 MediaVideo"
      },
      {
        "rule_set": "geoip-cn",
        "skip_resolve": true,
        "outbound": "direct"
      }
     ],
     "rule_set": [
      {
        "tag": "geoip-google",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/google.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geoip-telegram",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/telegram.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geoip-twitter",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/twitter.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geoip-facebook",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/facebook.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geoip-netflix",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/netflix.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geoip-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/cn.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-openai",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/openai.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-youtube",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/youtube.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-google",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/google.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-github",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/github.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-telegram",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/telegram.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-twitter",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/twitter.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-facebook",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/facebook.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-instagram",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/instagram.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-amazon",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/amazon.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-apple",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/apple.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-microsoft",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/microsoft.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-category-games",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/category-games.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-category-games-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/category-games@cn.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-bilibili",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/bilibili.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-tiktok",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/tiktok.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-netflix",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/netflix.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-hbo",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/hbo.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-disney",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/disney.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-primevideo",
        "type": "remote",
        "format": "binary",
       "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/primevideo.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/cn.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-geolocation-!cn",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/geolocation-!cn.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      },
      {
        "tag": "geosite-category-ads-all",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/category-ads-all.srs",
        "download_detour": "direct",
        "update_interval": "7d"
      }
    ]
  }
}
' > /etc/sing-box/config.json
}
######################启动脚本################################
install_service() {
    echo -e "配置系统服务文件"
    sleep 1

    # 检查服务文件是否存在，如果不存在则创建
    sing_box_service_file="/etc/systemd/system/sing-box.service"
if [ ! -f "$sing_box_service_file" ]; then
    # 如果服务文件不存在，则创建
    cat << EOF > "$sing_box_service_file"
[Unit]
Description=Sing-Box service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target

[Service]
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
RestartSec=1800s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
    echo "sing-box服务创建完成"  
else
    # 如果服务文件已经存在，则给出警告
    echo "警告：sing-box服务文件已存在，无需创建"
fi 
    sleep 1
    systemctl daemon-reload
    
}
################################安装tproxy################################
install_tproxy() {

    echo "关闭53端口监听"
    sed -i '/^#*DNSStubListener/s/#*DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
    systemctl restart systemd-resolved.service
    sleep 1
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
    echo "开始创建nftables tproxy转发"
    apt install nftables -y
# 写入tproxy rule    
# 判断文件是否存在
    if [ ! -f "/etc/systemd/system/sing-box-router.service" ]; then
    cat <<EOF > "/etc/systemd/system/sing-box-router.service"
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
    echo "sing-box-router 服务创建完成"
    else
    echo "警告：sing-box-router 服务文件已存在，无需创建"
    fi
################################写入nftables################################
check_interfaces
echo "" > "/etc/nftables.conf"
cat <<EOF > "/etc/nftables.conf"
#!/usr/sbin/nft -f
flush ruleset
table inet singbox {
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

  chain singbox-tproxy {
    fib daddr type { unspec, local, anycast, multicast } return
    ip daddr @local_ipv4 return
    ip6 daddr @local_ipv6 return
    udp dport { 123 } return
    meta l4proto { tcp, udp } meta mark set 1 tproxy to :7896 accept
  }

  chain singbox-mark {
    fib daddr type { unspec, local, anycast, multicast } return
    ip daddr @local_ipv4 return
    ip6 daddr @local_ipv6 return
    udp dport { 123 } return
    meta mark set 1
  }

  chain mangle-output {
    type route hook output priority mangle; policy accept;
    meta l4proto { tcp, udp } skgid != 1 ct direction original goto singbox-mark
  }

  chain mangle-prerouting {
    type filter hook prerouting priority mangle; policy accept;
    iifname { wg0, lo, $selected_interface } meta l4proto { tcp, udp } ct direction original goto singbox-tproxy
  }
}
EOF
    echo "nftables规则写入完成"
    echo "清空 nftalbes 规则"
    nft flush ruleset
    sleep 1
    echo "新规则生效"
    sleep 1
    nft -f /etc/nftables.conf
    install_over
}
################################sing-box安装结束################################
install_over() {
    echo "启用相关服务"
    systemctl enable --now nftables
    systemctl enable --now sing-box-router
    systemctl enable --now sing-box
}

#####################################获取网卡################################
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


################################sing-box安装结束################################
install_sing_box_over() {
echo "=================================================================="
echo -e "\t\t\tSing-Box 安装完毕"
echo -e "\t\t\tPowered by www.herozmy.com 2024"
echo -e "\n"
echo -e "singbox运行目录为/etc/sing-box"
echo -e "singbox WebUI地址:http://ip:9090"
echo -e "Mosdns配置脚本：wget https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/mosdns-p.sh && bash mosdns-p.sh"
echo -e "温馨提示:\n本脚本仅在 LXC ubuntu22.04 环境下测试，其他环境未经验证，仅供个人使用"
echo -e "本脚本仅适用于学习与研究等个人用途，请勿用于任何违反国家法律的活动！"
echo "=================================================================="
}
main() {
    install_singbox
    customize_settings
    install_service
    install_tproxy
    install_sing_box_over
}
main
