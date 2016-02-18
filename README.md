GeoShape Cookbook
=================

Requirements
-----
### Chef

* Chef 12.x

### Platform

* CentOS 6.x, 7.x
* RHEL 6.x, 7.x

How To
-----

### Vagrant

As well as installing [Vagrant](https://www.vagrantup.com/downloads.html) You will also have to install [ChefDK](https://downloads.chef.io/chef-dk)

After installing Vagrant you also have to install the following two Plugins:
* vagrant-berkshelf
* vagrant-omnibus

Once those are installed you may run __vagrant up__ to create a new VM

Attributes
-----

- `node['geoshape']['endpoint']` - The public endpoint for your GeoShape instance. Can be either an IP address or DNS name
- `node['geoshape']['https_only']` - Will redirect HTTP to HTTPS if set to `true`. Requires - `node['geoshape']['https_enabled']` to also be set to `true`
- `node['geoshape']['cert']` - The location on the filesystem to put the SSL certificate. Requires the use of Chef Vault
- `node['geoshape']['cert_chain']` - The location on the filesystem to put the SSL certificate chain. Requires the use of Chef Vault
- `node['geoshape']['cert_key']` - The location on the filesystem to put the SSL certificate private key. Requires the use of Chef Vault
- `node['java_keystore']` - 
- `node['geoshape']['rabbitmq']['endpoint']` - 
- `node['geoshape']['allowed_hosts']` -
- `node['geoshape']['geoserver']['endpoint']` - 
- `node['geoshape']['geoserver']['jsonp_enabled']` - 
- `node['geoshape']['email_host']` - 
- `node['geoshape']['email_port']` - 
- `node['geoshape']['email_from']` - 
- `node['geoshape']['enable_registration']` - 
- `node['geoshape']['account_activation']` - 
- `node['geoshape']['account_approval']` - 
- `node['geoshape']['account_email_confirm']` - 
- `node['geoshape']['auth_exempt_urls']` - 
- `node['geoshape']['debug']` - 
- `node['geoshape']['lockdown_geonode']` - 

- `node['geoserver']['root_user']['password']` - 
- `node['geoserver']['root_user']['password_hash']` -  
- `node['geoserver']['root_user']['password_digest']` -  
- `node['geoshape']['geoserver']['password_hash']` -  
- `node['geoshape']['geoserver']['admin_password']` -  
- `node['geoshape']['geoserver']['admin_user']` -  
- `node['geoshape']['database']['password']` -  
- `node['geoshape']['imports_database']['password']` - 
- `node['geoshape']['admin_user']` -  
- `node['geoshape']['admin_password']` -  
- `node['geoshape']['admin_password_hash']` -  
- `node['geoshape']['database_master_password']` -  
- `node['geoshape']['database_master_user']` -  

- `node['geoshape']['cert_vault']` - {:name => 'certs', :item => 'geoshape'}
- `node['geoshape']['database']['vault']` - {:name => 'geoshape', :item => 'database'}
- `node['geoshape']['geoserver']['vault']` - {:name => 'geoshape', :item => 'geoserver'}
- `node['geoshape']['geonode']['vault']` - {:name => 'geoshape', :item => 'geonode'}

- `node['geoshape']['database']['endpoint']` - 
- `node['geoshape']['database']['port']` - 
- `node['geoshape']['database']['user']` - 
- `node['geoshape']['database']['name']` - 
- `node['geoshape']['imports_database']['endpoint']` - 
- `node['geoshape']['imports_database']['port']` - 
- `node['geoshape']['imports_database']['user']` - 
- `node['geoshape']['imports_database']['name']` - 
- `node['geoshape']['imports_database']['geonode_alias']` - 
