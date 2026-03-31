#!/bin/sh
set -e

# Start rsyslog in foreground (we background it)
rsyslogd -n -f /etc/rsyslog-minimal.conf &

# Wait for /dev/log to exist (this is the UDS through which syslog operates)
while [ ! -S /dev/log ]; do
    sleep 0.05
done

# Start tftpd
in.tftpd --foreground \
    --create \
    -vvv \
    --address :${TFTP_PORT} \
    --port-range 51234:51234 \
    --user ${TFTP_USER} \
    --secure ${TFTP_ROOT}
