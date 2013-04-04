name             'chef-server'
maintainer       'Protec Innovations Ltd'
maintainer_email 'dev@protecinnovations.co.uk'
license          'BSD'
description      'Installs/Configures chef-server using system packages'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "openssl"
depends "nginx"
