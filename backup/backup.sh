#!/bin/bash

# ! /bin/sh


#***************************************************************
VERSION="2019.11.11"

DATETIME_START="$(date +"%Y.%m.%d-%H.%M.%S")"

# Default backup excludes and default options.
RSYNC_EXCLUDE_DSM='--exclude=#recycle/ --exclude=@eaDir/'
RSYNC_EXCLUDE_MAC='--exclude=.Trashes/ --exclude=.TemporaryItems/'
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
	echo "	$0 -s <source config> -d <destination config> [-c -p -v -q -h]			"
	echo "																			"
	echo "	-h = Help																"
	echo "       List this help menu												"
	echo "																			"
	echo "	-s = Source of rsync backup												"
	echo "																			"
	echo "	-d = Destination type of the backup (remote or local)					"
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
	echo "----------------------------------------------------------------------------"
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
RSYNC_EXCLUDES="$RSYNC_EXCLUDE_DSM $RSYNC_EXCLUDE_MAC $RSYNC_EXCLUDE_FILES"


#***************************************************************
# Get Options from the command line  
#***************************************************************
while getopts "s:d:hcvpq" options
do
	case $options in 
		c ) RSYNC_MODE_CHECKSUM='--checksum ';;
		v ) RSYNC_MODE_VERBOSE='--verbose ';;
		q ) RSYNC_MODE_QUIET='--quiet ';;
		p ) RSYNC_MODE_PROGRESS='--progress ';;	
		
		s ) opt_s=$OPTARG;;
		d ) opt_d=$OPTARG;;
		e ) opt_e=$OPTARG;;
		l ) opt_l=$OPTARG;;

		h ) opt_h=1;;
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


#***************************************************************
# Destination 
#***************************************************************
if [ $opt_d ]; then

	DESTINATION_CONFIG_FILE=backup.${opt_d}.config
	if [ -f ${CONFIG_DIR}/${DESTINATION_CONFIG_FILE} ]; then
		source ${CONFIG_DIR}/${DESTINATION_CONFIG_FILE}
		# TODO: check if the DESTINATION_CONFIG_FILE file contains the required variables and check their values.
	else
		print_header
		echo [ERROR] Destination config ${DESTINATION_CONFIG_FILE} does not exist.
		exit 1
	fi
else
	print_header
	echo [ERROR] Destination config -d is empty
	echo
	print_help
	exit 1	
fi
	
# Destination base directory to store the backup.
# Should be an absolute path. If the backup is on a remote machine. Do not enter a path like user@host:/path/to/store/backup
BACKUP_DIR=/backup

#***************************************************************
# Source
#***************************************************************
if [ $opt_s ]; then

	BACKUPSET_CONFIG_FILE=backupset.${opt_s}.config
	if [ -f ${CONFIG_DIR}/${BACKUPSET_CONFIG_FILE} ]; then
		source ${CONFIG_DIR}/${BACKUPSET_CONFIG_FILE}
		# TODO: check if the BACKUPSET_CONFIG_FILE file contains the required variables and check their values.
	else
		print_header
		echo [ERROR] Backupset config ${BACKUPSET_CONFIG_FILE} does not exist
		exit 1
	fi	

	## Create the destination path (also the escaped variant)
	DESTINATION_DIR=${BACKUP_DIR}/${BACKUP_NAME}
	DESTINATION_DIR_ESCAPED=${DESTINATION_DIR// /\\ }

	echo "-- DESTINATION_DIR: ${DESTINATION_DIR}"
	echo "-- DESTINATION_DIR_ESCAPED: ${DESTINATION_DIR_ESCAPED}"

else

	print_header
	echo [ERROR] Backupset config -s is empty
	echo
	print_help	
	exit 1

fi


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


if [ $DEST_IS_REMOTE -eq 1 ]; then

	if [ $DEST_PORT -ne 22 ]; then
		SSH_PORT='-p '$DEST_PORT
	fi
	
		
	# Check if private key file exists. If not -> quit backup.
	if [ ! -f ${DEST_KEYFILE} ]; then
		echo [ERROR] Cannot backup to remote because the private key ${DEST_KEYFILE} does not exist.
		echo
		print_help
		exit 1
	fi
	SSH_KEY='-i '${DEST_KEYFILE}		
	echo "-- SSH_KEY: ${SSH_KEY}"
			
	echo Start remote backup >> ${LOG_FILE_BUSY}
	echo >> ${LOG_FILE_BUSY}

	echo Create working dir for backup >> ${LOG_FILE_BUSY}
	
			
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
		"cd \"$DESTINATION_DIR\" &&  mv incomplete/ $DATETIME_START/ && rm -rf current && ln -s $DATETIME_START current && rm -rf partial"
	
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