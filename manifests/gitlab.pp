class gitlab::gitlab(
    $db_server   = 'localhost',
    $db_type     = 'mysql',
    $db_name     = 'gitlab',
    $db_username = 'gitlab',
    $db_password = 'gitlab',
    $vhost       = $fqdn,
    $port        = 80,
) {
    vcsrepo { 'gitlab':
        ensure      => present,
        path        => '/home/git/gitlab',
        provider    => git,
        source      => 'https://github.com/gitlabhq/gitlabhq.git',
        revision    => '5-3-stable',
        owner       => 'git',
        group       => 'git',
        require     => User['git'],
    }

    file { 'gitlab.yml':
        path        => '/home/git/gitlab/config/gitlab.yml',
        ensure      => file,
        owner       => 'git',
        group       => 'git',
        content     => template('gitlab/gitlab.yml.erb'),
        notify      => Service['gitlab'],
    }

    file { 'database.yml':
        path        => '/home/git/gitlab/config/database.yml',
        ensure      => file,
        owner       => 'git',
        group       => 'git',
        content     => template('gitlab/database.yml.erb'),
    }

    if $db_type == 'mysql' {
        if !defined(Package['mysql-devel']) {
            package {'mysql-devel':
                ensure  => installed,
            }
        }
        if !defined(Package['mysql']) {
            package {'mysql':
                ensure  => installed,
            }
        }
    }else{
        include postgresql
        include postgresql::client
        include postgresql::devel
    }

    if !defined(Package['libicu-devel']) {
        package { 'libicu-devel':
            ensure      => installed,
        }
    }

    package { 'charlock_holmes':
        ensure      => installed,
        provider    => gem,
        require     => [
            Package['libicu-devel'],
            Class['gitlab::ruby'],
        ]
    }
    #Quick Fix to bundle the right requirements
    if $db_type == 'mysql' {
        $db_require = 'mysql-devel'
        $db_without = 'postgres'
    }
    else{
        $db_require = 'postgresql-devel'
        $db_without = 'mysql'
    }
    # TODO: Need to install bundler using the gem from the rvm install of ruby.
    # Currently have to log in as root and do gem install bundler.
    # TODO: Remove rvm paths so that this works when ruby version changes
    exec { 'bundle-install':
        command     => "/usr/local/rvm/gems/ruby-1.9.3-p392@global/bin/bundle install --deployment --without development test ${db_without}",
        cwd         => '/home/git/gitlab',
        user        => 'git',
        require     => [
            Class['gitlab::ruby'],
            Vcsrepo['gitlab'],
            Package['charlock_holmes'],
            Package[$db_require],
            File['gitlab.yml'],
        ],
        path        => '/usr/local/rvm/gems/ruby-1.9.3-p392/bin:/usr/local/rvm/gems/ruby-1.9.3-p392@global/bin:/usr/local/rvm/rubies/ruby-1.9.3-p392/bin:/usr/local/rvm/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin',
        logoutput   => on_failure,
        creates     => '/home/git/gitlab/.bundle/config',
    }

    # TODO: This script requires input to confirm db setup. Currently have to
    # manually edit /home/gitlab/gitlab/lib/tasks/setup.rake to remove it.
    # Then you have to delete database.yml so that this is re-run.
    exec { 'gitlab:setup':
        command     => '/usr/local/rvm/gems/ruby-1.9.3-p392@global/bin/bundle exec rake gitlab:setup RAILS_ENV=production',
        cwd         => '/home/git/gitlab',
        user        => 'git',
        refreshonly => true,
        subscribe   => File['database.yml'],
        path        => '/usr/local/rvm/gems/ruby-1.9.3-p392/bin:/usr/local/rvm/gems/ruby-1.9.3-p392@global/bin:/usr/local/rvm/rubies/ruby-1.9.3-p392/bin:/usr/local/rvm/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin',
        logoutput   => on_failure,
        require     => [
            User['git'],
            Class['gitlab::ruby'],
            Vcsrepo['gitlab'],
            Exec['bundle-install'],
        ],
    }

    file { 'unicorn.rb':
        path        => '/home/git/gitlab/config/unicorn.rb',
        ensure      => file,
        owner       => git,
        group       => git,
        source      => '/home/git/gitlab/config/unicorn.rb.example',
        require     => [
            User['git'],
            Vcsrepo['gitlab'],
        ],
    }

    file { 'gitlab-init':
        path        => '/etc/init.d/gitlab',
        ensure      => file,
        owner       => 'root',
        group       => 'root',
        mode        => 0755,
        source      => 'puppet:///modules/gitlab/gitlab-init',
    }

    service { 'gitlab':
        ensure  => running,
        enable  => true,
        require => [
            File['gitlab-init'],
            Exec['gitlab:setup'],
        ]
    }
}
