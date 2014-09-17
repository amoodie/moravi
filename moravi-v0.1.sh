#!/bin/bash

# to add, the ability to extract files with this tool too. Remove the raw/intermediate datasets.





# This script is to be placed in the directory *above* the one that contains all the extracted data folders.
# All the bulk_downloaded files need to be extracted and placed into the folder named raw_data.
# 
#  n_dir
#     convert.sh
#     raw_data	
#	 lat_lon_int_v_bil
#           lat_lon_int_v.bil
#	    lat_lon_int_v.blw
#	    lat_lon_int_v.hdr
#	    lat_lon_int_v.prj


#
# make the needed directories
#
	mkdir -p ./data
	mkdir -p ./raw_data
	mkdir -p ./grd_files
#
# extract from download dir
#

#
# extract just the .bil files
#
	data_loc=./raw_data
	cp ./${data_loc}/**/*.bil ./data

#
# convert files to .grd format and rename them
#
	for file in ./data/*
		do
		#
		# deal with parsing the lat
		#
		    lat_raw=$(echo $file | awk -F "_" '{print $1}')
		    lat_str=$(echo $lat_raw | awk -F "/" '{print $3}')
		    lat_dir=${lat_str:0:1}
		    if [ "$lat_dir" = "n" ]
		    	then
			lat_l=${lat_str:1:3}
		    elif [ "$lat_dir" = "s" ]
		    	then
			lat_l=$((${lat_str:1:3} * -1))
		    else
			echo "error in latitude reading"
		    fi
		    lat_r=$(($lat_l + 1))
		    echo "lat is " $lat_l " to " $lat_r
		#
		# deal with parsing the lon
		#
		    lon_raw=$(echo $file | awk -F "_" '{print $2}')
		    lon_str=${lon_raw:0:4}
		    lon_dir=${lon_raw:0:1}
		    if [ "$lon_dir" = "e" ]
		    	then
			lon_l=${lon_raw:1:4}
		    elif [ "$lon_dir" = "w" ]
		    	then
			lon_l=$((${lon_raw:1:4} * -1))
		    else
			echo "error in longitude reading"
		    fi
		    lon_r=$(($lon_l + 1))
		    echo "lon is " $lon_l " to " $lon_r
		#
		# deal with getting the grid spacing
		#
		    grd_spc_raw=$(echo $file | awk -F "_" '{print $3}')
		    grd_spc=${grd_spc_raw:0:1}
		    if [ "$grd_spc" = "3" ]
		    	then
			echo "grid spacing is 3 arc second . . . good."
		    else
		  	echo "error in grid spacing . . . program only calibrated for arc seconds."
			echo "If in arc-seconds, results may be fine, but other units will need troubleshooting in the code."
			echo "See line 75ish on grid spacing"
		    fi
		    echo $lon_r
		#
		# begin processing data
		#
		    xyz2grd $file -G./grd_files/${lat_str}${lon_str}.grd -R${lon_l}/${lon_r}/${lat_l}/${lat_r} \
		    -N-9999 -ZTLhw -I${grd_spc}c -V
	done


#
# sort grid files into folders of rows and prep for grdpaste
#
	# begin by sorting into folders by row
	#echo "Sorting files, may take some time . . ."
	for i in `seq 0 99`
		do
			echo "check " $i			
			for file in ./grd_files/*
				do
				lat_raw=$(echo $file | awk -F "/" '{print $3}')
				lat_num=${lat_raw:0:3}		
				if [ "$lat_num" = "n${i}" ]
					then
					mkdir -p ./grd_files/n${i}
					mv $file ./grd_files/n${i}
					echo "sorted"
				elif [ "$lat_num" = "s${i}" ]
					then
					mkdir -p ./grd_files/s${i}
					mv $file ./grd_files/s${i}
					echo "sorted"
				fi
			done
	done
	# check for mac number of columns
	declare -i maxcount=0
	declare -i count
	declare maxdirectory
	find ./grd_files/* -type d | while read DIR;
		    do let count=`(ls $DIR | wc -w)`
		    if(($count > $maxcount)); then 
				let maxcount=count 
				maxdirectory="$DIR"
				echo "maxdirectory=$maxdirectory" > ./grd_files/tmp
		    fi
	done
	. ./grd_files/tmp
	rm ./grd_files/tmp
	max_vol=$(ls $maxdirectory -l | grep ^- | wc -l)
	echo "largest volume in" $maxdirectory ", n=" $max_vol
	#  correct directory to just xXX name
	xXX=$(echo $maxdirectory | awk -F "/" '{print $3}')
	# make list of columns needed
	cd ./grd_files  
	for lat in */
	 	do
		ls "$lat" | sed 's/[a-z][1-9][1-9].*\([a-z][0-9][0-9]*\).grd/\1/' >"${lat%/}.tmp"
	done
	for file in *.tmp
		do
		lat=$(echo $file | awk -F "." '{print $1}')
		grep -vFf "$file" ${xXX}.tmp >${lat}missing.out
		[ -s ${lat}missing.out ] && echo ${file%.tmp} is missing $(cat ${lat}missing.out)
	done
	# iterate the .out files that have size > 0, and make the files. named from filename and info in file. put in correct folder. delete temp and out files
	for file in *.out
		do
		size=$(echo $(stat --printf="%s" $file ) )
		echo $file "is size:" $size
		if [ "$size" > "0" ]
			then
			while read line
				do
				lat_raw=$(echo $file | awk -F "." '{print $1}')
				lat=${lat_raw:0:3}
				lat_dir=${lat:0:1}
				lon=$line
				lon_dir=${lon:0:1}
				if [ "$lat_dir" = "n" ]
					then
					b=${lat:1:3}
					t=$(( $b + 1 ))
					if [ "$lon_dir" = "e" ]
						then
						l=${lon:1:3}
						r=$(( $l + 1 ))
					elif [ "$lon_dir" = "w" ]
						then
						l=$(( ${lon:1:3} * -1 ))
						r=$(( $l + 1 ))										
					fi
					echo "l is" $l
					echo "r is" $r
					echo "b is" $b
					echo "t is" $t
				elif [ "$lat_dir" = "s" ]
					then
					b=$(( ${lat:1:3} * -1 ))
					t=$(( $b + 1 ))
					if [ "$lon_dir" = "e" ]
						then
						l=${lon:1:3}
						r=$(( $l + 1 ))
					elif [ "$lon_dir" = "w" ]
						then
						l=$(( ${lon:1:3} * -1 ))
						r=$(( $l + 1 ))					
					fi
					echo "l is" $l
					echo "r is" $r
					echo "b is" $b
					echo "t is" $t
				fi
				range=$l"/"$r"/"$b"/"$t
				echo "range needed is:" $range
				grdmath -I3c -R$range -V = ./${lat}/${lat}${lon}.grd
			done <$file
		else
			echo "file size is 0: no missing files in" $file		
		fi
	done
	# clean up
	rm -r *.tmp
	rm -r *.out
	rm 0

#
# begin the grdpaste
#
	# note still in dir grd_files/
	for lat in */
	 	do
		ls "$lat" | sed 's/e/e/' >"${lat%/}.tmp"
	done
	for file in *.tmp
		do
		lat=$(echo $file | awk -F "." '{print $1}')
		count=0		
		while read line
			do
			count=$(( $count + 1 ))
			if [ "$count" = "1" ]
				then
				declare "tmp_${count}=$line"
			elif [ "$count" = "2" ]
				then
				declare "tmp_${count}=$line"
				prod="P"$(( ${count} - 1 ))".grd"
				grdpaste ./${lat}/${tmp_1} ./${lat}/${tmp_2} -G./${lat}/${prod} -V
			elif [ "$count" > "2" ]
				then
				r="tmp_"${count}
				declare "r=$line"
				pprod="P"$(( ${count} - 2 ))".grd"
				prod="P"$(( ${count} - 1 ))".grd"
				grdpaste ./${lat}/${r} ./${lat}/${pprod} -G./${lat}/${prod} -V
				to_paste=${prod}
			fi
		done <$file
	done
	rm *.tmp
	rm 2
	echo "to paste:" $to_paste
	for lat in */
	 	do
		for file in ./${lat}*.grd
			do
			name=$(echo $file | awk -F "/" '{print $3}')
			if [ "${name}" = "${to_paste}" ]
				then
				echo ${file} >> rows.tmp
				echo "location noted"
			fi
		done
	done
	count=0	
	while read line
			do
			count=$(( $count + 1 ))
			if [ "$count" = "1" ]
				then
				declare "tmp_${count}=$line"
			elif [ "$count" = "2" ]
				then
				declare "tmp_${count}=$line"
				crod="C"$(( ${count} - 1 ))".grd"
				grdpaste ${tmp_1} ${tmp_2} -G./${crod} -V
			elif [ "$count" > "2" ]
				then
				r="tmp_"${count}
				declare "r=$line"
				ccrod="C"$(( ${count} - 2 ))".grd"
				crod="C"$(( ${count} - 1 ))".grd"
				grdpaste ${r} ${ccrod} -G./${crod} -V
				final=${crod}
			fi
		done <rows.tmp
	mv ./${final} ../complete.grd
	cd ..

#
# make map
#

