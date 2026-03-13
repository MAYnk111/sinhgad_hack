import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maternal_infant_care/data/models/dashboard_card_model.dart';
import 'package:maternal_infant_care/presentation/viewmodels/repository_providers.dart';
import 'package:maternal_infant_care/presentation/viewmodels/user_provider.dart';
import 'package:maternal_infant_care/data/repositories/dashboard_preferences_repository.dart';

class CustomizableDashboard extends ConsumerStatefulWidget {
  final Widget Function(BuildContext context, DashboardCardModel card) cardBuilder;
  final Widget header;
  final Widget? floatingActionButton;

  const CustomizableDashboard({
    super.key,
    required this.cardBuilder,
    required this.header,
    this.floatingActionButton,
  });

  @override
  ConsumerState<CustomizableDashboard> createState() => _CustomizableDashboardState();
}

class _CustomizableDashboardState extends ConsumerState<CustomizableDashboard> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final preferencesRepo = ref.watch(dashboardPreferencesProvider);

    return preferencesRepo.when(
      data: (repo) {
        if (userProfile == null) return const Center(child: CircularProgressIndicator());
        
        final cards = repo.getCards(userProfile);
        final visibleCards = _isEditMode ? cards : cards.where((c) => c.isVisible).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            centerTitle: true,
            automaticallyImplyLeading: false, 
          ),
          floatingActionButton: _isEditMode
              ? FloatingActionButton.extended(
                  onPressed: () {
                    setState(() {
                      _isEditMode = false;
                    });
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                  heroTag: 'fab_dashboard_edit',
                )
              : widget.floatingActionButton,
          body: ReorderableListView(
            header: Column(
              children: [
                widget.header,
                if (!_isEditMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditMode = true;
                            });
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Customize'),
                        ),
                      ],
                    ),
                  ),
                if (_isEditMode)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Drag to reorder • Tap eye to toggle visibility',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            padding: const EdgeInsets.only(bottom: 80),
            onReorder: (oldIndex, newIndex) async {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = cards.removeAt(oldIndex);
              cards.insert(newIndex, item);
              
              // Optimistic update
              setState(() {});
              
              // Persist
              await repo.updateCardOrder(userProfile, cards);
            },
            children: [
              for (final card in visibleCards)
                _buildCardWrapper(context, card, repo, userProfile),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading dashboard: $e')),
    );
  }

  Widget _buildCardWrapper(
    BuildContext context, 
    DashboardCardModel card, 
    DashboardPreferencesRepository repo,
    UserProfileType userType,
  ) {
    return Container(
      key: ValueKey(card.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          // The actual card content
          Opacity(
            opacity: _isEditMode && !card.isVisible ? 0.5 : 1.0,
            child: widget.cardBuilder(context, card),
          ),
          
          // Edit mode overlay
          if (_isEditMode)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    card.isVisible ? Icons.visibility : Icons.visibility_off,
                    color: card.isVisible 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey,
                  ),
                  onPressed: () async {
                    await repo.toggleCardVisibility(card.id, !card.isVisible);
                    setState(() {});
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
