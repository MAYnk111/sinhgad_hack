import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maternal_infant_care/data/models/resource_article_model.dart';
import 'package:maternal_infant_care/presentation/viewmodels/user_provider.dart';
import 'package:maternal_infant_care/presentation/widgets/resource_card.dart';
import 'package:maternal_infant_care/presentation/pages/careflow_ai_page.dart';
import 'package:maternal_infant_care/presentation/pages/disease_awareness_page.dart';
import 'package:maternal_infant_care/presentation/pages/nutrition_guidance_page.dart';
import 'package:maternal_infant_care/presentation/pages/daily_tips_page.dart';
import 'package:maternal_infant_care/presentation/pages/hospital_bag_page.dart';
import 'package:maternal_infant_care/presentation/pages/garbha_sanskar_page.dart';
import 'package:maternal_infant_care/presentation/pages/trimester_videos_page.dart';

class ResourcesPage extends ConsumerStatefulWidget {
  const ResourcesPage({super.key});

  @override
  ConsumerState<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends ConsumerState<ResourcesPage> {
  String searchQuery = '';
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Baby Care',
    'Health',
    'Nutrition',
    'Development',
    'Mother Care'
  ];

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final allArticles = _getArticles(userProfile);

    // Filter articles based on search and category
    final filteredArticles = allArticles.where((article) {
      final matchesSearch = article.title
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          article.description.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory =
          selectedCategory == 'All' || article.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Resources'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF4A4A4A),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDarkMode ? Brightness.light : Brightness.dark,
        ),
      ),
      body: Stack(
        children: [
          // Background: Parchment (scaffold background handles this in theme, but ensuring here)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),

          CustomScrollView(
            slivers: [
              // Add top padding for status bar + transparency
              SliverToBoxAdapter(
                child: SizedBox(
                    height:
                        MediaQuery.of(context).padding.top + kToolbarHeight),
              ),

              SliverToBoxAdapter(
                child: _buildSearchAndFilters(context),
              ),

              filteredArticles.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(context),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // Build rows of 2 items each
                            final startIndex = index * 2;
                            if (startIndex >= filteredArticles.length) {
                              return null;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ResourceCard(
                                        article: filteredArticles[startIndex]),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child:
                                        startIndex + 1 < filteredArticles.length
                                            ? ResourceCard(
                                                article: filteredArticles[
                                                    startIndex + 1])
                                            : const SizedBox(),
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: (filteredArticles.length / 2).ceil(),
                        ),
                      ),
                    ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VatsalyaAiPage()),
          );
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Ask AI'),
        heroTag: 'fab_resources',
        // Theme handles FAB style, but ensuring high contrast if needed
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 4,
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProfile = ref.watch(userProfileProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting / Hero Section - Aligned with Ancient Indian theme
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'संसाधन अन्वेषण\n(Explore Resources)',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
          ),
          Text(
            'विशेष लेख (Featured Articles)',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Search Bar - Ornate styling with gold borders
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.secondary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.secondary.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search for articles...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.secondary,
                  size: 24,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Explore Guides Section
          Text(
            'अध्ययन मार्गदर्शिका (Learning Guides)',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            padding: EdgeInsets.zero,
            children: [
              _CategoryCard(
                title: 'Garbha Sanskar',
                icon: Icons.spa,
                color: const Color(0xFF800000),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GarbhaSanskarPage())),
              ),
              _CategoryCard(
                title: 'Pregnancy Videos',
                icon: Icons.play_circle_fill_rounded,
                color: const Color(0xFF8B5E3C),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TrimesterVideosPage())),
              ),
              _CategoryCard(
                title: 'Medical',
                icon: Icons.medical_services_outlined,
                color: const Color(0xFFCD5C5C),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DiseaseAwarenessPage())),
              ),
              _CategoryCard(
                title: 'Nutrition',
                icon: Icons.restaurant_menu,
                color: const Color(0xFFDAA520),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NutritionGuidancePage())),
              ),
              _CategoryCard(
                title: 'Daily Tips',
                icon: Icons.lightbulb_outline,
                color: const Color(0xFFB8860B),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DailyTipsPage())),
              ),
              // Only show Labour Prep for pregnant users
              if (userProfile == UserProfileType.pregnant)
                _CategoryCard(
                  title: 'Labour Prep',
                  icon: Icons.child_friendly,
                  color: const Color(0xFF8B4513),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HospitalBagPage())),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Category Chips
          Text(
            'अनुशंसित पठन (Recommended Reads)',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.secondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedCategory = category);
                    },
                    backgroundColor: theme.cardTheme.color?.withOpacity(0.5) ??
                        (isDark
                            ? const Color(0xFF4E342E)
                            : const Color(0xFFFFF8E1)),
                    selectedColor: colorScheme.secondary.withOpacity(0.3),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.7),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? colorScheme.secondary
                            : colorScheme.secondary.withOpacity(0.3),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No resources found',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<ResourceArticleModel> _getArticles(UserProfileType? type) {
    if (type == UserProfileType.pregnant) {
      return [
        const ResourceArticleModel(
          id: 'preg1',
          title: 'Week-by-Week Guide',
          description: 'Monitor fetal गर्भविकास (development) across each trimester.',
          icon: Icons.calendar_month,
          color: Color(0xFFF48FB1), // Soft Pink
          category: 'Development',
          readingTime: '5 min',
          content: '''
# Week-by-Week Pregnancy Guide

## First Trimester (Week 1-12)
During गर्भावस्था (pregnancy), your body undergoes major changes. You might experience nausea, fatigue, and tender breasts as गर्भविकास (fetal development) begins.

*   **Week 4:** Baby is the size of a poppy seed.
*   **Week 8:** Baby is the size of a kidney bean.
*   **Week 12:** Baby is the size of a lime.

## Second Trimester (Week 13-26)
Often called the "honeymoon period," your energy may return.

*   **Week 16:** Baby is the size of an avocado.
*   **Week 20:** Halfway there! Baby is the size of a banana.
*   **Week 24:** Baby is the size of a cantaloupe.

## Third Trimester (Week 27-40)
The final stretch! You may feel more uncomfortable as baby grows.

*   **Week 28:** Baby is the size of an eggplant.
*   **Week 36:** Baby is the size of a papaya.
*   **Week 40:** Welcome baby! Size of a watermelon.
''',
        ),
        const ResourceArticleModel(
          id: 'preg2',
          title: 'Pregnancy Nutrition',
          description: 'Evidence-based nutritional support during गर्भावस्था (pregnancy).',
          icon: Icons.restaurant_menu,
          color: Color(0xFFA5D6A7), // Soft Green
          category: 'Nutrition',
          readingTime: '4 min',
          content: '''
# Nutrition During Pregnancy

Eating a balanced diet is crucial for गर्भविकास (fetal development) during गर्भावस्था (pregnancy).

## Key Nutrients
*   **Folic Acid:** Prevents birth defects. Found in leafy greens and fortified cereals.
*   **Iron:** Supports increased blood volume. Found in red meat, beans, and spinach.
*   **Calcium:** Builds strong bones. Found in dairy products and tofu.
*   **Protein:** Essential for growth. Found in lean meats, eggs, and nuts.

## Foods to Avoid
*   Raw or undercooked seafood/eggs
*   Unpasteurized dairy
*   High-mercury fish (shark, swordfish)
*   Excess caffeine
''',
        ),
        const ResourceArticleModel(
          id: 'preg3',
          title: 'Labor Preparation',
          description: 'Recognition of labor signs and preparation guidelines for delivery.',
          icon: Icons.pregnant_woman,
          color: Color(0xFFCE93D8), // Soft Purple
          category: 'Health',
          readingTime: '6 min',
          content: '''
# Preparing for Labor

Understanding labor signs during गर्भावस्था (pregnancy) helps you recognize when delivery is approaching.

## Signs of Labor
1.  **Contractions:** Regular, stronger, and closer together.
2.  **Water Breaking:** A gush or trickle of fluid.
3.  **Back Pain:** Persistent lower back ache.
4.  **Bloody Show:** Loss of mucus plug.

## Hospital Bag Checklist
*   **For Mom:** Comfortable clothes, toiletries, nursing bra, snacks, ID/insurance cards.
*   **For Baby:** Going-home outfit, car seat, blanket, diapers.
*   **For Partner:** Change of clothes, snacks, phone charger.
''',
        ),
        const ResourceArticleModel(
          id: 'preg4',
          title: 'Safe Exercises',
          description: 'Research-backed exercise guidelines during गर्भावस्था (pregnancy).',
          icon: Icons.fitness_center,
          color: Color(0xFF90CAF9), // Soft Blue
          category: 'Health',
          readingTime: '5 min',
          content: '''
# Safe Exercises During Pregnancy

Staying active during गर्भावस्था (pregnancy) is healthy for both you and your baby! It can improve mood, sleep, and even make labor easier while supporting overall ओजस् (vitality).

## Recommended Activities
*   **Walking:** The perfect low-impact exercise. Easy on the joints and can be done anywhere.
*   **Swimming:** Water supports your weight, relieving back tension and preventing overheating.
*   **Prenatal Yoga:** Great for flexibility, breathing (useful for labor!), and relaxation.
*   **Pilates:** Focuses on core strength, which helps support your growing belly.

## Trimester Specific Tips
*   **First Trimester:** Don't overdo it. Listen to your body and rest if you feel nauseous or fatigued.
*   **Second Trimester:** Avoid exercises lying flat on your back, as this can reduce blood flow.
*   **Third Trimester:** Focus on pelvic floor exercises (Kegels) and gentle movements.

## ⚠️ Stop Exercising If You Experience:
*   Dizziness or feeling faint.
*   Shortness of breath before starting exercise.
*   Chest pain or headache.
*   Vaginal bleeding or fluid leaking.
*   Calf pain or swelling.

*Always consult your doctor before starting any new exercise routine.*
''',
        ),
        const ResourceArticleModel(
          id: 'preg5',
          title: 'Mental Wellness',
          description: 'Emotional well-being and stress management during गर्भावस्था (pregnancy).',
          icon: Icons.spa,
          color: Color(0xFF80CBC4), // Soft Teal
          category: 'Mother Care',
          readingTime: '6 min',
          content: '''
# Your Mental Wellness Matters

गर्भावस्था (Pregnancy) is a time of huge transition. It's completely normal to feel a mix of excitement, anxiety, and everything in between as you navigate this journey.

## Managing Your Emotions
*   **Acknowledge Your Feelings:** Don't judge yourself for feeling anxious or overwhelmed. 
*   **Talk it Out:** Share your thoughts with your partner, a friend, or a support group.
*   **Limit "Information Overload":** Constant googling can increase anxiety. Stick to trusted sources like Vatsalya.
*   **Self-Care Rituals:** Whether it's a warm bath, reading, or listening to music, make time for things you love.

## Stress Relief Techniques
1.  **Box Breathing:** Inhale for 4s, hold for 4s, exhale for 4s, hold for 4s.
2.  **Mindfulness:** Try to focus on the present moment during daily tasks.
3.  **Journaling:** Writing down your thoughts can help clear your mind.

## When to Seek Professional Support
It's time to talk to a doctor or therapist if you experience:
*   Persistent sadness or hopelessness.
*   Constant, overwhelming worry.
*   Loss of interest in things you used to enjoy.
*   Changes in appetite or sleep patterns not related to pregnancy.

*You are not alone. Reaching out is a sign of strength.*
''',
        ),
        const ResourceArticleModel(
          id: 'preg6',
          title: 'Breastfeeding 101',
          description: 'Fundamentals of lactation and infant feeding initiation.',
          icon: Icons.baby_changing_station,
          color: Color(0xFFCE93D8), // Soft Purple
          category: 'Baby Care',
          readingTime: '7 min',
          content: '''
# Breastfeeding 101

## The Basics
Breastfeeding is a learned skill for both you and baby, essential for supporting शैशव अवस्था (early childhood) nutrition.

## Tips for Success
*   **Skin-to-Skin:** Helps bonding and milk flow.
*   **Good Latch:** Nipple should be deep in baby's mouth.
*   **Feed on Demand:** Watch for hunger cues (rooting, sucking hands).
*   **Hydration:** Drink plenty of water.

If it hurts, break suction and try again. Don't hesitate to see a lactation consultant.
''',
        ),
        const ResourceArticleModel(
          id: 'preg7',
          title: 'Postpartum Recovery',
          description: 'Physical and emotional recovery guidelines following delivery.',
          icon: Icons.healing,
          color: Color(0xFFFFCC80), // Soft Orange
          category: 'Mother Care',
          readingTime: '5 min',
          content: '''
# Postpartum Recovery

Recovery after गर्भावस्था (pregnancy) requires patience and self-care as your body heals.

## What to Expect
*   **Lochia:** Bleeding for 4-6 weeks is normal.
*   **Cramping:** Uterus shrinking back to size.
*   **Soreness:** Perineal or C-section incision pain.

## Self-Care
*   Rest as much as possible.
*   Use a peri bottle for hygiene.
*   Eat nourishing, warm meals.
*   Gentle walking when ready.
''',
        ),
      ];
    }

    if (type == UserProfileType.tryingToConceive) {
      return [
        const ResourceArticleModel(
          id: 'ttc1',
          title: 'Cycle Basics',
          description: 'Comprehensive understanding of menstrual ऋतुचक्र (cycle) phases.',
          icon: Icons.calendar_today,
          color: Color(0xFFB39DDB),
          category: 'Fertility',
          readingTime: '4 min',
          content: '''
# Understanding Your Cycle

The menstrual ऋतुचक्र (cycle) consists of four distinct phases that prepare the body for potential गर्भधारण (conception).
* **Menstrual Phase:** Bleeding days (Day 1 begins your cycle).
* **Follicular Phase:** Hormones prepare an egg to mature.
* **Ovulation:** Egg release, typically ~14 days before your next period.
* **Luteal Phase:** Progesterone rises to support implantation.

## Fertile Window
The fertile window is generally **5 days before ovulation** and **1 day after**.
Tracking cycle length helps estimate this window.
''',
        ),
        const ResourceArticleModel(
          id: 'ttc2',
          title: 'Ovulation Tracking',
          description: 'Evidence-based methods for monitoring ovulation and fertile windows.',
          icon: Icons.favorite_border,
          color: Color(0xFFF48FB1),
          category: 'Tracking',
          readingTime: '5 min',
          content: '''
# Ovulation Tracking

Tracking ovulation during your इतुचक्र (menstrual cycle) helps identify the optimal window for गर्भधारण (conception).

## Common Signs
* Increased cervical mucus (egg-white consistency)
* Mild pelvic discomfort (mittelschmerz)
* Slight rise in basal body temperature

## Helpful Tools
* **OPKs (Ovulation Predictor Kits)**
* **Basal Body Temperature Tracking**
* **Cycle Apps & Calendars**

Consistency improves accuracy.
''',
        ),
        const ResourceArticleModel(
          id: 'ttc3',
          title: 'Lifestyle for Fertility',
          description: 'Holistic wellness practices supporting गर्भधारण (conception).',
          icon: Icons.spa_outlined,
          color: Color(0xFFA5D6A7),
          category: 'Wellness',
          readingTime: '4 min',
          content: '''
# Lifestyle Support for Fertility

Supporting गर्भधारण (conception) through lifestyle includes maintaining संतुलन (balance) in daily routines: with whole grains, fruits, vegetables, and healthy fats.
* Aim for 7–9 hours of sleep to support hormone balance.
* Manage stress with gentle movement, meditation, or journaling.

If you have concerns, consult a healthcare professional.
''',
        ),
      ];
    } else {
      return [
        const ResourceArticleModel(
          id: 'tod1',
          title: 'Developmental Milestones',
          description: 'Tracking शैशव अवस्था (early childhood) developmental progression (1-3 years).',
          icon: Icons.accessibility,
          color: Color(0xFFFFCC80), // Soft Orange
          category: 'Development',
          readingTime: '5 min',
          content: '''
# Toddler Milestones

During शैशव अवस्था (early childhood), children achieve significant विकास (development) milestones:
*   Pulls up to stand
*   Cruises or takes first steps
*   Says "mama" or "dada"

## 18 Months
*   Walks alone
*   Drinks from a cup
*   Points to show interest

## 2 Years
*   Kicks a ball
*   Speaks in short sentences (2-4 words)
*   Follows simple instructions
''',
        ),
        const ResourceArticleModel(
          id: 'tod2',
          title: 'Feeding Guide',
          description: 'Evidence-based nutrition and feeding strategies for toddlers.',
          icon: Icons.child_care,
          color: Color(0xFF80CBC4), // Soft Teal
          category: 'Nutrition',
          readingTime: '4 min',
          content: '''
# Feeding Your Toddler

Nutrition during शैशव अवस्था (early childhood) supports healthy वृद्धि (growth). Offer a variety of foods. It's normal for appetite to fluctuate. Avoid force-feeding. Offer 3 meals and 2 snacks daily.
''',
        ),
        const ResourceArticleModel(
          id: 'tod3',
          title: 'Sleep Training',
          description: 'Research-based approaches to establishing healthy sleep routines.',
          icon: Icons.bedtime,
          color: Color(0xFF9FA8DA), // Soft Indigo
          category: 'Baby Care',
          readingTime: '5 min',
          content: '''
# Sleep Tips

Establishing healthy sleep patterns during शैशव अवस्था (early childhood) supports overall विकास (development). Establish a consistent bedtime routine. Keep the room dark and cool. Be patient with regressions. Aim for 11-14 hours of sleep total.
''',
        ),
        const ResourceArticleModel(
          id: 'tod4',
          title: 'Vaccination Schedule',
          description: 'Standard immunization protocols for शैशव अवस्था (early childhood).',
          icon: Icons.vaccines,
          color: Color(0xFFEF9A9A), // Soft Red
          category: 'Health',
          readingTime: '2 min',
          content: '''
# Vaccinations

Protecting your child during शैशव अवस्था (early childhood) through immunization is essential. Check with your pediatrician for the standard schedule (e.g., MMR, Varicella, DTaP boosters). Keep your records updated.
''',
        ),
        const ResourceArticleModel(
          id: 'tod5',
          title: 'Potty Training',
          description: 'Developmental readiness indicators and evidence-based training strategies.',
          icon: Icons.wc,
          color: Color(0xFFCE93D8), // Soft Purple
          category: 'Baby Care',
          readingTime: '4 min',
          content: '''
# Potty Training

This विकास (development) milestone during शैशव अवस्था (early childhood) typically occurs between 2-3 years. Most children are ready between 2 and 3 years old. Look for signs like staying dry for longer periods and showing interest in the bathroom.
''',
        ),
      ];
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: color,
          width: 2.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.08),
                color.withOpacity(0.03),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
