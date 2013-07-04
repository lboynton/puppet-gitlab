class gitlab::users {
    user { 'git':
        ensure      => present,
        comment     => 'Git Version Control',
        system      => true,
        managehome  => true,
    }
    exec { '/usr/bin/ssh-keygen -q -N "" -t rsa -f /home/git/.ssh/id_rsa':
        user        => 'git',
        creates     => '/home/git/.ssh/id_rsa',
        require     => User['git'],
        logoutput   => on_failure,
    }
    file { '/home/git/.gitconfig':
        ensure      => file,
        owner       => 'git',
        group       => 'git',
        content     => template('git/gitconfig.erb'),
        require     => User['git'],
    }
    file { '/home/git':
        ensure          => directory,
        owner           => 'git',
        group           => 'git',
        mode            => 755,
        require         => User['git'],
    }
}