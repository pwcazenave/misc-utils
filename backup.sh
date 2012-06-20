#!/bin/bash
# 
# backup script to save /home/$USER, /etc, /var and /boot directories to
# external usb drive. Logs are created on the external drive.
#
# TODO: 
# - put logs elsewhere too. DONE (see below).
# - make remote backups. DONE.
#
# Copyright 2007-2010 Pierre Cazenave <pwcazenave {at} gmail [dot] com>
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# created: not sure when! Beginning of 2007 judging by the oldest log.
# updated: 25/11/2007 
#	   10/04/2008
# 	   29/05/2008 -	* added --exclude to rsync for /home/pwc
#	   07/07/2008 -	* made it a --size-only on /home/pwc because it was 
#			copying almost everything, every time. 
#			* added full paths for all commands.
#	   16/07/2008 - * changed path of $USB to /media/usb/backups for a 
#			centralised location for all backups (Nat's, Mum's 
#			and mine). 
#			* fixed more absolute path omissions.
#			* added TODO section.
#          31/07/2008 - * fixed script to work on Debian.
#                       * rectified $USB to not include /backups, instead all 
#                       paths have /backups inserted where appropriate.
#                       * also made appropriate change to eliminate "current",
#                       and change to match new path: "archive".
#	   11/08/2008 - * fixed last "current" path mismatch (a typo: 
#			"curent").
#	   28/08/2008 - * fixed more non-absolute paths.
#	   12/10/2008 - * removed the partial directory check.
#			* added -p to mkdir commands, just in case.
#	   15/10/2008 -	* moved mounted check to BEFORE the mkdir commands.
#	   28/10/2008 -	* added LABEL variable.
#			* fixed mounting (was creating $USB without mounting 
#			disk). Uses -L $LABEL now.
#			* also creates and removes $USB directory, if not 
#			present.
#			* quoted all variables.
#			* rsync fails with error code 23, so can't use set 
#			-e. Due to fat32 not supporting symlinks, I think.
#	   06/11/2008 -	* changed LABEL to match new partitioning.
#			* removed 4GB limit and --size-only from rsync 
#			options.
#			* since new partition is ext3, can leave set -e in.
#			* remove -o uid=1000,gid=100 from mount command; 
#			was superfluous since $USB is owned by me anyway.
#	   11/12/2008 - * moved to fit-pc and amended home as necessary.
#			* remove r from rsync flags (superfluous).
#			* added $WHO for home directory and chowning afterwards.
#	   13/12/2008 -	* added argument to do_home so I could add root's home.
#	   20/03/2009 - * added do_perms to backup permissions for all files on 
#			the system so they can be backed up in case of 
#			accidental chmod.
#			Restore with: while read LINE; do PERMS=${LINE% *}; 
#			FILE=${LINE#* }; chmod $PERMS $FILE; done < $PERMS_FILE
#			* added PATH variable instead of absolute paths to all
#			commands.
#	   14/08/2009 - * fixed bug in deleting old logs when the backup hasn't
#			run in over a week. Previous behaviour meant it ran the 
#			rm command if there were more than 5 files, rather than
#			5 files over 7 days old.
#			* also added a chown and chmod on the /var backups so 
#			nosey parkers can't have a gander at sensitive logs.
#			* remove squid from var backups (too big and takes too
#			long, and since I'm not using it, I won't miss it).
#			* added removal of permissions backups from more than
#			a week ago. Same logic as the other backups.
#	   01/09/2009 - * moved to Slackware 13.0; amended $WHO as required.
#			* amended CHECK_PERMS{,_NAMES} to reflect the new 
#			partition layout.
#	   12/10/2009 - * fixed the incorrectly functioning check for existing
#			number of boot and etc tarballs.
#	   23/11/2009 - * fixed the permissions for loop array lookup as it 
#			wasn't working properly.
#			* moved the /var permissions and ownership fixes into
#			the do_var function.
#			* changed the do_home rsync command to output to 
#			LOG_FILE using --log-file instead of 2>&1 >> $LOG_FILE.
#	   25/11/2009 - * added .ktorrent to excludes for do_home.
#	   10/12/2009 - * moved script to reinstalled server. Amended $LABEL 
#			accordingly.
#	   05/02/2010 - * fixed the NEW_VAR command to look for compressed 
#			archives.
#	   16/02/2010 - * fixed the change of permissions at the end of the
#			script to skip the /var archive. This behaviour was
#			undoing the work of do_var which was setting permissions
#			to root:root.
#	   03/06/2010 - * added the Dropbox folder to the excluded files in 
#			do_home().
#	   30/11/2010 - * modified paths for new 2TB external disk.
#          20/02/2011 - * removed the USB mount code. If the target disk doesn't
#			exist, then we just quit.
#			* also changed LOG_DIR to point to the archive
#			directory.
#			* removed the compression of /var since space is less of
#			an issue for the time being.
#	   21/02/2011 - * added extra check for arguments to do_perms so we don't
#			crap out with an unbound variable error.
#			* also removed the umount command at the end since I'm 
#			assuming the disk is always connected these days. Either
#			way, if it's not or it's unmounted, the script exits at 
#			the beginning anyway, so that umount command would never
#			get executed.
#	   03/05/2011 - * moved over to Slackware 13.37. Paths remained unchanged
#			but $WHO changed. 
#	   29/06/2011 - * added the hidden .dropbox folder to the excluded files
#			in do_home().
#	   22/08/2011 - * added the Unison directory to the excluded files in 
#			do_home().
#	   20/06/2012 - * added new functionality to check if the most recent 
#			boot, var or etc archive is the same as today's. If so,
#			the new archive is removed and the old archive is
#			renamed. This should reduce traffic from home to work
#			without reducing the data actually being backed up
#			i.e. changes in any of those folders will still be 
#			in a unique archive. The cleanup code to remove old 
#			archives should always leave a minimum of six archives
#			even if they're ancient.
#			* Also refactored the archive code to only require a
#			single function which can be called multiple times with
#			a directory as first argument.
#			* Finally, remove tarballs from the chown so that only
#			root can read their contents (for security).

PATH=/usr/bin:/bin

#set -e # exit on most errors. 
#set -x # debugging
set -u # exit on unset variables.

DATE=$(date "+%y-%m-%d")
HOST=$(hostname -s)
WHO="rassilon"
HOME_DIR=/home/"$WHO"
ROOT_HOME_DIR=/root
ETC_DIR=/etc
BOOT_DIR=/boot
VAR_DIR=/var
CHECK_PERMS=(/)
CHECK_PERM_NAMES=(root)
LABEL="Citadel"
USB="/media/$LABEL"

# check if the usb drive's mounted, and if it's not, then quit.
MOUNTED=0
grep "$USB" /etc/mtab > /dev/null && MOUNTED=1
if [ "$MOUNTED" -eq "0" ]; then
	exit 1
fi

if [ -d "$USB/archive/$HOST" ]; then
	TO_DIR="$USB/archive/$HOST"
else
	mkdir -p "$USB/archive/$HOST"
	TO_DIR="$USB/archive/$HOST"
fi
if [ -d "$USB/archive/logs/$HOST" ]; then
	LOG_DIR="$USB/archive/logs/$HOST"
else
	mkdir -p "$USB/archive/logs/$HOST"
	LOG_DIR="$USB/archive/logs/$HOST"
fi
if [ -e "$LOG_DIR/backup_$DATE.log" ]; then
	NO_LOG="$(ls $LOG_DIR/backup_$DATE*.log | wc -l)"
	LOG_FILE="backup_$DATE.$NO_LOG.log"
else
	LOG_FILE="backup_$DATE.log"
fi
if [ -d "$USB/archive/$HOST/perms" ]; then
	PERMS_DIR="$USB/archive/$HOST/perms"
else
	mkdir -p "$USB/archive/$HOST/perms"
	PERMS_DIR="$USB/archive/$HOST/perms"
fi
if [ -e "$PERMS_DIR/perms_"$DATE"_root.log.bz2" ]; then
	NO_PERM="$(ls $PERMS_DIR/perms_${DATE}*root*.log.bz2 | wc -l)"
	PERMS_FILE="$PERMS_DIR"/perms_"$DATE"
else
	NO_PERM=""
	PERMS_FILE="$PERMS_DIR"/perms_"$DATE"
fi

do_home(){
	nice -n 10 rsync -av \
		--exclude=.thumbnails --exclude=Cache --exclude=Trash \
		--exclude=.ktorrent --exclude=Dropbox --exclude=.dropbox \
		--exclude=Unison --exclude=Cloud \
		--log-file="$LOG_DIR/$LOG_FILE" \
		"$1" "$TO_DIR" \
		2> /dev/null
}

do_archive(){
	# Now refactored for arbitrary input directory. So, set up some
	# necessary variables
	IN_DIR="$1"
	SANE_IN_DIR=${IN_DIR/\/} # strip leading slash

	# get the most recent archive's md5sum for comparison later
	MOST_RECENT=$(ls -1tr "$TO_DIR"/"$SANE_IN_DIR"_*.tar | tail -1)
	if [ $MOST_RECENT != "$TO_DIR/"$SANE_IN_DIR"_$DATE.tar" ]; then
		MD5_OLD=$(md5sum $MOST_RECENT | cut -f1 -d' ')
	else
		# For some reason (testing) we already have today's archive.
		# Let's not do all the md5 summing again.
		MD5_OLD='NO_COMPARE'
	fi
	echo "" >> "$LOG_DIR/$LOG_FILE"
	echo "Tarring $ETC_DIR to $TO_DIR/"$SANE_IN_DIR"_$DATE.tar" \
		>> "$LOG_DIR/$LOG_FILE"
	nice -n 10 tar pcf "$TO_DIR/"$SANE_IN_DIR"_$DATE.tar" "$ETC_DIR" \
		&> /dev/null 
	echo "Tarball $TO_DIR/"$SANE_IN_DIR"_$DATE.tar created." \
		>> "$LOG_DIR/$LOG_FILE"
	if [ $MD5_OLD != 'NO_COMPARE' ]; then
		MD5_NEW=$(md5sum "$TO_DIR/"$SANE_IN_DIR"_$DATE.tar" | cut -f1 -d' ')
		if [ $MD5_NEW == $MD5_OLD ]; then
			# replace new one with the old one (since there's no apparent
			# change.
			rm "$TO_DIR/"$SANE_IN_DIR"_$DATE.tar"
			mv $MOST_RECENT $TO_DIR/"$SANE_IN_DIR"_$DATE.tar
		fi
	fi
	# remove old tar files (greater than 7 days old), making sure there's 
	# still some left!
	NUM_ARCHIVE=$(find "$TO_DIR" -maxdepth 1 -mtime +7 \
		-iname "${SANE_IN_DIR}_????????.tar" | wc -l
		)
	NEW_NUM_ARCHIVE=$(find "$TO_DIR" -maxdepth 1 -mtime -7 \
		-iname "${SANE_IN_DIR}_????????.tar" | wc -l
		)
	if [[ "$NUM_ARCHIVE" -gt 5 && "$NEW_NUM_ARCHIVE" -gt 5 ]]; then
		echo "" >> "$LOG_DIR/$LOG_FILE"
		echo "Removing backups of $IN_DIR from more than a week ago." \
			>> "$LOG_DIR/$LOG_FILE"
		echo "" >> "$LOG_DIR/$LOG_FILE"
		find "$TO_DIR" -maxdepth 1 -mtime +7 \
			-iname "${SANE_IN_DIR}_????????.tar" \
			-exec rm -f "{}" \+
	else
		echo "" >> "$LOG_DIR/$LOG_FILE"
		echo "Won't remove old ${IN_DIR} backups; too few remaining." \
			>> "$LOG_DIR/$LOG_FILE"
		echo "" >> "$LOG_DIR/$LOG_FILE"
	fi
}

do_perms(){
	if [ $# -eq 3 ]; then
		PERM_SUFFIX="$2""$3"
	else
		PERM_SUFFIX="$2"
	fi

	find "$1" -mount ! -type l -exec stat --format="%u %g %a %n" "{}" + | \
		bzip2 - > "$PERMS_FILE"_${PERM_SUFFIX}.log.bz2
	# get rid of ancient permissions backups
	NO_PERMS=$(find "$PERMS_DIR" -maxdepth 1 -mtime +7 \
		-iname "perms_????????_${PERM_SUFFIX}.log.bz2" | wc -l
	)

	if [[ "$NO_PERMS" -gt 5 ]]; then
		echo "" >> "$LOG_DIR/$LOG_FILE"
		echo "Removing permissions backups from more than a week ago." \
			>> "$LOG_DIR/$LOG_FILE"
		find "$PERMS_DIR" -maxdepth 1 -mtime +7 \
			-iname "perms_????????_${PERM_SUFFIX}.log.bz2" \
			-exec rm -f "{}" +
	else
		echo "" >> "$LOG_DIR/$LOG_FILE"
		echo "Won't remove old permissions backups; too few remaining." \
			>> "$LOG_DIR/$LOG_FILE"
		echo "" >> "$LOG_DIR/$LOG_FILE"
	fi
}

echo "Backup for $DATE" > "$LOG_DIR/$LOG_FILE"

if [ -d "$HOME_DIR" ] && [ -d "$TO_DIR" ]; then
	do_home	$HOME_DIR	# backup the home directory
fi
if [ -d "$ROOT_HOME_DIR" ] && [ -d "$TO_DIR" ]; then
	do_home	$ROOT_HOME_DIR	# backup the root home directory
fi
if [ -d "$ETC_DIR" ] && [ -d "$TO_DIR" ]; then
	do_archive /etc		# backup /etc as a tarball, preserving permissions
fi
if [ -d "$BOOT_DIR" ] && [ -d "$TO_DIR" ]; then
	do_archive /boot	# backup /boot as a tarball, preserving permissions
fi
if [ -d "$VAR_DIR" ] && [ -d "$TO_DIR" ]; then
	do_archive /var		# backup /var as a tarball, preserving permissions
fi

for ((DIR=0; DIR<${#CHECK_PERMS[@]}; DIR++)); do
	if [ -d ${CHECK_PERMS[DIR]} ]; then
		if [ -z $NO_PERM ]; then
			do_perms ${CHECK_PERMS[$DIR]} ${CHECK_PERM_NAMES[$DIR]}
		else
			do_perms ${CHECK_PERMS[$DIR]} ${CHECK_PERM_NAMES[$DIR]} ."$NO_PERM"
		fi
		echo "" >> "$LOG_DIR/$LOG_FILE"
		echo "backed up permissions for ${CHECK_PERMS[$DIR]}." \
			>> "$LOG_DIR/$LOG_FILE"
	fi
done

# fix ownership on files created (logs, and, ironically, permissions).
chown "$WHO":users \
	"$LOG_DIR"/"$LOG_FILE" \
	"$PERMS_FILE"*

# fix permissions on tarball backups so unprivileged users can't rifle
# through them.
chmod 600 "$TO_DIR"/*$DATE*.tar
chown root:root "$TO_DIR"/*$DATE*.tar
echo "Fixed permission and ownership of /var archive." >> "$LOG_DIR/$LOG_FILE"

exit 0
