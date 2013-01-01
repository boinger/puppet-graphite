class graphite::params {
	$build_dir = "/usr/local/src/"
	
	$graphiteVersion = "graphite-web-0.9.10"
	$carbonVersion   = "carbon-0.9.10"
	$whisperVersion  = "whisper-0.9.10"
	
	$whisper_dl_url  = "http://launchpad.net/graphite/0.9/0.9.10/+download/${whisperVersion}.tar.gz"
	$whisper_dl_loc  = "$build_dir/whisper.tar.gz"
	
	$webapp_dl_url   = "http://launchpad.net/graphite/0.9/0.9.10/+download/${graphiteVersion}.tar.gz"
	$webapp_dl_loc   = "$build_dir/graphite-web.tar.gz"
	
	$carbon_dl_url   = "http://launchpad.net/graphite/0.9/0.9.10/+download/${carbonVersion}.tar.gz"
	$carbon_dl_loc   = "$build_dir/carbon.tar.gz"
	
	$install_prefix  = "/opt/"

	$apache_service_name = "httpd"
	$web_user            = "apache"
	$web_gid             = $web_user
	$graphitepkgs        = []
 
}
