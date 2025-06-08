#!/bin/bash
# Description:

# Author: @Mintimate
# Blog: https://www.mintimate.cn/about

# echo 标准化
RED='\033[0;31m'    # 红色
GREEN='\033[0;32m'  # 绿色
YELLOW='\033[0;33m' # 黄色
NC='\033[0m'        # 重置颜色

# 遇到错误立即退出
set -e


check_root() {
    # 检测root权限
    if [ "$(id -u)" -ne 0 ]; then
    echo "请使用root权限运行此脚本"
    exit 1
    fi
}


install_grub() {
    # 安装必要工具
    apt update
    apt install -y wget grub2-common util-linux genisoimage
}


# 查找数据盘挂载点
find_data_disk() {
  local disks=()
  
  # 使用 findmnt 获取所有符合条件的挂载点
  while IFS= read -r mount; do
    # 排除系统关键目录，匹配常见数据盘挂载点
    if [[ $mount =~ ^/(media|mnt|data)(/|$) ]] && 
       [[ ! $mount =~ ^/(boot|home|var|usr)(/|$) ]]; then
      disks+=("$mount")
    fi
  done < <(findmnt -nr -o TARGET -t ext4,btrfs,xfs,ntfs,fat,vfat 2>/dev/null)

  # 如果没有找到数据盘，直接报错退出
  if [ ${#disks[@]} -eq 0 ]; then
    echo "错误：未找到任何可用的数据盘挂载点" >&2
    return 1
  fi

  # 直接返回第一个挂载点
  echo "${disks[0]}"
  return 0
}

download_iso() {
    local iso_input="$1"

    # 如果输入是 HTTP/HTTPS URL，则下载
    if [[ "$iso_input" =~ ^https?:// ]]; then
        echo "检测到 ISO URL，开始下载..."
        ISO_NAME=$(basename "$iso_input")
        ISO_PATH="$ISO_DIR/$ISO_NAME"
        
        # 如果文件已存在，跳过下载
        if [ -f "$ISO_PATH" ]; then
            echo "ISO 文件已存在: $ISO_PATH"
            return 0
        fi

        # 下载 ISO 文件
        echo "正在下载 ISO 文件: $ISO_NAME"
        wget --show-progress -q -O "$ISO_PATH" "$iso_input" || {
            echo "下载失败"
            exit 1
        }

        # 验证 ISO 文件
        if ! file "$ISO_PATH" | grep -q "ISO"; then
            echo "下载的文件不是有效的 ISO 镜像"
            exit 1
        fi

    # 如果输入是本地路径，直接使用
    elif [ -f "$iso_input" ]; then
        echo "检测到本地 ISO 文件: $iso_input"
        ISO_PATH="$iso_input"

    # 无效输入
    else
        echo "错误：无效的 ISO 输入（必须是 URL 或本地文件路径）"
        exit 1
    fi
}

# 从 ISO 提取 initrd.gz 和 vmlinuz 路径
extract_kernel_paths() {
    local ISO_FILE="$1"
    
    # 检查文件是否存在
    if [ ! -f "$ISO_FILE" ]; then
        echo "Error: ISO file '$ISO_FILE' not found!" >&2
        return 1
    fi

    # 使用 isoinfo 查找路径
    local PATHS
    PATHS=$(isoinfo -R -i "$ISO_FILE" -f | grep -E "initrd.gz|vmlinuz" || {
        echo "Error: Failed to extract paths from ISO." >&2
        return 1
    })

    # 提取第一条 initrd.gz 和 vmlinuz
    INITRD=$(echo "$PATHS" | grep "initrd.gz" | head -n 1)
    VMLINUZ=$(echo "$PATHS" | grep "vmlinuz" | head -n 1)

    # 检查是否成功获取路径
    if [ -z "$INITRD" ] || [ -z "$VMLINUZ" ]; then
        echo "Error: Required files (initrd.gz or vmlinuz) not found in ISO." >&2
        return 1
    fi

    # 打印结果（调试用）
    echo "Extracted paths:"
    echo "INITRD=$INITRD"
    echo "VMLINUZ=$VMLINUZ"
}

### 主脚本逻辑 ###

# 解析命令行参数
while getopts ":iso:" opt; do
    case "$opt" in
        iso)
            # 创建ISO存储目录
            if DATA_DIR=$(find_data_disk); then
                echo -e "${GREEN} 数据盘挂载点: $data_dir ${NC}"
            else
                echo -e "${RED} 未找到可用的数据盘 ${NC}"
                exit 1
            fi
            ISO_DIR="$DATA_DIR/isos"
            mkdir -p "$ISO_DIR"
            download_iso "$OPTARG"
            ;;
        *)
            echo "用法: $0 -iso <URL或本地路径>"
            exit 1
            ;;
    esac
done

# 提取内核路径
extract_kernel_paths "$ISO_PATH" || exit 1

# 查找分区UUID
DISK_UUID=$(findmnt -n -o UUID -T "$ISO_PATH")
if [ -z "$DISK_UUID" ]; then
  echo "无法获取分区UUID"
  exit 1
fi

# 配置GRUB引导
GRUB_ISO_CONF="/etc/grub.d/40_custom_iso"

# 生成GRUB配置
cat << EOF > "$GRUB_ISO_CONF"
#!/bin/sh
exec tail -n +3 \$0

menuentry "Boot from ISO" {
    # 通过 UUID 定位外置存储
    search --no-floppy --fs-uuid --set=root $DISK_UUID

    # 设置 ISO 文件路径（相对于外置存储的根目录）
    set isofile=/isos/$ISO_NAME

    # 挂载 ISO 并加载内核
    loopback loop $isofile
    linux (loop)/$kernel boot=live components findiso=$isofile
    initrd (loop)/$initrd
}

EOF

# 设置可执行权限
chmod a+x "$GRUB_ISO_CONF"

# 更新GRUB配置
echo "正在更新引导配置..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "配置完成！可重启系统并选择从ISO启动"
echo "ISO文件保存在: $ISO_PATH"
echo "手动恢复: 删除 $GRUB_ISO_CONF 并运行 grub-mkconfig"
