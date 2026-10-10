#!/usr/bin/env bash
# shellcheck shell=bash
# MAXIMUS_T2_INSTALLER_V4 - /etc/default/grub bearbeiten
#
# Diese Datei wird eingelesen. Sie startet nichts selbst.
# Beide Funktionen arbeiten auf einer uebergebenen Datei.
# Dadurch sind sie mit einer Testvorlage pruefbar.
#
# Beide Funktionen sind mehrfach aufrufbar. Ein zweiter Aufruf aendert nichts.

# mt2_grub_read_cmdline <grubdatei>
# Gibt den Inhalt von GRUB_CMDLINE_LINUX ohne Anfuehrungszeichen aus.
mt2_grub_read_cmdline() {
	local f="$1"
	[ -f "$f" ] || return 1
	grep -E '^GRUB_CMDLINE_LINUX=' "$f" | tail -1 \
		| sed -e 's/^GRUB_CMDLINE_LINUX=//' -e 's/^"//' -e 's/"$//'
}

# mt2_grub_merge_cmdline <grubdatei> <parameter>...
# Ergaenzt Kernelparameter in GRUB_CMDLINE_LINUX.
# Ein Parameter, dessen Schluessel bereits gesetzt ist, bleibt unveraendert.
# Gibt die neue Zeile auf der Standardausgabe aus.
# Rueckgabe: 0 bei Erfolg, 1 wenn die Datei fehlt.
mt2_grub_merge_cmdline() {
	local f="$1"; shift
	[ -f "$f" ] || return 1
	local current new key p
	current="$(mt2_grub_read_cmdline "$f" || true)"
	new="$current"
	for p in "$@"; do
		key="${p%%=*}"
		if printf '%s' " $new " | grep -q " ${key}[= ]"; then
			continue
		fi
		new="${new:+$new }$p"
	done
	if [ "$new" != "$current" ]; then
		if grep -qE '^GRUB_CMDLINE_LINUX=' "$f"; then
			sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"$new\"|" "$f"
		else
			printf '\n# MAXIMUS_T2_INSTALLER_V4\nGRUB_CMDLINE_LINUX="%s"\n' "$new" >> "$f"
		fi
	fi
	printf '%s\n' "$new"
	return 0
}

# mt2_grub_set_keys <grubdatei> <schluesseldatei>
# Setzt jede Zeile SCHLUESSEL=WERT aus der Schluesseldatei.
# Ein auskommentierter Schluessel wird aktiviert.
# Ein fehlender Schluessel wird angehaengt.
# Gibt je gesetzten Schluessel eine Zeile aus.
mt2_grub_set_keys() {
	local f="$1" keyfile="$2"
	[ -f "$f" ] || return 1
	[ -f "$keyfile" ] || return 1
	local key value
	while IFS='=' read -r key value; do
		case "$key" in
			''|\#*) continue ;;
		esac
		if grep -qE "^#?${key}=" "$f"; then
			sed -i "s|^#\?${key}=.*|${key}=${value}|" "$f"
		else
			printf '%s=%s\n' "$key" "$value" >> "$f"
		fi
		printf '%s=%s\n' "$key" "$value"
	done < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$keyfile")
	return 0
}
