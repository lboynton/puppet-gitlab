# Install gitlab
class gitlab (
    $db_server   = 'localhost',
    $db_type     = 'mysql', #choose mysql or postgresql
    $db_name     = 'gitlab',
    $db_username = 'gitlab',
    $db_password = 'gitlab',
    $vhost       = $fqdn,
    $port        = 80,
) {
    Class['gitlab::deps']   -> Class['gitlab::shell']
    Class['gitlab::users']  -> Class['gitlab::shell']
    Class['gitlab::gitlab'] -> Class['gitlab::nginx']

    include epel
    include ::nginx
    include gitlab::deps
    include gitlab::users
    include gitlab::ruby
    include gitlab::redis
    include gitlab::shell

    class    { 'gitlab::nginx':
        vhost => $vhost,
    }

    if( $db_server == 'localhost' or $db_server == '127.0.0.1'){
        class { 'gitlab::db':
            db_type     => $db_type,
            db_server   => $db_server,
            db_name     => $db_name,
            db_username => $db_username,
            db_password => $db_password,
        }
    }

    class { 'gitlab::gitlab':
        db_type     => $db_type,
        db_name     => $db_name,
        db_server   => $db_server,
        db_username => $db_username,
        db_password => $db_password,
        vhost       => $vhost,
        port        => $port,
        require     => [
            Class['gitlab::users'],
            Class['gitlab::shell'],
        ]
    }
}
