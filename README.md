> The [wiki](https://github.com/KiruyaMomochi/wsa-tools/wiki) is open!

# WSA Tools

Some tools for working with the Windows Subsystem for Android.

## Problems

- `add-google.sh` doesn't work for Arm64 now.

## References

- [LSPosed/WSA-Kernel-SU](https://github.com/LSPosed/WSA-Kernel-SU)
- [knackebrot/WSAGAScript](https://github.com/knackebrot/WSAGAScript)
- [KiruyaMomochi/wsa-kernel-build](https://github.com/KiruyaMomochi/wsa-kernel-build)

## Q & A

### How to screenshot automacally?

Since `screencap` is not working, we need to find a way to do it.

There are basically two ideas:

1. Capture the window on Windows directly.
    Refer `https://github.com/robmikh/screenshot-rs`.

2. Create a server on Android and send the image to us.
    Refer `https://github.com/Genymobile/scrcpy`.
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
