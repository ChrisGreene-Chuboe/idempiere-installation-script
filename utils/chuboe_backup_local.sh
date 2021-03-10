#!/bin/bash

#Bring chuboe.properties into context
SCRIPTNAME=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPTNAME")
source $SCRIPTPATH/chuboe.properties

LOGFILE="$CHUBOE_PROP_LOG_PATH/chuboe_db_backup.log"
ADEMROOTDIR=$CHUBOE_PROP_IDEMPIERE_PATH
CHUBOE_UTIL=$CHUBOE_PROP_UTIL_PATH
CHUBOE_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH
LOCALBACKDIR=$CHUBOE_PROP_BACKUP_LOCAL_PATH
USER=$CHUBOE_PROP_DB_USERNAME
ADDPG="-h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT"
DATABASE=$CHUBOE_PROP_DB_NAME
IDEMPIEREUSER=$CHUBOE_PROP_IDEMPIERE_OS_USER
BACKUP_TAR="ExpDatDir_"`date +%Y%m%d`_`date +%H%M%S`".tar"
# You may update the number of cores used from default below
BACKUP_RESTORE_JOBS=$CHUBOE_PROP_BACKUP_RESTORE_JOBS

echo LOGFILE="$LOGFILE" >> "$LOGFILE"
echo ADEMROOTDIR="$ADEMROOTDIR" >> "$LOGFILE"

cd $LOCALBACKDIR
mkdir latest/
rm latest/*

pg_dump $ADDPG -vU $USER $DATABASE -Fd -j $BACKUP_RESTORE_JOBS -f latest

tar -cvf $BACKUP_TAR latest/*