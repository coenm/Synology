#!/bin/sh

FILE_PASSWD=/etc/passwd
AWK=/usr/bin/awk

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
	echo "This script will update the password file to change the users shell."
	echo
	echo "Usage:"
	echo
	echo "	$0 -u <username> [-h]"
	echo
	echo "	-h = Help"
	echo "		List this help menu"
	echo
	echo "	-u = Username to allow SSH access"
	echo
	echo "----------------------------------------------------------------------------"
}

while getopts "u:h" options
do
	case $options in 
		u ) opt_u=$OPTARG;;
		h ) opt_h=1;;
	esac
done


if [ $opt_h ]; then
	print_header
	print_help
	exit 1
fi 


if [ $opt_u ]; then
	# Inspired by https://andidittrich.de/2016/03/howto-re-enable-scpssh-login-on-synology-dsm-6-0-for-non-admin-users.html
	echo Enable ssh access for ${opt_u}

	COUNT=$(${AWK} -v username=${opt_u} -F: 'username==$1' ${FILE_PASSWD} | wc -l)

	if [ $COUNT == 1 ]; then

		echo User ${opt_u} found. Verify users shell...
		USER_SHELL=$(${AWK} -v username=${opt_u} -F: 'username==$1 { print $7 }' ${FILE_PASSWD} )

		if [ $USER_SHELL == '/bin/sh' ]; then
			
			echo User has already right shell.
			echo Done.
			exit 1

		else

			echo Change users shell from ${USER_SHELL} to /bin/sh
			${AWK} -i inplace -v username=${opt_u} -F: 'BEGIN{OFS=":"} username==$1 {gsub(/.*/,"/bin/sh",$7)}1' ${FILE_PASSWD}
			echo Done.
			exit 1

		fi

	else

		echo Ooeps, ${COUNT} lines found for this username. Manual action required.
		exit 2
	fi

else

	print_header
	echo [ERROR] No user is given.
	echo
	print_help	
	exit 1

fi