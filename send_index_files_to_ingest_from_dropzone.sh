#!/bin/bash

#. /x/home/pp_adm/.dwProfile_ppadm

for (( i=1; i<=$#; i++ ));
do
	case ${!i} in
		-RUN_DATE)
			((i=i+1))
			run_date=${!i}
			;;
			
		-SRC_DZONE_DIR)
			((i=i+1))
			dropzone_dir_path=${!i}
			;;		
		*) 
			echo "ERROR: unexpected command line argument ${!i}"
			echo "Usage: $(basename $0) -RUN_DATE <YYYYMMDD> -SRC_DZONE_DIR </path/to/dropzone/directory>"
			exit 1 
			;;
	esac
done

if [[ $# -lt 4 ]]; then
	echo "ERROR: unexpected command line argument ${!i}"
	echo "Usage: $(basename $0) -RUN_DATE <YYYYMMDD> -SRC_DZONE_DIR </path/to/dropzone/directory>"
	exit 1
fi

##############################################################################
#Declaring variables and path
##############################################################################
dropzone_user="pp_adm"   
exit_flag=0
incremental_wait=0
dropzone_server_name="dropzone.paypalcorp.com"
indicator_file="ScanningArchive_Index_$run_date.txt"
index_file="ScanningArchive.tar.gz"
ingest_dir_path="/x/home/pp_adm/outbound"
ingest_server_name=$(hostname -f)
date=$(date +%Y%m%d%H%M%S)
log_file="/x/home/pp_adm/log/send_index_files_to_ingest_from_dropzone_$date.log"

echo "" >> $log_file 2>&1  
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
echo "+Variables                                           +" >> $log_file 2>&1
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
echo "Ingest directory path: $ingest_server_name:$ingest_dir_path" >> $log_file 2>&1
echo "Dropzone             : $dropzone_server_name:$dropzone_dir_path/" >> $log_file 2>&1
echo "Indicator file name  : $indicator_file" >> $log_file 2>&1
echo "Index file name      : $index_file" >> $log_file 2>&1
echo "" >> $log_file 2>&1

#Checking 
while [[ $exit_flag -eq 0 ]]
do
	cmd=$(sftp $dropzone_user@$dropzone_server_name:$dropzone_dir_path/$indicator_file) >> $log_file 2>&1
	if [[ $? -eq 0 ]]; then
		echo "File verification successful in Dropzone, proceeding with file copying operation" >> $log_file 2>&1
		exit_flag=1
	else
		echo "Index files aren't placed in Dropzone path: $dropzone_dir_path/, waiting for file to be generated" >> $log_file 2>&1
		echo "Index files aren't placed in Dropzone path: $dropzone_dir_path/, waiting for 30m for file to be generated"
		incremental_wait=`expr $incremental_wait + 1`
		if [[ $incremental_wait -eq 12 ]]; then
			echo "incremental_wait=12 and no SUCCESS FILE from DROPZONE for $RUN_DATE" >> $log_file 2>&1
			echo "++++++++++++++++++++++ ABORTING ++++++++++++++++++++++" >> $log_file 2>&1
			exit 1
		fi
		sleep 30m
	fi
done

echo "" >> $log_file 2>&1  
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
echo "+Copying file from Dropzone Ingest                   +" >> $log_file 2>&1
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
echo "" >> $log_file 2>&1  

if test -f $ingest_dir_path/$indicator_file; then
	echo "Destination file already exists at $ingest_server_name:$ingest_dir_path/" >> $log_file 2>&1
	echo "++++++++++++++++++++++ ABORTING ++++++++++++++++++++++" >> $log_file 2>&1
	exit 1
else
	echo "Creating destination directory $ingest_server_name:$ingest_dir_path, if it does not exist" >> $log_file 2>&1
	mkdir -p $ingest_dir_path >> $log_file 2>&1
	echo "Performing copy operation" >> $log_file 2>&1
	scp $dropzone_user@$dropzone_server_name:$dropzone_dir_path/{$index_file,$indicator_file} $ingest_dir_path/ && chmod 775 $ingest_dir_path/{$index_file,$indicator_file} >> $log_file 2>&1
	if [[ $? -eq 0 ]]
	then
		echo "File transfer from $dropzone_server_name to $ingest_server_name is successful!!!" >> $log_file 2>&1	
		echo "+++++++++++++++++ File is copied for the next task in Ingest server +++++++++++++++++" >> $log_file 2>&1
	else
		echo "File transfer from $dropzone_server_name to $ingest_server_name is ++++++++ failed ++++++++" >> $log_file 2>&1
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
		exit 1
	fi
fi