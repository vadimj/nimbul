#!/bin/bash -e
#
# $Id$
#

#
# settings
#
export uninstall_if_exists=(json json_pure)
export install_if_doesnt_exist=(gem_plugin mongrel system_timer cached_model rubyist-aasm\
 josevalim-rails-footnotes starling daemons ruby-openid facter work_queue carrot emissary)
export rails_ver='2.2.2'
export install_flags="--no-ri --no-rdoc"
export json_ver='1.2.0'
export search_mysql_dirs=(/opt/local/lib/mysql5 /usr/local/mysql)
export sysvipc_gem_ver='0.7'

#
# make sure we are root
#
if [ $UID -gt 0 -a $(uname | grep Darwin -c) -eq 0 ]; then
    echo 'You need to be root to run this script'
    exit 1
fi

#
# get github gems (for emissary)
#
if [ $(gem sources | grep gems.github.com -c) -eq 0 ]; then
    gem sources -a http://gems.github.com
fi

# update ruby gems
gem update --system

echo "Installing rails ${rails_ver}"
gem install -v=${rails_ver} rails $install_flags

for lib in ${uninstall_if_exists[@]}; do
  count=`gem list --local $lib | awk {'print $1'} | egrep ^$lib$ -c`
  if [ $count -ge 1 ]; then
    echo "Uninstalling $lib"
    yes | gem uninstall $lib
  fi
done

for lib in ${install_if_doesnt_exist[@]}; do
  count=`gem list --local $lib | awk {'print $1'} | egrep ^$lib$ -c`
  if [ $count -le 0 ]; then
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

lib=mysql
if [ $(uname | grep Darwin -c) -eq 1 -a $(gem list --local $lib | awk {'print $1'} | egrep ^$lib$ -c) -le 0 ]; then
    mysql_dir=''
    mysql_config=''
    for m_dir in ${search_mysql_dirs[@]}; do
        m_config=${m_dir}/bin/mysql_config
        echo -n "Trying ${m_config}..."
        if [ -x ${m_config} ]; then
            echo " success"
            mysql_dir=${m_dir}
            mysql_config=${m_config}
        else
            echo ""
        fi
    done
    if [ -z ${mysql_dir} ]; then
        echo "Couldn't find mysql in ${search_mysql_dirs[@]}"
        echo "Error: mysql gem is not installed"
        exit 1
    else
        echo "Found mysql_config in ${mysql_config}"
        echo "Installing mysql gem with --with-mysql-dir=${mysql_dir} --with-mysql-config=${mysql_config}"
        export ARCHFLAGS="-arch i386 -arch x86_64" ; yes | gem install mysql --no-rdoc --no-ri \
            -- --with-mysql-dir=${mysql_dir} --with-mysql-config=${mysql_config}
    fi
fi

echo "Installing sysvipc version ${sysvipc_gem_ver} (later version won't work)"
mkdir -p /tmp
cd /tmp
rm -rf sysvipc-${sysvipc_gem_ver}*
wget --tries=5 http://rubyforge.org/frs/download.php/23172/sysvipc-${sysvipc_gem_ver}.tar.gz
tar xzvf sysvipc-${sysvipc_gem_ver}.tar.gz
cd sysvipc-${sysvipc_gem_ver}
ruby extconf.rb
if [ $(uname | grep Darwin -c) -eq 1 ]; then
    echo "Patching Makefile to avoid weird 'error: redefinition of 'union semun'' issue"
    perl -pi -e 's/^CPPFLAGS(.*)$/CPPFLAGS$1 -DHAVE_TYPE_UNION_SEMUN/g;' Makefile
fi
make ; make install
cd /tmp
rm -rf sysvipc-${sysvipc_gem_ver}*

echo "Enjoy"

exit 0
