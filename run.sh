#!/usr/bin/env sh
set -u

# Am I on Linux?
ON_LINUX=0
if [[ "$(uname)" = "Linux" ]]; then
  ON_LINUX=1
fi

REPOSITORY="https://github.com/zanaca/docker-dns"
PARENT_FOLDER='/usr/local'
DESTINATION=$(PARENT_FOLDER)/docker-dns

if [[ "${ON_LINUX}" -eq "1" ]]; then
  CHOWN="/usr/sbin/chown"
  CHGRP="/usr/bin/chgrp"
  TOUCH="/usr/bin/touch"
else
  CHOWN="/bin/chown"
  CHGRP="/bin/chgrp"
  TOUCH="/bin/touch"
fi


can_sudo() {
  local -a args
  if [[ -n "${SUDO_ASKPASS-}" ]]; then
    args=("-A")
  fi

  if [[ -z "${HAVE_SUDO_ACCESS-}" ]]; then
    if [[ -n "${args[*]-}" ]]; then
      /usr/bin/sudo "${args[@]}" -l mkdir &>/dev/null
    else
      /usr/bin/sudo -l mkdir &>/dev/null
    fi
    HAVE_SUDO_ACCESS="$?"
  fi

  if [[ "$HAVE_SUDO_ACCESS" -ne 0 ]]; then
    abort "You need to be an admin or have sudo access!"
  fi

  return "$HAVE_SUDO_ACCESS"
}

abort() {
  printf "%s\n" "$1"
  exit 1
}

run() {
  if ! "$@"; then
    abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

run_sudo() {
  local -a args=("$@")
  if [[ -n "${SUDO_ASKPASS-}" ]]; then
    args=("-A" "${args[@]}")
  fi
  if have_sudo_access; then
    echo "/usr/bin/sudo" "${args[@]}"
    run "/usr/bin/sudo" "${args[@]}"
  else
    echo "${args[@]}"
    run "${args[@]}"
  fi
}
