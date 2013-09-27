#
# Cookbook Name:: ubuntu_server
# Recipe:: default
#
# Copyright 2012, Naoya Nakazawa
#
# All rights reserved - Do Not Redistribute
#

service "autofs" do
  action [ :enable, :start ]
end

template "/etc/auto.master" do
  source "auto.master.erb"
  mode 0644
  notifies :restart, "service[autofs]"
end
