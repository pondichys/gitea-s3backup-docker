FROM gitea/gitea:1.21.11

LABEL maintainer="sebastien.pondichy@gmail.com"

COPY /scripts /scripts

RUN apk --no-cache add \
	s3cmd
#    python3 \
#    py3-pip \
#    && pip3 install s3cmd \
    && chmod u+x /scripts/gitea-backup.sh \
    && mkdir -p /etc/s3cmd
