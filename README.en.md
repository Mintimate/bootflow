# BootFlow 🚀
Minimal System Boot Toolset | "From BIOS to System, Simply Boot."

[中文说明](README.md)

Scripts:
- boot2rescue.sh: Installs a rescue mode system on Linux setups (supports x86 and ARM64 architectures).
- boot2cbs.sh: Downloads or moves user-provided ISO files (system images) to a mounted cloud disk, enabling boot and loading via Grub.

Repository Mirrors: [GitHub](https://github.com/Mintimate/bootflow)、[CNB](https://cnb.cool/Mintimate/tool-forge/bootflow)

## Alpine Rescue Mode

Designed for cloud servers from cloud providers, allowing system access via rescue mode. Some cloud providers offer independent rescue modes (e.g., Tencent Cloud), in which case this tool is theoretically unnecessary.

```bash
bash -c "$(wget -qO- https://cnb.cool/Mintimate/tool-forge/bootflow/-/git/raw/main/boot2rescue.sh)"
```

![Installation Process](assets/img/installShell.webp)

> For high-version systems like Debian 12, the default reboot is a fast reboot, which may require using `reboot -f` to force a reboot to enter the Grub boot interface.

After installation, you can make selections in the boot menu:

![Grub Selection Page](assets/img/grubUI.webp)

## Mount ISO for Grub Boot

Designed for cloud servers from cloud providers, where a cloud disk is pre-mounted to automatically download ISO files, then boot into the ISO installation interface via Grub.

Prerequisite: **Pre-mount a cloud disk to automatically download ISO files. The script will automatically download or copy ISOs to the isos directory in the root of the cloud disk**.

```bash
# Download the script
wget https://cnb.cool/Mintimate/tool-forge/bootflow/-/git/raw/main/boot2cbs.sh
# Execute the script
bash boot2cbs.sh -i <ISO file path/ISO download URL>
```

![Mount ISO for Grub Boot](assets/img/mountISO.webp)

After mounting, you can make selections in the boot menu:

![Grub ISO Selection](assets/img/grubUI-ISO.webp)

## License

[![GPLv3](gplv3.png)](LICENSE)