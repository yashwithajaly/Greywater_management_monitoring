import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

void main() {
  runApp(GreyApp());
}

class GreyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

// ----------------- LOGIN SCREEN -----------------
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController channelController = TextEditingController();
  final TextEditingController apiKeyController = TextEditingController();

  void navigateToHome() {
    String channelId = channelController.text.trim();
    String apiKey = apiKeyController.text.trim();

    if (channelId.isNotEmpty && apiKey.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SensorDataScreen(channelId: channelId, apiKey: apiKey),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter valid credentials")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: channelController,
              decoration: InputDecoration(labelText: "Enter Channel ID"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: apiKeyController,
              decoration: InputDecoration(labelText: "Enter Read API Key"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: navigateToHome,
              child: Text("Get Details"),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- SENSOR DATA SCREEN -----------------
class SensorDataScreen extends StatefulWidget {
  final String channelId;
  final String apiKey;

  SensorDataScreen({required this.channelId, required this.apiKey});

  @override
  _SensorDataScreenState createState() => _SensorDataScreenState();
}

class _SensorDataScreenState extends State<SensorDataScreen> {
  List<double> pHValues = [];
  List<double> turbidityValues = [];
  List<double> waterLevelValues = [];
  late String apiUrl;
  bool isLoading = true;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    apiUrl = "https://api.thingspeak.com/channels/${widget.channelId}/feeds.json?results=10&api_key=${widget.apiKey}";
    initializeNotifications();
    fetchData();
    Timer.periodic(Duration(seconds: 30), (timer) => fetchData());
  }

  void initializeNotifications() {
    var androidInitialize = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(android: androidInitialize);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    var androidDetails = const AndroidNotificationDetails(
      'channelId', 'channelName',
      importance: Importance.high,
      priority: Priority.high,
    );
    var generalNotificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, generalNotificationDetails);
  }

  Future<void> fetchData() async {
    try {
      print("Fetching data from: $apiUrl");
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data.containsKey('feeds') && data['feeds'] is List) {
          List feeds = List<Map<String, dynamic>>.from(data['feeds']);

          setState(() {
            pHValues = feeds.map((e) => double.tryParse(e['field1'] ?? '0') ?? 0).toList();
            turbidityValues = feeds.map((e) => double.tryParse(e['field2'] ?? '0') ?? 0).toList();
            waterLevelValues = feeds.map((e) => double.tryParse(e['field3'] ?? '0') ?? 0).toList();
            isLoading = false;
          });

          if (pHValues.isNotEmpty && pHValues.last > 9) {
            showNotification("⚠ High pH Level!", "pH has exceeded 9! Immediate action required.");
          }
        } else {
          print("API response doesn't contain valid feeds.");
        }
      } else {
        print("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  void logout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Grey Water Monitor"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSensorCard("pH Level", pHValues, Colors.blue),
                    buildSensorCard("Turbidity", turbidityValues, Colors.green),
                    buildSensorCard("Water Level", waterLevelValues, Colors.red),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: fetchData,
                      child: Text("Refresh Data"),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 300,
                      child: SensorChart(
                        pHValues: pHValues,
                        turbidityValues: turbidityValues,
                        waterLevelValues: waterLevelValues,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildSensorCard(String title, List<double> values, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(
              values.isNotEmpty ? values.last.toStringAsFixed(2) : "No Data",
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- SENSOR CHART -----------------
class SensorChart extends StatelessWidget {
  final List<double> pHValues;
  final List<double> turbidityValues;
  final List<double> waterLevelValues;

  const SensorChart({
    Key? key,
    required this.pHValues,
    required this.turbidityValues,
    required this.waterLevelValues,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          lineChartBarData(pHValues, Colors.blue),
          lineChartBarData(turbidityValues, Colors.green),
          lineChartBarData(waterLevelValues, Colors.red),
        ],
      ),
    );
  }

  LineChartBarData lineChartBarData(List<double> values, Color color) {
    return LineChartBarData(
      spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(show: true),
    );
  }
}