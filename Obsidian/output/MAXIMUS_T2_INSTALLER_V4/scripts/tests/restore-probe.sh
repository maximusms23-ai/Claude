#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER V4.2 - Probe: echte Wiederherstellung
#
# Ergebnis: Die Probe weist nach, dass rollback.sh Dateien wirklich
# zurueckschreibt. Sie misst nicht nur die Ankuendigung.
#
# Die Probe laeuft in einem eigenen Mount-Namensraum.
# Sie haengt temporaere Verzeichnisse ueber die Systempfade.
# Das Wirtsystem bleibt dabei unveraendert.
#
# Aufruf: unshare -m bash restore-probe.sh <skriptverzeichnis> <arbeitspfad> <fall>
#   Fall 'gut'     - gueltige Sicherung, die Wiederherstellung muss gelingen
#   Fall 'kaputt'  - beschaedigte Sicherung, der Rueckfall muss abbrechen
#
# Ausgabe: Zeilen der Form schluessel=wert

set -uo pipefail

SCRIPTS="${1:?Skriptverzeichnis fehlt}"
W="${2:?Arbeitspfad fehlt}"
CASE="${3:-gut}"

# shellcheck source=lib/common.sh
. "$SCRIPTS/lib/common.sh"

if [ "$(id -u)" -ne 0 ]; then
	printf 'fehler=rootrechte\n'; exit 3
fi

# Die Einhaengungen duerfen nicht nach aussen wirken.
mount --make-rprivate / 2>/dev/null || true

mkdir -p "$W"/{etcdef,boot/grub,mld,state,backups,log,orig}

# -------------------------------------------------------------------------
# Urzustand. Er ist der Vergleichsmassstab.
# -------------------------------------------------------------------------
printf 'GRUB_TIMEOUT=5\nGRUB_CMDLINE_LINUX_DEFAULT="quiet splash"\n' > "$W/orig/grub"
printf 'menuentry "Ubuntu" {\n  linux /vmlinuz-7.0.0-38-generic\n}\n'  > "$W/orig/grub.cfg"
cp "$W/orig/grub"     "$W/etcdef/grub"
cp "$W/orig/grub.cfg" "$W/boot/grub/grub.cfg"

mkdir -p "$MT2_STATE_DIR" "$MT2_BACKUP_ROOT" "$MT2_LOG_DIR"
mount --bind "$W/etcdef"  /etc/default        || { printf 'fehler=bind_etcdefault\n'; exit 1; }
mount --bind "$W/boot"    /boot               || { printf 'fehler=bind_boot\n'; exit 1; }
mount --bind "$W/mld"     /etc/modules-load.d || { printf 'fehler=bind_mld\n'; exit 1; }
mount --bind "$W/state"   "$MT2_STATE_DIR"    || { printf 'fehler=bind_state\n'; exit 1; }
mount --bind "$W/backups" "$MT2_BACKUP_ROOT"  || { printf 'fehler=bind_backups\n'; exit 1; }
mount --bind "$W/log"     "$MT2_LOG_DIR"      || { printf 'fehler=bind_log\n'; exit 1; }
printf 'namensraum=aktiv\n'

# -------------------------------------------------------------------------
# Sicherung aufbauen, wie install.sh sie anlegt
# -------------------------------------------------------------------------
BK="$MT2_BACKUP_ROOT/19700101T000000Z"
mkdir -p "$BK"
cp /etc/default/grub   "$BK/etc-default-grub"
cp /boot/grub/grub.cfg "$BK/grub.cfg"
printf 'beispielpaket\t1.0\n' > "$BK/pkg-before.txt"
printf 'beispielpaket\tinstall\n' > "$BK/dpkg-selections.txt"
printf '7.0.0-38-generic\n' > "$BK/running-kernel.txt"
printf '%s\n' "$MT2_VERSION" > "$BK/installer-version.txt"
{
	printf 'gesichert\tpflicht\t/etc/default/grub\tetc-default-grub\n'
	printf 'gesichert\tpflicht\t/boot/grub/grub.cfg\tgrub.cfg\n'
	printf 'gesichert\tpflicht\tdpkg-Bestand\tpkg-before.txt\n'
	printf 'erzeugt\tpflicht\tdpkg --get-selections\tdpkg-selections.txt\n'
	printf 'erzeugt\tpflicht\tuname -r\trunning-kernel.txt\n'
	printf 'erzeugt\tpflicht\tinstaller\tinstaller-version.txt\n'
} > "$BK/MANIFEST"
mt2_backup_seal "$BK" >/dev/null 2>&1 || { printf 'fehler=siegel\n'; exit 1; }

printf '%s\n' "$BK" > "$MT2_STATE_DIR/last-backup"
printf 'version=%s\nphase=done\n' "$MT2_VERSION" > "$MT2_STATE_DIR/install-state"
printf 'replace\t/etc/default/grub\ncreate\t/etc/modules-load.d/t2.conf\n' \
	> "$MT2_STATE_DIR/files-written.txt"
cp "$BK/pkg-before.txt" "$MT2_STATE_DIR/pkg-before.txt"
: > "$MT2_STATE_DIR/held-by-maximus.txt"

# -------------------------------------------------------------------------
# Fehler-Injektion: eine Pflichtdatei aus der Sicherung entfernen
# -------------------------------------------------------------------------
if [ "$CASE" = "kaputt" ]; then
	rm -f "$BK/etc-default-grub"
	mt2_backup_seal "$BK" >/dev/null 2>&1 || true
	printf 'fall=kaputt\n'
else
	printf 'fall=gut\n'
fi

# -------------------------------------------------------------------------
# Die Installation aendert die Dateien
# -------------------------------------------------------------------------
printf 'GRUB_TIMEOUT=0\nGRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on iommu=pt pm_async=off"\n' \
	> /etc/default/grub
printf 'menuentry "T2" {\n  linux /vmlinuz-6.18.54-1-t2-noble\n}\n' > /boot/grub/grub.cfg
printf 't2bce_vhci\n' > /etc/modules-load.d/t2.conf

cmp -s /etc/default/grub "$W/orig/grub" \
	&& printf 'vorher_geaendert=nein\n' || printf 'vorher_geaendert=ja\n'

# -------------------------------------------------------------------------
# Echter Rueckfall. Keine Simulation.
# -------------------------------------------------------------------------
RB_RC=0
bash "$SCRIPTS/rollback.sh" --yes --no-color > "$W/rollback.log" 2>&1 || RB_RC=$?
printf 'rueckfall_rc=%s\n' "$RB_RC"

# -------------------------------------------------------------------------
# Messung: Stimmt der Inhalt wieder Byte fuer Byte?
# -------------------------------------------------------------------------
cmp -s /etc/default/grub "$W/orig/grub" \
	&& printf 'grub_zurueck=ja\n' || printf 'grub_zurueck=nein\n'
cmp -s /boot/grub/grub.cfg "$W/orig/grub.cfg" \
	&& printf 'grubcfg_zurueck=ja\n' || printf 'grubcfg_zurueck=nein\n'
[ -e /etc/modules-load.d/t2.conf ] \
	&& printf 'neue_datei_entfernt=nein\n' || printf 'neue_datei_entfernt=ja\n'

printf 'protokoll=%s\n' "$W/rollback.log"
exit 0
