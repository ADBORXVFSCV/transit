// ignore: file_names
// ignore: file_names
// ignore_for_file: file_names, duplicate_ignore

import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocalDatabase {
  static const _databaseName = 'transport.db';
  static const _databaseVersion = 1;
  static const _password = 'your_secure_password_123!'; // In production, use secure key management

  static Database? _database;
  static final LocalDatabase _instance = LocalDatabase._internal();

  factory LocalDatabase() => _instance;

  LocalDatabase._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, _databaseName);

    return await openDatabase(
      dbPath,
      password: _password,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA cipher_memory_security = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Creating tables with indexes for performance
    await db.execute('''
      CREATE TABLE privet_bus (
        bus_id INTEGER PRIMARY KEY,
        created_at TEXT,
        name TEXT,
        nick_name TEXT,
        total_distance REAL,
        speed REAL,
        pictures TEXT,
        average_speed REAL,
        status INTEGER,
        owner TEXT,
        passengers REAL,
        reports TEXT,
        documents TEXT,
        last_update TEXT,
        machanics TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_bus_id ON privet_bus(bus_id)');

    await db.execute('''
      CREATE TABLE privet_bus_driver (
        created_at TEXT,
        nic INTEGER PRIMARY KEY,
        name TEXT,
        nick_name TEXT,
        age INTEGER,
        male INTEGER,
        skill TEXT,
        speed REAL,
        service_time TEXT,
        pictures TEXT,
        status INTEGER,
        documents TEXT,
        last_update TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_driver_nic ON privet_bus_driver(nic)');

    // Additional tables for app data
    await db.execute('''
      CREATE TABLE current_journeys (
        journey_id INTEGER PRIMARY KEY,
        start_time TEXT,
        end_time TEXT,
        route_id INTEGER,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_routes (
        route_id INTEGER PRIMARY KEY,
        name TEXT,
        stop_points TEXT,
        path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE my_schedules (
        schedule_id INTEGER PRIMARY KEY,
        journey_id INTEGER,
        date TEXT
      )
    ''');
  }

  // Update local database from Supabase
  Future<void> updateFromSupabase() async {
    final db = await database;
    final supabase = Supabase.instance.client;

    // Fetch data
    final buses = await supabase.from('privet_bus').select();
    final drivers = await supabase.from('privet_bus_driver').select();

    await db.transaction((txn) async {
      final batch = txn.batch();

      // Clear existing data
      await txn.delete('privet_bus');
      await txn.delete('privet_bus_driver');

      // Insert buses
      for (var bus in buses) {
        batch.insert('privet_bus', {
          'bus_id': bus['bus_id'],
          'created_at': bus['created_at'],
          'name': bus['name'],
          'nick_name': bus['nick_name'],
          'total_distance': bus['total_distance'],
          'speed': bus['speed'],
          'pictures': bus['pictures'],
          'average_speed': bus['average_speed'],
          'status': bus['status'],
          'owner': bus['owner'],
          'passengers': bus['passengers'],
          'reports': bus['reports'],
          'documents': jsonEncode(bus['documents']),
          'last_update': bus['last_update'],
          'machanics': jsonEncode(bus['machanics']),
        });
      }

      // Insert drivers
      for (var driver in drivers) {
        batch.insert('privet_bus_driver', {
          'created_at': driver['created_at'],
          'nic': driver['nic'],
          'name': driver['name'],
          'nick_name': driver['nick_name'],
          'age': driver['age'],
          'male': driver['male'] ? 1 : 0,
          'skill': jsonEncode(driver['skill']),
          'speed': driver['speed'],
          'service_time': driver['service_time'],
          'pictures': driver['pictures'],
          'status': driver['status'],
          'documents': jsonEncode(driver['documents']),
          'last_update': driver['last_update'],
        });
      }

      await batch.commit(noResult: true);
    });
  }

  // Query methods
  Future<List<Map<String, dynamic>>> getAllBuses() async {
    final db = await database;
    return await db.query('privet_bus');
  }

  Future<List<Map<String, dynamic>>> getAllDrivers() async {
    final db = await database;
    return await db.query('privet_bus_driver');
  }

  Future<List<Map<String, dynamic>>> getCurrentJourneys() async {
    final db = await database;
    return await db.query('current_journeys');
  }

  Future<List<Map<String, dynamic>>> getSavedRoutes() async {
    final db = await database;
    return await db.query('saved_routes');
  }

  Future<List<Map<String, dynamic>>> getSchedules() async {
    final db = await database;
    return await db.query('my_schedules');
  }

  // Insert methods for additional data
  Future<void> insertJourney(Map<String, dynamic> journey) async {
    final db = await database;
    await db.insert('current_journeys', journey);
  }

  Future<void> insertRoute(Map<String, dynamic> route) async {
    final db = await database;
    await db.insert('saved_routes', route);
  }

  Future<void> insertSchedule(Map<String, dynamic> schedule) async {
    final db = await database;
    await db.insert('my_schedules', schedule);
  }

  Future<void> deleteJourney(int journeyId) async {
    final db = await database;
    await db.delete('current_journeys', where: 'journey_id = ?', whereArgs: [journeyId]);
  }

  Future<void> deleteRoute(int routeId) async {
    final db = await database;
    await db.delete('saved_routes', where: 'route_id = ?', whereArgs: [routeId]);
  }

  Future<void> deleteSchedule(int scheduleId) async {
    final db = await database;
    await db.delete('my_schedules', where: 'schedule_id = ?', whereArgs: [scheduleId]);
  }

  Future<void> updateJourney(int journeyId, Map<String, dynamic> updatedJourney) async {
    final db = await database;
    await db.update('current_journeys', updatedJourney, where: 'journey_id = ?', whereArgs: [journeyId]);
}

  

}