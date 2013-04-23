class gitlab::db(
    $db_type     = 'mysql',
    $db_server,
    $db_name,
    $db_username,
    $db_password,
) {
    if ($db_type == 'mysql'){
        if( $db_server == 'localhost' or $db_server == '127.0.0.1'){
            include mysql::server
        }
        mysql::db { $db_name:
            user        => $db_username,
            password    => $db_password,
        }
    }
    if ($db_type == 'postgresql'){
        if( $db_server == 'localhost' or $db_server == '127.0.0.1'){
            include postgresql::server
        }
        postgresql::db { $db_name:
            user        => $db_username,
            password    => $db_password,
        }
    }
}
