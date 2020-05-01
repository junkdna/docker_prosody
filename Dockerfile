FROM debian:stretch
MAINTAINER Tillmann Heidsieck <theidsieck@leenox.de>
EXPOSE 80 5222 5269

RUN apt-get update && apt-get dist-upgrade -yqq && apt-get install -yqq \
	curl \
	gnupg \
	less \
	libidn11-dev \
	liblua5.1-dev \
	libssl-dev \
	lua-bitop \
	lua-dbi-mysql \
	lua-dbi-postgresql \
	lua-dbi-sqlite3 \
	lua-event \
	lua-expat \
	lua-filesystem \
	lua-sec \
	lua-socket \
	lua5.1 \
	make \
	mercurial \
	nginx-extras \
	procps \
	ssmtp \
	supervisor


RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
	dpkg-reconfigure --frontend noninteractive tzdata

ARG PROSODY_VERSION=0.11.5
ARG EXTRA_PLUGINS="\
	blocking \
	extdisco \
	filter_chatstates \
	http_upload_external \
	smacks \
	throttle_presence \
	turncredentials \
"

RUN useradd -s /bin/bash -r -M -d /usr/lib/prosody /prosody

RUN curl https://prosody.im/downloads/source/prosody-${PROSODY_VERSION}.tar.gz > /prosody.tar.gz

# TODO verify source, but where is the key?!
# COPY prosody-source-sign.key
# RUN curl https://prosody.im/downloads/source/prosody-${PROSODY_VERSION}.tar.gz.asc > /prosody.tar.gz.asc
# RUN gpg --verify /prosody.tar.gz.asc /prosody.tar.gz

RUN mkdir -p /usr/src && tar -xzf /prosody.tar.gz -C /usr/src && cd /usr/src/prosody-${PROSODY_VERSION} && ./configure --prefix=/usr && make && make install
RUN hg clone 'https://hg.prosody.im/prosody-modules/' /usr/src/prosody-modules
RUN mkdir -p /usr/lib/prosody/modules-extra
RUN for p in ${EXTRA_PLUGINS}; do ln -s "/usr/src/prosody-modules/mod_$p" "/usr/lib/prosody/modules-extra/mod_$p"; done

COPY index.html /srv/www/
COPY nginx.conf /etc/nginx/
COPY run.sh /usr/bin/
COPY supervisord.conf /etc/

VOLUME ["/etc/prosody", "/certs"]

ENTRYPOINT ["/usr/bin/run.sh"]
