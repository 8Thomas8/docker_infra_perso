FROM alpine:3.10

LABEL maintainer="Mark <mark.binlab@gmail.com>"

ARG HOME=/var/lib/bastion

ARG USER=bastion
ARG GROUP=bastion
ARG UID=4096
ARG GID=4096

ENV HOST_KEYS_PATH_PREFIX="/usr"
ENV HOST_KEYS_PATH="${HOST_KEYS_PATH_PREFIX}/etc/ssh"

COPY bastion /usr/sbin/bastion

#Creation du user
RUN addgroup -S -g ${GID} ${GROUP} \
    && adduser -D -h ${HOME} -s /bin/ash -g "${USER} service" \
           -u ${UID} -G ${GROUP} ${USER} \
    && sed -i "s/${USER}:!/${USER}:*/g" /etc/shadow \
    && set -x \
    && apk add --no-cache openssh-server

#Message sympa de demarrage
RUN echo "Bienvenue sur le bastion!" > /etc/motd 

RUN chmod +x /usr/sbin/bastion \
    && mkdir -p ${HOST_KEYS_PATH} \
    && mkdir /etc/ssh/auth_principals \
    && echo "bastion" > /etc/ssh/auth_principals/bastion

EXPOSE 22/tcp

VOLUME ${HOST_KEYS_PATH}

ENTRYPOINT ["bastion"]
