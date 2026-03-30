FROM docker.io/almalinux/9-minimal:9.7@sha256:6d23899d5dc580aa5cebcbf751928f502fa7452360afe396ec657de99f006669 \
     AS base

LABEL org.opencontainers.image.title = "tftp-test-srv" \
      org.opencontainers.image.version = "0.2.0" \
      org.opencontainers.image.description = "Bare-bones TFTP server listening on a non-privileged port and responding on a limited range of ports, intended for testing purposes." \
      org.opencontainers.image.authors = "Abdulla Almosalami @memphis242" \
      org.opencontainers.image.created = "2026-03-28"

# Install packages we want in the base image
RUN microdnf install -y \
    tftp-server \
&& microdnf -y clean all

# Document TFTP setup
ENV TFTP_ROOT=/tftp-root \
    TFTP_USER=tftpuser \
    TFTP_PORT=50069

# Add a non-privileged TFTP user, as general good practice. I don't need a
# home directory to be created or allow for su to this, so I'll make the user
# a system user /w nologin.
RUN useradd --system --shell /sbin/nologin ${TFTP_USER}

# Create the TFTP root directory and set ownership for TFTP root directory - owner
# should match what we -u / --user later for tftpd
RUN mkdir -p ${TFTP_ROOT} && \
    chown -R ${TFTP_USER}:${TFTP_USER} ${TFTP_ROOT} && \
    chmod 0755 ${TFTP_ROOT}

# Copy test files
COPY testfiles/ /tftp-root/

# Set current working directory to TFTP root
WORKDIR /tftp-root

# dbg image --------------------------------------------------------------------
# An image that includes syslog to help /w troubleshooting.
FROM base AS dbg

# Install rsyslog to be our syslog daemon
RUN microdnf install -y \
    rsyslog \
    procps-ng \
    iproute \
    tcpdump \
    strace \
&& microdnf -y clean all

# Set up syslog messages to also go to podman logs in addition to /var/log/messages,
# if only for the convenience of it.
RUN echo '*.* /dev/stdout' > /etc/rsyslog.d/console.conf

# Drop privileges -- We can't do this the usual USER way because tftpd needs elevated
#                    privileges for chroot(), setuid(), etc. So, the drop in
#                    privileges will be accomplished via -u / --user option and
#                    tftpd will setuid() to drop the privileges accordingly.
#USER ${TFTP_USER}

# Run TFTP server
CMD sh -c "\
    rsyslogd && \
    in.tftpd --foreground \
    --create \
    -vvv \
    --address :${TFTP_PORT} \
    --port-range 51234:51234 \
    --user ${TFTP_USER} \
    --secure ${TFTP_ROOT} \
"

# rel image --------------------------------------------------------------------
# An image without syslog.
FROM base AS rel

# Run TFTP server
CMD in.tftpd --foreground \
    --create \
    -vvv \
    --address :${TFTP_PORT} \
    --port-range 51234:51234 \
    --user ${TFTP_USER} \
    --secure ${TFTP_ROOT}

