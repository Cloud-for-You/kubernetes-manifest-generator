ROOTDIR=$(pwd)
TEMPDIR=tmp
FINALDIR=resources

exec_cmd() {
  tmp=$(mktemp)
  "$@" > "$tmp" 2>&1 && ret=$? || ret=$?
  [ "$ret" -eq 0 ] || cat "$tmp"
  rm -f "$tmp"
  return "$ret"
}
