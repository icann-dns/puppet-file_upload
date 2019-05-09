#!/usr/bin/env bash
# Copyright (c) 2019, Internet Corporation for Assigned Names and Numbers
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# 2019 ICANN DNS Engineering
set -f
#set -x
export PATH=/usr/bin:/bin

while getopts "s:D:d:u:k:b:P:eEL:Cp" opt; do
  case $opt in
	s ) SOURCE_DIR=${OPTARG} ;;
	D ) DESTINATION_HOST=${OPTARG} ;;
	d ) DESTINATION_DIR=${OPTARG} ;;
	u ) SSH_USER=${OPTARG} ;;
	k ) SSH_KEY_FILE=${OPTARG} ;;
	b ) BWLIMIT=${OPTARG} ;;
	P ) PATTERNS=($OPTARG) ;;	# Store patterns in an Array
	e ) DELETE=YES ;;
	E ) REMOVE_SOURCE_FILES=YES ;;
	L ) LOG_FILE=${OPTARG} ;;
	C ) CLEAN_KNOWN_HOSTS=YES ;;	
	p ) CREATE_PARENTS_DIRS=YES ;;	
  esac
done

INCLUDES=""

for PATTERN in "${PATTERNS[@]}" ; do
	INCLUDES="${INCLUDES} --include=/${PATTERN}"
done

LOGGER="/usr/bin/logger -t file_upload_${UPLOAD_HOST}"

if [ "${CLEAN_KNOWN_HOSTS}" == "YES" ] ; then
	ssh-keygen -f "/root/.ssh/known_hosts" -R ${UPLOAD_HOST} >/dev/null 2>&1
fi

SSH="/usr/bin/ssh -q -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o PreferredAuthentications=publickey -i ${SSH_KEY_FILE} -l ${SSH_USER}"

RSYNC="rsync -avi ${INCLUDES} --exclude=/* --exclude=*.log --bwlimit=${BWLIMIT}"

if [ "${DELETE}" == "YES" ] ; then
	RSYNC="$RSYNC --delete"
elif [ "${REMOVE_SOURCE_FILES}" == "YES" ]
then
	RSYNC="$RSYNC --remove-source-files"
fi

if test -n "$(find ${SOURCE_DIR} -name ${PATTERNS[@]} -maxdepth 1 -print -quit)" ; then
  ## if files exists to transfer then we do an rsync

  OLDNOW=$(date +%s)
  echo "${OLDNOW}: Transfer-START" >> ${LOG_FILE}

  if [ "${CREATE_PARENTS_DIRS}" == "YES" ]
  then
    # we use dev null here to create the parent dir
    # we only create parents not grandparents
    PARENT_DIR=$(dirname ${DESTINATION_DIR})
    rsync -ae "${SSH}" /dev/null ${DESTINATION_HOST}:${PARENT_DIR}/ &> /dev/null
  fi
  # 2 outputs managed by tee
  ${RSYNC} -e "${SSH}" ${SOURCE_DIR}/ ${DESTINATION_HOST}:${DESTINATION_DIR} | \
	tee >(gawk '$1=="<f+++++++++" {printf "%s: Transferred: %s\n", systime(), $2}' >> ${LOG_FILE} ) | \
	gawk '$1=="sent" {printf "%s: sent=%s, received=%s, rate=%s\n", systime(), $2, $5, $7}' >> ${LOG_FILE}

  NOW=$(date +%s)
  echo "${OLDNOW}: Transfer-END after $(( NOW - OLDNOW )) secs" >> ${LOG_FILE}

else
  echo "No files to transfer" >> ${LOG_FILE}
fi
