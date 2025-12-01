FROM quay.io/centos-bootc/centos-bootc:stream9

#setup sudo to not require password
RUN echo "%wheel        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/wheel-sudo

# Write some metadata
RUN echo VARIANT="CoreDNS bootc OS" && echo VARIANT_ID=com.gitlab.energinet.kube-kraken-images >> /usr/lib/os-release

# Install utilities
RUN dnf -y install qemu-guest-agent \
    firewalld \
    && dnf clean all

# Setup CoreDNS
COPY coredns.container /usr/share/containers/systemd
# Ensure logical pre-pull of image
RUN ln -s /usr/share/containers/systemd/coredns.container /usr/lib/bootc/bound-images.d/coredns.container
COPY Corefile /etc/coredns/

# Hack to allow pulling from local insecure registry
RUN mkdir -p /etc/containers/registries.conf.d \
 && printf '%s\n' \
      '[[registry]]' \
      'location = "10.0.2.2:5000"' \
      'insecure = true' \
    > /etc/containers/registries.conf.d/99-local-registry.conf

# Networking
EXPOSE 53
RUN firewall-offline-cmd --add-port 53/udp && \
    firewall-offline-cmd --add-port 53/tcp && \
    firewall-offline-cmd --add-service=dns

# Clean up caches in the image and lint the container
RUN rm /var/{cache,lib}/dnf /var/lib/rhsm /var/cache/ldconfig -rf
RUN bootc container lint