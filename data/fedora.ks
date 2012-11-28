install
keyboard BOXES_FEDORA_KBD
lang BOXES_LANG
network --onboot yes --device eth0 --bootproto dhcp --noipv6 --hostname=BOXES_HOSTNAME --activate
rootpw dummyPa55w0rd # Actual password set (or unset) in %post below
firewall --disabled
authconfig --enableshadow --enablemd5
selinux --enforcing
timezone --utc BOXES_TZ
bootloader --location=mbr
zerombr
clearpart --all --drives=vda

firstboot --disable

part biosboot --fstype=biosboot --size=1
part /boot --fstype ext4 --recommended --ondisk=vda
part pv.2 --size=1 --grow --ondisk=vda
volgroup VolGroup00 --pesize=32768 pv.2
logvol swap --fstype swap --name=LogVol01 --vgname=VolGroup00 --size=768 --grow --maxsize=1536
logvol / --fstype ext4 --name=LogVol00 --vgname=VolGroup00 --size=1024 --grow
reboot


%packages
@core
@hardware-support
@base-x
@gnome-desktop
@graphical-internet
@sound-and-video

# QXL video driver and SPICE vdagent
xorg-x11-drv-qxl
spice-vdagent

%end

%post --erroronfail

useradd -G wheel BOXES_USERNAME # Add user
if test -z BOXES_PASSWORD; then
    # Make both user and root account passwordless
    passwd -d BOXES_USERNAME
    passwd -d root
else
    echo BOXES_PASSWORD |passwd --stdin BOXES_USERNAME
    echo BOXES_PASSWORD |passwd --stdin root
fi

# Set user avatar
mkdir /mnt/unattended-media
mount /dev/sda /mnt/unattended-media
cp /mnt/unattended-media/BOXES_USERNAME /var/lib/AccountsService/icons/
umount /mnt/unattended-media
echo "
[User]
Language=
XSession=
Icon=/var/lib/AccountsService/icons/BOXES_USERNAME
" >> /var/lib/AccountsService/users/BOXES_USERNAME

# Enable autologin
echo "[daemon]
AutomaticLoginEnable=true
AutomaticLogin=BOXES_USERNAME

[security]

[xdmcp]

[greeter]

[chooser]

[debug]
" > /etc/gdm/custom.conf

%end
