#!/bin/sh

#
# This script will take a freshly installed qcow2 image and
# do the required Vagrant processing to package up a libvirt
# provider box.
#
# Usage: ./setup.sh <path to qcow2 image>
#
# Note, the script request the 'guestmount' program so you will
# most likely require the libguestfs-tools package to be installed:
#
#   sudo yum install libguestfs-tools
#
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

IMG=$1
shift

if [ "$(whoami)" != "root" ]; then
	echo "Sorry, you must run this script as root"
	exit 1
fi

if [ -z "$IMG" ]; then
    echo "No image was supplied"
    echo "Usage: $0 <path to qcow2 image>"
    exit 1
fi

# Determine the final box output name from the original image
OUTPUT_NAME=$(basename -s '.qcow2' $IMG)
echo "Final image name will be: $OUTPUT_NAME.box"

# Create a working directory
TDIR=`mktemp -d`
chmod 755 $TDIR

# Make a copy of the image for processing
echo "Making a copy of the image"
cp $IMG $TDIR/box.img
IMG=$TDIR/box.img
echo "New image = $IMG"

# Setup a mount directory
MNT=$TDIR/mnt-img
mkdir $MNT

# Mount the image to do the Vagrant setup
echo "Mounting image at $MNT"
guestmount -a "$IMG" -m /dev/sda3:/ -m /dev/sda1:/boot $MNT

# Locate the core changeroot location by finding the first instance of a 'usr' dir
CHROOT_DIR="$MNT/ostree/deploy/rh-atomic-controller/current"
echo "Chroot dir: $CHROOT_DIR"

# Safeguard
if [ "$CHROOT_DIR" == "/" ]; then
	echo "Error - chroot location determination in image failed.  Chroot is trying to run on '/'."
	exit 1
fi

# Verify we can run something in the chroot
chroot $CHROOT_DIR ls > /dev/null
if [ "$?" != 0 ]; then
	echo "Error - chroot test failed.  Wasn't able to run command in chroot"
	exit 1
fi

# Setup the vagrant user home directory
echo "Setting up vagrant user"
VAGRANT_HOME=$MNT/ostree/deploy/rh-atomic-controller/var/home/vagrant
mkdir -p $VAGRANT_HOME/.ssh
curl -s https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub > $VAGRANT_HOME/.ssh/authorized_keys
chmod 700 $VAGRANT_HOME/.ssh
chmod 600 $VAGRANT_HOME/.ssh/authorized_keys

# Setup an init script to finish vagrant setup
SYSTEMD_DIR=$CHROOT_DIR/usr/lib/systemd

# Create the actual user, set ownership and fix SELinux permissions when the system starts
# Otherwise, all the files touched will get the wrong permissions and context information
# and it causes all sorts of weird issues.
# Create the service itself
cat > $SYSTEMD_DIR/system/vagrant-init.service << EOF
[Unit]
Description=Relabel home directories on startup
Before=sshd.service

[Service]
Type=oneshot
ExecStart=/usr/bin/sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
ExecStart=/usr/bin/sed -i 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
ExecStart=/usr/bin/sed -i 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers
ExecStart=/usr/bin/echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
ExecStart=/usr/sbin/useradd -M vagrant
ExecStart=/usr/bin/chown -R vagrant:vagrant /var/home/vagrant
ExecStart=/usr/bin/chcon -u system_u -t home_root_t /var/home
ExecStart=/usr/bin/chcon -u unconfined_u -t user_home_dir_t /var/home/vagrant
ExecStart=/usr/bin/chcon -R -u unconfined_u -t ssh_home_t /var/home/vagrant/.ssh
ExecStart=/usr/sbin/restorecon /etc/ssh/sshd_config
ExecStart=rm /etc/systemd/system/multi-user.target.wants/vagrant-init.service

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
ln -s $SYSTEMD_DIR/system/vagrant-init.service $CHROOT_DIR/etc/systemd/system/multi-user.target.wants/vagrant-init.service

# Unmount
sync
fusermount -u $MNT

# Allow umount and flushing of data to occur
sleep 5

# Copy the vagrant artifacts over to make a box
cp $DIR/Vagrantfile $TDIR
cp $DIR/metadata.json $TDIR

# Package up the Vagrant box
echo "Creating vagrant box"
pushd $TDIR > /dev/null
tar cvf $OUTPUT_NAME.box ./metadata.json ./Vagrantfile ./box.img > /dev/null
popd > /dev/null

echo "New Box created at: /tmp/$OUTPUT_NAME.box"
mv $TDIR/$OUTPUT_NAME.box /tmp

# Clean up temporary files
rm -rf $TDIR
