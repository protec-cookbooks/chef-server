#
# Cookbook Name:: chef-server
# Recipe:: default
#
# Copyright 2013, Protec Innovations
#
# Licenced under the BSD
#

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

# We want to create a secure password here, but as we may be bootstrapping the
# server via chef-solo, we can't neccesarily store it agains the node.  So we
# store it to a temporary file.  If we detect that there is no password, then we
# check if that file exists, and load it from there.  If we don't have that file
# then we store the password to that file.  Once we're retrieving a password
# before we get to the recipe, we can remove the temporary file, as we should
# be getting it from the server (or overriden attributes) at that point.

unless node.chef_server.attribute?('rabbitmq_password')

    if File.exist?('/tmp/rabbitmq_password')
        node.set_unless['chef_server']['rabbitmq_password'] = File.read('/tmp/rabbitmq_password').strip
    end

    node.set_unless['chef_server']['rabbitmq_password'] = secure_password

    if Chef::Config[:solo]
        template "/tmp/rabbitmq_password" do
            source "password_tmp.erb"
            owner "root"
            group node['chef_server']['root_group']
            mode "0600"
            variables(
                {
                    :password => node['chef_server']['rabbitmq_password']
                }
            )
        end
    else    1
        file "/tmp/rabbitmq_password" do
            action :delete
        end
    end
end

unless node.chef_server.attribute?('webui_password')

    if File.exist?('/tmp/webui_password')
        node.set_unless['chef_server']['webui_password'] = File.read('/tmp/webui_password').strip
    end

    node.set_unless['chef_server']['webui_password'] = secure_password

    if Chef::Config[:solo]
        template "/tmp/webui_password" do
            source "password_tmp.erb"
            owner "root"
            group node['chef_server']['root_group']
            mode "0600"
            variables(
                {
                    :password => node['chef_server']['webui_password']
                }
            )
        end
    else    1
        file "/tmp/webui_password" do
            action :delete
        end
    end
end

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

template "/etc/nginx/sites-available/chef-server" do
    source "nginx.erb"
    owner "root"
    group node['chef_server']['root_group']
    mode "0644"
end

nginx_site "chef-server" do
    enable true
end

service node['chef_server']['service_name'] do
    supports :status => true, :restart => true, :reload => true
    action [:enable, :start]
end
