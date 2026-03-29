FROM docker.io/almalinux/9-minimal:9.7@sha256:6d23899d5dc580aa5cebcbf751928f502fa7452360afe396ec657de99f006669

LABEL org.opencontainers.image.title = "tftp-test-srv" \
      org.opencontainers.image.version = "0.1.0" \
      org.opencontainers.image.description = "Bare-bones TFTP server listening on a non-privileged port and responding on a limited range of ports, intended for testing purposes." \
      org.opencontainers.image.authors = "Abdulla Almosalami @memphis242" \
      org.opencontainers.image.created = "2026-03-28"

# Install packages we want
RUN microdnf install -y tftp-server && \
    microdnf -y clean all

# Document TFTP setup
ENV TFTP_ROOT=/tftp-root \
    TFTP_USER=tftpuser \
    TFTP_PORT=50069

# Create the TFTP root directory
RUN mkdir -p ${TFTP_ROOT}

# Add a non-privileged TFTP user, as general good practice.
RUN useradd --system --shell /sbin/nologin ${TFTP_USER} && \
    chown -R ${TFTP_USER}:${TFTP_USER} ${TFTP_ROOT}

# Copy test files
COPY testfiles/ /tftp-root/

# Set no ownership for TFTP root directory (needed for tftpd to be able to PUT)
RUN chown -R nobody:nobody ${TFTP_ROOT} && \
    chmod 0755 ${TFTP_ROOT}

# Set current working directory to TFTP root
WORKDIR /tftp-root

# Drop privileges -- Unfortunately, can't do this because tftpd seems to expect
#                    to be started up as root, or it will silently fail...
#USER ${TFTP_USER}

# Run TFTP server
CMD in.tftpd -L \
    --create \
    -vvv \
    --address :${TFTP_PORT} \
    --secure ${TFTP_ROOT} \
    --port-range 51234:51234
