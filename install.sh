#!/bin/bash -e
#
# $Id$
#

if [ $UID -gt 0 -a $(uname | grep Darwin -c) -eq 0 ]; then
    echo 'You need to be root to run this script'
    exit 1
fi


if [ $(gem sources | grep gems.github.com -c) -eq 0 ]; then
	gem sources -a http://gems.github.com
fi

#yum -y install mysql-shared
gem install -v=2.2.2 rails
gem install gem_plugin
gem install mongrel
# gem install mongrel_cluster

gem install system_timer
gem install cached_model
gem install rubyist-aasm
gem install josevalim-rails-footnotes
gem install starling
gem install daemons
gem install ruby-openid

#gem install passenger
#passenger-install-apache2-module

gem install facter
gem install work_queue
gem install carrot 
gem install emissary

# messaging active messaging shows debugging output about 
# these not being loading - they are not optional and not 
# needed so don't worry about them.
#gem install beanstalk-client reliable-msg stomp rubywmq

# fixing incompatibility between latest json libraries and ActiveSupport in 2.2.2
# http://groups.google.com/group/rubyonrails-core/browse_thread/thread/54e5453eaac6687b
yes | gem uninstall json json_pure
yes | gem install json json_pure --version=1.2.0

echo "Enjoy"

exit 0
