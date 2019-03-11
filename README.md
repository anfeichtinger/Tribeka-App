# Tribeka-App

## Was beinhaltet dieses Projekt?

Dies ist das Git Repository für die **Projektarbeit/Bachlorarbeit** von **Andreas Feichtinger**, SWD17.

Inhalt dieses Projektes ist eine auf dem Framework Flutter basierende App, welche es mobilen Geräten erlaubt die Arbeitsstunden in der Firma Tribeka festzuhalten.  
**Wichtig ist hierbei, dass es zwingend notwendig ist Zugang zu einem existierenden Account zu haben.** Da keine API zur Verfügung steht wird über die App mit dem Webserver kommuniziert, wobei die Response des Servers von der App analysiert wird. Mittels Web-Scraping werden die relevanten Daten extrahiert und zu leicht bearbeitbaren Objekten umgewandelt.

**Ziel** dieses Projektes ist es, das Eintragen der Arbeitsstunden so einfach und schnell wie möglich abzuwickeln. Aus diesem Grund ist es möglich innerhalb der App selbst Vorlagen abzuspeichern, wodurch der Benutzer seine Arbeitszeiten innerhalb von wenigen Sekunden aufzeichnen kann.

## Wie kann ich das Projekt öffnen und bearbeiten?

Es wird sowohl **Android Studio** mit zwei **Plugins (Dart** und **Flutter)** benötigt, sowie das **Framework Flutter**. Alle Teile funktioneren auf Windows, Linux und Mac OSX.
Weitere Informationen zu den einzelnen Schritten sowie Schritte zur Problemlösung finden sich auf den jeweiligen Downloadseiten, welche ebenfalls verlinkt sind. 
Hier eine Schritt für Schritt Anleitung:

*  Die aktuellste Version von **Android Studio** herunterladen und installieren. Diese kann hier heruntergeladen werden: https://developer.android.com/studio

*  Die aktuellste Version von **Flutter** herunterladen und an einen beliebigen Ort entpacken. Flutter kann hier heruntergeladen werden: https://flutter.dev/docs/get-started/install

*  Flutter sollte jetzt zur **PATH Variable** hinzugefügt werden um das Framework problemlos zu nutzen. Unter Windows 10 funktioniert dies wie folgt:
    * Drücken Sie die Tastenkombination *Win + R.* 
    * Schreiben Sie in das Feld: *"sysdm.cpl"* (ohne Anführungszeichen) und drücken Sie die *Enter* Taste.
    * Den Reiter *"Erweitert"* auswählen und unten auf *"Umgebungsvariablen"* drücken.
    * Hier unter Benutzervariablen *"PATH"* auswählen und auf bearbeiten drücken.
    * Rechts auf die Schaltfläche *"Neu"* drücken und den Pfad zu Flutter einfügen: In meine Fall *"C:\Users\<Benutzername>\Documents\Android\flutter\bin"*
    * Alle Fenster mit einem Druck auf *"OK"* bestätigen und nun sollte Flutter im *"PATH"* zur Verfügung stehen.

*  Öffnen Sie nun ein neues Powershell oder CMD Fenster und führen Sie folgenden Befehl aus: `flutter doctor –android-licenses`

*  Hier müssen alle Lizenzen für die Nutzung von Android und Flutter bestätigt werden, dies geschieht mit dem Drücken der *"Y"* Taste.

*  Anschließend öffnen Sie Android Studio und führen, wenn notwendig, das First-Time Setup durch. Hierbei ist es wichtig, dass eine aktuelle Android SDK installiert wird.

*  Android Studio sollte nun als Fenster geöffnet sein. Klicken Sie hier am unteren Rand auf Konfigurieren und wählen Sie Plugins aus.

*  Hier suchen Sie dann nach dem Plugin **Flutter**, wenn Sie dieses installieren, wird gefragt ob das Plugin **Dart** ebenso installiert werden soll. Lassen Sie dies zu.

*  Anschließend, sollte Android Studio neu gestartet werden. Nach dem Neustart kann man das geklonte Git-Repository öffnen. Gehen Sie dann unter Android Studio in die Kommandozeile.

*  Geben sie hier den Befehl `flutter packages get` ein um die verwendeten Dependencies herunter zu laden. Danach sollte das Projekt vollständig funktionieren.

*  Es ist zu empfehlen vor dem Kompilieren unter Android Studio in der Kommandozeile den Befehl `flutter doctor` auszuführen um zu überprüfen, ob alles funktioniert hat. 

### Hinweis:
> *Dieses Projekt entsteht in Zusammenarbeit mit der Kaffehauskette Tribeka aus Graz sowie der FH JOANNEUM GmbH* 