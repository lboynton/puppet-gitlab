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

    file { 'gitlab.yml':
        path        => '/home/gitlab/gitlab/config/gitlab.yml',
        ensure      => file,
        owner       => 'gitlab',
        group       => 'gitlab',
        content     => template('gitlab/gitlab.yml.erb'),
    }

    file { 'database.yml':
        path        => '/home/gitlab/gitlab/config/database.yml',
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
        require     => [
            Package['libicu-devel'],
            Class['gitlab::ruby'], 
        ]
    }

    # TODO: Need to install bundler using the gem from the rvm install of ruby.
    # Currently have to log in as root and do gem install bundler.
    # TODO: Remove rvm paths so that this works when ruby version changes
    exec { 'bundle-install':
        command     => '/usr/local/rvm/gems/ruby-1.9.3-p374@global/bin/bundle install --deployment --without development test postgres',
        cwd         => '/home/gitlab/gitlab',
        user        => 'gitlab',
        require     => [
            Class['gitlab::ruby'], 
            Vcsrepo['gitlab'], 
            Package['charlock_holmes'], 
            Package['mysql-devel'],
            File['gitlab.yml'],
        ],
        path        => '/usr/local/rvm/gems/ruby-1.9.3-p374/bin:/usr/local/rvm/gems/ruby-1.9.3-p374@global/bin:/usr/local/rvm/rubies/ruby-1.9.3-p374/bin:/usr/local/rvm/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin',
        logoutput   => on_failure,
        creates     => '/home/gitlab/gitlab/.bundle/config',
    }

    file { '/home/git/.gitolite/hooks/common/post-receive':
        ensure      => file,
        owner       => 'git',
        group       => 'git',
        source      => '/home/gitlab/gitlab/lib/hooks/post-receive',
        require     => [
            User['git'],
            Vcsrepo['gitlab'],
        ],
    }

    # TODO: This script requires input to confirm db setup. Currently have to 
    # manually edit /home/gitlab/gitlab/lib/tasks/setup.rake to remove it.
    # Then you have to delete database.yml so that this is re-run.
    exec { 'gitlab:setup':
        command     => '/usr/local/rvm/gems/ruby-1.9.3-p374@global/bin/bundle exec rake gitlab:setup RAILS_ENV=production',
        cwd         => '/home/gitlab/gitlab',
        user        => 'gitlab',
        refreshonly => true,
        subscribe   => File['database.yml'],
        path        => '/usr/local/rvm/gems/ruby-1.9.3-p374/bin:/usr/local/rvm/gems/ruby-1.9.3-p374@global/bin:/usr/local/rvm/rubies/ruby-1.9.3-p374/bin:/usr/local/rvm/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin',
        logoutput   => on_failure,
        require     => [
            User['gitlab'],
            Class['gitlab::ruby'], 
            Vcsrepo['gitlab'],
            Exec['bundle-install'],
        ],
    }

    file { 'unicorn.rb':
        path        => '/home/gitlab/gitlab/config/unicorn.rb',
        ensure      => file,
        owner       => gitlab,
        group       => gitlab,
        source      => '/home/gitlab/gitlab/config/unicorn.rb.example',
        require     => [
            User['gitlab'],
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