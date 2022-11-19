#!/bin/bash
 
#seconds var should be globally accessible
timecheck=0
#Point of this function is to start all the timers basically, set up the timing so that the info gathering is done correctly
function initialize() {
    #where we initialize things
    timecheck=$SECONDS
 
    #thing for system processes i need:
    #   - run ifstat -d 1 so i can grab its output
    #   - call $SECONDS to a variable (ie: test=$SECONDS) so it starts counting seconds
    #   - initialize file that I need to output to
 
    #initializes system monitoring text file
    touch "sysinfo.csv"
    echo "Time,RX Data Rate,TX Data Rate,Disk Writes,Space_Available" >> "sysinfo.csv"
  
    #things for process monitoring text files
    touch "procinfo.csv"
    echo "Time,APM1 CPU,APM1 Memory,APM2 CPU,APM2 Memory,APM3 CPU,APM3 Memory,APM4 CPU,APM4 Memory,APM5 CPU,APM5 Memory,APM6 CPU,APM6 Memory" >> "procinfo.csv"
  
    touch "processids.txt"
    #initialize ifstat in the bgnd
    ifstat -a -n -d 1
    #need to collect process ids on startup so I can kill later and for output purposes
    #need to do ifstat -d 1 for certain processes, -5 for the rest
    #basically run all commands to obtain system info to then use in the other functions
    ./APM1 8.8.8.8 &
    echo $! >> "processids.txt"
    ./APM2 8.8.8.8 &
    echo $! >> "processids.txt"
    ./APM3 8.8.8.8 &
    echo $! >> "processids.txt"
    ./APM4 8.8.8.8 &
    echo $! >> "processids.txt"
    ./APM5 8.8.8.8 &
    echo $! >> "processids.txt"
    ./APM6 8.8.8.8 &
    echo $! >> "processids.txt"

    system_monitoring &
    process_monitoring

    end
}
 
 
function process_monitoring() {
    go=true
    sec=0
    while [ "$go" = true ]
    do
        echo -n "$sec," >> "procinfo.csv"
        
        ps aux | awk '{print $3, $11}' | grep ./APM1 | awk '{printf $1} {printf ","}' >> "procinfo.csv"
        ps aux | awk '{print $4, $11}' | grep ./APM1 | awk '{printf $1} {printf ","}' >> "procinfo.csv"
        ps aux | awk '{print $3, $11}' | grep ./APM2 | awk '{printf $1} {printf ","}' >> "procinfo.csv"
        ps aux | awk '{print $4, $11}' | grep ./APM2 | awk '{printf $1} {printf ","}' >> "procinfo.csv"
        ps aux | awk '{print $3, $11}' | grep ./APM3 | awk '{printf $1} {printf ","}' >> "procinfo.csv"
        ps aux | awk '{print $4, $11}' | grep ./APM3 | awk '{printf $1} {printf ","}' >> "procinfo.csv"
        ps aux | awk '{print $3, $11}' | grep ./APM4 | awk '{printf $1} {printf ","}' >> "procinfo.csv"
        ps aux | awk '{print $4, $11}' | grep ./APM4 | awk '{printf $1} {printf ","}' >> "procinfo.csv"
        ps aux | awk '{print $3, $11}' | grep ./APM5 | awk '{printf $1} {printf ","}' >> "procinfo.csv"
        ps aux | awk '{print $4, $11}' | grep ./APM5 | awk '{printf $1} {printf ","}' >> "procinfo.csv"
        ps aux | awk '{print $3, $11}' | grep ./APM6 | awk '{printf $1} {printf ","}' >> "procinfo.csv"
        ps aux | awk '{print $4, $11}' | grep ./APM6 | awk '{printf $1} {printf ","}' >> "procinfo.csv"
        echo "\n" >> "procinfo.csv"

        (( sec += 5 ))
        sleep 5
        if [ $sec -gt 900 ]
        then
            go=false
        fi
        

    done
    cut -d, -f14 --complement procinfo.csv > processors_metrix.csv
    rm procinfo.csv
}
 
function system_monitoring() {
    #measure things idk
    #note: this isn’t necessarily tested, couldnt be bothered to open a VM
    #this has to measure things in a loop so it can run for 15 mins
    go=true
    while [ "$go" = true ]
    do
        #network bandwidth util
        echo -n "$timecheck," >> "sysinfo.csv"
        #ifstat is called in init; either call here instead or grab it somehow so we can keep outputting it to a file
        ifstat ens192 -a | tail -2 | head -1 | awk 'BEGIN{ORS=","}{print $7}' >> "sysinfo.csv"
        ifstat ens192 -a | tail -2 | head -1 | awk 'BEGIN{ORS=","}{print $9}' >> "sysinfo.csv"
        #hard disk access rates
        iostat sda | grep sda | awk 'BEGIN{ORS=","}{print $6}' >> "sysinfo.csv" #prints kb_written in current session
 
        #hard disk utilization
        #ask prof: do we need to measure this in kb or gb, prob gb but just want to be sure
        #grabs amt of available space
        df / | awk '{print $4}' | sed '1d' >> "sysinfo.csv" #gets amt of space used in gigs
        #ig we could get the amt of total space once if we really want to
        #just for faster calculations of used space
 
        #wait 1 second
        (( timecheck += 1 ))
        sleep 1

        #ending check- if $SECONDS is over 15 mins we break
        if [ $timecheck -gt 900 ]
        then
            go=false
        fi
    done
    cut -d, -f14 --complement sysinfo.csv > system_metrics.csv
    rm sysinfo.csv
}
 
#kill timers and wrap up the process
function end() {
    #gotta make sure to kill timers
    timecheck=999
    #ensure that the txt file stops getting updated
    #clear any junk thats occupying the terminal
    clear
    while read line; do kill -17 $line; done < "processids.txt"
    killall ifstat
}
 
initialize
 

