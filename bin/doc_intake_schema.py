"""
doc_intake_schema — Pydantic-Schemas fuer tom-doc-intake.

Definiert das strukturierte Output-Format fuer die KI-gesteuerte
Dokument-Aufnahme. Wird von tom-doc-intake importiert und als
JSON-Schema an Ollama's format-Parameter uebergeben.

Kategorien spiegeln die Archiv-Struktur auf /Volumes/Archiv/ARCIV/.
"""

from enum import Enum
from typing import Optional

try:
    from pydantic import BaseModel, Field
except ImportError:
    import sys
    print(
        "FEHLER: pydantic nicht installiert.\n"
        "  pip install pydantic\n"
        "oder:\n"
        "  uv pip install pydantic",
        file=sys.stderr,
    )
    sys.exit(1)


class ArchivKategorie(str, Enum):
    """16 Archiv-Kategorien auf /Volumes/Archiv/ARCIV/."""
    ARBEIT = "01_Arbeit"
    BUNDESWEHR = "02_Bundeswehr"
    RECHNUNGEN = "03_Rechnungen"
    VERSICHERUNGEN = "04_Versicherungen"
    BILDUNG = "05_Bildung"
    GESUNDHEIT = "06_Gesundheit"
    VERTRAEGE = "07_Vertraege"
    URKUNDEN = "08_Urkunden"
    RENTE = "09_Rente"
    STEUER = "10_Steuer"
    AUTO = "11_Auto"
    FINANZEN = "12_Finanzen"
    UNI = "13_Uni"
    BETREUUNG = "14_Betreuung"
    WOHNUNG = "15_Wohnung"
    SONSTIGES = "16_Sonstiges"


class UebermittlungArt(str, Enum):
    """Wie das Dokument uebermittelt wurde / werden soll."""
    EMAIL = "Email"
    BRIEF = "Brief"
    FAX = "Fax"
    TELEFONANRUF = "Telefonanruf"
    ONLINE_PORTAL = "Online-Portal"
    PERSOENLICH = "Persoenlich"
    UNBEKANNT = ""


class DocIntakeResult(BaseModel):
    """Strukturiertes Ergebnis der KI-Dokument-Analyse.

    Wird als JSON-Schema an Ollama format-Parameter uebergeben:
        format=DocIntakeResult.model_json_schema()
    """

    betreff_kurz: str = Field(
        description="Kurzer Betreff des Dokuments, max 80 Zeichen"
    )
    absender: str = Field(
        description="Absender-Name oder Organisation"
    )
    empfaenger: list[str] = Field(
        default_factory=list,
        description="Liste der Empfaenger (Personen oder Organisationen)",
    )
    kategorie: ArchivKategorie = Field(
        description="Vorgeschlagene Archiv-Kategorie (01-16)"
    )
    zusammenfassung: str = Field(
        description="2-3 Saetze Zusammenfassung des Dokument-Inhalts"
    )

    # --- Steuer-Relevanz ---
    steuer_relevant: bool = Field(
        default=False,
        description="Ist das Dokument steuerlich relevant?",
    )

    # --- Krankenversicherung-Relevanz ---
    kv_relevant: bool = Field(
        default=False,
        description="Hat das Dokument Bezug zur Krankenversicherung?",
    )
    kv_details: str = Field(
        default="",
        description="Details zur KV-Relevanz, z.B. Beitragsanpassung, Leistungsbescheid",
    )

    # --- Renten-Relevanz ---
    rente_relevant: bool = Field(
        default=False,
        description="Hat das Dokument Bezug zur Rente/Altersvorsorge?",
    )
    rente_details: str = Field(
        default="",
        description="Details zur Renten-Relevanz, z.B. Renteninformation, Anrechnungszeiten",
    )

    # --- Finanzen/Budget-Relevanz ---
    finanzen_relevant: bool = Field(
        default=False,
        description="Enthaelt das Dokument finanzielle Forderungen oder Zahlungen?",
    )
    finanzen_betrag: Optional[str] = Field(
        default=None,
        description="Extrahierter Geldbetrag mit Waehrung, z.B. '342.50 EUR'",
    )
    finanzen_faelligkeit: Optional[str] = Field(
        default=None,
        description="Zahlungsfrist im Format YYYY-MM-DD",
    )
    finanzen_budgetiert: bool = Field(
        default=False,
        description="Einschaetzung: Ist dieser Betrag vermutlich im Budget eingeplant?",
    )
    finanzen_details: str = Field(
        default="",
        description="Details zur Finanz-Relevanz, z.B. Nebenkostenabrechnung, Nachzahlung",
    )

    # --- Uebermittlung ---
    uebermittlung_art: str = Field(
        default="",
        description="Wie wurde das Dokument empfangen: Email, Brief, Fax, Online-Portal, Persoenlich",
    )

    # --- Verknuepfungen ---
    abhaengigkeiten: list[str] = Field(
        default_factory=list,
        description="Erkannte Bezuege zu anderen Dokumenten oder Vorgaengen",
    )
    personen_erkannt: list[str] = Field(
        default_factory=list,
        description="Im Dokument erkannte Personen-Namen",
    )
    antwortfrist: Optional[str] = Field(
        default=None,
        description="Empfohlene Antwortfrist im Format YYYY-MM-DD, falls Handlung noetig",
    )
    archiv_kategorie: ArchivKategorie = Field(
        description="Vorgeschlagene Archiv-Kategorie fuer die Ablage"
    )


# Mapping von alter Archiv-Struktur (~/Downloads/Archiv/) auf neue
LEGACY_TO_NEW_KATEGORIE = {
    "01 Arbeitgeber_Arbeitsamt": ArchivKategorie.ARBEIT,
    "02 Bundeswehr": ArchivKategorie.BUNDESWEHR,
    "03 Rechnungen": ArchivKategorie.RECHNUNGEN,
    "04 Versicherungen": ArchivKategorie.VERSICHERUNGEN,
    "05 Bildung": ArchivKategorie.BILDUNG,
    "06 Arzt": ArchivKategorie.GESUNDHEIT,
    "07 Verträge": ArchivKategorie.VERTRAEGE,
    "08 Urkunden": ArchivKategorie.URKUNDEN,
    "09 Rente_Steuer": None,  # muss gesplittet werden
    "10 Auto": ArchivKategorie.AUTO,
    "11 Finanzen": ArchivKategorie.FINANZEN,
    "12 Uni": ArchivKategorie.UNI,
    "13 Betreuung": ArchivKategorie.BETREUUNG,
    "14 Wohnung": ArchivKategorie.WOHNUNG,
    "15 Sonstiges": ArchivKategorie.SONSTIGES,
}

# Unterordner in "09 Rente_Steuer" die zu Rente gehoeren
RENTE_SUBFOLDERS = {
    "🏦 Rentenbescheide",
    "📣 Meldungen_Rentenversicherung",
    "📬 Schriftverkehr_Rentenversicherung",
    "🧾 Nachweise_Beitragszeiten",
    "🪪 Sozialversicherungsnachweis",
}

# Unterordner in "09 Rente_Steuer" die zu Steuer gehoeren
STEUER_SUBFOLDERS = {
    "📝 Steuererklaerungen",
    "🧮 WISO_ELSTER_Exports",
    "🧾 Steuerbescheid",
    "📎 Belege",
    "💶 Lohnabrechnungen",
}

# Archiv-Basis-Pfade
ARCHIV_VOLUME = "/Volumes/Archiv/ARCIV"
ARCHIV_LEGACY = "/Users/maxim/Downloads/Archiv"
ZWISCHEN_ABLAGE = "/Volumes/Zwischen_Ablage/Antwortsvorschlaegen"


if __name__ == "__main__":
    import json
    schema = DocIntakeResult.model_json_schema()
    print(json.dumps(schema, indent=2, ensure_ascii=False))
