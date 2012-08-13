import sys, subprocess, os

def cmd(cmdtext):
	result = subprocess.getstatusoutput(cmdtext)
	if result[0] != 0:
		print('Install failed!')
		sys.exit()

# read config file
config_file = open('/root/Desktop/install.conf')
config = dict()

curr_attr = ''
for line in config_file:
	line = line.replace('\n', '')
	if line != '' and line[0] != '#':
		if line[0] == '[' and line[-1] == ']':
			curr_attr = line.replace('[', '').replace(']', '')
		elif '=' in line:
			#print(line)
			split = line.split('=')
			if split[1] == '' and curr_attr == 'required':
				print("You must provide a value for " + split[0])
				sys.exit()
			elif split[1] != '':
				config[split[0]] = split[1]
				


print('Starting...')

# step 1: use gparted (already installed) to partition hard drive

# step 2: mount
print('Mounting drives...')

cmd('mount {} /mnt'.format(config['root_partition']))

if 'boot_partition' in config:
	cmd('mkdir /mnt/boot')
	cmd('mount {} /mnt/boot'.format(config['boot_partition']))

if 'home_partition' in config:
	cmd('mkdir /mnt/home')
	cmd('mount {} /mnt/home'.format(config['home_partition']))


# step 3: install base packages
print('Installing base packages...')
cmd('pacstrap /mnt base base-devel')

# step 4: install bootloader package
print('Installing bootloader...')
cmd('pacstrap /mnt {}'.format(config['bootloader_package']))

# step 5: configure
print('Configuring...')
cmd('genfstab -p /mnt >> /mnt/etc/fstab')

# exit chroot hack from: http://bytes.com/topic/python/answers/803078-exit-os-chroot
# chroot
real_root = os.open('/', os.O_RDONLY)
os.chroot('/mnt')

cmd('echo {} > /etc/hostname'.format(config['hostname']))
cmd('ln -s /usr/share/zoneinfo/{}/{} /etc/localtime'.format(config['locale_zone'], config['locale_subzone']))
cmd('locale-gen')
cmd('mkinitcpio -p linux')

# step 5.1: configure bootloader
print("Configuring bootloader...")
cmd('modprobe dm-mod')
cmd('grub-install /dev/sda')
cmd('grub-mkconfig -o /boot/grub/grub.cfg')

print("Set new root password:")
cmd('passwd')

if 'default_user' in config:
	cmd('useradd -m -g users -G audio,lp,optical,storage,video,wheel,games,power,scanner -s /bin/bash {}'.format(config['default_user']))
	print("Set {}'s password:")
	cmd('passwd {}'.format(config['default_user']))

# exit chroot
os.fchdir(real_root)
os.chroot('.')
os.close(real_root)

# step 6: unmount/cleanup
print("Unmounting...")
if 'boot_partition' in config:
	cmd('umount /mnt/boot')
if 'home_partition' in config:
	cmd('umount /mnt/home')
cmd('umount /mnt')

print('Arch installed. Reboot when ready.')