#!/bin/bash

echo "Non-generic ugly script to update Nimbul from SVN..."

NIMBUL_HOME=$(dirname $0)

cd "${NIMBUL_HOME}"
./stop

cd /root/roles/nimbul
role.sh unlink nimbul
svn up --password $SVNPASS
role.sh relink nimbul

cd "${NIMBUL_HOME}"
rake db:migrate
./start

tail -f log/*.log

exit 0
