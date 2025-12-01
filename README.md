# Weinkeller

Weinkeller is a Flutter application for managing your personal wine cellar. It lets you scan wine labels or QR codes, view details about each wine, and keep track of your inventory across devices.

## Features

- **Account management** – register, log in and update your user information.
- **QR scanning** – quickly scan bottles and jump to their stored information.
- **Manual wine entry** – look up wines manually if scanning is not possible.
- **History tracking** – see previous scans and fermentation entries.
- **Configurable settings** – switch between light and dark mode and change the backend URL.

The app is built with Flutter and uses packages such as `provider`, `sqflite`, `http` and `qr_code_scanner` for state management, local storage and network access.

## Getting Started

1. Ensure you have Flutter installed. Follow the instructions at [flutter.dev](https://docs.flutter.dev/) if this is your first Flutter project.
2. Clone this repository and run `flutter pub get` to install dependencies.
3. Launch the app with `flutter run` or open it in your preferred IDE.

## Design Template

The UI design for Weinkeller is available as a Figma community file. You can view or download the template here:

<https://www.figma.com/community/file/1514245212911777342/weinkeller>

A placeholder for the design file is included under `assets/design`. Replace `assets/design/weinkeller.fig` with the downloaded Figma file if you wish to keep a local copy.
