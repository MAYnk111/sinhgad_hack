import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maternal_infant_care/core/theme/app_theme.dart';
import 'package:maternal_infant_care/core/services/centralized_translations.dart';
import 'package:maternal_infant_care/presentation/viewmodels/repository_providers.dart';
import 'package:maternal_infant_care/presentation/viewmodels/auth_provider.dart';
import 'package:maternal_infant_care/presentation/viewmodels/user_provider.dart';
import 'package:maternal_infant_care/core/utils/notification_service.dart';
import 'package:maternal_infant_care/presentation/pages/feeding_tracking_page.dart';
import 'package:maternal_infant_care/presentation/pages/sleep_tracking_page.dart';
import 'package:maternal_infant_care/presentation/pages/growth_tracking_page.dart';
import 'package:maternal_infant_care/presentation/pages/vaccination_page.dart';
import 'package:maternal_infant_care/presentation/pages/nutrition_guidance_page.dart';
import 'package:maternal_infant_care/presentation/pages/disease_awareness_page.dart';
import 'package:maternal_infant_care/presentation/pages/reminders_page.dart';
import 'package:maternal_infant_care/presentation/pages/diaper_tracking_page.dart';
import 'package:maternal_infant_care/presentation/pages/careflow_ai_page.dart';

import 'package:maternal_infant_care/presentation/pages/profile_page.dart';
import 'package:maternal_infant_care/presentation/pages/pregnancy_setup_page.dart';
import 'package:maternal_infant_care/presentation/viewmodels/user_meta_provider.dart';
import 'package:maternal_infant_care/presentation/pages/weekly_stats_page.dart';
import 'package:maternal_infant_care/presentation/pages/daily_summary_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
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
    final pregnancyRepo = ref.watch(pregnancyRepositoryProvider);
    final feedingRepo = ref.watch(feedingRepositoryProvider);
    final sleepRepo = ref.watch(sleepRepositoryProvider);
    final diaperRepo = ref.watch(diaperRepositoryProvider);
    final profileType = ref.watch(userProfileProvider);
    final userMeta = ref.watch(userMetaProvider);
    final username = userMeta.username;

    return Scaffold(
      appBar: AppBar(
        title: const Tr('dashboard.title'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (username != null && username.isNotEmpty) ...[
                Text(
                  'Hi, $username',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  'How is your journey today?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
              ],
              _buildGreetingCard(context, pregnancyRepo),
              const SizedBox(height: 32),
              _buildSectionHeader(context, 'Daily Tracker Hub',
                  'Monitor your baby\'s essentials'),
              const SizedBox(height: 16),
              _buildTrackingGrid(context, feedingRepo, sleepRepo, diaperRepo),
              const SizedBox(height: 32),
              _buildSectionHeader(context, 'Health & Security',
                  'Medical milestones & protection'),
              const SizedBox(height: 16),
              _buildHealthSection(context),
              const SizedBox(height: 32),
              _buildSectionHeader(
                  context, 'Wisdom Center', 'Expert guidance & awareness'),
              const SizedBox(height: 16),
              _buildWisdomHub(context),
              const SizedBox(height: 32),
              _buildSectionHeader(
                  context, 'Growth & Stats', 'Visualize progress over time'),
              const SizedBox(height: 16),
              _ActionTile(
                title: 'Weekly Insights',
                subtitle: 'View charts & trends',
                icon: Icons.bar_chart,
                color: Colors.deepPurpleAccent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WeeklyStatsPage())),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      floatingActionButton: profileType == UserProfileType.pregnant
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => _startSosHoldTimer(),
                  onTapUp: (_) => _cancelSosHoldTimer(),
                  onTapCancel: _cancelSosHoldTimer,
                  child: FloatingActionButton(
                    heroTag: 'fab_sos',
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    onPressed: () {},
                    child: const Text(
                      'SOS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'fab_ai_small',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VatsalyaAiPage()),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: const Icon(Icons.auto_awesome),
                ),
              ],
            )
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VatsalyaAiPage()),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Vatsalya AI'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
    );
  }

  Widget _buildGreetingCard(BuildContext context, AsyncValue pregnancyRepo) {
    final profileType = ref.watch(userProfileProvider);
    final userMeta = ref.watch(userMetaProvider);
    final username = userMeta.username;

    if (profileType == UserProfileType.toddlerParent) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.child_care,
                      color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      username != null && username.isNotEmpty
                          ? 'Hi, $username! ❤️'
                          : 'Welcome Back! ❤️',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Your little one is growing every day. Stay on top of their needs.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return pregnancyRepo.when(
      data: (repo) {
        final pregnancy = repo.getPregnancy();
        if (pregnancy == null) return _buildNoPregnancyCard(context);

        final daysUntilDue = pregnancy.daysUntilDue;
        final progress =
            ((9 - (daysUntilDue / 30)).clamp(0.0, 9.0) / 9.0).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    username != null && username.isNotEmpty
                        ? 'Hi, $username'
                        : 'Pregnancy Journey',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  Text(
                    'Month ${pregnancy.currentMonth}',
                    style: const TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (username != null && username.isNotEmpty) ...[
                const SizedBox(height: 4),
                const Text(
                  'Your journey to motherhood',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  minHeight: 10,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$daysUntilDue days until your big day!',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildNoPregnancyCard(context),
    );
  }

  Widget _buildNoPregnancyCard(BuildContext context) {
    final userMeta = ref.watch(userMetaProvider);
    final username = userMeta.username;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.favorite, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
              username != null && username.isNotEmpty
                  ? 'Hi, $username!'
                  : 'Welcome to Vatsalya',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text('Track your journey from day one.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PregnancySetupPage()),
              );
            },
            child: const Text('Start Journey'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildTrackingGrid(
    BuildContext context,
    AsyncValue feedingRepo,
    AsyncValue sleepRepo,
    AsyncValue diaperRepo,
  ) {
    final today = DateTime.now();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: feedingRepo.when(
                data: (repo) => _HubCard(
                  title: 'Feeding',
                  subtitle: '${repo.getFeedingsByDate(today).length} sessions',
                  icon: Icons.restaurant,
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FeedingTrackingPage())),
                ),
                loading: () => const _LoadingHubCard(color: Colors.orange),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: sleepRepo.when(
                data: (repo) => _HubCard(
                  title: 'Sleep',
                  subtitle:
                      '${repo.getTotalSleepHoursByDate(today).toStringAsFixed(1)} hours',
                  icon: Icons.king_bed,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SleepTrackingPage())),
                ),
                loading: () => const _LoadingHubCard(color: Colors.indigo),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: diaperRepo.when(
                data: (repo) => _HubCard(
                  title: 'Diaper',
                  subtitle: '${repo.getDiapersByDate(today).length} changes',
                  icon: Icons.layers,
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DiaperTrackingPage())),
                ),
                loading: () => const _LoadingHubCard(color: Colors.teal),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _HubCard(
                title: 'Daily Summary',
                subtitle: 'View logs',
                icon: Icons.assignment,
                color: Colors.blueGrey,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DailySummaryPage())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthSection(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          title: 'Vaccinations',
          subtitle: 'Manage upcoming shots & records',
          icon: Icons.medical_services,
          color: Colors.redAccent,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const VaccinationPage())),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          title: 'Growth Tracker',
          subtitle: 'Weight, Height & Percentiles',
          icon: Icons.auto_graph,
          color: Colors.blue,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GrowthTrackingPage())),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          title: 'Custom Reminders',
          subtitle: 'Set medicine or routine alerts',
          icon: Icons.alarm_add,
          color: Colors.deepPurple,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RemindersPage())),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SmallActionChip(
                label: 'Test Notify',
                icon: Icons.notifications_active,
                onTap: () async {
                  await NotificationService.showNotification(
                    id: 999,
                    title: 'System Active 🚀',
                    body: 'Your notification system is working perfectly.',
                  );
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('System Active'),
                        content: const Text(
                            'The notification system has been successfully verified. You will receive timely reminders.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SmallActionChip(
                label: 'Scheduled',
                icon: Icons.event_note,
                onTap: () async {
                  final pending =
                      await NotificationService.getPendingNotifications();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Past Alarms'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: pending.isEmpty
                              ? const Text('No pending reminders at this time.')
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: pending.length,
                                  itemBuilder: (context, index) => ListTile(
                                    leading: const Icon(Icons.alarm),
                                    title: Text(pending[index].title ?? 'Alert',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(pending[index].body ?? '',
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWisdomHub(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HubCard(
            title: 'Disease Info',
            subtitle: 'Awareness & Prevention',
            icon: Icons.health_and_safety,
            color: Colors.green,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DiseaseAwarenessPage())),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _HubCard(
            title: 'Nutrition',
            subtitle: 'Feeding & Diet guides',
            icon: Icons.restaurant_menu,
            color: Colors.orange,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NutritionGuidancePage())),
          ),
        ),
      ],
    );
  }
}

class _HubCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingHubCard extends StatelessWidget {
  final Color color;
  const _LoadingHubCard({required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Container(
        height: 140,
        alignment: Alignment.center,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color:
                Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}

class _SmallActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color:
                Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
