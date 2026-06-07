FROM alpine:3.21
ARG APK_MIRROR=dl-cdn.alpinelinux.org
RUN sed -i "s|dl-cdn.alpinelinux.org|${APK_MIRROR}|g" /etc/apk/repositories && \
    apk add --no-cache dash coreutils python3
COPY tests/test_suite.sh /test_suite.sh
RUN chmod +x /test_suite.sh
ENTRYPOINT ["/bin/sh", "/test_suite.sh"]
