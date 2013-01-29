# Install gitlab
class gitlab (
    $db_username = 'gitlab',
    $db_password = 'gitlab',
) {
    if $::osfamily == 'RedHat' and $::operatingsystem != 'Fedora' {
        include epel
    }

    Class['gitlab::users'] -> Class['gitlab::gitolite']
    Class['gitlab::gitlab'] -> Class['gitlab::nginx']
    
    include gitlab::users
    include gitlab::ruby
    include gitlab::redis
    include gitlab::gitolite
    include gitlab::nginx

    class { 'gitlab::db':
        db_username => $db_username,
        db_password => $db_password,
    }

    class { 'gitlab::gitlab':
        db_username => $db_username,
        db_password => $db_password,
        require     => [
            Class['gitlab::users'],
            Class['gitlab::gitolite'],
        ]
    }
}