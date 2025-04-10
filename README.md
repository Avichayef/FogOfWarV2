# Fog of War App

This is a Flutter application that implements a "Fog of War" effect on OpenStreetMap. As you explore the real world, the map is revealed around you.

## Project Structure

- `fog_of_war_app/` - The main Flutter application

## Features

- OpenStreetMap integration for map display
- Real-time location tracking
- Fog of War effect with 1-meter tiles
- User authentication with local database
- Persistent storage of exposed terrain
- Secure storage for user credentials

## How to Run

Navigate to the `fog_of_war_app` directory and follow the instructions in the README.md file there.

## Implementation Details

### Map Integration

The app uses OpenStreetMap through the flutter_osm_plugin package, which provides a Flutter widget for displaying OpenStreetMap.

### Fog of War Effect

The fog of war effect is implemented as a custom overlay on top of the map. The overlay consists of a grid of 1-meter tiles that are initially black (unexplored). As the user moves around, tiles within a certain radius of the user's location are revealed.

### Location Tracking

The app uses the geolocator package to track the user's location in real-time. The location is updated every 1 meter of movement.

### Database

The app uses SQLite through the sqflite package to store user credentials and exposed terrain data. The database schema includes tables for users and exposed terrain.

### Security

User credentials are stored securely using the flutter_secure_storage package, which uses platform-specific secure storage (Keychain for iOS, Keystore for Android).

## Testing

The app can be tested on a physical device or an emulator. For emulator testing, you can use the location simulation features provided by Android Studio or Xcode.

## License

This project is for educational purposes only.
