#!/bin/bash

set -e

CONF_FILE="install.conf"
while read i
do
	comment=`echo $i | sed -e 's/#.*//'`
	if [ "$comment" != "" ]; then
		attr_type=`echo "$i" | awk 'NR>1{print $1}' RS=[ FS=]`
		if [ "$attr_type" != "" ]; then
			curr_attr=$attr_type
		else
			var=`echo "$i" | awk -F"=" '{print $1}'`
			param=`echo "$i" | awk -F"=" '{print $2}'`
			echo $i
			if [ "$param" == "" ] && [ "$curr_attr" == "required" ]; then
				echo "You must set "$var" in install.conf."
				exit 1
			elif [ "$var" == "efi_partition" ] && [ -n "$param" ] && [ "$bootloader_package" == "grub-efi-x86_64" ]; then
				echo "You must specify the efi partition if you are using grub-efi-x86_64."
				exit 1
			fi
			eval $var='$param'
		fi
	fi
done < $CONF_FILE

echo "Starting..."

# step 1: use gparted (already installed) to partition hard drive
# this setup assumes boot/root/home

# step 2: mount
echo "Mounting drives..."
mount $root_partition /mnt
if [ -n "$boot_partition" ]; then
	mkdir /mnt/boot
	mount $boot_partition /mnt/boot
fi
if [ -n "$home_partition" ]; then
	mkdir /mnt/home
	mount $home_partition /mnt/home
fi

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
mkdir -p /mnt/boot/grub/locale
cp /mnt/usr/share/locale/en@quot/LC_MESSAGES/grub.mo /mnt/boot/grub/locale/en.mo
arch-chroot /mnt /bin/bash -c "modprobe dm-mod"

if [ "$bootloader_package" == 'grub-bios' ]; then
	drive=$(echo $boot_partition | sed -e 's/[0-9]//')
	arch-chroot /mnt /bin/bash -c "grub-install $drive"
else
	arch-chroot /mnt /bin/bash -c "mkdir -p /boot/efi"
	arch-chroot /mnt /bin/bash -c "mount -t vfat $efi_partition /boot/efi"
	arch-chroot /mnt /bin/bash -c "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck --debug"
fi
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