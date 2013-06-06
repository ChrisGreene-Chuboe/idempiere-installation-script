#!/bin/bash

# Author Chuck Boecking
# aws_idempiere_install_script_master.sh
# 1.0 initial release

usage()
{
cat << EOF

usage: $0

This script helps you launch the approapriate
iDempiere components on a given server

OPTIONS:
	-h	Help
	-s	Prevent this server from running
		services like accounting and workflow
		(not implemented yet)
	-p 	No install postgresql - provide the
		IP for the postgresql server
	-e	Move the postgresql files
		to EBS - provide the drive name
	-i	No install iDempiere (DB only)
	-b	Name of s3 bucket for backups (not implemented yet)
	-P	DB password
	-l	launch iDempiere with nohup

EOF
}

#initialize variables
IS_INSTALL_DB="Y"
IS_INSTALL_SERVICE="Y"
IS_MOVE_DB="N"
IS_INSTALL_ID="Y"
IS_LAUNCH_ID="N"
PIP="localhost"
DEVNAME="NONE"
DBPASS="NONE"


while getopts "hsp:e:ib:P:l" OPTION
do
	case $OPTION in
		h)	usage
			exit 1;;

		s)	#no install services like accounting and workflow
			IS_INSTALL_SERVICE="N"
			echo "NOTE: -s option Not implemented yet!!";;

		p)	#no install postgresql
			IS_INSTALL_DB="N"
			PIP=$OPTARG;;

		e)	#move DB
			IS_MOVE_DB="Y"
			DEVNAME=$OPTARG;;

		i)	#no install iDempiere
			IS_INSTALL_ID="N";;

		b)	#specify s3 bucket for backup
			echo "NOTE: -b option not implemented yet!!";;

		P)	#database password
			DBPASS=$OPTARG;;

		l)	#launch iDempiere
			IS_LAUNCH_ID="Y";;
	esac
done

echo "Install DB=" $IS_INSTALL_DB
echo "Move DB="$IS_MOVE_DB
echo "Install iDempiere="$IS_INSTALL_ID
echo "Install iDempiere Services="$IS_INSTALL_SERVICE
echo "Database IP="$PIP
echo "MoveDB Device Name="$DEVNAME
echo "DB Password="$DBPASS
echo "Launch iDempiere with nohup"=$IS_LAUNCH_ID

#Check error conditions
if [[ $DBPASS == "NONE" && $IS_INSTALL_DB == "Y"  ]]
then
	echo "Must set DB Password if installing DB!!"
	exit 1
fi

sudo apt-get --yes update
sudo apt-get --yes install unzip htop

if [[ $IS_INSTALL_DB == "Y" ]]
then
      echo "Installing DB because IS_INSTALL_DB == Y"
	  sudo apt-get --yes install postgresql postgresql-contrib phppgadmin
	  sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '"$DBPASS"';"
	  #ACTION - need to open up DB to outside world
	  #ACTION - need to configure phppgadmin to run on a specific port and make sure it is running when this script completes
fi #end if IS_INSTALL_DB==Y


if [[ $IS_MOVE_DB == "Y" ]]
then
	echo "Moving DB because IS_MOVE_DB == Y"
	sudo apt-get update
	sudo updatedb
	sudo apt-get install -y xfsprogs
	#sudo apt-get install -y postgresql #uncomment if you need the script to install the db
	sudo mkfs.ext4 /dev/$DEVNAME
	echo "/dev/"$DEVNAME" /vol ext4 noatime 0 0" | sudo tee -a /etc/fstab
	sudo mkdir -m 000 /vol
	sudo mount /vol

	sudo -u postgres service postgresql stop

	#map the data direcory
	sudo mkdir /vol/var
	sudo mv /var/lib/postgresql/9.1/main /vol/var
	sudo mkdir /var/lib/postgresql/9.1/main
	echo "/vol/var/main /var/lib/postgresql/9.1/main     none bind" | sudo tee -a /etc/fstab
	sudo mount /var/lib/postgresql/9.1/main

	#map the conf directory
	sudo mkdir /vol/etc
	sudo mv /etc/postgresql/9.1/main /vol/etc
	sudo mkdir /etc/postgresql/9.1/main
	echo "/vol/etc/main /etc/postgresql/9.1/main     none bind" | sudo tee -a /etc/fstab
	sudo mount /etc/postgresql/9.1/main

	sudo -u postgres service postgresql start

fi #end if IS_MOVE_DB==Y

if [[ $IS_INSTALL_ID == "Y" ]]
then
	echo "Installing iDemipere because IS_INSTALL_ID == Y"
	sudo apt-get --yes install openjdk-6-jdk
	mkdir /home/ubuntu/installer_`date +%Y%m%d`
	wget http://jenkins.idempiere.com/job/iDempiereDaily/ws/buckminster.output/org.adempiere.server_1.0.0-eclipse.feature/idempiereServer.gtk.linux.x86_64.zip -P /home/ubuntu/installer_`date +%Y%m%d`
	unzip /home/ubuntu/installer_`date +%Y%m%d`/idempiereServer.gtk.linux.x86_64.zip -d /home/ubuntu/installer_`date +%Y%m%d`
	cd /home/ubuntu/installer_`date +%Y%m%d`/idempiere.gtk.linux.x86_64/idempiere-server/

#not indented because of file input
sh console-setup.sh <<!













2
$PIP




$DBPASS
mail.dummy.com




!
cd utils; sh RUN_ImportIdempiere.sh <<!

!
#end of file input

fi #end if $IS_INSTALL_ID == "Y"

if [[ $IS_LAUNCH_ID == "Y" ]]
then
	echo "launching iDempiere with nohup"
	cd /home/ubuntu/installer_`date +%Y%m%d`/idempiere.gtk.linux.x86_64/idempiere-server/; nohup ./idempiere-server.sh &
fi
