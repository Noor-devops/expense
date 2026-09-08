#!/bin/bash

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD
MYSQL_HOST=database.nirfaws.online

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

if [ $USERID -ne 0 ]; then
    echo -e "$TIMESTAMP [ERROR] $R Please run this script with root access $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y &>>$LOGS_FILE
dnf module enable nodejs:20 -y  &>>$LOGS_FILE
dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing NodeJS:20"

id expense &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "expense system user" expense &>>$LOGS_FILE
    VALIDATE $? "Creating expense system user"
else
    echo -e "System user expense already created ... $Y SKIPPING $N"
fi

rm -rf /app
VALIDATE $? "Removing existing code"

rm -rf /tmp/backend.zip
VALIDATE $? "Removed backend zip"

mkdir -p /app  &>>$LOGS_FILE
VALIDATE $? "Creating app directory"

curl -o /tmp/backend.tar.gz https://raw.githubusercontent.com/daws-90s/expense-documentation/refs/heads/main/artifacts/expense-backend-v3.tar.gz &>>$LOGS_FILE
cd /app
tar -xzf /tmp/backend.tar.gz &>>$LOGS_FILE
VALIDATE $? "Downloaded and extracted expense code"

npm install  &>>$LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/backend.service /etc/systemd/system/backend.service
VALIDATE $? "Created systemctl service"

dnf install mysql -y &>>$LOGS_FILE
VALIDATE $? "Installing MySQL client"

mysql -h $MYSQL_HOST -u root -pExpenseApp@1 -e "use transactions" &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pExpenseApp@1 < /app/schema/backend.sql
    VALIDATE $? "Data loaded"
else
    echo -e "Data already loaded ... $Y SKIPPING $N"
fi

systemctl enable shipping 
systemctl restart shipping
VALIDATE $? "Enable and restarted shipping"
