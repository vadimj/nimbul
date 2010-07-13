#!/bin/bash

echo "Non-generic ugly script to update Flock from SVN..."

cd /var/nyt/www/console
./stop

cd /root/roles/console
role.sh unlink console
svn up --password $SVNPASS
role.sh relink console

cd /var/nyt/www/console
rake db:migrate
./start

tail -f log/*.log

exit 0
