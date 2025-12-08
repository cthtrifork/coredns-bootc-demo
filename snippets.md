```sh
RUN mkdir -p /etc/motd.d && \
    cowsay "I am a bootable container" | sudo tee /etc/motd.d/10-cowsay-motm > /dev/null
```