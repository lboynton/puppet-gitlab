# Install gitlab
class gitlab (
    $db_username = 'gitlab',
    $db_password = 'gitlab',
) {
    if $::osfamily == 'RedHat' and $::operatingsystem != 'Fedora' {
        include epel
    }

    Class['gitlab::users'] -> Class['gitlab::gitolite']
    
    include nginx
    include gitlab::users
    include gitlab::ruby
    include gitlab::redis
    include gitlab::gitolite

    class { 'gitlab::db':
        db_username => $db_username,
        db_password => $db_password,
    }

    class { 'gitlab::gitlab':
        db_username => $db_username,
        db_password => $db_password,
    }
}