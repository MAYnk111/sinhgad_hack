import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maternal_infant_care/data/models/dashboard_card_model.dart';
import 'package:maternal_infant_care/presentation/widgets/customizable_dashboard.dart';
import 'package:maternal_infant_care/presentation/widgets/kick_counter_widget.dart';
import 'package:maternal_infant_care/presentation/widgets/contraction_timer_widget.dart';
import 'package:maternal_infant_care/presentation/pages/hospital_bag_page.dart';
import 'package:maternal_infant_care/presentation/pages/symptom_tracker_page.dart';
import 'package:maternal_infant_care/presentation/pages/daily_tips_page.dart';
import 'package:maternal_infant_care/presentation/viewmodels/user_meta_provider.dart';
import 'package:maternal_infant_care/presentation/widgets/start_journey_widget.dart';
import 'package:maternal_infant_care/presentation/viewmodels/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:maternal_infant_care/presentation/pages/daily_summary_page.dart';
import 'package:maternal_infant_care/presentation/pages/weekly_stats_page.dart';

// Reuse existing widgets where possible or create simple ones
class PregnantDashboardPage extends ConsumerStatefulWidget {
  const PregnantDashboardPage({super.key});

  @override
  ConsumerState<PregnantDashboardPage> createState() => _PregnantDashboardPageState();
}

class _PregnantDashboardPageState extends ConsumerState<PregnantDashboardPage> {
  Timer? _sosHoldTimer;

  @override
  void dispose() {
    _sosHoldTimer?.cancel();
    super.dispose();
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
    if (emergencyContact == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No emergency contact found for SMS.')),
      );
      return;
    }

    final position = await _getCurrentLocation();
    if (position == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to fetch location. Check GPS permissions.'),
        ),
      );
      return;
    }

    final mapsLink =
        'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    final message = 'Emergency! I need help. My location:\n$mapsLink';

    final smsUri = Uri(
      scheme: 'sms',
      path: emergencyContact,
      queryParameters: {'body': message},
    );

    final launched = await launchUrl(
      smsUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open SMS app.')),
      );
    }
  }

  void _startSosHoldTimer() {
    _sosHoldTimer?.cancel();
    _sosHoldTimer = Timer(const Duration(seconds: 2), () {
      triggerSOS();
    });
  }

  void _cancelSosHoldTimer() {
    _sosHoldTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return CustomizableDashboard(
      header: _buildHeader(context),
      cardBuilder: (context, card) {
        return _buildCardContent(context, card);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final userMeta = ref.watch(userMetaProvider);
    final username = userMeta.username;
    final displayName = (username != null && username.isNotEmpty) ? username : 'Janani'; // "Mother" in Sanskrit

    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Namaste, $displayName',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              // Ornamental decorative element if needed
              Icon(Icons.spa_outlined, color: Theme.of(context).colorScheme.secondary, size: 28),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Supporting गर्भावस्था (pregnancy) wellness and गर्भविकास (fetal development) awareness.',
            softWrap: true,
            maxLines: null,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          const StartJourneyWidget(),
        ],
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, DashboardCardModel card) {
    final theme = Theme.of(context);
    // Use theme primary/secondary colors instead of random materials
    
    switch (card.widgetType) {
      case 'pregnancy_progress':
        return const SizedBox.shrink(); 
      case 'daily_summary':
        return _buildActionCard(
          context, 
          'Daily Summary', 
          'View today\'s logs', 
          Icons.auto_stories, // Book/Scripture icon
          theme.colorScheme.primary, 
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailySummaryPage()))
        );
      case 'weekly_stats':
        return _buildActionCard(
          context, 
          'Weekly Insights', 
          'View charts & trends', 
          Icons.insights, 
          theme.colorScheme.tertiary, // Bronze/Peru
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklyStatsPage()))
        );
      case 'kick_counter':
        return const KickCounterWidget();
      case 'contraction_timer':
        return const ContractionTimerWidget();
      case 'hospital_bag':
        return _buildActionCard(
          context, 
          'Hospital Bag', 
          'Checklist for delivery day', 
          Icons.local_mall_outlined, 
          theme.colorScheme.secondary, // Gold
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalBagPage()))
        );
      case 'symptom_tracker':
        return _buildActionCard(
          context, 
          'Symptom Tracker', 
          'Log your well-being', 
          Icons.healing_outlined, 
          theme.colorScheme.primary, 
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomTrackerPage()))
        );
       case 'daily_tips':
        return _buildActionCard(
          context, 
          'Wisdom of the Day', 
          'Ancient & modern advice', 
          Icons.lightbulb_outline, 
          theme.colorScheme.secondary, 
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyTipsPage()))
        );
      default:
        return _buildActionCard(
            context, 
            card.title, 
            'Widget not implemented', 
            Icons.widgets_outlined, 
            theme.colorScheme.onSurface.withOpacity(0.5), 
            () {}
        );
    }
  }

  Widget _buildProgressCard(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final userMeta = ref.watch(userMetaProvider);
        final startDate = userMeta.startDate;
        int week = 1;
        if (startDate != null) {
          week = (DateTime.now().difference(startDate).inDays / 7).floor() + 1;
        }
        week = week.clamp(1, 40);
        double progress = (week / 40);
        
        final theme = Theme.of(context);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                const Color(0xFF5D4037), // Darker earth tone
              ],
            ),
            // Beveled corners for the container effectively
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.secondary, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.child_care, color: theme.colorScheme.secondary, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Week $week', 
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.secondary, // Gold text
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Nurturing life within. 🌟', 
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.9),
                  fontStyle: FontStyle.italic,
                )
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: progress, 
                backgroundColor: Colors.black26, 
                color: theme.colorScheme.secondary, // Gold progress bar
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color iconColor, VoidCallback onTap) {
    // Rely on the global CardTheme for the shape/color/elevation
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: InkWell(
        onTap: onTap,
        customBorder: Theme.of(context).cardTheme.shape,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // Slightly darker/lighter than card background for contrast
                  color: iconColor.withOpacity(0.1),
                  border: Border.all(color: iconColor.withOpacity(0.3)),
                  shape: BoxShape.circle, // Keep circles for icons or make them diamonds? Let's stick to circles for touch targets
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.arrow_forward_ios, 
                size: 14, 
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.7)
              ),
            ],
          ),
        ),
      ),
    );
  }
}
