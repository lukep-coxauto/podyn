#!/bin/bash

if [[ -n $DYNAMODB_ENDPOINT ]]; then
    DYNAMODB_OPTS="--ddb-endpoint $DYNAMODB_ENDPOINT"
else
    DYNAMODB_OPTS=""
fi

# Create a launcher script to stop a running podyn and start a new one

echo "#!/bin/bash" > ./launch.sh
echo "/app/stop.sh podyn" >> ./launch.sh
echo "if [ \$AWS_SECRET_ACCESS_KEY != \"test\" ]; then" >> ./launch.sh
echo "  curl -X POST --data-urlencode 'payload={\"username\":\"podyn\",\"channel\":\"developers\",\"icon_url\":\"\",\"attachments\":[{\"color\":\"#4183c4\",\"text\":\"Launching podyn ${AWS_REGION}\",\"footer\":\"\"}]}' https://hooks.slack.com/services/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" >> ./launch.sh
echo "fi" >> ./launch.sh
echo "exec java -jar /app/podyn.jar --postgres-jdbc-url \"${POSTGRES_JDBC_URL}\" $DYNAMODB_OPTS ${@}" >> ./launch.sh

chmod +x ./launch.sh

echo "---- env"
env
echo "----"


if [[ ${@} != *"--data"* ]]; then
    # Start the syncer
    touch /app/podyn.log
    service podyn start
    tail -f /app/podyn.log
else
    # Just load the data and exit
    /app/launch.sh
fi

