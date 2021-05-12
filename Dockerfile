FROM archlinux AS packages
COPY build /build
RUN /build/build-packages.sh

FROM archlinux AS root
ARG ARCH_MIRROR=http://mirror.math.princeton.edu/pub/archlinux
RUN sed -i "1s|^|Server = $ARCH_MIRROR/\$repo/os/\$arch\n|" /etc/pacman.d/mirrorlist

RUN pacman-key --init

RUN curl -s https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc \
  | pacman-key --add - && pacman-key --finger 56C464BAAC421453 && pacman-key --lsign-key 56C464BAAC421453

RUN echo "[linux-surface]" >> /etc/pacman.conf && echo "Server = https://pkg.surfacelinux.com/arch/"  >> /etc/pacman.conf

RUN pacman -Syyu --needed --noconfirm \
    acpi \
    aspell-en \
    atom \
    base \
    base-devel \
    bc \
    bind-tools \
    binutils \
    ca-certificates \
    ccid \
    cpio \
    cpupower \
    cryptsetup \
    curl \
    device-mapper \
    dhcpcd \
    diffutils \
    dmidecode \
    docker \
    docker-compose \
    dracut \
    e2fsprogs \
    efibootmgr \
    efitools \
    evolution \
    evolution-ews \
    expect \
    firefox \
    flatpak \
    fwupd \
    fzf \
    gdm \
    git-crypt \
    gnome \
    gnu-free-fonts \
    hunspell-en_US \
    inetutils \
    intel-ucode \
    in-toto \
    ipmitool \
    iw \
    jq \
    kubectl \
    kubectx \
    libfido2 \
    libp11 \
    linux \
    linux-firmware \
    linux-headers \
    lvm2 \
    man-db \
    man-pages \
    meld \
    multipath-tools \
    networkmanager \
    networkmanager-openconnect \
    networkmanager-openvpn \
    noto-fonts \
    opensc \
    pam-u2f \
    pcsclite \
    python-netifaces \
    rsync \
    sbsigntools \
    screen \
    socat \
    squashfs-tools \
    sudo \
    systemd \
    tpm2-abrmd \
    tpm2-tools \
    ttf-fira-code \
    ttf-hack \
    ttf-ibm-plex \
    ttf-inconsolata \
    ttf-roboto \
    ttf-ubuntu-font-family \
    usbutils \
    vim \
    vlc \
    weston \
    wget \
    which \
    wireless_tools \
    wpa_supplicant \
    yubikey-manager \
    yubikey-personalization \
    yubioath-desktop \
    nmap \
    code \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal \
    pipewire-pulse \
    skopeo \
    seahorse \
    xf86-video-intel \
    xf86-input-libinput \
    kitty \
    intel-media-dirver

COPY --from=packages /build/packages /tmp/packages

RUN find /tmp/packages -iname zoom\*_orig\* -delete
RUN yes | pacman -U /tmp/packages/*

RUN yes | pacman -S --needed --noconfirm linux-surface linux-surface-headers iptsd

RUN rm -r /tmp/packages

RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | HELM_INSTALL_DIR=/usr/bin bash

RUN ( cd /usr/bin && curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash )

RUN curl -Lo /usr/bin/skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && \
chmod +x /usr/bin/skaffold

COPY files /

RUN rm /usr/lib/systemd/system/systemd-firstboot.service

RUN for i in \
  etc/environment \
  etc/xdg/ \
  etc/cloud/ \
  etc/security/ \
  etc/gdm/ \
  etc/geoclue/ \
  etc/UPower/ \
  etc/ca-certificates/ \
  etc/ssl/ \
  etc/pam.d/ \
  etc/profile.d/ \
  etc/bash.bashrc \
  etc/fonts/ \
  etc/pulse/ \
  etc/fwupd/ \
  etc/pki/ \
  etc/fancontrol \
  etc/ethertypes \
  etc/man_db.conf \
  etc/pipewire/ \
  etc/NetworkManager/; \
do \
  [ -e "/$i" ] && rsync -av /$i /usr/share/factory/$i ; \
done

RUN echo \
  pcscd.service \
  bluetooth.service \
  coldplug.service \
  gdm.service \
  mount-modules.service \
  firstboot.service \
  var-lib-systemd-home.mount \
  var-lib-firstboot.mount \
  var-lib-bluetooth.mount \
  NetworkManager.service \
  'etc-NetworkManager-system\\x2dconnections.mount' \
  systemd-homed.service \
  restart-systemd-homed.service \
  iptsd.service \
  | xargs -n 1 systemctl enable

RUN mkdir -p /usr/lib/systemd/user/default.target.wants && \
  ln -s ../docker.service /usr/lib/systemd/user/default.target.wants/

RUN rsync --ignore-existing -av /etc/systemd/ /usr/lib/systemd/

RUN rm /usr/lib/pcsc/drivers/ifd-ccid.bundle/Contents/Info.plist && cp /etc/libccid_Info.plist /usr/lib/pcsc/drivers/ifd-ccid.bundle/Contents/Info.plist && \
  rm /usr/lib/systemd/system/sshdgenkeys.service && \
  rm /usr/lib/systemd/system/docker* && \
  ( ! test -f /etc/dbus-1/system.d/wpa_supplicant.conf ||  mv /etc/dbus-1/system.d/wpa_supplicant.conf /usr/share/dbus-1/system.d/ )

RUN sed -e 's|C! /etc/pam.d|C /etc/pam.d|' -i /usr/lib/tmpfiles.d/etc.conf && \
  cd /usr/lib/firmware && mkdir -p intel-ucode && \
  cat /boot/intel-ucode.img | cpio -idmv && \
  mv kernel/x86/microcode/GenuineIntel.bin intel-ucode/ && \
  rm -r kernel

RUN validity-sensors-firmware

RUN mv /opt /usr/local/opt

ARG VERS=dev
RUN sed -e "s/%VERS%/$VERS/g" < /etc/os-release.template > /usr/lib/os-release && cat /usr/lib/os-release

FROM root AS build

RUN mkdir -p /output

RUN cp /usr/lib/os-release /output

RUN mv /usr/lib/modules /modules && \
  ln -s /modules /usr/lib/modules && \
  cd /modules && \
  for MOD_DIR in *; do \
    cd /modules/${MOD_DIR} && \
    mksquashfs * /output/modules_${MOD_DIR}_squashfs && \
    veritysetup format /output/modules_${MOD_DIR}_squashfs /output/modules_${MOD_DIR}_verity > /output/modules_${MOD_DIR}_verity-info.txt; \
  done && \
  mkdir -p /usr/lib/systemd/system/systemd-modules-load.service.wants && \
  ln -s /usr/lib/systemd/system/mount-modules.service /usr/lib/systemd/system/systemd-modules-load.service.wants/mount-modules.service && \
  ln -s /usr/lib/systemd/system/mount-modules.service /usr/lib/systemd/system/multi-user.target.wants/mount-modules.service

RUN mksquashfs usr etc /output/root.squashfs && \
  veritysetup format /output/root.squashfs /output/root.verity > /output/root.verity-info.txt

COPY secureboot /etc/secureboot

RUN for KER_VER in $(ls /usr/lib/modules/);\
  do \
   dracut --force --uefi --kver $KER_VER /output/kernel-$KER_VER.efi;\
  done

FROM alpine as installer
RUN apk add --no-cache lvm2 coreutils util-linux cryptsetup bash psmisc device-mapper

COPY --from=build /output /output

COPY install/install.sh /install.sh

ENTRYPOINT ["/install.sh"]
