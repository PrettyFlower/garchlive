I recommend partitioning your hard drive first using GParted.

Then you can either install manually using the instructions on https://wiki.archlinux.org/index.php/Installation_Guide or use the arch ultimate install script. To run the install script, just open a terminal and type:


cd /root/Desktop
./aui --ais

This will run the installation script to put Arch on your computer. Once this is complete, it will prompt you to reboot and let you know that its included a copy of the aui script in root. When you have rebooted, run 

./aui

and this will help you configure the rest of your system with nice things like a desktop environment.