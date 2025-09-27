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

PKGR_TMP_ID=$(date +%s)

if [ -z "${PKGR_TMP_ID}" ]; then
  echo "Could not create a unique temporary identifier."
  exit 1
fi

PKGR_TMP_ROOT=pkgr_tmproot_${PKGR_TMP_ID}

mkdir -p "${PKGR_TMP_ROOT}/pkgdtmp" || exit 1
mkdir -p "${PKGR_TMP_ROOT}/download" || exit 1
pushd "${PKGR_TMP_ROOT}/download" || exit 1

PKGR_CLIENT_URI=https://tcl.to/r/pkg_client_full
PKGR_TMP_FILE=pkgrd_tmp_file.zip
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

unzip -o "${PKGR_TMP_FILE}" || exit 1

popd || exit 1
pushd "${PKGR_TMP_ROOT}" || exit 1

export PKGR_TEMP=pkgdtmp
export PKGR_SETUP_TEMP=pkgdtmp
export PKGD_TEMP=pkgdtmp

echo "Running package client toolset setup as current user..."
tclsh "download/pkgr_an_d/client/1.0/neutral/pkgr_setup.eagle"

popd || exit 1
