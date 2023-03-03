FROM pihole/pihole:latest

##### Install dependencies
RUN apt update && apt install --no-install-recommends --yes openssh-server git sudo rsync && mkdir -p /run/sshd

##### Install gravity-sync
RUN curl -sSL https://raw.githubusercontent.com/vmstan/gs-install/main/gs-install.sh | GS_DOCKER=1 bash
RUN cd /etc/gravity-sync/.gs && git remote set-url origin https://github.com/systemofapwne/gravity-sync.git && git pull && gravity-sync upgrade

##### Copy files to container
COPY /root /

##### Base config
# Default SSH Port
ENV GS_SSH_PORT=2222
# SSH user for accessing this container
ENV LOCAL_USER=gs
# If 'LOCAL_PASSWORD' is not set, a random SSH password for the user 'LOCAL_USER' will be set on each container boot. The password can be then retrieved via 'docker exec -it <container_name> cat password'. Further interaction between the containers will user ssh-keys and wont rely on that password. The password is only for initialisation.
#ENV LOCAL_PASSWORD=<RANDOM>
# Mode of automatic sync of this container (sync/smart, push, pull)
ENV GS_AUTO_MODE=sync

# Exposed ports for the container
EXPOSE 2222
EXPOSE 53
EXPOSE 67/udp
EXPOSE 80/tcp

VOLUME /config
