FROM maven:3-jdk-8 as builder
WORKDIR /app
COPY . /app
RUN mvn package

FROM openjdk:8
ARG APP_VERSION=1.0
WORKDIR /app
COPY --from=builder "/app/target/podyn-${APP_VERSION}.jar" /app/podyn.jar
COPY stop.sh /app/
RUN chmod +x /app/stop.sh
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
COPY podyn-service /etc/init.d/podyn
RUN chmod +x /etc/init.d/podyn

RUN apt-get update
RUN apt-get install cron -y
COPY podyn-cron /etc/cron.d/podyn-cron
RUN chmod 0644 /etc/cron.d/podyn-cron
RUN crontab /etc/cron.d/podyn-cron
RUN touch /var/log/cron.log

ENTRYPOINT ["/entrypoint.sh"]
