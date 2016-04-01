#
# Cookbook Name:: geoshape
# Recipe:: database
#
# Copyright 2016, Boundless
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'chef-vault'

database_vault = get_secret(node.geoshape.database.vault[:name], node.geoshape.database.vault[:item])
geoshape_database_password = database_vault ? database_vault['password'] : node.geoshape.database.password
master_password = database_vault ? database_vault['master_password'] : node.geoshape.database_master_password
node.override.postgresql.password.postgres = master_password

connection_param = "PGPASSWORD='#{master_password}' psql -U #{node.geoshape.database_master_user} -h #{node.geoshape.database.endpoint}"

# assuming we're running this recipe on the geoshape instance only. Better to do this based on recipes in the run list
if %w{127.0.0.1 localhost}.include?(node.geoshape.database.endpoint)
  include_recipe "geoshape::repos"
  include_recipe "postgresql::server"
  package "postgis-postgresql95"

  service "postgresql-#{node.postgresql.version}" do
    action :nothing
  end
else
  include_recipe "postgresql::client"
end

# We aren't using the Database cookbook because it requires the pg gem, which requires us to install development packages
execute "create geoshape database user" do
  command "#{connection_param} -t -c \"create role #{node.geoshape.database.user} login password '#{geoshape_database_password}'\""
  only_if "#{connection_param} -t -c \"select count(1) from pg_catalog.pg_user where usename = '#{node.geoshape.database.user}'\" | grep 0"
  sensitive true
end

execute "create geoshape database" do
  command "#{connection_param} -t -c \"create database #{node.geoshape.database.name} owner #{node.geoshape.database.user}\""
  only_if "#{connection_param} -t -c \"select count(1) from pg_database where datname = '#{node.geoshape.database.name}'\" | grep 0"
  sensitive true
end

execute "create geoshape_data database" do
  command "#{connection_param} -t -c \"create database #{node.geoshape.imports_database.name} owner #{node.geoshape.imports_database.user}\""
  only_if "#{connection_param}  -t -c \"select count(1) from pg_database where datname = '#{node.geoshape.imports_database.name}'\" | grep 0"
  sensitive true
end

execute "Create PostGIS extension" do
  command "#{connection_param} -d #{node.geoshape.imports_database.name} -t -c \"create extension postgis\""
  only_if "#{connection_param}  -d #{node.geoshape.imports_database.name} -t -c \"select count(1) from pg_available_extensions where installed_version is not null and name = 'postgis'\" | grep 0"
  sensitive true
end
