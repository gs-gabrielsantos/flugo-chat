Flugo Chat
----------
Aplicativo de chat em tempo real desenvolvido em Flutter.

O projeto já contém todas as configurações necessárias (Firebase, nome do app, ícone e assets).
Basta clonar o repositório e compilar.

--------------------------------------------------------------------
1. Requisitos
--------------------------------------------------------------------
- Flutter SDK instalado
- Android SDK (via Android Studio)
- Dispositivo Android ou emulador

Verificação do ambiente:
- flutter doctor

--------------------------------------------------------------------
2. Estrutura de pastas
--------------------------------------------------------------------

```
flugo_chat/
  android/
  assets/
  lib/
    components/
      app_messenger.dart
      chat_message.dart
      swipe_to_reply.dart
    screens/
      auth_screen.dart
      chat_screen.dart
    app_theme.dart
    main.dart
  pubspec.yaml
  README.txt
```

--------------------------------------------------------------------
3. Instalação e execução
--------------------------------------------------------------------
Instalar dependências:
- flutter pub get

Executar em modo debug:
- flutter run

--------------------------------------------------------------------
4. Geração de APK (Android)
--------------------------------------------------------------------
Preparar build:
- flutter clean
- flutter pub get

Gerar APK release:
- flutter build apk --release

Arquivo gerado:
build/app/outputs/flutter-apk/app-release.apk