import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maternal_infant_care/presentation/pages/resources_page.dart';
import 'package:maternal_infant_care/presentation/pages/profile_page.dart';
import 'package:maternal_infant_care/presentation/pages/reminders_page.dart';
import 'package:maternal_infant_care/presentation/viewmodels/auth_provider.dart';
import 'package:maternal_infant_care/presentation/viewmodels/user_provider.dart';
import 'package:maternal_infant_care/presentation/viewmodels/user_meta_provider.dart';
import 'package:maternal_infant_care/presentation/pages/pregnancy_setup_page.dart';
import 'package:maternal_infant_care/presentation/pages/toddler_setup_page.dart';
import 'package:maternal_infant_care/presentation/pages/trying_to_conceive_setup_page.dart';
import 'package:maternal_infant_care/core/utils/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// We'll import these when we create them, for now using placeholders/existing
import 'package:maternal_infant_care/presentation/pages/pregnant_dashboard_page.dart';
import 'package:maternal_infant_care/presentation/pages/toddler_dashboard_page.dart';
import 'package:maternal_infant_care/presentation/pages/trying_to_conceive_dashboard_page.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;
  Timer? _sosHoldTimer;
  bool _sosTriggered = false;

  @override
  void dispose() {
    _sosHoldTimer?.cancel();
    super.dispose();
  }
  
  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await NotificationService.requestPermission();
    print('DEBUG: MainNavigationShell - Notification permission granted: $granted');
  }

  Future<String?> _resolveEmergencyContact() async {
    final user = ref.read(currentUserProvider);
    final directContact = user?['phone']?.toString().trim();
    if (directContact != null && directContact.isNotEmpty) {
      return directContact;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedContact = prefs.getString('emergency_contact_phone')?.trim();
    if (savedContact == null || savedContact.isEmpty) {
      return null;
    }
    return savedContact;
  }

  Future<Position?> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> triggerSOS() async {
    final emergencyContact = await _resolveEmergencyContact();
    final position = await _getCurrentLocation();
    final mapsLink = position != null
        ? 'https://maps.google.com/?q=${position.latitude},${position.longitude}'
        : 'Location unavailable';
    final message = 'Emergency! I need help. My location:\n$mapsLink';

    final smsUri = Uri(
      scheme: 'sms',
      path: emergencyContact ?? '',
      queryParameters: {'body': message},
    );

    var launched = await launchUrl(
      smsUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      final fallback = Uri.parse(
        'sms:${emergencyContact ?? ''}?body=${Uri.encodeComponent(message)}',
      );
      launched = await launchUrl(
        fallback,
        mode: LaunchMode.externalApplication,
      );
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open SMS app.')),
      );
    } else if (launched && mounted && emergencyContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency contact not set. SMS opened without number.'),
        ),
      );
    }
  }

  void _startSosHoldTimer() {
    _sosHoldTimer?.cancel();
    _sosTriggered = false;
    _sosHoldTimer = Timer(const Duration(seconds: 2), () {
      _sosTriggered = true;
      triggerSOS();
    });
  }

  void _cancelSosHoldTimer({bool showHint = false}) {
    _sosHoldTimer?.cancel();
    if (showHint && !_sosTriggered && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Press and hold SOS for 2 seconds.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userMeta = ref.watch(userMetaProvider);
    print('DEBUG: MainNavigationShell - role: ${userMeta.role}, startDate: ${userMeta.startDate}');
    
    // Smart Onboarding Redirection
    if (userMeta.startDate == null) {
      if (userMeta.role == UserProfileType.pregnant) {
        return const PregnancySetupPage();
      } else if (userMeta.role == UserProfileType.tryingToConceive) {
        return const TryingToConceiveSetupPage();
      } else if (userMeta.role == UserProfileType.toddlerParent) {
        return const ToddlerSetupPage();
      }
    }

    // Determine the dashboard based on profile type
    Widget homePage;
    if (userMeta.role == UserProfileType.pregnant) {
      homePage = const PregnantDashboardPage();
    } else if (userMeta.role == UserProfileType.tryingToConceive) {
      homePage = const TryingToConceiveDashboardPage();
    } else {
      homePage = const ToddlerDashboardPage();
    }

    final screens = [
      homePage,
      const ResourcesPage(),
      const RemindersPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton:
          userMeta.role == UserProfileType.pregnant && _currentIndex == 0
              ? Listener(
                  onPointerDown: (_) => _startSosHoldTimer(),
                  onPointerUp: (_) => _cancelSosHoldTimer(showHint: true),
                  onPointerCancel: (_) => _cancelSosHoldTimer(),
                  child: FloatingActionButton(
                    heroTag: 'fab_shell_sos',
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    onPressed: () {
                      _cancelSosHoldTimer(showHint: true);
                    },
                    child: const Text(
                      'SOS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Resources',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm),
            label: 'Reminders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
