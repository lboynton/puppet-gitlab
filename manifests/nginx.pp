class gitlab::nginx(
		$vhost = $fqdn,
	){
    nginx::resource::upstream { 'gitlab':
        ensure  => present,
        members => [
            'unix:/home/gitlab/gitlab/tmp/sockets/gitlab.socket',
        ]
    }

    nginx::resource::vhost { "$vhost":
        ensure      => present,
        www_root    => '/home/gitlab/gitlab/public',
        try_files   => '$uri $uri/index.html $uri.html @gitlab',
    }

    nginx::resource::location { "@gitlab":
        location            => '@gitlab',
        proxy               => 'http://gitlab',
        vhost               => "$vhost",
        proxy_read_timeout  => 300,
    }
}
