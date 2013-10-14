#
# Cookbook Name:: ubuntu_server
# Recipe:: default
#
# Copyright 2013, Naoya Nakazawa
#
# All rights reserved - Do Not Redistribute
#


#
# /bin/sh => /bin/bash
#
link "/bin/sh" do
  to "/bin/bash"
  notifies :run, "execute[dpkg-reconfigure-dash]"
end

execute "dpkg-reconfigure-dash" do
  command "echo \"dash    dash/sh boolean false\" | debconf-set-selections ; dpkg-reconfigure --frontend=noninteractive dash"
  action :nothing
end


#
# /etc/environment
#
file "/etc/environment" do
  mode 0644
  content <<-EOH
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
SHELL="/bin/bash"
LANG="en_US.UTF-8"
EDITOR="/usr/bin/vim"
EOH
end


#
# Editor and Ruby 1.9.3
#
link "/etc/alternatives/editor" do
  to "/usr/bin/vim"
end
link "/etc/alternatives/editor.1.gz" do
  to "/usr/share/man/man1/vim.1.gz"
end


#
# Directory
#
directory "/usr/local/script" do
  mode 0755
  action :create
end


#
# Packages
#
execute "apt-get update" do
  ignore_failure true
  action :nothing
  only_if do
    ::File.exists?('/var/lib/apt/periodic/update-success-stamp') &&
    ::File.mtime('/var/lib/apt/periodic/update-success-stamp') < Time.now - 86400
  end
end.run_action(:run)

%w{
  ack-grep
  byobu
  cpufrequtils
  curl
  expect
  ethtool
  dstat
  git
  iotop
  keychain
  landscape-common
  mailutils
  mlocate
  mosh
  pigz
  rsync
  traceroute
  tree
  update-motd
  screen
  sshpass
  vim
  tmux
  zsh
}.each do |pkg, ver|
  package pkg do
    action :install
    version ver if ver && ver.length > 0
  end
end

%w{
  lm-sensors
  smartmontools
}.each do |pkg, ver|
  package pkg do
    action :install
    version ver if ver && ver.length > 0
    only_if { node.virtualization[:role] == "host" }
  end
end

%w{
  ubuntu-release-upgrader-core
  update-manager-core
  update-notifier-common
}.each do |pkg|
  package pkg do
    action :purge
  end
end


#
# Apt
#
file "/etc/apt/apt.conf.d/00architectures" do
  owner "root"
  group "root"
  mode "0644"
  content "APT::Architectures { \"amd64\"; }"
  action :create
end


#
# Motd message
#
%w{
  10-help-text
  51-cloudguest
  98-cloudguest
}.each do |motd|
  file "/etc/update-motd.d/#{motd}" do
    action :delete
  end
end

%w{
  00-header
  60-distro
}.each do |motd|
  template "/etc/update-motd.d/#{motd}" do
    source "motd-#{motd}.erb"
    owner "root"
    group "root"
    mode 0755
    action :create
  end
end

template "/usr/share/landscape/landscape-sysinfo.wrapper" do
  source "landscape-sysinfo.wrapper.erb"
  owner "root"
  group "root"
  mode 0755
  action :create
end

file "/etc/motd.tail" do
  content node[:ubuntu_server][:motd_tail]
  owner "root"
  group "root"
  mode 0644
  action :create
end


#
# sysctl
#
unless node[:ubuntu_server][:sysctl][:params].empty?
  execute "add-sysctl" do
    command "echo \"#{node[:ubuntu_server][:sysctl][:params_header]}\n#{node[:ubuntu_server][:sysctl][:params]}\" >> /etc/sysctl.conf"
    not_if "grep \"#{node[:ubuntu_server][:sysctl][:params_header]}\" /etc/sysctl.conf"
    action :run
    notifies :run, "execute[reload-sysctl]"
  end

  execute "reload-sysctl" do
    command "sysctl -p"
    action :nothing
  end
end


#
# rc.local
#
template "/etc/rc.local" do
  source "rc.local.erb"
  mode 0755
end


#
# Disable Ctrl+Alt+Del
#
template "/etc/init/control-alt-delete.conf" do
  source "control-alt-delete.conf.erb"
  mode 0644
  action :create
  only_if { node.virtualization[:role] == "host" }
end


#
# Lock root account
#
user "root" do
  action :lock
end


#
# ufw
#
if node[:ubuntu_server][:ufw][:enable]
  template "/etc/default/ufw" do
    source "default-ufw.erb"
    owner "root"
    group "root"
    mode 0644
    action :create
#    notifies :reload, "firewall[ufw]"
  end

  template "/etc/ufw/before.rules" do
    source "ufw-before.rules.erb"
    owner "root"
    group "root"
    mode 0640
    action :create
#    notifies :reload, "firewall[ufw]"
  end

  template "/etc/ufw/sysctl.conf" do
    source "sysctl.conf.erb"
    owner "root"
    group "root"
    mode 0644
    action :create
#    notifies :reload, "firewall[ufw]", :delayed
  end
end


#
# sysstat
#
package "sysstat" do
  action :install
end

template "/etc/default/sysstat" do
  source "sysstat.erb"
  mode 0664
  action :create
  notifies :reload, "service[sysstat]", :delayed
end

template "/etc/sysstat/sysstat" do
  source "sysstat-sysstat.erb"
  mode 0664
  action :create
  notifies :reload, "service[sysstat]", :delayed
end

template "/etc/cron.d/sysstat" do
  source "cron-sysstat.erb"
  mode 0600
  action :create
  notifies :reload, "service[sysstat]", :delayed
end

service "sysstat" do
  action [:enable, :start]
end


#
# KVM host
#
if node.virtualization[:system] == "kvm" and node.virtualization[:role] == "host"
  %w{
    ubuntu-virt-server
    koan
    selinux-basics
  }.each do |pkg|
    package pkg do
      action :install
      notifies :execute, "execute[virt-disable-nat-iface]", :delayed if pkg == "ubuntu-virt-server"
    end
  end

  service "qemu-kvm" do
    action [:enable, :start]
  end

  service "libvirt-bin" do
    action [:enable, :start]
  end

  template "/etc/default/qemu-kvm" do
    source "default-qemu-kvm.erb"
    mode 0644
    action :create
    notifies :restart, "service[qemu-kvm]"
  end

  execute "virt-disable-nat-iface" do
    command "virsh net-destroy default"
    action :nothing
    notifies :restart, "service[libvirt-bin]"
  end
end


#
# KVM guest
#
if node.virtualization[:system] == "kvm" and node.virtualization[:role] == "guest"
  package "arping" do
    action :install
  end

  template "/usr/local/script/macrefresh.py" do
    source "macrefresh.py.erb"
    mode 0755
    notifies :run, "execute[exec-rc-local]"
  end

  execute "exec-rc-local" do
    command "sh /etc/rc.local"
    action :nothing
  end
end


#
# Physical Host
#
cookbook_file "/usr/local/script/generante_persistent_net.sh" do
  source "generate_persistent_net.sh"
  mode 0755
  action :create
  only_if { node.virtualization.empty? }
end
