#!/bin/bash

#######################################################################
#
# Linux on Hyper-V and Azure Test Code, ver. 1.0.0
# Copyright (c) Microsoft Corporation
#
# All rights reserved.
# Licensed under the Apache License, Version 2.0 (the ""License"");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
#
# THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS
# OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
# ANY IMPLIED WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR
# PURPOSE, MERCHANTABLITY OR NON-INFRINGEMENT.
#
# See the Apache Version 2.0 License for specific language governing
# permissions and limitations under the License.
#
#######################################################################

#######################################################################
#
#
#
# Description:
#######################################################################

#HOW TO PARSE THE ARGUMENTS.. SOURCE - http://stackoverflow.com/questions/4882349/parsing-shell-script-arguments

while echo $1 | grep ^- > /dev/null; do
    eval $( echo $1 | sed 's/-//g' | tr -d '\012')=$2
    shift
    shift
done

master=$master
slaves=$slaves
rm -rf /root/temp.txt
#
# Constants/Globals
#
CONSTANTS_FILE="/root/constants.sh"
ICA_TESTRUNNING="TestRunning"      # The test is running
ICA_TESTCOMPLETED="TestCompleted"  # The test completed successfully
ICA_TESTABORTED="TestAborted"      # Error during the setup of the test
ICA_TESTFAILED="TestFailed"        # Error occurred during the test
CurrentMachine=""
imb_mpi1_finalStatus=0
imb_rma_finalStatus=0
imb_nbc_finalStatus=0
#######################################################################
#
# LogMsg()
#
#######################################################################
LogMsg()
{
    timeStamp=`date "+%b %d %Y %T"`
    echo "$timeStamp : ${1}"    # Add the time stamp to the log message
    echo "$timeStamp : ${1}" >> /root/temp.txt
}

UpdateTestState()
{
    echo "${1}" > /root/state.txt
}

PrepareForRDMA()
{
        # TODO
        echo Doing Nothing
}
#Get all the Kernel-Logs from all VMs.
CollectKernelLogs()
{
    slavesArr=`echo ${slaves} | tr ',' ' '`
    for vm in $master $slavesArr
    do
                    LogMsg "Getting kernel logs from $vm"
                    ssh root@${vm} "dmesg > kernel-logs-${vm}.txt"
                    scp root@${vm}:kernel-logs-${vm}.txt .
                    if [ $? -eq 0 ];
                    then
                                    LogMsg "Kernel Logs collected successfully from ${vm}."
                    else
                                    LogMsg "Error: Failed to collect kernel logs from ${vm}."
                    fi

    done
}

CompressFiles()
{
    compressedFileName=$1
    pattern=$2
    LogMsg "Compressing ${pattern} files into ${compressedFileName}"
    tar -cvzf ${compressedFileName} ${pattern}*
    if [ $? -eq 0 ];
    then
            LogMsg "${pattern}* files compresssed successfully."
            LogMsg "Deleting local copies of ${pattern}* files"
            rm -rvf ${pattern}*
    else
            LogMsg "Error: Failed to compress files."
            LogMsg "Don't worry. Your files are still here."
    fi
}

if [ -e ${CONSTANTS_FILE} ]; then
    source ${CONSTANTS_FILE}
else
    errMsg="Error: missing ${CONSTANTS_FILE} file"
    LogMsg "${errMsg}"
    UpdateTestState $ICA_TESTABORTED
    exit 10
fi


CollectKernelLogs
