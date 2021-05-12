#!/bin/bash -x
set -ex
export SRCDIR=/build
export DESTDIR=/build
pacman -Syu --noconfirm

pacman --needed -Sy --noconfirm arch-install-scripts base-devel git sudo awk libffi --noscriptlet
useradd -m build
echo 'build ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/build
chmod 0440 /etc/sudoers.d/build
visudo -c

for PROFILE in $SRCDIR/*-aur.txt
do
  PKG_DEST_DIR="$DESTDIR/packages"
  for i in $(cat $PROFILE  | grep -v '^#' | grep -v '^ *$' | sort -u)
  do
    if [ "$i" = "fprintd-clients" ]
    then
      pacman --needed -Sy --noconfirm --noscriptlet polkit dbus-glib
    elif [ "$i" = "libwacom-surface" ]
    then
      pacman --needed -Sy --noconfirm --noscriptlet libgudev cmake python-libevdev python-pyudev python-pytest
    fi
    if ! [ -e ~build/build/$i/*.pkg.tar* ]
    then
      su - build << EOP
  set -ex
  if [ "$i" = "gnupg-scdaemon-shared-access" ]
  then
    gpg --keyserver hkps://keyserver.ubuntu.com --recv-key 528897B826403ADA
  fi
  mkdir -p ~/build
  git clone https://aur.archlinux.org/$i.git ~/build/$i
  cd ~/build/$i
  (
    source PKGBUILD
    if [ -n "\$validpgpkeys" ]
    then
      gpg --keyserver hkps://keyserver.ubuntu.com --recv-key \$validpgpkeys
    fi
    if [ -n "\${makedepends}" ]
    then
      sudo pacman -S --noconfirm --needed \${makedepends[@]}
    fi
  )
  export PKGEXT=.pkg.tar
  makepkg -sd --noconfirm --needed
EOP
    fi
    mkdir -p "$PKG_DEST_DIR"
    cp -av  ~build/build/$i/*.pkg.tar* $PKG_DEST_DIR
  done
done
# su - build << EOP
# set -ex

# gpg --keyserver hkps://keyserver.ubuntu.com --recv-key C54CA336CFEB557E

# git clone https://github.com/archlinux/svntogit-packages.git -b packages/systemd --depth 1 ~/build/systemd

# cd ~/build/systemd
# patch -p1 < $SRCDIR/systemd.patch
# cd trunk
# (
#   source PKGBUILD
#   if [ -n "\$validpgpkeys" ]
#   then
#     gpg --keyserver hkps://keyserver.ubuntu.com --recv-key \$validpgpkeys
#   fi
#   if [ -n "\${makedepends}" ]
#   then
#     sudo pacman -S --noconfirm --needed \${makedepends[@]}
#   fi
# )
# export PKGEXT=.pkg.tar
# makepkg -sd --noconfirm --needed
# EOP
# mkdir -p "$PKG_DEST_DIR"
# cp -av  ~build/build/systemd/trunk/*.pkg.tar* $PKG_DEST_DIR
