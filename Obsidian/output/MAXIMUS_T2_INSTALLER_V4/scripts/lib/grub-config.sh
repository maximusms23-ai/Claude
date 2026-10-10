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
	# V4.1: Beide Anfuehrungsarten entfernen. Ubuntu nutzt doppelte, ein
	# Benutzer kann aber einfache gesetzt haben. Sonst landen die Zeichen
	# als Kernelparameter in der Zeile.
	grep -E '^GRUB_CMDLINE_LINUX=' "$f" | tail -1 \
		| sed -e 's/^GRUB_CMDLINE_LINUX=//' \
		      -e 's/^"\(.*\)"$/\1/' \
		      -e "s/^'\(.*\)'\$/\1/"
}

# Maskiert eine Zeichenkette fuer die Ersetzungsseite von sed.
# Ohne diese Maskierung bedeutet '&' dort "der ganze Treffer".
# Gemessen in V4.1: 'KEY=a&b' wurde zu 'KEY=aKEY=altb'.
# Das Trennzeichen '|' muss ebenfalls maskiert werden, sonst bricht sed ab.
# Die Umsetzung nutzt Parameterersetzung. Sie ist eindeutig lesbar.
mt2_sed_escape_replacement() {
	local s="$1"
	s="${s//\\/\\\\}"
	s="${s//&/\\&}"
	s="${s//|/\\|}"
	printf '%s' "$s"
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
			local esc
			esc="$(mt2_sed_escape_replacement "$new")"
			sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"$esc\"|" "$f"
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
	local key value esc
	while IFS='=' read -r key value; do
		case "$key" in
			''|\#*) continue ;;
		esac
		esc="$(mt2_sed_escape_replacement "$value")"
		if grep -qE "^#?${key}=" "$f"; then
			sed -i "s|^#\?${key}=.*|${key}=${esc}|" "$f"
		else
			printf '%s=%s\n' "$key" "$value" >> "$f"
		fi
		printf '%s=%s\n' "$key" "$value"
	done < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$keyfile")
	return 0
}
