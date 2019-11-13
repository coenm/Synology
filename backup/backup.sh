#!/bin/bash

# ! /bin/sh


#***************************************************************
VERSION="2019.11.11"

DATETIME_START="$(date +"%Y.%m.%d-%H.%M.%S")"

RSYNC_DEFAULT_OPTIONS='--hard-links --delete --delete-excluded --archive --chmod=oga-w'

# Get absolute path this script is in and use this path as a base for all other (relatve) filenames.
# !! Please make sure there are no spaces inside the path !!
# Source: https://stackoverflow.com/questions/242538/unix-shell-script-find-out-which-directory-the-script-file-resides
# 2017-12-07
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

# not sure if it should end with /
CONFIG_DIR=config

echo $SCRIPTPATH
echo $CONFIG_DIR


#***************************************************************
# Functions  
#***************************************************************

print_header()
{
	echo ""
	echo ""
	echo "#################################################"
	echo "#   $0 - version $VERSION" 
	echo "#################################################"
	echo ""
}


print_help()
{
	echo "Usage:																	"
	echo "																			"
	echo "	$0 -n name [-H <host> -I <identity file> [-P <port>]] [-c -p -v -q -h]	"
	echo "																			"
	echo "	-h = Help																"
	echo "       List this help menu												"
	echo "																			"
	echo "	-n = Name of the backup (used as root folder in backup destination).    "
	echo "																			"
	echo "	-c = Checksum mode														"
	echo "       Forces sender to checksum all files before transfer.				"
	echo "       Can be quite slow.													"
	echo "																			"
	echo "	-v = Verbose mode														"
	echo "       Run rsync command with the -v switch to use verbose output			"
	echo "																			"
	echo "	-p = Progress mode														"
	echo "       Run rsync command with the -p switch to show the progress			"
	echo "																			"
	echo "	-q = Quiet mode															"
	echo "       Run rsync command with -q switch to suppress all output			"
	echo "       except errors														"
	echo "																			"
	echo "	-H = Host name (for remote backup)										"
	echo "       Hostname of remote machine. Can be IP4 or hostname.		     	"
	echo "																			"
	echo "	-P = SSH Port (for remote backup)										"
	echo "       Destination SSH port of the remote machine (default 22).	     	"
	echo "																			"
	echo "	-I = Identity file (for remote backup)									"
	echo "       RSA or EC private key.                                  	     	"
	echo "																			"
	echo "----------------------------------------------------------------------------"
# . Normally SSH runs on port 22 but this property allows others.
}

CONFIG_LOG_DIR_BUSY=/logs/busy
CONFIG_LOG_DIR_FINISHED=/logs

mkdir -p $CONFIG_LOG_DIR_BUSY
mkdir -p $CONFIG_LOG_DIR_FINISHED

# https://stackoverflow.com/questions/9612090/how-to-loop-through-file-names-returned-by-find
# find /config -name "exclude_*.config"
for i in $(find /config -name "exclude_*.config"); do
    echo "Found exclude file: $i"
	RSYNC_EXCLUDE_FILES_ARRAY+=( --exclude-from "$i" )
done

RSYNC_EXCLUDE_FILES=${RSYNC_EXCLUDE_FILES_ARRAY[@]}
echo RSYNC_EXCLUDE_FILES: ${RSYNC_EXCLUDE_FILES}

#Wrapping up the excludes
RSYNC_EXCLUDES="$RSYNC_EXCLUDE_FILES"

opt_cap_p=22

#***************************************************************
# Get Options from the command line  
#***************************************************************
while getopts "n:H:P:I:hcvpq" options
do
	case $options in 
		c ) RSYNC_MODE_CHECKSUM='--checksum ';;
		v ) RSYNC_MODE_VERBOSE='--verbose ';;
		q ) RSYNC_MODE_QUIET='--quiet ';;
		p ) RSYNC_MODE_PROGRESS='--progress ';;	
		
		n ) opt_n=$OPTARG;;

		H ) 
		    opt_cap_h=$OPTARG
		    DO_REMOTE=1
		    ;;
		P ) opt_cap_p=$OPTARG;;
		I ) opt_cap_i=$OPTARG;;

		h ) opt_h=1;;
		* ) opt_h=1;;
	esac
done


 
#***************************************************************
# Print Help 
#***************************************************************
if [ $opt_h ]; then
	print_header
	print_help
	exit 1
fi 


# Destination base directory to store the backup.
# Should be an absolute path. If the backup is on a remote machine. Do not enter a path like user@host:/path/to/store/backup
BACKUP_DIR=/backup

#***************************************************************
# Name of backup
#***************************************************************
if [ ! -z $opt_n ]; then

	BACKUP_NAME=$opt_n
	echo "-- BACKUP_NAME: ${BACKUP_NAME}"

else

	print_header
	echo [ERROR] Backup name -n is empty
	echo
	print_help	
	exit 1

fi

# Backup directory. Must be absolute path. Directory must exists and the executing user of the script should have read rights.
BACKUP_SOURCE_DIR=/source	

## Create the destination path (also the escaped variant)
DESTINATION_DIR=${BACKUP_DIR}/${BACKUP_NAME}
DESTINATION_DIR_ESCAPED=${DESTINATION_DIR// /\\ }

echo "-- DESTINATION_DIR: ${DESTINATION_DIR}"
echo "-- DESTINATION_DIR_ESCAPED: ${DESTINATION_DIR_ESCAPED}"


#***************************************************************
# Misc
#***************************************************************

# Construct logfiles
LOG_FILE=${DATETIME_START}_${opt_d}_${opt_s}.log
LOG_FILE_BUSY=${CONFIG_LOG_DIR_BUSY}/${LOG_FILE}
LOG_FILE_FINISHED=${CONFIG_LOG_DIR_FINISHED}/${LOG_FILE}
LOG_FILE=


#Check if source exists
if [ ! -d "$BACKUP_SOURCE_DIR" ]; then
	print_header
	echo [ERROR] $BACKUP_SOURCE_DIR does not exist.
	exit 1
fi


#***************************************************************
# Run the real backup
#***************************************************************
echo Started at $DATETIME_START using backupscript $VERSION >> ${LOG_FILE_BUSY}

echo "-- DO_REMOTE: ${DO_REMOTE}"
echo "-- opt_cap_h: ${opt_cap_h}"
echo "-- opt_cap_p: ${opt_cap_p}"
echo "-- opt_cap_i: ${opt_cap_i}"

if [ $DO_REMOTE -eq 1 ]; then

	DEST_HOST=${opt_cap_h}

	DEST_PORT=${opt_cap_p}
	SSH_PORT='-p '$DEST_PORT	

	# Check if private key file exists. If not -> quit backup.
	DEST_KEYFILE=${opt_cap_i}
	if [ -z $DEST_KEYFILE ]; then
		echo [ERROR] Private key not set.
		echo
		print_help
		exit 1
	fi
	
	if [ ! -f ${DEST_KEYFILE} ]; then
		echo [ERROR] Cannot backup to remote because the private key ${DEST_KEYFILE} does not exist.
		echo
		print_help
		exit 1
	fi

    # copy the private key to other directory
	# make sure the permissions are okay and use that key.
	mkdir -p /root/backupscript/
	cp ${DEST_KEYFILE} root/backupscript/id_ed25519
	DEST_KEYFILE=root/backupscript/id_ed25519
	chown root:root ${DEST_KEYFILE}
	chmod 600 ${DEST_KEYFILE}
   
	SSH_KEY='-i '${DEST_KEYFILE}		
	echo "-- SSH_KEY: ${SSH_KEY}"
			
	echo Start remote backup >> ${LOG_FILE_BUSY}
	echo >> ${LOG_FILE_BUSY}

	echo Create working dir for backup >> ${LOG_FILE_BUSY}
	
	# Remote username. This user should exist on the remote machine, should have SSH access with public key authorization enabled.
	DEST_USER=$SSH_USERNAME

	echo "-- SSH_PORT: ${SSH_PORT}"
	echo "-- DEST_USER: ${DEST_USER}"
	echo "-- DEST_HOST: ${DEST_HOST}"

	ssh \
		"-o StrictHostKeyChecking=false " $SSH_PORT $SSH_KEY ${DEST_USER}@${DEST_HOST} \
		"mkdir -p \"$DESTINATION_DIR/incomplete/\" && mkdir -p \"$DESTINATION_DIR/partial/\""

	echo >> ${LOG_FILE_BUSY}
	
	echo Start RSync >> ${LOG_FILE_BUSY}
	echo >> ${LOG_FILE_BUSY}
	echo DESTINATION_DIR_ESCAPED: ${DESTINATION_DIR_ESCAPED} >> ${LOG_FILE_BUSY}
	
	rsync \
		$RSYNC_MODE_CHECKSUM \
		$RSYNC_MODE_VERBOSE \
		$RSYNC_MODE_PROGRESS \
		$RSYNC_MODE_QUIET \
		${RSYNC_DEFAULT_OPTIONS} \
		${RSYNC_EXCLUDES} \
		-e 'ssh -o StrictHostKeyChecking=false -p '${DEST_PORT}' -i'${DEST_KEYFILE} \
		--link-dest="${DESTINATION_DIR_ESCAPED}/current"  \
		"${BACKUP_SOURCE_DIR}" \
		${DEST_USER}@${DEST_HOST}:"${DESTINATION_DIR_ESCAPED}/incomplete/" >> ${LOG_FILE_BUSY} 2>&1
		
		
	echo >> ${LOG_FILE_BUSY}
	
	echo wrapping up... >> ${LOG_FILE_BUSY}
	echo >> ${LOG_FILE_BUSY}
	
	ssh \
		"-o StrictHostKeyChecking=false " $SSH_PORT $SSH_KEY ${DEST_USER}@${DEST_HOST} \
		"cd \"$DESTINATION_DIR\" && mv incomplete/ $DATETIME_START/ && rm -rf current && ln -s $DATETIME_START current && rm -rf partial"


	rm -rf ${DEST_KEYFILE}
	
else

	echo start local backup >> ${LOG_FILE_BUSY}
	echo >> ${LOG_FILE_BUSY}
	
	echo Create working dir for backup >> ${LOG_FILE_BUSY}
	
	mkdir -p "${DESTINATION_DIR}/current"
	mkdir -p "${DESTINATION_DIR}/incomplete/"
	mkdir -p "${DESTINATION_DIR}/partial/"

	echo

	echo Start RSync >> ${LOG_FILE_BUSY}
	echo >> ${LOG_FILE_BUSY}
	
	rsync \
		$RSYNC_MODE_CHECKSUM \
		$RSYNC_MODE_VERBOSE \
		$RSYNC_MODE_PROGRESS \
		$RSYNC_MODE_QUIET \
		${RSYNC_DEFAULT_OPTIONS} \
		${RSYNC_EXCLUDES} \
		--link-dest="${DESTINATION_DIR}/current" \
		"${BACKUP_SOURCE_DIR}" \
		"${DESTINATION_DIR}/incomplete/" >> ${LOG_FILE_BUSY} 2>&1

		
	echo >> ${LOG_FILE_BUSY}
	
	echo wrapping up... >> ${LOG_FILE_BUSY}
	echo >> ${LOG_FILE_BUSY}
	cd "${DESTINATION_DIR}"

	mv incomplete/ ${DATETIME_START}/ 
	rm -rf current 
	ln -s $DATETIME_START current
	rm -rf partial	
fi


# .. and we are done...
DATETIME_FINISHED="$(date +"%Y.%m.%d-%H.%M.%S")"

echo Finished at $DATETIME_FINISHED >> ${LOG_FILE_BUSY}
echo Backup finished

mv ${LOG_FILE_BUSY} ${LOG_FILE_FINISHED}

exit 