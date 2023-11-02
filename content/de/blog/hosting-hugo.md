---
author: "Antonius Malsam"
title: "Hosting einer HUGO Website mit Apache"
description: "Anleitung zum Build und Deployment einer HUGO Website mit Docker und Apache"
tags: ["docker", "HUGO", "apache", "container"]
date: 2023-10-31
thumbnail: https://miro.medium.com/v2/resize:fit:704/1*QPeS1zcQMRH_bvZgESgCIg.png
---

# Einleitung

Willkommen zum dritten und letzten Teil meiner Blogserie zum Erstellen meines Blogs mit HUGO. Nachdem ich euch in den letzten Post gezeigt habe, wie man eine Website mit HUGO und dem [blist-theme](https://github.com/apvarun/blist-hugo-theme) erstellt und wie man mit dem Plugin [hugo-mod-json-resume](https://github.com/schnerring/hugo-mod-json-resume) einen personalisierten Lebenslauf hinzufügen kann, schauen wir uns heute an, wie wir unsere Website im Internet zur  verfügung stellen können. Diesmal benötigen wir nur eine beliebige HUGO-Website als startpunkt, die Themen in diesem Post sind nicht abhängig von der Applikation selbst.

# Voraussetzungen

-    Zugang zu einem persönlichen Server mit public IP (Ubuntu 22.04.3 LTS in diesem Post verwendet)
-    Docker Installation
-    Ein Domain Name

# Build der HUGO Website

Mit einer HUGO-Website die im Entwicklungsmodus (`hugo server`) funktioniert, ist es sehr einfach einen Build zu generieren, der von einem Web Server bereitgestellt werden kann. Navigiert einfach zum Root Directory eures Projects and führt das HUGO Command aus:

```sh
hugo
```

Dieses Kommando löst einen Build aus, in dem alle dependencies, layouts, das CSS und die Scripts des Projekts verwendet werden. Das Ergebnis des Builds wird in das `{$projectRoot}/public` Verzeichnis gelegt. Etwas später werde ich euch zeigen, wie man dieses public directory mit einem Apache Web Server hosten kann. Jetzt werden wir zuerst einen Docker build definieren. Dadurch wird der Build Prozess von unserer lokalen Entwickler Maschine abstrahiert und wir können unseren Website Build auf jedem beliebigen System mit Docker Installation durchführen. Dazu erstellen wir ein `Containerfile` im root directory des Projekts und fügen den folgenden Inhalt hinzu:

```dockerfile
FROM docker.io/library/golang:1.21.3-bookworm
COPY . .
RUN apt-get update -y
RUN apt-get install wget git npm -y
RUN npm i -g postcss-cli
RUN npm i  
RUN wget https://github.com/gohugoio/hugo/releases/download/v0.115.4/hugo_extended_0.115.4_Linux-64bit.tar.gz && \
    tar -xvzf hugo_extended_0.115.4_Linux-64bit.tar.gz  && \
    chmod +x hugo && \
    mv hugo /usr/local/bin/hugo && \
    rm hugo_extended_0.115.4_Linux-64bit.tar.gz
RUN hugo
VOLUME [ "/public" ]
```

Im Gegensatz zu einem traditionellen Docker File, das ein Image erzeugt, in dem eine Applikation läuft, verwenden wir in diesem Docker Build ein Volume um das Ergebnis des Buildprozesses, den public ordner, zur Verfügung zu stellen. Im nächsten Schritt werden wir dieses Volume verwenden, um das public directory aus dem Image zu extrahieren, vorerst sehen wir uns jedoch das Containerfile an. Wir verwenden ein auf Ubuntu Bookworm basierendes Golang Image, da wir eine Go Installation für den HUGO Build benötigen. Wir kopieren den Inhalt unseres Projektverzeichnisses in den Build container, updaten die packages und installieren wget, git und npm. Dann installieren wir die npm dependencies und das postcss-cli, das für das blist-theme benötigt wird. Dann nehmen wir den Download und die Installation von HUGO vor und zuletz wird der Build ausgeführt. Zusätzlich ist es ratsam, Dateien und Verzeichnisse, die während des Builds nicht benötigt werden, aber im Projektverzeichnis liegen zu entfernen. Dazu erstellen wir eine Datei namens `.dockerignore` mit diesem Inhalt:

```.dockerignore
.gitignore
.gitmodules
build_and_deploy.sh
public
resources/_gen
node_modules
```

Jetzt können wir den Docker Build starten:
```sh
docker build -t hugo-release -f Containerfile .
```
Als nächste spezifizieren wir ein Directory in das das Resultat des Builds eingefügt werden soll:
```sh
export target_directory="/path/to/your/target"
```
Dann können wir das public Directory aus dem eben erstellten Image extrahieren:
```sh
docker run --rm hugo-release tar -cf - public | tar -xvf - -C $target_directory --strip-components=1
```

Schauen wir uns dieses Docker command genauer an. `docker run` startet das neu gebaute Image, mit dem `--rm` Flag sorgen wir dafür, dass der Container wieder entfernt wird sobald wir fertig sind. `hugo-release` ist das Tag, das wir zuvor für das Image vergeben haben. Mit `tar -cv - public` spezifieren wir den Befehl, der zum Image Start ausgeführt werden soll. Mit diesem Befehl erstellen wir ein tar File für das public directory, dass durch die angabe von `-` direkt auf den Standardoutput ausgegeben wird. Diese Ausgabe verwenden wir durch den `|` Operator sofort wieder in einem weiteren tar Befehl, der die Inhalte des erstellten Archivs in unser `$target_directory` entpackt. Mit der Option `--strip-components=1` wird das erste Directory im tar entfernt, das heißt, es wird nicht der public Ordner in das Zielverzeichnis kopiert, sondern der Inhalt des public Ordners. Nachdem wir jetzt einen Maschinenunabhängigen Build unserer Website haben, beschäftigen wir uns mit dem Webserver.

# Konfiguration des Webservers

## Installation Apache2 Webserver

Um unsere Website im Internet zu hosten, benötigen wir einen server, bestenfalls mit einer statischen, öffentlichen IP. In der folgenden Anleitung installieren wir einen Apache Webserver auf einem Ubuntu System und konfigurieren das Hosting für unsere Website. Ich verwende für mein Deployment einen eigenen Server, den ich mir bei einem Provider gemietet habe. Solltet auch ihr erst kürzlich den Zugriff zum Server erhalten haben, so habt ihr vermutlich einen Username und ein Passwort für eine SSH Verbindung erhalten. Ich empfehle, die Authentifizierungsmethode zu einem persönlichen SSH Key zu ändern. Daraufhin kann die Passwort authentifizierung abgeschaltet werden. Wie genau man das macht, könnt ihr in vielen Online Tutorials nach lesen, auch tools wie ChatGPT werden euch bei diesem standard Vorgehen helfen können. Die Verbindung zu eurem Server auf diese Weise zu sichern ist wesentlich besser, da so nur der Besitzer eures persönlichen Private Keys Zugriff zum Server erhalten kann. Außerdem empfehle ich einen neuen User mit sudo Privilegien zu erstellen, sodass nicht immer der root User verwendet wird. Das gibt euch eine weitere Sicherheitsschicht, da bei kritischen Operationen eine zusätzliche Passwort abfrage zwischengestellt ist. Dadurch ist man weniger gefährdet, aus Unachtsamkeit wichtige Daten oder Files zu bearbeiten oder zu löschen. Außerdem solltet ihr an dieser Stelle eure Domain konfiguriert haben, sodass der Domain Name zu eurer Server IP führt.

Nach dieser kurzen Einführung zum Server können wir mit dem deployment der Website weiter machen. Da wir Docker für den Build verwenden und git benötigen um an unseren Source code zu kommen, benötigt ihr diese beiden Programme auf dem Server. Als nächstes installieren wir den Apache Webserver:
```sh
sudo apt-get install apache2 apache2-doc apache2-utils
```
Danach können wir überprüfen ob der apache2 System Service läuft:
```sh
systemctl status apache2
```

Eine andere Methode um zu Überprüfen ob der Webserver läuft, ist die Eingabe der IP des servers in einen Webbrowser. Auf dieser Adresse sollte ihr jetzt die Apache2 default Seite sehen:

{{< figure src="/blog/hosting/apache-default.png" class="blog-figure-center shadow" >}}

Die default Seite werden wir jetzt deaktivieren und uns als nächstes mit der Firewall beschäftigen.
```
sudo a2dissite 000-default.conf
systemctl reload apache2
```

## Konfiguration einer Firewall

Eine Firewall soll einen Rechner vor ungewollten Verbindungen schützen, einen Server ohne Firewall öffentlich zugänglich zu machen stellt ein Sicherheitsrisiko da, daher werden wir nun ein Firewall für unseren Server aktivieren. Ubuntu besitzt eine built in Firewall, die über Kommandozeilenbefehle konfiguriert werden kann. Einige Programme, wie zum Beispiel auch Apache2, bieten vordefinierte Konfigurationen für diese Firewall. Wir können uns die Liste der installierten Applikation mit solchen vordefinierten Konfigurationen anzeigen lassen:

```sh
sudo ufw app list
# Output:
# Available applications:
#   Apache
#   Apache Full
#   Apache Secure
#   OpenSSH
```

Sobald die Firewall eingeschaltet ist, werden alle Ports, die nicht durch eine Konfiguration in der Firewall freigeschaltet sind blockiert. Wir werden *Apache Full* für unseren Webserver aktivieren. **Außerdem sollte man nicht vergessen auch OpenSSH freizugeben. Ist das nicht der Fall und die Firewall wird aktiviert, so wird potentiell die aktulle SSH Verbindung abgebrochen. Hat der Provider bis auf SSH keine Möglichkeit den Server zu kontrollieren, so hat man sich damit aus dem System ausgeschlossen.** 
```sh
sudo ufw allow 'Apache Full'
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status
```

Der `ufw status` Befehl, zeigt uns die aktuellen Firewall Regeln, nach unserer Konfiguration sollte das etwa so aussehen:
```
Status: active

To                         Action      From
--                         ------      ----
Apache Full                ALLOW       Anywhere                  
OpenSSH                    ALLOW       Anywhere                  
Apache Full (v6)           ALLOW       Anywhere (v6)             
OpenSSH (v6)               ALLOW       Anywhere (v6)  
```

## Hosting der Website

Jetzt werden wir Vorbereitungen für das Hosting unserer Website mit Apache treffen:
```sh
cd /var/www/html
sudo mkdir $your_domain_name
cd $your_domain_name
sudo mkdir public_html
sudo mkdir log
sudo mkdir backups
```

Wir navigieren zu Apaches default verzeichnis für html files und erstellen ein Verzeichnis mit unserem Domain Name (z.B. amcloudsolutions.de). In diesem Verzeichnis erstellen wir die Ordern `public_html`, `log`, and `backups`. Als nächstest gehen wir in das Konfigurationsverzeichnis von Apache und erstellen eine Konfiguration für unsere Domain.

```sh
cd /etc/apache2/sites-available/
sudo vim $your_domain_name.conf
```

In diesem File fügen wir die folgende Konfiguraton hinzu, natürlich müsst ihr meine Domain durch eure ersetzen:
```conf
<VirtualHost *:80>
  # Admin email, Server Name (domain name), and any aliases
  ServerAdmin antonius.malsam@amcloudsolutions.de
  ServerName amcloudsolutions.de
  ServerAlias www.amcloudsolutions.de

  # Index file and Document Root (where the public files are lcoated)
  DirectoryIndex index.html index.php
  DocumentRoot /var/www/html/amcloudsolutions.de/public_html

  LogLevel warn
  ErrorLog /var/www/html/amcloudsolutions.de/log/error.log
  CustomLog /var/www/html/amcloudsolutions.de/log/access.log combined
</VirtualHost>
```

Nun müssen wir die Website nur noch aktivieren

```sh
sudo a2ensite amcloudtech.de.conf
sudo systemctl reload apache2
```

Wenn man jetzt den konfigurierten Domain Name im Browser eingibt, so zeigt sich folgende Index Seite, die die Inhalte des *public_html* Verzeichnisses wiederspiegelt.

{{< figure src="/blog/hosting/basic-index.png" class="blog-figure-center shadow" >}}

Fügt man nun die Inhalte des zuvor mit dem HUGO Build erstellten *public* directories in das *public_html* Verzeichnis ein, so wird die Website angezeigt. Wenn ihr den Build an dieser Stelle nicht manuell auf euren Server kopieren möchtet folgt weiter dem Tutorial, wir werden diesen Vorgang in einem Script automatisieren. Vorerst werden wir allerdings unsere Verbindungen mit SSL absichern.

## SSL aktivieren

Aktuell wird unsere Seite im Browser nicht als sicher angesehen, da wir über keine SSL Verbindung verfügen. Glücklicherweise macht Apache es uns sehr einfach unsere Website mit HTTPS abzusichern. Wir lassen die benötigten Zertifikate von [Let's Encrypt](https://letsencrypt.org/de/) ausstellen. Der Apache Webserver wird durch die Anwendung *Certbot* abgesichert, das sich sowohl um die Ausstellung als auch um die Erneuerung der Zertifikate kümmert. Schaut euch folgenden Blog Post auf [DigitalOcean](https://www.digitalocean.com/community/tutorials/) an, wenn ihr mehr dazu erfahren wollt. Hier gebe ich nur einen kurzen Setup Guide.

Erst müssen wir Certbot installieren
```sh
sudo apt-get install certbot python3-certbot-apache
```

Als nächstes führen wir den folgenden Befehl aus:

```sh
sudo certbot --apache
```

Akzeptier die Konditionen und gebt eure persönliche E-Mail Adresse an, für den Rest der Interaktionen könnt ihr die default Werte verwenden und das wars, damit sind unsere Zertifikate bereit und unsere Verbindung sicher. Um nochmal Sicherzustellen, dass auch die Erneuerung der Zertifikate läuft, könnt ihr euch den dafür konfigurierten System Service ansehen:

```sh
sudo systemctl status certbot.timer
```

## Release automatisieren

Jetzt da unser Webserver läuft und wir die Website sicher über HTTPS unter Verwendung unserer Domain erreichen können, ist es an der Zeit die Inhalte der Website hinzuzufügen. Wie ich vorher bereits angemerkt habe, könnte man einfach den Inhalt des *public* Folders aus unserem vorherigen Build kopieren. Das jedoch bei jeder Änderung manuell durchzuführen ist sehr Anstrengend, speziell im Fall eines Blogs, in dem sich der Inhalt sehr häufig ändert. Daher automatisieren wir diesen Prozess mit einem Shell Script.

Das Scriipt muss unseren zuvor definierten docker build ausführen und daraufhin automatisch das *public* Directory aus dem Docker Image zum *public_html* Directory von Apache extrahieren. Das komplette Script findet ihr auf meinem [github repository](https://github.com/AntoniusMa/blist-homepage/blob/main/build_and_deploy.sh), wir werden es hier Schritt für Schritt erarbeiten. Erstellt zuerst ein File namens `build_and_deploy.sh` mit folgendem Inhalt: 

```sh
#!/bin/sh

# Default value for target_directory
target_directory="./public"
```

Hier setzen wir den Typen des scripts auf *sh* und definieren einen default Variable für das Verzeichnis in das der Build kopiert werden soll. Ein public Verzeichnis wie *public_html* bei Apache, wird auch bei vielen anderen Webservern verwendet. Da wir das Script möglichst unabhängig vom verwendeten Webserver machen möchten, soll das `$target_directory` durch ein Argument auf der Kommandozeile beim Aufruf des Scripts gesetzt werden können. Der erste Teil unseres Scripts ermöglicht das: 

```sh
while [ $# -gt 0 ]; do
    case "$1" in
        --target-directory | -t)
            shift
            target_directory="$1"
            ;;
        --help | -h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --target-directory, -t  Specify the target directory"
            echo "  --help, -h              Display this help message"
            exit 0
            ;;
        *)
            # Unknown flag
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done
```

Die *while* Schleife iteriert durch alle Kommandozeilen-Argumente, `$#` ist dabei die Anzahl der Argumente. Die `shift` Operation verschiebt die Kommandozeilen-Argumente um eine Position nach links. Ein `shift` entfernt daher das aktuell erste Argument, belegt die Variable `$1` mit dem darauf folgenden Element und verringert den Betrag von `$#` um 1. Die Schleife wird daher solange fortgeführt, bis kein Argument mehr übrig ist. Und für den Fall, dass es auf das `--target-directory` Argument stößt, wird die `target_directory` Variable überschrieben.


Als nächstes werden wir sicherstellen, dass der User des Scripts sich sicher ist, dass die alten Inhalte des `target_directory` gelöscht werden sollen. Diese Abfrage habe ich aus Sicherheitsgründen mit eingebunden. Da die Verzeichnisse von Apache schreibgeschützt sind, werden wir das Script mit root privilegien ausführen müssen. Das heißt schlimmsten Falls können durch das Script systemkritische Dateien gelöscht werden, die zusätzliche Abfrage verhinderts, dass durch eine versehentliche Falscheingabe schaden entsteht.

```sh
# Prompt the user for confirmation
printf "This will delete the content of '$target_directory'. \n do you want to proceed? (y/n): "
read response

case "$response" in
    [yY])
        echo "Proceeding..."
        ;;
    [nN])
        echo "Build aborted."
        exit 0
        ;;
    *)
        echo "Invalid input. Aborting."
        exit 1
        ;;
esac
```

Jetzt können wir den Docker Build hinzufügen:
```sh
if sudo docker build -t hugo-release -f Containerfile .; then
    # create target directory if not exist
    mkdir -p $target_directory
    # clear target directory
    rm -r $target_directory/*
    # copy build to target directory
    sudo docker run --rm hugo-release tar -cf - public | tar -xvf - -C $target_directory --strip-components=1
else
    echo "Docker build failed, aborting..."
fi
```

Bevor die alten Inhalte des `target_directory` gelöscht werden möchten wir sicherstellen, dass der Docker Build auch erfolgreich war. Ist das der Fall, so werden die Inhalte des Verzeichnisses gelöscht und das neue Resultat im `public` Directory des Images zu unserem `target_directory` kopiert. Jetzt fügen wir alle Änderungen, das Containerfile und das Script zum git Repository dazu und pushen die Änderungen. Auf unserem Server führen wir einen git clone aus und können dann mit folgendem Befehl die Website deployen:

```sh
sudo -E ./build_and_deploy.sh --target-directory /var/www/html/$your_domain_name/public_html/
```

Ab jetzt können wir durch das Containerfile und das build_and_deploy.sh Script ein Update unserer Website durch einen einfachen einzeiligen Kommandozeilenbefehl durchführen.


# Zusammenfassung

In diesem Beitrag haben wir gesehen, wie man eine HUGO-Website erstellt und bereitstellt. Wir haben einen Weg gefunden, den Build unabhängiv von unserer persönlichen Entwicklungsmaschine zu machen, indem wir Docker verwenden, und wir haben das Deployment mit einem einfachen Shell-Script automatisiert. Zudem haben wir uns mit der Konfiguration eines Apache Webservers für die Website befasst und unsere Seite mithilfe von *Let's encrypt* und *Certbot* mit SSL gesichert und unsere Seite so ins Internet gebracht. Damit ist die Anleitung zur Erstellung einer WEbsite mit HUGO abgeschlossen. Ich hoffe der Einblick in die Entwicklung von Websites mit HUGO hat euch gefallen!

**HUGO Website Posts**
-    [Erstellen einer HUGO website](https://amcloudsolutions.de/de/blog/hugo-website/)
-    [Lebenslauf für eine HUGO website](https://amcloudsolutions.de/de/blog/cv-article/)
-    ⚪ [Hosting einer HUGO website](https://amcloudsolutions.de/de/blog/hosting-hugo/)