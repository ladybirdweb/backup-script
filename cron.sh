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

blue=$(tput setaf 14)

reset=$(tput sgr0)

# Banner.
echo -e "																									"
echo -e "																									"
sleep 0.1
echo -e "$blue						██████╗  █████╗  ██████╗██╗  ██╗██╗   ██╗██████╗     ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗				  		$reset"
sleep 0.1
echo -e "$blue						██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██║   ██║██╔══██╗    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝				  		$reset"
sleep 0.1
echo -e "$blue						██████╔╝███████║██║     █████╔╝ ██║   ██║██████╔╝    ███████╗██║     ██████╔╝██║██████╔╝   ██║					  		$reset"
sleep 0.1
echo -e "$blue						██╔══██╗██╔══██║██║     ██╔═██╗ ██║   ██║██╔═══╝     ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║					  		$reset"
sleep 0.1
echo -e "$blue						██████╔╝██║  ██║╚██████╗██║  ██╗╚██████╔╝██║         ███████║╚██████╗██║  ██║██║██║        ██║					  		$reset"
sleep 0.1
echo -e "$blue						╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝         ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝					  		$reset"
sleep 0.1
echo -e "																									"



# Detect Debian users running the script with "sh" instead of bash.
    
echo -e " ";
if readlink /proc/$$/exe | grep -q "dash"; then
	echo "&red This installer needs to be run with 'bash', not 'sh'. $reset";
	exit 1
fi

# Checking for the Super User.
    
echo -e " ";
if [[ $EUID -ne 0 ]]; then
   echo -e "$red This script must be run as root $reset";
   exit 1
fi

# FUNCTION TO ADD OR REMOVE THE CORN JOB

function add_or_remove_cron() {
    echo -e "$yellow Do you want to add or remove the cron job? Enter 'add' or 'remove': $reset"
    read -r choice
	sleep 0.5
	echo -e " 																														"

    if [[ "$choice" == "add" ]]; then
        echo -e "$yellow Have you added the required details to the python script? Enter 'yes' or 'no': $reset"
        read -r confirmation
		sleep 0.5 

        if [[ "$confirmation" == "no" ]]; then
            echo -e "$red Please add the required details to the python script and re-run the script. $reset"
            return
        fi
        
        # PROMPT THE USER FOR THE SCRIPT DIRECTORY
		echo -e "$yellow Enter the directory path for the scripts (to get this directory use 'pwd' command): $reset"
		read -r script_dir

		#CREATING LOG FILE:
		touch $script_dir/backup.log
	
		# PROMPT THE USER FOR THE CRON INTERVAL
		echo "$yellow Select the cron interval: $reset"
		echo "$yellow 1. Daily $reset"  #THIS CRON IS FOR EVERYDAY
		echo "$yellow 2. Weekly $reset"  #THIS CRON IS FOR EVERY WEEK AT SPECIFIED DAY IN THE BELOW INTERVAL CHOICE
		echo "$yellow 3. Monthly $reset"  #THIS CRON IS FOR EVERY MONTH AT SPECIFIED DATE IN THE BELOW INTERVAL CHOICE
		read -r interval_choice

		# DETERMINE THE INTERVAL BASED ON USERS CHOICE
		if [ "$interval_choice" = "1" ]; then
		    interval="* * *"  #THIS CRON IS FOR EVERYDAY
		elif [ "$interval_choice" = "2" ]; then
		    interval="* * 0"  #THIS CRON IS FOR SUNDAY OF EVERY WEEK YOU CAN CHANGE BY 0-6 AS SUNDAY TO SATURDAY
		elif [ "$interval_choice" = "3" ]; then
		    interval="1 * *"  #THIS CRON IS FOR FIRST OF THE MONTH THIS CAN BE CHNAGED T0 1-31 ACCORDING TO THE DATE
		else
		    echo "$red Invalid selection. Please select a valid option. $reset"
		    return
		fi

		#PROMPT THE USER FOR COSTUM CRON TIME THE DETFAULT IS SET TO MIDNIGHT
		echo "$yellow Enter the time of day to run the cron job (in 24-hour format, e.g. 23:30) or press Enter to use the default time of midnight: $reset"
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

		# PROMPT USER FOR SCP OR FTP INCASE OF REMOTE:

		function remote_ftp_or_scp {

			if [[ $REPLY1 = @(C|c) ]]; then 
 	       		(crontab -l 2>/dev/null; echo "${cron_time} ${interval} python3 ${script_dir}/mainscp.py >> ${script_dir}/backup.log 2>&1") | crontab - 
				echo -e "$green Cronjob ser up successfully. $reset"
            elif [[ $REPLY1 =  @(D|d) ]]; then 
                (crontab -l 2>/dev/null; echo "${cron_time} ${interval} python3 ${script_dir}/mainftp.py >> ${script_dir}/backup.log 2>&1") | crontab -
    	        echo -e "$green Cronjob ser up successfully. $reset" 
            else  
                echo -e "$red Invalid choice. Please enter 'A' or 'B'. $reset"
                remote_ftp_or_scp
			fi
		}

		function remote_or_local {

		# PROMPT THE USER FOR LOCAL OR REMOTE BACKUPS
		echo -e "$yellow Do you want to store the backup Locally or to Remote storage: Please select (A) for Remote and (B) for Local $reset"
		read -p "$yellow Option (Remote:A / Local: B) $reset" REPLY
    	if [[ $REPLY = @(A|a) ]]; then
		# SET UP THE CRON JOB TO RUN THE SCRIPT AT THE SPECIFIED TIME AND INTERVAL
			echo -e "$yellow Select SCP or FTP to upload the files to remote storage. $reset"
			read -p "$yellow (SCP:C / FTP:D) $reset" REPLY1
			remote_ftp_or_scp
    	elif [[ $REPLY = @(B|b) ]]; then
		# SET UP THE CRON JOB TO RUN THE SCRIPT AT THE SPECIFIED TIME AND INTERVAL
			(crontab -l 2>/dev/null; echo "${cron_time} ${interval} python3 ${script_dir}/mainlocal.py >> ${script_dir}/backup.log 2>&1") | crontab -
			echo -e "$green Cron job set up successfully. $reset"
		else 
			echo -e "$red Invalid choice. Please enter 'A' or 'B'. $reset"
			remote_or_local
		fi
		}
		remote_or_local
    
	elif [[ "$choice" == "remove" ]]; then
    	# CODE TO REMOVE CRON JOB
		crontab -l | grep -v "mainscp.py" | crontab -
		crontab -l | grep -v "mainftp.py" | crontab -
		crontab -l | grep -v "mainlocal.py" | crontab -
        echo -e "$green Cron job removed! $reset"
    else
        echo -e "$red Invalid choice. Please enter 'add' or 'remove'. $reset"
        add_or_remove_cron
    fi
}

add_or_remove_cron