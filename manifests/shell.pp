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

    # todo: only run this once
    exec { 'rewrite-hooks':
        command     => '/home/git/gitlab-shell/support/rewrite-hooks.sh',
        cwd         => '/home/git',
        user        => 'git'
    }
}