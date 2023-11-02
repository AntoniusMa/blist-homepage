---
author: "Antonius Malsam"
title: "Erstellen eines online Lebenslaufs mit HUGO und json-resume"
description: "Wie man mit HUGO und json-resume eine website für den Lebenslauf erstellt"
tags: ["hugo", "css", "html"]
date: 2023-10-25
thumbnail: /blog/cv/thumbnail.png
---

Willkommen zum nächsten Teil meines Guides zum erstellen einer Website mit HUGO. Dieser Post knüpft an die Einrichtung des Projekts und die Gestaltung der Titelseite im [letzten Artikel](https://amcloudsolutions.de/en/blog/hugo-website/). Dieses mal, wird *json-resume* verwendet um eine benutzerdefinierte Lebenslaufseite zu erstellen, die im von uns zuvor bearbeiteten Theme gestylt ist. Den vollständigen Code für die Seite findet ihr wie immer auf meinem [public repository](https://github.com/AntoniusMa/blist-homepage).

# Voraussetzungen

Um mit dem folgenden Tutorial zu beginnen, benötigt ihr eine lauffähige Version einer HUGO-Website mit einem beliebigen Theme. Wenn ihr den Anweisungen im Guide Schritt für Schritt folgen möchtet, benötigt ihr ein Projekt mit dem [blist-theme](https://github.com/apvarun/blist-hugo-theme) und den Anpassungen, die ich in meinem [letzten Beitrag](https://amcloudsolutions.de/en/blog/hugo-website/) vorgenommen habe.

# Einleitung

Das [blist-theme](https://github.com/apvarun/blist-hugo-theme) eignet sich perfekt für einen Blog, allerdings benötigt ein Lebenslauf ein ganz anderes Layout als ein Blog-Artikel. Deshalb habe ich mich entschlossen, ein eigenes Template für meinen Lebenslauf zu implementieren. Dieses Template soll trotzdem das selbe Design verwenden wie die restliche Website. Die folgenden Anweisungen können in ähnlicher Weise mit jedem anderen HUGO theme durchgeführt werden, der Artikel wurde jedoch unter verwendung des [blist-theme](https://github.com/apvarun/blist-hugo-theme) erstellt. Einige der verwendeten Klassen sind spezifisch für das verwendete Theme und könnten daher in eurem eigenen Projekt nicht verfügbar sein.

Kommen wir nun zum eigentlichen Thema das Beitrags, das erstellen des Lebenslaufes. Glücklicherweise habe ich das [gruvbox-theme](https://github.com/schnerring/hugo-theme-gruvbox) als Inspiration gefunden. In diesem Artikel werde ich Zeigen wie die wesentlichen Teile der beiden verwendeten themes kombiniert werden können um eine Homepage zu erstellen, die das Blog-Format um einen Lebenslauf zur persönlichen Präsentation erweitert.

# Hinzufügen von *json

Um den Lebenslauf zu erstellen soll nicht das komplette Theme geändert werden. Daher analysieren wir zunächst das gruvbox-theme, um herauszufinden, wie wir den Lebenslauf aus diesem Theme mit unserem Theme kombinieren können. Das gruvbox Repository verwendet das [hugo-mod-json-resume](https://github.com/schnerring/hugo-mod-json-resume) HUGO Module um einen Lebenslauf darzustellen. *json-resume* ist ein open source project, das ein Format für einheitlichen Lebenslauf-Daten als JSON-Object definiert hat. Das *hugo-mod-json-resume* Module benutzt dieses Format um aus den Daten ein html layout für HUGO websites zu generieren. Daher stellt sich heraus, dass wir für unsere Zwecke nur das *hugo-mod-json-resume* Plugin benötigen.

Das HUGO CLI stellt uns Funktionen zur Verfügung, mit denen wir solche Plugins managen können. Zuerst müssen wir ein neues HUGO Module in unserem Projektverzeichnis erzeugen. Typischerweise wird dieses Module nach der Domain oder einem Subpfad der Domain benannt.

```sh
hugo mod init amcloudsolutions.de
```

Dann wird das *hugo-mod-json-resume* Module installiert indem folgende Zeilen zur `hugo.toml` hinzugefügt werden.

```toml
[module]
  [[module.imports]]
    path = "github.com/schnerring/hugo-mod-json-resume"
  [[module.mounts]]
    source = "node_modules/simple-icons/icons"
    target = "assets/simple-icons"
```

Daraufhin werden folgende Kommandozeilen Befehle ausgeführt:
```sh
hugo mod get
hugo mod npm pack
npm install
```

Zusätzlich kopieren wir das default Stylesheet aus dem [hugo-mod-json-resume repository](https://github.com/schnerring/hugo-mod-json-resume/blob/main/assets/css/json-resume.css) in unser `static/` directory. Später werden wir dieses Stylesheet verwenden um die generierten Templates von json-resume anzupassen. Als nächstes erstellen wir den Ordner `data/json_resume` und erzeugen zwei Beispiel Daten-Files nach diesem [Muster](https://github.com/schnerring/hugo-mod-json-resume/blob/main/data/json_resume/en.json). Diese Dateien bennen wir als `en.json` und `de.json` und ersetzen den Inhalt mit unserem Lebenslauf. Damit ist die Installtion von *json-resume* für unser Projekt abgeschlossen und wir können uns dem Erstellen der Lebenslauf-Seite mit dem Plugin widmen.

# Hinzufügen der Lebenslauf-Seite

Noch gibt es keinen Menüpunkt für den Lebenslauf. Um das zu ändern, fügen wir folgente Routen in der `hugo.toml` des Projekts hinzu:
```toml
    [[languages.en.menu.main]]
        name = "CV"
        url = "cv"
        weight = 2
    
    [[languages.de.menu.main]]
        name = "Lebenslauf"
        url = "cv"
        weight = 2
```

Die *weight* Property spezifiziert die Position, an der ein Menüpunkt in der Liste auftauchen soll. Die Numerierung läuft von links nach rechts (auf kleinen Bildschirmen von oben nach unten). Gebt acht darauf, die *weight* Property der anderen Menüpunkte anzupassen, um den Lebenslauf an die gewünschte Stelle zu verschieben. Jetzt erstellen wir eine `cv.md` Datei pro Sprache im jeweiligen Verzeichnis `content/<language>/`. Achtet darauf, dass die Route die im `hugo.toml` File definiert wurde mit dem Titel der Markdown Datei übereinstimmen muss. Aus diesem Grund habe ich entschieden für die Englische und die Deutsche Version die gleiche URL zu verwenden. Dadurch kann der Leser die Sprache während des Lesens wechseln ohne Umgeleitet zu werden. In die `cv.md` Dateien könnt ihr den Inhalt meines [Beispiel-CV-File](https://raw.githubusercontent.com/AntoniusMa/blist-homepage/main/content/en/cv.md) kopieren. Leider kann ich es hier nicht direkt einbinden, da das enthaltene Markdown template direkt wieder von HUGO intepretiert werden würde. An dieser Stelle werden wir eine kurze Pause einlegen, um uns anzusehen, welche neuen Feature und Konzepte wir im `cv.md` File verwenden.

Als erstes fällt auf, dass in den Metadaten ein *layout* angegeben wurde. Wie im vorherigen Blog Beitrag erklärt, generier HUGO im default fall für alle \*.md Dateien unter Verwendung des `baseof.html` Files in `layouts/default` ein Template. Da wir allerdings ein Unabhängiges Layout für unsere Lebenslauf Seite haben möchten, müssen wir ein Layout spezifizieren, das HUGO verwenden soll. Dieses Layout setzen wir auf `cv/cv`, etwas später im Artikel werde ich erklären, wie HUGO nach diesem Layout sucht.

Desweiteren verwenden wir HUGOs templating Feature innerhalb eines Markdown Files um einen sogenannten *Shortcode* aufzurufen. Shortcodes sind simple Snippets in Content Files die vorher definierte Templates generieren. Sie können entweder selbst definiert werden oder sind bereits von HUGO vorgegeben (wie zum Beispiel der *figure* Shortcode zum hinzufügen von Bildern). In diesem Beispiel ist der Shortcode `json-resume` von dem zuvor hinzugefügt Plugin definiert. Dieser Shortcode nimmt den hinten angefügten Parameter, z.B. \"work\", und konstruiert aus den hinter diesem Key im JSON-File definierten Objekt ein Template. Um das etwas genauer zu verstehen erzeugen wir vorerst das HTML Template File für unseren Lebenslauf unter `layouts/_default/cv/cv.html`. Kopiert den folgen Inhalt in die HTML Datei:

```html
<!DOCTYPE html>
<html {{ if .Site.Params.defaultThemeDark }}class="dark"{{ end }} lang="{{ .Lang }}" itemscope itemtype="http://schema.org/WebPage">
  {{- partial "head.html" . -}}
  <body class="dark:bg-gray-800 dark:text-white relative flex flex-col min-h-screen">
    {{- partial "header.html" . -}}
    <main >
        <article>
            <h1 class="text-2xl font-bold mb-2"> {{ .Title }}</h1>
            {{ .Content }}
        </article>
    </main>
    {{- partial "footer.html" . -}}
  </body>
</html>
```

Vergleicht man dieses HTML mit dem `baseof.html` so gibt es kaum einen Unterschied. Für den Moment haben wir einfach nur den Inhalt des \<main\> Tags verändert. Die Variablen *.Title* und *.Content* werden direkt vom Markdown file übernommen. Ersteres ist der in den Metadaten definierte Titel, *.Content* ist der Markdown Inhalt unter dem Metadata Bereich. Startet euren HUGO Entwicklungs-Server und schaut euch das Ergebnis an.
If you compare this to the `baseof.html` file, there is not much of a difference. For now, we've just replaced the contents of the \<main\> tag. *.Title* and *.Content* are variables injected directly from the Markdown file, the first is the title property from the metadata section, the second is the content of the file. Launch your HUGO development server and see the result.
```sh
hugo server
```

{{< figure src="/blog/cv/unstyled-cv.png" class="blog-figure-center shadow" >}}

Öffnet man die Inspection-Tools des Browsers, so sieht man, dass die Inhalte des `cv.md` Files, und die Inhalte des json-resume Data Files in der jeweiligen Sprache verwendet wurden, um HTML Elemente zu erzeugen die die gegebenen Informationen beinhalten. Der Lebenslauf schaut im Moment sehr rudimentär aus, doch bevor wir uns dem Design widmen, schauen wir uns an wie HUGO das speziell definierte Layout file für den Lebenslauf gefunden hat.

HUGO definiert einen Base Path für jede \*.md Datei. Dabei wird die relative Position des Files im Content Verzeichnis verwendet. Am Beispiel des englischsprachigen Lebenslaufs (`content/en/cv.md`), wäre dieser Base Path `layouts/en/baseof.html`. Wie erwähnt, ist das der verwendete Path, ohne *layout* Spezifikation. Warum findet HUGO also ohne *layout* Spezifikation die `layouts/_default/baseof.html` Datei? Das liegt daran, dass für den Fall, das HUGO keinen passenden Pfad finden kann, automatisch das `_default` Verzeichnis verwendet. In unserem speziellen Fall wird also für den Path-Teil `en` das `_default` Verzeichnis gewählt und hier nach einem `baseof.html` File gesucht. Spezifizieren wir nun ein layout, so kombiniert HUGO die Position des \*.md Files und das angegebene *layout* daraus ergibt sich folgender Pfad: `layouts/<languageCode>/cv/cv.html`. Durch das _default Matching wird daher `layouts/_default/cv/cv.html` verwendet. Genug der Theorie, machen wir uns daran den Lebenslauf zu stylen 🎉

# Layout und Style des Lebenslaufs

Zunächst werden wir die Datei `json-resume.css` integrieren, indem wir das Partial `head.html` verändern. Wie ihr möglicherweise noch aus dem letzten Artikel wisst, finden wir die Partials in unserem Theme repository unter `themes/blist`. Dieses mal wollen wir allerdings nicht das Theme anpassen, es handelt sich um eine applikationsspezifische Änderung daher sollte sie in unserem Homepage Repository vorgenommen werden. HUGO macht es sehr einfach, die Theme Dateien zu überschreiben. Dafür muss nur ein File mit dem selben Namen, im selben Verzeichnis erstellt werden. Um also das `themes/blist/layouts/partials/head.html` File zu überschreiben erzeugen wir eine eigene Datei unter `layouts/partials/head.html`. Wir kopieren den Inhalt und fügen das neue Stylesheet hinzu:

```html
<link rel="stylesheet" href="/json-resume.css" />
```

Wie ihr seht, wird die Lebenslauf Seite dadurch etwas umstrukturiert, sie sieht aber nach wie vor sehr unordentlich aus. Wir müssen uns selbst die Hände dreckig machen und die Templates und Styles anpassen. Dazu sehen wir uns nochmal das [gruvbox theme](https://hugo-theme-gruvbox.schnerring.net/) an.

{{< figure src="https://raw.githubusercontent.com/schnerring/hugo-theme-gruvbox/main/images/tn.png" class="blog-figure-center shadow" >}}

Wir werden versuchen, die Sidebar, die allgemeine Information zur Person beinhalten zu replizieren. Sie soll immer an der Seite des Lebenslaufs zu sehen sein, egal wie weit im Lebenslauf gescrollt wird. Dieses verhalten nennt sich *sticky*. Um ein solches Layout zu erstellen, müssen wir die `cv.html` Datei bearbeiten. Wir verwenden ein *grid* Layout, das wir mit Unterstützung der vom theme instanziierten Klassen erstellen. Ersetzt den Inhalt des \<main\> Tags durch:

```html
    <main class="grid lg:grid-cols-12 gap-5">
        <article class="lg:col-span-8">
            <h1 class="text-2xl font-bold mb-2"> {{ .Title }}</h1>
            {{ .Content }}
        </article>
        <aside class="dark:bg-gray-900 dark:prose-dark lg:col-span-4 m-0">
            <div style="top: 114px;" class="overflow-y-auto sticky z-1 basics-fixed-height">
              {{ partial "json-resume/basics.html" . }}
            </div>
        </aside>
    </main>
```

Mit diesem Template erstellen wir auf großen Bildschirmen ein *grid* mit 12 Spalten. Dazu verwenden wir die Tailwind Klassen für konditionales Design. Das heißt jede Klasse, die zum Beispiel durch das Präfix *sm:* eingeleitet wird, wird nur aktiv, wenn die Bildschirmgröße den vordefinierten Breakpoint überschreitet. Tailwind definiert solche Breakpoints um Responsive Design zu ermöglichen. Jede Tailwind Klasse kann durch ein Präfix der folgenden vordefinierten Breakpoints ergänzt werden:

-   sm (Screen size >= 640px)
-   md (Screen size >= 768px)
-   lg (Screen size >= 1024px)
-   xl (Screen size >= 1280px)
-   2xl (Screen size >= 1536px)

Auf großen Screens (lg) wird der \<article\> Tag, in dem sich der Lebenslauf befindet, 8/12 Spalten einnehmen, die Sidebar 4/12 Spalten. Auf kleineren Bildschirmen erscheint die Sidebar unter dem Inhalt des Lebenslaufs. Wir benutzen außerdem ein Partial aus dem hugo-json-resume Plugin, das ein Layout für das *Basic Information* Objekt im JSON-File generiert. Um die Sidebar erst unter dem Header beginnen zu lassen, setzen wir die *top* Property auf 114px. Dieser Wert ist Abhängig von der größe des Headers, und muss eventuell angepasst werden, wenn z.B. ein größeres Logo verwendet wird. Die *z-1* Klasse sorgt dafür, dass die Sidebar im Vordergrund angezeigt wird und nicht von anderen Komponenten verdeckt wird. Zum Abschluss verwenden wir die Tailwind Klassen *sticky* und *overflow-y-auto*. Diese sorgen dafür, dass die Position der Sidebar fixiert wird und der Inhalt der Sidebar unabhängig vom Lebenslauf gescrollt werden kann.

An dieser Stelle habe ich mich entschieden, auch die Header Bar des Themes anzupassen. Beim Scrollen durch den Lebenslauf verschwindet dieser Header. Ich möchte aus Usability Gründen meinen Lesern sowohl im Blog als auch Im Lebenslauf ermöglichen, die Navigation von jeder Scroll-Position aus zu verwendent. Daher möchte ich auch einen sticky Header. Da ich mein eigenen Fork des blist-themes verwende, werde ich das Theme direkt bearbeiten. Dazu wird das `header.html` File geöffnet und der Header folgendermaßen bearbeitet: 

```html
<header class="highlight-border-bottom sticky top-0 z-10 dark:bg-gray-800 flex justify-between md:justify-between gap-4 flex-wrap p-4 px-6 md:px-12 relative">
```

Wir haben die *mx-auto* Klasse entfernt. Diese Klasse wurde verwendet um den Inhalt des Headers mit einer automatischen Margin zu zentrieren. In unserem neuen Header werden das Logo und die Menü Items am linken, bzw. rechten Rand des Headers platziert, sodass der Header über den gesamten Viewport reicht. Würden wir das nicht tun, so würde der sticky Header in der Mitte der Seite angezeigt, während der Scroll-Text links und rechts an ihm vorbei läuft. Um die Position zu fixieren nutzen wir einmal mehr die *sticky* Klasse. Da der Header immer am Anfang der Seite stehen soll wird die *top* Property auf 0 gesetzt. Außerdem habe ich mich entschlossen Rahmenlinien zu verwenden um eine klarere Abtrennung zwischen Content Bereich, Footer und Header zu schaffen. Dazu habe ich zwei neue Klassen in `themes/blist/assets/css/styles.css` defniert:

```css
:root {
    --border-highlight-color: rgba(158, 124, 71);
    --border-base-color: rgba(158, 124, 71, 0.5);
    --border-base-width: 2px;
}

.highlight-border-top {
border-color: var(--border-highlight-color);
border-top-width: var(--border-base-width);
}

.highlight-border-bottom {
border-color: var(--border-highlight-color);
border-bottom-width: var(--border-base-width);
}
```


Zusätzlich zur *highlight-border-bottom* Klasse im Header, wird im `cv.html` File die *highlight-border-bottom* Klasse auf dem \<main\> container verwendet. Es gibt eine letzte Sache die in unserem Theme fehlt. Wenn ihr bereits die Lebenslauf Daten eingefügt habt und dadurch einen Scrollbaren Content habt, werdet ihr sehen, dass die Scrollbalken des Browsers verwendet werden. Dieses Detail bricht mit unserem Design und schaut zusätzlich nicht besonders gut aus, daher verwenden wir den folgenden CSS code in `styles.css`:

```css
  ::-webkit-scrollbar {
    width: 8px;
  }
  
  /* Thumb */
  ::-webkit-scrollbar-thumb {
    background: #4b5563; /* Color of the scrollbar thumb */
    border-radius: 5px; /* Rounded corners for the thumb */
  }
  
  /* Track background */
  ::-webkit-scrollbar-track {
    background: #111827; /* Color of the track */
  }
  
  /* Corner */
  ::-webkit-scrollbar-corner {
    background: #111827; /* Color of the scrollbar corners */
  }
```

Nun lasst uns zur Sidebar zurückkehren, es fehlt noch das spacing und styling ihres Inhalts. Sieht man sich das Layout in den Inspection-Tools im Browser an, so sieht man, dass die generierten Elemente verschiedenste Klassen verwenden. Diese Klassen können wir Anpassen um das Design zu unseren Wünschen zu verändern. Die kleinen Details der CSS Anpassung sind nicht besonders Spannend, daher könnt ihr die Klassen entweder eigenständig Anpassen, oder ihr verwendet meine Kopie der [json-resume.css](https://github.com/AntoniusMa/blist-homepage/blob/main/static/json-resume.css) Datei. Zusätzlich zur Sidebar sind hier auch schon die Styles für den Inhalt des Lebenslaufes enthalten. Um sie zu verwenden benötigt ihr die folgenden Klassen für den \<article\> Tag im `cv.html`:

```html
<article class="mx-auto lg:col-span-8 prose lg:prose-xl p-4 dark:prose-dark dark-bg-cv">
```

Ich werde auch hier nicht alles genau erläutern allerdings sollten wir auf einige Dinge bezüglich des Responsive Designs eingehen:

```css
/* screen size specifics */
@media (max-width: 639px) /* < tailwind sm */ {
    .jr__date-range,
    .jr-work__location,
    .jr-work__position,
    .jr__date-range {
        flex-basis: 100%;
    }
}

@media (min-width: 640px) /* tailwind sm */ {
    .jr__date-range,
    .jr-work__location {
        flex-grow: 1;
        text-align: right;
        flex-basis: 40%;
    }
    .jr-work__name {
        flex-basis: 60%;
    }
}

@media (min-width: 1024px) /* tailwind lg */ {
    .basics-fixed-height {
        height: calc(100vh - 114px);
    }
}
```

Der Lebenslauf soll in allen Bildschirmgrößen ansehnlich bleiben. Daher definieren wir ein Layout für große und eines für kleine Bildschirmgrößen. Auf großen Bildschirmen ist genug Platz um all unsere Text-Inhalte nebeneinander anzuzeigen. Daher können wir den Platz etwas besser Ausnutzen und positionieren die Job-Position in der selben Zeile wie das Datum, das gleiche tun wir mit der Firma und der Betriebsstätte. Wir verwenden die *flex-wrap* Property für Zeilenumbrüche. Das bedeutet, dass die verwendete umliegende Flexbox automatisch einen Zeilenumbruch einfügt, wenn ein Element nicht mehr in die selbe Zeile passt. Für eine Bildschirmweite über 640 px, unser Breakpoint für kleine Bildschirme, setzen wir die *flex-basis* von *jr-work__name* zu 60 \% und die von *jr__data-range* zu 40 \%. Dadurch zwingen wir den Firmennamen in die nächste Zeile. Durch den *flex-grow* von 1 auf *jr__date-range* und *jr-work__location*, zwingen wir diese beiden Elemente, den restlichen Platz in der Zeile einzunehmen und können dadurch das Alignment auf der Rechten Seite verwirklichen. Für alle Bildschirme deren Weite kleiner als 640px ist, setzen wir *flex-basis* zu 100 \% dadurch wird automatisch nach jedem Element ein Zeilenumbruch gesetzt. Durch dieses CSS erhalten wir die folgenden Beiden Designs für kleine und große Bildschirme:

{{< figure src="/blog/cv/CV-small-screen.png" class="blog-figure-center shadow" >}}


{{< figure src="/blog/cv/CV-big-screen.png" class="blog-figure-center shadow" >}}

Damit ist unser Lebenslauf fertig!

# Zusammenfassung

In diesem Artikel haben wir gesehen wie wir json-resume in unser HUGO Projekt integrieren können um eine eigene Seite für einen Lebenslauf zu erstellen. Wir haben HUGOs layout overwrite Feature kennengelernt und gelernt, wie wir verschieden Layout für verschiedene Teile einer Website definieren können. Wir haben ein externes Plugin zu unserem Projekt hinzugefügt und HUGOs Shortcodes verwendet um ein an verschiedene Bildschirmgrößen anpassbares Design zu erschaffen, das sich perfekt in unser bisheriges Theme integriert. Im nächsten Teil der Serie werde ich euch zeigen wie wir unsere fertige Website in einer Production Environment mit Apache deployen können und wie wir den Build Prozess durch Docker automatisieren und Plattformunabhängig gestalten können.


**HUGO Website Posts**
-    [Erstellen einer HUGO website](https://amcloudsolutions.de/de/blog/hugo-website/)
-    ⚪ [Lebenslauf für eine HUGO website](https://amcloudsolutions.de/de/blog/cv-article/)
-    [Hosting einer HUGO website](https://amcloudsolutions.de/de/blog/hosting-hugo/)