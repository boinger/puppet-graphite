class graphite::config (
	$gr_user = "graphite",
	$gr_max_cache_size = "inf",
	$gr_max_updates_per_second = 500,
	$gr_max_creates_per_minute = 50,
	$gr_line_receiver_interface = "0.0.0.0",
	$gr_line_receiver_port = 2003,
	$gr_enable_udp_listener = "False",
	$gr_udp_receiver_interface = "0.0.0.0",
	$gr_udp_receiver_port = 2003,
	$gr_pickle_receiver_interface = "0.0.0.0",
	$gr_pickle_receiver_port = 2004,
	$gr_use_insecure_unpickler = "False",
	$gr_cache_query_interface = "0.0.0.0",
	$gr_cache_query_port = 7002,
	$gr_timezone = 'GMT',
) inherits graphite::params {

	anchor { 'graphite::config::begin': }
	anchor { 'graphite::config::end': }

	Exec {
		path => '/bin:/usr/bin:/usr/sbin',
	}

	file { "/etc/httpd/conf.d/welcome.conf":
		ensure  => absent,
		require => Package["httpd"],
	}

	service { "httpd":
			hasrestart => true,
			hasstatus  => true,
			ensure     => running,
			enable     => true,
			require    => Exec["Chown graphite for apache"];
	}

	# first init of user db for graphite
	exec { "Initial django db creation":
			command     => "python manage.py syncdb --noinput",
			cwd         => "/opt/graphite/webapp/graphite",
			refreshonly => true,
			notify      => Exec["Chown graphite for apache"],
			#subscribe  => Exec["Install $graphiteVersion"],
			before      => Exec["Chown graphite for apache"],
			require     => [Package['carbon'],Package['graphite-web']],
	}

	# change access permissions for apache
	exec { "Chown graphite for apache":
			command     => "chown -R $web_user:$web_user /opt/graphite/storage/",
			cwd         => "/opt/graphite/",
			refreshonly => true,
			require     => Package["graphite-web"],
	}

	# Deploy configfiles
	file {
		"/opt/graphite/webapp/graphite/local_settings.py":
			mode    => 644,
			owner   => "$web_user",
			group   => "$web_user",
			content => template("graphite/opt/graphite/webapp/graphite/local_settings.py.erb"),
			require => [Package["httpd"],Exec["Initial django db creation"]];

		"${apacheconf_dir}/graphite.conf":
			mode    => 644,
			owner   => "$web_user",
			group   => "$web_user",
			content => template("graphite/etc/apache2/sites-available/graphite.conf.erb"),
			require => [Package["httpd"],Exec["Initial django db creation"]],
	}

	# configure carbon engine
	file {
		"/opt/graphite/conf/storage-schemas.conf":
			mode    => 644,
			content => template("graphite/opt/graphite/conf/storage-schemas.conf.erb"),
			require => Package["graphite-web"],
			notify  => Service["carbon-cache"];

		"/opt/graphite/conf/carbon.conf":
			mode    => 644,
			content => template("graphite/opt/graphite/conf/carbon.conf.erb"),
			require => Package["graphite-web"],
			notify  => Service["carbon-cache"];
	}


	# configure logrotate script for carbon
	file { "/opt/graphite/bin/carbon-logrotate.sh":
			mode    => 544,
			content => template("graphite/opt/graphite/bin/carbon-logrotate.sh.erb"),
			require => Package["graphite-web"];
	}

	cron { "Rotate carbon logs":
			command => "/opt/graphite/bin/carbon-logrotate.sh",
			user    => root,
			hour    => '1',
			minute  => '15',
			require => File["/opt/graphite/bin/carbon-logrotate.sh"];
	}

	# startup carbon engine
	service { "carbon-cache":
			hasstatus  => true,
			hasrestart => true,
			ensure     => running,
			enable     => true,
			before     => Anchor['graphite::config::end'],
			require    => File["/etc/init.d/carbon-cache"];
	}

	file { "/etc/init.d/carbon-cache":
			ensure  => present,
			mode    => 750,
			content => template("graphite/etc/init.d/carbon-cache.erb"),
			require => File["/opt/graphite/conf/carbon.conf"];
	}
}
