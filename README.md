> The [wiki](https://github.com/KiruyaMomochi/wsa-tools/wiki) is open!

# WSA Tools

Some tools for working with the Windows Subsystem for Android.

## Problems

- `add-google.sh` doesn't work for Arm64 now.
    - Consider use [ADeltaX/WSAGAScript](https://github.com/ADeltaX/WSAGAScript) and modify script.
- Magisk sometimes doesn't work after reboot, however, kernel su is always working.

## References

- [LSPosed/WSA-Kernel-SU](https://github.com/LSPosed/WSA-Kernel-SU)
- [knackebrot/WSAGAScript](https://github.com/knackebrot/WSAGAScript)
    - Consider use [ADeltaX/WSAGAScript](https://github.com/ADeltaX/WSAGAScript) and modify script.
- [KiruyaMomochi/wsa-kernel-build](https://github.com/KiruyaMomochi/wsa-kernel-build)

## Tips & Tricks

### Specify device for `adb`

Use

    adb -s <device> <command>

For example, use `adb -s 127.0.0.1:58526 <commmand>` for WSA.

## Q & A

### How to screenshot automacally?

Since `screencap` is not working, we need to find a way to do it.

There are basically two ideas:

1. Capture the window on Windows directly.
    Refer <https://github.com/robmikh/screenshot-rs>.

2. Create a server on Android and send the image to us.
    Refer <https://github.com/Genymobile/scrcpy>.
    However it only support screen record, we may need to modify it.

### I can't install Google, lot's of error about security context

Your distribution seems not support SELinux. For example, Arch users will see many errors.

For Arch, the solution is to install some SELinux packages:
1. add the following lines to your /etc/pacman.conf:
    ```conf
    [selinux]
    Server = https://github.com/archlinuxhardened/selinux/releases/download/ArchLinux-SELinux
    SigLevel = Never
    ```
2. run `pacman -Sy coreutils-selinux shadow-selinux cronie-selinux sudo-selinux`
    > ⚠️ !!! After this, sudoer files may be reset. So make sure you can login as root before install.
3. Try build images again.

### The Play Store opens, but I can't add any account

It's possible that you download the wrong architecture.

Please download the correct version from <https://opengapps.org>.

### Is there any easier way to change content of a installed Packaged App

You can ignore Access Control by [NyaMisty/IgnoreACLs](https://github.com/NyaMisty/IgnoreACLs).
But your computer may in risk, so take care of it.

- The original repo [DavidXanatos/IgnoreACLs](https://github.com/DavidXanatos/IgnoreACLs) may have issues with Windows 11.
