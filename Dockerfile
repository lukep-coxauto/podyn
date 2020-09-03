FROM maven:3-jdk-8 as builder
WORKDIR /app
COPY pom.xml .
COPY dependency-reduced-pom.xml .
COPY src/ src/
RUN mvn package

FROM openjdk:8
ARG APP_VERSION=1.0
WORKDIR /app

RUN apt-get update
RUN apt-get install cron -y

COPY --from=builder "/app/target/podyn-${APP_VERSION}.jar" /app/podyn.jar

COPY podyn-cron /etc/cron.d/podyn-cron
RUN chmod 0644 /etc/cron.d/podyn-cron
RUN crontab /etc/cron.d/podyn-cron
RUN touch /var/log/cron.log

COPY stop.sh /app/
RUN chmod +x /app/stop.sh
COPY podyn-service /etc/init.d/podyn
RUN chmod +x /etc/init.d/podyn
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
