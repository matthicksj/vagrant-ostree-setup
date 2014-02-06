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

if [ "$(getenforce)" != "Permissive" ]; then
	echo "Sorry, you must set SELinux to permissive (e.g. setenforce 0) run this script"
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
CHROOT_DIR=$(find $MNT -type d -name "usr" | head -n 1 | sed "s^/usr^^")
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
VAGRANT_HOME=$MNT/ostree/deploy/fb2docker/var/vagranthome
mkdir -p $VAGRANT_HOME/.ssh
curl -s https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub > $VAGRANT_HOME/.ssh/authorized_keys
chmod 700 $VAGRANT_HOME/.ssh
chmod 600 $VAGRANT_HOME/.ssh/authorized_keys

# Now go into chroot and add the user
chroot $CHROOT_DIR useradd -d /var/vagranthome -M -u 501 vagrant
chown -R 501:501 $VAGRANT_HOME
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> $CHROOT_DIR/etc/sudoers

# Setup root user
echo "Setting up root user"
ROOT_HOME=$MNT/ostree/deploy/fb2docker/var/roothome
mkdir -p $ROOT_HOME/.ssh
curl -s https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub > $ROOT_HOME/.ssh/authorized_keys
chmod 700 $ROOT_HOME/.ssh
chmod 600 $ROOT_HOME/.ssh/authorized_keys

# System setup
echo "Applying various system settings"
chroot $CHROOT_DIR sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
chroot $CHROOT_DIR sed -i 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
chroot $CHROOT_DIR sed -i 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers

# Unmount
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