#
# Cookbook Name:: ubuntu_server
# Definitions:: ubuntu_server_static_routes
#
# Copyright 2012, Naoya Nakazawa
#
# All rights reserved - Do Not Redistribute
#

define :ubuntu_server_static_routes, :routes => [] do
  template "/etc/network/if-up.d/static-routes-#{params[:name]}" do
    cookbook "ubuntu_server"
    source "static-routes-iface.erb"
    mode 0755
    variables(:params => params, :route_mode => "add")
    not_if { :route.empty? }
    action :create
    notifies :run, "execute[exec-adding-route]"
  end

  template "/etc/network/if-down.d/static-routes-#{params[:name]}" do
    cookbook "ubuntu_server"
    source "static-routes-iface.erb"
    mode 0755
    variables(:params => params, :route_mode => "del")
    not_if { :route.empty? }
    action :create
  end

  execute "exec-adding-route" do
    command "sh /etc/network/if-up.d/static-routes-#{params[:name]}"
    environment ({'IFACE' => params[:name]})
    not_if { :route.empty? }
    action :nothing
  end
end
