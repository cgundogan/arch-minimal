#! /bin/bash
set -e

if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

ARCHIVE=$(basename $1)
wget $1 && wget $1.sig
gpg --verify ${ARCHIVE}.sig ${ARCHIVE} || {
    echo 'Could not verify signature!'
    exit 1
}

tar -xf ${ARCHIVE}
ROOT=$(tar -tf ${ARCHIVE} | head -1)
ROOT=${ROOT%/}

PKGRM=(
    dhcpcd
    gawk
    gettext
    iproute2
    jfsutils
    licenses
    linux
    lvm2
    man-db
    man-pages
    mdadm
    nano
    netctl
    openresolv
    pciutils
    pcmciautils
    reiserfsprogs
    s-nail
    systemd-sysvcompat
    texinfo
    usbutils
    vi
    xfsprogs
)

./${ROOT}/bin/arch-chroot ${ROOT} << EOF
    echo 'Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch' > /etc/pacman.d/mirrorlist
    pacman-key --init
    pacman-key --populate archlinux
    pacman -Syu --noconfirm base
    pacman -Rddssnu --noconfirm ${PKGRM[*]}
    yes | pacman -Scc
    rm -rf /usr/share/{doc,info,man,perl5/core_perl}/*
    find /usr/share/locale/* ! -name 'en_US' ! -name 'en_GB' -type d -exec rm -rf {} +
    find /usr/share/i18n/locales/* ! -name 'en_US' ! -name 'en_GB' -type d -exec rm -rf {} +
    find /usr/share/terminfo/* ! -name 'xterm' -type f -exec rm -f {} +
    find /usr/share/i18n/charmaps/* ! -name 'UTF-8.gz' -type f -exec rm -f {} +
    find / -regextype posix-extended -regex ".+\.pac(new|save)" -exec rm -f {} +
    rm -rf /usr/lib/udev/* /var/lib/pacman/sync/*
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
    rm -rf /root/*
    exit
EOF

DEV=./${ROOT}/dev
bash << EOF
	rm -rf $DEV
	mkdir -p $DEV
	mknod -m 0666 $DEV/null c 1 3
	mknod -m 0666 $DEV/zero c 1 5
	mknod -m 0666 $DEV/random c 1 9
	mknod -m 0666 $DEV/urandom c 1 9
	mkdir -m 0755 $DEV/pts
	mkdir -m 1777 $DEV/shm
	mknod -m 0666 $DEV/tty c 5 0
	mknod -m 0600 $DEV/console c 5 1
	mknod -m 0666 $DEV/tty0 c 4 0
	mknod -m 0666 $DEV/full c 1 7
	mknod -m 0600 $DEV/initctl p
	mknod -m 0666 $DEV/ptmx c 5 2
	ln -sf /proc/self/fd $DEV/fd
EOF

tar --numeric-owner --xattrs --acls -C ${ROOT} -c . | docker import - arch-minimal
docker run --rm -t arch-minimal echo Success.
