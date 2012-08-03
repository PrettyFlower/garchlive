#!/bin/bash

CONF_FILE="install.config"
for i in `cat $CONF_FILE | grep '^[^#].*'`
do
	var=`echo "$i" | awk -F"=" '{print $1}'`
	param=`echo "$i" | awk -F"=" '{print $2}'`
	if [ "$param" == "" ]; then
		echo "You must set "$var" in install.config."
		exit 1
	fi
	eval $var=$param
done

echo "Starting..."

# step 1: use gparted (already installed) to partition hard drive
# this setup assumes boot/root/home

# step 2: mount
echo "Mounting drives..."
mount $root_partition /mnt
mkdir /mnt/boot
mount $boot_partition /mnt/boot
mkdir /mnt/home
mount $home_partition /mnt/home

# step 3: install base packages
echo "Installing packages..."
pacstrap /mnt \
base \
base-devel \
ntp \
dbus \
networkmanager \
most \
zsh \
xf86-video-vesa \
virtualbox-archlinux-additions \
xfce4 \
gparted \
gedit \
pidgin \
firefox \
flashplugin \
yaourt \
 \
xorg-appres \
xorg-bdftopcf \
xorg-docs \
xorg-font-util \
xorg-font-utils \
xorg-fonts-100dpi \
xorg-fonts-75dpi \
xorg-fonts-alias \
xorg-fonts-encodings \
xorg-fonts-misc \
xorg-iceauth \
xorg-luit \
xorg-mkfontdir \
xorg-mkfontscale \
xorg-server \
xorg-server-common \
xorg-setxkbmap \
xorg-xauth \
xorg-xinit \
xorg-xkbcomp \
xorg-xmessage \
xorg-xprop \
xorg-xrandr \
xorg-xrdb \
xorg-xset \
xorg-xsetroot

# step 4: install bootloader package
echo "Installing bootloader..."
pacstrap /mnt $bootloader_package

# step 5: configure
echo "Configuring..."
genfstab -p /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash -c "echo \"$hostname\" > /etc/hostname"
arch-chroot /mnt /bin/bash -c "ln -s /usr/share/zoneinfo/$locale_zone/$locale_subzone /etc/localtime"
arch-chroot /mnt /bin/bash -c "locale-gen"
arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux"

# step 5.1: configure bootloader
echo "Configuring bootloader..."
arch-chroot /mnt /bin/bash -c "modprobe dm-mod"
arch-chroot /mnt /bin/bash -c "grub-install --debug /dev/sda"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

echo "Set new root password:"
arch-chroot /mnt /bin/bash -c "passwd"

arch-chroot /mnt /bin/bash -c "useradd -m -g users -G audio,lp,optical,storage,video,wheel,games,power,scanner -s /bin/bash $default_user"
echo "Set default user password:"
arch-chroot /mnt /bin/bash -c "passwd $default_user"

# step 6: unmount/cleanup
echo "Unmounting..."
umount /mnt/boot
umount /mnt/home
umount /mnt

echo "Arch installed. Reboot when ready."