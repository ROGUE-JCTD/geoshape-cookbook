#
# Cookbook Name:: geoshape
# Recipe:: apache
#
# Copyright 2016, Boundless
#
# All rights reserved - Do Not Redistribute
#

case node.platform
when "centos", "redhat"
  include_recipe "yum-epel"
end

include_recipe "apache2"
include_recipe "apache2::mod_rewrite"
include_recipe "apache2::mod_ssl"
include_recipe "apache2::mod_proxy"
include_recipe "apache2::mod_proxy_ajp"
include_recipe "apache2::mod_proxy_http"
include_recipe "apache2::mod_expires"
include_recipe "apache2::mod_deflate"
include_recipe "apache2::mod_xsendfile"

if node.geoshape.https_enabled
  include_recipe 'chef-vault'
  cert = get_secret(node.geoshape.cert_vault[:name], node.geoshape.cert_vault[:item])

  directory node.apache.dir do
    owner node.apache.user
    group node.apache.group
    mode 0755
  end

  %w{cert key bundle}.each { |type|
    file "#{node.apache.dir}/ssl/geoshape_#{type}" do
      mode 0400
      content cert[type].strip
      sensitive true
      owner node.apache.user
      group node.apache.group
    end
  }
end

web_app "geoshape" do
  server_name node.fqdn
  server_aliases [ node.fqdn, node.hostname ]
  docroot node.apache.docroot_dir
  allow_override "All"
  template "geoshape.conf.erb"
  version node.apache.version
  log_dir node.apache.log_dir
  https_only node.geoshape.https_only
  https_enabled node.geoshape.https_enabled
  cert node.geoshape.cert
  cert_chain node.geoshape.cert_chain
  cert_key node.geoshape.cert_key
end

template "#{node.apache.dir}/conf-enabled/proxy_ajp.conf" do
  source "proxy.conf.erb"
  mode 0644
  owner node.apache.user
  group node.apache.group
  notifies :reload, "service[apache2]", :delayed
  variables(version: node.apache.version)
end
