FROM ubuntu:jammy-20240416
#FROM python:3.10-bookworm

ARG BUILD_DATE
ARG VCS_REF

# https://github.com/saltstack/salt/releases
ENV SALT_VERSION_MAJ="3007"
ENV SALT_VERSION_MIN="0"
ENV IMAGE_REVISION="_1"
ENV IMAGE_VERSION="${SALT_VERSION_MAJ}.${SALT_VERSION_MIN}${IMAGE_REVISION}"

ENV SALT_DOCKER_DIR="/etc/docker-salt" \
    SALT_ROOT_DIR="/etc/salt" \
    SALT_CACHE_DIR='/var/cache/salt' \
    SALT_USER="salt" \
    SALT_HOME="/home/salt"

ENV SALT_BUILD_DIR="${SALT_DOCKER_DIR}/build" \
    SALT_RUNTIME_DIR="${SALT_DOCKER_DIR}/runtime" \
    SALT_DATA_DIR="${SALT_HOME}/data"

ENV SALT_CONFS_DIR="${SALT_DATA_DIR}/config" \
    SALT_KEYS_DIR="${SALT_DATA_DIR}/keys" \
    SALT_BASE_DIR="${SALT_DATA_DIR}/srv" \
    SALT_LOGS_DIR="${SALT_DATA_DIR}/logs" \
    SALT_FORMULAS_DIR="${SALT_DATA_DIR}/3pfs"

RUN mkdir -p ${SALT_BUILD_DIR}
WORKDIR ${SALT_BUILD_DIR}

# Install packages
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --yes --quiet --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gettext-base \
    git \
    gpg \
    gpg-agent \
    inotify-tools \
    locales \
    logrotate \
    net-tools \
    openssh-client \
    pkg-config \
    psmisc \
    python3-openssl \
    sudo \
    supervisor \
    tzdata \
    wget \
 && DEBIAN_FRONTEND=noninteractive update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
    locale-gen en_US.UTF-8 \
    dpkg-reconfigure locales \
 && DEBIAN_FRONTEND=noninteractive apt-get clean --yes \
 && rm -rf /var/lib/apt/lists/*

# Install saltstack
COPY assets/build ${SALT_BUILD_DIR}
RUN bash ${SALT_BUILD_DIR}/install.sh

COPY assets/runtime ${SALT_RUNTIME_DIR}
RUN chmod -R +x ${SALT_RUNTIME_DIR}

COPY assets/sbin/* /usr/local/sbin/

# Cleaning tasks
RUN rm -rf "${SALT_BUILD_DIR:?}"/*

# Entrypoint
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh

# Shared resources
EXPOSE 4505 4506 8000
RUN mkdir -p "${SALT_BASE_DIR}" "${SALT_FORMULAS_DIR}" "${SALT_KEYS_DIR}" "${SALT_CONFS_DIR}" "${SALT_LOGS_DIR}"
VOLUME [ "${SALT_KEYS_DIR}", "${SALT_LOGS_DIR}" ]

LABEL org.opencontainers.image.title="Dockerized Salt Master"
LABEL org.opencontainers.image.description="salt-master ${SALT_VERSION_MAJ}.${SALT_VERSION_MIN} containerized"
LABEL org.opencontainers.image.documentation="https://github.com/coralhl/salt-master-docker/blob/${IMAGE_VERSION}/README.md"
LABEL org.opencontainers.image.url="https://github.com/coralhl/salt-master-docker"
LABEL org.opencontainers.image.source="https://github.com/coralhl/salt-master-docker.git"
LABEL org.opencontainers.image.authors="Coral XCIII <coral@xciii.ru>"
LABEL org.opencontainers.image.vendor="coralhl"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.base.name="ubuntu:jammy-20240416"
LABEL org.opencontainers.image.licenses="MIT"

WORKDIR ${SALT_HOME}
ENTRYPOINT [ "/sbin/entrypoint.sh" ]
CMD [ "app:start" ]
