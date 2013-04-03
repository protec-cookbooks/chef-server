#
# Cookbook Name:: chef-server
# Recipe:: default
#
# Copyright 2013, Protec Innovations
#
# Licenced under the BSD
#

node.set_unless['chef_server']['rabbitmq_password'] = secure_password
node.set_unless['chef_server']['webui_password'] = secure_password
node.save

directory "/var/cache/local/preseeding" do
    owner "root"
    group node['chef_server']['root_group']
    mode 0755
    recursive true
end

execute "preseed chef-server" do
    command "debconf-set-selections /var/cache/local/preseeding/chef-server.seed"
    action :nothing
end

template "/var/cache/local/preseeding/chef-server.seed" do
    source "chef-server.seed.erb"
    owner "root"
    group node['chef_server']['root_group']
    mode "0600"
    notifies :run, "execute[preseed chef-server]", :immediately
end

package "chef-server" do
    action :install
end
