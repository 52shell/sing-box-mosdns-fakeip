# install mosdns&sing-box fakeip模式

## 特解鸣谢:
* @Panicpanic


* @ovpavac
## 前言:
脚本根据O佬手搓流程写成
相关分流规则有O佬和ph佬两套配置
新手小白所以写的不咋地，有bug也不要见怪
sing-box有两版内核分别:
* 官方内核
* puer sing-box内核 {支持机场}

脚本内的sing-box和mosdns请分为两个系统sing-box最好使用VM安装，当然lxc也可以。mosdns lxc vm都可以
* 仅测试Ubuntu22.04安装，理论支持debian系统

支持:amd64 arm64
多合一脚本:
``` shell
wget https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/install.sh && bash install.sh
```
脚本内生成配置处`订阅地址`为自建[sub-singbox](https://github.com/Toperlock/sing-box-subscribe)转换方案，默认为本人自用地址，如有需要可以在github里的`install-sing-box.sh`里`sub_host=`后自行修改替换


更新记录：

增加写入快捷 方式：
``` shell
 wget -O /usr/bin/fake https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/fake.sh && chmod +x /usr/bin/fake
```
之后更新核心配置。输入`fake`即可
