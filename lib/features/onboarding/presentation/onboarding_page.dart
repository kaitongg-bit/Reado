import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  double _dailyMinutes = 30; // Default 30 mins
  static const int totalCourseMinutes = 6000;

  DateTime get _estimatedDate {
    int daysNeeded = (totalCourseMinutes / _dailyMinutes).ceil();
    return DateTime.now().add(Duration(days: daysNeeded));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'Ready to become a PM?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'How much time can you commit daily?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 48),
              
              // Dynamic Target Date Display
              Center(
                child: Column(
                  children: [
                    Text(
                      'Predicted Offer Date',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM d, yyyy').format(_estimatedDate),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),

              // The Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('15 min', style: TextStyle(color: Colors.grey[400])),
                  Text('${_dailyMinutes.toInt()} min/day', 
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('60 min', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
              Slider(
                value: _dailyMinutes,
                min: 15,
                max: 60,
                divisions: 9, // Steps of 5 mins
                label: '${_dailyMinutes.toInt()} min',
                onChanged: (value) {
                  setState(() {
                    _dailyMinutes = value;
                  });
                },
              ),
              
              const Spacer(),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Home
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start My Journey',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
