#!/usr/bin/env bash
# MAXIMUS T2 Neuinstallation V1 - Nachbereitung im Zielsystem
#
# Ergebnis: Das installierte Ubuntu erhaelt die T2-Treiberpakete, die
# Startparameter, die Module fuer die fruehe Startumgebung, die Dienste
# und den Funktionsbericht fuer den ersten Start.
#
# Umgebung: ubiquity ruft dieses Skript als 'ubiquity/success_command' auf.
# Das Zielsystem ist dann unter /target eingehaengt.
#
# Aufruf: bash postinstall.sh <stabile-kennung-des-ziels>

set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SELF_DIR/lib/common.sh"

MX_LOG=/var/log/maximus-t2-neuinstall.log
TARGET=/target
T_SID="${1:-unbekannt}"
# Gemessen im Prueflauf: early.sh laeuft im Initramfs und notiert dort
# /root/cdrom. Im laufenden Live-System heisst derselbe Ort /cdrom.
# Der Pfad wird deshalb zur Laufzeit neu bestimmt.
MEDIUM_PATH=''
for d in /cdrom /run/live/medium /isodevice "$(cat "$SELF_DIR/medium-pfad" 2>/dev/null)"; do
	[ -n "$d" ] || continue
	if [ -d "$d/maximus" ]; then MEDIUM_PATH="$d"; break; fi
done
[ -n "$MEDIUM_PATH" ] || MEDIUM_PATH=/cdrom

log_step "Nachbereitung im Zielsystem"

if [ ! -d "$TARGET" ] || ! findmnt -no TARGET "$TARGET" >/dev/null 2>&1; then
	log_err "Das Zielsystem ist unter $TARGET nicht eingehaengt."
	log_err "Die Nachbereitung wird uebersprungen."
	exit 0   # ubiquity soll deswegen nicht die Installation verwerfen
fi
log_ok "Zielsystem eingehaengt: $(findmnt -no SOURCE "$TARGET")"

FAILED=0
note_fail() { log_err "$1"; FAILED=$((FAILED + 1)); }

in_target() { chroot "$TARGET" env DEBIAN_FRONTEND=noninteractive "$@"; }

# ---------------------------------------------------------------------------
log_step "1. T2-Pakete offline nachinstallieren"
# ---------------------------------------------------------------------------
PKGDIR="$MEDIUM_PATH/maximus/packages"
if [ -d "$PKGDIR" ] && ls "$PKGDIR"/*.deb >/dev/null 2>&1; then
	NDEB="$(ls "$PKGDIR"/*.deb | wc -l)"
	log_info "$NDEB Paketdateien auf dem Medium gefunden."
	# Pruefsummen zuerst. Ohne gueltige Pruefsumme wird nichts installiert.
	if [ -f "$PKGDIR/SHA256SUMS" ]; then
		if (cd "$PKGDIR" && sha256sum -c SHA256SUMS >/dev/null 2>&1); then
			log_ok "Alle Paketdateien haben die erwartete Pruefsumme."
		else
			note_fail "Mindestens eine Paketdatei hat eine falsche Pruefsumme."
			log_err "Es wird kein Paket installiert."
			PKGDIR=''
		fi
	else
		note_fail "Die Datei SHA256SUMS fehlt im Paketverzeichnis."
		PKGDIR=''
	fi
	if [ -n "$PKGDIR" ]; then
		mkdir -p "$TARGET/var/cache/maximus-pakete"
		cp "$PKGDIR"/*.deb "$TARGET/var/cache/maximus-pakete/" \
			|| note_fail "Die Paketdateien liessen sich nicht ins Ziel kopieren."
		# dpkg zuerst, dann apt-get -f fuer die Abhaengigkeiten aus dem Ziel.
		if in_target sh -c 'dpkg -i /var/cache/maximus-pakete/*.deb' >>"$MX_LOG" 2>&1; then
			log_ok "Die T2-Pakete sind installiert."
		else
			log_warn "dpkg meldete Abhaengigkeiten. Es wird ohne Netz nachgebessert."
			if in_target apt-get -y -o APT::Get::AllowUnauthenticated=false \
				--no-download --fix-broken install >>"$MX_LOG" 2>&1; then
				log_ok "Die Abhaengigkeiten sind aus dem Zielbestand aufgeloest."
			else
				note_fail "Die Abhaengigkeiten liessen sich offline nicht aufloesen."
			fi
		fi
		in_target sh -c 'rm -f /var/cache/maximus-pakete/*.deb' >/dev/null 2>&1 || true
	fi
else
	log_warn "Es liegen keine T2-Zusatzpakete auf dem Medium."
	log_warn "Luefterregelung und Touch Bar bleiben dann unversorgt."
fi

# ---------------------------------------------------------------------------
log_step "2. Startparameter setzen"
# ---------------------------------------------------------------------------
# Diese Parameter stammen aus dem Projekt t2linux.
MX_CMDLINE="pm_async=off intel_iommu=on iommu=pt pcie_ports=native"
GRUBDEF="$TARGET/etc/default/grub"
if [ -f "$GRUBDEF" ]; then
	cp -a "$GRUBDEF" "$GRUBDEF.maximus-vorher" || true
	# Gemessen im Prueflauf: Ein gieriges \(.*\) verschluckt das schliessende
	# Anfuehrungszeichen nicht, es bleibt im Wert stehen. Ergebnis war
	# 'quiet splash" pm_async=off ...'. Deshalb wird es getrennt entfernt.
	CUR="$(sed -n 's/^GRUB_CMDLINE_LINUX_DEFAULT=//p' "$GRUBDEF" | tail -1)"
	CUR="${CUR%\"}"; CUR="${CUR#\"}"
	CUR="${CUR%\'}"; CUR="${CUR#\'}"
	NEW="$CUR"
	for opt in $MX_CMDLINE; do
		case " $NEW " in *" $opt "*) ;; *) NEW="$NEW $opt" ;; esac
	done
	NEW="$(printf '%s' "$NEW" | sed 's/^ *//;s/ *$//')"
	if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUBDEF"; then
		sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$NEW\"|" "$GRUBDEF"
	else
		printf 'GRUB_CMDLINE_LINUX_DEFAULT="%s"\n' "$NEW" >> "$GRUBDEF"
	fi
	# Das Menue bleibt sichtbar. Ohne Menue ist eine Rettung schwerer.
	grep -q '^GRUB_TIMEOUT_STYLE=' "$GRUBDEF" \
		&& sed -i 's|^GRUB_TIMEOUT_STYLE=.*|GRUB_TIMEOUT_STYLE=menu|' "$GRUBDEF" \
		|| printf 'GRUB_TIMEOUT_STYLE=menu\n' >> "$GRUBDEF"
	grep -q '^GRUB_TIMEOUT=' "$GRUBDEF" \
		&& sed -i 's|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=5|' "$GRUBDEF" \
		|| printf 'GRUB_TIMEOUT=5\n' >> "$GRUBDEF"
	log_ok "Startparameter: $NEW"
else
	note_fail "$GRUBDEF fehlt im Zielsystem."
fi

# ---------------------------------------------------------------------------
log_step "3. Module fuer die fruehe Startumgebung"
# ---------------------------------------------------------------------------
# Ohne diese Module fehlen Tastatur und Trackpad schon vor dem Anmelden.
MODDIR="$TARGET/etc/initramfs-tools"
if [ -d "$MODDIR" ]; then
	MODF="$MODDIR/modules"
	touch "$MODF"
	ADDED=0
	for m in apple-mfi-fastcharge t2bce_dma t2bce_core t2bce_vhci; do
		# Nur Module aufnehmen, die es im Zielkernel wirklich gibt.
		if chroot "$TARGET" sh -c "find /lib/modules -name '${m}.ko*' -print -quit 2>/dev/null | grep -q ." 2>/dev/null; then
			grep -qx "$m" "$MODF" || { printf '%s\n' "$m" >> "$MODF"; ADDED=$((ADDED + 1)); }
		fi
	done
	log_ok "$ADDED Module fuer das Initramfs ergaenzt."
	MLD="$TARGET/etc/modules-load.d/maximus-t2.conf"
	mkdir -p "$(dirname "$MLD")"
	printf '# MAXIMUS T2: Module beim Start laden\nt2bce_vhci\n' > "$MLD"
	if in_target update-initramfs -u -k all >>"$MX_LOG" 2>&1; then
		log_ok "Das Initramfs ist neu gebaut."
	else
		note_fail "update-initramfs meldete einen Fehler."
	fi
	# Die geaenderten Startparameter wirken erst nach update-grub.
	# Gemessen: Ohne diesen Schritt startet das Ziel in 'grub>'.
	if in_target update-grub >>"$MX_LOG" 2>&1; then
		log_ok "Das Startmenue ist mit den neuen Parametern erzeugt."
	else
		note_fail "update-grub meldete einen Fehler."
	fi
	if [ -s "$TARGET/boot/grub/grub.cfg" ]; then
		log_ok "grub.cfg vorhanden ($(grep -c '^menuentry\|^submenu' "$TARGET/boot/grub/grub.cfg") Eintraege)."
	else
		note_fail "Es gibt keine /boot/grub/grub.cfg. Das Ziel startet nicht."
	fi
else
	note_fail "$MODDIR fehlt im Zielsystem."
fi

# ---------------------------------------------------------------------------
log_step "4. Firmware uebernehmen"
# ---------------------------------------------------------------------------
# Die Apple-Firmware ist nicht frei weitergebbar. Sie liegt nur dann hier,
# wenn du sie vorher selbst exportiert hast.
FWSRC="$MEDIUM_PATH/maximus/firmware/verified"
if [ -d "$FWSRC" ] && find "$FWSRC" -type f -print -quit 2>/dev/null | grep -q .; then
	NFW="$(find "$FWSRC" -type f | wc -l)"
	mkdir -p "$TARGET/lib/firmware/brcm"
	if cp -a "$FWSRC/." "$TARGET/lib/firmware/brcm/" 2>>"$MX_LOG"; then
		log_ok "$NFW Firmwaredateien uebernommen."
	else
		note_fail "Die Firmware liess sich nicht uebernehmen."
	fi
else
	log_warn "Es liegt keine geprueefte Apple-Firmware auf dem Medium."
	log_warn "WLAN und Bluetooth bleiben dann zunaechst ohne Funktion."
	log_warn "Abhilfe nach dem ersten Start: 'sudo get-apple-firmware get_from_macos'"
	log_warn "oder per Kabelnetz: 'sudo get-apple-firmware get_from_online'."
fi

# ---------------------------------------------------------------------------
log_step "5. Dienste einrichten"
# ---------------------------------------------------------------------------
for svc in t2fanrd tiny-dfr; do
	if chroot "$TARGET" sh -c "test -f /lib/systemd/system/$svc.service" 2>/dev/null; then
		if in_target systemctl enable "$svc" >>"$MX_LOG" 2>&1; then
			log_ok "Dienst eingeschaltet: $svc"
		else
			note_fail "Der Dienst $svc liess sich nicht einschalten."
		fi
	else
		log_warn "Dienst nicht vorhanden: $svc"
	fi
done

# ---------------------------------------------------------------------------
log_step "6. Paketquelle fuer kuenftige Kernelupdates"
# ---------------------------------------------------------------------------
# Ohne diese Quelle verliert das Ziel bei einem Kernelupdate die T2-Treiber.
# Der Schluessel liegt bei der Quelle, nicht im globalen Schluesselbund.
KEYSRC="$MEDIUM_PATH/maximus/apt/t2-ubuntu-repo.gpg"
if [ -f "$KEYSRC" ]; then
	mkdir -p "$TARGET/usr/share/keyrings"
	cp "$KEYSRC" "$TARGET/usr/share/keyrings/t2-ubuntu-repo.gpg" \
		|| note_fail "Der Signaturschluessel liess sich nicht ablegen."
	cat > "$TARGET/etc/apt/sources.list.d/t2-ubuntu-repo.sources" <<SRCEOF
Types: deb
URIs: https://adityagarg8.github.io/t2-ubuntu-repo
Suites: ./
Signed-By: /usr/share/keyrings/t2-ubuntu-repo.gpg
SRCEOF
	log_ok "Paketquelle eingetragen, Schluessel per Signed-By gebunden."
	log_info "Der T2-Kernel bleibt damit bei Updates versorgt."
else
	log_warn "Es liegt kein Signaturschluessel auf dem Medium."
	log_warn "Die T2-Paketquelle wurde NICHT eingetragen."
	log_warn "Ein Kernelupdate kann die T2-Treiber dann verlieren."
fi

# ---------------------------------------------------------------------------
log_step "7. Funktionsbericht fuer den ersten Start"
# ---------------------------------------------------------------------------
if [ -d "$SELF_DIR/firstboot" ]; then
	mkdir -p "$TARGET/opt/maximus"
	cp -a "$SELF_DIR/firstboot" "$TARGET/opt/maximus/" || note_fail "Der Erststart-Teil fehlt."
	cp -a "$SELF_DIR/lib" "$TARGET/opt/maximus/" || true
	if [ -f "$TARGET/opt/maximus/firstboot/maximus-firstboot.service" ]; then
		cp "$TARGET/opt/maximus/firstboot/maximus-firstboot.service" \
			"$TARGET/etc/systemd/system/maximus-firstboot.service"
		in_target systemctl enable maximus-firstboot.service >>"$MX_LOG" 2>&1 \
			&& log_ok "Der Funktionsbericht laeuft beim ersten Start." \
			|| note_fail "Der Erststart-Dienst liess sich nicht einschalten."
	fi
else
	note_fail "Das Verzeichnis firstboot/ fehlt auf dem Medium."
fi

# ---------------------------------------------------------------------------
log_step "8. Marke und Bericht ablegen"
# ---------------------------------------------------------------------------
mkdir -p "$TARGET/var/lib/maximus-t2"
{
	printf 'fassung=%s\n' "$MX_VERSION"
	printf 'zeitpunkt=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
	printf 'ziel_kennung=%s\n' "$T_SID"
	printf 'live_kernel=%s\n' "$(uname -r)"
	printf 'fehler_in_nachbereitung=%s\n' "$FAILED"
} > "$TARGET/var/lib/maximus-t2/neuinstall-fertig"
cp "$MX_LOG" "$TARGET/var/log/maximus-t2-neuinstall.log" 2>/dev/null || true
log_ok "Marke abgelegt: /var/lib/maximus-t2/neuinstall-fertig"
log_info "Ein zweiter Lauf des Assistenten erkennt diese Marke."

if [ "$FAILED" -gt 0 ]; then
	log_warn "Die Nachbereitung meldet $FAILED Fehler. Der Bericht nach dem"
	log_warn "ersten Start zeigt, was davon betroffen ist."
else
	log_ok "Die Nachbereitung ist ohne Fehler durchgelaufen."
fi
exit 0
