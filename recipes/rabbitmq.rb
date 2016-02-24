#
# Cookbook Name:: geoshape
# Recipe:: rabbitmq
#
# Copyright 2016, Boundless
#
# All rights reserved - Do Not Redistribute
#

require "net/http"
require "uri"

case node.platform
when "centos", "redhat"
  service "rabbitmq-server" do
    action :nothing
  end

  include_recipe "geoshape::repos"
  package %w{rabbitmq-server erlang}

  open_firewall_port(5672) if !%w{127.0.0.1 localhost}.include?(node.geoshape.rabbitmq.endpoint)

  template "/usr/lib/rabbitmq/bin/rabbitmq-env" do
    source "rabbitmq-env.erb"
    owner "root"
    group "root"
    # if we change the end point while the service is started the service will fail to restart
    notifies :stop, "service[rabbitmq-server]", :before
    notifies :start, "service[rabbitmq-server]"
    variables(hostname: node.geoshape.rabbitmq.endpoint)
  end

  service "rabbitmq-server" do
    action :start
  end
else
  Chef::Log.warn("Unsupported platform #{node.platform}")
end
