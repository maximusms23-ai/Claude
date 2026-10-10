#!/usr/bin/env bash
# MAXIMUS T2 Neuinstallation V1 - Installation ohne Grafik
#
# Ergebnis: Das bestaetigte Ziel traegt danach ein startfaehiges Ubuntu
# mit T2-Unterstuetzung.
#
# WARUM NICHT ubiquity im automatischen Betrieb?
# Gemessen: Das Frontend 'noninteractive' von ubiquity kann keine gefuehrte
# Partitionierung. Seine Klasse PageNoninteractive in
# /usr/lib/ubiquity/plugins/ubi-partman.py kennt die beiden noetigen
# Methoden nicht:
#   class PageNoninteractive(PageBase):
#       def set_part_page(self, p):
#           pass
# PageGtk und PageKde haben set_autopartition_options und
# get_autopartition_choice, PageNoninteractive nicht.
# Im Prueflauf endete ubiquity deshalb in einer Schleife mit der Meldung
# "Kein Root-Dateisystem: Es wurde kein Root-Dateisystem festgelegt."
#
# Dieses Skript macht genau das, was ubiquity sonst tut: Es teilt die Platte
# auf, legt Dateisysteme an, packt das Live-Abbild aus und richtet das
# System ein. Jeder Schritt ist einzeln protokolliert und nachpruefbar.
#
# Aufruf: bash install-direct.sh --device GERAET --user NAME --fullname TEXT
#                                --host NAME --passfile DATEI [--dry-run]

set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SELF_DIR/lib/common.sh"

DEV=''; U_NAME=''; U_FULL=''; U_HOST='macbook-t2'; PASSFILE=''; DRY_RUN=0
while [ "$#" -gt 0 ]; do
	case "$1" in
		--device)   DEV="${2:?}"; shift ;;
		--user)     U_NAME="${2:?}"; shift ;;
		--fullname) U_FULL="${2:?}"; shift ;;
		--host)     U_HOST="${2:?}"; shift ;;
		--passfile) PASSFILE="${2:?}"; shift ;;
		--dry-run)  DRY_RUN=1 ;;
		*) die "$RC_USAGE" "Unbekannte Option '$1'." "Lies den Kopf dieses Skripts." ;;
	esac
	shift
done

MX_LOG=/var/log/maximus-t2-neuinstall.log
mx_require_root
[ -b "$DEV" ] || die "$RC_USAGE" "--device '$DEV' ist kein Blockgeraet." "Pruefe die Angabe."
[ -n "$U_NAME" ] || die "$RC_USAGE" "--user fehlt." "Der Benutzername ist noetig."
[ -n "$PASSFILE" ] && [ -f "$PASSFILE" ] || die "$RC_USAGE" "--passfile fehlt." "Das Passwort wird nicht als Argument uebergeben."
for t in sgdisk mkfs.vfat mkfs.ext4 unsquashfs blkid chroot; do mx_require_tool "$t"; done

TARGET=/target
SQUASH=''
for c in /cdrom/casper/filesystem.squashfs /run/live/medium/casper/filesystem.squashfs; do
	[ -f "$c" ] && { SQUASH="$c"; break; }
done
[ -n "$SQUASH" ] || die "$RC_INSTALL" "Das Live-Abbild filesystem.squashfs ist nicht auffindbar." \
	"Ohne das Abbild ist keine Installation moeglich."

# Sicherheitsgegenprobe: Das Ziel darf nicht das laufende Medium sein.
MEDIUM="$(mx_live_medium_disk 2>/dev/null)" || MEDIUM=''
if [ -n "$MEDIUM" ] && [ "$(readlink -f "$DEV")" = "$(readlink -f "$MEDIUM")" ]; then
	die "$RC_TARGET_IS_MEDIUM" "Das Ziel ist das laufende Installationsmedium." "Abbruch."
fi
ROOTSRC="$(findmnt -no SOURCE / 2>/dev/null)"
if [ -n "$ROOTSRC" ] && [ "$(lsblk -no PKNAME "$ROOTSRC" 2>/dev/null | head -1)" = "$(basename "$DEV")" ]; then
	die "$RC_TARGET_IS_MEDIUM" "Das Ziel traegt das laufende Wurzeldateisystem." "Abbruch."
fi

log_step "Installation auf $DEV"
log_info "Live-Abbild: $SQUASH ($(du -h "$SQUASH" | cut -f1))"
if [ "$DRY_RUN" -eq 1 ]; then
	log_warn "SIMULATION. Es wird nichts geschrieben."
fi

PART_EFI=""; PART_ROOT=""
part_name() {
	case "$DEV" in
		*[0-9]) printf '%sp%s\n' "$DEV" "$1" ;;
		*)      printf '%s%s\n' "$DEV" "$1" ;;
	esac
}

# ---------------------------------------------------------------------------
log_step "1. Einhaengungen loesen"
# ---------------------------------------------------------------------------
while read -r pn mp; do
	[ -n "$mp" ] || continue
	if [ "$DRY_RUN" -eq 1 ]; then
		log "         [wuerde aushaengen] /dev/$pn"
	else
		umount "/dev/$pn" 2>/dev/null && log_ok "ausgehaengt: /dev/$pn" || true
	fi
done < <(lsblk -nlo NAME,MOUNTPOINT "$DEV" 2>/dev/null | tail -n +2)
swapoff -a 2>/dev/null || true

# ---------------------------------------------------------------------------
log_step "2. Partitionstabelle anlegen"
# ---------------------------------------------------------------------------
# GPT mit zwei Partitionen:
#   1  512 MiB  EFI-Systempartition (FAT32)
#   2  Rest     Wurzeldateisystem (ext4)
if [ "$DRY_RUN" -eq 1 ]; then
	log "         [wuerde ausfuehren] sgdisk --zap-all $DEV"
	log "         [wuerde ausfuehren] sgdisk -n1:0:+512M -t1:ef00 -c1:EFI $DEV"
	log "         [wuerde ausfuehren] sgdisk -n2:0:0 -t2:8300 -c2:ubuntu $DEV"
else
	sgdisk --zap-all "$DEV" >>"$MX_LOG" 2>&1 \
		|| die "$RC_INSTALL" "Die Partitionstabelle liess sich nicht loeschen." "Pruefe $MX_LOG."
	sgdisk -n1:0:+512M -t1:ef00 -c1:EFI "$DEV" >>"$MX_LOG" 2>&1 \
		|| die "$RC_INSTALL" "Die EFI-Partition liess sich nicht anlegen." "Pruefe $MX_LOG."
	sgdisk -n2:0:0 -t2:8300 -c2:ubuntu "$DEV" >>"$MX_LOG" 2>&1 \
		|| die "$RC_INSTALL" "Die Wurzelpartition liess sich nicht anlegen." "Pruefe $MX_LOG."
	partprobe "$DEV" 2>/dev/null || true
	udevadm settle 2>/dev/null || sleep 3
	log_ok "Partitionstabelle angelegt:"
	lsblk -no NAME,SIZE,PARTTYPENAME "$DEV" | sed 's/^/         /' | tee -a "$MX_LOG"
fi
PART_EFI="$(part_name 1)"; PART_ROOT="$(part_name 2)"
log_info "EFI:   $PART_EFI"
log_info "Wurzel: $PART_ROOT"

# ---------------------------------------------------------------------------
log_step "3. Dateisysteme anlegen"
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 1 ]; then
	log "         [wuerde ausfuehren] mkfs.vfat -F32 -n EFI $PART_EFI"
	log "         [wuerde ausfuehren] mkfs.ext4 -F -L ubuntu $PART_ROOT"
else
	[ -b "$PART_EFI" ] || die "$RC_INSTALL" "$PART_EFI ist nicht erschienen." "Pruefe die Partitionierung."
	[ -b "$PART_ROOT" ] || die "$RC_INSTALL" "$PART_ROOT ist nicht erschienen." "Pruefe die Partitionierung."
	mkfs.vfat -F32 -n EFI "$PART_EFI" >>"$MX_LOG" 2>&1 \
		|| die "$RC_INSTALL" "Die EFI-Partition liess sich nicht formatieren." "Pruefe $MX_LOG."
	mkfs.ext4 -F -L ubuntu "$PART_ROOT" >>"$MX_LOG" 2>&1 \
		|| die "$RC_INSTALL" "Die Wurzelpartition liess sich nicht formatieren." "Pruefe $MX_LOG."
	log_ok "Dateisysteme angelegt."
fi

# ---------------------------------------------------------------------------
log_step "4. Ziel einhaengen"
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ]; then
	mkdir -p "$TARGET"
	mount "$PART_ROOT" "$TARGET" \
		|| die "$RC_INSTALL" "Das Ziel liess sich nicht einhaengen." "Pruefe $MX_LOG."
	mkdir -p "$TARGET/boot/efi"
	mount "$PART_EFI" "$TARGET/boot/efi" \
		|| die "$RC_INSTALL" "Die EFI-Partition liess sich nicht einhaengen." "Pruefe $MX_LOG."
	log_ok "Eingehaengt: $TARGET und $TARGET/boot/efi"
fi

# ---------------------------------------------------------------------------
log_step "5. Betriebssystem auspacken"
# ---------------------------------------------------------------------------
# Das ist derselbe Inhalt, den ubiquity kopiert. Es wird nichts geladen.
if [ "$DRY_RUN" -eq 1 ]; then
	log "         [wuerde ausfuehren] unsquashfs -f -d $TARGET $SQUASH"
else
	log_info "Das dauert einige Minuten. Es wird nichts aus dem Netz geladen."
	if ! unsquashfs -f -d "$TARGET" "$SQUASH" >>"$MX_LOG" 2>&1; then
		die "$RC_INSTALL" "Das Auspacken des Abbilds schlug fehl." "Pruefe $MX_LOG."
	fi
	NF="$(find "$TARGET" -xdev -type f 2>/dev/null | wc -l)"
	log_ok "Ausgepackt: $NF Dateien, $(du -sh --one-file-system "$TARGET" 2>/dev/null | cut -f1)"
	[ "$NF" -gt 10000 ] || die "$RC_INSTALL" "Das Ziel traegt nur $NF Dateien. Das ist zu wenig." \
		"Die Installation ist unvollstaendig."
fi

# ---------------------------------------------------------------------------
log_step "6. Dateisystemtabelle schreiben"
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ]; then
	UUID_ROOT="$(blkid -s UUID -o value "$PART_ROOT")"
	UUID_EFI="$(blkid -s UUID -o value "$PART_EFI")"
	[ -n "$UUID_ROOT" ] && [ -n "$UUID_EFI" ] \
		|| die "$RC_INSTALL" "Die UUIDs liessen sich nicht lesen." "Pruefe $MX_LOG."
	{
		printf '# MAXIMUS T2 Neuinstallation V%s\n' "$MX_VERSION"
		printf '# Die Eintraege nutzen UUIDs. Ein Geraetename waere nicht stabil.\n'
		printf 'UUID=%s  /          ext4  errors=remount-ro  0  1\n' "$UUID_ROOT"
		printf 'UUID=%s  /boot/efi  vfat  umask=0077         0  1\n' "$UUID_EFI"
	} > "$TARGET/etc/fstab"
	log_ok "fstab geschrieben:"
	grep -v '^#' "$TARGET/etc/fstab" | sed 's/^/         /' | tee -a "$MX_LOG"
fi

# ---------------------------------------------------------------------------
log_step "7. Systemverzeichnisse einbinden"
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ]; then
	for d in dev dev/pts proc sys run; do
		mkdir -p "$TARGET/$d"
		mount --bind "/$d" "$TARGET/$d" 2>/dev/null || mount -t "${d##*/}" "${d##*/}" "$TARGET/$d" 2>/dev/null || true
	done
	mount --bind /sys/firmware/efi/efivars "$TARGET/sys/firmware/efi/efivars" 2>/dev/null || true
	log_ok "Systemverzeichnisse eingebunden."
fi

in_target() { chroot "$TARGET" env DEBIAN_FRONTEND=noninteractive LC_ALL=C "$@"; }

# ---------------------------------------------------------------------------
log_step "8. System einrichten"
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ]; then
	printf '%s\n' "$U_HOST" > "$TARGET/etc/hostname"
	{
		printf '127.0.0.1\tlocalhost\n'
		printf '127.0.1.1\t%s\n' "$U_HOST"
		printf '::1\tlocalhost ip6-localhost ip6-loopback\n'
	} > "$TARGET/etc/hosts"
	log_ok "Rechnername: $U_HOST"

	# Sprache, Tastatur, Zeitzone
	printf 'LANG=de_DE.UTF-8\nLANGUAGE=de_DE:de\nLC_ALL=de_DE.UTF-8\n' > "$TARGET/etc/default/locale"
	printf 'de_DE.UTF-8 UTF-8\nen_US.UTF-8 UTF-8\n' > "$TARGET/etc/locale.gen"
	in_target locale-gen >>"$MX_LOG" 2>&1 && log_ok "Sprache: de_DE.UTF-8" \
		|| log_warn "locale-gen meldete einen Fehler."
	{
		printf 'XKBMODEL="pc105"\nXKBLAYOUT="de"\nXKBVARIANT=""\nXKBOPTIONS=""\n'
		printf 'BACKSPACE="guess"\n'
	} > "$TARGET/etc/default/keyboard"
	log_ok "Tastatur: de (pc105)"
	in_target ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
	printf 'Europe/Berlin\n' > "$TARGET/etc/timezone"
	log_ok "Zeitzone: Europe/Berlin"

	# Benutzer anlegen. Das Passwort steht nie in der Befehlszeile.
	if in_target id "$U_NAME" >/dev/null 2>&1; then
		log_info "Der Benutzer $U_NAME ist schon vorhanden."
	else
		in_target useradd -m -s /bin/bash -c "$U_FULL" "$U_NAME" >>"$MX_LOG" 2>&1 \
			|| die "$RC_INSTALL" "Der Benutzer liess sich nicht anlegen." "Pruefe $MX_LOG."
	fi
	for g in sudo adm cdrom dip plugdev lpadmin; do
		in_target getent group "$g" >/dev/null 2>&1 && in_target usermod -aG "$g" "$U_NAME" 2>/dev/null || true
	done
	# chpasswd liest von der Standardeingabe. Kein Argument, kein Protokoll.
	if printf '%s:%s' "$U_NAME" "$(cat "$PASSFILE")" | in_target chpasswd 2>>"$MX_LOG"; then
		log_ok "Benutzer $U_NAME angelegt und Passwort gesetzt."
	else
		die "$RC_INSTALL" "Das Passwort liess sich nicht setzen." "Pruefe $MX_LOG."
	fi
	in_target passwd -l root >>"$MX_LOG" 2>&1 && log_ok "Das Konto root ist gesperrt." || true

	# Live-Bestandteile entfernen. Sonst startet das Ziel als Live-System.
	in_target apt-get -y --purge remove casper ubiquity ubiquity-casper \
		ubiquity-frontend-gtk ubiquity-slideshow-ubuntu ubiquity-ubuntu-artwork \
		lupin-casper >>"$MX_LOG" 2>&1 \
		&& log_ok "Live-Bestandteile entfernt." \
		|| log_warn "Nicht alle Live-Bestandteile liessen sich entfernen."
	rm -f "$TARGET/etc/sudoers.d/casper" 2>/dev/null || true
	rm -f "$TARGET/etc/sudoers.d/90-ubuntu-live" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
log_step "9. Bootloader einrichten"
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ]; then
	# --removable legt EFI/BOOT/BOOTX64.EFI an. Genau diesen Pfad findet der
	# Startmanager des Mac. Ohne ihn erscheint der Eintrag oft nicht.
	if in_target grub-install --target=x86_64-efi --efi-directory=/boot/efi \
		--bootloader-id=ubuntu --removable --no-nvram >>"$MX_LOG" 2>&1; then
		log_ok "GRUB in die EFI-Partition geschrieben (auch als EFI/BOOT/BOOTX64.EFI)."
	else
		die "$RC_INSTALL" "grub-install schlug fehl." "Das Ziel waere nicht startfaehig. Pruefe $MX_LOG."
	fi
	# Zusaetzlich der uebliche Pfad, falls NVRAM doch nutzbar ist.
	in_target grub-install --target=x86_64-efi --efi-directory=/boot/efi \
		--bootloader-id=ubuntu >>"$MX_LOG" 2>&1 || true
	for f in /boot/efi/EFI/BOOT/BOOTX64.EFI /boot/efi/EFI/ubuntu/grubx64.efi; do
		if [ -f "$TARGET$f" ]; then
			log_ok "vorhanden: $f ($(stat -c%s "$TARGET$f") Byte)"
		else
			log_warn "fehlt: $f"
		fi
	done
fi

log_step "10. Ergebnis"
if [ "$DRY_RUN" -eq 1 ]; then
	log_ok "Simulation beendet. Es wurde nichts geschrieben."
	exit "$RC_OK"
fi
log_ok "Das Betriebssystem ist installiert."
log_info "Die Nachbereitung (Treiber, Dienste, Bericht) folgt getrennt."
exit "$RC_OK"
