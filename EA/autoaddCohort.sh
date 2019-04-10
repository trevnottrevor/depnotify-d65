#!/bin/bash
#
# Adapted for District 65 by Trev Kelderman for use with DEPNotify.
# 
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: autoAddCohort.sh
#
# Purpose: This script will add our dummy receipts (which are called cohorts) based on the D65 Building and Computer name.


# Creation functions for each cohort
base_staff () {
	echo "BASE-STAFF" > /Library/JAMF\ D65/Cohort/RECEIPT-BASE-STAFF.txt
}

elementary_staff () {
	echo "ELEMENTARY-STAFF" > /Library/JAMF\ D65/Cohort/RECEIPT-ELEMENTARY-STAFF.txt
}

magnet_staff () {
	echo "MAGNET-STAFF" > /Library/JAMF\ D65/Cohort/RECEIPT-MAGNET-STAFF.txt
}

middle_staff () {
	echo "MIDDLE-STAFF" > /Library/JAMF\ D65/Cohort/RECEIPT-MIDDLE-STAFF.txt
}

base_student () {
	echo "BASE-STUDENT" > /Library/JAMF\ D65/Cohort/RECEIPT-BASE-STUDENT.txt
}

elementary_student () {
	echo "ELEMENTARY-STUDENT" > /Library/JAMF\ D65/Cohort/RECEIPT-ELEMENTARY-STUDENT.txt
}

magnet_student () {
	echo "MAGNET-STUDENT" > /Library/JAMF\ D65/Cohort/RECEIPT-MAGNET-STUDENT.txt
}

middle_student () {
	echo "MIDDLE-STUDENT" > /Library/JAMF\ D65/Cohort/RECEIPT-MIDDLE-STUDENT.txt
}

magnet_student_media () {
	echo "MAGNET-STUDENT-MEDIA" > /Library/JAMF\ D65/Cohort/RECEIPT-MAGNET-STUDENT-MEDIA.txt
}

middle_student_media () {
	echo "MIDDLE-STUDENT-MEDIA" > /Library/JAMF\ D65/Cohort/RECEIPT-MIDDLE-STUDENT-MEDIA.txt
}

nichols_student_music () {
	echo "NICHOLS-STUDENT-MUSIC" > /Library/JAMF\ D65/Cohort/RECEIPT-NICHOLS-STUDENT-MUSIC.txt
}

# Get Building Code and Role from ComputerName
buildingRole=`scutil --get ComputerName | awk 'BEGIN {FS="-"} END {print $1$2}'`
cartOrmediaOrmusic=`scutil --get ComputerName | awk 'BEGIN {FS="-"} END {print $3}'`

# Arrays for all of our different types of computers
baseStaff=(jeha jeca ject paa pat ria rit)
elementaryStaff=(daa dat dea det kga kgt lia lit lwa lwt oaa oat ora ort waa wat wha wht wia wit)
magnetStaff=(jeht bra brt kla klt)
middleStaff=(cha cht haa hat nia nit)
baseStudent=(jehs jecs pas ris)
elementaryStudent=(das des kgs lis lws oas ors was whs wis)
magnetStudent=(brs kls)
middleStudent=(chs has nis)
cartStudent=(cart01 cart02 cart03 cart04)
mediaLab=(media)
musicLab=(music)

# Make "JAMF D65" directory and hide it
mkdir /Library/JAMF\ D65
mkdir /Library/JAMF\ D65/Cohort
chflags hidden /Library/JAMF\ D65

# Automatically choose the appropriate Cohort based on D65 Building and computer name.
if [[ " ${baseStaff[@]} " =~ " ${buildingRole} " ]]; then
	base_staff

elif [[ " ${elementaryStaff[@]} " =~ " ${buildingRole} " ]]; then
	elementary_staff

elif [[ " ${magnetStaff[@]} " =~ " ${buildingRole} " ]]; then
	magnet_staff

elif [[ " ${middleStaff[@]} " =~ " ${buildingRole} " ]]; then
	middle_staff

elif [[ " ${baseStudent[@]} " =~ " ${buildingRole} " ]]; then
	base_student

elif [[ " ${elementaryStudent[@]} " =~ " ${buildingRole} " ]]; then
	elementary_student

elif [[ " ${magnetStudent[@]} " =~ " ${buildingRole} " ]] && [[ " ${cartStudent[@]} " =~ " ${cartOrmediaOrmusic} " ]]; then
	magnet_student

elif [[ " ${middleStudent[@]} " =~ " ${buildingRole} " ]] && [[ " ${cartStudent[@]} " =~ " ${cartOrmediaOrmusic} " ]]; then
	middle_student

elif [[ " ${magnetStudent[@]} " =~ " ${buildingRole} " ]] && [[ " ${mediaLab[@]} " =~ " ${cartOrmediaOrmusic} " ]]; then
	magnet_student_media

elif [[ " ${middleStudent[@]} " =~ " ${buildingRole} " ]] && [[ " ${mediaLab[@]} " =~ " ${cartOrmediaOrmusic} " ]]; then
	middle_student_media

elif [[ " ${middleStudent[@]} " =~ " ${buildingRole} " ]] && [[ " ${musicLab[@]} " =~ " ${cartOrmediaOrmusic} " ]]; then
	nichols_student_music

else
	echo "$buildingRole does not match any District 65 locations. Adding generic D65COMPUTER cohort."
	echo "D65-COMPUTER" > /Library/JAMF\ D65/Cohort/RECEIPT-D65-COMPUTER.txt
	exit 1

fi
