#!/usr/bin/bash

##################################################################################################################
#title           :es_install_datapath_immutable.sh                                                               #
#description     :The purpose of this testcase is to test that Elasticsearch                                     #
#                 can NOT be successfully installed in docker by invoking the original install.sh script,        #
#                 if the DataPath is immutable.                                                                  #
#author		     :Zihao Yan                                                                                       #
#date            :20190215                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./es_install_datapath_immutable.sh                                                             #
#actual results  :Testcase es_install_datapath_immutable.sh passed!                                              #
#expected results:Testcase es_install_datapath_immutable.sh passed!                                              #
##################################################################################################################

##################################################################################################################
# The following function is for cleaning up before and after installation                                        #
##################################################################################################################
cleanup()
{
user="elasticsearch"                                                                                             #Elasticsearch user
UnifiedLogPath="/var/log/netbrain"                                                                               #unified LogPath
UnifiedUninstallPath="/usr/lib/netbrain/"                                                                        #unified UninstallPath
UnifiedConfigPath="/etc/elasticsearch/"                                                                          #unified ConfigPath
UninstallPath="/usr/lib/netbrain/installer/elasticsearch"                                                        #uninstall.sh copied to UninstallPath
echo "y"|$UninstallPath/uninstall.sh >/dev/null 2>&1                                                             #uninstall Elasticsearch
echo "y"|./others/uninstall.sh >/dev/null 2>&1                                                                   #uninstall Elasticsearch
rpm -qa|grep -E "elasticsearch"|xargs rpm -e >/dev/null 2>&1                                                     #uninstall all Elasticsearch related rpms if they have been installed
rm -rf $DataPath $UnifiedConfigPath $UnifiedLogPath $UnifiedUninstallPath                                        #remove all Elasticsearch files and paths
userdel -r -f $user >/dev/null 2>&1                                                                              #remove Elasticsearch user and group
groupdel $user >/dev/null 2>&1                                                                                   #remove Elasticsearch group
service firewalld start >/dev/null 2>&1                                                                          #start the firewalld service
i=0 
for line in `firewall-cmd --list-ports`                                                                          #list all ports in the firewall
do
    name[${i}]=$line
    firewall-cmd --remove-port=${name[$i]} --permanent >/dev/null 2>&1                                           #remove all ports from the firewall
    let i=${i}+1
done
firewall-cmd --reload >/dev/null 2>&1                                                                            #reload the firewall
service firewalld stop >/dev/null 2>&1                                                                           #stop the firewalld service
}
cleanup                                                                                                          #invoke cleanup funtion to purge all Elasticsearch related stuffs
conf_path=`ls config/setup.conf`                                                                                 #the Elasticsearch config file name
log="ES.log"                                                                                                     #installation log generated in the current directory
log_fail="ES_fail.log"                                                                                           #generate logs only if the testcase failed
DataPath="`grep "^DataPath" $conf_path|tr "=" " "|awk '{print $2}'`"                                             #default DataPath
rm -rf $DataPath                                                                                                 #remove DataPath for conflict
mkdir -p $DataPath                                                                                               #create DataPath
chattr +i $DataPath                                                                                              #make DataPath immutable
msg_error="The directory $DataPath is immutable. The installation aborted."                                      #message for a sign of DataPath which is immutable
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh >$log 2>&1                                                                              #execute Elasticsearch installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
	chattr -i $DataPath                                                                                          #make DataPath mutable
	cleanup                                                                                                      #invoke cleanup funtion to purge all Elasticsearch related stuffs
	exit 0
fi
chattr -i $DataPath                                                                                              #make DataPath mutable
if grep -q "$msg_error" $log; then                                                                               #determine if the install.sh is successfully completed
echo "Testcase $BASH_SOURCE passed!"
else
echo -e "The following wording information was not found in $log: $msg_error. This is the reason why \
testcase $BASH_SOURCE failed.">$log_fail                                                                         #if the testcase fails, generate the reasons for the failure
echo "Testcase $BASH_SOURCE failed!"
fi
cleanup                                                                                                          #invoke cleanup funtion to purge all Elasticsearch related stuffs
