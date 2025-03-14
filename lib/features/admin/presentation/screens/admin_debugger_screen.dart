// filepath: /Users/hashi/Desktop/projects/RealState/rsapp/lib/features/admin/presentation/screens/admin_debugger_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/admin_utils.dart';
import '../../../../core/utils/debug_logger.dart';
import 'package:flutter/foundation.dart';

/// A debug screen for admin users to diagnose and fix permission issues
/// This screen is only accessible in debug mode
class AdminDebuggerScreen extends StatefulWidget {
  const AdminDebuggerScreen({Key? key}) : super(key: key);

  @override
  State<AdminDebuggerScreen> createState() => _AdminDebuggerScreenState();
}

class _AdminDebuggerScreenState extends State<AdminDebuggerScreen> {
  bool _isLoading = false;
  bool _isAdmin = false;
  Map<String, dynamic>? _diagnostics;
  List<String>? _recommendations;
  List<String>? _appliedFixes;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminStatus = await AdminUtils.isCurrentUserAdmin();

      setState(() {
        _isAdmin = adminStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _runDiagnostics({bool attemptFix = false}) async {
    setState(() {
      _isLoading = true;
      _diagnostics = null;
      _recommendations = null;
      _appliedFixes = null;
      _errorMessage = null;
    });

    try {
      final result =
          await AdminUtils.enhancedAdminDebugger(attemptFix: attemptFix);

      setState(() {
        _diagnostics = result;
        _recommendations = List<String>.from(result['recommendations'] ?? []);
        _appliedFixes = List<String>.from(result['appliedFixes'] ?? []);
        _isLoading = false;
      });

      // Re-check admin status after diagnostics
      _checkAdminStatus();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      DebugLogger.error('Error in admin debugger', e);
    }
  }

  Future<void> _forceAddAsAdmin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AdminUtils.forceAddCurrentUserAsAdmin();

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully added as admin!'),
            backgroundColor: Colors.green,
          ),
        );

        // Re-check admin status and run diagnostics
        await _checkAdminStatus();
        await _runDiagnostics();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add as admin. Check logs for details.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoCard(String title, dynamic value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                color: value.toString().contains('true')
                    ? Colors.green
                    : (value.toString().contains('false') ? Colors.red : null),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsSection() {
    if (_diagnostics == null) {
      return const SizedBox.shrink();
    }

    final sections = <Widget>[
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Diagnostics Results',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];

    // Key diagnostic information
    final keyInfo = {
      'Admin Status': _diagnostics!['isAdmin'] ?? false,
      'Debug Mode': _diagnostics!['isDebugMode'] ?? false,
      'User ID': _diagnostics!['uid'] ?? 'Not available',
      'Email': _diagnostics!['email'] ?? 'Not available',
      'Admin Doc Exists': _diagnostics!['adminDocExists'] ?? false,
      'Admin Role in User Doc': _diagnostics!['isAdminInUserDoc'] ?? false,
      'Has Admin Claim': _diagnostics!['hasAdminClaim'] ?? false,
      'Can Read Admin Collection':
          _diagnostics!['canReadAdminCollection'] ?? false,
    };

    keyInfo.forEach((key, value) {
      sections.add(_buildInfoCard(key, value));
    });

    // Recommendations
    if (_recommendations != null && _recommendations!.isNotEmpty) {
      sections.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Recommendations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      for (final recommendation in _recommendations!) {
        sections.add(
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.amber[100],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(recommendation),
            ),
          ),
        );
      }
    }

    // Applied Fixes
    if (_appliedFixes != null && _appliedFixes!.isNotEmpty) {
      sections.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Applied Fixes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      for (final fix in _appliedFixes!) {
        sections.add(
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.green[100],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(fix),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only allow in debug mode
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Debugger'),
        ),
        body: const Center(
          child: Text('This screen is only available in debug mode'),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Access Debugger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _checkAdminStatus,
            tooltip: 'Refresh admin status',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: _isAdmin ? Colors.green[100] : Colors.red[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _isAdmin ? Icons.check_circle : Icons.cancel,
                            color: _isAdmin ? Colors.green : Colors.red,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isAdmin
                                      ? 'Admin Access Confirmed'
                                      : 'Not an Admin',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                if (user != null) ...[
                                  const SizedBox(height: 8),
                                  Text('User: ${user.email}'),
                                  Text('UID: ${user.uid}'),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Card(
                      color: Colors.red[100],
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Error',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_errorMessage!),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.bug_report),
                          label: const Text('Run Diagnostics'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () => _runDiagnostics(attemptFix: false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.build),
                          label: const Text('Fix Issues'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isLoading
                              ? null
                              : () => _runDiagnostics(attemptFix: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Force Add As Admin (Debug Only)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    onPressed: _isLoading ? null : _forceAddAsAdmin,
                  ),
                  const SizedBox(height: 24),
                  _buildDiagnosticsSection(),
                ],
              ),
            ),
    );
  }
}
