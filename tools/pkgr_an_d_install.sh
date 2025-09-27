#!/bin/bash

if [ ! -x "$(command -v tclsh)" ]; then
  echo "The program 'tclsh' is apparently not installed."
  echo "Please use 'apt-get install tcl8.6' (Linux)."
  exit 1
fi

if ! echo "exit [catch {package require tls}]" | tclsh; then
  echo "The 'tls' package for Tcl is not installed."
  echo "Please use 'apt-get install tcl-tls' (Linux)."
  exit 1
fi

if [ ! -x "$(command -v wget)" ] && [ ! -x "$(command -v curl)" ]; then
  echo "The programs 'wget' and/or 'curl' are apparently not installed."
  echo "Please use 'apt-get install wget' (Linux) or 'brew install wget' (Mac)."
  exit 1
fi

if [ -x "$(command -v gpg2)" ]; then
  PKGR_GPG_VER_OK=$(echo "puts [regexp -- {^gpg \(GnuPG\) 2\.[0123]\.} [exec gpg2 --version --homedir {}]]" | tclsh)
elif [ -x "$(command -v gpg)" ]; then
  PKGR_GPG_VER_OK=$(echo "puts [regexp -- {^gpg \(GnuPG\) 2\.[0123]\.} [exec gpg --version --homedir {}]]" | tclsh)
else
  echo "The program 'gpg2' (a.k.a. 'gpg') is apparently not installed."
  echo "Please use 'apt-get install gnupg2' (Linux) or 'brew install gnupg' (Mac)."
  exit 1
fi

if [ "$PKGR_GPG_VER_OK" != "1" ]; then
  echo "The program 'gpg2' (a.k.a. 'gpg') is returning an unsupported version."
  echo "Please use 'apt-get install gnupg2' (Linux) or 'brew install gnupg' (Mac)."
  exit 1
fi

if [ ! -x "$(command -v date)" ]; then
  echo "The program 'date' is apparently not installed."
  exit 1
fi

if [ ! -x "$(command -v sudo)" ]; then
  echo "The program 'sudo' is apparently not installed."
  exit 1
fi

if [ ! -x "$(command -v logname)" ]; then
  echo "The program 'logname' is apparently not installed."
  exit 1
fi

PKGR_LOGIN_USER=$SUDO_USER

if [ -z "${PKGR_LOGIN_USER}" ]; then
  PKGR_LOGIN_USER=$(logname)
fi

if [ -z "${PKGR_LOGIN_USER}" ]; then
  echo "Could not determine the original login name."
  exit 1
fi

PKGR_ROOT_DIR=$(echo "puts [file dirname [set tcl_library]]" | tclsh)

if [ -z "${PKGR_ROOT_DIR}" ]; then
  echo "Could not determine parent directory of Tcl library directory."
  exit 1
fi

if [ ! -w "${PKGR_ROOT_DIR}" ]; then
  echo "Parent directory of Tcl library directory is not writable."
  exit 1
fi

PKGR_TMP_ID=$(date +%s)

if [ -z "${PKGR_TMP_ID}" ]; then
  echo "Could not create a unique temporary identifier."
  exit 1
fi

PKGR_INSTALL_DIR=${PKGR_ROOT_DIR}/pkgd
PKGR_TMP_DIR=~/pkgdtmp

mkdir -p "${PKGR_INSTALL_DIR}" || exit 1
sudo -u "${PKGR_LOGIN_USER}" mkdir -p "${PKGR_TMP_DIR}" || exit 1

PKGR_CLIENT_URI=https://tcl.to/r/pkg_client_full
PKGR_TMP_FILE=${PKGR_TMP_DIR}/pkgrd_tmp_${PKGR_TMP_ID}_file.zip
PKGR_GET_OK=0

if [ -x "$(command -v wget)" ]; then
  for wgetArg in "" ""
  do
    if wget -4 $wgetArg "--output-document=${PKGR_TMP_FILE}" "${PKGR_CLIENT_URI}"; then
      if [ -f "${PKGR_TMP_FILE}" ]; then
        PKGR_GET_OK=1
        break
      fi
    fi
  done
else
  for curlArg in "" ""
  do
    if curl -4 $curlArg --location "${PKGR_CLIENT_URI}" > "${PKGR_TMP_FILE}"; then
      if [ -f "${PKGR_TMP_FILE}" ]; then
        PKGR_GET_OK=1
        break
      fi
    fi
  done
fi

if [ $PKGR_GET_OK -eq 0 ] || [ ! -f "${PKGR_TMP_FILE}" ]; then
  echo "Could not download the package client toolset archive."
  exit 1
fi

unzip -o "${PKGR_TMP_FILE}" -d "${PKGR_INSTALL_DIR}" || exit 1

export PKGR_TEMP=${PKGR_TMP_DIR}
export PKGR_SETUP_TEMP=${PKGR_TMP_DIR}
export PKGD_TEMP=${PKGR_TMP_DIR}

echo "Running package client toolset setup as user '${PKGR_LOGIN_USER}'..."
sudo -u "${PKGR_LOGIN_USER}" "PKGR_TEMP=$PKGR_TEMP" "PKGR_SETUP_TEMP=$PKGR_SETUP_TEMP" "PKGD_TEMP=PKGD_TEMP" tclsh "${PKGR_INSTALL_DIR}/pkgr_an_d/client/1.0/neutral/pkgr_setup.eagle"
