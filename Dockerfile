FROM    ubuntu:20.04

# for the VNC connection
EXPOSE 5900
# for the browser VNC client
EXPOSE 5901
# Use environment variable to allow custom VNC passwords
ENV VNC_PASSWD=123456

#RUN echo "deb https://repo.huaweicloud.com/ubuntu-ports/ focal main contrib non-free" > /etc/apt/sources.list
#RUN echo "deb https://repo.huaweicloud.com/ubuntu-ports/ focal-updates main contrib non-free" >> /etc/apt/sources.list
#RUN echo "deb https://repo.huaweicloud.com/ubuntu-ports/ focal-backports main contrib non-free" >> /etc/apt/sources.list
#RUN echo "deb https://repo.huaweicloud.com/ubuntu-ports/ focal-security main contrib non-free" >> /etc/apt/sources.list

# Make sure the dependencies are met
ENV APT_INSTALL_PRE="apt -o Acquire::ForceIPv4=true update && DEBIAN_FRONTEND=noninteractive apt -o Acquire::ForceIPv4=true install -y --no-install-recommends"
ENV APT_INSTALL_POST="&& apt clean -y && rm -rf /var/lib/apt/lists/*"
# Make sure the dependencies are met
RUN eval ${APT_INSTALL_PRE} tigervnc-standalone-server tigervnc-common fluxbox eterm xterm git net-tools python3 python3-dev  python3-numpy ca-certificates scrot  wget libnss3 libxss1 desktop-file-utils libasound2 ttf-wqy-zenhei libgtk-3-0 libgbm1 libnotify4 xdg-utils libsecret-common libsecret-1-0 libindicator3-7 libdbusmenu-glib4 libdbusmenu-gtk3-4 libappindicator3-1 apt-utils  libxtst6 ${APT_INSTALL_POST}
RUN wget https://issuepcdn.baidupcs.com/issue/netdisk/LinuxGuanjia/4.3.0/baidunetdisk_4.3.0_arm64.deb && dpkg -i baidunetdisk_4.3.0_arm64.deb && rm baidunetdisk_4.3.0_arm64.deb


# Install VNC. Requires net-tools, python and python-numpy
RUN git clone --branch v1.3.0 --single-branch https://github.com/novnc/noVNC.git /opt/noVNC
RUN git clone --branch v0.10.0 --single-branch https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify
RUN ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Add menu entries to the container
RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"Xterm\" command=\"xterm -ls -bg black -fg white\"" >> /usr/share/menu/custom-docker && update-menus
RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"BaiduNetdisk\" command=\"/opt/baidunetdisk/baidunetdisk\"" >> /usr/share/menu/baidunetdisk && update-menus

# Set timezone to UTC
RUN ln -snf /usr/share/zoneinfo/UTC /etc/localtime && echo UTC > /etc/timezone

# Add in a health status
HEALTHCHECK --start-period=10s CMD bash -c "if [ \"`pidof -x Xtigervnc | wc -l`\" == "1" ]; then exit 0; else exit 1; fi"

RUN echo 'root:passworq' | chpasswd
# Add in non-root user
ENV UID_OF_DOCKERUSER 1000
RUN useradd -m -s /bin/bash -g users -u ${UID_OF_DOCKERUSER} dockerUser
RUN chown -R dockerUser:users /home/dockerUser && chown dockerUser:users /opt

USER dockerUser

# Copy various files to their respective places
COPY --chown=dockerUser:users container_startup.sh /opt/container_startup.sh
COPY --chown=dockerUser:users x11vnc_entrypoint.sh /opt/x11vnc_entrypoint.sh
# Subsequent images can put their scripts to run at startup here
RUN mkdir /opt/startup_scripts

ENTRYPOINT ["/opt/container_startup.sh"]
