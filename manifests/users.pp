class gitlab::users {
    user { 'gitlab':
        ensure      => present,
        comment     => 'GitLab CI',
        system      => true,
        managehome  => true,
    }
    user { 'git':
        ensure      => present,
        comment     => 'Git Version Control',
        system      => true,
        managehome  => true,
    }
}