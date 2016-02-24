# This is an awful way to deal with IPs. This entire thing is pointless outside of vagrant and a local VM
default.geoshape.endpoint =
  if Chef::Config[:solo]
    case node.platform
    when "centos", "redhat"
      case node.platform_version.to_i
      when 6
        node['network']['interfaces']['eth1']['addresses'].detect{|k,v| v[:family] == "inet" }.first
      when 7
        node['network']['interfaces']['enp0s8']['addresses'].detect{|k,v| v[:family] == "inet" }.first
      end
    end
  else
    node.ipaddress
  end

node.normal.tomcat.base_version = 8
node.normal.tomcat.install_method = "archive"
node.normal.tomcat.jndi = true
node.normal.java.oracle.accept_oracle_download_terms = true
node.normal.java.oracle.jce.enabled = true
node.normal.java.jdk_version = 8

case node.platform
when "centos", "redhat"
  default.tomcat_max_heap = "#{(node.memory.total.to_i * 0.4 ).floor / 1024}m"
  default.elasctic_max_heap = "#{(node.memory.total.to_i * 0.1 ).floor / 1024}m"
  node.normal.java.java_home = "/usr/lib/jvm/java"
  node.normal.java.install_flavor = "oracle"
  node.normal['java']['jdk']['8']['x86_64']['url'] = "https://s3.amazonaws.com/boundlessps-public/jdk-8u74-linux-x64.tar.gz"
  node.normal['java']['jdk']['8']['x86_64']['checksum'] = "0bfd5d79f776d448efc64cb47075a52618ef76aabb31fde21c5c1018683cdddd"
end

node.normal.tomcat.java_options = "-Djava.awt.headless=true -Xms256m -Xmx#{node.tomcat_max_heap} -Xrs -XX:PerfDataSamplingInterval=500 -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:NewRatio=2 -XX:SoftRefLRUPolicyMSPerMB=36000 -Dorg.geotools.shapefile.datetime=true -Djava.library.path=/opt/libjpeg-turbo/lib64:/usr/lib64  -Duser.home=/var/lib/geoserver_data/geogig"

default.geoshape.https_only = false
default.geoshape.https_enabled = false
default.geoshape.cert = "#{node.apache.dir}/ssl/geoshape_cert"
default.geoshape.cert_chain = "#{node.apache.dir}/ssl/geoshape_bundle"
default.geoshape.cert_key = "#{node.apache.dir}/ssl/geoshape_key"

# default.geoshape.installation_method = "package"
default.geoshape.etc = "/etc/geoshape"
default.java_keystore = "/etc/pki/java/cacerts"
default.geoshape.basedir = "/var/lib/geonode"
default.geoshape.bindir = "#{node.geoshape.basedir}/bin"
default.python27 = "#{node.geoshape.bindir}/python2.7"
default.geoshape.rogue_geonode = "#{node.geoshape.basedir}/rogue_geonode"
default.geoshape.manage = "#{node.geoshape.rogue_geonode}/manage.py"
default.geoshape.rabbitmq.endpoint = "localhost"
default.geoshape.rabbitmq.user = "guest"
default.geoshape.rabbitmq.port = 5672
default.geoshape.elasticsearch.endpoint = "http://localhost"
default.geoshape.elasticsearch.port = 9200
default.geoshape.allowed_hosts = ["#{node.geoshape.endpoint}"]
default.geoshape.geoserver.data_dir = "/var/lib/geoserver_data"
default.geoshape.geoserver.gwc_data_dir = "#{node.geoshape.geoserver.data_dir}/gwc"
default.geoshape.geoserver.endpoint = "localhost"
default.geoshape.geoserver.jsonp_enabled = false
default.geoshape.email_host = "localhost"
default.geoshape.email_port = 25
default.geoshape.email_from = "webmaster@#{node.geoshape.endpoint}"
default.geoshape.enable_registration = true
default.geoshape.account_activation = 7
default.geoshape.account_approval = true
default.geoshape.account_email_confirm = true
default.geoshape.auth_exempt_urls = ["'/account/signup/*'"]
default.geoshape.debug = true
default.geoshape.lockdown_geonode = true

default.geoserver.root_user.password = "OUEJ6u1ZgQme"
default.geoserver.root_user.password_hash = "SMyGqqwmWVUqNmYvMpy/yU7pJflL/BcT"
default.geoserver.root_user.password_digest = "digest1:Oa8Fkm86HT17L840PSMTBmUBMnyho+HqSKfQhyHvDNqRZpiKxTz9GK5S1SuyQoDV"
default.geoshape.geoserver.password_hash = "crypt1:R79GCWTjNzQgvYHOziTXhWyNfBHwzd6M"
default.geoshape.geoserver.admin_password = "OUEJ6u1ZgQme"
default.geoshape.geoserver.admin_user = "admin"
default.geoshape.database.password = "boundless"
default.geoshape.imports_database.password = node.geoshape.database.password
default.geoshape.admin_user = "admin"
default.geoshape.admin_password = "boundless"
default.geoshape.admin_password_hash = "pbkdf2_sha256$29000$wGjL9reU91fZ$FKyyAQlNJ5mbCVCukw0VWh51NEnCCarIbOUrK/4SXbU="
default.geoshape.database_master_password = "ui2lGJ30g5"
default.geoshape.database_master_user = "postgres"

# Default chef vault structure for all credentials
default.geoshape.cert_vault = {:name => 'certs', :item => 'geoshape'}
default.geoshape.database.vault = {:name => 'geoshape', :item => 'database'}
default.geoshape.geoserver.vault = {:name => 'geoshape', :item => 'geoserver'}
default.geoshape.geonode.vault = {:name => 'geoshape', :item => 'geonode'}

default.geoshape.database.endpoint = "localhost"
default.geoshape.database.port = 5432
default.geoshape.database.user = "geoshape"
default.geoshape.database.name = "geoshape"

default.geoshape.imports_database.endpoint = node.geoshape.database.endpoint
default.geoshape.imports_database.port = node.geoshape.database.port
default.geoshape.imports_database.user = node.geoshape.database.user
default.geoshape.imports_database.name = "geoshape_data"
default.geoshape.imports_database.geonode_alias = "geoshape_imports"
