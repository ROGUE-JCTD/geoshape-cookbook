#
# Cookbook Name:: geoshape
# Recipe:: default
#
# Copyright 2016, Boundless
#
# All rights reserved - Do Not Redistribute
#
require "net/http"
require "uri"

include_recipe "geoshape::apache"
include_recipe "chef-vault"

geoserver_vault = get_secret(node.geoshape.geoserver.vault[:name], node.geoshape.geoserver.vault[:item])
geoserver_password = 
  if geoserver_vault
    geoserver_vault['admin_password']
  else
    node.geoshape.geoserver.admin_password
  end

database_vault = get_secret(node.geoshape.database.vault[:name], node.geoshape.database.vault[:item])
if database_vault
  database_password = database_vault['password']
  imports_database_password = database_vault['imports_password']
else
  database_password = node.geoshape.database.password
  imports_database_password = node.geoshape.imports_database.password
end

geonode_vault = get_secret(node.geoshape.geonode.vault[:name], node.geoshape.geonode.vault[:item])
geonode_password_hash = 
  if geonode_vault
    geonode_vault['admin_password_hash']
  else
    node.geoshape.admin_password_hash
  end

case node.platform
when "centos", "redhat"
  case node.platform_version.to_i
  when 7
    # Currently removing firewalld for backwards compatibility
    package "firewalld" do
      action :remove
    end

    package "iptables-services"
  end

    %w{80 443}.each { |port|
      execute "iptables -I INPUT -p tcp --dport #{port} -j ACCEPT; service iptables save" do
        not_if "iptables -nL | egrep '^ACCEPT.*dpt:#{port}($| )'"
      end
    }

    %w{httpd_can_network_connect_db httpd_can_network_connect}.each {|pol|
      execute "setsebool -P #{pol} 1" do
        not_if "grep #{pol}=1 /etc/selinux/targeted/modules/active/booleans.local"
      end
    }

    %w{tomcat8 rabbitmq-server elasticsearch geoshape httpd postfix}.each{ |svc|
      service svc do
        action :nothing
      end
    }

    service "postgresql-#{node.postgresql.version}" do
      action :nothing
    end

    remote_file "/etc/yum.repos.d/geoshape.repo" do
      source "http://yum.boundlessps.com/geoshape.repo"
    end

    execute "rpm --import http://yum.boundlessps.com/RPM-GPG-KEY-yum.boundlessps.com" do
      not_if "rpm -q gpg-pubkey | grep gpg-pubkey-3b7df5eb-569d1240"
    end

    # We're currently installing everything on one instance/VM
    include_recipe "postgresql::server"
    package %w{geoshape geoshape-geoserver elasticsearch postgis-postgresql95}
    include_recipe "geoshape::database"
    include_recipe "java"
    include_recipe "tomcat"
    include_recipe "geoshape::geoserver"

    template "/etc/supervisord.conf" do
      source "supervisord.conf.erb"
      notifies :restart, "service[geoshape]"
    end

    template "/usr/share/elasticsearch/bin/elasticsearch.in.sh" do
      owner "root"
      group "root"
      source "elasticsearch.in.sh.erb"
      variables(heap_size: node.elasctic_max_heap)
      notifies :restart, "service[elasticsearch]"
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
        lockdown_geonode: node.geoshape.lockdown_geonode
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

    template "/usr/lib/rabbitmq/bin/rabbitmq-env" do
      source "rabbitmq-env.erb"
      owner "root"
      group "root"
      notifies :restart, "service[rabbitmq-server]"
      variables(hostname: node.geoshape.rabbitmq.endpoint)
    end

    execute "#{node.python27} #{node.geoshape.manage} collectstatic --noinput"
    execute "#{node.python27} #{node.geoshape.manage} syncdb --noinput" do
      notifies :start, "service[geoshape]", :immediately
      notifies :start, "service[tomcat8]", :immediately
      notifies :start, "service[rabbitmq-server]", :immediately
      notifies :start, "service[elasticsearch]", :immediately
      notifies :start, "service[httpd]", :immediately
    end

    template "#{Chef::Config[:file_cache_path]}/admin.json" do
      source "admin.json.erb"
      variables(
        password_hash: geonode_password_hash,
        username: node.geoshape.admin_user
      )
    end

    ruby_block "wait-for-geoserver" do
      block do
        attempts = 0
        uri = URI.parse("http://localhost/geoserver/rest/workspaces/geonode.xml")
        http = Net::HTTP.new(uri.host, uri.port)
        req = Net::HTTP::Get.new(uri.request_uri)
        req.basic_auth(node.geoshape.geoserver.admin_user, geoserver_password)

        loop do
          resp = http.request(req)
          break if resp.code == '200' || attempts >= 20
          if %w{403, 404}.include?(resp.code) && attempts >= 4
            `service httpd restart`
            `service tomcat8 restart`
          end
          sleep 20
          attempts += 1
        end
      end
      action :nothing
    end

    execute "#{node.python27} #{node.geoshape.manage} loaddata #{Chef::Config[:file_cache_path]}/admin.json"
    execute "#{node.python27} #{node.geoshape.manage} updatelayers --ignore-errors --remove-deleted --skip-unadvertised" do
      notifies :run, "ruby_block[wait-for-geoserver]", :before
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
