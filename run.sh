#!/bin/bash

# Run the command and capture the output
TDP=360000
#set the power limit
power_limit=400000
initial_power_limit=$power_limit
half_TDP=$((TDP / 2))
rm result.txt

# Start the loop
while [ $power_limit -ge 390000 ]
#while [ $power_limit -ge 0 ]
do
	echo "Setting current power limit: $power_limit" >> result.txt
	/opt/e-sms/e_smi/bin/e_smi_tool --setpowerlimit 0 $power_limit

	# Use grep to find the line containing "GFLOPS" and write it to result.txt
	output=$(sudo ./run_dgemm.py > output_tmp.txt) &
	job_id=$!
	sleep 10
#	clkfreq=$(/opt/e-sms/e_smi/bin/e_smi_tool --showclocks)


	# this will grep the core frequencof the first 'n' cores, and do an average it. 
	clkfreq_allcore=$(grep "^[c]pu MHz" /proc/cpuinfo | head -n 8)
	wait $job_id
	

	# Use awk to parse the frequencies and calculate their average
	average_clkfreq=$(echo "$clkfreq_allcore" | awk -F: '{ total += $2; count++ } END { print total/count }')		

	
	grep "GFLOPS" output_tmp.txt >> result.txt
	echo "clkfreq = $average_clkfreq"  >> result.txt
    	# Subtract 10 from power_limit
    	power_limit=$((power_limit - 10000))
done

echo "Test done, setting back to original power limit: $initial_power_limit"
/opt/e-sms/e_smi/bin/e_smi_tool --setpowerlimit 0 $initial_power_limit

# add a timestamp to the result file
timestamp=$(date "+%Y.%m.%d-%H.%M.%S")
mv result.txt result_${timestamp}.txt
