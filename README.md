# BootFlow 🚀
​​极简系统引导工具集​​ | "From BIOS to System, Simply Boot."

## Alpine 救援模式

适用于在云厂商的云服务器上，通过救援模式进入系统。部分云厂商有提供独立的救援模式（比如： 腾讯云），那么理论上不需要使用本工具。

```bash
bash -c "$(wget -qO- https://cnb.cool/Mintimate/tool-forge/bootflow/-/git/raw/main/boot2rescue.sh)"
```

![安装过程](assets/img/installShell.webp)

> Debian 12 等高版本系统，默认重启是快速重启，可能需要使用`reboot -f` 强制重启才可以进入 grub 引导界面。

安装后，可以在开机引导内进行选择：

![grub选择页面](assets/img/grubUI.webp)

## Licence

[![GPLv3](gplv3.png)](LICENSE)