#
# Cookbook Name:: ubuntu_server
# Definitions:: ubuntu_server_script
#
# Copyright 2012, Naoya Nakazawa
#
# All rights reserved - Do Not Redistribute
#

define :ubuntu_server_script, :dir => "bin", :cookbook => "ubuntu_server" do
  template "/usr/local/#{params[:dir]}/#{params[:name]}" do
    cookbook params[:cookbook]
    source "#{params[:name]}.erb"
    mode 0755
    variables(:params => params)
    action :create
  end
end
