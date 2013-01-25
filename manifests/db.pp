class gitlab_ci::db(
	$db_username,
	$db_password,
) {
    include mysql::server

    mysql::db { 'gitlab':
        user        => $db_username,
        password    => $db_password,
    }
}