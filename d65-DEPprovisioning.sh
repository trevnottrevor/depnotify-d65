#!/bin/bash
#
#
# Edited and adapted for use at District 65 by Trev Kelderman (keldermant@district65.net)
# Original script was created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: com.d65-DEPprovisioning.sh
#
# Purpose: Install and run DEPNotify at enrollment time and do some final touches.
# If the machine is already in the jss it will automatically continue
# and complete setup. If the machine isn't in the jss or it's a Staff machine,
# it will ask the tech to assign it a name and cohort. It also checks for software updates
# and installs them if found.
# This gets put in the composer package along with DEPNotify, com.d65.launch.plist,
# and any supporting files. Then add the post install script to the package.
#
#
# Get the JSS URL from the Mac's jamf plist file, we'll use this to check if the machine is already in the jss
if [ -e "/Library/Preferences/com.jamfsoftware.jamf.plist" ]; then
	JSSURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
else
	echo "No JSS server set. Exiting..."
	exit 1
fi
# I don't like hardcoding passwords but since we're putting this locally on the machine...
APIUSER="depnotify"
APIPASS="pfR0ftendc"

JAMFBIN=/usr/local/bin/jamf
OSVERSION=$(sw_vers -productVersion)
serial=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')
# get all EAs of this machine from the JSS and break down the ones we need (If they're in the JSS)
eaxml=$(curl "$JSSURL"JSSResource/computers/serialnumber/"$serial"/subset/extension_attributes -u "$APIUSER":"$APIPASS" -H "Accept: text/xml")
jssMacName=$(echo "$eaxml" | xpath '//extension_attribute[name="New Computer Name"' | awk -F'<value>|</value>' '{print $2}')
jssCohort=$(echo "$eaxml" | xpath '//extension_attribute[name="New Cohort"' | awk -F'<value>|</value>' '{print $2}')
# Get the logged in user
CURRENTUSER=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
# Setup Done File
setupDone="/var/db/receipts/com.d65.provisioning.done.bom"
# DEPNotify Log file
DNLOG=/var/tmp/depnotify.log

# If the receipt is found, DEP already ran so let's remove this script and
# the launch Daemon. This helps if someone re-enrolls a machine for some reason.
if [ -f "${setupDone}" ]; then
	# Remove the Launch Daemon
	/bin/rm -Rf /Library/LaunchDaemons/com.d65.launch.plist
	# Remove this script
	/bin/rm -- "$0"
	exit 0
fi

# This is where we wait until a user is completely logged in
if pgrep -x "Finder" \
&& pgrep -x "Dock" \
&& [ "$CURRENTUSER" != "_mbsetupuser" ] \
&& [ ! -f "${setupDone}" ]; then

	# Let's caffinate the mac because this can take long
	/usr/bin/caffeinate -d -i -m -u -s &
	caffeinatepid=$!

	# Kill any installer process running
	killall Installer
	# Wait a few seconds
	sleep 5

	# If the computer is NOT in the jss or if it's an BASE-STAFF, ELEMENTARY-STAFF, MAGNET-STAFF, MIDDLE-STAFF machine
	# we want to get user input because most likely this is being reprovisioned.

	if [[ "$jssMacName" == "" ]] || [[ "$jssCohort" == "" ]] || [[ "$jssCohort" == "BASE-STAFF" ]] || [[ "$jssCohort" == "ELEMENTARY-STAFF" ]] || [[ "$jssCohort" == "MAGNET-STAFF" ]] || [[ "$jssCohort" == "MIDDLE-STAFF" ]]; then
		# Configure DEPNotify registration window
		sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify PathToPlistFile /var/tmp/
		sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify RegisterMainTitle "Setup..."
		sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify RegisterButtonLabel Setup
	 	sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify UITextFieldUpperPlaceholder "jeh-t-jappleseed-#####"
		sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify UITextFieldUpperLabel "Computer Name"
		sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify UITextFieldLowerPlaceholder "12345"
		sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify UITextFieldLowerLabel "D65 Asset Tag"
		sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify UIPopUpMenuUpper -array 'Base-Staff' 'Elementary-Staff' 'Magnet-Staff' 'Middle-Staff' 'Base-Student' 'Elementary-Student' 'Magnet-Student' 'Middle-Student' 'Magnet-Student-Media' 'Middle-Student-Media' 'Nichols-Student-Music'
		sudo -u "$CURRENTUSER" defaults write menu.nomad.DEPNotify UIPopUpMenuUpperLabel "Cohort"

		# Configure DEPNotify starting window
		echo "Command: MainTitle: New Mac Setup" >> $DNLOG
		echo "Command: Image: /Library/JAMF D65/d65logo-depnotify.png" >> $DNLOG
		echo "Command: WindowStyle: NotMovable" >> $DNLOG
		echo "Command: DeterminateManual: 5" >> $DNLOG

		# Open DepNotify fullscreen
	  sudo -u "$CURRENTUSER" /Applications/Utilities/DEPNotify.app/Contents/MacOS/DEPNotify -fullScreen &
		echo "Command: MainText: Make sure this Mac is plugged into a wired network connection before beginning. \n \n \
		Enter the computer name in the \"Computer Name\" field." >> $DNLOG

	  # get user input...
	  echo "Command: ContinueButtonRegister: Begin" >> $DNLOG
	  echo "Status: Please click the button below..." >> $DNLOG
	  DNPLIST=/var/tmp/DEPNotify.plist
	  # hold here until the user enters something
	  while : ; do
	  	[[ -f $DNPLIST ]] && break
	  	sleep 1
	  done
		# Let's read the user data into some variables...
		computerName=$(/usr/libexec/plistbuddy $DNPLIST -c "print 'Computer Name'")
		cohort=$(/usr/libexec/plistbuddy $DNPLIST -c "print 'Cohort'" | tr [a-z] [A-Z])
		ASSETTAG=$(/usr/libexec/plistbuddy $DNPLIST -c "print 'D65 Asset Tag'")
		
		echo "Status: Setting computer name..." >> $DNLOG
		scutil --set HostName "$computerName"
		scutil --set LocalHostName "$computerName"
		scutil --set ComputerName "$computerName"

	else
		# This is if the machine is already found on the server
		# Set variables for Computer Name and Role to those from the receipts
		computerName=$jssMacName
		cohort=$jssCohort
		
		# Launch DEPNotify
		echo "Command: Image: /Library/JAMF D65/d65logo-depnotify.png" >> $DNLOG
		echo "Command: MainTitle: Setting things up..."  >> $DNLOG
		echo "Command: WindowStyle: NotMovable" >> $DNLOG
		echo "Command: DeterminateManual: 4" >> $DNLOG
		sudo -u "$CURRENTUSER" /Applications/Utilities/DEPNotify.app/Contents/MacOS/DEPNotify -fullScreen &
		echo "Status: Please wait..." >> $DNLOG
		
		echo "Setting computer name, host name and local host name..."
		scutil --set HostName "$computerName"
		scutil --set LocalHostName "$computerName"
		scutil --set ComputerName "$computerName"
		
	fi # End of "is this a known or unknown machine" section..this is the merge

	# Carry on with the setup...
	# This is where we do everything else...
	
	# Setting the variable for the assigned user. This user will get assigned in the JSS only for staff computers
		assignedUser=`scutil --get ComputerName | awk 'BEGIN {FS="-"} END {print $3}'`
	# Since we have a different naming convention for Staff machines and we need to set the "User" info in the jss
	# we're going to break down the naming of the system by cohort here.
	echo "Command: DeterminateManualStep:" >> $DNLOG
	if [[ "$cohort" == "BASE-STAFF" ]] || [[ "$cohort" == "ELEMENTARY-STAFF" ]] || [[ "$cohort" == "MAGNET-STAFF" ]] || [[ "$cohort" == "MIDDLE-STAFF" ]]; then
		echo "Status: Assigning device..." >> $DNLOG
		$JAMFBIN recon -endUsername $assignedUser
	else
		echo "Status: Setting computer name..." >> $DNLOG
		scutil --set HostName "$computerName"
		scutil --set LocalHostName "$computerName"
		scutil --set ComputerName "$computerName"
	fi

	# The firstRun scripts policies are where we set our receipts on the machines, no need to do them in this script.
	echo "Command: MainTitle: $computerName"  >> $DNLOG
	echo "Status: Running FirstRun scripts and installing packages..." >> $DNLOG
	echo "Command: DeterminateManualStep:" >> $DNLOG
	echo "Command: MainText: This Mac is installing all necessary software and running some installation scripts.  \
Please do not interrupt this process. This may take a while to complete; the machine restarts \
automatically when it's finished. \n \n Cohort: $cohort \n \n macOS Version: $OSVERSION"  >> $DNLOG

		$JAMFBIN policy -event install-"$cohort"-software
		$JAMFBIN policy -event enroll-firstRun-scripts

	echo "Command: DeterminateManualStep:" >> $DNLOG
	echo "Status: Updating Inventory..." >> $DNLOG
		$JAMFBIN recon
		# Let's set the asset tag in the JSS
		$JAMFBIN recon -assetTag $ASSETTAG

	echo "Command: DeterminateManualStep:" >> $DNLOG
	echo "Status: Cleaning up files and restarting system..." >> $DNLOG
  kill $caffeinatepid
  echo "Command: RestartNow:" >>  $DNLOG

  # Remove DEPNotify logs but not the App
  /bin/rm -Rf $DNLOG
  /bin/rm -Rf $DNPLIST

	# Wait a few seconds
	sleep 5
	# Remove the autologin user password file so it doesn't login again
	/bin/rm -Rf /etc/kcpassword
	# Remote autologin DEP user, remove from admin group and delete User home folder
	dscl . delete /Users/dep
	dseditgroup -o edit -d dep -t user admin
	rm -rf /Users/dep
	# Create a bom file that allow this script to stop launching DEPNotify after done
	/usr/bin/touch /var/db/receipts/com.d65.provisioning.done.bom
	# Remove the Launch Daemon
	/bin/rm -Rf /Library/LaunchDaemons/com.d65.launch.plist
	# Remove this script
	/bin/rm -- "$0"
	
fi
exit 0
