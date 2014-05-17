Vagrant.configure("2") do |config|
  config.vm.box = "atomic"

  config.vm.network "forwarded_port", guest: 43273, host: 43273
  config.vm.network "forwarded_port", guest: 6060, host: 2225
  config.vm.network "forwarded_port", guest: 14000, host: 14000
  config.vm.network "forwarded_port", guest: 2181, host: 2181
  config.vm.network "forwarded_port", guest: 1001, host: 1001
  for i in 4000..4050
    config.vm.network :forwarded_port, guest: i, host: i
  end

  config.vm.synced_folder './', '/vagrant', type: 'rsync', disabled: true

  config.vm.provider :virtualbox do |v|
    v.memory = 4096
    v.cpus =4
    v.customize ["modifyvm", :id, "--cpus", "4"]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  config.vm.provider :libvirt do |libvirt|
    libvirt.cpus = 4
    libvirt.memory = 4096
    libvirt.driver = 'kvm' # needed for kvm performance benefits!
    libvirt.connect_via_ssh = false
    libvirt.username = 'root'
  end
end

