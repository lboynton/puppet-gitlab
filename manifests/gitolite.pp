class gitlab::gitolite {
    package { 'perl-Time-HiRes':
        ensure  => installed,
    }

    vcsrepo { 'gitolite':
        ensure      => present,
        path        => '/home/git/gitolite',
        provider    => git,
        source      => 'https://github.com/gitlabhq/gitolite.git',
        revision    => 'gl-v320',
        owner       => 'git',
        group       => 'git',
        require     => User['git'],
    }

    file { '/home/git/bin':
        ensure      => directory,
        owner       => 'git',
        group       => 'git',
        require     => User['git'],
    }
    
    exec { 'install-gitolite':
        command     => '/home/git/gitolite/install -ln /home/git/bin',
        creates     => '/home/git/bin/gitolite',
        user        => 'git',
        require     => [Vcsrepo['gitolite'], File['/home/git/bin']],
        logoutput   => on_failure,
    }

    file { '/home/git/gitlab.pub':
        ensure      => present,
        source      => '/home/gitlab/.ssh/id_rsa.pub',
        owner       => 'git',
        group       => 'git',
    }

    exec { 'set-up-gitolite':
        command     => '/bin/su git -c "/home/git/bin/gitolite setup -pk /home/git/gitlab.pub"',
        logoutput   => on_failure,
        require     => [Exec['install-gitolite'], File['/home/git/gitlab.pub']],
        creates     => '/home/git/projects.list',
    }
}