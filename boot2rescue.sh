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

default_boot=false

# 解析参数（支持 -d 1 和 --default）
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d)
      if [ "$2" = "1" ]; then
        echo -e "${YELLOW} 操作结束后，配置为默认启动项 ${NC}"
        default_boot=true
        shift 2
      else
        echo -e "${RED} 错误: -d 参数必须为 1 ${NC}"
        exit 1
      fi
      ;;
    --default)
      echo -e "${YELLOW} 操作结束后，配置为默认启动项 ${NC}"
      default_boot=true
      shift
      ;;
    *)
      echo -e "${RED} 错误: 未知参数 $1 ${NC}"
      exit 1
      ;;
  esac
done

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
if [ "$default_boot" = true ]; then
    echo -e "${GREEN} 修改默认启动项 ${NC}"
    sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT="Alpine Linux Minimal"/' /etc/default/grub
fi

# 更新 GRUB 配置
echo -e "${GREEN} 更新 GRUB 配置 ${NC}"
update-grub
echo -e "${GREEN} Done ${NC}"