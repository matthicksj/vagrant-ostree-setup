Vagrant Setup
=============

This is a simple script to convert a qcow2 ostree image to a Vagrant image.
You should be able to run the setup script and it will copy the qcow2 image,
crack it open and add the required users and SSH setup for Vagrant.  It will
then use the templates in this project for the libvirt provider defaults
and package everything up as a Vagrant box that you can import.

Usage
------
To convert an image, first you'll need to temporarily disable SELinux:

    sudo setenforce 0

Next, you run the setup.sh script with a qcow2 image:

    sudo ./setup.sh <path to qcow2 image>

When complete, you will have a Vagrant box with the same name as your image
stored in /tmp.  You can simply import into Vagrant with:

    vagrant box add myimage /tmp/<image>

And after that, just following the normal Vagrant instructions for initializing,
starting, stopping, etc.


LibVirt Vagrant Provider
========================

You'll want to make sure you have the libvirt provider installed in Vagrant
to run these images.  Follow the instructions at [pradels/vagrant-libvirt](https://github.com/pradels/vagrant-libvirt).


