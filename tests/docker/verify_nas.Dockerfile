FROM alpine:3.21
COPY tests/verify_nas.sh /verify_nas.sh
RUN chmod +x /verify_nas.sh
ENTRYPOINT ["/bin/sh", "/verify_nas.sh"]
