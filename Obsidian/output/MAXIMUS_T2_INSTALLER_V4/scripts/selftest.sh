#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER_V4 - Eigenpruefung des Installationspakets
#
# Ergebnis: Das Skript prueft Struktur, Skripte, Listen und Pruefsummen.
# Es benoetigt keine Rootrechte. Es benoetigt keine T2-Hardware.
# Es aendert nichts.
#
# Aufruf:  ./selftest.sh [--no-color] [--skip-debs]

set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SELF_DIR/lib/common.sh"
# shellcheck source=lib/grub-config.sh
. "$SELF_DIR/lib/grub-config.sh"
ROOT="$(cd "$SELF_DIR/.." && pwd)"

SKIP_DEBS=0
for arg in "$@"; do
	case "$arg" in
		--no-color)  NO_COLOR=1; export NO_COLOR ;;
		--skip-debs) SKIP_DEBS=1 ;;
		-h|--help)   sed -n '2,10p' "$0"; exit "$RC_OK" ;;
		*)           die "$RC_USAGE" "Unbekannte Option '$arg'." "Erlaubt sind --no-color und --skip-debs." ;;
	esac
done

T_OK=0; T_FAIL=0; T_SKIP=0
t_pass() { T_OK=$((T_OK + 1));   log_ok   "$1"; }
t_fail() { T_FAIL=$((T_FAIL + 1)); log_err "$1"; }
t_skip() { T_SKIP=$((T_SKIP + 1)); log_info "uebersprungen: $1"; }

log "MAXIMUS_T2_INSTALLER_V4 - Eigenpruefung"
log "Paketwurzel: $ROOT"

# ---------------------------------------------------------------------------
log_step "Test 1: Pflichtdateien und Verzeichnisse"
# ---------------------------------------------------------------------------
REQUIRED_FILES="
README.md
manifest.json
SHA256SUMS
SOURCE_AUDIT.md
COMPATIBILITY_MATRIX.md
config/install-packages.list
config/grub/10-maximus-t2-grub.conf
config/grub/20-maximus-t2-cmdline.conf
config/modules/t2.conf
config/modules/t2-touchbar.conf
config/modules/initramfs-modules.conf
config/network/99-network-t2-ncm.rules
config/network/99-network-t2-ncm.conf
config/power/99-maximus-t2-sleep.conf
config/fan/t2fand.conf.reference
config/apt/t2-ubuntu-repo.gpg
config/apt/t2-ubuntu-repo.fingerprint
firmware/README.md
packages/t2linux.sources
recovery/GRUB-NOTSTART.txt
recovery/RESTORE.md
reports/BUILD_REPORT.md
reports/PACKAGE_AUDIT.md
scripts/lib/common.sh
scripts/lib/grub-entry.sh
scripts/lib/grub-config.sh
scripts/tests/grub.cfg.fixture
scripts/tests/default-grub.fixture
scripts/tests/default-grub-partial.fixture
scripts/tests/default-grub-nocmdline.fixture
scripts/preflight.sh
scripts/install.sh
scripts/verify.sh
scripts/rollback.sh
scripts/fetch-packages.sh
scripts/deploy-to-t7.sh
scripts/selftest.sh
"
for f in $REQUIRED_FILES; do
	if [ -f "$ROOT/$f" ]; then t_pass "vorhanden: $f"; else t_fail "fehlt: $f"; fi
done
for d in packages/ubuntu packages/t2linux packages/dependencies firmware/verified; do
	if [ -d "$ROOT/$d" ]; then t_pass "vorhanden: $d/"; else t_fail "fehlt: $d/"; fi
done

# ---------------------------------------------------------------------------
log_step "Test 2: Syntax aller Skripte"
# ---------------------------------------------------------------------------
while IFS= read -r s; do
	if bash -n "$s" 2>/dev/null; then
		t_pass "Syntax in Ordnung: ${s#"$ROOT"/}"
	else
		t_fail "Syntaxfehler: ${s#"$ROOT"/}"
	fi
done < <(find "$ROOT/scripts" -name '*.sh' -type f | sort)

# ---------------------------------------------------------------------------
log_step "Test 3: ShellCheck"
# ---------------------------------------------------------------------------
if command -v shellcheck >/dev/null 2>&1; then
	while IFS= read -r s; do
		if shellcheck -x -s bash -P "$ROOT/scripts" "$s" >/dev/null 2>&1; then
			t_pass "ShellCheck sauber: ${s#"$ROOT"/}"
		else
			t_fail "ShellCheck-Befunde: ${s#"$ROOT"/}"
		fi
	done < <(find "$ROOT/scripts" -name '*.sh' -type f | sort)
else
	t_skip "ShellCheck ist nicht installiert. Installiere es mit: sudo apt install shellcheck"
fi

# ---------------------------------------------------------------------------
log_step "Test 4: Ausfuehrungsrechte"
# ---------------------------------------------------------------------------
for s in preflight.sh install.sh verify.sh rollback.sh fetch-packages.sh deploy-to-t7.sh selftest.sh; do
	if [ -x "$ROOT/scripts/$s" ]; then
		t_pass "ausfuehrbar: scripts/$s"
	else
		log_warn "scripts/$s ist nicht ausfuehrbar. Rufe es mit 'bash scripts/$s' auf."
		t_pass "aufrufbar ueber bash: scripts/$s"
	fi
done

# ---------------------------------------------------------------------------
log_step "Test 5: Paketliste ohne Konfliktpakete"
# ---------------------------------------------------------------------------
declare -a PKGLIST=()
mapfile -t PKGLIST < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' \
	"$ROOT/config/install-packages.list" 2>/dev/null)
if [ "${#PKGLIST[@]}" -eq 0 ]; then
	t_fail "config/install-packages.list ist leer."
else
	t_pass "config/install-packages.list enthaelt ${#PKGLIST[@]} Pakete."
	BAD=0
	for bad in apple-bce apple-touchbar applesmc-t2 bcm5974-t2 apfs-dkms broadcom-wl bcmwl-kernel-source; do
		if printf '%s\n' "${PKGLIST[@]}" | grep -qx "$bad"; then
			t_fail "Konfliktpaket in der Liste: $bad"
			BAD=1
		fi
	done
	[ "$BAD" -eq 0 ] && t_pass "Es steht kein Konfliktpaket in der Liste."
	if printf '%s\n' "${PKGLIST[@]}" | grep -qx "linux-t2-lts"; then
		t_pass "Der Kernel linux-t2-lts ist vorgesehen."
	else
		t_fail "Der Kernel linux-t2-lts fehlt in der Liste."
	fi
	if printf '%s\n' "${PKGLIST[@]}" | grep -qx "t2-apple-audio-dsp-speakers161"; then
		t_pass "Das modellbezogene Lautsprecherprofil fuer das 16-Zoll-Modell ist vorgesehen."
	else
		t_fail "Das Lautsprecherprofil t2-apple-audio-dsp-speakers161 fehlt."
	fi
	for wrong in t2-apple-audio-dsp-speakers151 t2-apple-audio-dsp-speakers152 t2-apple-audio-dsp-speakers141; do
		if printf '%s\n' "${PKGLIST[@]}" | grep -qx "$wrong"; then
			t_fail "Falsches Lautsprecherprofil in der Liste: $wrong"
		fi
	done
fi

# ---------------------------------------------------------------------------
log_step "Test 6: Kernelparameter vollstaendig"
# ---------------------------------------------------------------------------
for p in intel_iommu=on iommu=pt pm_async=off; do
	if grep -qx "$p" "$ROOT/config/grub/20-maximus-t2-cmdline.conf" 2>/dev/null; then
		t_pass "Kernelparameter vorhanden: $p"
	else
		t_fail "Kernelparameter fehlt: $p"
	fi
done

# ---------------------------------------------------------------------------
log_step "Test 7: Module fuer die Initialramdisk"
# ---------------------------------------------------------------------------
for m in t2bce_dma t2bce_core t2bce_vhci; do
	if grep -qx "$m" "$ROOT/config/modules/initramfs-modules.conf" 2>/dev/null; then
		t_pass "Modul vorgesehen: $m"
	else
		t_fail "Modul fehlt: $m"
	fi
done

# ---------------------------------------------------------------------------
log_step "Test 8: Einheitstest fuer die GRUB-Menueerkennung"
# ---------------------------------------------------------------------------
FIX="$SELF_DIR/tests/grub.cfg.fixture"
if [ ! -f "$FIX" ]; then
	t_fail "Die Testvorlage scripts/tests/grub.cfg.fixture fehlt."
else
	GOT="$("$SELF_DIR/lib/grub-entry.sh" 6.18.54-1-t2-noble "$FIX" 2>/dev/null || true)"
	WANT='gnulinux-advanced-TESTUUID>gnulinux-6.18.54-1-t2-noble-advanced-TESTUUID'
	if [ "$GOT" = "$WANT" ]; then
		t_pass "Die Menueerkennung liefert die erwartete Kennung."
	else
		t_fail "Die Menueerkennung liefert '$GOT' statt '$WANT'."
	fi
	if "$SELF_DIR/lib/grub-entry.sh" 6.18.54-1-t2-noble "$FIX" 2>/dev/null | grep -q 'recovery'; then
		t_fail "Die Menueerkennung waehlt faelschlich den Wiederherstellungsmodus."
	else
		t_pass "Der Wiederherstellungsmodus wird uebersprungen."
	fi
	if "$SELF_DIR/lib/grub-entry.sh" 9.9.9-nicht-vorhanden "$FIX" >/dev/null 2>&1; then
		t_fail "Die Menueerkennung meldet keinen Fehler bei fehlendem Kernel."
	else
		t_pass "Bei fehlendem Kernel wird ein Fehler gemeldet."
	fi
fi

# ---------------------------------------------------------------------------
log_step "Test 9: Schreibpfade der Skripte"
# ---------------------------------------------------------------------------
# Jeder Schreibpfad in install.sh muss in der Freigabeliste stehen.
BAD_PATHS=0
while IFS= read -r path; do
	[ -n "$path" ] || continue
	ALLOWED=0
	for a in $MT2_WRITE_ALLOWLIST; do
		case "$path" in "$a"*) ALLOWED=1; break ;; esac
	done
	if [ "$ALLOWED" -eq 0 ]; then
		t_fail "Schreibpfad ausserhalb der Freigabeliste: $path"
		BAD_PATHS=1
	fi
done < <(grep -oE '(write_file[^#]*|install -m [0-7]+ [^ ]+ |> ?)/(etc|boot|var|usr|lib|opt|srv|root|home)[A-Za-z0-9_./-]*' \
	"$ROOT/scripts/install.sh" 2>/dev/null | grep -oE '/(etc|boot|var|usr|lib|opt|srv|root|home)[A-Za-z0-9_./-]*' | sort -u)
[ "$BAD_PATHS" -eq 0 ] && t_pass "Alle Schreibpfade in install.sh liegen in der Freigabeliste."

# Gefaehrliche Muster duerfen nicht vorkommen.
# Dieses Pruefskript selbst ist ausgenommen. Es traegt die Muster als Suchtext.
declare -a SCAN=()
while IFS= read -r s; do
	case "$(basename "$s")" in
		selftest.sh) continue ;;
	esac
	SCAN+=("$s")
done < <(find "$ROOT/scripts" -name '*.sh' -type f | sort)
log_info "Geprueft werden ${#SCAN[@]} Skripte. Ausgenommen ist selftest.sh selbst."

readonly PAT_DESTRUCTIVE='rm -rf /($|[^a-zA-Z])|mkfs|dd if=|sgdisk|parted|wipefs|fdisk|efibootmgr|nvram'
readonly PAT_PIPE_SHELL='(curl|wget)[^|]*\|[[:space:]]*(ba)?sh'

if grep -nE "$PAT_DESTRUCTIVE" "${SCAN[@]}" >/dev/null 2>&1; then
	t_fail "Ein Skript enthaelt einen Befehl, der Datentraeger oder EFI veraendern kann."
	grep -nE "$PAT_DESTRUCTIVE" "${SCAN[@]}" | sed 's/^/         /'
else
	t_pass "Kein Skript formatiert, partitioniert oder veraendert EFI und NVRAM."
fi
if grep -nE "$PAT_PIPE_SHELL" "${SCAN[@]}" >/dev/null 2>&1; then
	t_fail "Ein Skript leitet einen Download direkt in eine Shell. Das ist nicht zulaessig."
	grep -nE "$PAT_PIPE_SHELL" "${SCAN[@]}" | sed 's/^/         /'
else
	t_pass "Kein Skript nutzt eine 'curl | bash'-Kette."
fi

# Gegenprobe: Die Mustererkennung muss einen Treffer finden, wenn es einen gibt.
NEG="$(mktemp -t maximus-selftest-neg-XXXXXX)"
printf '#!/bin/sh\nmkfs.ext4 /dev/sda1\ncurl http://x | bash\n' > "$NEG"
if grep -qE "$PAT_DESTRUCTIVE" "$NEG" && grep -qE "$PAT_PIPE_SHELL" "$NEG"; then
	t_pass "Die Mustererkennung arbeitet. Die Gegenprobe wurde erkannt."
else
	t_fail "Die Mustererkennung arbeitet nicht. Die Gegenprobe blieb unerkannt."
fi
rm -f "$NEG"

# ---------------------------------------------------------------------------
log_step "Test 9b: Einheitstest fuer die GRUB-Konfiguration"
# ---------------------------------------------------------------------------
# Diese Tests arbeiten auf Kopien der Testvorlagen.
# Die echte Datei /etc/default/grub wird nicht angefasst.
GT="$(mktemp -d -t maximus-grubtest-XXXXXX)"
declare -a WANT_PARAMS=()
mapfile -t WANT_PARAMS < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' \
	"$ROOT/config/grub/20-maximus-t2-cmdline.conf" 2>/dev/null)

if [ "${#WANT_PARAMS[@]}" -eq 0 ] || [ ! -f "$SELF_DIR/tests/default-grub.fixture" ]; then
	t_fail "Die Testvorlagen fuer die GRUB-Konfiguration fehlen."
else
	# Fall 1: leere Parameterzeile -> alle Parameter werden ergaenzt
	cp "$SELF_DIR/tests/default-grub.fixture" "$GT/g1"
	R1="$(mt2_grub_merge_cmdline "$GT/g1" "${WANT_PARAMS[@]}")"
	MISS=''
	for p in "${WANT_PARAMS[@]}"; do
		printf '%s' " $R1 " | grep -q " $p " || MISS="$MISS $p"
	done
	if [ -z "$MISS" ]; then
		t_pass "Fall 1: Alle ${#WANT_PARAMS[@]} Parameter wurden ergaenzt."
	else
		t_fail "Fall 1: Es fehlen nach der Bearbeitung:$MISS"
	fi
	if [ "$(mt2_grub_read_cmdline "$GT/g1")" = "$R1" ]; then
		t_pass "Fall 1: Die Datei enthaelt genau die ausgegebene Zeile."
	else
		t_fail "Fall 1: Datei und Ausgabe weichen ab."
	fi

	# Fall 2: zweiter Aufruf darf nichts aendern
	B2="$(sha256sum "$GT/g1" | cut -d' ' -f1)"
	R2="$(mt2_grub_merge_cmdline "$GT/g1" "${WANT_PARAMS[@]}")"
	A2="$(sha256sum "$GT/g1" | cut -d' ' -f1)"
	if [ "$B2" = "$A2" ] && [ "$R2" = "$R1" ]; then
		t_pass "Fall 2: Ein zweiter Aufruf aendert nichts."
	else
		t_fail "Fall 2: Ein zweiter Aufruf hat die Datei veraendert."
	fi

	# Fall 3: vorhandene Parameter bleiben erhalten
	cp "$SELF_DIR/tests/default-grub-partial.fixture" "$GT/g3"
	R3="$(mt2_grub_merge_cmdline "$GT/g3" "${WANT_PARAMS[@]}")"
	if printf '%s' " $R3 " | grep -q ' mitigations=off '; then
		t_pass "Fall 3: Ein fremder Parameter bleibt erhalten."
	else
		t_fail "Fall 3: Der fremde Parameter 'mitigations=off' wurde entfernt."
	fi
	if [ "$(printf '%s' "$R3" | grep -o 'iommu=pt' | wc -l)" -eq 1 ]; then
		t_pass "Fall 3: Ein bereits gesetzter Parameter wird nicht verdoppelt."
	else
		t_fail "Fall 3: 'iommu=pt' kommt mehrfach vor."
	fi
	if printf '%s' " $R3 " | grep -q ' intel_iommu=on '; then
		t_pass "Fall 3: Die fehlenden Parameter wurden ergaenzt."
	else
		t_fail "Fall 3: 'intel_iommu=on' wurde nicht ergaenzt."
	fi

	# Fall 4: fehlende Parameterzeile wird angelegt
	cp "$SELF_DIR/tests/default-grub-nocmdline.fixture" "$GT/g4"
	R4="$(mt2_grub_merge_cmdline "$GT/g4" "${WANT_PARAMS[@]}")"
	if grep -qE '^GRUB_CMDLINE_LINUX=' "$GT/g4" && [ -n "$R4" ]; then
		t_pass "Fall 4: Eine fehlende Parameterzeile wird angelegt."
	else
		t_fail "Fall 4: Die Parameterzeile wurde nicht angelegt."
	fi

	# Fall 5: fehlende Datei -> Rueckgabe 1, kein Abbruch
	if mt2_grub_merge_cmdline "$GT/gibtsnicht" "${WANT_PARAMS[@]}" >/dev/null 2>&1; then
		t_fail "Fall 5: Eine fehlende Datei wurde nicht gemeldet."
	else
		t_pass "Fall 5: Eine fehlende Datei wird mit Rueckgabe 1 gemeldet."
	fi

	# Fall 6: Menueschluessel setzen
	cp "$SELF_DIR/tests/default-grub.fixture" "$GT/g6"
	mt2_grub_set_keys "$GT/g6" "$ROOT/config/grub/10-maximus-t2-grub.conf" >/dev/null
	OK6=1
	while IFS='=' read -r k v; do
		case "$k" in ''|\#*) continue ;; esac
		grep -qx "${k}=${v}" "$GT/g6" || { t_fail "Fall 6: '${k}=${v}' wurde nicht gesetzt."; OK6=0; }
	done < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$ROOT/config/grub/10-maximus-t2-grub.conf")
	[ "$OK6" -eq 1 ] && t_pass "Fall 6: Alle Menueschluessel wurden gesetzt."
	if grep -qx 'GRUB_TIMEOUT=10' "$GT/g6"; then
		t_pass "Fall 6: GRUB_TIMEOUT wurde von 0 auf 10 gesetzt. Das Menue bleibt sichtbar."
	else
		t_fail "Fall 6: GRUB_TIMEOUT ist nicht 10. Das Menue koennte unsichtbar bleiben."
	fi
	if grep -qx 'GRUB_TIMEOUT_STYLE=menu' "$GT/g6"; then
		t_pass "Fall 6: Der auskommentierte Schluessel GRUB_TIMEOUT_STYLE wurde aktiviert."
	else
		t_fail "Fall 6: GRUB_TIMEOUT_STYLE=menu fehlt."
	fi
	if grep -qx 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' "$GT/g6"; then
		t_pass "Fall 6: Fremde Zeilen bleiben unveraendert."
	else
		t_fail "Fall 6: Die Zeile GRUB_CMDLINE_LINUX_DEFAULT wurde veraendert."
	fi
	# Fall 7: zweiter Aufruf von set_keys aendert nichts
	B7="$(sha256sum "$GT/g6" | cut -d' ' -f1)"
	mt2_grub_set_keys "$GT/g6" "$ROOT/config/grub/10-maximus-t2-grub.conf" >/dev/null
	if [ "$B7" = "$(sha256sum "$GT/g6" | cut -d' ' -f1)" ]; then
		t_pass "Fall 7: Ein zweiter Aufruf von mt2_grub_set_keys aendert nichts."
	else
		t_fail "Fall 7: Ein zweiter Aufruf hat die Datei veraendert."
	fi
fi
rm -rf "$GT"

# ---------------------------------------------------------------------------
log_step "Test 10: Quellenliste der T2-Pakete"
# ---------------------------------------------------------------------------
SRC="$ROOT/packages/t2linux.sources"
if [ ! -f "$SRC" ]; then
	t_fail "packages/t2linux.sources fehlt."
else
	LINES=0; BADL=0
	while IFS="$(printf '\t')" read -r fname fsha furl; do
		case "$fname" in ''|\#*) continue ;; esac
		LINES=$((LINES + 1))
		case "$fsha" in
			[0-9a-f]*) [ "${#fsha}" -eq 64 ] || { t_fail "Pruefsumme mit falscher Laenge: $fname"; BADL=1; } ;;
			*) t_fail "Keine gueltige SHA-256-Pruefsumme: $fname"; BADL=1 ;;
		esac
		case "$furl" in
			https://*) : ;;
			*) t_fail "Die Quelle von '$fname' nutzt kein HTTPS."; BADL=1 ;;
		esac
	done < "$SRC"
	if [ "$LINES" -eq 0 ]; then
		t_fail "packages/t2linux.sources enthaelt keine Eintraege."
	elif [ "$BADL" -eq 0 ]; then
		t_pass "Alle $LINES Eintraege haben eine HTTPS-Quelle und eine gueltige Pruefsumme."
	fi
fi

# ---------------------------------------------------------------------------
log_step "Test 11: manifest.json"
# ---------------------------------------------------------------------------
if command -v python3 >/dev/null 2>&1; then
	if python3 -I -c 'import json,sys; json.load(open(sys.argv[1]))' "$ROOT/manifest.json" 2>/dev/null; then
		t_pass "manifest.json ist gueltiges JSON."
	else
		t_fail "manifest.json ist kein gueltiges JSON."
	fi
else
	t_skip "python3 fehlt. manifest.json wurde nicht geprueft."
fi

# ---------------------------------------------------------------------------
log_step "Test 12: Pruefsummen"
# ---------------------------------------------------------------------------
if [ -f "$ROOT/SHA256SUMS" ]; then
	if mt2_verify_sha256 "$ROOT/SHA256SUMS" "$ROOT"; then
		t_pass "Alle Dateien des Rahmenwerks haben die erwartete Pruefsumme."
	else
		t_fail "Mindestens eine Datei des Rahmenwerks wurde veraendert."
	fi
else
	t_fail "SHA256SUMS fehlt."
fi

DEB_COUNT="$(mt2_count_files "$ROOT/packages" -name '*.deb')"
if [ "$SKIP_DEBS" -eq 1 ]; then
	t_skip "Die Pruefung der Paketdateien wurde mit --skip-debs uebersprungen."
elif [ "$DEB_COUNT" -eq 0 ]; then
	log_warn "Es liegen keine Paketdateien vor. Fuehre scripts/fetch-packages.sh aus."
	t_skip "Die Paketdateien fehlen noch (Rahmenwerk ohne Nutzlast)."
elif [ -f "$ROOT/packages/SHA256SUMS.debs" ]; then
	if mt2_verify_sha256 "$ROOT/packages/SHA256SUMS.debs" "$ROOT/packages"; then
		t_pass "Alle $DEB_COUNT Paketdateien haben die erwartete Pruefsumme."
	else
		t_fail "Mindestens eine Paketdatei ist beschaedigt."
	fi
else
	t_fail "packages/SHA256SUMS.debs fehlt, obwohl Paketdateien vorliegen."
fi

# ---------------------------------------------------------------------------
log_step "Ergebnis"
# ---------------------------------------------------------------------------
log "Bestanden: $T_OK   Fehlgeschlagen: $T_FAIL   Uebersprungen: $T_SKIP"
if [ "$T_FAIL" -gt 0 ]; then
	log_err "Die Eigenpruefung ist fehlgeschlagen."
	exit "$RC_PKG_TREE"
fi
log_ok "Die Eigenpruefung ist bestanden."
exit "$RC_OK"
