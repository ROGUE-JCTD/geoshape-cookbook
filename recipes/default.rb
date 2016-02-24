#
# Cookbook Name:: geoshape
# Recipe:: default
#
# Copyright 2016, Boundless
#
# All rights reserved - Do Not Redistribute
#

case node.platform
when "centos", "redhat"
  # We're currently installing everything on one instance/VM
  include_recipe "geoshape::database"
  include_recipe "geoshape::elasticsearch"
  include_recipe "geoshape::rabbitmq"
  include_recipe "geoshape::geoserver"
  include_recipe "geoshape::geoshape"
else
  Chef::Log.warn("Unsupported platform #{node.platform}")
end
