dracut -f --kver `uname -r`
grub2-mkconfig > /etc/grub2-efi.cfg

