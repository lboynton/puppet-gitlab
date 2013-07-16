class gitlab::deps {
	if !defined(Package['git']) {
		package { 'git':
	        ensure  	=> installed,
	    }
	}

	if !defined(Package['libicu-devel']) {
        package { 'libicu-devel':
            ensure      => installed,
        }
    }

    if !defined(Package['patch']) {
        package { 'patch':
            ensure      => installed,
        }
    }

    if !defined(Package['libxml2-devel']) {
        package { 'libxml2-devel':
            ensure      => installed,
        }
    }

    if !defined(Package['libxslt-devel']) {
        package { 'libxslt-devel':
            ensure      => installed,
        }
    }
}