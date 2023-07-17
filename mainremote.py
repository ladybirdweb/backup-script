#!/usr/bin/env python3

##---------- Author : Thirumoorthi Duraipandi -----------------------------------------------##
##---------- Email : thirumoorthi.duraipandi@ladybirdweb.com --------------------------------##
##---------- Maintained by Ladybird Web Solution Pvt Ltd ------------------------------------##
##---------- Github page : https://github.com/ladybirdweb/backup-script/---------------------##
##---------- Purpose : Auto Backup and upload for  Faveo Helpdesk in a linux system.---------##
##---------- Tested on : RHEL9/8/7, Rocky 9/8, Ubuntu22/20/18, CentOS 9 Stream, Debian 11----## 
##---------- Initial version : v1.0 (Updated on 2nd Dec 2022) -------------------------------##
##-----Note: This script requires root privileges, otherwise one could run the script -------##
##---------- as a sudo user who got root privileges. ----------------------------------------##
##----USAGE: "sudo python3 main.py" ---------------------------------------------------------##

import os
import shutil
import datetime
import subprocess
import paramiko
import time


# Setting the Variables:

# Set the Backup Retention period in days for REMOTE Default 7 days:
BACKUP_RETENTION = 7

# Set the Backup Retention period in days for local Default 5 mins:
LOCAL_BACKUP_RETENTION = 5 / (24 * 60)

# Set the directory you want to store backup files
BACKUP_DIRECTORY = "/path/to/backup/directory"

# Set the directory you want to take backup
BACKUP_SOURCE = "/path/to/directory/to/backup"

# Set the MySQL server credentials
MYSQL_HOST = "localhost" # Default is localhost if you want to use remote host change the value.
MYSQL_PORT = "3306" # Default is 3306 if you want to use different port change the value accordingly.
MYSQL_USER = "database-username"
MYSQL_PASSWORD = "database-password"

# Set the database name you want to backup
DATABASE_NAME = "database-name"

# Set FTP credentials
FTP_HOST = "ftp-hostname"
FTP_PORT = "21" # Default port is 21 if you have different valuse chnage it accordingly.
FTP_USER = "ftp-username"
FTP_PASS = "ftp-password"

# Set remote directory path to upload in FTP
REMOTE_DIR = "/remote/directory/in/ftp/server"

# Set the current date as a variables
CURRENT_DATE = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")


# FILE SYSTEM BACKUP:
def File_System_Backup():
  try:
    # Set the backup file name
    BACKUP_FILE = f"{BACKUP_DIRECTORY}/file_backup_{CURRENT_DATE}.tar.gz"

    # Create the backup directory if it doesn't exist
    os.makedirs(BACKUP_DIRECTORY, exist_ok=True)

    # Create the backup zip file
    shutil.make_archive(BACKUP_FILE[:-7], 'gztar', BACKUP_SOURCE)

    # Print a message indicating the backup is complete
    print(f"Backup of directory {BACKUP_SOURCE} completed at {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    return True

  except Exception as e:
      print(f"Error during File backup: {e}")
      return False


# MYSQL BACKUP:
def MySQL_Backup():

  try:
    # Set the backup file name
    MYSQL_BACKUP_FILE = f"{BACKUP_DIRECTORY}/{DATABASE_NAME}-backup-{CURRENT_DATE}.sql"

    # Dump the database to the backup file
    with open(MYSQL_BACKUP_FILE, 'w') as f:
        subprocess.run(['mysqldump', '-h', MYSQL_HOST, '-P', MYSQL_PORT, '-u', MYSQL_USER, '-p' + MYSQL_PASSWORD, DATABASE_NAME], stdout=f, check=True)

    # Compress the backup file using gzip
    with open(f"{MYSQL_BACKUP_FILE}.tar.gz", 'wb') as f:
        subprocess.run(['tar', '-czf', '-', MYSQL_BACKUP_FILE], stdout=f, check=True)

    # Remove the SQL file
    os.remove(MYSQL_BACKUP_FILE)

    print(f"Backup of MySQL Database {DATABASE_NAME} completed at {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    return True
  except Exception as e:
      print(f"Error during MySQL backup: {e}")
      return False

#SCP UPLOAD & DELETE:
def SCP_Upload():
    try:
        # Create SSH client
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        # Connect to SCP server
        ssh.connect(FTP_HOST, FTP_PORT, FTP_USER, FTP_PASS)

        # Upload files with .gz extension
        for filename in os.listdir(BACKUP_DIRECTORY):
            if filename.endswith(".gz"):
                local_file = os.path.join(BACKUP_DIRECTORY, filename)
                remote_file = os.path.join(REMOTE_DIR, filename)
                scp_client = ssh.open_sftp()
                scp_client.put(local_file, remote_file)
                scp_client.close()
                print(f"Uploaded {local_file} to {remote_file}")

        # Delete old backups
        now = time.time()
        scp_client = ssh.open_sftp()
        scp_client.chdir(REMOTE_DIR)
        for filename in scp_client.listdir():
            file_attr = scp_client.stat(filename)
            file_timestamp = file_attr.st_mtime
            if (now - file_timestamp) > (BACKUP_RETENTION * 24 * 60 * 60):
                print(f"Deleting old backup: {filename}")
                scp_client.remove(filename)
        scp_client.close()

        # Disconnect from the SCP server
        ssh.close()

        return True
    except Exception as e:
        print(f"Error during SCP Upload: {e}")
        return False


# Purge_Old_Backup function
def Purge_Old_Backup():
  try:
    # Change to the ZIP directory
    os.chdir(BACKUP_DIRECTORY)

    # Find ZIP files that are older than the time threshold and delete them
    now = time.time()
    for root, dirs, files in os.walk("."):
        for file in files:
            if file.endswith(".gz"):
                filepath = os.path.join(root, file)
                if os.stat(filepath).st_mtime < now - LOCAL_BACKUP_RETENTION * 86400:
                    os.remove(filepath)
                    with open(LOG_FILE, "a") as f:
                        f.write(f"Deleted {filepath}.\n")

    # Print a message indicating the number of files deleted
    num_deleted = len([name for name in os.listdir(".") if name.endswith(".gz")])
    print(f"Deleted {num_deleted} ZIP files older than {LOCAL_BACKUP_RETENTION} days in {BACKUP_DIRECTORY}.")
    return True
  except Exception as e:
      print(f"Error during Purge: {e}")
      return False


# Execute functions in order and exit if any of them fails
if File_System_Backup() and MySQL_Backup() and SCP_Upload() and Purge_Old_Backup():
    print('All functions executed successfully')
else:
    print('Error: One or more functions failed')
    exit(1)
