class gitlab::gitlab(
    $db_username,
    $db_password,
) {
    vcsrepo { 'gitlab':
        ensure      => present,
        path        => '/home/gitlab/gitlab',
        provider    => git,
        source      => 'https://github.com/gitlabhq/gitlabhq.git',
        revision    => '4-1-stable',
        owner       => 'gitlab',
        group       => 'gitlab',
        require     => User['gitlab'],
    }

    file { '/home/gitlab/gitlab/config/gitlab.yml':
        ensure      => file,
        owner       => 'gitlab',
        group       => 'gitlab',
        content     => template('gitlab/gitlab.yml.erb'),
    }

    file { '/home/gitlab/gitlab/config/database.yml':
        ensure      => file,
        owner       => 'gitlab',
        group       => 'gitlab',
        content     => template('gitlab/database.yml.erb'),
    }

    if !defined(Package['mysql-devel']) {
        package {'mysql-devel':
            ensure  => installed,
        }
    }

    if !defined(Package['libicu-devel']) {
        package { 'libicu-devel':
            ensure      => installed,
        }
    }

    package { 'charlock_holmes':
        ensure      => installed,
        provider    => gem,
        require     => Package['libicu-devel'],
    }

    exec { '/usr/local/rvm/gems/ruby-1.9.3-p374@global/bin/bundle install --deployment --without development test postgres':
        cwd         => '/home/gitlab/gitlab',
        user        => 'gitlab',
        require     => [
            Class['gitlab::ruby'], 
            Vcsrepo['gitlab'], 
            Package['charlock_holmes'], 
            Package['mysql-devel']
        ],
        logoutput   => on_failure,
    }
}