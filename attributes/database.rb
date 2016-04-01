case node.platform
when "centos", "redhat", "oracle"
  default.postgresql.enable_pgdg_yum = true
  default.postgresql.version = "9.5"
  default.postgresql.server.service_name = "postgresql-#{node.postgresql.version}"
  default.postgresql.dir = "/var/lib/pgsql/#{node.postgresql.version}/data"
  default.postgresql.config.data_directory = node.postgresql.dir
  default.geoshape.postgresql_version = node.postgresql.version.split('.').join
  default.postgresql.initdb_locale = "en_US.UTF-8"

  default.postgresql.client.packages = ["postgresql#{node.geoshape.postgresql_version}"]
  default.postgresql.server.packages = ["postgresql#{node.geoshape.postgresql_version}-server"]
  default.postgresql.contrib.packages = ["postgresql#{node.geoshape.postgresql_version}-contrib"]

  case node.platform_version.to_i
  when 7
    default.postgresql.setup_script = "/usr/pgsql-#{node.postgresql.version}/bin/postgresql#{node.geoshape.postgresql_version}-setup"
  end
end

default['postgresql']['pg_hba'] = [
  {:type => 'local', :db => 'all', :user => 'postgres', :addr => nil, :method => 'trust'},
  {:type => 'local', :db => 'all', :user => 'all', :method => 'md5'},
  {:type => 'host', :db => 'all', :user => 'all', :addr => '127.0.0.1/32', :method => 'md5'},
  {:type => 'host', :db => 'all', :user => 'all', :addr => '::1/128', :method => 'md5'}
]

# node.save unless Chef::Config[:solo]
