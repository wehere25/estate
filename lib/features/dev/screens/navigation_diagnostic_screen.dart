
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/navigation_logger.dart';
import '../../../features/auth/domain/providers/auth_provider.dart';
import '../../../core/services/global_auth_service.dart';

class NavigationDiagnosticScreen extends StatefulWidget {
  const NavigationDiagnosticScreen({Key? key}) : super(key: key);

  @override
  _NavigationDiagnosticScreenState createState() => _NavigationDiagnosticScreenState();
}

class _NavigationDiagnosticScreenState extends State<NavigationDiagnosticScreen> {
  final List<Map<String, dynamic>> _logs = [];
  bool _providerAvailable = false;
  String _authStatus = 'Unknown';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _checkProviders();
    _loadLogs();
  }

  void _checkProviders() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      setState(() {
        _providerAvailable = true;
        _authStatus = 'isAuthenticated: ${authProvider.isAuthenticated}, status: ${authProvider.status}';
      });
    } catch (e) {
      setState(() {
        _providerAvailable = false;
        _error = e.toString();
      });
    }
  }

  void _loadLogs() {
    final logs = NavigationLogger.getNavigationHistory();
    setState(() {
      _logs.clear();
      _logs.addAll(logs);
    });
  }

  void _clearLogs() {
    NavigationLogger.clearNavigationHistory();
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkProviders();
              _loadLogs();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: _providerAvailable ? Colors.green[100] : Colors.red[100],
            padding: const EdgeInsets.all(8.0),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AuthProvider Available: $_providerAvailable',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _providerAvailable ? Colors.green[900] : Colors.red[900],
                  ),
                ),
                if (_providerAvailable) ...[
                  const SizedBox(height: 4),
                  Text('Status: $_authStatus'),
                ] else ...[
                  const SizedBox(height: 4),
                  Text('Error: $_error'),
                ]
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Navigation Logs (${_logs.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                // Displaying logs in reverse order (newest first)
                final log = _logs[_logs.length - 1 - index];
                return _buildLogTile(log);
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                NavigationLogger.dumpWidgetTree(context);
              },
              child: const Text('Dump Widget Tree'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLogTile(Map<String, dynamic> log) {
    final type = log['type'] as String;
    final message = log['message'] as String;
    final data = log['data'] as String?;
    final stackDepth = log['stackDepth'] as int;

    Color? color;
    IconData icon;

    if (type.contains('ERROR')) {
      color = Colors.red[100];
      icon = Icons.error_outline;
    } else if (type.contains('PUSH')) {
      color = Colors.blue[50];
      icon = Icons.arrow_forward;
    } else if (type.contains('POP')) {
      color = Colors.purple[50];
      icon = Icons.arrow_back;
    } else if (type.contains('PROVIDER_ACCESS')) {
      color = Colors.green[50];
      icon = Icons.check_circle_outline;
    } else if (type.contains('PROVIDER_ERROR')) {
      color = Colors.orange[100];
      icon = Icons.warning_amber_rounded;
    } else {
      icon = Icons.info_outline;
    }

    return Card(
      color: color,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    type,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(left: 8.0 * stackDepth),
              child: Text(message),
            ),
            if (data != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(left: 8.0 * stackDepth),
                child: Text(
                  'Data: $data',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
