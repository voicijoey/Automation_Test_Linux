#!/usr/bin/bash

##################################################################################################################
#title           :fs_uninstall_root3.sh                                                                          #
#description     :The purpose of this testcase is to test that Front Server                                      #
#                 can be successfully uninstalled in docker by invoking the original uninstall.sh script in      #
#                 source directory located within the installation directory, while modifying /etc/sudoers to    #
#                 obtain root access, which means that uninstall.sh is correctly invoked and executed.           #
#author		     :Zihao Yan                                                                                       #
#date            :20190409                                                                                       #
#version         :1.0                                                                                            #
#usage		     :./fs_uninstall_root3.sh                                                                        #
#actual results  :Testcase fs_uninstall_root3.sh passed!                                                         #
#expected results:Testcase fs_uninstall.sh_root3 passed!                                                         #
##################################################################################################################

newuser="derek"                                                                                                  #new user
adduser $newuser                                                                                                 #add a new user
sudoers="/etc/sudoers"                                                                                           #sudoers location
chmod u+w $sudoers                                                                                               #give write permission for /etc/sudoers
newper="$newuser ALL=(ALL) NOPASSWD:ALL"                                                                         #set permission for sudo for the new user
root_line_number=`grep -n "^root" $sudoers|cut -f 1 -d":"`                                                       #get root sudoers config line number
sed -i "$root_line_number a$newper" $sudoers                                                                     #add new user permission for sudo in /etc/sudoers
usermod -G wheel $newuser                                                                                        #add the user to wheel group
su="/etc/pam.d/su"                                                                                               #su file
chmod u+w $su                                                                                                    #give write permission for /etc/pam.d/su
sed -i "s/#auth/auth/g" $su                                                                                      #remove the comment #auth        sufficient  pam_wheel.so trust use_uid 
input="input.file"                                                                                               #input file for install.sh
rm -rf $input                                                                                                    #remove input file for conflict
echo -e "YES" >$input                                                                                            #echo YES to agree the EULA
echo -e "I ACCEPT" >>$input                                                                                      #echo I ACCEPT to accept the terms in the subscription EULA
servicename="netbrainfrontserver"                                                                                #Front Server service name
log="FS.log"                                                                                                     #installation log generated in the current directory
log2="FS_uninstall.log"                                                                                          #uninstallation log generated in the current directory
log_fail="FS_fail.log"                                                                                           #generate logs only if the testcase failed
msg_install="Successfully installed Front Server"                                                                #message for a sign of successfully installing the Front Server
msg_uninstall="Successfully uninstalled FrontServer"                                                             #message for a sign of successfully uninstalling the Front Server
InstallPath="/usr/lib/netbrain/frontserver"                                                                      #the default Installation Path
UninstallPath="/usr/lib/netbrain/installer/frontserver"                                                          #uninstall.sh copied to the UninstallPath
service="/usr/lib/systemd/system/$servicename.service"                                                           #Front Server systemd service file
rm -rf $log $log_fail                                                                                            #remove logs for conflict
timeout 600 ./install.sh <$input >$log 2>&1                                                                      #execute Front Server installation script and save the log
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    exit 0
fi

if ! grep -q "$msg_install" $log;then                                                                            #if the testcase fails, generate the reasons for the failure
echo -e "The following wording information was found in $log: $msg_install. This may indicate \
that the installation was not successful, or some dependencies failed to install. \
This is the reason why the testcase failed.">>$log_fail
fi

if [ ! -d $InstallPath ];then                                                                                    #if the testcase fails, generate the reasons for the failure
echo -e "The Installation Path $InstallPath was not created. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if ! sh -c "service $servicename status |grep dead >/dev/null 2>&1">/dev/null 2>&1;then                          #if the testcase fails, generate the reasons for the failure
echo -e "The $servicename service is not in dead state. This may indicate \
that the installation was not successful. This is the reason why the testcase failed.">>$log_fail
fi

if sh -c "service $servicename status |grep dead >/dev/null 2>&1">/dev/null 2>&1 \
&& grep -q "$msg_install" $log && [ -d $InstallPath ];then                                                       #determine if Front Server installation is successfully completed
timeout 600 su $newuser --session-command \
"su --session-command 'timeout 600 echo "y"|timeout 600 $UninstallPath/uninstall.sh'" >$log2 2>&1                #execute Front Server uninstallation script and save the log    
if [ $? -eq 124 ];then                                                                                           #determine if the testcase runs timed out
    echo "Testcase $BASH_SOURCE timeout!"
    cat $log2 >>$log                                                                                             #merge two logs
    exit 0
fi
	if ! grep -q "$msg_uninstall" $log2;then                                                                     #if the testcase fails, generate the reasons for the failure
    echo -e "The following wording information was not found in $log2: $msg_uninstall. This may indicate \
    that the uninstallation was not successful. This is the reason why the testcase failed.">>$log_fail
    fi

    if [ -d $InstallPath ];then                                                                                  #if the testcase fails, generate the reasons for the failure
    echo -e "The Installation Path $InstallPath still existed after uninstallation. This may indicate \
    that the uninstallation was not successful. This is the reason why the testcase failed.">>$log_fail
    fi
	
	if [ -f $service ];then                                                                                      #if the testcase fails, generate the reasons for the failure
    echo -e "The systemd service $service still existed after uninstallation, which is not an expected behavior. \
	This may indicate that the uninstallation was not successful. \
	This is the reason why the testcase failed.">>$log_fail
    fi
	
	if grep -q "$msg_uninstall" $log2 && [ ! -d $InstallPath ] && [ ! -f $service ];then                         #determine if Front Server uninstallation is successfully completed
    echo "Testcase $BASH_SOURCE passed!"
	else
	echo "Testcase $BASH_SOURCE failed!"
	fi
else
echo "Testcase $BASH_SOURCE failed!"
fi

if [ -f $log2 ];then
cat $log2 >>$log                                                                                                 #merge two logs
fi












