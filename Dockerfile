#
# jetty web server.
#

FROM alpine:3.5
MAINTAINER Yusuke Kawatsu "https://github.com/megmogmog1965"

# Set correct environment variables.
ENV HOME=/root \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    JAVA_HOME=/opt/jdk \
    PATH=${PATH}:/opt/jdk/bin \
    JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=131 \
    JAVA_VERSION_BUILD=11 \
    JAVA_VERSION_HASH=d54c1d3a095b4ff2b6607d096fa80163 \
    GLIBC_VERSION=2.23-r3

# install utility commands.
RUN apk upgrade --update && \
    apk add --no-cache --update libstdc++ curl ca-certificates bash unzip

# libs.
RUN set -ex && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    apk add --no-cache --allow-untrusted /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib

# java8.
RUN mkdir /opt && \
    curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/java.tar.gz \
      http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_VERSION_HASH}/jdk-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz && \
    gunzip /tmp/java.tar.gz && \
    tar -C /opt -xf /tmp/java.tar && \
    ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk && \
    sed -i s/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=10/ $JAVA_HOME/jre/lib/security/java.security && \
    apk del glibc-i18n && \
    rm -rf /opt/jdk/*src.zip \
           /opt/jdk/lib/missioncontrol \
           /opt/jdk/lib/visualvm \
           /opt/jdk/lib/*javafx* \
           /opt/jdk/jre/plugin \
           /opt/jdk/jre/bin/javaws \
           /opt/jdk/jre/bin/jjs \
           /opt/jdk/jre/bin/orbd \
           /opt/jdk/jre/bin/pack200 \
           /opt/jdk/jre/bin/policytool \
           /opt/jdk/jre/bin/rmid \
           /opt/jdk/jre/bin/rmiregistry \
           /opt/jdk/jre/bin/servertool \
           /opt/jdk/jre/bin/tnameserv \
           /opt/jdk/jre/bin/unpack200 \
           /opt/jdk/jre/lib/javaws.jar \
           /opt/jdk/jre/lib/deploy* \
           /opt/jdk/jre/lib/desktop \
           /opt/jdk/jre/lib/*javafx* \
           /opt/jdk/jre/lib/*jfx* \
           /opt/jdk/jre/lib/amd64/libdecora_sse.so \
           /opt/jdk/jre/lib/amd64/libprism_*.so \
           /opt/jdk/jre/lib/amd64/libfxplugins.so \
           /opt/jdk/jre/lib/amd64/libglass.so \
           /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
           /opt/jdk/jre/lib/amd64/libjavafx*.so \
           /opt/jdk/jre/lib/amd64/libjfx*.so \
           /opt/jdk/jre/lib/ext/jfxrt.jar \
           /opt/jdk/jre/lib/ext/nashorn.jar \
           /opt/jdk/jre/lib/oblique-fonts \
           /opt/jdk/jre/lib/plugin.jar \
           /tmp/* /var/cache/apk/*

# install jetty.
RUN curl -LO "http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/9.4.5.v20170502/jetty-distribution-9.4.5.v20170502.zip" && \
    unzip jetty-distribution-9.4.5.v20170502.zip && \
    mv jetty-distribution-9.4.5.v20170502 /var/lib/jetty && \
    ln -s /var/lib/jetty/bin/jetty.sh /etc/init.d/jetty && \
    rm -f jetty-distribution-9.4.5.v20170502.zip

# jetty default settings.
RUN mkdir -p /etc/default/
ADD jetty /etc/default/
ADD start.ini /var/lib/jetty/
ADD webdefault.xml console-capture.xml jetty-jmx.xml /var/lib/jetty/etc/

# jetty debug settings.
RUN sed -i -e 's/^RUN_ARGS=.*$/DEBUG_ARGS=(-Xdebug -agentlib:jdwp=transport=dt_socket,address=8585,server=y,suspend=n)\nRUN_ARGS=(\
${JAVA_OPTIONS[@]} ${DEBUG_ARGS[@]} -jar "$JETTY_START" ${JETTY_ARGS[*]})/g' /etc/init.d/jetty

# port mapping.
EXPOSE 8080 8585 1099

# (optional) deploy *.war.
COPY deployment/* /var/lib/jetty/webapps/

# entrypoint.
#ENTRYPOINT /etc/init.d/jetty run
CMD [ "/etc/init.d/jetty", "run" ]
