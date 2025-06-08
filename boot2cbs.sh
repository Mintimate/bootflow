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
    快速挂载 ISO 文件到 Grub 启动项内（需要提前挂载云盘）
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
    https://space.bilibili.com/355567627
_____________________________________________________________${NC}"
}

check_root() {
    # 检测root权限
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}错误：请使用 root 用户运行此脚本${NC}"
        exit 1
    fi
}


install_grub() {
    echo -e "${GREEN}使用 apt 安装相关依赖${NC}"
    # 安装必要工具
    apt-get update -y >>/dev/null
    apt-get install -y wget grub2-common util-linux rsync genisoimage >>/dev/null
    echo -e "${GREEN}安装必要工具完成${NC}"
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
    echo -e "${RED}错误：未找到任何可用的数据盘挂载点${NC}"
    return 1
  fi

  # 直接返回第一个挂载点
  echo "${disks[0]}"
  return 0
}

download_iso() {
    local iso_input="$1"

    ISO_NAME=$(basename "$iso_input")

    # 如果输入是 HTTP/HTTPS URL，则下载
    if [[ "$iso_input" =~ ^https?:// ]]; then
        echo -e "${YELLOW}检测到远程 ISO 文件，开始下载${NC}"
        ISO_PATH="$ISO_DIR/$ISO_NAME"

        # 如果文件已存在，跳过下载
        if [ -f "$ISO_PATH" ]; then
            ehco -e "${GREEN}$ISO_PATH 已存在，跳过下载${NC}"
            return 0
        fi

        # 下载 ISO 文件
        echo "正在下载 ISO 文件: $ISO_NAME"
        wget --show-progress -q -O "$ISO_PATH" "$iso_input" || {
            echo -e "${RED}下载失败${NC}"
            exit 1
        }

        # 验证 ISO 文件
        if ! file "$ISO_PATH" | grep -q "ISO"; then
            echo -e "${RED}下载的文件不是 ISO 格式${NC}"
            exit 1
        fi

    # 如果输入是本地路径，直接使用
    elif [ -f "$iso_input" ]; then
        echo -e "${GREEN}检测到本地 ISO 文件，直接使用${NC}"
        ISO_PATH="$iso_input"
        echo -e "${GREEN}复制到云硬盘挂载目录 $ISO_DIR${NC}"
        rsync -ah --progress $iso_input "$ISO_DIR"
    # 无效输入
    else
        echo -e "${RED}错误：无效的 ISO 输入（必须是 URL 或本地文件路径）${NC}"
        exit 1
    fi
}

# 从 ISO 提取 initrd.gz 和 vmlinuz 路径
extract_kernel_paths() {
    local ISO_FILE="$1"

    # 检查文件是否存在
    if [ ! -f "$ISO_FILE" ]; then
        echo -e "${RED}ISO 文件不存在: $ISO_FILE${NC}"
        return 1
    fi

    # 使用 isoinfo 查找路径
    local PATHS
    PATHS=$(isoinfo -R -i "$ISO_FILE" -f | grep -E "initrd.gz|vmlinuz" || {
        echo -e "${RED}错误: 无法从ISO中提取内核启动路径${NC}"
        return 1
    })

    # 提取第一条 initrd.gz 和 vmlinuz
    INITRD=$(echo "$PATHS" | grep "initrd.gz" | head -n 1)
    VMLINUZ=$(echo "$PATHS" | grep "vmlinuz" | head -n 1)

    # 检查是否成功获取路径
    if [ -z "$INITRD" ] || [ -z "$VMLINUZ" ]; then
        echo -e "${RED}错误: 无法从ISO中提取内核启动路径${NC}"
        return 1
    fi

    # 打印结果（调试用）
    echo -e "${GREEN}提取到的内核路径:${NC}"
    echo -e "${GREEN}  initrd.gz: $INITRD${NC}"
    echo -e "${GREEN}  vmlinuz:   $VMLINUZ${NC}"
    echo -e "${GREEN}  ISO文件:   $ISO_FILE${NC}"

}

### 主脚本逻辑 ###

# 解析命令行参数
check_root
# 检查参数
if [ $# -eq 0 ] || [[ "$1" != "-i" && "$1" != "--iso" ]]; then
    echo -e "${RED}用法: $0 -i|--iso <URL或本地路径>${NC}"
    exit 1
fi

# 安装必要工具
install_grub

# 打印
printMintimate
echo -e "${YELLOW} 是否确认使用脚本，下载 ISO 文件到数据盘并配置 GRUB 引导${NC}"
read temp
if [ ${temp} = "y" ]; then
    echo -e "${GREEN} 继续执行脚本 ${NC}"
else
    echo -e "${GREEN} Good bye, See U! ${NC}"
    exit 1
fi

# 获取ISO路径
ISO_INPUT="$2"
[ -z "$ISO_INPUT" ] && { echo -e "${RED}必须指定ISO路径${NC}"; exit 1; }

# 设置存储目录
DATA_DIR=$(find_data_disk) || { echo -e "${RED}未找到数据盘${NC}"; exit 1; }
ISO_DIR="$DATA_DIR/isos"
mkdir -p "$ISO_DIR"

# 下载ISO文件
if ! download_iso "$ISO_INPUT"; then
    exit 1
fi

# 提取内核路径
if ! extract_kernel_paths "$ISO_PATH"; then
    exit 1
fi

# 查找分区UUID
DISK_UUID=$(findmnt -n -o UUID -T "$ISO_PATH")
if [ -z "$DISK_UUID" ]; then
  echo -e "${RED}无法找到ISO文件所在的分区UUID${NC}"
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
    loopback loop /isos/$ISO_NAME
    linux (loop)$VMLINUZ boot=live components findiso=/isos/$ISO_NAME
    initrd (loop)$INITRD
}

EOF

# 设置可执行权限
chmod a+x "$GRUB_ISO_CONF"

# 更新GRUB配置
echo -e "${GREEN}正在更新GRUB配置${NC}"
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "${GREEN}ISO引导已配置完成${NC}"
echo -e "${GREEN}ISO文件保存在: $ISO_PATH${NC}"

echo -e "${YELLOW}tips${NC}"
echo -e "${YELLOW}如需修在，请删除 $GRUB_ISO_CONF 文件${NC}"
echo -e "${YELLOW}并执行 grub-mkconfig -o /boot/grub/grub.cfg ${NC}"