rm work/x86_64/root-image/etc/systemd/system/default.target
ln -s /usr/lib/systemd/system/graphical.target work/x86_64/root-image/etc/systemd/system/default.target
rm work/x86_64/root-image/etc/systemd/system/graphical.target.wants/startxfce4.service
ln -s /etc/systemd/system/startxfce4.service work/x86_64/root-image/etc/systemd/system/graphical.target.wants/startxfce4.service