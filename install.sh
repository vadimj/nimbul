#!/bin/bash -e
#
# $Id$
#

export uninstall_if_exists=(json json_pure)

export install_if_doesnt_exist=(gem_plugin mongrel system_timer cached_model rubyist-aasm\
 josevalim-rails-footnotes starling daemons ruby-openid facter work_queue carrot emissary)

export install_flags="--no-ri --no-rdoc"

export json_ver="1.2.0"

if [ $UID -gt 0 -a $(uname | grep Darwin -c) -eq 0 ]; then
    echo 'You need to be root to run this script'
    exit 1
fi


if [ $(gem sources | grep gems.github.com -c) -eq 0 ]; then
	gem sources -a http://gems.github.com
fi

gem update --system
gem install -v=2.2.2 rails $install_flags

for lib in ${uninstall_if_exists[@]}; do
  if [ X$(gem list --local $lib | grep $lib | awk {'print $1'}) == X$lib ]; then
    echo "Uninstalling $lib"
    yes | gem uninstall $lib
  fi
done

for lib in ${install_if_doesnt_exist[@]}; do
  if [ $(gem list --local $lib | grep $lib -c) -le 0 ]; then
    echo "Adding missing required library '${lib}' to list of gems to install"
    install_list="$lib ${install_list}"
  fi
done

echo "Installing required libraries"
if [ ! -z "$install_list" ]; then
  yes | gem install $install_list $install_flags
fi

echo "Installing version $json_ver of json and json_pure libraries" 
yes | gem install json json_pure --version=$json_ver $install_flags

echo "Enjoy"

exit 0
