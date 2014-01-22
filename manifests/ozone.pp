# Specifically targetting CentOS 5.8 with this class.

class ozone::ozone ( $user = 'ozone', 
  $ozone_home = '/opt/ozone', 
  $ozone_https_port = 443, 
  $ozone_http_port = 80,
  $ozone_hostname = 'localhost',
  $ozone_ca_cert = '',
  $ozone_ca_key = '',
  $ozone_version = '7-GA'
) {

  # Remote location to 3.8.1 bundle
  $ver_381 = ""
  
  if !defined(Service['iptables']) {
    service { "iptables": ensure => false, enable => false }
  }
  
  if $ozone_version == '7-GA' {
    exec { "get_ozone":
      cwd     => $ozone_home,
      command => "wget https://s3.amazonaws.com/org.ozoneplatform/OWF/7-GA/OWF-bundle-7-GA.zip -O owf-7-GA.zip",
      creates => "${ozone_home}/owf-7-GA.zip",
      timeout => 3000,
    }
  } elsif $ozone_version == '3.8.1' {
    exec { "get_ozone":
      cwd     => $ozone_home,
      command => "wget ${ver_381},
      creates => "${ozone_home}/owf-${ozone_version}.zip",
      timeout => 3000,
    }
  }

  user { $user:
      ensure  => 'present',
      home    => "/home/${user}",
      shell   => '/bin/bash',
      groups  => 'wheel'
  } ->
  file { "/home/${user}": 
      ensure  => 'directory',
      owner   => $user,
      group   => $user,
      mode    => "0770"
  } ->
  file { "/home/${user}/projects": 
      ensure  => directory,
      owner   => $user,
      group   => $user } ->
  file { $ozone_home:
      ensure  => 'directory',
      owner   => $user,
      group   => $user,
      mode    => "0775" 
  } ->
  file { "${ozone_home}/certs":
      ensure  => 'directory',
      owner   => $user,
      group   => $user,
      mode    => "0775"
  } ->     
  file { "/var/run/ozone/":
      ensure  => 'directory',
      owner   => $user,
      group   => $user,
      mode    => "0775"
  } 
  
  if $ozone_ca_cert == '' {
    warning('No root CA being used, will self-sign a certificate.')
  }
  else
  {
    file { "ca_cert":
      path    => "${ozone_home}/certs/${ozone_ca_cert}",
      source  => "puppet:///modules/ozone/${ozone_ca_cert}",
      require => File["${ozone_home}/certs/"]
    } 
    file { "ca_key":
      path    => "${ozone_home}/certs/${ozone_ca_key}",
      source  => "puppet:///modules/ozone/${ozone_ca_key}",
      require => File["${ozone_home}/certs/"]
    }
  }

  package{ "unzip": ensure => installed } ->
  package { "java-1.6.0-openjdk-devel": ensure => installed } ->
  # Need Ant from source here
  exec { "get_ant": 
    cwd     => '/usr/local',
    command => 'wget http://mirrors.ibiblio.org/apache//ant/binaries/apache-ant-1.9.3-bin.zip',
    creates => '/usr/local/apache-ant-1.9.3-bin.zip',
  } ->
  exec { "unzip_ant":
    cwd     => '/usr/local',
    command => 'unzip apache-ant-1.9.3-bin.zip',
    creates => '/usr/local/apache-ant-1.9.3'
  } -> 
  file { "/usr/local/bin/ant":
    ensure => link,
    target => '/usr/local/apache-ant-1.9.3/bin/ant'
  } -> 
  exec { "unzip_ozone":
    user    => $user,
    cwd     => $ozone_home,
    command => "unzip owf-${ozone_version}.zip",
    creates => "${ozone_home}/apache-tomcat-7.0.21",
    require => Exec['get_ozone']
  } ->
  file { "${ozone_home}/tomcat":
    ensure  => "link",
    owner   => $user,
    group   => $user,
    target  => "${ozone_home}/apache-tomcat-7.0.21",
  } ->
  file { "${ozone_home}/tomcat/bin/catalina.sh":
    owner => $user,
    group => $user,
    mode  => "0755"
  } ->
  file { "${ozone_home}/tomcat/conf/server.xml":
    owner   => $user,
    group   => $user,
    mode    => "0755",
    content => template("ozone/server.xml.erb"),
  } ->
  file { "${ozone_home}/tomcat/lib/OzoneConfig.properties":
    owner   => $user,
    group   => $user,
    mode    => "0755",
    content => template("ozone/OzoneConfig.properties.erb"),
  } ->
  file { "${ozone_home}/tomcat/bin/setenv.sh":
    owner   => $user,
    group   => $user,
    mode    => "0755",
    content => template("ozone/setenv.sh.erb"),
  } ->
  file { "${ozone_home}/etc/tools/create_certs.sh":
    owner   => $user,
    group   => $user,
    mode    => "0775",
    content => template("ozone/create_certs.sh.erb")
  } ->
  exec { "${ozone_home}/etc/tools/create_certs.sh":
    user    => "root",
    cwd     => "${ozone_home}/etc/tools",
    creates => "${ozone_home}/etc/tools/${ozone_hostname}.jks"
  } ->
  exec { "cp ${ozone_home}/etc/tools/${ozone_hostname}.jks ${ozone_home}/tomcat/certs/":
    user    => "root",
    cwd     => "${ozone_home}/etc/tools",
    creates => "${ozone_home}/tomcat/certs/${ozone_hostname}.jks"
  } ->
  file { "/etc/init.d/ozone":
    owner   => 'root',
    group   => 'root',
    mode    => "0755",
    content => template("ozone/ozone.erb"),
  } ->
  file { "${ozone_home}/tomcat/webapps/ozone":
    ensure  => 'directory',
    owner   => $user,
    group   => $user,
  } ->
  service { "ozone":
    ensure => running, 
    enable => true
  }
}
