#!/usr/bin/env sh
set -u

# Linux check
ON_LINUX=0
if [[ "$(uname)" = "Linux" ]]; then
  ON_LINUX=1
fi

DDNS_NAME=ns0
DDNS_TAG=${DDNS_NAME}
DDNS_TLD=docker

REPOSITORY="https://github.com/zanaca/docker-dns"
PARENT_FOLDER=/usr/local
DESTINATION=${PARENT_FOLDER}/docker-dns

can_sudo() {
  local -a args
  if [[ -n "${SUDO_ASKPASS-}" ]]; then
    args=("-A")
  fi

  if [[ -z "${CAN_DO_SUDO-}" ]]; then
    if [[ -n "${args[*]-}" ]]; then
      /usr/bin/sudo "${args[@]}" -l mkdir &>/dev/null
    else
      /usr/bin/sudo -l mkdir &>/dev/null
    fi
    CAN_DO_SUDO="$?"
  fi

  if [[ "$CAN_DO_SUDO" -ne 0 ]]; then
    abort "You need sudo access!"
  fi

  return "$CAN_DO_SUDO"
}

join() {
  local arg
  printf "$1"
  shift
  for arg in "$@"; do
    printf " "
    printf  "${arg// /\ }"
  done
}

abort() {
  printf "ERROR: $1\n"
  exit 1
}

run() {
  if ! "$@"; then
    abort "$(join "$@")"
  fi
}

run_sudo() {
  local -a args=("$@")
  if [[ -n "${SUDO_ASKPASS-}" ]]; then
    args=("-A" "${args[@]}")
  fi
  if can_sudo; then
    run "/usr/bin/sudo" "${args[@]}"
  else
    run "${args[@]}"
  fi
}

check_if_python() {
  PYTHON_NOK=""
  command -v python3 >/dev/null 2>&1 || PYTHON_NOK=1
  if [ ! -z ${PYTHON_NOK} ]; then
    abort "Python3 is not installed. Aborting."
  fi

  PIP_NOK=""
  local PIP=pip3
  command -v ${PIP} >/dev/null 2>&1 || PIP=pip
  command -v ${PIP} >/dev/null 2>&1 || PIP_NOK=1
  if [ ! -z ${PIP_NOK} ]; then
    abort "pip is not installed. Aborting."
  fi

  echo "$PIP"
 }

show_path_advice() {
  case "$SHELL" in
    */bash*)
      if [[ -r "$HOME/.bash_profile" ]]; then
        profile="$HOME/.bash_profile"
      else
        profile="$HOME/.profile"
      fi
      ;;
    */zsh*)
      profile="$HOME/.zprofile"
      ;;
    *)
      profile="$HOME/.profile"
      ;;
  esac

  [[ "${PATH}" =~ "${DESTINATION}" ]] || cat <<EOC
You can add docker-dns to your \$PATH in ${profile}:
  echo export PATH=\\\$PATH:${DESTINATION}/bin >> ${profile}
EOC
}

grab_information() {
  printf "Please inform the container's name for docker-dns. That container is used to communicate from host machine to Docker environment.\n"
  printf "Container's name: [${DDNS_NAME}] "
  read USER_ANSWER
  [ ! -z "${USER_ANSWER}" ] && DDNS_NAME=${USER_ANSWER}

  printf "Now inform the container's image tag name: [${DDNS_TAG}] "
  read USER_ANSWER
  [ ! -z ${USER_ANSWER} ] && DDNS_TAG=${USER_ANSWER}

  printf "And now inform the top level domain you would like to use for containers name resolution.\nFor example, for \"${DDNS_NAME}.docker\" please inform \"docker\". If you prefer \"${DDNS_NAME}.dev\" please inform \"dev\".\n"
  printf "Top level domain:  [${DDNS_TLD}] "
  read USER_ANSWER
  [ ! -z ${USER_ANSWER} ] && DDNS_TLD=${USER_ANSWER}

}

printf "\033[33m     _            _                      _            \n"
printf "  __| | ___   ___| | _____ _ __       __| |_ __  ___  \n"
printf " / _\` |/ _ \ / __| |/ / _ \ '__|____ / _\` | '_ \/ __| \n"
printf "| (_| | (_) | (__|   <  __/ | |_____| (_| | | | \__ \ \n"
printf " \__,_|\___/ \___|_|\_\___|_|        \__,_|_| |_|___/ \n"
printf "       Host machine DNS for Docker Containers"
printf "\033[m\n\n"


printf "Starting instalation process\n"
printf "Eventually you will be asked for you password to perform \"sudo\" steps.\n\n"

grab_information

while true; do
  printf "\nPlease confirm the information below\nContainer name: ${DDNS_NAME}\nImage tag name: ${DDNS_TAG}\nWorking domain: ${DDNS_TLD}\nIs that correct? [y/N] "
  read USER_ANSWER
  case $USER_ANSWER in
    [Yy]* ) printf "\n"; break;;
    [Nn]* ) printf "\n"; grab_information;;
    * ) printf "Please answer with [y]es or [n]o\n";;
  esac
done

printf "Downloading and installing docker-dns.\n"
(
  cd "${PARENT_FOLDER}" >/dev/null || return

  run_sudo rm -Rf "${DESTINATION}" > /dev/null

  run_sudo git clone ${REPOSITORY}

  cd ${DESTINATION}

  PIP=$(check_if_python)
  sudo -H ${PIP} install -r ${DESTINATION}/requirements.txt

  run_sudo ./bin/docker-dns install -t "${DDNS_TAG}" -n "${DDNS_NAME}" -d "${DDNS_TLD}"

  ./bin/docker-dns status

  show_path_advice

) || exit 1