#!/usr/bin/env bash
# Bildet die Pruefsummen des Rahmenwerks. Die Paketdateien und das Abbild
# sind ausgenommen, weil sie erzeugt werden.
set -eu
cd "$1"
{
  printf '# MAXIMUS_T2_NEUINSTALL_V1 - Pruefsummen des Rahmenwerks\n'
  printf '# Pruefen mit:  sha256sum -c SHA256SUMS\n'
  printf '# Nicht enthalten, weil erzeugt oder nicht weitergebbar:\n'
  printf '#   iso-overlay/maximus/packages/*.deb   siehe deren SHA256SUMS\n'
  printf '#   iso-overlay/maximus/firmware/verified/*  Apple-Firmware\n'
  printf '#   *.iso                                 das gebaute Abbild\n'
  find . -type f \
    ! -name '*.deb' ! -name '*.iso' ! -path './SHA256SUMS' \
    ! -path './iso-overlay/maximus/firmware/verified/*' \
    ! -path './.git/*' | sort | xargs sha256sum
} > SHA256SUMS
