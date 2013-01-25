class gitlab_ci::redis {
    package { 'redis':
        ensure  => installed,
    }

    service { 'redis':
        ensure  => running,
        enable  => true,
    }
}