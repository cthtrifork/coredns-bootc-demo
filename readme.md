
# CoreDNS Bootc Image

This project provides an OS image with a pre-configured [CoreDNS](https://coredns.io/) service running on port 53, exposing DNS for the DEV environment. The image is built and provisioned using [bootc](https://bootc-dev.github.io/bootc/), eliminating the need for configuration management tools like Ansible, Terraform, or Chef.

## Features
- CoreDNS container (1.13.13) running as a systemd service
- DNS exposed on TCP/UDP port 53
- Read-only container filesystem for security
- Configurable via `/etc/coredns/Corefile` (mounted into the container)
- Auto-update support

## Quick Start


1. **Start a local registry**

```sh
podman run -d --name local-registry \
  -p 5000:5000 \
  docker.io/library/registry:3
```

1. **Build & push the image**

```sh
podman build -f ./Containerfile -t localhost/coredns-bootc:v1 ./
podman tag \
  localhost/coredns-bootc:v1 \
  localhost:5000/coredns-bootc:v1
podman push -q --tls-verify=false \
  localhost:5000/coredns-bootc:v1
```

1. **Build qcow2 using bootc-image-builder**

```sh
sudo podman pull docker.io/coredns/coredns:1.13.1
sudo podman pull -q --tls-verify=false localhost:5000/coredns-bootc:v1
sudo podman run --rm -it --privileged \
  -v /var/lib/containers/storage:/var/lib/containers/storage:Z \
  -v "./out":/output:Z \
  -v "./config.toml":/config.toml:ro \
  --security-opt label=type:unconfined_t \
  --pull newer \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --rootfs xfs --type qcow2 \
  localhost:5000/coredns-bootc:v1
```
1. **Test container locally**

```sh
sudo podman run --rm -ti localhost:5000/coredns-bootc:v1
sudo podman exec -it <container_name> bash
```

1. **Test VM locally**

```sh
sudo qemu-system-x86_64 \
  -name bootc-vm \
  -enable-kvm \
  -cpu host \
  -m 4G \
  -drive if=virtio,file="./qcow2/disk.qcow2",format=qcow2 \
  -net nic,model=virtio \
  -net user,hostfwd=tcp::5000-:5000 \
  -net user,hostfwd=tcp::2222-:22 \
  -display none \
  -monitor unix:/tmp/qemu-monitor-sock,server,nowait \
  -daemonize
```

```sh
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 \
      -p 2222 \
      cthtrifork@localhost \
      "sudo bootc status"
```

**VM Requirements:**
- Use the vmdk or qcow2 as the hard drive
- Minimum 2GiB memory recommended
- Disk size can be expanded after first boot

## Configuration
- The CoreDNS container is defined in [`coredns.container`](./coredns.container). See [Podman Quadlet](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) and [Fedora bootc container embedding](https://docs.fedoraproject.org/en-US/bootc/embedding-containers/#_embedding_quadlets_into_a_bootc_image) for details.
- The DNS configuration is provided via [`Corefile`](./Corefile) and mounted into the container at runtime.

## Troubleshooting & Debugging

### Build Issues
- Use `--no-cache` with Podman if you encounter build problems.

### VM Access & DNS Verification
```sh
# SSH into the VM
ssh <user>@<vm_ip>

# Verify DNS is working
dig @<vm_ip> google.com

# Force update (if needed)
sudo systemctl start bootc-fetch-apply-updates.service
```

### Service Status
```sh
# Check CoreDNS service status
systemctl status coredns.service
# View logs
journalctl -u coredns.service -b
# Show service file
systemctl cat coredns.service
```

## References
- [bootc documentation](https://bootc-dev.github.io/bootc/)
- [Fedora bootc guide](https://docs.fedoraproject.org/en-US/bootc/getting-started/)
- [CoreDNS documentation](https://coredns.io/)