---
author: "Antonius Malsam"
title: "Erstellen eines Blogs mit HUGO"
description: "Eine Anleitung, wie ich meinen Blog mit Go HUGO erstellt habe."
tags: ["hugo", "css", "html"]
date: 2023-10-15
thumbnail: https://gohugo.io/featured.png
---

Dieser Artikel zeigt, wie ich mit [HUGO](https://gohugo.io/), einem Go-basierten Open-Source Generator für statische Websites meine persönliche Website und diesen blog erstellt habe.

# Einleitung

Seien wir ehrlich, es gibt tonnenweise Frameworks für die Einrichtung statischer Websites. Sie sind in hohem maße Anpasspar, meist auch ohne technischen Hintergrund relativ einfach zu verwenden und es gibt eine viel größere Community um sie. Warum braucht die Welt ein weiteres Framework und warum sollte man es verwenden? Um ehrlich zu sein, habe ich keine gute Erklärung dafür. An einem schönenen Sommertag kam ein ehemaliger Kollege ins Büro und sagte: "Hey, hast du dir mal dieses Go-Framework für statische Websites angesehen, HUGO, man kann alle Inhalte in Markdown schreiben, es ist der hammer, ich werd meine Website damit bauen" ([schaut euch seine seite an](https://schneider-its.net)).

Und das war's auch schon. Ich habe noch nicht mit WordPress gearbeitet, ich bin erfahrener Entwickler, ich kann Websites one schicke Drag-and-Drop Oberflächen erstellen und ich liebe Markdown. Das ist alles, was man braucht, um eine Website mit HUGO zu erstellen, und ich muss sagen, dass es ziemlich viel Spaß gemacht hat, also lasst uns loslegen.

# Voraussetzungen

Zunächst benötigt ihr eine Installation von HUGO und den Abhängigkeiten, folgt dazu den Anweisungen auf der [website](https://gohugo.io/installation/). Außerdem brauchen wir *git*, *npm* und natürliche eure bevorzugte IDE.

# Aufsetzen des Projekts.

Die HUGO CLI stellt uns eine Funktion zur Verfügung, mit der man ein Basisprojekt erstellen kann. Dazu navigiert ihr zu dem Verzeichnis, in dem die Homepage erstellt werden soll und erstellt sie mit
```sh
hugo new site homepage
```

Diese Funktion erstellt euch die Grundstruktur eines HUGO-Projekts. Als nächstes fügen wir dem Projekt ein Theme hinzu.

# Themes

Die HUGO-Community bietet eine große Auswahl an Themes, die man für seine Homepage verwenden kann. Ihr findet diese Themes hier: [Theme Übersicht](https://themes.gohugo.io/). Ich habe mich entschieden für das Layout und das grundlegende Design meiner Seite das [blist-theme](https://github.com/apvarun/blist-hugo-theme). Ich finde es sieht super aus bietet alle Grundlegenden funktionen die ich mir für meine Website wünsche. An dieser Stelle, vielen Dank dem Entwicklerteam das das Theme als Open-Source Projekt zur verfügung stellt. Es steht euch frei, das Original-Repository zu verwenden, da ich aber einige Elemente im Theme zu meinen Zwecken anpassen möchte, habe ich mich entschieden auf einem eigenen [Fork](https://github.com/AntoniusMa/blist-hugo-custom) zu arbeiten

Wir integrieren dieses Theme als Git-Submodule. Dazu navigiert ihr in das Root Verzeichnis und initialisiert ein git projekt.

```sh
git init
```

An dieser Stelle könnt ihr das Repository zu eurem eigenen Git-Versionskontrollsystem, zum Beispiel auf Github hinzufügen. Nun fügen wir das Submodule hinzu

```
git submodule add https://github.com/AntoniusMa/blist-hugo-custom.git themes/blist
```
Das Submodul wird in `themes/blist` geklont. Auf die Einzelheiten des Submodules werde ich Schritt für Schritt eingehen während wir unsere Website bearbeiten. Um die Installation abzuschließen, kopiert das `package.json` und das `package-lock.json` File in das Root Verzeichnis und führt folgende Befehle aus:

```sh
npm i # install npm dependencies
npm i -g postcss-cli
```

Das Blist-Theme benötigt das postcss-cli während des HUGO-Builds, daher müssen wir es global installieren. Kopiert nun den Inhalt von `themes/blist/exampleSite/config.toml`in das `hugo.toml` File und startet den HUGO Entwicklungsserver
```sh
hugo server
```

In der Default-Einstellung wird dieser Befehl unsere Seite auf [localhost:1313](http://localhost:1313) bereitstellen. Stellt sicher dass ihr das Grundlayout des Blist Theme sehen könnt. Die Bilder sollten leer sein und der Inhalt mit dem default Inhalt übereinstimmen, die Bearbeitung der Titelseite folgt als nächstes.

# Titelseite

Das blist light theme ist nur wenig Anpassbar ohne große Veränderung im Theme selbst vorzunehmen. Daher werden wir es vorest deaktivieren und eine option in der Konfiguration hinzufügen, die das Dark Theme als default setzt. Öffnet das `hugo.toml` File und fügt folgende Properties im `[params]` Objekt hinzu:

```toml
[params]
  # Enable the darkmode toggle in header
  darkModeToggle = false
  defaultThemeDark = true
```

Um die Dark Theme Option zu verwenden, müssen wir die `themes/blist/layouts/_default/baseof.html` Datei des Themes bearbeiten. In HUGO wird die Datei `baseof.html` verwendet, um das grundlegende Layout der Website zu definieren und zu gestalten, also in unserem Fall die Kopf- und Fußzeile, die Navigation und die Inhaltsbereiche. Um die Theme-Datei zu überschreiben, könnten wir unsere eigene `baseof.html` in `layouts/_default/` erstellen, aber da es sich um eine direkte Theme-Anpassung handelt, werden wir das Submodule bearbeiten. In `themes/blist/layouts/_default/baseof.html` fügen wir `{{ if .Site.Params.defaultThemeDark }}class="dark"{{ end }}` in den html-Tag ein.

```html
<html {{ if .Site.Params.defaultThemeDark }}class="dark"{{ end }} lang="{{ .Lang }}" itemscope itemtype="http://schema.org/WebPage">
```

Dies ist das erste Mal, dass wir die HUGO-Templating-Funktion mit der {{ \<Ausdruck\> }}-Syntax verwenden müssen. Hier haben wir eine Bedingung erstellt und das *.Site* Objekt verwendet, das HUGO automatisch während des Builds injiziert. Speichert die Änderungen, daraufhin wird der HUGO-Server seine Hot-Reload-Funktion verwenden, um die Seite neu zu laden. Sie sollte sich jetzt im Dark Theme befinden.

## Sprachauswahl

Da ich kein Französisch spreche, habe ich die Sprache entfernt (einfach aus der `hugo.toml` entfernen), was zu einem Problem führt, das nur auftritt, wenn genau 2 Sprachen zur Auswahl stehen. Die derzeit nicht gewählte Sprache wird in der Kopfzeile angezeigt.

Aus Usability Sich ist das irreführend, da der Klick auf die Sprache zwar diese Sprache aktiviert, die ausgewählte Sprache allerdings für den Nutzer nicht sichtbar ist. Daher werden wir die Auswahl so anpassen, dass wie im Fall von mehr als 2 Sprachen, eine Dropdown-Liste angezeigt wird. Die Kopfzeile wird in einem *partial* definiert. Partials sind Komponenten zur Kapselungen individueller Teile einer HUGO Applikation. Sie können auch an verschiedenen Stellen auf der Website wiederverwendet werden. Im File `/themes/blist/layouts/partials/header.html` l23 nehen wir folgende Änderung vor:

```html
    - {{ if ge (len .Site.Languages) 3 }}
    + {{ if ge (len .Site.Languages) 1 }}
    <li class="relative cursor-pointer">
      <span class="language-switcher flex items-center gap-2">
```

Also, all of the script tags are included in the footer partial, including the language selection logic. I've decidede to move the language selection function to its layout (the header file). Add

Außerdem werden ausnahmslos alle script tags im footer der Applikation eingebunden, auch die für die Sprachauswahl. Ich habe mich Entschieden die jeweiligen JS Funktionen an der Stelle zu definieren, wo auch das betreffende Layout definiert ist (in diesem Fall im header file). Fügt

```html
{{ if ge (len .Site.Languages) 1 }}
<script>
const languageMenuButton = document.querySelector('.language-switcher');
const languageDropdown = document.querySelector('.language-dropdown');
languageMenuButton.addEventListener('click', (evt) => {
    evt.preventDefault()
    if (languageDropdown.classList.contains('hidden')) {
    languageDropdown.classList.remove('hidden')
    languageDropdown.classList.add('flex')
    } else {
    languageDropdown.classList.add('hidden');
    languageDropdown.classList.remove('flex');
    }
})
</script>
{{ end }}
```
zum Ende der `haeder.html`, noch vor dem schließenden `</header>` Tag und entfernt das Script aus dem footer. Zuletz kümmern wir uns um ein Problem mit der Navigation beim Wechsel der Sprachen. Jedes mal wenn eine andere Sprache ausgewählt wird, führt das zu einem redirect auf die Home page der jeweiligen Sprache (`lococalhost:1313/<languageCode>`), unabhängig davon, in welchem Navigationspfad man sich gerade befindet. Ich möchte allerdings, dass meine Besucher während dem Lesen eines Blog Posts die Sprache wechseln können, ohne noch einmal nach dem Beitrag suchen zu müssen. Um das zu erreichen müssen wir die Sprachauswahl im header mit folgendem Code Snippet ergänzen.

```html
<div
class="language-dropdown absolute top-full mt-2 left-0 flex-col gap-2 bg-gray-100 dark:bg-gray-900 dark:text-white z-10 hidden">
{{ $currURL := urls.AbsURL .Permalink }}
{{ $langPrefix := urls.AbsLangURL "/" }}
{{ $trimmedURL := strings.TrimPrefix $langPrefix $currURL}}
{{ range .Site.Languages }}
<a class="px-3 py-2 hover:bg-gray-200 dark:hover:bg-gray-700" href="/{{ .Lang }}/{{ $trimmedURL }}" lang="{{ .Lang }}">{{ default .Lang .LanguageName }}</a>
{{ end }}
</div>
```

Wir benutzen die templating Funktion um die aktuelle URL zu erhalten, entfernen das Sprach Präfix und fügen das neue Präfix hinzu. Damit ist die Sprachauswahl fertig.


## Inhalt bearbeiten

Jetzt ist es Zeit unsere eigenen Inhalte zur Titelseite hinzuzufügen. Das Blist Theme benutzt zur Definition des Inhalts auf der Titelseite die Konfigurationsdatei `hugo.toml`. Zunächst nehmen wir einige Anpassungen vor. `[languages.<languageCode>.params]` wird verwendet, damit können die Parameter Sprachspezifisch überschrieben werden. Allerdings finden sich hier auch Propertis wie `logo` und `introPhoto`, die nicht Sprachabhängig sein sollten. Daher entfernen wir sie aus den Sprachspezifischen parametern und fügen sie unter `[params]` hinzu. Um eigene Bilder zu verwenden, müssen sie in das `$projectRoot/static/` Verzeichnis gelegt werden und der Pfad muss dementsprechend angepasst werden.

```toml
[params]
    introPhoto = "/profile-pic.jpg"
    logo = "/logo-color.svg"
# ...
```

Als nächstes passen wir die `introTitle` und `introSubtitle` Properties für jede Sprache an und löschen die `copyright` property. Updatet das Panel für Soziale Netzwerke indem ihr das `[params.homepage.social]` Objekt im `hugo.toml` File bearbeitet. Setzt den Titel und die Description des Panels zu euren vorlieben und löscht alle sozialen Netzwerke, die ihr nicht abbilden möchtet. Zuletzt fehlt noch der Titel der website selbst, ganz oben im `hugo.toml` File. Die Seite sollte nun etwa so aussehen:

{{< figure src="/blog/hugo-website/title-page-result.png" class="blog-figure-center shadow" >}}

For now, we're done with the front page layout, you might want to consider resizing your logo in `header.html`. Now let us see how we can add a post to our blog.
Für den Moment sind wir mit dem Layout der Titelseite fertig. Eventuell empfiehlt es sich noch, die Größe des Logos über die `header.html` Datei anzupassen. Jetzt werden wir den ersten Beitrag zu unserem Blog hinzufügen.


# Erstellen des ersten Beitrags

Um den ersten Beitrag zu erstellen, erzeugt die Verzeichnisse `content/de/blog` und `content/en/blog`. Erstellt jeweils ein File namens `_index.md` mit folgendem Inhalt
```md
---
author: Antonius Malsam
title: Blog
---
```

Das stellt die Übersichtsseite des Blogs dar, mehr Inhalt wird in diesem Markdown File nicht benötigt, da das Blist Theme den Rest übernimmt. Jetzt erstellen wir für die beiden Sprachen ein File für den ersten Post, zum Beispiel `hugo-website.md`. Hier ein Beispiel für den Inhalt:

```md

---
author: "Antonius Malsam"
title: "How to create a blog with HUGO"
description: "A walkthrough on how I created by blog with Go HUGO."
tags: ["hugo", "css", "html"]
date: 2023-10-15
thumbnail: https://gohugo.io/featured.png
---

This article provides a walkthrough on how to create a personal website and blog with [HUGO](https://gohugo.io/), a Go based open source static site generator. In fact, the story is about the creation of this blog.

```

We define the metadata for the blog post and give it a thumbnail image. The tags are used to group your blog posts in the tags section of the homepage. Then we add a short summary for the post and save it.
Wir definieren die Metadaten für den Blogbeitrag und geben ihm ein Thumbnail Bild. Die Tags werden verwendet, um die Blogeinträge im `Tags` teil der Applikation zu gruppieren. Dann fügen wir eine kurze Zusammenfassung für den Beitrag hinzu und speichern ihn.

{{< figure src="/blog/hugo-website/title-with-blog.png" class="blog-figure-center shadow" >}}

Nach dem Aktualisieren (dnekt dran den Browser Cache zu löschen) sehen wir unseren ersten Blog beitrag auf dem Titelbildschirm.

# Zusammenfassung

Das ist das Ende meines ersten Beitrags über die Entstehung dieses Blogs. Ich habe mich für HUGO entschieden, um etwas Neues auszuprobieren – etwas, das perfekt zu meinen Fähigkeiten und Erfahrungen passt und mir erlaubt, Inhalte mit Leichtigkeit in Markdown zu erstellen. Genau das ist das Schöne an HUGO: Es ermöglicht einem, die gesamte Webentwicklungskompetenz anzuwenden und bietet gleichzeitig eine erstaunlich einfache Möglichkeit, ein Projekt zu starten. Und das beste ist, dass man aus Hunderten von verfügbaren Themes wählen kann, und alle zu 100 % anpassbar durch HTML, JS und CSS sind. Als Entwickler war es für mich ein wahres Vergnügen, meine Website mit HUGO zu gestalten. Ich kann es daher uneingeschränkt jedem empfehlen, der bereits ein gewisses Verständnis für Webentwicklung mitbringt.

Schaut euch auch die nächsten Beiträge zum erstellen einer HUGO website an:
**HUGO Website Posts**
-    ⚪ [Erstellen einer HUGO website](https://amcloudsolutions.de/de/blog/hugo-website/)
-    [Lebenslauf für eine HUGO website](https://amcloudsolutions.de/de/blog/cv-article/)
-    [Hosting einer HUGO website](https://amcloudsolutions.de/de/blog/hosting-hugo/)