FROM gitea/gitea:1.14.5

LABEL maintainer="sebastien.pondichy@gmail.com"

RUN apk --no-cache add \
    python3 \
    py3-pip \
    && pip3 install s3cmd

COPY /scripts /scripts