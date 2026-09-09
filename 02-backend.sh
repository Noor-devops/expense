#!/bin/bash

SCRIPT_DIR=$PWD
app_name=backend
source ./common.sh
check_root


app_setup
nodejs_setup
systemd_setup

dnf install mysql -y &>>$LOGS_FILE
VALIDATE $? "Installing MySQL client"

mysql -h $MYSQL_HOST -u root -pExpenseApp@1 -e "use transactions" &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pExpenseApp@1 < /app/schema/backend.sql
    VALIDATE $? "Data loaded"
else
    echo -e "Data already loaded ... $Y SKIPPING $N"
fi

app_restart
print_total_time