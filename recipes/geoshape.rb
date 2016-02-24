#
# Cookbook Name:: geoshape
# Recipe:: geoshape
#
# Copyright 2016, Boundless
#
# All rights reserved - Do Not Redistribute
#

require "net/http"
require "uri"

include_recipe "chef-vault"

geoserver_vault = get_secret(node.geoshape.geoserver.vault[:name], node.geoshape.geoserver.vault[:item])
database_vault = get_secret(node.geoshape.database.vault[:name], node.geoshape.database.vault[:item])
geonode_vault = get_secret(node.geoshape.geonode.vault[:name], node.geoshape.geonode.vault[:item])

geoserver_password = geoserver_vault ? geoserver_vault['admin_password'] : node.geoshape.geoserver.admin_password
geonode_password_hash = geonode_vault ? geonode_vault['admin_password_hash'] : node.geoshape.admin_password_hash

if database_vault
  database_password = database_vault['password']
  imports_database_password = database_vault['imports_password']
else
  database_password = node.geoshape.database.password
  imports_database_password = node.geoshape.imports_database.password
end

case node.platform
when "centos", "redhat"
  include_recipe "geoshape::repos"
  include_recipe "geoshape::iptables"
  include_recipe "geoshape::apache"

  %w{80 443}.each { |port|
    open_firewall_port(port)
  }

  %w{httpd_can_network_connect_db httpd_can_network_connect}.each {|pol|
    execute "setsebool -P #{pol} 1" do
      not_if "grep #{pol}=1 /etc/selinux/targeted/modules/active/booleans.local"
    end
  }

  %w{geoshape httpd postfix}.each{ |svc|
    service svc do
      action :nothing
    end
  }

  package "geoshape"

  template "/etc/supervisord.conf" do
    source "supervisord.conf.erb"
    notifies :restart, "service[geoshape]"
  end

  template "/etc/geoshape/local_settings.py" do
    owner "geoshape"
    group "geoservice"
    source "local_settings.py.erb"
    mode 0755
    notifies :restart, "service[geoshape]"
    variables(
      site_url: "http://#{node.geoshape.endpoint}/",
      allowed_hosts: node.geoshape.allowed_hosts,
      db_username: node.geoshape.database.user,
      db_password: database_password,
      db_name: node.geoshape.database.name,
      db_endpoint: node.geoshape.database.endpoint,
      db_port: node.geoshape.database.port,
      imports_db_name: node.geoshape.imports_database.name,
      imports_db_alias: node.geoshape.imports_database.geonode_alias,
      imports_db_user: node.geoshape.imports_database.user,
      imports_db_password: imports_database_password,
      imports_db_port: node.geoshape.imports_database.port,
      imports_db_endpoint: node.geoshape.imports_database.endpoint,
      geoserver_username: node.geoshape.geoserver.admin_user,
      geoserver_password: geoserver_password,
      server_email: node.geoshape.email_from,
      email_host: node.geoshape.email_host,
      email_port: node.geoshape.email_port,
      enable_registration: node.geoshape.enable_registration,
      account_activation: node.geoshape.account_activation,
      account_approval: node.geoshape.account_approval,
      account_email_confirm: node.geoshape.account_email_confirm,
      auth_exempt_urls: node.geoshape.auth_exempt_urls,
      debug: node.geoshape.debug,
      lockdown_geonode: node.geoshape.lockdown_geonode,
      elasticsearch_port: node.geoshape.elasticsearch.port,
      elasticsearch_endpoint: node.geoshape.elasticsearch.endpoint,
      rabbitmq_endpoint: node.geoshape.rabbitmq.endpoint,
      rabbitmq_username: node.geoshape.rabbitmq.user,
      rabbitmq_port: node.geoshape.rabbitmq.port
    )
  end

  if node.geoshape.enable_registration
    package "postfix"

    template "/etc/postfix/main.cf" do
      source "main.cf.erb"
      owner "root"
      group "root"
      mode 0644
      notifies :restart, "service[postfix]"
      variables(hostname: node.hostname)
    end
  end

  execute "#{node.python27} #{node.geoshape.manage} collectstatic --noinput"
  execute "#{node.python27} #{node.geoshape.manage} syncdb --noinput" do
    notifies :start, "service[geoshape]", :immediately
    notifies :start, "service[httpd]", :immediately
  end

  template "#{Chef::Config[:file_cache_path]}/admin.json" do
    source "admin.json.erb"
    variables(
      password_hash: geonode_password_hash,
      username: node.geoshape.admin_user
    )
  end

  ruby_block "wait for geoshape" do
    block do
      attempts = 0
      uri = URI.parse("http://localhost/geoserver/rest/workspaces/geonode.xml")
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Get.new(uri.request_uri)
      req.basic_auth(node.geoshape.geoserver.admin_user, geoserver_password)

      loop do
        resp = http.request(req)
        if resp.code == '200' || attempts >= 20
          break
        elsif %w{403 404}.include?(resp.code) && attempts >= 2
          `service httpd restart`
        end
        sleep 20
        attempts += 1
      end
    end
    action :nothing
  end

  execute "#{node.python27} #{node.geoshape.manage} loaddata #{Chef::Config[:file_cache_path]}/admin.json"
  execute "#{node.python27} #{node.geoshape.manage} updatelayers --ignore-errors --remove-deleted --skip-unadvertised" do
    notifies :run, "ruby_block[wait for geoshape]", :before
  end

  # Elasticsearch fails from time to time. Need to add a rescue to this 
  execute "#{node.python27} #{node.geoshape.manage} rebuild_index --noinput"

  # Making sure we ingest Geoserver layers
  cron "update geoserver layers" do
    minute "*"
    user "root"
    command "#{node.python27} #{node.geoshape.manage} updatelayers --remove-deleted --ignore-errors"
  end
else
  Chef::Log.warn("Unsupported platform #{node.platform}")
end
