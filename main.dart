import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colorful Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins', useMaterial3: true),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _cityController = TextEditingController();
  final String _apiKey = "1695da0ffb036e82360dda8d7f0deb9c";

  String _city = "";
  String _temperature = "";
  String _weatherDescription = "";
  String _humidity = "";
  String _windSpeed = "";
  String _pressure = "";
  String _visibility = "";
  String _uvIndex = "";
  String _sunrise = "";
  String _sunset = "";
  String _iconCode = "01d"; // default icon code

  bool _isLoading = false;
  List<dynamic> _forecast = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialCity();
  }

  void _fetchInitialCity() {
    _searchCityByName("Bogura");
  }

  void _searchCity() {
    final city = _cityController.text.trim();
    if (city.isEmpty) return;
    _searchCityByName(city);
  }

  void _searchCityByName(String city) async {
    setState(() => _isLoading = true);

    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$_apiKey&units=metric',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lat = data['coord']['lat'];
        final lon = data['coord']['lon'];

        setState(() {
          _city = data['name'];
          _temperature = "${data['main']['temp'].round()}°C";
          _weatherDescription = toTitleCase(data['weather'][0]['description']);
          _humidity = "${data['main']['humidity']}%";
          _windSpeed = "${data['wind']['speed']} km/h";
          _pressure = "${data['main']['pressure']} hPa";
          _visibility = "${(data['visibility'] / 1000).toStringAsFixed(1)} km";
          _sunrise = _formatTime(data['sys']['sunrise']);
          _sunset = _formatTime(data['sys']['sunset']);
          _iconCode = data['weather'][0]['icon'];
        });

        _fetchUVIndex(lat, lon);
        _fetchForecast(city);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("City not found")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(int timestamp) {
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('h:mm a').format(time);
  }

  void _fetchUVIndex(double lat, double lon) async {
    final uvUrl = Uri.parse(
      'https://api.openweathermap.org/data/2.5/uvi?appid=$_apiKey&lat=$lat&lon=$lon',
    );

    try {
      final response = await http.get(uvUrl);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _uvIndex = data['value'].toStringAsFixed(1);
        });
      }
    } catch (_) {}
  }

  void _fetchForecast(String city) async {
    final forecastUrl = Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$_apiKey&units=metric',
    );

    try {
      final response = await http.get(forecastUrl);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List forecastList = data['list'];
        final Map<String, dynamic> dailyForecast = {};

        for (var forecast in forecastList) {
          final DateTime forecastDate = DateTime.fromMillisecondsSinceEpoch(
            forecast['dt'] * 1000,
          );
          final dayKey = DateFormat('yyyy-MM-dd').format(forecastDate);

          if (!dailyForecast.containsKey(dayKey)) {
            dailyForecast[dayKey] = forecast;
          }
        }

        setState(() {
          _forecast = dailyForecast.values.take(5).toList();
        });
      }
    } catch (_) {}
  }

  String toTitleCase(String str) {
    return str
        .split(" ")
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(" ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: TextField(
                      controller: _cityController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: "Search for a city",
                        hintStyle: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: _searchCity,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else ...[
                    Center(
                      child: Image.network(
                        "http://openweathermap.org/img/wn/$_iconCode@4x.png",
                        width: 120,
                        height: 120,
                      ),
                    ),
                    Center(
                      child: Text(
                        _city,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: Text(
                        _temperature,
                        style: const TextStyle(
                          fontSize: 64,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        _weatherDescription,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _buildInfoCard("Humidity", _humidity),
                        _buildInfoCard("Wind", _windSpeed),
                        _buildInfoCard("Pressure", _pressure),
                        _buildInfoCard("Visibility", _visibility),
                        _buildInfoCard("UV Index", _uvIndex),
                        _buildInfoCard("Sunrise", _sunrise),
                        _buildInfoCard("Sunset", _sunset),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Lifestyle Tips",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildChip("Use sunscreen"),
                        _buildChip("Avoid peak UV time"),
                        _buildChip("Stay hydrated"),
                        _buildChip("Use oil-control products"),
                        _buildChip("Exercise indoors"),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "Next 5 Days",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _forecast.length,
                        itemBuilder: (context, index) {
                          final forecast = _forecast[index];
                          final forecastDate =
                              DateTime.fromMillisecondsSinceEpoch(
                                forecast['dt'] * 1000,
                              );
                          final day = DateFormat('EEE').format(forecastDate);
                          final temp = "${forecast['main']['temp'].round()}°C";
                          final iconCode = forecast['weather'][0]['icon'];
                          final iconUrl =
                              "http://openweathermap.org/img/wn/$iconCode@2x.png";

                          return ForecastCard(
                            day: day,
                            iconUrl: iconUrl,
                            temp: temp,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.white.withOpacity(0.2),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }
}

class ForecastCard extends StatelessWidget {
  final String day;
  final String iconUrl;
  final String temp;

  const ForecastCard({
    super.key,
    required this.day,
    required this.iconUrl,
    required this.temp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Image.network(iconUrl, width: 40, height: 40),
          const SizedBox(height: 10),
          Text(temp, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
