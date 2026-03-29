# TFTP Test Server Container (Podman)
TODO
```bash
# Podman commands
podman build --target [dbg|rel] --tag tftp-test-srv:0.2.0 .
podman images
podman run --rm --network=host <img_name>
podman ps
podman exec -it <container_name> sh

# tftp commands
in.tftpd -L -c -vvv -a :<tftp_port> -s <tftp_root_dir>
tftp -vvv localhost <tftp_port>
> get <fname_on_srv>
> put <fname_on_host>
```

### Notes
- `rsyslog` simply added 10MB to the container img
