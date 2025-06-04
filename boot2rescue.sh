#!/bin/bash

default_boot=false

# 解析参数（支持 -d 1 和 --default）
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d)
      if [ "$2" = "1" ]; then
        default_boot=true
        shift 2
      else
        echo "错误: -d 参数必须为 1" >&2
        exit 1
      fi
      ;;
    --default)
      default_boot=true
      shift
      ;;
    *)
      echo "未知参数: $1" >&2
      exit 1
      ;;
  esac
done

# 创建netboot目录并进入
mkdir -p /netboot && cd /netboot || exit

# 设置镜像源
rgeo="https://mirrors.tuna.tsinghua.edu.cn/alpine/edge"

# 下载必要文件
wget "$repo/releases/x86_64/netboot/vmlinuz-virt" || exit
wget "$repo/releases/x86_64/netboot/initramfs-virt" || exit
modl="$repo/releases/x86_64/netboot/modloop-virt"

# 添加GRUB启动项
cat >> /etc/grub.d/40_custom <<EOF
menuentry "Alpine Linux Minimal" {
    search --set=root --file /netboot/vmlinuz-virt
    linux /netboot/vmlinuz-virt console=tty0 console=ttyS0,115200 ip=dhcp modloop=$modl alpine_repo=$repo/main/
    initrd /netboot/initramfs-virt
}
EOF

# 修改默认启动项
if [ "$default_boot" = true ]; then
    sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT="Alpine Linux Minimal"/' /etc/default/grub
fi

# 更新 GRUB 配置
update-grub