#!/bin/bash

clear

    #get current path
    path=$(pwd)

    echo -e "\033[0;31m
          _    _ _______ ____    _____  ______ _____  _      ______     __
     /\  | |  | |__   __/ __ \  |  __ \|  ____|  __ \| |    / __ \ \   / /
    /  \ | |  | |  | | | |  | | | |  | | |__  | |__) | |   | |  | \ \_/ / 
   / /\ \| |  | |  | | | |  | | | |  | |  __| |  ___/| |   | |  | |\   /  
  / ____ \ |__| |  | | | |__| | | |__| | |____| |    | |___| |__| | | |   
 /_/    \_\____/   |_|  \____/  |_____/|______|_|    |______\____/  |_|   
                                                                          
                                                                          
\033[0m"
    echo -e "\033[0;32mTool to auto-deploy a react website on ubuntu server\033[0;0m"
    echo ""
    echo 'Installing packages ...'
    #Adding source for node16
    curl -s https://deb.nodesource.com/setup_16.x | sudo bash > /dev/null 2>&1
    sudo apt update > /dev/null 2>&1
    sudo apt install nodejs npm git-all nginx -y > /dev/null 2>&1

    clear

    echo 'Do you have a Git repository ? [Y/N] : '
    read repo

    if [ $repo = 'Y' ] || [ $repo = 'Yes' ] || [ $repo = 'y' ] || [ $repo = 'yes' ]
    then
        #clone repo & define project name
        echo 'Paste your link here : '
        read gitrepo
        echo ""
        echo "Cloning repository..."
        #making a new folder to prevent error while creating config file
        sudo mkdir projects > /dev/null 2>&1
        cd projects
        git clone $gitrepo > /dev/null 2>&1
        #use last part of url to make project name
        projectname="$(echo $gitrepo | sed -r 's/.+\/([^.]+)(\.git)?/\1/')"
        projectpath="$path/projects/$projectname"
        cd $projectpath
        #Install the node_modules
        echo "Installing node_modules..."
        sudo npm i > /dev/null 2>&1
        if [ $? -eq 0 ]
            then
                echo -e "\033[0;32mSUCCESS!\033[0;0m"
                sleep 1
            else 
                echo -e "\033[0;31mERROR: Installation failed\033[0;0m"
                exit 1
            fi
        
        
    elif [ $repo = 'N' ] || [ $repo = 'No' ] || [ $repo = 'n' ] || [ $repo = 'no' ]
    then
        #if project is already on local
        echo 'Paste your project path here : '
        read projectpath
        cd $projectpath
        #projectname is the last part of the path
        projectname="${projectpath##*/}"

    else
        echo 'Wrong argument try again ...'
        exit 1
    fi

    #try to build react project
    clear
    echo 'Project in build, please wait ...'
    sudo npm run build > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
        echo -e "\033[0;32mBuild succesfully\033[0;0m"
        sleep 1
        clear
        #Command to show current external IP address
        currentip"=$(dig @resolver4.opendns.com myip.opendns.com +short)"
        echo -e "What is your Host IP (current is \033[0;36m$currentip)\033[0;0m"
        read hostip
        #testing if the ip pattern is correct
        if [[ $hostip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then

            clear
            cd $path

            #duplicate & rename config file to project name
            sudo cp config $projectname

            #templating modification in config file
            sed -i "s/SERVERNAME/$hostip/" $projectname
            sed -i "s/PROJECTNAME/$projectname/" $projectname

            #create folder insite html folder & add permission of nginx to read folder
            sudo mkdir /var/www/html/$projectname > /dev/null 2>&1
            sudo chown -R www-data:www-data /var/www/html/$projectname > /dev/null 2>&1

            #move config file to sites-available
            sudo cp $projectname /etc/nginx/sites-available/ > /dev/null 2>&1

            #move build project to html folder
            sudo cp -a "${projectpath}/build/." /var/www/html/$projectname > /dev/null 2>&1

            #make link between sites-available & site enabled
            sudo ln -s /etc/nginx/sites-available/$projectname /etc/nginx/sites-enabled > /dev/null 2>&1

            #delete default conf of nginx
            sudo rm -f /etc/nginx/sites-available/default > /dev/null 2>&1
            sudo rm -f /etc/nginx/sites-enabled/default > /dev/null 2>&1

            #delete config file in current folder
            sudo rm $projectname

            echo -e "\033[0;32m
   _____ _    _  _____ _____ ______  _____ _____ 
  / ____| |  | |/ ____/ ____|  ____|/ ____/ ____|
 | (___ | |  | | |   | |    | |__  | (___| (___  
  \___ \| |  | | |   | |    |  __|  \___ \\___ \ 
  ____) | |__| | |___| |____| |____ ____) |___) |
 |_____/ \____/ \_____\_____|______|_____/_____/                                       
\033[0;0m"

            echo -e "File has been created in \033[0;36m/etc/nginx/sites-available/$projectname\033[0;0m"
            echo -e "Your website folder is located in \033[0;36m/var/www/html/$projectname\033[0;0m"
            echo -e "Link has been make in \033[0;36m/etc/nginx/site-enabled/$projectname\033[0;0m"
            echo ""

            sleep 1
            
            echo "Testing config for nginx..."
            #test if config of nginx is correct or not
            sudo nginx -t > /dev/null 2>&1
            if [ $? -eq 0 ]
            then
                #if config is ok, restart nginx
                sudo systemctl restart nginx > /dev/null 2>&1 
                echo -e "\033[0;32mSUCCESS! Go to http://${hostip}/ to see you website\033[0;0m"
            else 
                echo -e "\033[0;31mERROR: Config Failed\033[0;0m"
                exit 1
            fi
        else
            echo -e "\033[0;31mWrong IP pattern\033[0;0m"
            exit 1
        fi
    else
        echo -e "\033[0;31mBuild Failed\033[0;0m"
        exit 1
    fi

    # SSL CERTIFICATE

    echo " "
    echo 'Put website on DNS & HTTPS? [Y/N] : '
    read sslresponse

    if [ $sslresponse = 'Y' ] || [ $sslresponse = 'Yes' ] || [ $sslresponse = 'y' ] || [ $sslresponse = 'yes' ]
    then
        clear

        echo "Installing packages ..."
        sudo apt install certbot python3 python3-certbot-nginx -y > /dev/null 2>&1

        echo "Put your Host Domain Name (eg: www.example.com)"
        read dns

        #edit server name in sites-available folder of nginx
        sed -i "s/$hostip/$dns/" /etc/nginx/sites-available/$projectname > /dev/null 2>&1

        #use certbot to link dns & to put HTTPS
        sudo certbot --nginx -d $dns
        if [ $? -eq 0 ]
        then
            clear
            #restart nginx
            echo "Restarting nginx..."
            sudo systemctl restart nginx > /dev/null 2>&1

            clear
            echo -e "\033[0;32mSuccess !\033[0;0m go to https://${dns}/"
            echo -e "You can test the config at \033[0;32mhttps://www.ssllabs.com/ssltest/analyze.html?d=${dns}&latest\033[0;0m"
        else
            echo -e "\033[0;31mError : unable to setup certbot certificate, try again.\033[0;0m"
            exit 1
        fi

    else
        echo "Exit"
        exit
    fi