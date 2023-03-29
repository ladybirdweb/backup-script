#!/bin/bash
##---------- Author : Thirumoorthi Duraipandi------------------------------------------------##
##---------- Email : thirumoorthi.duraipandi@ladybirdweb.com---------------------------------##
##---------- Github page : https://github.com/ladybirdweb/backup-script/---------------------##
##---------- Purpose : Auto Backup and upload for  Faveo Helpdesk in a linux system.---------##
##---------- Tested on : RHEL9/8/7, Rocky 9/8, Ubuntu22/20/18, CentOS 9 Stream, Debian 11----## 
##---------- Initial version : v1.0 (Updated on 2nd Dec 2022) -------------------------------##
##-----NOTE: This script requires root privileges, otherwise one could run the script -------##
##---------- as a sudo user who got root privileges. ----------------------------------------##
##----USAGE: "sudo /bin/bash cron.sh" -------------------------------------------------------##

# Colour variables for the script.

red=$(tput setaf 1)

green=$(tput setaf 2)

yellow=$(tput setaf 11)

skyblue=$(tput setaf 14)

reset=$(tput sgr0)

# Faveo Banner.

echo -e "$skyblue                                                                                                                         $reset";
sleep 0.05
echo -e "$skyblue                                        _______ _______ _     _ _______ _______                                          $reset";
sleep 0.05
echo -e "$skyblue                                       (_______|_______|_)   (_|_______|_______)                                         $reset";
sleep 0.05
echo -e "$skyblue                                        _____   _______ _     _ _____   _     _                                          $reset";
sleep 0.05
echo -e "$skyblue                                       |  ___) |  ___  | |   | |  ___) | |   | |                                         $reset";
sleep 0.05
echo -e "$skyblue                                       | |     | |   | |\ \ / /| |_____| |___| |                                         $reset";
sleep 0.05
echo -e "$skyblue                                       |_|     |_|   |_| \___/ |_______)\_____/                                          $reset";
sleep 0.05
echo -e "$skyblue                                                                                                                         $reset";
sleep 0.05
echo -e "$skyblue                               _     _ _______ _       ______ ______  _______  ______ _     _                            $reset";
sleep 0.05
echo -e "$skyblue                             (_)   (_|_______|_)     (_____ (______)(_______)/ _____|_)   | |                            $reset";
sleep 0.05
echo -e "$skyblue                              _______ _____   _       _____) )     _ _____  ( (____  _____| |                            $reset";
sleep 0.05
echo -e "$skyblue                             |  ___  |  ___) | |     |  ____/ |   | |  ___)  \____ \|  _   _)                            $reset";
sleep 0.05
echo -e "$skyblue                             | |   | | |_____| |_____| |    | |__/ /| |_____ _____) ) |  \ \                             $reset";
sleep 0.05
echo -e "$skyblue                             |_|   |_|_______)_______)_|    |_____/ |_______|______/|_|   \_)                            $reset";
sleep 0.05
echo -e "$skyblue                                                                                                                         $reset";
sleep 0.05
echo -e "$skyblue                                                                                                                         $reset";


# FUNCTION TO ADD OR REMOVE THE CORN JOB

function add_or_remove_cron() {
    echo -e "$yellow Do you want to add or remove the cron job? Enter 'add' or 'remove': $reset"
    read -r choice
	sleep 0.5
	echo -e " 																														"

    if [[ "$choice" == "add" ]]; then
        echo -e "$yellow Have you added the required details to the backup-automated-details.sh script? Enter 'yes' or 'no': $reset"
        read -r confirmation
		sleep 0.5 

        if [[ "$confirmation" == "no" ]]; then
            echo -e "$red Please add the required details to the backup-automated-details.sh script and re-run the script. $reset"
            return
        fi
        
        # PROMPT THE USER FOR THE SCRIPT DIRECTORY
	echo -e "$yellow Enter the directory path for the scripts (to get this directory use 'pwd' command): $reset"
	read -r script_dir

	#CREATING LOG FILE:
	touch $script_dir/backup.log
	
	# PROMPT THE USER FOR THE CRON INTERVAL
	echo "Select the cron interval:"
	echo "1. Daily"  #THIS CRON IS FOR EVERYDAY
	echo "2. Weekly"  #THIS CRON IS FOR EVERY WEEK AT SPECIFIED DAY IN THE BELOW INTERVAL CHOICE
	echo "3. Monthly"  #THIS CRON IS FOR EVERY MONTH AT SPECIFIED DATE IN THE BELOW INTERVAL CHOICE
	read -r interval_choice

	# DETERMINE THE INTERVAL BASED ON USERS CHOICE
	if [ "$interval_choice" = "1" ]; then
	    interval="* * *"  #THIS CRON IS FOR EVERYDAY
	elif [ "$interval_choice" = "2" ]; then
	    interval="* * 0"  #THIS CRON IS FOR SUNDAY OF EVERY WEEK YOU CAN CHANGE BY 0-6 AS SUNDAY TO SATURDAY
	elif [ "$interval_choice" = "3" ]; then
	    interval="1 * *"  #THIS CRON IS FOR FIRST OF THE MONTH THIS CAN BE CHNAGED T0 1-31 ACCORDING TO THE DATE
	else
	    echo "Invalid selection. Please select a valid option."
	    return
	fi
	
	# PROMPT THE USER FOR COSTUM CRON TIME THE DETFAULT IS SET TO MIDNIGHT
	echo "Enter the time of day to run the cron job (in 24-hour format, e.g. 23:30) or press Enter to use the default time of midnight:"
	read -r time_input

	if [ -z "$time_input" ]; then
	    cron_time="0 0" # DEFAULT TIME AS MIDNIGHT
	else
	    # CONVERT THE USER INPUT TO CRON TIME FORMAT
	    if [[ "$time_input" =~ ^([01]?[0-9]|2[0-3]):([0-5][0-9])$ ]]; then
	        cron_time="${BASH_REMATCH[2]} ${BASH_REMATCH[1]}"
	    else
	        echo "Invalid time format. Please enter the time in 24-hour format, e.g. 23:30"
	        return
	    fi
	fi
	
	# SET UP THE CRON JOB TO RUN THE SCRIPT AT THE SPECIFIED TIME AND INTERVAL
	(crontab -l 2>/dev/null; echo "${cron_time} ${interval} python3 ${script_dir}/main.py >> ${script_dir}/backup.log 2>&1") | crontab -
	
	echo -e "$green Cron job set up successfully. $reset"


    elif [[ "$choice" == "remove" ]]; then

        # CODE TO REMOVE CRON JOB
	crontab -l | grep -v "main.py" | crontab -
        echo -e "$green Cron job removed! $reset"
    else
        echo -e "$red Invalid choice. Please enter 'add' or 'remove'. $reset"
        add_or_remove_cron
    fi
}

add_or_remove_cron