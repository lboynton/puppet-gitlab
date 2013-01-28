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
}