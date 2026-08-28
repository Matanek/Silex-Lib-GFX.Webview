# Afficher une interface HTML avec GFX.WebView

`GFX.WebView` affiche du HTML, CSS et JavaScript dans la WebView fournie par le
système d’exploitation. Il n’embarque ni Chromium ni autre runtime de
navigateur dans GFX.

[Read this documentation in English.](../EN/README.md)

## Installer le package

```text
silex install GFX.WebView
```

GFX.WebView demande Silex 0.40.0 ou une version plus récente.

## Ouvrir un site incorporé

Le plugin possède la vue pendant tout le cycle de l’application :

```sx
use GFX.Application
use GFX.WebView

func main() {
    var site = WebView.Site.html(embed_text("Web/index.html"))
    site.add(WebView.Asset.css(embed_text("Web/app.css"), path:"/app.css"))
    site.add(WebView.Asset.javascript(embed_text("Web/app.js"), path:"/app.js"))

    Application()
        ..add_plugin(WebView.Plugin(site, WebView.Settings(context_menu:true)))
        ..run()
}
```

Les chemins passés à `embed_text` sont relatifs au fichier `.sx` et connus à la
compilation. Le plugin installe lui-même les capacités Window et Input, crée la
vue pendant `Schedule.startup`, vide les messages après les mises à jour puis
détruit la vue à l’arrêt. Fermer la fenêtre arrête l’application par défaut.

Un programme direct peut construire `WebView.View(window, site)` et posséder
sa fenêtre, sa boucle d’événements et son cycle de vie.

## Incorporer les assets

Les chemins logiques commencent par `/` et identifient les ressources dans le
site. `Asset.html`, `Asset.css` et `Asset.javascript` associent du texte à un
chemin et un media type. L’initialiseur général accepte les autres formats :

```sx
let manifest = WebView.Asset(
    content:embed_text("Web/manifest.json"),
    path:"/manifest.json",
    media_type:WebView.MediaType.json,
)
```

Les ressources binaires utilisent `embed_bytes` :

```sx
site.add(WebView.Asset(
    content:embed_bytes("Web/icon.png"),
    path:"/icon.png",
    media_type:WebView.MediaType.png,
))
```

`MediaType` nomme les formats indépendamment de leur extension ;
`MediaType.custom(...)` couvre un type absent de l’enum. Les références du
document sont remplacées par des data URLs autonomes. Chaque adaptateur assemble
un seul document avant de le charger ; le dossier source n’est pas distribué à
côté de l’exécutable.

## Échanger des messages

Le bridge `window.silex` est installé au document-start, avant les scripts du
HTML. JavaScript peut donc s’abonner et envoyer immédiatement :

```js
window.silex.send("action", "save")
window.silex.on("status", payload => {
    document.querySelector("#status").textContent = payload
})
```

Silex reçoit les messages puis met ses réponses en file :

```sx
for message in view.receive() {
    if message.name == "action" {
        view.send("status", "Saved " + message.payload)
    }
}
view.flush()
```

`flush` n’appelle pas la plateforme si la file est vide et envoie sinon toute
la file dans une seule évaluation JavaScript. Dans l’autre sens, JavaScript
regroupe les appels d’une microtask. L’ordre est conservé dans les deux sens.

Noms et payloads sont des chaînes ; une application peut y encoder du JSON. Le
dispatch reste asynchrone et ne participe pas aux frames de rendu.

## Gérer la vue et son apparence

`View` ne possède pas d’opération publique `update()` par frame. WebKit ou
WebView2 possède layout, JavaScript, peinture et invalidation ; `status`,
`receive` et `flush` assurent uniquement le housekeeping de plateforme.

La fenêtre et la WebView sont transparentes par défaut. `Settings.background`
et `set_background(Color)` remplacent le fond natif ; un fond CSS opaque reste
prioritaire. Le menu contextuel système est désactivé par défaut et s’active
avec `WebView.Settings(context_menu:true)`.

Créez, utilisez et détruisez fenêtre et vue sur le thread principal. `View`
retient sa `GFX.Window`, remplit son contenu et suit les redimensionnements.

Une cible optionnelle peut être inspectée avant la création :

```sx
let web_view = WebView.availability()
if !web_view.is_available() {
    if let reason = web_view.reason() { print(reason) }
    return
}
```

## Connaître les plateformes

- `macos-arm64` utilise Cocoa et WebKit par l’Interop Objective-C.
- `linux-x64` utilise GTK 3, WebKitGTK 4.1 et X11. XWayland suit ce parcours ;
  l’attachement Wayland natif n’est pas encore implémenté.
- `windows-x64` et `windows-arm64` utilisent le runtime Microsoft Edge WebView2
  installé et le loader statique propre à l’architecture. Windows ARM64 reste
  une cible reconnue et expérimentale dans la matrice Silex.

Le moteur de navigateur reste fourni par le système sélectionné. macOS et Linux
lient leurs services directement par Interop ; Windows fait de même pour Win32
et COM et ajoute seulement le loader WebView2 officiel.

Les applications complètes [EmbeddedWebView](https://github.com/Matanek/Silex-Examples/tree/main/Sources/EmbeddedWebView)
et [WebViewBridge](https://github.com/Matanek/Silex-Examples/blob/main/Sources/WebViewBridge.sx)
appartiennent à Silex-Examples. Le benchmark de messages appartient à
[Silex-Benchmarks](https://github.com/Matanek/Silex-Benchmarks/tree/main/Sources/WebViewBridgeRoundTrips).
