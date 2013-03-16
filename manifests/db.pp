class gitlab::db(
	$db_type     = 'mysql',
	$db_name,  
	$db_username,
	$db_password,
) {
	if ($db_type == 'mysql'){
		include mysql::server
		mysql::db { $db_name:
			user        => $db_username,
			password    => $db_password,
    	}
	}
	if ($db_type == 'postgresql'){
		include postgresql::server
		postgresql::db { $db_name:
			user        => $db_username,
			password    => $db_password,
		}
	}
}
