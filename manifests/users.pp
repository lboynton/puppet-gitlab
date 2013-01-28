class gitlab::users {
    user { 'gitlab':
        ensure      => present,
        comment     => 'GitLab CI',
        groups      => 'git',
        require     => User['git'],
        system      => true,
        managehome  => true,
    }
    user { 'git':
        ensure      => present,
        comment     => 'Git Version Control',
        system      => true,
        managehome  => true,
    }
    exec { '/usr/bin/ssh-keygen -q -N "" -t rsa -f /home/gitlab/.ssh/id_rsa':
        user        => 'gitlab',
        creates     => '/home/gitlab/.ssh/id_rsa',
        require     => User['gitlab'],
        logoutput   => on_failure,
    }
    file { '/home/gitlab/.gitconfig':
        ensure      => file,
        owner       => 'gitlab',
        group       => 'gitlab',
        content     => template('gitlab/gitconfig.erb'),
    }
}