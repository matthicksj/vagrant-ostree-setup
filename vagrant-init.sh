#!/bin/sh

# Do the SSH configuration
sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
sed -i 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers

# Add the vagrant user
useradd -M vagrant

# Make sure the home directory permissions are right
chown -R vagrant:vagrant /var/home/vagrant
chcon -u system_u -t home_root_t /var/home
chcon -u unconfined_u -t user_home_dir_t /var/home/vagrant
chcon -R -u unconfined_u -t ssh_home_t /var/home/vagrant/.ssh
chmod 700 /var/home/vagrant/.ssh
chmod 600 /var/home/vagrant/.ssh/authorized_keys

# Setup the sudoers entry
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers