---
title: T2-Starteinstellungen einmalig setzen
created: 2026-10-10
type: anleitung
tags: [maximus, t2linux, macbookpro16-1, secure-boot]
---

# T2-Starteinstellungen einmalig setzen

**Diese Schritte kann keine Datei auf der Samsung T7 ersetzen.**
Die Einstellung liegt im T2-Chip. Sie wird in macOS gesetzt.
Ohne sie startet der Mac kein fremdes Betriebssystem.

Quelle: t2linux-Wiki, Seite `guides/preinstall`, Abschnitt
"Disable Secure Boot". Stand der gelesenen Fassung: Commit `986f5a7`.

## Wann musst du das tun?

**Vor** dem Löschen von macOS. Danach ist das Startsicherheitsdienstprogramm
nicht mehr erreichbar, weil es Teil der macOS-Wiederherstellung ist.

## Schritte

1. Schalte den Mac aus.
2. Schalte ihn ein. Halte sofort **Command-R** gedrückt.
   Halte die Tasten, bis der schwarze Bildschirm kurz aufblitzt.
3. Der Mac startet in die macOS-Wiederherstellung.
4. Wähle deinen Benutzer. Gib dein Passwort ein.
5. Öffne in der Menüleiste: **Dienstprogramme → Startsicherheitsdienstprogramm**.
6. Gib dein Passwort erneut ein.
7. Setze **Sicherer Systemstart** auf **Keine Sicherheit**.
8. Setze **Externes Booten** auf
   **Booten von externen oder Wechselmedien erlauben**.
9. Starte neu.

## Gegenprobe

Halte beim Start die **Wahltaste (⌥)** gedrückt.
Erscheint die Samsung T7 als orange **EFI Boot**, dann ist die
Einstellung wirksam.

Erscheinen **zwei** Einträge "EFI Boot", dann wähle zuerst den **rechten**.

## Fehlermeldung "Für diesen Startvolume ist ein Softwareupdate erforderlich"

Diese Meldung bedeutet: Der sichere Systemstart ist noch aktiv.
Gehe zurück zu Schritt 5.

Die Meldung kann auch erscheinen, wenn das Medium als APFS oder
"macOS Extended" formatiert ist. Das Installationsmedium dieses Pakets
ist das nicht.

## Sicherheit danach

Du kannst die Sicherheit teilweise zurückholen:

- Im Startsicherheitsdienstprogramm lässt sich ein **Firmware-Passwort**
  einschalten. Dann braucht jeder Start eines anderen Systems ein Passwort.
- Nach der Installation auf der internen SSD kannst du
  **Booten von externen Medien** wieder verbieten.

**Achtung:** Verbiete das externe Booten erst, wenn Ubuntu von der internen
SSD startet. Sonst sperrst du dich aus.

## rEFInd: nur mit vorhandenem macOS möglich

Das t2linux-Wiki empfiehlt den Startmanager **rEFInd**, weil GRUB von Ubuntu
bei vielen Nutzern nicht über den Mac-Startmanager startet.

**rEFInd lässt sich nur aus macOS heraus installieren.** Die Installation
braucht `diskutil`, `refind-install` und `bless`. Alle drei gibt es nur in
macOS.

Wenn du macOS entfernen willst und rEFInd nutzen möchtest, dann installiere
rEFInd **vorher**:

1. Lege mit dem Festplattendienstprogramm eine Partition von 100 bis 200 MB
   als **MS-DOS (FAT)** an. Bezeichne sie **REFIND**.
2. Folge der Anleitung des Projekts:
   `https://wiki.t2linux.org/guides/refind/`
3. Prüfe mit gehaltener Wahltaste, dass rEFInd startet.

Die REFIND-Partition überlebt eine Neuinstallation nur dann, wenn du in
Betriebsart 2 arbeitest. Betriebsart 1 löscht die ganze Platte.
