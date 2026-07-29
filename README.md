# guinea_roads

## Google Maps et itinéraires

La carte Android et le service web Routes utilisent deux types
d'autorisation différents. La clé déclarée dans
`android/local.properties` sert uniquement au SDK Maps Android :

```properties
MAPS_API_KEY=VOTRE_CLE_MAPS_ANDROID
```

Cette clé doit être restreinte à l'application Android
`com.example.guinea_roads`, à ses empreintes SHA et uniquement à
**Maps SDK for Android**. Le manifeste reçoit automatiquement cette valeur au
moment de la compilation.

Pour afficher le tracé routier, activez **Routes API** et la
facturation dans le même projet Google Cloud, puis lancez l'application avec
une clé dédiée au service web :

```bash
flutter run --dart-define=GOOGLE_ROUTES_API_KEY=VOTRE_CLE_ROUTES
```

En développement, copiez `config/routes.dev.example.json` vers
`config/routes.dev.json`, renseignez-y la clé régénérée, puis utilisez la
configuration **Guinea Roads (dev)** dans Android Studio ou VS Code. En ligne
de commande, l'équivalent est :

```bash
flutter run --dart-define-from-file=config/routes.dev.json
```

`config/routes.dev.json` est ignoré par Git et ne doit jamais être partagé.

Une clé Routes ne devrait pas être publiée dans une application de
production. Faites passer ces requêtes par un backend/proxy avant diffusion.
Sans clé valide, l'application affiche volontairement une ligne pointillée
approximative entre les arrêts et indique la cause du refus Google.

`android/app/google-services.json` configure Firebase. Il ne contient ni la
clé Maps Android utilisée par le manifeste ni la clé Routes. Ne le remplacez
que si l'application Android est déplacée vers un autre projet Firebase.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
