// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/heatmap_calendar.dart';
import '../../widgets/daily_checkin_widget.dart';
import '../habits/add_habit_screen.dart';
import '../profile/profile_screen.dart';
import 'habit_list_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      habitProvider.loadHabits();
      habitProvider.loadHeatmapData(DateTime.now().year);
    });
  }

  final List<Widget> _screens = [
    DashboardTab(),
    HabitListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1 ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddHabitScreen()),
          );
        },
        child: Icon(Icons.add),
      ) : null,
    );
  }
}

class DashboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          Consumer<HabitProvider>(
            builder: (context, habitProvider, child) {
              return IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  habitProvider.loadHabits();
                  habitProvider.loadHeatmapData(DateTime.now().year);
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Text(
              'Hello ${user?.displayName ?? 'there'}! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Keep building those habits!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),

            // Today's check-in
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Check-in',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    DailyCheckinWidget(),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Heatmap
            Card(
              child: Consumer<HabitProvider>(
                builder: (context, habitProvider, child) {
                  if (habitProvider.isLoading) {
                    return Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final maxCompletions = habitProvider.heatmapData.values.fold(
                      0, (max, value) => value > max ? value : max
                  ).clamp(1, double.infinity).toInt();

                  return HeatmapCalendar(
                    completionData: habitProvider.heatmapData,
                    maxCompletions: maxCompletions,
                    year: DateTime.now().year,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
