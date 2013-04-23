include gitlab

package { 'vim-enhanced':
    ensure => installed,
}

service { 'iptables':
    ensure  => stopped,
    enable  => false,
}