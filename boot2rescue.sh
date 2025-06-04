#!/bin/bash
# Description:

# Author: @Mintimate
# Blog: https://www.mintimate.cn/about
# Reference: https://www.rehiy.com/post/441/

# echo 标准化
RED='\033[0;31m'    # 红色
GREEN='\033[0;32m'  # 绿色
YELLOW='\033[0;33m' # 黄色
NC='\033[0m'        # 重置颜色

printMintimate() {
    echo -e "${GREEN}
_____________________________________________________________
    _   _
    /  /|     ,                 ,
---/| /-|----------__---_/_---------_--_-----__---_/_-----__-
  / |/  |   /    /   )  /     /    / /  )  /   )  /     /___)
_/__/___|__/____/___/__(_ ___/____/_/__/__(___(__(_ ___(___ _
         Mintimate's Blog:https://www.mintimate.cn
_____________________________________________________________${NC}"
    echo -e "${GREEN}
    快速配置 Linux 服务器救援模式
    适用于 grub 引导启动的系统
    作者：Mintimate
   
    获取帮助 -> QQ：198330181
    （限：求助前，有给我视频三连的粉丝用户）

    捐赠和赞赏：
    https://www.afdian.com/a/mintimate
    
    更多教程：
    Mintimate's Blog:
    https://www.mintimate.cn
    
    Mintimate's Bilibili:
    https://space.bilibili.com/355567627${NC}"
}

printMintimate

# 创建netboot目录并进入
echo -e "${GREEN} 正在创建 netboot 目录并进入 ${NC}"
mkdir -p /netboot && cd /netboot || exit

# 设置镜像源
repo="https://mirrors.tuna.tsinghua.edu.cn/alpine/edge"

# 下载必要文件
echo -e "${GREEN} 正在下载必要文件 ${NC}"
# 静默下载
wget -q "$repo/releases/x86_64/netboot/vmlinuz-virt" || exit
wget -q "$repo/releases/x86_64/netboot/initramfs-virt" || exit
modl="$repo/releases/x86_64/netboot/modloop-virt"

# 添加GRUB启动项
echo -e "${GREEN} 正在添加 GRUB 启动项 ${NC}"
cat >> /etc/grub.d/40_custom <<EOF
menuentry "Alpine Linux Minimal" {
    search --set=root --file /netboot/vmlinuz-virt
    linux /netboot/vmlinuz-virt console=tty0 console=ttyS0,115200 ip=dhcp modloop=$modl alpine_repo=$repo/main/
    initrd /netboot/initramfs-virt
}
EOF

# 修改默认启动项
echo -e "${GREEN} 是否修改默认启动项 ${NC}"
echo -e "${YELLOW} 输入y后回车=>修改；其他键后回车=>不修改 ${NC}"
echo -e "${YELLOW} 修改后，grub 默认首选启动替换为 Alpine Linux Minimal ${NC}"
read temp
if [ ${temp} = "y" ];then
    echo -e "${GREEN} 修改默认启动项 ${NC}"
    sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT="Alpine Linux Minimal"/' /etc/default/grub
else
    echo -e "${GREEN} 不修改默认启动项 ${NC}"
fi

# 更新 GRUB 配置
echo -e "${GREEN} 更新 GRUB 配置 ${NC}"
update-grub
echo -e "${GREEN} Done ${NC}"