#!/bin/sh

##
## $Id: auto_update.sh,v 1.3 2016/03/26 08:23:27 anoncvs Exp $
##
## Find all git subdirectories and do a "git pull" to update
## thhem to the latest revision.
##
PATH=/bin:/usr/bin;
WK_DIR=/home/gaijin/ESP8266;
EXCEPT=${WK_DIR}/Do_Not_Update.txt;	## If name in exception list, skip update.
EX_FLAG_FILE="Do_Not_Update";		## If file exists in target directory, skip update.
CHK_DIR=".git";				## If dir does not exist in targ dir, skip update.
GIT_BIN=/usr/bin/git;
LOG=/var/tmp/ESP8266_auto_update.log;


## Only output to stdout if we have a tty attached (so quiet
## when run from cron).
Totty(){
	tty -s && printf "\n\t${*}\n\n";
}

## Chicken and Egg quit routine (no writeable log file).
FQuit(){
	Totty "${*}";
	exit 254;
}

## Log to local log file (read "man logger" for syslogging
## from a script).
Log(){
        DATENOW=`/bin/date`;
        printf "${DATENOW}:  ${@}\n" >> ${LOG} || \
		FQuit "Unable to write to log file: ${LOG}";
}

## Verboseness.
Info(){
	Totty "[INFO] ${*}";
	Log "[INFO] ${*}";
}

## Flag errors.
Error(){
	Totty "ERROR: ${*}";
	Log "ERROR: ${*}";
}

## Oops!  Something nasty happened.
Fatal(){
	Error "${*} -- Cannot continue.";
	exit 254;
}

## Check a directory name against the exception list entries.
CheckExceptList(){
        [ ${#} -ne 1 ] && Fatal "CheckExceptList: Dir-name required.";
        EXCPT_TARG="${1}";
        for NOUPDT in ${EXCPT_LIST};   do
                if [ "${NOUPDT}" = "${EXCPT_TARG}" ];   then
                        Log "Directory ${EXCPT_TARG} skipped (in exception list)";
                        return 1;
                fi
        done
        return 0;
}

## Check for a .git subdirectory and for a Do_Not_Update flag file.
CheckGitDir(){
        [ ${#} -ne 1 ] && Fatal "CheckGitDir: Dir-name required.";
	if [ ! -d "${1}"/${CHK_DIR} ];	then
		Log "Directory ${EXCPT_TARG} skipped (no ${CHK_DIR} directory)";
		return 1;
	fi
	if [ -f "${1}"/${EX_FLAG_FILE} ];	then
		Log "Directory ${EXCPT_TARG} skipped (${EX_FLAG_FILE} file exists)";
		return 1;
	fi
	return 0;
}

## Okay.  Lets actually do stuff ...sanity checks first.
[ ! -d ${WK_DIR} ] && Fatal "Directory does not exist: ${WK_DIR}";
[ ! -x ${GIT_BIN} ] && Fatal "Not executable: ${GIT_BIN}";
if [ ! -f ${EXCEPT} -o ! -s ${EXCEPT} ];	then
       Info "No exceptions found: ${EXCEPT}.  Continuing anyway.";
       EXCPT_LIST=;
else
	## Build exceptions list.
	for EXCL in `/bin/cat ${EXCEPT}`; do
		EXCPT_LIST="${EXCPT_LIST} ${EXCL}";
	done
fi

## Back-up the oldlog file.
if [ -s ${LOG} ];	then
	/bin/mv ${LOG} ${LOG}_OLD || \
		Fatal "Failed to back-up old log file: ${LOG}_OLD";
fi
cd ${WK_DIR} || Fatal "Failed to cd to ${WK_DIR}";
Log "Started...";

## Build top-level directory list.
DIR_LIST=`find . -xdev -maxdepth 1 -type d -ls | nawk '{print $11, " ";}'`;

## Drop any directories which are specifically mentioned in the
## exceptions file, or any directories which do not have a .git
## subdirectory, or any directories which have a "Do_Not_Update"
## marker file in them.
for TDIR in ${DIR_LIST}; do
	if [ "${TDIR}" = "." -o "${TDIR}" = ".." ];	then
		continue;	## Drop "." and ".." (top level dirs).
	fi
	CheckExceptList "${TDIR}";
	if [ ${?} -eq 1 ];	then
		continue;
	fi
	CheckGitDir "${TDIR}";
	if [ ${?} -eq 1 ];	then
		continue;
	fi

	WORK_LIST="${WORK_LIST} ${TDIR}";
done

for WDIR in ${WORK_LIST}; do
	Log "";
	Log "------------------------------------------------------------------------------------------";
	Log "Updating: ${WDIR}...";
	cd ${WDIR} || Fatal "Unable to cd to dir: ${WDIR}";
	${GIT_BIN} pull >> ${LOG} 2>&1;
	if [ ${?} -ne 0 ];	then
		Error "Git \"pull\" unsuccessful: ${WDIR}";
	else
		Log "${WDIR}: Update completed.";
	fi
	cd ${WK_DIR} || Fatal "Strange! Unable to cd back to original work dir: ${WK_DIR}";
done

exit ${?};
