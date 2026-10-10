#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER_V4 - Paketbestand auf dem Baurechner herstellen
#
# Ergebnis: Das Verzeichnis packages/ enthaelt danach alle Paketdateien,
# einen Paketindex und eine Pruefsummenliste. Die Installation auf dem
# MacBook braucht dann keine Internetverbindung mehr.
#
# Dieses Skript laeuft auf dem BAURECHNER, nicht auf dem MacBook.
# Es installiert nichts. Es veraendert das Betriebssystem nicht.
#
# Voraussetzungen:
#   1. Ubuntu 24.04 (noble) fuer amd64, echt oder im Container.
#   2. Internetzugang zu archive.ubuntu.com und zu den T2-Quellen.
#   3. Etwa 1,5 GB freier Speicherplatz.
#
# Aufruf:  ./fetch-packages.sh [OPTIONEN]
#   --out PFAD    Zielverzeichnis. Standard ist <Paketwurzel>/packages.
#   --keep-cache  Loescht das Arbeitsverzeichnis nicht.
#   --no-color    Gibt keine Farbcodes aus.

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SELF_DIR/lib/common.sh"
ROOT="$(cd "$SELF_DIR/.." && pwd)"

OUT="$ROOT/packages"
KEEP_CACHE=0
while [ "$#" -gt 0 ]; do
	case "$1" in
		--out)        shift; OUT="${1:-}" ;;
		--keep-cache) KEEP_CACHE=1 ;;
		--no-color)   NO_COLOR=1; export NO_COLOR ;;
		-h|--help)    sed -n '2,22p' "$0"; exit "$RC_OK" ;;
		*)            die "$RC_USAGE" "Unbekannte Option '$1'." "Rufe '$0 --help' auf." ;;
	esac
	shift
done
[ -n "$OUT" ] || die "$RC_USAGE" "--out erwartet einen Pfad." "Beispiel: --out /pfad/packages"

WORK="$(mktemp -d -t maximus-t2-build-XXXXXX)"
# shellcheck disable=SC2317  # Die Funktion ruft die EXIT-Falle auf.
cleanup() {
	if [ "$KEEP_CACHE" -eq 1 ]; then
		log_info "Arbeitsverzeichnis bleibt erhalten: $WORK"
	else
		rm -rf "$WORK"
	fi
}
trap cleanup EXIT

log "MAXIMUS_T2_INSTALLER_V4 - Paketbestand herstellen"
log "Zielverzeichnis: $OUT"
log "Arbeitsverzeichnis: $WORK"

# ---------------------------------------------------------------------------
log_step "Bauumgebung pruefen"
# ---------------------------------------------------------------------------
for c in curl gpg sha256sum apt-get dpkg-deb dpkg-scanpackages gzip find awk sed; do
	mt2_need_cmd "$c"
done
log_ok "Alle benoetigten Programme sind vorhanden."

BUILD_CODENAME="$(mt2_codename || true)"
BUILD_ARCH="$(dpkg --print-architecture 2>/dev/null || true)"
if [ "$BUILD_CODENAME" != "$MT2_SUPPORTED_CODENAME" ]; then
	die "$RC_RELEASE" "Die Bauumgebung ist '$BUILD_CODENAME', nicht '$MT2_SUPPORTED_CODENAME'." \
		"Nutze einen Ubuntu-24.04-Container, zum Beispiel: docker run --rm -it -v \$PWD:/work ubuntu:24.04 bash"
fi
if [ "$BUILD_ARCH" != "amd64" ]; then
	die "$RC_RELEASE" "Die Bauumgebung ist '$BUILD_ARCH', nicht 'amd64'." "Nutze eine amd64-Umgebung."
fi
log_ok "Bauumgebung: Ubuntu 24.04 ($BUILD_CODENAME), amd64"

FREE_MIB="$(df -Pm "$(dirname "$OUT")" 2>/dev/null | awk 'NR==2{print $4}')"
if [ "${FREE_MIB:-0}" -lt 1536 ]; then
	die "$RC_PKG_TREE" "Es sind nur ${FREE_MIB:-0} MiB frei. Notwendig sind 1536 MiB." "Schaffe Speicherplatz und starte erneut."
fi
log_ok "Freier Speicherplatz: ${FREE_MIB} MiB"

# ---------------------------------------------------------------------------
log_step "Signaturschluessel pruefen"
# ---------------------------------------------------------------------------
KEYFILE="$ROOT/config/apt/t2-ubuntu-repo.gpg"
FPFILE="$ROOT/config/apt/t2-ubuntu-repo.fingerprint"
[ -f "$KEYFILE" ] || die "$RC_PKG_TREE" "Der Schluessel '$KEYFILE' fehlt." "Stelle das Installationspaket vollstaendig wieder her."
[ -f "$FPFILE" ] || die "$RC_PKG_TREE" "Die Fingerabdruckdatei fehlt." "Stelle das Installationspaket vollstaendig wieder her."
EXPECT_FP="$(tr -d ' \n' < "$FPFILE")"
ACTUAL_FP="$(gpg --with-colons --show-keys "$KEYFILE" 2>/dev/null | awk -F: '/^fpr:/{print $10; exit}')"
if [ "$ACTUAL_FP" != "$EXPECT_FP" ]; then
	die "$RC_CHECKSUM" "Der Fingerabdruck des Schluessels stimmt nicht. Erwartet '$EXPECT_FP', gefunden '$ACTUAL_FP'." \
		"Der Schluessel wurde veraendert. Brich ab und pruefe die Quelle."
fi
log_ok "Schluessel bestaetigt: $ACTUAL_FP (Aditya Garg)"

# ---------------------------------------------------------------------------
log_step "Signierte Paketindizes der T2-Quellen pruefen"
# ---------------------------------------------------------------------------
mkdir -p "$WORK/t2index"
KEYRING="$WORK/t2.kbx"
gpg --no-default-keyring --keyring "$KEYRING" --import "$KEYFILE" >/dev/null 2>&1 \
	|| die "$RC_CHECKSUM" "Der Schluessel liess sich nicht einlesen." "Pruefe die Datei $KEYFILE."

COMMON_BASE="https://adityagarg8.github.io/t2-ubuntu-repo"
COMMON_GIT="https://github.com/AdityaGarg8/t2-ubuntu-repo.git"
INDEX_OK=0
if curl -fsSL --max-time 120 -o "$WORK/t2index/InRelease" "$COMMON_BASE/InRelease" 2>/dev/null \
	&& curl -fsSL --max-time 120 -o "$WORK/t2index/Packages" "$COMMON_BASE/Packages" 2>/dev/null; then
	log_ok "Die Indizes des gemeinsamen Repositoriums wurden geladen."
	INDEX_OK=1
elif command -v git >/dev/null 2>&1 \
	&& git clone --depth 1 -q "$COMMON_GIT" "$WORK/t2clone" 2>/dev/null; then
	cp "$WORK/t2clone/InRelease" "$WORK/t2clone/Packages" "$WORK/t2index/" 2>/dev/null || true
	log_warn "Die Webseite war nicht erreichbar. Die Indizes stammen aus dem Git-Abbild."
	INDEX_OK=1
fi

if [ "$INDEX_OK" -eq 1 ] && [ -f "$WORK/t2index/InRelease" ]; then
	if gpg --no-default-keyring --keyring "$KEYRING" --verify "$WORK/t2index/InRelease" >/dev/null 2>&1; then
		log_ok "Die GPG-Signatur des Paketindex ist gueltig."
	else
		die "$RC_CHECKSUM" "Die GPG-Signatur des Paketindex ist ungueltig." \
			"Brich ab. Lade keine Pakete aus einer nicht bestaetigten Quelle."
	fi
else
	log_warn "Der Paketindex war nicht erreichbar. Die Pruefung stuetzt sich allein auf packages/t2linux.sources."
fi

# ---------------------------------------------------------------------------
log_step "T2-Paketdateien laden"
# ---------------------------------------------------------------------------
SRCLIST="$ROOT/packages/t2linux.sources"
[ -f "$SRCLIST" ] || die "$RC_PKG_TREE" "packages/t2linux.sources fehlt." "Stelle das Installationspaket vollstaendig wieder her."
mkdir -p "$OUT/t2linux"
N_T2=0
while IFS="$(printf '\t')" read -r fname fsha furl; do
	case "$fname" in ''|\#*) continue ;; esac
	target="$OUT/t2linux/$fname"
	if [ -f "$target" ] && [ "$(sha256sum "$target" | cut -d' ' -f1)" = "$fsha" ]; then
		log_info "bereits vorhanden und geprueft: $fname"
		N_T2=$((N_T2 + 1))
		continue
	fi
	log_info "lade: $fname"
	if ! curl -fsSL --retry 3 --retry-delay 2 --max-time 1800 -o "$target.part" "$furl"; then
		# Rueckfall: gemeinsames Repositorium als Git-Abbild
		if [ -d "$WORK/t2clone" ] && [ -f "$WORK/t2clone/$fname" ]; then
			cp "$WORK/t2clone/$fname" "$target.part"
			log_warn "Der Download schlug fehl. Die Datei stammt aus dem Git-Abbild."
		else
			rm -f "$target.part"
			die "$RC_REPO" "Der Download von '$fname' schlug fehl." "Pruefe die Internetverbindung und starte erneut."
		fi
	fi
	got="$(sha256sum "$target.part" | cut -d' ' -f1)"
	if [ "$got" != "$fsha" ]; then
		rm -f "$target.part"
		die "$RC_CHECKSUM" "Falsche Pruefsumme bei '$fname'. Erwartet '$fsha', erhalten '$got'." \
			"Die Quelle hat sich geaendert. Erneuere packages/t2linux.sources nach einer Quellenpruefung."
	fi
	mv "$target.part" "$target"
	log_ok "geprueft: $fname"
	N_T2=$((N_T2 + 1))
done < "$SRCLIST"
log_ok "$N_T2 T2-Paketdateien liegen bereit."

# ---------------------------------------------------------------------------
log_step "Isolierte Paketverwaltung aufsetzen"
# ---------------------------------------------------------------------------
AR="$WORK/aptroot"
mkdir -p "$AR"/{etc/apt/apt.conf.d,etc/apt/preferences.d,etc/apt/sources.list.d,etc/apt/keyrings,var/lib/apt/lists/partial,var/lib/dpkg,var/cache/apt/archives/partial,var/log/apt}
: > "$AR/var/lib/dpkg/status"
printf 'amd64\n' > "$AR/var/lib/dpkg/arch"

UKEY=''
for k in /usr/share/keyrings/ubuntu-archive-keyring.gpg /etc/apt/trusted.gpg.d/ubuntu-keyring-2018-archive.gpg; do
	[ -f "$k" ] && UKEY="$k" && break
done
[ -n "$UKEY" ] || die "$RC_PKG_TREE" "Der Ubuntu-Archivschluessel fehlt." "Installiere das Paket 'ubuntu-keyring'."
cp "$UKEY" "$AR/etc/apt/keyrings/ubuntu-archive-keyring.gpg"
log_ok "Ubuntu-Archivschluessel: $UKEY"

MIRROR="${MT2_UBUNTU_MIRROR:-https://archive.ubuntu.com/ubuntu}"
{
	for suite in noble noble-updates noble-security; do
		printf 'deb [arch=amd64 signed-by=%s/etc/apt/keyrings/ubuntu-archive-keyring.gpg] %s %s main restricted universe multiverse\n' \
			"$AR" "$MIRROR" "$suite"
	done
} > "$AR/etc/apt/sources.list"
printf 'deb [arch=amd64 trusted=yes] file://%s ./\n' "$OUT/t2linux" > "$AR/etc/apt/sources.list.d/local-t2.list"

cat > "$WORK/apt.conf" <<EOF
Dir "$AR";
Dir::State "$AR/var/lib/apt";
Dir::State::status "$AR/var/lib/dpkg/status";
Dir::Cache "$AR/var/cache/apt";
Dir::Etc "$AR/etc/apt";
Dir::Etc::sourcelist "$AR/etc/apt/sources.list";
Dir::Etc::sourceparts "$AR/etc/apt/sources.list.d";
Dir::Log "$AR/var/log/apt";
APT::Architecture "amd64";
APT::Architectures "amd64";
Acquire::Languages "none";
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF
export APT_CONFIG="$WORK/apt.conf"

( cd "$OUT/t2linux" && dpkg-scanpackages --multiversion . /dev/null 2>/dev/null > Packages ) \
	|| die "$RC_REPO" "Der lokale T2-Index liess sich nicht erzeugen." "Pruefe die Dateien in $OUT/t2linux."
log_ok "Lokaler T2-Index: $(grep -c '^Package:' "$OUT/t2linux/Packages") Eintraege"

if ! apt-get update -qq >/dev/null 2>&1; then
	die "$RC_REPO" "Die Paketindizes liessen sich nicht laden." \
		"Pruefe den Zugang zu $MIRROR. Setze bei Bedarf MT2_UBUNTU_MIRROR auf einen Spiegelserver."
fi
log_ok "Die Paketindizes sind geladen und signaturgeprueft."

# ---------------------------------------------------------------------------
log_step "Abhaengigkeiten aufloesen und laden"
# ---------------------------------------------------------------------------
declare -a PKGLIST=()
mapfile -t PKGLIST < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' \
	"$ROOT/config/install-packages.list")
[ "${#PKGLIST[@]}" -gt 0 ] || die "$RC_PKG_TREE" "config/install-packages.list ist leer." "Stelle die Datei wieder her."
log_info "${#PKGLIST[@]} Pakete sind angefordert."

if ! apt-get install -s -y --no-install-recommends "${PKGLIST[@]}" > "$WORK/sim.txt" 2>&1; then
	log_err "Die Aufloesung schlug fehl:"
	sed -n '1,30p' "$WORK/sim.txt" | sed 's/^/         /'
	die "$RC_DEPS" "Die Paketabhaengigkeiten sind nicht erfuellbar." "Pruefe die Paketnamen in config/install-packages.list."
fi
grep -E 'newly installed' "$WORK/sim.txt" | tail -1 | sed 's/^/         /'

if ! apt-get install -d -y --no-install-recommends "${PKGLIST[@]}" >/dev/null 2>&1; then
	die "$RC_REPO" "Der Download der Abhaengigkeiten schlug fehl." "Pruefe die Internetverbindung und starte erneut."
fi
CACHED="$(mt2_count_files "$AR/var/cache/apt/archives" -maxdepth 1 -name '*.deb')"
log_ok "$CACHED Paketdateien wurden geladen."

# ---------------------------------------------------------------------------
log_step "Pakete einsortieren"
# ---------------------------------------------------------------------------
mkdir -p "$OUT/ubuntu" "$OUT/dependencies"
find "$OUT/ubuntu" "$OUT/dependencies" -maxdepth 1 -name '*.deb' -delete
N_U=0; N_D=0
while IFS= read -r deb; do
	name="$(dpkg-deb -f "$deb" Package 2>/dev/null || true)"
	[ -n "$name" ] || continue
	# T2-Pakete liegen bereits in t2linux/ und werden nicht kopiert.
	if [ -f "$OUT/t2linux/$(basename "$deb")" ]; then continue; fi
	if printf '%s\n' "${PKGLIST[@]}" | grep -qx "$name"; then
		cp "$deb" "$OUT/ubuntu/"; N_U=$((N_U + 1))
	else
		cp "$deb" "$OUT/dependencies/"; N_D=$((N_D + 1))
	fi
done < <(find "$AR/var/cache/apt/archives" -maxdepth 1 -name '*.deb' | sort)
log_ok "ubuntu/: $N_U Pakete   dependencies/: $N_D Pakete   t2linux/: $N_T2 Pakete"

# ---------------------------------------------------------------------------
log_step "Offline-Paketquelle erzeugen"
# ---------------------------------------------------------------------------
( cd "$OUT" && dpkg-scanpackages --multiversion . /dev/null 2>/dev/null > Packages ) \
	|| die "$RC_REPO" "Der Gesamtindex liess sich nicht erzeugen." "Pruefe die Dateien unter $OUT."
gzip -9nkf "$OUT/Packages"
TOTAL="$(grep -c '^Package:' "$OUT/Packages")"
log_ok "Gesamtindex: $TOTAL Eintraege"

# Release-Datei mit Pruefsummen schreiben. apt-ftparchive ist nicht erforderlich.
{
	printf 'Origin: MAXIMUS-T2-OFFLINE\n'
	printf 'Label: MAXIMUS_T2_INSTALLER_V4\n'
	printf 'Suite: %s\n' "$MT2_SUPPORTED_CODENAME"
	printf 'Codename: %s\n' "$MT2_SUPPORTED_CODENAME"
	printf 'Architectures: amd64\n'
	printf 'Components: ./\n'
	printf 'Date: %s\n' "$(date -u -R)"
	printf 'Description: Offline-Paketquelle fuer T2Linux auf MacBookPro16,1\n'
	printf 'SHA256:\n'
	for f in Packages Packages.gz; do
		printf ' %s %s %s\n' "$(sha256sum "$OUT/$f" | cut -d' ' -f1)" "$(stat -c%s "$OUT/$f")" "$f"
	done
} > "$OUT/Release"
log_ok "Release-Datei geschrieben."

# ---------------------------------------------------------------------------
log_step "Pruefsummenliste erzeugen und vergleichen"
# ---------------------------------------------------------------------------
EXPECTED="$OUT/SHA256SUMS.debs"
NEWLIST="$WORK/SHA256SUMS.debs"
( cd "$OUT" && find . -name '*.deb' -type f | sort | xargs -r sha256sum ) > "$NEWLIST"
NEW_COUNT="$(wc -l < "$NEWLIST")"

if [ -f "$EXPECTED" ]; then
	if diff -q <(sort "$EXPECTED") <(sort "$NEWLIST") >/dev/null 2>&1; then
		log_ok "Der Paketbestand stimmt mit der mitgelieferten Liste ueberein ($NEW_COUNT Dateien)."
	else
		log_warn "Der Paketbestand weicht von der mitgelieferten Liste ab."
		log_warn "Das ist normal, wenn Ubuntu Sicherheitsaktualisierungen veroeffentlicht hat."
		diff <(sort "$EXPECTED") <(sort "$NEWLIST") | head -20 | sed 's/^/         /' || true
		cp "$EXPECTED" "$OUT/SHA256SUMS.debs.previous"
		log_info "Die alte Liste liegt in SHA256SUMS.debs.previous."
	fi
fi
cp "$NEWLIST" "$EXPECTED"
log_ok "packages/SHA256SUMS.debs enthaelt $NEW_COUNT Eintraege."

# ---------------------------------------------------------------------------
log_step "Abschluss"
# ---------------------------------------------------------------------------
SIZE="$(du -sh "$OUT" | cut -f1)"
log_ok "PACKAGE_READY: Der Paketbestand ist vollstaendig und geprueft."
log "Gesamtgroesse: $SIZE"
log ""
log "Naechste Schritte:"
log "  1. Pruefung:   ./scripts/selftest.sh"
log "  2. Uebertragen: sudo ./scripts/deploy-to-t7.sh"
exit "$RC_OK"
