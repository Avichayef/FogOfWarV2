import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _exposedTerrain = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check server status
      final serverStatus = await _apiService.checkServerStatus();

      if (!serverStatus) {
        throw Exception('Server is not connected');
      }

      // Get exposed terrain for the current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final exposedTerrain = await _apiService.getExposedTerrain(authProvider.currentUser!.id);

        setState(() {
          // For simplicity, we'll just show the current user in the users list
          _users = [{'id': authProvider.currentUser!.id, 'username': authProvider.currentUser!.username}];
          _exposedTerrain = exposedTerrain;
          _isLoading = false;
        });
      } else {
        setState(() {
          _users = [];
          _exposedTerrain = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current User: ${authProvider.currentUser?.username ?? 'None'} (ID: ${authProvider.currentUser?.id ?? 'None'})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Server Status: ${authProvider.isServerConnected ? 'Connected' : 'Disconnected'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: authProvider.isServerConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Users:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _users.isEmpty
                        ? const Text('No users found')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return Card(
                                child: ListTile(
                                  title: Text('Username: ${user['username']}'),
                                  subtitle: Text('ID: ${user['id']}'),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 20),
                    const Text(
                      'Exposed Terrain:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Total exposed tiles: ${_exposedTerrain.length}'),
                    const SizedBox(height: 8),
                    _exposedTerrain.isEmpty
                        ? const Text('No exposed terrain found')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _exposedTerrain.length > 10 ? 10 : _exposedTerrain.length,
                            itemBuilder: (context, index) {
                              final terrain = _exposedTerrain[index];
                              return Card(
                                child: ListTile(
                                  title: Text('Lat: ${terrain['latitude']}, Lng: ${terrain['longitude']}'),
                                  subtitle: Text('User ID: ${terrain['user_id']}'),
                                ),
                              );
                            },
                          ),
                    if (_exposedTerrain.length > 10)
                      Text('... and ${_exposedTerrain.length - 10} more tiles'),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
