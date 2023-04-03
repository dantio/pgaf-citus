# dantio/pgaf-citus
FROM debian:bullseye-slim

ARG PGVERSION=15
ARG CITUS=postgresql-15-citus-11.2

LABEL maintainer="dantio"

# explicitly set user/group IDs
RUN set -eux;
RUN groupadd -r postgres --gid=999
RUN useradd -r -g postgres --uid=999 --home-dir=/var/lib/postgresql --shell=/bin/bash postgres

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     ca-certificates \
     gnupg \
     curl \
     sudo \
     postgresql-common \
  && rm -rf /var/lib/apt/lists/*

# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN set -eux; \
  if [ -f /etc/dpkg/dpkg.cfg.d/docker ]; then \
  # if this file exists, we're likely in "debian:xxx-slim", and locales are thus being excluded so we need to remove that exclusion (since we need locales)
    grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; \
    sed -ri '/\/usr\/share\/locale/d' /etc/dpkg/dpkg.cfg.d/docker; \
    ! grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; \
  fi; \
  apt-get update; apt-get install -y --no-install-recommends locales; rm -rf /var/lib/apt/lists/*; \
  localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8


# we use apt.postgresql.org
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main ${PGVERSION}" > /etc/apt/sources.list.d/pgdg.list
RUN echo "deb-src http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main ${PGVERSION}" > /etc/apt/sources.list.d/pgdg.src.list

# bypass initdb of a "main" cluster
RUN echo 'create_main_cluster = false' | sudo tee -a /etc/postgresql-common/createcluster.conf

# Setup Citus
RUN curl https://install.citusdata.com/community/deb.sh | sudo bash
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ${CITUS} \
    postgresql-${PGVERSION}-topn=2.5.0.citus-1 \
    postgresql-${PGVERSION}-hll=2.17.citus-1 \
    postgresql-${PGVERSION}-cron \
    pg-auto-failover-cli \
    postgresql-${PGVERSION}-auto-failover \
  && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos '' pgaf
RUN adduser pgaf sudo
RUN adduser pgaf postgres
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

ENV PGHOME /var/lib/postgresql
ENV PGDATA "${PGHOME}/data"
RUN mkdir -p "$PGHOME" && chown -R pgaf:postgres "$PGHOME"
RUN mkdir -p /var/backup && chown -R pgaf:postgres /var/backup

ENV XDG_DATA_HOME "${PGHOME}/.local/share"
ENV XDG_CONFIG_HOME "${PGHOME}/.config"
ENV PGCONF /etc/pgaf
RUN mkdir -p "$PGCONF"

# add cutom postgressql.conf
RUN echo "include_if_exists '${PGCONF}/postgresql.conf'" >> /usr/share/postgresql/${PGVERSION}/postgresql.conf.sample
# add citus to default PostgreSQL config
# RUN echo "shared_preload_libraries='citus'" >> /usr/share/postgresql/${PGVERSION}/postgresql.conf.sample

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
COPY wait-for-it.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wait-for-it.sh

USER pgaf

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/postgresql/${PGVERSION}/bin

STOPSIGNAL SIGINT
EXPOSE 5432

VOLUME $PGHOME

ENTRYPOINT ["docker-entrypoint.sh"]
