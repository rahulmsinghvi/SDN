#!/bin/bash

for (( i=1; i<=$#; i++ ));
do
	case ${!i} in
		-RUN_DATE)
			((i=i+1))
			run_date=${!i}
			;;
			
		-DEST_DZONE_DIR)
			((i=i+1))
			dropzone_dir_path=${!i}
			;;
			
		*) 
			echo "ERROR: unexpected command line argument ${!i}"
			echo "Usage: $(basename $0) -RUN_DATE <YYYYMMDD> -DEST_DZONE_DIR </path/to/dropzone/dir>"
			exit 1 
			;;
	esac
done

if [[ $# -lt 4 ]]; then
	echo "ERROR: unexpected command line argument ${!i}"
	echo "Usage: $(basename $0) -RUN_DATE <YYYYMMDD>"
	exit 1
fi

##############################################################################
#Declaring variables and path
##############################################################################
dropzone_user="pp_adm"
dropzone_server_name="dropzone.paypalcorp.com"
indicator_file_processed="IND_$run_date.txt.processed"
result_files="scanresult*"
ingest_dir_path="/x/home/pp_dt_cmpln_batch/sdn/outbound"
ingest_server_name=$(hostname -f)
date=$(date +%Y%m%d%H%M%S)
log_file="/x/home/pp_adm/log/send_result_files_to_dropzone_from_ingest_$date.log"

echo "" >> $log_file 2>&1  
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
echo "+Variables                                           +" >> $log_file 2>&1
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
echo "Ingest directory path   : $ingest_server_name:$ingest_dir_path" >> $log_file 2>&1
echo "Dropzone directory path : $dropzone_user@$dropzone_dir_path/" >> $log_file 2>&1
echo "Indicator file name     : $indicator_file_processed" >> $log_file 2>&1
echo "" >> $log_file 2>&1

echo "" >> $log_file 2>&1  
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
echo "+Copying file from Ingest to dropzone                  +" >> $log_file 2>&1
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
echo "" >> $log_file 2>&1  

cmd=$(sftp $dropzone_user@$dropzone_server_name:$dropzone_dir_path/$indicator_file_processed >> $log_file 2>&1)
if [[ $? -eq 0 ]]; then
	echo "Destination file already exists at $dropzone_server_name:$dropzone_dir_path/" >> $log_file 2>&1
	echo "++++++++++++++++++++++ ABORTING ++++++++++++++++++++++" >> $log_file 2>&1
	exit 1
else	
	echo "Performing copy operation" >> $log_file 2>&1
	scp $ingest_dir_path/{$result_files,$indicator_file_processed} $dropzone_user@$dropzone_server_name:$dropzone_dir_path/ >> $log_file 2>&1
	if [[ $? -eq 0 ]]
	then
		echo "File transfer from $ingest_server_name to $dropzone_server_name is successful!!!" >> $log_file 2>&1	
		rm -f $ingest_dir_path/$result_files $ingest_dir_path/$indicator_file_processed  >> $log_file 2>&1
		if [[ $? -eq 0 ]]
		then
			echo "Files are deleted from the $ingest_server_name:$ingest_dir_path/" >> $log_file 2>&1
		else
			echo "Files deletion failed in $ingest_server_name:$ingest_dir_path/" >> $log_file 2>&1
		fi
	else
		echo "File transfer from $ingest_server_name to $dropzone_server_name is +++ failed +++" >> $log_file 2>&1
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
		exit 1
	fi
fi