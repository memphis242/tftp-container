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
    --secure ${TFTP_ROOT} &

# Set up SIGTERM to be forwarded to tftpd and rsyslogd from sh...
# An init system would be best here, but the smaller init systems such as tini
# and dumb-init were not available, and systemd would be overkill, so doing
# this manual trapping for now...
TFTPD_PID=$!

# Forward signals
trap 'kill -TERM $TFTPD_PID $RSYSLOG_PID' TERM INT

# Wait for tftpd
wait $TFTPD_PID
