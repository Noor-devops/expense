USERID=$(id -u)
LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

echo -e "$TIMESTAMP [INFO] Script started"

check_root(){
    if [ $USERID -ne 0 ]; then
        echo -e "$TIMESTAMP $R Please run this script with root access $N"
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $2 is..... $R FAILURE $N" | tee -a $LOGS_FILE
    else
        echo -e "$TIMESTAMP [INFO] $2 is..... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

print_total_time(){
    echo -e "$TIMESTAMP [INFO] Script executed in $G $SECONDS seconds $N"
}

app_setup(){
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

    curl -o /tmp/$app_name.tar.gz https://raw.githubusercontent.com/daws-90s/expense-documentation/refs/heads/main/artifacts/expense-$app_name-v3.tar.gz &>>$LOGS_FILE
    cd /app
    tar -xzf /tmp/$app_name.tar.gz &>>$LOGS_FILE
    VALIDATE $? "Downloaded and extracted expense code"
}

nodejs_setup(){
    dnf module disable nodejs -y &>>$LOGS_FILE
    dnf module enable nodejs:20 -y  &>>$LOGS_FILE
    dnf install nodejs -y &>>$LOGS_FILE
    VALIDATE $? "Installing NodeJS:20"
    npm install  &>>$LOGS_FILE
    VALIDATE $? "Installing dependencies"
}

systemd_setup(){
    cp $SCRIPT_DIR/$app_name.service /etc/systemd/system/$app_name.service
    VALIDATE $? "Created systemctl service"
    systemctl daemon-reload
    systemctl enable $app_name
    VALIDATE $? "Enabled $app_name"
}

app_restart(){
    systemctl restart $app_name
    VALIDATE $? "$app_name restarting"
}