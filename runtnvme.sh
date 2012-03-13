#!/bin/bash

# Copyright (c) 2011, Intel Corporation.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

TNVME_CMD_LINE=$@
BASE_LOG_DIR=./Logs
RUNNING_TEST=false

Usage() {
echo "usage...."
echo "  $0 <tnvme cmd line options>"
echo ""
}

if [ -z "$TNVME_CMD_LINE" ]; then
  Usage
  exit
fi

if [[ "$TNVME_CMD_LINE" == *-t* ]]; then
    RUNNING_TEST=true
fi

# Create a root logging directory. Sub-directories will be created by tnvme
# to house the dumping of various resources during test execution. A utility,
# svlogd, is used to create rotating logs from tnvme's stdout/stderr.
# You will most likley have to install svlogd to take advatage of the huge
# time savings introduced by this new logging/archiving scheme. The
# instructions that dictate svlogd's behavior are contained in ./Logs/config 
rm -rf ${BASE_LOG_DIR}
mkdir -m 0777 ${BASE_LOG_DIR}
echo "s10000000" >${BASE_LOG_DIR}/config
echo "n10" >>${BASE_LOG_DIR}/config

# ./Logs/GrpInformative contains the resource dumps of GrpInformative
# ./Logs/GrpPending contains the resource dumps of the last group which executed
# ./Logs/current is the current output from tnvme via stderr/stdout
# ./Logs/*.s files are the result of svlogd rotating ./Logs/current
if [ $RUNNING_TEST == true ]; then
    # Pipe tnvme into the logging utility for 8 fold speed increase
    ../tnvme/tnvme --log=${BASE_LOG_DIR} -k skiptest.cfg $TNVME_CMD_LINE 2>&1 | svlogd -v -tt -b 2048 -l 0 ${BASE_LOG_DIR}
else
    # Allow tnvme to be slow, because we want to see the output immediately
    ../tnvme/tnvme --log=${BASE_LOG_DIR} -k skiptest.cfg $TNVME_CMD_LINE 2>&1 | tee ${BASE_LOG_DIR}/current
fi

# Cleanup files used to rotate logs, they are just noise
rm -f ${BASE_LOG_DIR}/lock
rm -f ${BASE_LOG_DIR}/config

# Report the end of the current log file
grep -A 4 "Iteration SUMMARY" ${BASE_LOG_DIR}/current
