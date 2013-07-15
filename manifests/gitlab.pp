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

    # todo: only run once
    exec { 'install-charlock_holmes':
        command     => 'gem install charlock_holmes',
        environment => 'LD_LIBRARY_PATH=/opt/rh/ruby193/root/usr/lib64',
        path        => '/opt/rh/ruby193/root/usr/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin',
        logoutput   => on_failure,
        require     => [
            Package['libicu-devel'],
            Package['patch'],
            Package['libxml2-devel'],
            Class['gitlab::ruby'],
            Vcsrepo['gitlab'],
        ],
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

    exec { 'bundle-install':
        command     => "bundle install --deployment --without development test ${db_without}",
        cwd         => '/home/git/gitlab',
        environment => 'LD_LIBRARY_PATH=/opt/rh/ruby193/root/usr/lib64',
        user        => 'git',
        require     => [
            Class['gitlab::ruby'],
            Vcsrepo['gitlab'],
            Exec['install-charlock_holmes'],
            Package[$db_require],
            File['gitlab.yml'],
        ],
        path        => '/opt/rh/ruby193/root/usr/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin',
        logoutput   => on_failure,
        creates     => '/home/git/gitlab/.bundle/config',
    }

    exec { 'gitlab:setup':
        command     => 'bundle exec rake gitlab:setup RAILS_ENV=production',
        cwd         => '/home/git/gitlab',
        environment => [
            'force=yes',
            'LD_LIBRARY_PATH=/opt/rh/ruby193/root/usr/lib64',
        ],
        user        => 'git',
        refreshonly => true,
        subscribe   => File['database.yml'],
        path        => '/opt/rh/ruby193/root/usr/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin',
        logoutput   => on_failure,
        require     => [
            User['git'],
            Class['gitlab::ruby'],
            Vcsrepo['gitlab'],
            Exec['bundle-install']
        ],
    }

    file { 'puma.rb':
        path        => '/home/git/gitlab/config/puma.rb',
        ensure      => file,
        owner       => git,
        group       => git,
        source      => '/home/git/gitlab/config/puma.rb.example',
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

    file { '/home/git/gitlab/tmp/sockets':
        ensure      => directory,
        owner       => 'git',
        group       => 'git',
        mode        => 0755,
        require     => Vcsrepo['gitlab'],
    }

    file { '/home/git/gitlab/public/uploads':
        ensure      => directory,
        owner       => 'git',
        group       => 'git',
        mode        => 0755,
        require     => Vcsrepo['gitlab'],
    }

    file { '/home/git/gitlab-satellites':
        ensure      => directory,
        owner       => 'git',
        group       => 'git',
        mode        => 0755,
        before      => Service['gitlab'],
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
