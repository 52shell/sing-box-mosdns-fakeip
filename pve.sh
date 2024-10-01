#!/bin/bash

# 定义配置内容
CONFIG="
PasswordAuthentication yes
PermitEmptyPasswords no
UseDNS no
"

# 将配置写入 /etc/ssh/sshd_config.d/10-server-sshd.conf 文件
echo "$CONFIG" | sudo tee /etc/ssh/sshd_config.d/10-server-sshd.conf > /dev/null
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
# 重启 SSH 服务
sudo systemctl restart ssh.service

# 输出完成信息
echo "SSH 配置已更新并重启服务。"