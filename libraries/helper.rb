require "net/http"
require "net/https"
require "uri"

module Geoshape
  module Helper
    def get_secret(vault, item)
      chef_vault_item(vault, item)
    rescue Net::HTTPServerException
    rescue Chef::Exceptions::ValidationFailed, NoMethodError #Need better way to deal with Chef Solo
    end

    def datastore_exists?(user, password)
      uri = URI.parse("http://localhost:8080/geoserver/rest/workspaces/geonode/datastores.json")
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Get.new(uri.request_uri)
      req.basic_auth(user, password)
      resp = http.request(req)

      if resp.code == '200'
        resp.body.include?(node.geoshape.imports_database.geonode_alias) ? true : false
      end
    end

    def open_firewall_port(port, protocol: "tcp")
      execute "iptables -I INPUT -p #{protocol} --dport #{port} -j ACCEPT && service iptables save" do
        not_if "iptables -nL | egrep '^ACCEPT.*dpt:#{port}($| )'"
      end
    end
  end
end

Chef::Node.send(:include, Geoshape::Helper)
Chef::Recipe.send(:include, Geoshape::Helper)
Chef::Resource.send(:include, Geoshape::Helper)
Chef::Provider.send(:include, Geoshape::Helper)
