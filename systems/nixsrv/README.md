# List containers
```bash
nixos-container list
```

# bash of container
```bash
udo nixos-container root-login {CONTAINER_NAME}
```

# Start tailscale on container
```bash
tailscale up --ssh --advertise-tags=tag:nixsrv-container
```

# Start serve on container
```bash
tailscale serve --bg {PORT}
```