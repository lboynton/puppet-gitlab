class gitlab::ruby{
    yumrepo { 'ruby-scl':
        baseurl        => "http://people.redhat.com/bkabrda/ruby193-rhel-6/",
        failovermethod => 'priority',
        enabled        => '1',
        gpgcheck       => '0',
        descr          => "Ruby 1.9.3 Dynamic Software Collection"
    }

    package {['ruby193', 'ruby193-ruby-devel']:
        ensure => installed,
        require => Yumrepo['ruby-scl'],
    }
}
