#
# Cookbook Name:: geoshape
# Recipe:: elasticsearch
#
# Copyright 2016, Boundless
#
# All rights reserved - Do Not Redistribute
#

require "uri"

case node.platform
when "centos", "redhat", "oracle"
  include_recipe "geoshape::repos"
  include_recipe "geoshape::iptables"

  open_firewall_port(node.geoshape.elasticsearch.port) if !%w{127.0.0.1 localhost}.include?(URI.parse(node.geoshape.elasticsearch.endpoint).host)

  service "elasticsearch" do
    action :nothing
  end

  package "elasticsearch"
  include_recipe "java"

  template "/usr/share/elasticsearch/bin/elasticsearch.in.sh" do
    owner "root"
    group "root"
    source "elasticsearch.in.sh.erb"
    variables(heap_size: node.elasctic_max_heap)
    notifies :restart, "service[elasticsearch]"
  end

  service "elasticsearch" do
    action :start
  end
else
  Chef::Log.warn("Unsupported platform #{node.platform}")
end
