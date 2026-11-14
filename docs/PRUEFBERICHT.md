# Prüfung von Version 0.2

Prüfumgebung: Linux, offizieller Godot-Editor **4.7.stable.official.5b4e0cb0f**, Compatibility-Renderer, Softwaregrafik Mesa/llvmpipe, logische Fenstergröße 1152 × 648. Stand: 11. November 2026.

| Bereich | Ergebnis |
| --- | --- |
| Ursprüngliches Projekt unter Godot 4.7 | Import, ursprüngliche 75 Prüfungen und Start bestanden; schwarzer Bildschirm nicht reproduziert. |
| Spielablauf in Version 0.2 | 75 vorhandene Integrationsprüfungen bestanden. |
| Neue Grundlage | 67 Prüfungen für Weltenverwaltung, Helligkeit, Startanzeige und Spielstandübernahme bestanden. |
| Tatsächlich beschädigtes Spielskript | In einer isolierten Projektkopie bleibt der Startbildschirm mit Erklärung sichtbar. |
| Nicht ladbare Startwelt | In einer isolierten Projektkopie bleibt der Startbildschirm mit Erklärung sichtbar. |
| Regulärer Projektstart | Startbildschirm lädt das vollständige Titelmenü. |
| Grafische Kontrolle | Titel, Garten mit Touchsteuerung, Schleierwelt, Dialog, Einstellungen, Bildtest und Fehleranzeige dargestellt und geprüft. |

Die Tests verwenden eigene Spielstands- und Einstellungsdateien. Die Prüfung der absichtlich beschädigten Projekte läuft in temporären Kopien. Der normale Spielstand wird dadurch nicht überschrieben.

## Offene Prüfungen

Erneute Prüfung vor dem GitHub-Upload am 14. November 2026: In der aktuellen
Linux-Umgebung steht Godot **4.6.3.stable.official.7d41c59c4** zur Verfügung.
Mit dieser Version sind Ressourcenimport, 75 Integrationsprüfungen,
67 Grundlagenprüfungen, beide Startfehler-Prüfungen und der reguläre
Projektstart erfolgreich durchgelaufen. Godot 4.7 wurde bei diesem Upload
nicht erneut geprüft.

- Reproduktion und abschließende Behebung des auf Andrés Handy beobachteten schwarzen Bildes.
- Test von Berührungseingaben, Leistung und Darstellung auf dem echten Android-Gerät.
- APK-Export, Windows-Export und tatsächlicher GitHub-Actions-Lauf.
- Weitere fertige Welten: In Version 0.2 ist weiterhin ausschließlich Welt 1 spielbar.
