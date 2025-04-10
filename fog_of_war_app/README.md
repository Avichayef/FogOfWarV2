# Fog of War App

A Flutter application that implements a "Fog of War" effect on OpenStreetMap. As you explore the real world, the map is revealed around you.

## Features

- OpenStreetMap integration
- Real-time location tracking
- Fog of War effect with 1-meter tiles
- User authentication
- Local SQLite database to store exposed terrain
- Secure storage for user credentials

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Android Studio or VS Code with Flutter extensions
- Android device or emulator with Google Play Services
- iOS device or simulator (for iOS testing)

### Installation

1. Clone this repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Connect your device or start an emulator
5. Run `flutter run` to start the app

## Testing the App

### Testing on a Physical Device

1. Enable developer options and USB debugging on your Android device
2. Connect your device to your computer
3. Run `flutter run` to install and launch the app
4. Allow location permissions when prompted
5. Create an account or log in
6. Start exploring! The map will be revealed as you move around

### Testing on an Emulator

Since the emulator doesn't provide real location data, you can use the following steps to simulate movement:

1. Run `flutter run` to start the app on the emulator
2. In Android Studio, open the Emulator Extended Controls (three dots at the bottom of the emulator)
3. Go to the "Location" tab
4. Set a location on the map or use the route feature to simulate movement
5. The app will respond to these location changes and reveal the map accordingly

## Technical Details

### HTTPS for Location Services

For location services to work properly, browsers and mobile operating systems require HTTPS. For local development, we're using:

- For Android: The app automatically handles HTTP/HTTPS for local development
- For iOS: The app includes the necessary permissions in Info.plist
- For web testing (if needed): You can use tools like ngrok to create a secure tunnel

### Database Structure

The app uses SQLite with the following tables:

1. `users` - Stores user credentials
   - `id`: Primary key
   - `username`: Unique username
   - `password_hash`: Hashed password

2. `exposed_terrain` - Stores the exposed map tiles
   - `id`: Primary key
   - `user_id`: Foreign key to users table
   - `latitude`: Latitude coordinate of the exposed tile
   - `longitude`: Longitude coordinate of the exposed tile

### Fog of War Implementation

The fog of war effect is implemented using:

- A custom overlay on top of the OpenStreetMap
- 1-meter grid tiles (as requested)
- Black color for unexplored areas
- Tiles are revealed based on the user's current location and a visibility radius
- Exposed tiles are stored in the database for persistence between sessions

## Troubleshooting

- **Location not updating**: Make sure location permissions are granted and location services are enabled on your device
- **Map not loading**: Check your internet connection
- **Black screen**: The app might be waiting for your first location update. Try moving around or manually setting a location in the emulator

## License

This project is for educational purposes only.
