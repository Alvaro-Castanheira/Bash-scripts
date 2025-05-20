#!/bin/bash

# This script can disable, deletes and backsups user's home directories.
# NOTE: This script doesn't disable or delete system or service accounts.

# This scripts must be executed with SUPERUSER privileges.

# More informaton on the help function.

### Variables ###
DATE="$(date +%d-%m-%Y-%H-%M)"
BACKUPDIR="/archive"
USERHOME="/home/${1}"
DEL='false'
RHD='false'
BACKUP='false'

### Functions ###

help(){
    echo "USAGE:disable-local-user.sh [-dra] USER_NAME...
     OPTIONS:
     -d Deletes accounts instead of disabling them.
     -r Removes the home directory associated with the account(s).
     -a Creates an archive of the home directory associated with the accounts(s) and stores the archive in the /archives directory."
    
}

backuphomedir(){
    ## Function variables ##
    TESTEDIR="/tmp/restoreteste"
    BACKUPFILE="${1}-${DATE}.tar.gz"
    USERHOME="/home/"${1}""

    ## Testing if the backup directory exists, if not then is created.
    if [[ ! -d "${BACKUPDIR}" ]]
    then
        mkdir "${BACKUPDIR}"
    fi

    BACKUPTESTE_1=$(ls -l $USERHOME | md5sum | awk '{print $1}')

    tar -czf "${BACKUPDIR}/${BACKUPFILE}" "${USERHOME}" 

    # Testing if the backup was successfull.
      if [[ ! -d "${TESTEDIR}" ]]
    then
        mkdir "${TESTEDIR}"
    fi

    tar -xzf "${BACKUPDIR}/${BACKUPFILE}" -C "${TESTEDIR}"

    BACKUPTESTE_2=$(ls -l "${TESTEDIR}""${USERHOME}" | md5sum | awk '{print $1}' )

    if [ "${BACKUPTESTE_1}" = "${BACKUPTESTE_2}" ]
	then 
		echo "${1} Home dir backup was successfull."
		rm -rf $TESTEDIR
	else
		echo "Something went wrong. Backup failed."
		echo "Check "${TESTEDIR}" for troubleshooting."
        exit 1
	fi

}


deleteuser(){
    if [[ "${RHD}" = 'true' ]]
    then 
        userdel -r "${1}" # Removes user's home dir.
        echo ""${1}" home directory removed."
    else 
        userdel "${1}"
    fi

    if [[ ${?} -eq 0 ]]
        then 
            echo "${1} was deleted."
        else
            echo "Failed to delete the account. Please try again."
            exit 1
        fi

}

disableuser(){

    usermod -L ${1}

     if [[ ${?} -eq 0 ]]
        then 
            echo "${1} was disabled."
        else
            echo "Failed to disable the account. Please try again."
            exit 1
        fi
}

# Test for superuser privileges
if [[ "${UID}" -ne 0 ]]
then
    echo "Please execute the script with sudo or as root." >2&
    exit 1
fi


while getopts drah OPTION
do
    case ${OPTION} in
        d) DEL='true'    ;;
        r) RHD='true'    ;;
        a) BACKUP='true' ;; 
        h) help          ;;
        *) help          ;;
    esac
done        

shift "$(( OPTIND -1 ))" # Removes the "option" so the next loop only consider de remaning args that are user names.


for USER in "${@}"
do
    echo "User that is being treated is ${USER}."

    if [[ $(id -u "${USER}") -lt 1000 ]] # Test for system or service users.
    then
        echo "This script doesn't disables or deletes system or service accounts." >&2
        echo "${USER} will reamin active."
    else 
        if [[ "${DEL}" = 'true' ]]
        then # Deletes the user.
            if [[ "${BACKUP}" = 'true' ]]
            then
                backuphomedir "${USER}"
                deleteuser "${USER}"
            else
                deleteuser "${USER}"
            fi                        
        else
            if [[ "${BACKUP}" = 'true' ]]
            then
                backuphomedir "${USER}"
                disableuser "${USER}"
            else
                disableuser "${USER}"
            fi
        fi
    fi
done


