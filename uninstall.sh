#!/bin/sh
# Remove the system symlinks installed by install.sh.
# The flag and guestbook in the invoking user's home are kept unless you pass --purge.

set -eu

PURGE=0
for arg in "$@"; do
  case "$arg" in
    --purge) PURGE=1 ;;
    -h|--help)
      echo "Usage: ./uninstall.sh [--purge]"
      echo "  --purge  Also delete ~/flag.txt and ~/guest-book.txt"
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

TARGET_USER=${SUDO_USER:-$(id -un)}
if [ "$TARGET_USER" = "root" ]; then
  echo "Run this as your normal user, or with sudo from that user's account." >&2
  exit 1
fi

case "$(uname -s)" in
  Darwin)
    HOME_DIR=$(dscl . -read "/Users/$TARGET_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
    ;;
  *)
    HOME_DIR=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
    ;;
esac
if [ -z "${HOME_DIR:-}" ] || [ ! -d "$HOME_DIR" ]; then
  HOME_DIR=$(eval echo "~$TARGET_USER")
fi

remove() {
  if [ -L "$1" ] || [ -e "$1" ]; then
    sudo rm -f "$1"
    echo "~ removed: $1"
  fi
}

remove /etc/flag.txt
remove /usr/local/flag.txt
remove /tmp/flag.txt
remove /var/tmp/flag.txt

if [ -d /var/root ]; then
  remove /var/root/flag.txt
elif [ -d /root ]; then
  remove /root/flag.txt
fi

if [ "$PURGE" -eq 1 ]; then
  rm -f "$HOME_DIR/flag.txt" "$HOME_DIR/guest-book.txt"
  echo "~ purged $HOME_DIR/flag.txt and $HOME_DIR/guest-book.txt"
else
  echo "~ kept $HOME_DIR/flag.txt and $HOME_DIR/guest-book.txt (use --purge to delete them)"
fi

if [ "$(uname -s)" = "Darwin" ] && [ -f /etc/synthetic.conf ]; then
  if grep -q '^flag\.txt[[:space:]]' /etc/synthetic.conf 2>/dev/null; then
    echo "~ note: /etc/synthetic.conf still has a flag.txt entry; remove it and reboot to drop /flag.txt"
  fi
fi
