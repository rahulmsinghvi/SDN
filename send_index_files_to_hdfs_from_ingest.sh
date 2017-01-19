#!/bin/bash

for (( i=1; i<=$#; i++ ));
do
	case ${!i} in
		-RUN_DATE)
			((i=i+1))
			run_date=${!i}
			;;
			
		-DEST_HDP_ENV)
			((i=i+1))
			hadoop_env=${!i}
			;;
			
		-DEST_HDFS_DIR)
			((i=i+1))
			hadoop_hdfs_dir_path=${!i}
			;;
		*) 
			echo "ERROR: unexpected command line argument ${!i}"
			echo "Usage: $(basename $0) -RUN_DATE <YYYYMMDD> -DEST_HDP_ENV <horton|stampy> -DEST_HDFS_DIR </path/to/hdfs/dir>"
			exit 1 
			;;
	esac
done

if [[ $# -lt 6 ]]; then
	echo "ERROR: unexpected command line argument ${!i}"
	echo "Usage: $(basename $0) -RUN_DATE <YYYYMMDD> -DEST_HDP_ENV <horton|stampy> -DEST_HDFS_DIR </path/to/hdfs/dir>"
	exit 1 
fi

##############################################################################
#Declaring variables and path
##############################################################################
indicator_file="ScanningArchive_Index_$run_date.txt"
index_file="ScanningArchive.tar.gz"
ingest_dir_path="/x/home/pp_adm/outbound"
date=$(date +%Y%m%d%H%M%S)
ingest_server_name=$(hostname -f)
log_file="/x/home/pp_dt_cmpln_batch/sdn/scripts/send_index_files_to_hdfs_from_ingest_$date.log"

##############################################################################
#Source the appropriate system's environment variables
##############################################################################
source /etc/$hadoop_env/env

echo "" >> $log_file 2>&1  
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
echo "+Variables                                           +" >> $log_file 2>&1
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
echo "Ingest directory path: $ingest_server_name:$ingest_dir_path" >> $log_file 2>&1
echo "HDFS file path       : $hadoop_env:$hadoop_hdfs_dir_path/" >> $log_file 2>&1
echo "Indicator file name  : $indicator_file" >> $log_file 2>&1
echo "Index file name      : $index_file" >> $log_file 2>&1
echo "" >> $log_file 2>&1

echo "" >> $log_file 2>&1
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
echo "+Copying file from Ingest to Hadoop                  +" >> $log_file 2>&1
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
echo "" >> $log_file 2>&1  

cmd=$(hadoop fs -ls $hadoop_hdfs_dir_path/$indicator_file >> $log_file 2>&1)
if [[ $? -eq 0 ]]; then
	echo "Destination file already exists at $hadoop_env:$hadoop_hdfs_dir_path/" >> $log_file 2>&1
	echo "++++++++++++++++++++++ ABORTING ++++++++++++++++++++++" >> $log_file 2>&1
	exit 1
else	
	echo "Performing copy operation to HDFS" >> $log_file 2>&1
	hadoop fs -put $ingest_dir_path/$index_file $ingest_dir_path/$indicator_file $hadoop_hdfs_dir_path && hadoop fs -chmod 775 $hadoop_hdfs_dir_path/{$index_file,$indicator_file} >> $log_file 2>&1	
	if [[ $? -eq 0 ]]
	then		
		echo "File transfer from $ingest_server_name to HDFS is successful!!!" >> $log_file 2>&1
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
		rm -f $ingest_dir_path/$index_file $ingest_dir_path/$indicator_file >> $log_file 2>&1
		if [[ $? -eq 0 ]]
		then
			echo "Files are deleted from the $ingest_server_name:$ingest_dir_path/" >> $log_file 2>&1			
		else
			echo "Files deletion failed in $ingest_server_name:$ingest_dir_path/" >> $log_file 2>&1
		fi
	else
		echo "File transfer from $ingest_server_name to $hadoop_env is ++++++++ FAILED ++++++++" >> $log_file 2>&1
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
		exit 1
	fi
fi