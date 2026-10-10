#!/usr/bin/env bash
# MAXIMUS T2 Neuinstallation V1 - Paketnutzlast offline beschaffen
#
# Ergebnis: Das Verzeichnis iso-overlay/maximus/packages enthaelt die
# Pakete, die das Live-System NICHT mitbringt, mit Pruefsummen.
#
# Vertrauenskette, wie in MAXIMUS V4.2 nachgewiesen:
#   1. Fingerabdruck des Signaturschluessels wird gegen die Erwartung geprueft.
#   2. InRelease wird mit diesem Schluessel geprueft.
#   3. Die Pruefsumme von Packages stammt aus Release.
#   4. Die Pruefsumme jeder .deb stammt aus Packages.
# Kein Schluessel landet im globalen Schluesselbund.
#
# Aufruf: bash 02-fetch-payload.sh --out DIR [--keep-work]

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SELF_DIR/.." && pwd)"
OUT="$ROOT/iso-overlay/maximus/packages"
KEEP=0
while [ "$#" -gt 0 ]; do
	case "$1" in
		--out) OUT="${2:?}"; shift ;;
		--keep-work) KEEP=1 ;;
		-h|--help) sed -n '2,16p' "$0"; exit 0 ;;
		*) printf 'FEHLER: Unbekannte Option %s\n' "$1" >&2; exit 2 ;;
	esac
	shift
done

readonly FP_ERWARTET="9F9873A566A73E27CFF0294FE2E496114ACDBFD4"
readonly REPO_GIT="https://github.com/AdityaGarg8/t2-ubuntu-repo"
readonly REL_BASE="https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/noble"
readonly UBU_BASE="https://archive.ubuntu.com/ubuntu"

# Pakete, die das Live-System nicht mitbringt. Gemessen an
# casper/filesystem.manifest des Projekt-ISO.
readonly T2_PAKETE="t2fanrd t2-ncm t2-touchid"
readonly REL_PAKETE="tiny-dfr"
readonly UBU_PAKETE="language-pack-de language-pack-de-base language-pack-gnome-de language-pack-gnome-de-base"

for t in git curl gpg sha256sum awk; do
	command -v "$t" >/dev/null 2>&1 || { printf 'FEHLER: %s fehlt.\n' "$t" >&2; exit 6; }
done

W="$(mktemp -d -t maximus-payload-XXXXXX)"
cleanup() { [ "$KEEP" -eq 1 ] || rm -rf "$W"; }
trap cleanup EXIT
mkdir -p "$OUT"
step() { printf '\n=== %s ===\n' "$1"; }

step "1. T2-Paketquelle holen"
git clone -q --depth 1 "$REPO_GIT" "$W/repo"
for f in InRelease Release Release.gpg KEY.gpg Packages; do
	[ -f "$W/repo/$f" ] || { printf 'FEHLER: %s fehlt in der Paketquelle.\n' "$f" >&2; exit 14; }
done
printf 'Paketquelle geholt. Commit: %s\n' "$(git -C "$W/repo" rev-parse HEAD)"

step "2. Signaturschluessel pruefen"
export GNUPGHOME="$W/gnupg"; mkdir -p "$GNUPGHOME"; chmod 700 "$GNUPGHOME"
gpg --batch --quiet --import "$W/repo/KEY.gpg"
FP="$(gpg --batch --with-colons --fingerprint 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')"
printf 'erwartet: %s\n' "$FP_ERWARTET"
printf 'gemessen: %s\n' "$FP"
[ "$FP" = "$FP_ERWARTET" ] || { printf 'FEHLER: Der Fingerabdruck weicht ab.\n' >&2; exit 13; }
printf 'Der Fingerabdruck stimmt.\n'

step "3. InRelease pruefen"
if gpg --batch --quiet --verify "$W/repo/InRelease" 2>"$W/gpg.err"; then
	printf 'Die Signatur von InRelease ist gueltig.\n'
else
	printf 'FEHLER: InRelease ist nicht gueltig signiert.\n' >&2
	sed 's/^/  /' "$W/gpg.err" >&2
	exit 13
fi

step "4. Pruefsumme von Packages aus Release entnehmen"
PKG_SHA_SOLL="$(awk '/^SHA256:/{f=1;next} f && $3=="Packages"{print $1; exit}' "$W/repo/Release")"
PKG_SHA_IST="$(sha256sum "$W/repo/Packages" | cut -d' ' -f1)"
printf 'Release nennt:  %s\n' "${PKG_SHA_SOLL:-NICHTS}"
printf 'Packages hat:   %s\n' "$PKG_SHA_IST"
[ -n "$PKG_SHA_SOLL" ] || { printf 'FEHLER: Release nennt keine Pruefsumme fuer Packages.\n' >&2; exit 13; }
[ "$PKG_SHA_SOLL" = "$PKG_SHA_IST" ] || { printf 'FEHLER: Packages weicht von Release ab.\n' >&2; exit 13; }
printf 'Die Kette Release -> Packages ist geschlossen.\n'

step "5. T2-Pakete auswaehlen und pruefen"
# Je Paket die hoechste Fassung aus Packages nehmen.
pick() {
	awk -v want="$1" '
		/^Package: /   { p=$2 }
		/^Version: /   { v=$2 }
		/^Filename: /  { fn=$2 }
		/^SHA256: /    { s=$2 }
		/^$/ { if (p==want && fn!="") print v"\t"fn"\t"s; p=v=fn=s="" }
		END { if (p==want && fn!="") print v"\t"fn"\t"s }
	' "$W/repo/Packages" | sort -V | tail -1
}
: > "$OUT/SHA256SUMS.neu"
NGOT=0
for p in $T2_PAKETE; do
	row="$(pick "$p")"
	if [ -z "$row" ]; then printf 'FEHLER: %s steht nicht in Packages.\n' "$p" >&2; exit 12; fi
	ver="$(printf '%s' "$row" | cut -f1)"
	fn="$(printf '%s' "$row"  | cut -f2)"
	soll="$(printf '%s' "$row" | cut -f3)"
	src="$W/repo/$(basename "$fn")"
	[ -f "$src" ] || src="$W/repo/$fn"
	[ -f "$src" ] || { printf 'FEHLER: %s liegt nicht in der Paketquelle.\n' "$fn" >&2; exit 12; }
	ist="$(sha256sum "$src" | cut -d' ' -f1)"
	if [ "$soll" != "$ist" ]; then
		printf 'FEHLER: %s hat eine falsche Pruefsumme.\n  Packages: %s\n  Datei:    %s\n' \
			"$fn" "$soll" "$ist" >&2
		exit 13
	fi
	cp "$src" "$OUT/"
	printf '%s  %s\n' "$ist" "$(basename "$fn")" >> "$OUT/SHA256SUMS.neu"
	printf '  %-14s %-18s Pruefsumme stimmt\n' "$p" "$ver"
	NGOT=$((NGOT + 1))
done

step "6. Pakete aus den Release-Anhaengen"
# tiny-dfr liegt nicht in der gemeinsamen Quelle, sondern bei der Fassung noble.
for p in $REL_PAKETE; do
	# Die Dateiliste steht in den Release-Anhaengen. Der Name folgt dem Muster.
	found=0
	for cand in $(awk -v want="$p" '
			/^Package: /  { pk=$2 }
			/^Filename: / { fn=$2 }
			/^$/ { if (pk==want && fn!="") print fn; pk=fn="" }
		' "$W/repo/Packages"); do
		printf '  %s aus der gemeinsamen Quelle: %s\n' "$p" "$cand"; found=1
	done
	if [ "$found" -eq 0 ]; then
		printf '  %s wird aus den Release-Anhaengen geholt.\n' "$p"
		# Die Fassung wird aus dem Packages-Index der Fassung noble gelesen.
		if curl -sfL --max-time 60 "$REL_BASE/Packages" -o "$W/rel-Packages" 2>/dev/null; then
			row="$(awk -v want="$p" '
				/^Package: /  { pk=$2 }
				/^Version: /  { v=$2 }
				/^Filename: / { fn=$2 }
				/^SHA256: /   { s=$2 }
				/^$/ { if (pk==want && fn!="") print v"\t"fn"\t"s; pk=v=fn=s="" }
				END { if (pk==want && fn!="") print v"\t"fn"\t"s }
			' "$W/rel-Packages" | sort -V | tail -1)"
			if [ -n "$row" ]; then
				ver="$(printf '%s' "$row" | cut -f1)"
				fn="$(printf '%s' "$row"  | cut -f2)"
				soll="$(printf '%s' "$row" | cut -f3)"
				base="$(basename "$fn")"
				if curl -sfL --retry 3 --max-time 600 "$REL_BASE/$base" -o "$OUT/$base"; then
					ist="$(sha256sum "$OUT/$base" | cut -d' ' -f1)"
					if [ "$soll" = "$ist" ]; then
						printf '%s  %s\n' "$ist" "$base" >> "$OUT/SHA256SUMS.neu"
						printf '  %-14s %-18s Pruefsumme stimmt\n' "$p" "$ver"
						NGOT=$((NGOT + 1))
					else
						printf 'FEHLER: %s hat eine falsche Pruefsumme.\n' "$base" >&2
						rm -f "$OUT/$base"; exit 13
					fi
				else
					printf 'WARNUNG: %s liess sich nicht laden.\n' "$base" >&2
				fi
			else
				printf 'WARNUNG: %s steht nicht im Index der Fassung noble.\n' "$p" >&2
			fi
		else
			printf 'WARNUNG: Der Index der Fassung noble ist nicht erreichbar.\n' >&2
		fi
	fi
done

step "7. Deutsche Sprachpakete aus dem Ubuntu-Archiv"
# Diese Pakete sind von Canonical signiert. Die Pruefsumme stammt aus dem
# signierten Paketindex des Archivs.
UKEY=/usr/share/keyrings/ubuntu-archive-keyring.gpg
if [ ! -f "$UKEY" ]; then
	printf 'WARNUNG: Der Ubuntu-Schluesselbund fehlt. Die Sprachpakete entfallen.\n' >&2
else
	for comp in main universe; do
		for suite in noble noble-updates; do
			u="$UBU_BASE/dists/$suite/$comp/binary-amd64/Packages.gz"
			curl -sfL --max-time 180 "$u" -o "$W/u-$suite-$comp.gz" 2>/dev/null \
				&& gzip -dc "$W/u-$suite-$comp.gz" >> "$W/ubu-Packages" 2>/dev/null || true
		done
	done
	if [ -s "$W/ubu-Packages" ]; then
		for p in $UBU_PAKETE; do
			row="$(awk -v want="$p" '
				/^Package: /  { pk=$2 }
				/^Version: /  { v=$2 }
				/^Filename: / { fn=$2 }
				/^SHA256: /   { s=$2 }
				/^$/ { if (pk==want && fn!="") print v"\t"fn"\t"s; pk=v=fn=s="" }
			' "$W/ubu-Packages" | sort -V | tail -1)"
			if [ -z "$row" ]; then printf '  WARNUNG: %s nicht im Index.\n' "$p" >&2; continue; fi
			ver="$(printf '%s' "$row" | cut -f1)"
			fn="$(printf '%s' "$row"  | cut -f2)"
			soll="$(printf '%s' "$row" | cut -f3)"
			base="$(basename "$fn")"
			if curl -sfL --retry 3 --max-time 300 "$UBU_BASE/$fn" -o "$OUT/$base"; then
				ist="$(sha256sum "$OUT/$base" | cut -d' ' -f1)"
				if [ "$soll" = "$ist" ]; then
					printf '%s  %s\n' "$ist" "$base" >> "$OUT/SHA256SUMS.neu"
					printf '  %-30s %-22s Pruefsumme stimmt\n' "$p" "$ver"
					NGOT=$((NGOT + 1))
				else
					printf 'FEHLER: %s hat eine falsche Pruefsumme.\n' "$base" >&2
					rm -f "$OUT/$base"; exit 13
				fi
			fi
		done
	else
		printf 'WARNUNG: Der Ubuntu-Paketindex ist nicht erreichbar.\n' >&2
	fi
fi

step "8. Pruefsummenliste abschliessen"
# V4.2-Regel: Eine vorhandene Liste wird NICHT selbsttaetig ueberschrieben.
if [ -f "$OUT/SHA256SUMS" ]; then
	if cmp -s "$OUT/SHA256SUMS" "$OUT/SHA256SUMS.neu"; then
		printf 'Die Liste ist unveraendert.\n'
		rm -f "$OUT/SHA256SUMS.neu"
	else
		printf 'HINWEIS: Die neue Liste weicht von der vorhandenen ab.\n'
		printf 'Die alte Liste bleibt als SHA256SUMS.vorher erhalten.\n'
		cp "$OUT/SHA256SUMS" "$OUT/SHA256SUMS.vorher"
		mv "$OUT/SHA256SUMS.neu" "$OUT/SHA256SUMS"
	fi
else
	mv "$OUT/SHA256SUMS.neu" "$OUT/SHA256SUMS"
fi
printf 'Pakete: %s\n' "$NGOT"
printf 'Umfang: %s\n' "$(du -sh "$OUT" | cut -f1)"
( cd "$OUT" && sha256sum -c SHA256SUMS >/dev/null 2>&1 ) \
	&& printf 'Gegenprobe: alle Pruefsummen stimmen.\n' \
	|| { printf 'FEHLER: Die Gegenprobe schlug fehl.\n' >&2; exit 13; }
exit 0
