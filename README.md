# install mosdns&sing-box fakeip模式

## 特解鸣谢:
* @Panicpanic
* @ovpavac
## 前言:
脚本根据O佬手搓教程流程写成，新手小白所以写的不咋地，有bug也不要见怪
sing-box有两版内核分别:
- 官方内核
- puer sing-box内核 {支持机场订阅}
    脚本内的sing-box和mosdns请分为两个系统安装，sing-box最好使用VM安装，当然lxc也可以。mosdns lxc vm都可以
脚本仅测试Ubuntu22.04安装，理论支持debian系统，
    支持:amd64 arm64 安装
多合一脚本:
``` shell
wget https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/install.sh && bash install
```


