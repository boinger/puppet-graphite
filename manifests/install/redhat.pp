# Works for Redhat 6.4+, Scientific 6.4+, and CentOS 6.4+

class graphite::install::redhat {

	package {
		[
		"graphite-web",
		"python-carbon",
		"python-whisper",
		]:
			ensure => latest;
	}

	/*
# Works for Redhat 6.x, Scientific 6.x, and CentOS 6.x
	require graphite::params

	Exec {path => '/bin:/usr/bin:/usr/sbin', }
	Package  { ensure => "installed", }

	# for full functionality we need this packages:
	# madatory: python-cairo, python-django, python-twisted, python-django-tagging, python-simplejson
	# optinal: python-ldap, python-memcache, memcached, python-sqlite

	anchor { "graphitepkg::begin": }
	anchor { "graphitepkg::end": }

	package {
		$graphitepkgs:
			require => Anchor["graphitepkg::begin"],
			before  => Anchor["graphitepkg::end"]
	}

	# Install required python env special for redhat/centos

	package {
		"python-setuptools":
			require => Anchor["graphitepkg::begin"],
			before  => Anchor["graphitepkg::end"]
	}

	exec {
		"Install django-tagging":
			command => "easy_install django-tagging",
			cwd     => "$build_dir",
			require => Anchor["graphitepkg::end"];

		"Install twisted":
			command => "easy_install twisted",
			cwd     => "$build_dir",
			require => Anchor["graphitepkg::end"];

		"Install txamqp":
			command => "easy_install txamqp",
			cwd     => "$build_dir",
			require => Anchor["graphitepkg::end"];
	}

	# Download graphite sources

	exec {
		"Download and untar $graphiteVersion":
			command => "wget -O - $webapp_dl_url | tar xz",
			creates => "${build_dir}/$graphiteVersion",
			cwd     => "$build_dir";

		"Download and untar $carbonVersion":
			command => "wget -O - $carbon_dl_url | tar xz",
			creates => "${build_dir}/$carbonVersion",
			cwd     => "$build_dir";

		"Download and untar $whisperVersion":
			command => "wget -O - $whisper_dl_url | tar xz",
			creates => "${build_dir}/$whisperVersion",
			cwd     => "$build_dir";
	}

	# Install graphite from source

	exec {
		"Install $graphiteVersion":
			command     => "python setup.py install",
			cwd         => "${build_dir}/$graphiteVersion",
			subscribe   => Exec["Download and untar $graphiteVersion"],
			refreshonly => true,
			require     => [Exec["Download and untar $graphiteVersion"],Exec["Install django-tagging"]];

		"Install $carbonVersion":
			command     => "python setup.py install",
			cwd         => "${build_dir}/$carbonVersion",
			subscribe   => Exec["Download and untar $carbonVersion"],
			refreshonly => true,
			require     => [Exec["Download and untar $carbonVersion"],Exec["Install twisted"]];

		"Install $whisperVersion":
			command     => "python setup.py install",
			cwd         => "${build_dir}/$whisperVersion",
			subscribe   => Exec["Download and untar $whisperVersion"],
			refreshonly => true,
			require     => [Exec["Download and untar $whisperVersion"],Exec["Install twisted"]];
	}
	*/
	
}
