FROM docker.io/almalinux/9-base:9.7@sha256:49dba63e0f383abdcefb67fea2247a519036cd90143d433e53752b73a4496b86

LABEL org.opencontainers.image.title = "tftp-test-srv" \
      org.opencontainers.image.version = "0.1.0" \
      org.opencontainers.image.description = "Bare-bones TFTP server listening on a non-privileged port and responding on a limited range of ports, intended for testing purposes." \
      org.opencontainers.image.authors = "Abdulla Almosalami @memphis242" \
      org.opencontainers.image.created = "2026-03-28"

# Install packages we want
RUN dnf install -y tftp-server && \
    dnf -y clean all

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
