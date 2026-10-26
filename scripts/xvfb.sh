# Source : démarre Xvfb sur :99 si nécessaire.
export DISPLAY=:99
if ! xdpyinfo >/dev/null 2>&1; then
  (Xvfb :99 -screen 0 1024x768x24 >/dev/null 2>&1 &)
  for _ in $(seq 1 300); do xdpyinfo >/dev/null 2>&1 && break; sleep 0.1; done
fi
win() { xwininfo -root -tree | awk '/"F\* MVU"/{print $1; exit}'; }
waitwin() { for _ in $(seq 1 1000); do [ -n "$(win)" ] && return 0; sleep 0.01; done; return 1; }
