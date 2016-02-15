module Geoshape
  module Helper
    def get_secret(vault, item)
      chef_vault_item(vault, item)
    rescue Net::HTTPServerException
    rescue Chef::Exceptions::ValidationFailed, NoMethodError #Need better way to deal with Chef Solo
    end
  end
end

Chef::Node.send(:include, Geoshape::Helper)
Chef::Recipe.send(:include, Geoshape::Helper)
Chef::Resource.send(:include, Geoshape::Helper)
Chef::Provider.send(:include, Geoshape::Helper)
