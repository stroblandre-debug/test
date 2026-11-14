# Änderungen

## 0.2 – 11. November 2026

- Zielversion auf Godot 4.7 umgestellt und mit dem offiziellen Linux-Editor 4.7 stable geprüft.
- Eigenständige Startszene ergänzt. Wenn das eigentliche Spielskript nicht geladen oder die Welt nicht initialisiert werden kann, bleibt eine Erklärung mit Wiederholen und Startbericht sichtbar.
- Einen unabhängigen Bildtest mit Farbfeldern und heller Fläche hinzugefügt. Er verwendet keine importierte Spielgrafik und keine importierte Schrift.
- Menü „Bild & Ton“ mit gespeicherter Helligkeit und Klangeinstellung ergänzt. Die Voreinstellung der Welt ist etwas heller.
- Garten als eigene Weltszene ausgegliedert; gemeinsame Kollision, Bewegung und Schleierregeln in einer Basisklasse zusammengefasst.
- Einen Katalog für bis zu 33 Welten und einen Szenenlader ergänzt. Nur die tatsächlich vorhandene Welt 1 ist begehbar.
- Spielstände auf getrennte Fortschrittsstände je Welt vorbereitet. Dateien der Version 0.1 werden eingelesen; vor der ersten Umwandlung bleibt eine genaue `.v1.bak`-Sicherung erhalten.
- Abgesprochene Weltideen einschließlich des kosmischen Horrors im Tal der erloschenen Sterne im Weltenplan festgehalten.
- Bestehende 75 Spielablaufprüfungen um 67 Prüfungen der neuen Grundlage und zwei Tests mit absichtlich beschädigtem Spielstart ergänzt.
- Vorbereiteten GitHub-Workflow auf Godot 4.7 aktualisiert. Ein Repository ist weiterhin nicht freigegeben; der Workflow wurde noch nicht auf GitHub ausgeführt.

Der auf Andrés Handy beobachtete schwarze Bildschirm konnte auf dem Linux-Testsystem weder im ursprünglichen Projekt noch in Version 0.2 nachgestellt werden. Die Ursache auf dem Gerät ist damit weiterhin offen. Die Änderungen verbessern den Start und geben Mittel zur Eingrenzung; ein behobener Gerätefehler wird nicht behauptet.
