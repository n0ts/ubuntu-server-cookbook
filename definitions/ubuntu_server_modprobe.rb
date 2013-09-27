#
# Cookbook Name:: ubuntu_server
# Definition:: ubuntu_server_modprobe_blacklist
#
# Copyright 2012, Naoya Nakazawa
#
# All rights reserved - Do Not Redistribute
#

define :ubuntu_server_modprobe_blacklist, :mods => [] do
  content = []
  params[:mods].collect{|v| content << "blacklist #{v}" }

  file "/etc/modprobe.d/blacklist-#{params[:name]}.conf" do
    mode 0644
    content content.join("\n")
    action :create
    not_if params[:mods].empty?
    notifies :run, "execute[exec-rmmod]"
  end

  execute "exec-rmmod" do
    command "rmmod #{params[:mods].join(" ")}"
    action :nothing
  end
end
