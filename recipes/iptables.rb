#
# Cookbook Name:: geoshape
# Recipe:: iptables
#
# Copyright 2016, Boundless
#
# All rights reserved - Do Not Redistribute
#

require "net/http"
require "uri"

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
else
  Chef::Log.warn("Unsupported platform #{node.platform}")
end
