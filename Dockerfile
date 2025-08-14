FROM docker.gitea.com/gitea:1.24.5

LABEL maintainer="sebastien.pondichy@gmail.com"

COPY /scripts /scripts

RUN apk --no-cache add \
	s3cmd \
	&& chmod u+x /scripts/gitea-backup.sh \
	&& mkdir -p /etc/s3cmd
