#!/bin/bash

for (( i=1; i<=$#; i++ ));
do
	case ${!i} in
		-RUN_DATE)
			((i=i+1))
			run_date=${!i}
			;;
			
		-SRC_HDP_ENV)
			((i=i+1))
			hadoop_env=${!i}
			;;
			
		-SRC_HDFS_DIR)
			((i=i+1))
			hadoop_hdfs_dir_path=${!i}
			;;
		*) 
			echo "ERROR: unexpected command line argument ${!i}"
			echo "Usage: $(basename $0) -RUN_DATE <YYYYMMDD> -SRC_HDP_ENV <horton|stampy> -SRC_HDFS_DIR </path/to/hdfs/dir>"
			exit 1 
			;;
	esac
done

if [[ $# -lt 6 ]]; then
	echo "ERROR: unexpected command line argument ${!i}"
	echo "Usage: $(basename $0) -RUN_DATE <YYYYMMDD> -SRC_HDP_ENV <horton|stampy> -SRC_HDFS_DIR </path/to/hdfs/dir>"
	exit 1 
fi

##############################################################################
#Declaring variables and path
##############################################################################
result_files="scanresult*"
indicator_file="IND_$run_date.txt"
indicator_file_processed="$indicator_file.processed"
ingest_dir_path="/x/home/pp_dt_cmpln_batch/sdn/outbound"
ingest_server_name=$(hostname -f)
date=$(date +%Y%m%d%H%M%S)
log_file="/x/home/pp_dt_cmpln_batch/sdn/scripts/send_result_files_to_ingest_from_hdfs_$date.log"

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
echo "" >> $log_file 2>&1

#Checking 
while [[ exit_flag -eq 0 ]]
do
	cmd=$(hadoop fs -ls $hadoop_hdfs_dir_path/{$result_files,$indicator_file} >> $log_file 2>&1)
	if [[ $? -eq 0 ]]; then
		echo "File verification successful in Hadoop, proceeding with file copying operation" >> $log_file 2>&1
		exit_flag=1
	else
		echo "Result files aren't placed in Hadoop path: $hadoop_hdfs_dir_path/, waiting for file to be generated" >> $log_file 2>&1
		echo "Result files aren't placed in Hadoop path: $hadoop_hdfs_dir_path/, waiting for file to be generated"
		incremental_wait=`expr $incremental_wait + 1`
		if [[ $incremental_wait -eq 12 ]]; then
			echo "incremental_wait=12 and no SUCCESS FILE from Hadoop for $run_date" >> $log_file 2>&1
			echo "++++++++++++++++++++++ ABORTING ++++++++++++++++++++++" >> $log_file 2>&1
			exit 1
		fi
		sleep 30m
	fi
done

echo "" >> $log_file 2>&1
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
echo "+Copying file from Hadoop to Ingest                  +" >> $log_file 2>&1
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
echo "" >> $log_file 2>&1  

if test -f $ingest_dir_path/$indicator_file_processed; then
	echo "Destination file already exists at $ingest_server_name:$ingest_dir_path/" >> $log_file 2>&1
	echo "++++++++++++++++++++++ ABORTING ++++++++++++++++++++++" >> $log_file 2>&1
	exit 1
else
	echo "Performing copy operation" >> $log_file 2>&1
	hadoop fs -get $hadoop_hdfs_dir_path/{$result_files,$indicator_file} $ingest_dir_path/ && chmod 755 $ingest_dir_path/{$result_files,$indicator_file} >> $log_file 2>&1
	if [[ $? -eq 0 ]]
	then
		echo "File transfer from $hadoop_env to $ingest_server_name is successful!!!" >> $log_file 2>&1
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
		mv $ingest_dir_path/$indicator_file $ingest_dir_path/$indicator_file_processed >> $log_file 2>&1
		if [[ $? -eq 0 ]]
		then
			echo "++++++++++++++++++++++ Indicator file is created ++++++++++++++++++++++" >> $log_file 2>&1		
		else
			echo "++++++++++++++++++++++ Indicator file creation failed ++++++++++++++++++++++" >> $log_file 2>&1
		fi
	else
		echo "File transfer from $hadoop_env to $ingest_server_name is ++++++++ FAILED ++++++++" >> $log_file 2>&1
		echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $log_file 2>&1
		exit 1
	fi
fi