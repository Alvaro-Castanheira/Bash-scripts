#!/bin/bash

# This scripts Executes all arguments as a single command on every server listed in the /multinet/serverslist file by default.
# To use this script your ssh key must be configured on the remote host.

# This script must be executed with you PERSONAL user.
# If you want to execute the remote comands with superuser privileges, specify the -s option.
# For the correct execution with the -s opiton you user must be allowed to use sudo without ask for password.

# Executes the provided command as the user executing the script.

# More information displayed on the help function.


#### Variables ####
SERVER_FILE='/multinet/serverslist'
SSH_OPTION='-o ConnectTimeout=2'

### Functions ###

function help(){
    echo "USAGE:run-everywhere.sh [-vs] [-f _FILE_] _COMMAND_
OPTIONS:
-f _FILE_  This allows the user to override the default file of /multinet/servers.
-n This allows the user to perform a "dry run" where the commands will be displayed instead of executed.
-s Run the command with sudo (superuser) privileges on the remote servers.
-v Enable verbose mode, which displays the name of the server for which the command is being executed on."

}

function verbose(){
    if [[ $VERBOSE = 'true' ]]
    then
        REMOTEHOST=$(ssh $SSH_OPTION $SERVER "hostname")
        REMOTEHOSTIP=$(ssh $SSH_OPTION $SERVER "nmcli con show ens160 | grep "ipv4.addresses" | awk '{print \$2}' | awk -F "/" '{print \$1}'")
        echo "Working on $REMOTEHOST IP:$REMOTEHOSTIP"
    fi
}


## Start ##

# Test for superuser privileges. #A TESTAR AQUI
if [[ $(id -u) -eq 0 ]]
then
    echo -e "Please execute the script with your user.
    \rThis script doesn't allow to run as superuser."
    echo
    help
    exit 1
fi


while getopts vhsnf: OPTION
do
    case $OPTION in
        f) SERVER_FILE="${OPTARG}" ;; 
        v) VERBOSE='true'          ;;
        s) SUPERUSER='sudo'        ;; 
        n) DRYRUN='true'           ;;
        h) help                    ;;
        ?) help                    ;;       
    esac 
done


# Removes the option while leaving the remaing arguments.
shift "$(( $OPTIND -1 ))" 

# Test if SERVER_FILE exists 
if [[ ! -f  $SERVER_FILE ]]
then 
    echo -e "$SERVER_FILE doesn't exist.
    \rPlease provide another file."
    exit 1 
fi

# Testing if the user provided at least one argument
if [[ ${#} -eq 0 ]]
then 
    echo "A command must be supplied as an argument."
    help
    exit 1
fi

# Remote host command execution
for SERVER in $(cat $SERVER_FILE) 
do
    if [[ $DRYRUN = 'true' ]]
    then
        verbose
        echo "ssh $SSH_OPTION $SERVER "$SUPERUSER ${@}""
        
    else
        verbose
        ssh $SSH_OPTION $SERVER "$SUPERUSER ${@}"
        ERROR_COD=$(echo $?)

        if [[ $ERROR_COD -ne 0 ]]
        then 
            echo -e "Error running the command on $SERVER.
            \rError code: $ERROR_COD."
        fi
    fi

    echo
done

exit 0