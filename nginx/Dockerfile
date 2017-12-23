FROM cgundogan/arch-minimal:x86_64-2017.12.23
MAINTAINER Cenk Gündoğan <mail-github@cgundogan.de>

RUN pacman -Syyu --noconfirm nginx-mainline && \
    yes | pacman -Scc

COPY nginx.conf /etc/nginx/nginx.conf
COPY html /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
