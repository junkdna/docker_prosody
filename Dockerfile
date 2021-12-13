FROM debian:bullseye-slim as build
LABEL org.opencontainers.image.authors="theidsieck@leenox.de,dominik.laton@web.de"

RUN apt-get update && apt-get dist-upgrade -yqq && apt-get install -yqq \
	curl \
	gnupg \
	less \
	libidn11-dev \
	liblua5.1-dev \
	libnginx-mod-http-perl \
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

ARG PROSODY_VERSION=0.11.10
ARG EXTRA_PLUGINS="\
	blocking \
	bookmarks \
	cloud_notify \
	extdisco \
	external_services \
	filter_chatstates \
	http_upload_external \
	smacks \
	throttle_presence \
	turncredentials \
	vcard_muc \
"

RUN curl https://prosody.im/downloads/source/prosody-${PROSODY_VERSION}.tar.gz > /prosody.tar.gz

# TODO verify source, but where is the key?!
# COPY prosody-source-sign.key
# RUN curl https://prosody.im/downloads/source/prosody-${PROSODY_VERSION}.tar.gz.asc > /prosody.tar.gz.asc
# RUN gpg --verify /prosody.tar.gz.asc /prosody.tar.gz

RUN mkdir -p /usr/src && tar -xzf /prosody.tar.gz -C /usr/src && cd /usr/src/prosody-${PROSODY_VERSION} && ./configure --prefix=/usr && make && make install
RUN hg clone 'https://hg.prosody.im/prosody-modules/' /usr/src/prosody-modules
RUN mkdir -p /out/prosody/usr/bin
RUN mkdir -p /out/prosody/usr/lib
RUN mkdir -p /out/prosody/etc
RUN cp /usr/bin/prosody* /out/prosody/usr/bin/
RUN cp -r /usr/lib/prosody /out/prosody/usr/lib
RUN cp -r /etc/prosody /out/prosody/etc
RUN mkdir -p /out/prosody/usr/lib/prosody/modules-extra
RUN for p in ${EXTRA_PLUGINS}; do cp -r "/usr/src/prosody-modules/mod_$p" "/out/prosody/usr/lib/prosody/modules-extra"; done

RUN mkdir -p /usr/local/lib/perl
RUN curl https://raw.githubusercontent.com/weiss/ngx_http_upload/master/upload.pm > /usr/local/lib/perl/upload.pm
RUN sed -i "s#uri_prefix_components = 0#uri_prefix_components = 1#g" /usr/local/lib/perl/upload.pm
RUN mkdir -p /out/prosody/usr/local/lib/perl
RUN cp /usr/local/lib/perl/upload.pm /out/prosody/usr/local/lib/perl


FROM debian:bullseye-slim
LABEL org.opencontainers.image.authors="theidsieck@leenox.de,dominik.laton@web.de"
EXPOSE 80 5222 5269

RUN apt-get update && apt-get dist-upgrade -yqq && apt-get install -yqq \
	curl \
	libidn11 \
	libnginx-mod-http-perl \
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
	nginx-extras \
	procps \
	ssmtp \
	supervisor


RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
	dpkg-reconfigure --frontend noninteractive tzdata

RUN useradd -s /bin/bash -r -M -d /usr/lib/prosody /prosody

COPY --from=build /out/prosody /

COPY index.html /srv/www/
COPY nginx.conf /etc/nginx/
COPY run.sh /usr/bin/
COPY supervisord.conf /etc/

VOLUME ["/etc/prosody", "/certs"]

ENTRYPOINT ["/usr/bin/run.sh"]
