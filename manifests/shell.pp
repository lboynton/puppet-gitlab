class gitlab::shell {
    vcsrepo { 'gitlab-shell':
        ensure      => present,
        path        => '/home/git/gitlab-shell',
        provider    => git,
        source      => 'https://github.com/gitlabhq/gitlab-shell.git',
        revision    => 'v1.5.0',
        owner       => 'git',
        group       => 'git',
        require     => User['git'],
    }

    file { 'config.yml':
        path        => '/home/git/gitlab-shell/config.yml',
        ensure      => file,
        owner       => 'git',
        group       => 'git',
        content     => template('gitlab/gitlab-shell.yml.erb'),
    }

    exec { 'install':
        command     => '/home/git/gitlab-shell/bin/install',
        creates     => '/home/git/repositories',
        cwd         => '/home/git/gitlab-shell',
        user        => 'git',
        require     => Vcsrepo['gitlab-shell']
    }
}