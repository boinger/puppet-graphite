class graphite::config (
  $gr_user                      = "graphite",
  $gr_gid                       = "carbon",
  $gr_max_cache_size            = "inf",
  $gr_max_updates_per_second    = 500,
  $gr_max_creates_per_minute    = 50,
  $gr_line_receiver_interface   = "0.0.0.0",
  $gr_line_receiver_port        = 2003,
  $gr_enable_udp_listener       = "False",
  $gr_udp_receiver_interface    = "0.0.0.0",
  $gr_udp_receiver_port         = 2003,
  $gr_pickle_receiver_interface = "0.0.0.0",
  $gr_pickle_receiver_port      = 2004,
  $gr_use_insecure_unpickler    = "False",
  $gr_cache_query_interface     = "0.0.0.0",
  $gr_cache_query_port          = 7002,
  $gr_timezone                  = 'GMT',
  $gr_secretkey                 = 'defaultsecretkey',
  $gr_default_retentions        = '30s:24h,60s:2d,300s:60d,600s:500d',
) inherits graphite::params {

  anchor { 'graphite::config::begin': }
  anchor { 'graphite::config::end': }

  Exec {path => '/bin:/usr/bin:/usr/sbin', }

  file { "/etc/httpd/conf.d/welcome.conf":
    ensure  => absent,
    require => Package["httpd"],
  }

  service {
    "httpd":
      hasrestart => true,
      hasstatus  => true,
      ensure     => running,
      enable     => true,
      require    => File['/data/graphite/storage/'];

   "carbon-cache":
      hasstatus  => true,
      hasrestart => true,
      ensure     => running,
      enable     => true,
      before     => Anchor['graphite::config::end'],
      require    => File["/etc/init.d/carbon-cache"];
  }

  # first init of user db for graphite
  exec {
    "Initial django db creation":
      command => "python manage.py syncdb --noinput",
      cwd     => "/usr/lib/python2.6/site-packages/graphite",
      creates => "/data/graphite/storage/graphite.db",
      require => [
        Package['python-carbon'],
        Package['graphite-web'],
        File['/etc/graphite-web/local_settings.py'],
        ];
  }

  # Deploy configfiles
  file {
    "/data/graphite":
      ensure  => directory,
      mode    => 0755,
      owner   => "$gr_user",
      group   => "$gr_gid",
      require => File['/data'];

    "/data/graphite/storage":
      ensure => directory,
      mode   => 0775,
      owner  => "$gr_user",
      group  => "$gr_gid";

    "/data/graphite/storage/whisper":
      ensure => directory,
      mode   => 0775,
      owner  => "$gr_user",
      group  => "$gr_gid",
      before => Service['carbon-cache'];

    "/data/graphite/storage/graphite.db":
      mode    => 0664,
      owner   => "$gr_user",
      group   => "$gr_gid",
      require => Exec['Initial django db creation'];

    [
    "/data/graphite/storage/log",
    "/data/graphite/storage/log/webapp"
    ]:
      ensure  => directory,
      recurse => true,
      mode    => 0775,
      owner   => "$gr_user",
      group   => "$gr_gid",
      require => Service['httpd'];

    "/opt/graphite":
      ensure => directory,
      mode   => 0755,
      owner  => "$gr_user",
      group  => "$gr_gid";

    "/opt/graphite/storage":
      ensure  => '/data/graphite/storage',
      require => [
          File['/opt/graphite'],
          File['/data/graphite/storage'],
        ];

    "/opt/graphite/webapp":
      ensure  => '/usr/share/graphite/webapp',
      require => File['/opt/graphite'];

    "/etc/graphite-web/local_settings.py":
      mode    => 644,
      owner   => "$gr_user",
      group   => "$gr_gid",
      content => template("graphite/opt/graphite/webapp/graphite/local_settings.py.erb"),
      require => Package["httpd"];

    "/usr/lib/python2.6/site-packages/graphite/local_settings.py":
      ensure => "/etc/graphite-web/local_settings.py";

    "/etc/graphite-web/app_settings.py":  ## Even though the file says not to mod it directly, we have to because of Django v1.4
      mode    => 0644,
      owner   => "$gr_user",
      group   => "$gr_gid",
      content => template("graphite/opt/graphite/webapp/graphite/app_settings.py.erb"),
      require => [Package["httpd"],Exec["Initial django db creation"]];

    "/usr/lib/python2.6/site-packages/graphite/app_settings.py":
      ensure => "/etc/graphite-web/app_settings.py";

    "/etc/httpd/conf.d/graphite.conf":
      mode    => 0644,
      owner   => "$web_user",
      group   => "$web_gid",
      content => template("graphite/etc/apache2/sites-available/graphite.conf.erb"),
      require => [Package["httpd"],Exec["Initial django db creation"]],
      #notify  => [Exec["Chown graphite for apache"], Service['httpd']];
      notify  => Service['httpd'];

    "/opt/graphite/conf":
      recurse => true,
      mode    => 0644,
      owner   => "$gr_user",
      group   => "$gr_gid",
      source  => "puppet:///modules/graphite/opt/graphite/conf";

    "/opt/graphite/conf/graphite.wsgi":
      mode    => 0644,
      owner   => "$gr_user",
      group   => "$gr_gid",
      content => template("graphite/opt/graphite/conf/graphite.wsgi.erb"),
      require => [Package["httpd"],File["/etc/httpd/conf.d/graphite.conf"]],
      notify  => [Service['httpd']];

  # configure carbon engine
    "/opt/graphite/conf/storage-schemas.conf":
      mode    => 0644,
      owner   => "$gr_user",
      group   => "$gr_gid",
      content => template("graphite/opt/graphite/conf/storage-schemas.conf.erb"),
      require => Package["graphite-web"],
      notify  => Service["carbon-cache"];

    "/opt/graphite/conf/storage-aggregation.conf":
      mode    => 0644,
      owner   => "$gr_user",
      group   => "$gr_gid",
      content => template("graphite/opt/graphite/conf/storage-aggregation.conf.erb"),
      require => Package["graphite-web"]; ## No notify needed -- this file is monitored for changes

    "/opt/graphite/conf/carbon.conf":
      mode    => 0644,
      content => template("graphite/opt/graphite/conf/carbon.conf.erb"),
      require => Package["graphite-web"],
      notify  => Service["carbon-cache"];

    "/etc/init.d/carbon-cache":
      ensure  => present,
      mode    => 0750,
      content => template("graphite/etc/init.d/carbon-cache.erb"),
      require => File["/opt/graphite/conf/carbon.conf"];

    "/opt/graphite/bin":
      ensure  => directory,
      mode    => 0755;

  # search index builder
    "/opt/graphite/bin/build-index.sh":
      mode    => 0755,
      content => template("graphite/opt/graphite/bin/build-index.sh.erb"),
      require => Package["graphite-web"];

  # configure logrotate script for carbon
    "/opt/graphite/bin/carbon-logrotate.sh":
      mode    => 0755,
      content => template("graphite/opt/graphite/bin/carbon-logrotate.sh.erb"),
      require => Package["graphite-web"];
  }

  cron {
    "Rebuild graphite index":
      command => "/opt/graphite/bin/build-index.sh 2>&1 >/dev/null",
      user    => root,
      hour    => '4',
      minute  => '44',
      require => File["/opt/graphite/bin/build-index.sh"];

    # XXX has a hard coded path that is bad. I don't see log files piling up, so I'm removing this for now
    "Rotate carbon logs":
      ensure => absent;
    #   command => "/opt/graphite/bin/carbon-logrotate.sh",
    #   user    => root,
    #   hour    => '1',
    #   minute  => '15',
    #   require => File["/opt/graphite/bin/carbon-logrotate.sh"];
  }

}
