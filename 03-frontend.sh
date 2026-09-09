#!/bin/bash

app_name=frontend
source ./common.sh
check_root

dnf module disable nginx -y &>> $LOGS_FILE
dnf module enable nginx:1.24 -y &>> $LOGS_FILE
dnf install nginx -y &>> $LOGS_FILE
VALIDATE $? "Installing Nginx"

rm -rf /usr/share/nginx/html/* &>> $LOGS_FILE
VALIDATE $? "Removed Default code"

curl -o /tmp/frontend.tar.gz https://raw.githubusercontent.com/daws-90s/expense-documentation/refs/heads/main/artifacts/expense-frontend-v3.tar.gz &>> $LOGS_FILE
cd /usr/share/nginx/html
tar -xzf /tmp/frontend.tar.gz
VALIDATE $? "Downloaded and extracted frontend code"

cp $SCRIPT_DIR/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copied roboshop nginx conf"

systemctl restart nginx
systemctl enable nginx &>> $LOGS_FILE
VALIDATE $? "Enabled and restarted nginx"

print_total_time