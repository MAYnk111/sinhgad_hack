import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maternal_infant_care/core/theme/app_theme.dart';
import 'package:maternal_infant_care/core/services/centralized_translations.dart';
import 'package:maternal_infant_care/presentation/viewmodels/auth_provider.dart';
import 'package:maternal_infant_care/presentation/viewmodels/user_provider.dart';
import 'package:maternal_infant_care/presentation/viewmodels/language_provider.dart';
import 'package:maternal_infant_care/presentation/viewmodels/translation_provider.dart';
import 'package:maternal_infant_care/presentation/pages/auth_page.dart';
import 'package:maternal_infant_care/presentation/pages/settings_page.dart';
import 'package:maternal_infant_care/presentation/viewmodels/user_meta_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileType = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currentLanguageCode = ref.watch(languageProvider);
    final currentLanguage = AppLanguage.fromCode(currentLanguageCode);
    final userMeta = ref.watch(userMetaProvider);

    final userEmail = user?['email'] as String?;
    final displayName =
        (userMeta.username != null && userMeta.username!.isNotEmpty)
            ? userMeta.username!
            : (userEmail ?? 'User');
    final initials =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Tr('profile.title'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar with ornate gold border
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // User Info
            Text(
              displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (userMeta.username != null && userMeta.username!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '@${userMeta.username}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _profileLabel(profileType),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Settings Section with gold accent
            _buildSectionHeader(context, ref, 'profile.settings'),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Tr('profile.dark_mode'),
                    subtitle: const Tr('profile.adjust_appearance'),
                    secondary: Icon(
                      themeMode == ThemeMode.dark
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    value: themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Tr('profile.language'),
                    subtitle: Text(currentLanguage.nativeName),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showLanguageDialog(context, ref, currentLanguage);
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('Consultation Mode'),
                    subtitle: const Text(
                      'Enable supportive content for recovery and consultation',
                    ),
                    secondary: Icon(
                      Icons.favorite_border,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    value: userMeta.consultationMode,
                    onChanged: (value) async {
                      final previous = userMeta.consultationMode;
                      ref
                          .read(consultationModeOverrideProvider.notifier)
                          .state = value;

                      final updated = await ref
                          .read(authServiceProvider)
                          .updateUserMetadata({'consultation_mode': value});

                      if (!updated) {
                        ref
                            .read(consultationModeOverrideProvider.notifier)
                            .state = previous;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Unable to update Consultation Mode.'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  // Translation Service Status
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final serviceStatus =
                            ref.watch(translationServiceProvider);
                        return serviceStatus.when(
                          data: (available) => Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      available ? Colors.green : Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                available
                                    ? 'Translation Service Ready'
                                    : 'Translation Service Offline',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          loading: () => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Checking Translation Service...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          error: (_, __) => Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Translation Service Unavailable',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Tr('profile.settings'),
                    subtitle: const Tr('profile.account_journey_notifications'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsPage()));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // About Section
            _buildSectionHeader(context, ref, 'profile.about'),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Tr('profile.version'),
                    trailing: Text('1.0.0'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: const Tr('profile.privacy_policy'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Tr('profile.terms_of_service'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthPage()),
                      (route) => false,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                icon: const Icon(Icons.logout),
                label: const Tr('profile.log_out'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, WidgetRef ref, String keyPath) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Tr(
        keyPath,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, WidgetRef ref, AppLanguage currentLanguage) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Tr(
                        'profile.select_language',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: AppLanguage.values.length,
                    itemBuilder: (context, index) {
                      final language = AppLanguage.values[index];
                      final isSelected = language == currentLanguage;

                      return ListTile(
                        leading: Text(
                          language.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          language.nativeName,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () async {
                          final languageNotifier =
                              ref.read(languageProvider.notifier);
                          await languageNotifier.setLanguage(language);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          // Show confirmation snackbar
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Language changed to ${language.nativeName}'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Tr('profile.cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _profileLabel(UserProfileType? profileType) {
    switch (profileType) {
      case UserProfileType.pregnant:
        return 'Expecting Mother';
      case UserProfileType.tryingToConceive:
        return 'Trying to Conceive';
      case UserProfileType.toddlerParent:
        return 'Toddler Parent';
      default:
        return '';
    }
  }
}
