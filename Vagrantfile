# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_plugin "vagrant-libvirt"

Vagrant.configure("2") do |config|
  config.vm.box = "atomic"

  config.vm.define :atomic_vm do |atomic_vm|
    atomic_vm.vm.network :bridged, :adapter => 1
    atomic_vm.vm.network :bridged, :adapter => 2
  end

  config.vm.provider :libvirt do |libvirt|
    # Options for libvirt vagrant provider. Default options are commented.

    # A hypervisor name to access. Some examples of drivers are qemu (KVM/qemu),
    # xen (Xen hypervisor), lxc (Linux Containers), esx (VMware ESX), vmwarews
    # (VMware Workstation) and more. Refer to documentation for available
    # drivers (http://libvirt.org/drivers.html).
    # libvirt.driver = "qemu"

    # The name of the server, where libvirtd is running.
    # libvirt.host = "localhost"

    # If use ssh tunnel to connect to Libvirt.
    # libvirt.connect_via_ssh = false

    # The username and password to access Libvirt.
    # libvirt.username = "username"
    # libvirt.password = "secret"

    # Libvirt storage pool name, where box image and instance snapshots will
    # be stored.
    # libvirt.storage_pool_name = "default"
  end
end

