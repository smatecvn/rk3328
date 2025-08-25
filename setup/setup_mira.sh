#!/bin/bash

# Setup I2C
touch /etc/udev/rules.d/99-i2c.rules
echo 'KERNEL=="i2c-4", SYMLINK+="i2c-2"' > /etc/udev/rules.d/99-i2c.rules
udevadm control --reload-rules
udevadm trigger

# Setup script
cp init_4g_module.sh /usr/local/bin/init_4g_module.sh
chmod +x /usr/local/bin/init_4g_module.sh
cp netcfg-watcher.sh /usr/local/bin/netcfg-watcher.sh
chmod +x /usr/local/bin/netcfg-watcher.sh
cp setup_leds.sh /usr/local/bin/setup_leds.sh
chmod +x /usr/local/bin/setup_leds.sh
cp check_and_start_container.sh /usr/local/bin/check_and_start_container.sh
chmod +x /usr/local/bin/check_and_start_container.sh

# Setup tools
apt update  && apt install -y inotify-tools

# Setup default network
cp request.json /etc/netplan

# Setup network monitor service
cp netcfg-watcher.service /etc/systemd/system/netcfg-watcher.service
systemctl daemon-reload
systemctl enable netcfg-watcher
systemctl start netcfg-watcher

# Setup 4G reset pin
cp pre-docker-gpio.service /etc/systemd/system/pre-docker-gpio.service
systemctl daemon-reload
systemctl enable pre-docker-gpio.service
systemctl start pre-docker-gpio.service

# Setup network leds (Link + Traffic)
#cp setup-leds.service /etc/systemd/system/setup-leds.service
#systemctl daemon-reload
#systemctl enable setup-leds.service
#systemctl start setup-leds.service

# Setup crontab, monitor mira container
(crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/check_and_start_container.sh") | crontab -

# Setup /dev/ttyUSB3 used for mgwp app. ModemManager use /dev/ttyUSB2 by default
touch /etc/udev/rules.d/99-mm-ignore.rules
echo 'KERNEL=="ttyUSB3", ENV{ID_MM_DEVICE_IGNORE}="1"' > /etc/udev/rules.d/99-mm-ignore.rules
udevadm control --reload-rules
udevadm trigger