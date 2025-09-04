// lib/screens/debug/connection_test_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ConnectionTestScreen extends StatefulWidget {
  @override
  _ConnectionTestScreenState createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  bool _isLoading = false;
  String _result = '';
  
  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing connection...';
    });
    
    try {
      final isConnected = await ApiService.testConnection();
      setState(() {
        _result = isConnected 
            ? '✅ Connection successful!\nBackend is running at: ${ApiService.baseUrl}'
            : '❌ Connection failed.\nMake sure backend is running at: ${ApiService.baseUrl}';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Connection error: $e\n\nAPI URL: ${ApiService.baseUrl}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _testRegister() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing registration...';
    });
    
    try {
      final result = await ApiService.register(
        'test${DateTime.now().millisecondsSinceEpoch}@example.com',
        'password123',
        'Test User'
      );
      setState(() {
        _result = '✅ Registration successful!\nToken: ${result['token']?.substring(0, 20)}...';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Registration failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connection Test'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Backend Connection Test',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Text('API Base URL: ${ApiService.baseUrl}'),
            SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: Text('Test Health Endpoint'),
            ),
            SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testRegister,
              child: Text('Test Registration'),
            ),
            SizedBox(height: 16),
            
            if (_isLoading)
              Center(child: CircularProgressIndicator()),
              
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result.isEmpty ? 'No test results yet' : _result,
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            Text(
              'Troubleshooting Tips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '• Make sure backend is running: npm run dev\n'
              '• Check if port 3000 is available\n'
              '• For Android emulator: use 10.0.2.2:3000\n'
              '• For iOS simulator: use localhost:3000\n'
              '• Check network security config on Android',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}