import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/LocalDatabase.dart';

class UpdatingDatabaseScreen extends StatefulWidget {
  const UpdatingDatabaseScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UpdatingDatabaseScreenState createState() => _UpdatingDatabaseScreenState();
}

class _UpdatingDatabaseScreenState extends State<UpdatingDatabaseScreen> {
  String _status = 'Starting database update...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _updateDatabase();
  }

  Future<void> _updateDatabase() async {
    try {
      setState(() {
        _status = 'Fetching data from Supabase...';
        _progress = 0.3;
      });

      await LocalDatabase().updateFromSupabase();

      setState(() {
        _status = 'Updating local database...';
        _progress = 0.7;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastDatabaseUpdate', DateTime.now().millisecondsSinceEpoch);

      await Supabase.instance.client
          .from('management')
          .update({'is_changed': false})
          .eq('id', '12345678');

      setState(() {
        _status = 'Database updated successfully';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _status = 'Error updating database: $e';
        _progress = 0.0;
      });
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Updating Database'),
        backgroundColor: const Color(0xFF0A0E21),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF0A0E21),
    );
  }
}