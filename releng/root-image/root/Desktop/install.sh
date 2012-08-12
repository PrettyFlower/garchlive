#!/bin/bash

set -e

CONF_FILE="install.conf"
while read i
do
	comment=`echo $i | sed -e 's/#.*//'`
	curr_attr=""
	if [ "$comment" != "" ]; then
		attr_type=`echo "$i" | awk 'NR>1{print $1}' RS=[ FS=]`
		if [ "$attr_type" != "" ]; then
			curr_attr=( $(eval "echo \$$attr_type") )
			echo $curr_attr
		else
			var=`echo "$i" | awk -F"=" '{print $1}'`
			param=`echo "$i" | awk -F"=" '{print $2}'`
			#echo $i
			echo $curr_attr
			if [ "$param" == "" ] && [ "$curr_attr"=="required" ]; then
				echo "You must set "$var" in install.conf."
				exit 1
			fi
			eval $var='$param'
		fi
	fi
done < $CONF_FILE

echo "Starting..."

exit 1

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
pacstrap /mnt base base-devel

# step 4: install bootloader package
echo "Installing bootloader..."
pacstrap /mnt $bootloader_package

# step 5: configure
echo "Configuring..."
genfstab -p /mnt >> /mnt/etc/fstab
echo $hostname > /mnt/etc/hostname
ln -s /mnt/usr/share/zoneinfo/$locale_zone/$locale_subzone /mnt/etc/localtime
safe_locale_preference=$(printf "%s\n" "$locale_preference" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/#$safe_locale_preference/$safe_locale_preference/" /mnt/etc/locale.gen
arch-chroot /mnt /bin/bash -c "locale-gen"
arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux"

# step 5.1: configure bootloader
echo "Configuring bootloader..."
arch-chroot /mnt /bin/bash -c "modprobe dm-mod"
arch-chroot /mnt /bin/bash -c "grub-install /dev/sda"
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