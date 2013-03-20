class gitlab::ruby{
    include rvm

    rvm_system_ruby { 'ruby-1.9.3':
        ensure      => 'present',
        default_use => true,
    }

    rvm_gem { 'ruby-1.9.3/bundler': 
        ensure      => present,
        require     => Rvm_system_ruby['ruby-1.9.3'],
    }

    rvm::system_user { gitlab: }
}
