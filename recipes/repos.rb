#
# Cookbook Name:: geoshape
# Recipe:: repos
#
# Copyright 2016, Boundless
#
# All rights reserved - Do Not Redistribute
#

case node.platform
when "redhat"
  # RHEL is missing some base packages that we need, so adding the CentOS base repo
  cookbook_file "/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-#{node.platform_version.to_i}" do
    source "RPM-GPG-KEY-CentOS-#{node.platform_version.to_i}"
    mode 0644
  end

  yum_repository "centos-base" do
    description "CentOS Base Repo"
    mirrorlist "http://mirrorlist.centos.org/?release=#{node.platform_version.to_i}&arch=$basearch&repo=os&infra=$infra"
    gpgkey "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-#{node.platform_version.to_i}"
    exclude "centos-logos basesystem chrony subscription-manager yum linux-firmware abrt* redhat* python*"
  end

  yum_repository "rabbitmq-server" do
    description "RabbitMQ Server"
    baseurl "https://packagecloud.io/rabbitmq/rabbitmq-server/el/#{node.platform_version.to_i}/$basearch"
    gpgcheck false
  end

  yum_repository "geoshape" do
    description "GeoShape Repo"
    baseurl "http://yum.boundlessps.com/el#{node.platform_version.to_i}/$basearch"
    gpgkey "http://yum.boundlessps.com/RPM-GPG-KEY-yum.boundlessps.com"
  end

  execute "rpm --import http://yum.boundlessps.com/RPM-GPG-KEY-yum.boundlessps.com" do
    not_if "rpm -q gpg-pubkey | grep gpg-pubkey-3b7df5eb-569d1240"
  end

  yum_repository "pgdg95" do
    description "Postgres 9.5 Community Repo"
    baseurl "https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-$releasever-$basearch"
    gpgkey "http://yum.boundlessps.com/RPM-GPG-KEY-PGDG-95"
  end

  yum_repository "elasticsearch" do
    description "Elasticearch 1.7 Community Repo"
    baseurl "http://packages.elastic.co/elasticsearch/1.7/centos"
    gpgkey "http://packages.elastic.co/GPG-KEY-elasticsearch"
  end
when "centos"
  yum_repository "rabbitmq-server" do
    description "RabbitMQ Server"
    baseurl "https://packagecloud.io/rabbitmq/rabbitmq-server/el/$releasever/$basearch"
    gpgcheck false
  end

  execute "rpm --import http://yum.boundlessps.com/RPM-GPG-KEY-yum.boundlessps.com" do
    not_if "rpm -q gpg-pubkey | grep gpg-pubkey-3b7df5eb-569d1240"
  end

  yum_repository "geoshape" do
    description "GeoShape Repo"
    baseurl "http://yum.boundlessps.com/el$releasever/$basearch"
    gpgkey "http://yum.boundlessps.com/RPM-GPG-KEY-yum.boundlessps.com"
  end

  yum_repository "pgdg95" do
    description "Postgres 9.5 Community Repo"
    baseurl "https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-$releasever-$basearch"
    gpgkey "http://yum.boundlessps.com/RPM-GPG-KEY-PGDG-95"
  end

  yum_repository "elasticsearch" do
    description "Elasticearch 1.7 Community Repo"
    baseurl "http://packages.elastic.co/elasticsearch/1.7/centos"
    gpgkey "http://packages.elastic.co/GPG-KEY-elasticsearch"
  end
else
  Chef::Log.warn("Unsupported platform #{node.platform}")
end
