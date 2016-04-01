name             'geoshape'
maintainer       'Boundless'
maintainer_email 'arahav@boundlessgeo.com'
license          'All rights reserved'
description      'Installs/Configures geoshape'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.3'

depends 'postgresql', '3.4.24'
depends 'chef-vault'
depends 'apache2'
depends 'tomcat', '1.0.1'
depends 'java'
depends 'yum-epel'
