#
# Cookbook Name:: geoshape
# Recipe:: geoserver
#
# Copyright 2016, Boundless
#
# All rights reserved - Do Not Redistribute
#
require "net/http"
require "net/https"
require "uri"

include_recipe 'chef-vault'
geoserver_vault = get_secret(node.geoshape.geoserver.vault[:name], node.geoshape.geoserver.vault[:item])
database_vault = get_secret(node.geoshape.database.vault[:name], node.geoshape.database.vault[:item])

database_password = database_vault ? database_vault['imports_password'] : node.geoshape.imports_database.password

if geoserver_vault
  admin_password_hash = geoserver_vault['admin_password_hash']
  admin_password = geoserver_vault['admin_password']
  root_password_digest = geoserver_vault['root_password_digest']
  root_password_hash = geoserver_vault['root_password_hash']
else
  admin_password_hash = node.geoshape.geoserver.password_hash
  admin_password = node.geoshape.geoserver.admin_password
  root_password_digest = node.geoserver.root_user.password_digest
  root_password_hash = node.geoserver.root_user.password_hash
end

service "tomcat8" do
  action :nothing
end

include_recipe "geoshape::repos"
package "geoshape-geoserver" do
  notifies :run, "execute[set geoserver permissions]"
end
include_recipe "java"
include_recipe "tomcat"

execute "set geoserver permissions" do
  command "find #{node.geoshape.geoserver.data_dir} -type d -exec chmod 755 {} + && find #{node.geoshape.geoserver.data_dir} -type f -exec chmod 644 {} + && chown -R tomcat:tomcat #{node.geoshape.geoserver.data_dir}"
  action :nothing
end

if !%w{127.0.0.1 localhost}.include?(node.geoshape.geoserver.endpoint)
  [node.tomcat.ajp_port, node.tomcat.port, node.tomcat.ssl_port].each { |port|
    open_firewall_port(port)
  }
end

# configuring various Geoserver passwords
template "#{node.geoshape.geoserver.data_dir}/security/usergroup/default/users.xml" do
  source "gs_users.xml.erb"
  mode 0644
  owner "tomcat"
  group "tomcat"
  notifies :restart, "service[tomcat8]"
  # notifies :run, "ruby_block[wait for geoserver]"
  variables(password_hash: admin_password_hash)
end

file "#{node.geoshape.geoserver.data_dir}/security/masterpw.digest" do
  content root_password_digest
  owner "tomcat"
  group "tomcat"
  notifies :restart, "service[tomcat8]"
  mode 0644
end

file "#{node.geoshape.geoserver.data_dir}/security/masterpw/default/passwd" do
  content root_password_hash
  owner "tomcat"
  group "tomcat"
  notifies :restart, "service[tomcat8]"
  mode 0644
end

cookbook_file "#{node.geoshape.geoserver.data_dir}/security/geoserver.jceks" do
  source "geoserver.jceks"
  owner "tomcat"
  group "tomcat"
  notifies :restart, "service[tomcat8]"
  mode 0644
end

# If Geoserver is on the same instance as Geoshape we always want to use HTTP
geoshape_endpoint =
  if %w{127.0.0.1 localhost}.include?(node.geoshape.geoserver.endpoint)
    "http://localhost"
  else 
    node.geoshape.https_enabled ? "https://#{node.geoshape.endpoint}" : "http://#{node.geoshape.endpoint}"
  end

# Do we really want to restart Tomcat immediately? This is only relevant when Geoserver and Geoshape are installed on the same instance
template "#{node.geoshape.geoserver.data_dir}/security/auth/geonodeAuthProvider/config.xml" do
  source "geonode_auth_provider_config.xml.erb"
  mode 0644
  owner "tomcat"
  group "tomcat"
  notifies :restart, "service[tomcat8]", :immediately
  notifies :run, "ruby_block[wait for geoserver]", :immediately
  variables(url: geoshape_endpoint)
end

remote_file "#{node.tomcat.lib_dir}/postgresql.jar" do
  source "https://jdbc.postgresql.org/download/postgresql-9.4.1207.jar"
  owner "root"
  group "root"
  notifies :restart, "service[tomcat8]"
  mode 0644
end

# Postgres JNDI attributes
jndi_connections = [
  {
    "datasource_name" => "#{node.geoshape.imports_database.geonode_alias}", "driver" =>  "org.postgresql.Driver", "user" => node.geoshape.imports_database.user, "password" => database_password, "max_total" => 40, "max_idle" => 10, "max_wait" => -1,
    "connection_string" => "postgresql://#{node.geoshape.imports_database.endpoint}:#{node.geoshape.imports_database.port}/#{node.geoshape.imports_database.name}"
  }
]

node.override.tomcat.jndi_connections = jndi_connections

template "#{node.tomcat.webapp_dir}/geoserver/WEB-INF/web.xml" do
  owner "tomcat"
  group "tomcat"
  mode 0644
  source "web.xml.erb"
  notifies :restart, "service[tomcat8]"
  variables(
    jsonp_enabled: node.geoshape.geoserver.jsonp_enabled,
    geoserver_directory: node.geoshape.geoserver.data_dir,
    gwc_directory: node.geoshape.geoserver.gwc_data_dir,
    jndi_connections: jndi_connections
  )
end

ruby_block "wait for geoserver" do
  block do
    attempts = 0
    uri = URI.parse("http://localhost:#{node.tomcat.port}/geoserver/rest/workspaces/geonode.xml")
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.request_uri)
    req.basic_auth(node.geoshape.geoserver.admin_user, admin_password)

    loop do
      resp = http.request(req)
      break if resp.code == '200' || attempts >= 20
      sleep 15
      attempts += 1
    end
  end
  action :nothing
end

template "#{Chef::Config[:file_cache_path]}/datastore.xml" do
  source "datastore.xml.erb"
  variables(name: node.geoshape.imports_database.geonode_alias)
end

# unless datastore_exists?(node.geoshape.geoserver.admin_user, admin_password)
  # Create a Geoserver Postgres JNDI store
  ruby_block "create Geoserver store" do
    block do
      uri = URI.parse("http://localhost:#{node.tomcat.port}/geoserver/rest/workspaces/geonode/datastores.json")
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Get.new(uri.request_uri)
      req.basic_auth(node.geoshape.geoserver.admin_user, admin_password)
      resp = http.request(req)

      if resp.code != '200'
        `service tomcat8 restart`
        sleep 30
      end
      unless resp.body.include?(node.geoshape.imports_database.geonode_alias)
        credentials = "#{node.geoshape.geoserver.admin_user}:'#{admin_password}'"
        `curl -u #{credentials} -XPOST -H 'Content-type: text/xml' -d @#{Chef::Config[:file_cache_path]}/datastore.xml http://localhost:#{node.tomcat.port}/geoserver/rest/workspaces/geonode/datastores.xml`
      end
    end
  end
# end
