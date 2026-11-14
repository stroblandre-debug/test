# Schwarzen Bildschirm eingrenzen

Version 0.2 wurde mit Godot **4.7 stable** auf Linux mit dem Compatibility-Renderer gestartet und grafisch geprüft. Der auf dem Handy gemeldete Fehler wurde dabei nicht nachgestellt. Ein bestätigter Fehlergrund auf dem Gerät liegt noch nicht vor.

## Zuerst frisch importieren

1. Das neue ZIP in einen eigenen Projektordner importieren. Das bisherige Projekt kann daneben bestehen bleiben.
2. Die darin enthaltene `project.godot` öffnen.
3. **Projekt ausführen / ▶ / F5** verwenden. Die Hauptszene ist jetzt `scenes/startup.tscn` und wird automatisch geöffnet.
4. Erscheint das Titelmenü, eine Reise beginnen. Unter **Bild & Ton** lässt sich die Helligkeit der Spielwelt einstellen.

Der Startbildschirm lädt das eigentliche Spiel erst anschließend. Kann ein Spielskript oder die Welt nicht korrekt gestartet werden, bleibt eine Erklärung mit „Erneut versuchen“ und „Startbericht anzeigen“ sichtbar. Das fängt bestimmte Projektfehler ab, jedoch keinen vollständigen Ausfall der Grafikdarstellung im Godot-Editor oder Gerätetreiber.

## Wenn es weiterhin schwarz bleibt

1. Im Godot-Dateibaum `scenes/bildtest.tscn` öffnen.
2. **Aktuelle Szene ausführen / F6** starten. Diese Szene zeigt ohne Spielwelt rote, grüne und blaue Felder, ein helles Quadrat und Schrift.
3. Wenn das Bild erscheint, **Startbericht anzeigen** öffnen und ein Bildschirmfoto davon schicken.
4. Wenn auch dieser Bildtest schwarz ist, mitteilen, ob die Godot-Oberfläche selbst sichtbar bleibt. Zusätzlich die vollständige Versionsnummer aus „Über Godot“ und gegebenenfalls die erste rote Fehlermeldung schicken.

Das Projekt verwendet bereits **Compatibility / Kompatibilität**. Bei geänderter Projekteinstellung den Renderer im Editor prüfen und das Projekt neu öffnen. Die Helligkeitseinstellung hilft bei einer zu dunklen Spielwelt; sie ersetzt keine Reparatur einer vollständig ausgefallenen Anzeige.

Im Android-Editor sollte das Spielfenster für Eingaben geöffnet sein. Falls das Spiel im kleinen Bild-in-Bild-Fenster erscheint, zuerst dieses Fenster vergrößern; im Bild-in-Bild-Modus kann die Eingabe eingeschränkt sein.

## Welche Informationen helfen

- Bleibt nur das Spiel nach ▶ schwarz oder auch der Editor?
- Sind Titel, Herzen, Tasten oder der Bildtest sichtbar?
- Vollständige Godot-Version, beispielsweise `4.7.stable.official`.
- Erste rote Fehlermeldung, falls vorhanden.

Der Startbericht wird ausschließlich lokal unter `user://veil_startbericht.txt` geschrieben. Das Spiel sendet ihn nicht ins Internet.
