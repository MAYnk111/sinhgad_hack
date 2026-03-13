import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maternal_infant_care/presentation/viewmodels/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DiseaseAwarenessPage extends ConsumerStatefulWidget {
  const DiseaseAwarenessPage({super.key});

  @override
  ConsumerState<DiseaseAwarenessPage> createState() =>
      _DiseaseAwarenessPageState();
}

class _DiseaseAwarenessPageState extends ConsumerState<DiseaseAwarenessPage> {
  String searchQuery = '';
  String selectedCategory = 'All';
  Map<String, dynamic>? selectedDisease;

  final List<String> categories = [
    'All',
    'Common',
    'Respiratory',
    'Digestive',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final emergencyContact = currentUser?['phone']?.toString();

    final allDiseases = _getCommonDiseases();
    final filteredDiseases = allDiseases.where((disease) {
      final matchesSearch = disease['name']
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      final matchesCategory =
          selectedCategory == 'All' || disease['category'] == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Awareness'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: 'Search conditions...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
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
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredDiseases.isEmpty
                ? const Center(
                    child: Text('No results found.'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredDiseases.length,
                    itemBuilder: (context, index) {
                      final disease = filteredDiseases[index];
                      return _DiseaseHubCard(
                        disease: disease,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DiseaseDetailPage(
                                disease: disease,
                                emergencyContact: emergencyContact,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getCommonDiseases() {
    return [
      {
        'name': 'Common Cold',
        'category': 'Common',
        'icon': Icons.ac_unit,
        'color': const Color(0xFF4FC3F7), // Light Blue
        'symptoms': [
          'Runny nose',
          'Sneezing',
          'Cough',
          'Mild fever',
          'Irritability'
        ],
        'prevention': [
          'Wash hands frequently',
          'Keep baby away from sick people',
          'Clean toys and surfaces regularly',
          'Avoid sharing utensils',
        ],
        'homeCare': [
          'Ensure adequate rest',
          'Keep baby hydrated with breast milk/formula',
          'Use saline drops for stuffy nose',
          'Monitor temperature',
        ],
        'seeDoctor': [
          'Fever above 100.4°F in babies under 3 months',
          'Difficulty breathing',
          'Severe cough lasting more than a week',
          'Signs of dehydration',
        ],
        'riskLevel': 'Low',
      },
      {
        'name': 'Fever',
        'category': 'Common',
        'icon': Icons.thermostat,
        'color': const Color(0xFFFFB74D), // Soft Orange
        'symptoms': [
          'Elevated body temperature',
          'Irritability',
          'Decreased appetite',
          'Lethargy'
        ],
        'prevention': [
          'Maintain good hygiene',
          'Ensure proper vaccination',
          'Keep baby away from sick individuals',
        ],
        'homeCare': [
          'Monitor temperature regularly',
          'Dress baby in light clothing',
          'Ensure adequate fluid intake',
          'Give lukewarm sponge baths if recommended',
        ],
        'seeDoctor': [
          'Fever above 100.4°F in babies under 3 months',
          'Fever above 102.2°F in older babies',
          'Fever lasting more than 3 days',
          'Baby appears very ill or unresponsive',
        ],
        'riskLevel': 'Moderate',
      },
      {
        'name': 'Diarrhea',
        'category': 'Digestive',
        'icon': Icons.water_drop,
        'color': const Color(0xFF8D6E63), // Sandalwood
        'symptoms': [
          'Frequent loose, watery stools',
          'Dehydration signs',
          'Reduced urine output',
          'Irritability',
        ],
        'prevention': [
          'Maintain hygiene and sanitation',
          'Wash hands before handling food',
          'Ensure safe water sources',
          'Practice safe food preparation',
        ],
        'homeCare': [
          'Continue breastfeeding/formula feeding',
          'Offer ORS as advised',
          'Monitor for signs of dehydration',
          'Change diapers frequently',
        ],
        'seeDoctor': [
          'Signs of dehydration (dry mouth, no tears)',
          'Blood in stools',
          'Diarrhea lasting more than 24 hours',
          'High fever with diarrhea',
        ],
        'riskLevel': 'High',
      },
      {
        'name': 'RSV',
        'category': 'Respiratory',
        'icon': Icons.air,
        'color': const Color(0xFFEF5350), // Soft Red
        'symptoms': [
          'Runny nose',
          'Cough',
          'Wheezing',
          'Difficulty breathing',
          'Fever',
        ],
        'prevention': [
          'Wash hands frequently',
          'Avoid close contact with sick people',
          'Keep away from crowds during season',
          'Clean and disinfect surfaces',
        ],
        'homeCare': [
          'Ensure adequate rest and hydration',
          'Use humidifier to ease breathing',
          'Keep baby in upright position',
          'Monitor breathing closely',
        ],
        'seeDoctor': [
          'Rapid or difficulty breathing',
          'Bluish color around lips',
          'Signs of dehydration',
          'High fever',
        ],
        'riskLevel': 'High',
      },
      {
        'name': 'Croup',
        'category': 'Respiratory',
        'icon': Icons.record_voice_over,
        'color': const Color(0xFF7986CB), // Indigo
        'symptoms': [
          'Barking cough (sounds like a seal)',
          'Hoarseness',
          'Stridor (high-pitched breathing)',
          'Low-grade fever',
        ],
        'prevention': [
          'Maintain good hand hygiene',
          'Keep infant away from people with respiratory infections',
          'Ensure vaccinations are up to date',
        ],
        'homeCare': [
          'Keep child calm (crying worsens symptoms)',
          'Use a cool-mist humidifier',
          'Brief exposure to cool night air can help',
          'Steam from a hot shower for 10 minutes',
        ],
        'seeDoctor': [
          'Stridor while resting',
          'Difficulty swallowing',
          'Extreme irritability or fatigue',
          'Bluish skin or lips',
        ],
        'riskLevel': 'Moderate',
      },
      {
        'name': 'Ear Infection',
        'category': 'Common',
        'icon': Icons.hearing,
        'color': const Color(0xFFBA68C8), // Purple
        'symptoms': [
          'Ear pulling/tugging',
          'Fussiness',
          'Difficulty sleeping',
          'Fluid drainage from ear',
          'Fever',
        ],
        'prevention': [
          'Avoid second-hand smoke',
          'Breastfeed for at least 6 months',
          'Ensure vaccinations (especially flu and pneumococcal)',
          'Avoid bottle-feeding while lying flat',
        ],
        'homeCare': [
          'Warm compress over the ear',
          'Rest and extra fluids',
          'Follow doctor-prescribed pain relief',
          'Monitor for changes in hearing',
        ],
        'seeDoctor': [
          'Severe pain or high fever',
          'Fluid, pus, or bloody discharge',
          'Hearing loss symptoms',
          'Symptoms not improving after 48 hours',
        ],
        'riskLevel': 'Moderate',
      },
      {
        'name': 'Hand, Foot, & Mouth',
        'category': 'Other',
        'icon': Icons.pan_tool_alt,
        'color': const Color(0xFFF06292), // Pink
        'symptoms': [
          'Fever',
          'Sore throat',
          'Small blisters on hands and feet',
          'Painful mouth sores',
          'Loss of appetite',
        ],
        'prevention': [
          'Frequent hand washing',
          'Disinfect toys and common areas',
          'Avoid sharing cups or utensils',
          'Keep child home until blisters dry',
        ],
        'homeCare': [
          'Offer cold drinks or soft foods',
          'Avoid spicy or acidic foods',
          'Maintain hydration',
          'Monitor temperature',
        ],
        'seeDoctor': [
          'Signs of dehydration',
          'Mouth sores making drinking impossible',
          'High fever not coming down',
          'Lethargy or confusion',
        ],
        'riskLevel': 'Medium',
      },
      {
        'name': 'Diaper Rash',
        'category': 'Common',
        'icon': Icons.child_care,
        'color': const Color(0xFF4DB6AC), // Teal
        'symptoms': [
          'Redness in diaper area',
          'Small red bumps',
          'Child cry when diaper area is touched',
          'Peeling or scaling skin',
        ],
        'prevention': [
          'Change diapers frequently',
          'Clean area gently with water',
          'Allow "air time" without a diaper',
          'Apply barrier cream (zinc oxide)',
        ],
        'homeCare': [
          'Increase diaper changes',
          'Use mild, fragrance-free wipes',
          'Pat skin dry, don\'t rub',
          'Rinse area with warm water at each change',
        ],
        'seeDoctor': [
          'Blisters or pus-filled sores',
          'Rash spreading beyond diaper area',
          'Fever with rash',
          'Rash that doesn\'t improve in 3 days',
        ],
        'riskLevel': 'Low',
      },
      {
        'name': 'Jaundice',
        'category': 'Other',
        'icon': Icons.face_retouching_natural,
        'color': const Color(0xFFFFF176), // Yellow
        'symptoms': [
          'Yellowish skin and eye whites',
          'Poor feeding',
          'High-pitched crying',
          'Lethargy or sleepiness',
        ],
        'prevention': [
          'Ensure baby is feeding well 8-12 times a day',
          'Check skin color in natural light',
          'Avoid dehydration',
        ],
        'homeCare': [
          'Frequent feedings to help clear bilirubin in stools',
          'Monitor diaper output',
          'Follow pediatrician\'s instructions closely',
          'Exposure to indirect sunlight (only if advised)',
        ],
        'seeDoctor': [
          'Yellowing spreading to arms/legs',
          'Yellow skin seems dark or deep',
          'Baby is hard to wake up',
          'Baby not gaining weight',
        ],
        'riskLevel': 'Moderate',
      },
      {
        'name': 'Colic',
        'category': 'Digestive',
        'icon': Icons.sentiment_very_dissatisfied,
        'color': const Color(0xFFFF8A65), // Deep Orange
        'symptoms': [
          'Intense crying for 3+ hours a day',
          'Crying occurs at the same time each day',
          'Clenched fists or curled legs',
          'Red face during crying',
        ],
        'prevention': [
          'Try different soothing techniques',
          'Maintain a calm environment',
          'Burp baby frequently during feeds',
          'Consider dietary changes if breastfeeding',
        ],
        'homeCare': [
          'Gentle rhythmic rocking',
          'White noise or soft music',
          'Warm bath or tummy massage',
          'Ensure caregiver gets breaks/rest',
        ],
        'seeDoctor': [
          'Crying pattern changes suddenly',
          'Fever, vomiting, or diarrhea',
          'Baby seems in pain, not just fussy',
          'Caregiver feels overwhelmed or angry',
        ],
        'riskLevel': 'Low',
      },
      {
        'name': 'Constipation',
        'category': 'Digestive',
        'icon': Icons.hourglass_empty,
        'color': const Color(0xFF9CCC65), // Light Green
        'symptoms': [
          'Hard, pellet-like stools',
          'Straining or pain during bowel movements',
          'Abdominal bloating',
          'Blood on outside of stool',
        ],
        'prevention': [
          'Ensure adequate fluid intake',
          'Introduce high-fiber foods (if on solids)',
          'Tummy time and leg exercises',
          'Maintain regular feeding schedule',
        ],
        'homeCare': [
          'Gently move baby\'s legs in "bicycle" motion',
          'Warm bath to relax abdominal muscles',
          'Small amounts of prune or pear juice (if advised)',
          'Gentle tummy massage',
        ],
        'seeDoctor': [
          'Vomiting with constipation',
          'Extremely swollen belly',
          'Persistent blood in stool',
          'Not passing stool for several days',
        ],
        'riskLevel': 'Low',
      },
      {
        'name': 'Pneumonia',
        'category': 'Respiratory',
        'icon': Icons.medical_information,
        'color': const Color(0xFFE57373), // Red
        'symptoms': [
          'Rapid or labored breathing',
          'Chest retractions (skin pulling in)',
          'Persistent deep cough',
          'High fever and chills',
          'Wheezing or grunting sounds',
        ],
        'prevention': [
          'Timely PCV and Hib vaccinations',
          'Exclusive breastfeeding for first 6 months',
          'Keep away from tobacco smoke',
          'Avoid crowded indoor spaces with sick people',
        ],
        'homeCare': [
          'Ensure strictly prescribed medications are taken',
          'Maximize rest and hydration',
          'Keep infant in semi-upright position',
          'Monitor oxygen levels if advised',
        ],
        'seeDoctor': [
          'Nostrils flaring with each breath',
          'Bluish tint to lips or nails',
          'Extreme difficulty breathing',
          'Unable to feed or keep fluids down',
        ],
        'riskLevel': 'High',
      },
    ];
  }
}

class _DiseaseHubCard extends StatelessWidget {
  final Map<String, dynamic> disease;
  final VoidCallback onTap;

  const _DiseaseHubCard({required this.disease, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final riskColor = disease['riskLevel'] == 'High'
        ? Colors.red
        : disease['riskLevel'] == 'Moderate'
            ? Colors.orange
            : Colors.green;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color:
                Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (disease['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  disease['icon'] as IconData,
                  color: disease['color'] as Color,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                disease['name'] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: riskColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${disease['riskLevel']} Risk',
                    style: TextStyle(
                      fontSize: 12,
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                    ),
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

class DiseaseDetailPage extends StatelessWidget {
  final Map<String, dynamic> disease;
  final String? emergencyContact;

  const DiseaseDetailPage({
    super.key,
    required this.disease,
    this.emergencyContact,
  });

  @override
  Widget build(BuildContext context) {
    final riskColor = disease['riskLevel'] == 'High'
        ? Colors.red
        : disease['riskLevel'] == 'Moderate'
            ? Colors.orange
            : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text(disease['name'] as String),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: riskColor),
                  const SizedBox(width: 8),
                  Text(
                    'Risk Level: ${disease['riskLevel']}',
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _DetailSection(
              title: 'Symptoms',
              icon: Icons.info_outline,
              items: (disease['symptoms'] as List).cast<String>(),
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            _DetailSection(
              title: 'Prevention',
              icon: Icons.shield_outlined,
              items: (disease['prevention'] as List).cast<String>(),
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            _DetailSection(
              title: 'Home Care',
              icon: Icons.home_outlined,
              items: (disease['homeCare'] as List).cast<String>(),
              color: Colors.orange,
            ),
            const SizedBox(height: 32),
            _EmergencySection(
              items: (disease['seeDoctor'] as List).cast<String>(),
              emergencyContact: emergencyContact,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final Color color;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 36.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: color.withOpacity(0.7)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _EmergencySection extends StatefulWidget {
  final List<String> items;
  final String? emergencyContact;

  const _EmergencySection({
    required this.items,
    this.emergencyContact,
  });

  @override
  State<_EmergencySection> createState() => _EmergencySectionState();
}

class _EmergencySectionState extends State<_EmergencySection> {
  Timer? _holdTimer;
  int _remainingSeconds = 3;
  bool _isHolding = false;
  bool _isSending = false;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  Future<String?> _resolveEmergencyContact() async {
    final directContact = widget.emergencyContact?.trim();
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

  Future<void> _triggerSos() async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
    });

    try {
      final emergencyContact = await _resolveEmergencyContact();
      if (emergencyContact == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No emergency contact found for SMS.'),
            ),
          );
        }
        return;
      }

      final position = await _getCurrentLocation();
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to fetch location. Check GPS permissions.'),
            ),
          );
        }
        return;
      }

      final locationLink =
          'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      final message =
          'Emergency! I need help. My location:\n$locationLink';

      final smsUri = Uri(
        scheme: 'sms',
        path: emergencyContact,
        queryParameters: <String, String>{
          'body': message,
        },
      );

      final launched = await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open SMS app.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isHolding = false;
          _remainingSeconds = 3;
        });
      }
    }
  }

  void _startHold() {
    if (_isSending || _isHolding) return;

    setState(() {
      _isHolding = true;
      _remainingSeconds = 3;
    });

    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_remainingSeconds <= 1) {
        timer.cancel();
        _triggerSos();
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isHolding = false;
      _remainingSeconds = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency_rounded, color: Colors.red, size: 24),
              SizedBox(width: 12),
              Text(
                'When to See a Doctor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTapDown: (_) => _startHold(),
                  onTapCancel: _cancelHold,
                  onTapUp: (_) {
                    if (_isHolding && !_isSending) {
                      _cancelHold();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isHolding
                          ? Colors.red.shade700
                          : Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.35),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isSending
                          ? const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isHolding
                      ? 'Keep holding... $_remainingSeconds'
                      : 'Hold for 3 seconds to send SOS',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
