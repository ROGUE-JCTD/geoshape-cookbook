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
geoshape_database_password = 
  if database_vault
    database_vault['password']
  else
    node.geoshape.database.password
  end

master_password = 
  if database_vault
    database_vault['master_password']
  else
    node.geoshape.database_master_password
  end

# We aren't using the Database cookbook because it requires the pg gem, which requires us to install development packages
execute "create geoshape database user" do
  command "PGPASSWORD='#{master_password}' psql -U #{node.geoshape.database_master_user} -t -c \"create role #{node.geoshape.database.user} login password '#{geoshape_database_password}'\""
  only_if "PGPASSWORD='#{master_password}' psql -U #{node.geoshape.database_master_user} -t -c \"select count(1) from pg_catalog.pg_user where usename = '#{node.geoshape.database.user}'\" | grep 0"
end

execute "create geoshape database" do
  command "PGPASSWORD='#{master_password}' psql -U #{node.geoshape.database_master_user} -t -c \"create database #{node.geoshape.database.name} owner #{node.geoshape.database.user}\""
  only_if "PGPASSWORD='#{master_password}' psql -U #{node.geoshape.database_master_user} -t -c \"select count(1) from pg_database where datname = '#{node.geoshape.database.name}'\" | grep 0"
end

execute "create geoshape_data database" do
  command "PGPASSWORD='#{master_password}' psql -U #{node.geoshape.database_master_user} -t -c \"create database #{node.geoshape.imports_database.name} owner #{node.geoshape.imports_database.user}\""
  only_if "PGPASSWORD='#{master_password}' psql -U #{node.geoshape.database_master_user} -t -c \"select count(1) from pg_database where datname = '#{node.geoshape.imports_database.name}'\" | grep 0"
end

execute "Create PostGIS extension" do
  command "PGPASSWORD='#{master_password}' psql -U #{node.geoshape.database_master_user} -d #{node.geoshape.imports_database.name} -t -c \"create extension postgis\""
  only_if "PGPASSWORD='#{master_password}' psql -U #{node.geoshape.database_master_user} -d #{node.geoshape.imports_database.name} -t -c \"select count(1) from pg_available_extensions where installed_version is not null and name = 'postgis'\" | grep 0"
end
