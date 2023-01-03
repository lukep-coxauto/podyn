#!/bin/bash

if [[ -n $DYNAMODB_ENDPOINT ]]; then
    DYNAMODB_OPTS="--ddb-endpoint \"$DYNAMODB_ENDPOINT\""
else
    DYNAMODB_OPTS=""
fi

PODYN=$@
if [[ "$@" != "--"* ]]; then
    SLACK=`echo $@ | sed 's/ .*//'`
    PODYN=`echo $@ | sed 's/.* //'`
fi

echo "Slack: $SLACK"
echo "Podyn: $PODYN"

# Create a launcher script to stop a running podyn and start a new one

echo "#!/bin/bash" > ./launch.sh
echo "export AWS_SECRET_ACCESS_KEY=\"$AWS_SECRET_ACCESS_KEY\"" >> ./launch.sh
echo "export AWS_ACCESS_KEY_ID=\"$AWS_ACCESS_KEY_ID\"" >> ./launch.sh
echo "export AWS_REGION=\"$AWS_REGION\"" >> ./launch.sh
echo "" >> ./launch.sh
echo "if ps aux | grep -v \"grep\" | grep \"podyn.jar\"" >> ./launch.sh
echo "then" >> ./launch.sh
echo "    echo \"podyn.jar is already running\"" >> ./launch.sh
echo "else" >> ./launch.sh
echo "    echo \"starting podyn.jar ${@} &>> /app/podyn.log\"" >> ./launch.sh
echo "    java -jar /app/podyn.jar --postgres-jdbc-url \"${POSTGRES_JDBC_URL}\" $DYNAMODB_OPTS ${@} &>> /app/podyn.log &" >> ./launch.sh
echo "    if [ \"$SLACK\" != \"\" ]; then" >> ./launch.sh
echo "        curl -X POST --data-urlencode 'payload={\"username\":\"podyn\",\"channel\":\"developers\",\"icon_url\":\"\",\"attachments\":[{\"color\":\"#4183c4\",\"text\":\"Launching podyn ${AWS_REGION}\",\"footer\":\"\"}]}' $SLACK" >> ./launch.sh
echo "    fi" >> ./launch.sh
echo "fi" >> ./launch.sh

chmod +x ./launch.sh

echo "---- env"
env
echo "----"

if [[ ${@} != *"--data"* ]]; then
    # Start the syncer
    rm -f /app/podyn.log
    touch /app/podyn.log
    service rsyslog start
    service cron start
    crontab -l

    echo "Podyn SYNC" >> /app/podyn.log
    /app/launch.sh

    # tail -f /var/log/syslog | xargs -IL date +"SYSLOG: %Y-%m-%d %H:%M:%S - L"
    tail -f /app/podyn.log | xargs -IL date +"PODYN: %Y-%m-%d %H:%M:%S - L"
else
    # Just load the data and exit
    service cron stop

    echo "Podyn COPY" >> /app/podyn.log
    java -jar /app/podyn.jar --postgres-jdbc-url "${POSTGRES_JDBC_URL}" $DYNAMODB_OPTS ${@}
fi
echo "entrypoint terminated with $?"
