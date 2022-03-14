# Firefox over VNC and RDP
####### build building stage container
FROM    ubuntu:20.04 AS builder
# Make sure the package repository is up to date
RUN     apt-get update 

# Install xdummy, xvfb in order to create a 'fake' display and firefox
RUN     apt-get install -y xserver-xorg-video-dummy xvfb
# Install vnc
RUN     apt-get install -y x11vnc 

#should move this line to build stage
#for Xdummy to work, we need to update Xdummy script so it links the Xdummy.so with "-ldl" flag
RUN   apt-get install -y build-essential
RUN   sed -i -e "s/^ *cc -shared -fPIC.*/& -ldl/" /usr/bin/Xdummy
RUN   /usr/bin/Xdummy -install


######  build running container
FROM ubuntu:20.04 AS runner
RUN   apt-get update && \
      apt-get install -y vim curl && \
      apt-get install -y xserver-xorg-video-dummy xvfb  && \
      apt-get install -y xscreensaver  && \
      apt-get install -y xrdp x11vnc && \
      apt-get install -y xfce4 && \
      apt-get install -y firefox && \
      apt-get install -y ffmpeg  && \
      apt-get clean && \
      mkdir ~/.vnc && \
      curl https://xpra.org/xorg.conf -o /usr/share/X11/xorg.conf.d/00-xorg.conf && \
      sed -i -e "\$a startxfce4\n" -e "s/.* \/etc\/X11\/Xsession/##&/1"  /etc/xrdp/startwm.sh && \
      sed -i  -e "s/Virtual 8192 4096/Virtual 1920 1080/"  /usr/share/X11/xorg.conf.d/00-xorg.conf

COPY --from=builder /usr/bin/Xdummy.so /usr/bin/Xdummy.so

EXPOSE 5900
EXPOSE 3389

RUN    echo '#!/bin/bash \n\
DEFAULT_PASSWORD=XL_mMLMZ8xPTIR9G \n\
RANDOM_PASSWORD=$(openssl rand -base64 12) \n\
x11vnc -storepasswd ${RANDOM_PASSWORD:-$DEFAULT_PASSWORD} ~/.vnc/passwd \n\
echo "VNC password has been changed to: ${RANDOM_PASSWORD:-$DEFAULT_PASSWORD} " \n\
\
echo -e "${RANDOM_PASSWORD:-$DEFAULT_PASSWORD}\n${RANDOM_PASSWORD:-$DEFAULT_PASSWORD}\n" | passwd -q \n\
echo "root password has been changed to ${RANDOM_PASSWORD:-$DEFAULT_PASSWORD} " \n\
\
service xrdp start \n\
\
/usr/bin/x11vnc -forever -usepw -xdummy -env FD_SESS=xfce -env FD_GEOM=1920x1080 \n\
' > /usr/local/bin/burnerX.sh

RUN     chmod 755 /usr/local/bin/burnerX.sh
CMD ["/usr/local/bin/burnerX.sh"]
#CMD ["/bin/bash"]

