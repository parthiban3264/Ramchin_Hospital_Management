import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Mediacl_Staff/Pages/OutPatient/Page/InjectionPage.dart';
import 'service.dart';
import 'widget.dart';

class CreateTestScanPage extends StatefulWidget {
  const CreateTestScanPage({super.key});
  @override
  State<CreateTestScanPage> createState() => CreateTestScanPageState();
}

class CreateTestScanPageState extends State<CreateTestScanPage>
    with TickerProviderStateMixin {
  String hospitalName = "Hospital",
      hospitalPlace = "Location",
      hospitalPhoto = "",
      hospitalId = '';
  int currentStep = 0;
  final List<String> wizardSteps = ['Type', 'Category', 'Parameters', 'Review'];
  final testNameCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  String selectedType = 'TEST';
  String selectedCategory = '';

  String selectedModality = '';
  String selectedRegion = '';
  final paramNameCtrl = TextEditingController();
  final methodCtrl = TextEditingController();
  final customUnitCtrl = TextEditingController();
  final customQualCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String paramValueType = 'numeric';
  String paramUnit = '';
  String paramSpecimen = '';
  String paramQualRef = '';
  String? currentAgeRange;
  String currentGender = 'MF';
  final refMinCtrl = TextEditingController();
  final refMaxCtrl = TextEditingController();
  Map<String, String> tempRefRanges = {};
  List<TestParameter> parameters = [];
  Set<String> existingTestCategories = {};
  Map<String, Set<String>> existingScanRegions = {};
  Map<String, Map<String, String>> existingScanAmounts = {};
  Map<String, int> existingScanIds = {};
  Map<String, int> existingTestIds = {};
  Map<String, List<Map<String, dynamic>>> existingScanOptions = {};
  Map<String, List<TestParameter>> existingTestParameters = {};
  final paramPriceCtrl = TextEditingController();
  final customCategoryCtrl = TextEditingController();
  final customModalityCtrl = TextEditingController();
  final customRegionCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  List<String> extraScanModalities = [];
  List<String> extraTestCategories = [];
  int? editingParamIndex;
  late AnimationController _fadeController;
  late PageController _pageController;

  void _nextStep() {
    if (currentStep == 0 && selectedType.isEmpty) {
      showSnack('Select Test or Scan', error: true, context: context);
      return;
    }
    if (currentStep == 1) {
      if (selectedType == 'TEST' && selectedCategory.isEmpty) {
        showSnack('Select a category', error: true, context: context);
        return;
      }
      if (selectedType == 'SCAN' &&
          (selectedModality.isEmpty || selectedRegion.isEmpty)) {
        showSnack('Select scan name and option', error: true, context: context);
        return;
      }
    }
    if (currentStep == 2 && selectedType == 'TEST' && parameters.isEmpty) {
      showSnack('Add at least one parameter', error: true, context: context);
      return;
    }

    if (currentStep < 3) {
      int nextStep = currentStep + 1;
      if (currentStep == 1 && selectedType == 'SCAN') {
        if (amountCtrl.text.trim().isEmpty) {
          showSnack('Enter amount', error: true, context: context);
          return;
        }
        nextStep = 3;
      }

      setState(() => currentStep = nextStep);
      _pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _prevStep() {
    if (currentStep > 0) {
      int prevStep = currentStep - 1;
      if (currentStep == 3 && selectedType == 'SCAN') {
        prevStep = 1; // Skip Step 2
      }

      setState(() => currentStep = prevStep);
      _pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _addRefRange() {
    if (currentAgeRange == null ||
        (refMinCtrl.text.isEmpty && refMaxCtrl.text.isEmpty)) {
      showSnack(
        'Select age group and enter values',
        error: true,
        context: context,
      );
      return;
    }
    final key = currentAgeRange == 'pregnant'
        ? 'pregnant'
        : '${currentAgeRange}_$currentGender';
    final min = refMinCtrl.text.trim().toUpperCase();
    final max = refMaxCtrl.text.trim().toUpperCase();
    String val = min.isNotEmpty && max.isNotEmpty
        ? '$min-$max'
        : (min.isEmpty ? '≤$max' : '≥$min');
    setState(() {
      tempRefRanges[key] = val;
      refMinCtrl.clear();
      refMaxCtrl.clear();
      currentAgeRange = null;
    });
    HapticFeedback.lightImpact();
  }

  String _normalizeAgeKey(String rawKey) {
    if (rawKey == 'pregnant') return 'pregnant';
    String base = rawKey;
    String gSuffix = 'MF'; // Default internal gender suffix

    // Detect gender from descriptive suffixes first
    final upperKey = rawKey.toUpperCase();
    if (upperKey.endsWith('_MALE')) {
      gSuffix = 'M';
      base = rawKey.substring(0, rawKey.length - 5);
    } else if (upperKey.endsWith('_FEMALE')) {
      gSuffix = 'F';
      base = rawKey.substring(0, rawKey.length - 7);
    } else if (upperKey.endsWith('_ALL')) {
      gSuffix = 'MF';
      base = rawKey.substring(0, rawKey.length - 4);
    } else if (upperKey.endsWith('_MF')) {
      gSuffix = 'MF';
      base = rawKey.substring(0, rawKey.length - 3);
    } else if (upperKey.endsWith('_M')) {
      gSuffix = 'M';
      base = rawKey.substring(0, rawKey.length - 2);
    } else if (upperKey.endsWith('_F')) {
      gSuffix = 'F';
      base = rawKey.substring(0, rawKey.length - 2);
    }

    final mapping = {
      'NEWBORN': '0_1',
      'INFANT': '1_12',
      'TODDLER': '12_72',
      'TODDLER/CHILD': '12_72',
      'CHILD': '72_144',
      'ADOLESCENT': '144_216',
      'ADULT': '216_780',
      'ELDERLY': '780_0',
      'PREGNANT': 'pregnant',
    };

    String normalizedBase = mapping[base.toUpperCase()] ?? base;

    // If it was already in a numeric format but lost its suffix during detection
    // (e.g. 0_1_M became 0_1), ensure it stays in that format
    if (normalizedBase == '0_1' ||
        normalizedBase == '1_12' ||
        normalizedBase == '12_72' ||
        normalizedBase == '72_144' ||
        normalizedBase == '144_216' ||
        normalizedBase == '216_780' ||
        normalizedBase == '780_0') {
      // It's a standard age group
    } else if (base.contains('_') && base.split('_').length >= 2) {
      // already numeric-like format but maybe base was 0_1 or something
      normalizedBase = base;
    }

    if (normalizedBase == 'pregnant') return 'pregnant';
    return '${normalizedBase}_$gSuffix';
  }

  void _clearParamForm() {
    setState(() {
      editingParamIndex = null;
      paramNameCtrl.clear();
      methodCtrl.clear();
      paramPriceCtrl.clear();
      customUnitCtrl.clear();
      customQualCtrl.clear();
      descCtrl.clear();
      refMinCtrl.clear();
      refMaxCtrl.clear();
      currentAgeRange = null;
      paramUnit = '';
      paramQualRef = '';
      paramSpecimen = '';
      tempRefRanges.clear();
      paramValueType = 'numeric';
    });
  }

  void _loadParamForEdit(int index, TestParameter p) {
    setState(() {
      editingParamIndex = index;
      paramNameCtrl.text = p.name;
      paramPriceCtrl.text = p.price > 0 ? p.price.toString() : '';
      methodCtrl.text = p.method;
      paramValueType = p.valueType.name;
      paramSpecimen = p.specimen;
      refMinCtrl.clear();
      refMaxCtrl.clear();
      currentAgeRange = null;

      // Handle Unit (Case-insensitive)
      final allUnits =
          (paramValueType == 'countPerHpf' || paramValueType == 'countPerLpf')
          ? countUnits
          : numericUnits;

      final matchedUnit = allUnits.firstWhere(
        (u) => u.toUpperCase() == p.unit.toUpperCase(),
        orElse: () => '',
      );

      if (matchedUnit.isNotEmpty) {
        paramUnit = matchedUnit;
        customUnitCtrl.clear();
      } else if (p.unit.isNotEmpty) {
        paramUnit = 'Others';
        customUnitCtrl.text = p.unit;
      } else {
        paramUnit = '';
        customUnitCtrl.clear();
      }

      // Handle Descriptive/Qualitative Ref (Case-insensitive)
      if (p.qualitativeRef != null && p.qualitativeRef!.trim().isNotEmpty) {
        final val = p.qualitativeRef!.trim();
        if (paramValueType == 'descriptive') {
          descCtrl.text = val;
          paramQualRef = '';
        } else {
          // Existing qualitative logic...
          final matchedQual = qualitativeOptions.firstWhere(
            (q) =>
                q.toUpperCase() == val.toUpperCase() &&
                q.toUpperCase() != 'OTHERS',
            orElse: () => '',
          );

          if (matchedQual.isNotEmpty) {
            paramQualRef = matchedQual;
            customQualCtrl.clear();
          } else {
            paramQualRef = 'Others';
            customQualCtrl.text = val;
          }
        }
      } else {
        paramQualRef = '';
        customQualCtrl.clear();
        descCtrl.clear();
      }

      tempRefRanges = {};
      p.referenceRanges.forEach((k, v) {
        tempRefRanges[_normalizeAgeKey(k)] = v;
      });

      // Navigate to Step 3 (Parameters) if not already there
      if (currentStep != 2) {
        setState(() => currentStep = 2);
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }

      // Auto-select the first reference range for immediate editing feedback
      if (tempRefRanges.isNotEmpty) {
        final firstKey = tempRefRanges.keys.first;
        if (firstKey == 'pregnant') {
          currentAgeRange = 'pregnant';
          currentGender = 'F';
        } else {
          final parts = firstKey.split('_');
          if (parts.length >= 2) {
            currentGender = parts.last;
            currentAgeRange = parts.sublist(0, parts.length - 1).join('_');
          }
        }

        final val = tempRefRanges[firstKey]!;
        if (val.contains('-')) {
          final parts = val.split('-');
          refMinCtrl.text = parts[0];
          refMaxCtrl.text = parts[1];
        } else if (val.startsWith('≤')) {
          refMinCtrl.clear();
          refMaxCtrl.text = val.substring(1);
        } else if (val.startsWith('≥')) {
          refMinCtrl.text = val.substring(1);
          refMaxCtrl.clear();
        } else {
          refMinCtrl.text = val;
          refMaxCtrl.clear();
        }
      }
    });
    HapticFeedback.selectionClick();
  }

  void _addParameter() {
    if (paramNameCtrl.text.isEmpty) {
      showSnack('Enter parameter name', error: true, context: context);
      return;
    }

    final vt = ValueType.values.firstWhere((e) => e.name == paramValueType);
    final unit = paramUnit == 'Others' ? customUnitCtrl.text.trim() : paramUnit;
    final qualRef = paramValueType == 'descriptive'
        ? descCtrl.text.trim()
        : (paramQualRef == 'Others'
              ? customQualCtrl.text.trim()
              : paramQualRef);

    final categoryDetails =
        testCategoryDetails[selectedCategory == 'Other'
            ? customCategoryCtrl.text.trim().toUpperCase()
            : selectedCategory];
    final subsections = categoryDetails?['subsections'] as List<dynamic>? ?? [];
    final subsection = subsections.isNotEmpty
        ? subsections.first.toString()
        : 'TOTAL';

    final param = TestParameter(
      name: paramNameCtrl.text.trim().toUpperCase(),
      subsection: subsection.toUpperCase(),
      valueType: vt,
      unit: unit.toUpperCase(),
      method: methodCtrl.text.trim().toUpperCase(),
      specimen: paramSpecimen.toUpperCase(),
      price: double.tryParse(paramPriceCtrl.text.trim()) ?? 0.0,
      referenceRanges: Map.from(tempRefRanges),
      qualitativeRef: qualRef.toUpperCase(),
    );

    setState(() {
      if (editingParamIndex != null) {
        parameters[editingParamIndex!] = param;
      } else {
        parameters.add(param);
      }
      editingParamIndex = null;
      paramNameCtrl.clear();
      methodCtrl.clear();
      paramPriceCtrl.clear();
      customUnitCtrl.clear();
      customQualCtrl.clear();
      descCtrl.clear();
      paramUnit = '';
      paramQualRef = '';
      tempRefRanges.clear();
    });
    HapticFeedback.mediumImpact();
    showSnack(
      editingParamIndex != null ? 'Parameter updated!' : 'Parameter added!',
      context: context,
    );
  }

  void _submit() {
    // UPPERCASE EVERYTHING
    final categoryName = selectedCategory == 'Other'
        ? customCategoryCtrl.text.trim().toUpperCase()
        : selectedCategory.toUpperCase();
    final modalityName = selectedModality == 'Other'
        ? customModalityCtrl.text.trim().toUpperCase()
        : selectedModality.toUpperCase();
    final regionName = selectedRegion == 'Other'
        ? customRegionCtrl.text.trim().toUpperCase()
        : selectedRegion.toUpperCase();

    if (selectedType == 'TEST' && categoryName.isEmpty) {
      showSnack('Enter category name', error: true, context: context);
      return;
    }
    if (selectedType == 'SCAN' &&
        (modalityName.isEmpty || regionName.isEmpty)) {
      showSnack(
        'Enter modality and region details',
        error: true,
        context: context,
      );
      return;
    }

    final data = selectedType == 'TEST'
        ? {
            'name': testNameCtrl.text.trim().isNotEmpty
                ? testNameCtrl.text.trim().toUpperCase()
                : categoryName,
            'category': categoryName,
            'type': selectedType,
            'parameters': parameters.map((p) => p.toJson()).toList(),
          }
        : {
            'name': testNameCtrl.text.trim().isNotEmpty
                ? testNameCtrl.text.trim().toUpperCase()
                : modalityName,
            'modality': modalityName,
            'region': regionName,
            'type': selectedType,
            'amount': amountCtrl.text.trim().toUpperCase(),
          };

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.preview, color: successColor),
            ),
            const SizedBox(width: 12),
            const Text(
              'Preview',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sectionBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryLight.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: successColor.withValues(
                              alpha: 0.1,
                            ),
                            child: Icon(
                              selectedType == 'TEST'
                                  ? Icons.science
                                  : Icons.scanner,
                              color: successColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  selectedType == 'TEST'
                                      ? 'Laboratory Test'
                                      : 'Medical Scan',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      if (selectedType == 'TEST')
                        previewRow('Category', data['category']),
                      if (selectedType == 'SCAN') ...[
                        previewRow('Scan', data['modality']),
                        previewRow('Option', data['region']),
                        previewRow(
                          'Amount',
                          '₹${data['amount'] ?? "0"}',
                          isBold: true,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Parameters List (For Test)
                if (selectedType == 'TEST' && parameters.isNotEmpty) ...[
                  const Text(
                    'Parameters Configuration',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...parameters.map(
                    (p) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (p.unit.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    p.unit,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (p.referenceRanges.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 18),
                              child: Text(
                                'Refs: ${p.referenceRanges.entries.map((e) => "${keyLabel(e.key)}: ${e.value}").join(", ")}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          if (p.price > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2, left: 18),
                              child: Text(
                                'Price: ₹${p.price}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: successColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Edit'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: successColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                if (selectedType == 'SCAN' &&
                    existingScanIds.containsKey(data['modality'])) {
                  // UPDATE EXISTING SCAN
                  final id = existingScanIds[data['modality']]!;
                  final oldOptions =
                      existingScanOptions[data['modality']] ?? [];

                  final newRegion = data['region'];
                  final newPrice = double.tryParse(data['amount'].toString());

                  // Copy list to avoid mutating original state directly before success
                  List<Map<String, dynamic>> newOptions = List.from(oldOptions);

                  final index = newOptions.indexWhere(
                    (o) =>
                        o['optionName']?.toString().toUpperCase() ==
                        newRegion.toString().toUpperCase(),
                  );

                  if (index != -1) {
                    // Update existing option price
                    newOptions[index] = {
                      ...newOptions[index],
                      if (newPrice != null) 'price': newPrice,
                    };
                  } else {
                    // Add new option
                    newOptions.add({
                      'optionName': newRegion.toString().toUpperCase(),
                      'price': newPrice ?? 0,
                      'unit': '-',
                      'type': '',
                      'reference': '',
                    });
                  }

                  await TestAndScanService().updateTestOrScan(
                    id: id,
                    options: newOptions,
                  );
                } else if (selectedType == 'TEST' &&
                    existingTestIds.containsKey(
                      data['category']?.toString().toUpperCase(),
                    )) {
                  // UPDATE EXISTING TEST
                  final id =
                      existingTestIds[data['category']
                          ?.toString()
                          .toUpperCase()]!;
                  List<Map<String, dynamic>> options = [];
                  if (data['parameters'] is List) {
                    options = (data['parameters'] as List)
                        .cast<Map<String, dynamic>>();
                  }
                  await TestAndScanService().updateTestOrScan(
                    id: id,
                    options: options,
                  );
                } else {
                  // CREATE NEW
                  List<Map<String, dynamic>> options = [];
                  if (selectedType == 'SCAN') {
                    options.add({
                      'optionName': data['region'].toString().toUpperCase(),
                      'price': double.tryParse(
                        data['amount']?.toString() ?? '0',
                      ),
                      'unit': '-',
                      'type': '',
                      'reference': '',
                    });
                  } else {
                    // For TESTS, assuming options = parameters
                    // Parameters list of Maps: {name, unit, referenceRange...}
                    // Map keys should match what backend expects.
                    // Assuming p.toJson() aligns with backend 'options' structure or specific structure?
                    // Service expects List<Map>.
                    if (data['parameters'] is List) {
                      options = (data['parameters'] as List)
                          .cast<Map<String, dynamic>>();
                    }
                  }

                  await TestAndScanService().createTestOrScan(
                    title: data['name'].toString(),
                    type: data['type'].toString(),
                    category: data['category']?.toString(),
                    amount: double.tryParse(data['amount']?.toString() ?? '0'),
                    options: options,
                  );
                }

                if (mounted) {
                  Navigator.pop(context); // Pop loading
                  Navigator.pop(context); // Pop preview
                  showSnack('Saved successfully!', context: context);
                  setState(() {
                    testNameCtrl.clear();
                    customCategoryCtrl.clear();
                    customModalityCtrl.clear();
                    customRegionCtrl.clear();
                    amountCtrl.clear();
                    selectedCategory = '';
                    selectedModality = '';
                    selectedRegion = '';
                    parameters.clear();
                    currentStep = 0;
                    _pageController.jumpToPage(0);
                    // Refresh data
                    fetchAllTestsScans();
                  });
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Pop loading
                  showSnack('Error: $e', error: true, context: context);
                }
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGradientStart,

      appBar: buildAppBar(
        context,
        title: 'Create ${selectedType == 'TEST' ? 'Test' : 'Scan'}',
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgGradientStart, bgGradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: buildStepIndicator(currentStep, wizardSteps),
            ),
            // Step labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: wizardSteps.asMap().entries.map((e) {
                  final isActive = e.key == currentStep;
                  return Expanded(
                    child: Text(
                      e.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive ? primaryColor : Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            // Page view
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => currentStep = i),
                children: [
                  buildStep1(
                    hospitalName,
                    hospitalPlace,
                    hospitalPhoto,
                    _buildTypeCard,
                  ),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    String type,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = selectedType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          selectedType = type;
          selectedCategory = '';
          selectedModality = '';
          selectedRegion = '';
          parameters.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [primaryColor, primaryLight])
              : null,
          color: isSelected ? null : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : primaryColor.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : primaryColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: selectedType == 'TEST'
          ? _buildTestCategorySelection()
          : _buildScanModalitySelection(),
    );
  }

  Widget _buildTestCategorySelection() {
    final searchTerm = searchCtrl.text.toLowerCase();
    final departments = <String, List<String>>{};

    testCategoryDetails.forEach((name, details) {
      if (searchTerm.isEmpty || name.toLowerCase().contains(searchTerm)) {
        final dept = details['dept'] as String? ?? 'Other';
        departments.putIfAbsent(dept, () => []).add(name);
      }
    });

    // ADD EXTRA CATEGORIES (USER DEFINED)
    for (var extra in extraTestCategories) {
      if (searchTerm.isEmpty || extra.toLowerCase().contains(searchTerm)) {
        departments.putIfAbsent('USER DEFINED', () => []).add(extra);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search categories...',
            prefixIcon: const Icon(Icons.search, color: primaryColor),
            suffixIcon: searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchCtrl.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Categories by department
        ...departments.entries.map(
          (dept) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dept.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemCount: dept.value.length,
                itemBuilder: (_, i) {
                  final name = dept.value[i];
                  final details =
                      testCategoryDetails[name] ??
                      {'icon': Icons.present_to_all};

                  final isExisting = existingTestCategories.contains(
                    name.toUpperCase(),
                  );
                  final isSelected = selectedCategory == name;

                  return buildCategoryCard(
                    name,
                    details['icon'] as IconData,
                    isSelected,
                    () {
                      setState(() {
                        if (selectedCategory != name) {
                          selectedCategory = name;
                          parameters.clear();
                          // If it's an existing test, load its parameters
                          if (isExisting) {
                            final upName = name.toUpperCase();
                            if (existingTestParameters.containsKey(upName)) {
                              // Clone parameters via deep copy to avoid shared state across additions
                              parameters = existingTestParameters[upName]!
                                  .map(
                                    (p) => TestParameter(
                                      name: p.name,
                                      subsection: p.subsection,
                                      valueType: p.valueType,
                                      unit: p.unit,
                                      method: p.method,
                                      specimen: p.specimen,
                                      price: p.price,
                                      referenceRanges: Map<String, String>.from(
                                        p.referenceRanges,
                                      ),
                                      qualitativeRef: p.qualitativeRef,
                                    ),
                                  )
                                  .toList();
                              showSnack(
                                'Loaded existing parameters for $name',
                                context: context,
                              );
                            }
                          }
                        }
                        // } else if (hasTemplate) {
                        //   _loadTemplate(name);
                        // }
                      });
                    },
                    subtitle: isExisting ? 'Exists' : null,
                    color: isExisting ? successColor : null,
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        // Custom Category Input
        if (selectedCategory == 'Other')
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextFormField(
              controller: customCategoryCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: inputDeco('Custom Category Name', Icons.edit),
            ),
          ),
      ],
    );
  }

  Widget _buildScanModalitySelection() {
    final allModalities = [
      ...imagingModalities.keys.where((k) => k != 'Other'),
      ...extraScanModalities,
      'Other',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Scans',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: allModalities.length,
          itemBuilder: (_, i) {
            final name = allModalities[i];
            final isExtra = extraScanModalities.contains(name);
            final details = !isExtra
                ? imagingModalities[name]!
                : {'icon': Icons.folder_special};
            final isExisting = existingScanRegions.containsKey(name);

            return buildCategoryCard(
              name,
              details['icon'] as IconData,
              selectedModality == name,
              () => setState(() {
                selectedModality = name;
                selectedRegion = '';
              }),
              color: isExisting || isExtra ? successColor : null,
            );
          },
        ),
        // Custom Modality Input
        if (selectedModality == 'Other')
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            child: TextFormField(
              controller: customModalityCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: inputDeco('Custom Scan Name', Icons.edit),
            ),
          ),
        if (selectedModality.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Select Option',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                (extraScanModalities.contains(selectedModality)
                        ? [
                            ...existingScanRegions[selectedModality] ?? {},
                            'Other',
                          ]
                        : imagingModalities[selectedModality]!['regions']
                              as List<String>)
                    .map((r) {
                      // Check if this region exists for the selected modality
                      final isExisting =
                          existingScanRegions[selectedModality]?.contains(
                            r.toUpperCase(),
                          ) ??
                          existingScanRegions[selectedModality]?.contains(r) ??
                          false;

                      return chip(
                        r,
                        selectedRegion == r,
                        () => setState(() {
                          selectedRegion = r;
                          // Check for existing amount
                          final amounts = existingScanAmounts[selectedModality];
                          if (amounts != null) {
                            if (amounts.containsKey(r)) {
                              amountCtrl.text = amounts[r]!;
                            } else if (amounts.containsKey(r.toUpperCase())) {
                              amountCtrl.text = amounts[r.toUpperCase()]!;
                            } else {
                              amountCtrl.clear();
                            }
                          } else {
                            amountCtrl.clear();
                          }
                        }),
                        activeColor: isExisting ? successColor : accentColor,
                      );
                    })
                    .toList(),
          ),

          // Custom Region Input
          if (selectedRegion == 'Other')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextFormField(
                controller: customRegionCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: inputDeco('Custom Option Name', Icons.edit),
              ),
            ),

          // Amount Field
          if (selectedRegion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: inputDeco('Amount', Icons.currency_rupee),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStep3() {
    if (selectedType == 'SCAN') {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: successColor, size: 64),
              SizedBox(height: 16),
              Text(
                'Scan Configuration Complete',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Proceed to review and create your scan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parameters list
          if (parameters.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.list_alt, color: successColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Parameters (${parameters.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => parameters.clear()),
                  icon: const Icon(
                    Icons.delete_sweep,
                    size: 18,
                    color: dangerColor,
                  ),
                  label: const Text(
                    'Clear All',
                    style: TextStyle(color: dangerColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...parameters.asMap().entries.map(
              (e) => _buildParamCard(e.key, e.value),
            ),
            const SizedBox(height: 16),
            const Divider(),
          ],

          // Add new parameter form
          sectionCard(
            'Add Parameter',
            Icons.add_circle_outline,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: paramNameCtrl,
                        decoration: inputDeco(
                          'Parameter Name *',
                          Icons.label_outline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: paramPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: inputDeco('Price', Icons.currency_rupee),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Value Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    chip(
                      'Numeric',
                      paramValueType == 'numeric',
                      () => setState(() => paramValueType = 'numeric'),
                      activeColor: null,
                      inactiveBg: null,
                    ),
                    chip(
                      'Qualitative',
                      paramValueType == 'qualitative',
                      () => setState(() => paramValueType = 'qualitative'),
                      activeColor: null,
                      inactiveBg: null,
                    ),
                    chip(
                      'Normal',
                      paramValueType == 'normal',
                      () => setState(() => paramValueType = 'normal'),
                      activeColor: null,
                      inactiveBg: null,
                    ),
                    chip(
                      'Count/hpf',
                      paramValueType == 'countPerHpf',
                      () => setState(() => paramValueType = 'countPerHpf'),
                      activeColor: null,
                      inactiveBg: null,
                    ),
                    chip(
                      'Count/lpf',
                      paramValueType == 'countPerLpf',
                      () => setState(() => paramValueType = 'countPerLpf'),
                      activeColor: null,
                      inactiveBg: null,
                    ),
                    chip(
                      'Descriptive',
                      paramValueType == 'descriptive',
                      () => setState(() => paramValueType = 'descriptive'),
                      activeColor: null,
                      inactiveBg: null,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Unit/Qualitative selection
                if (paramValueType == 'numeric' ||
                    paramValueType == 'countPerHpf' ||
                    paramValueType == 'countPerLpf') ...[
                  const Text(
                    'Unit',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value:
                        (paramValueType == 'numeric'
                                ? numericUnits
                                : countUnits)
                            .contains(paramUnit)
                        ? paramUnit
                        : null,
                    decoration: inputDeco('Select Unit', Icons.straighten),
                    items:
                        (paramValueType == 'numeric'
                                ? numericUnits
                                : countUnits)
                            .toSet()
                            .toList()
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(
                                  u,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => paramUnit = v ?? ''),
                  ),
                  if (paramUnit == 'Others')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextFormField(
                        controller: customUnitCtrl,
                        decoration: inputDeco('Custom Unit', Icons.edit),
                      ),
                    ),
                ],
                if (paramValueType == 'qualitative' ||
                    paramValueType == 'normal') ...[
                  Text(
                    paramValueType == 'qualitative'
                        ? 'Normal Value'
                        : 'Standard Normal Value',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...qualitativeOptions.map(
                        (q) => chip(
                          q,
                          paramQualRef == q,
                          () => setState(() => paramQualRef = q),
                        ),
                      ),
                    ],
                  ),
                  if (paramQualRef == 'Others')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextFormField(
                        controller: customQualCtrl,
                        decoration: inputDeco('Custom Value', Icons.edit),
                      ),
                    ),
                ],
                if (paramValueType == 'descriptive') ...[
                  const Text(
                    'Brief Description',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: inputDeco(
                      'Enter parameter description...',
                      Icons.description_outlined,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Specimen',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: specimenTypes.take(10).map((s) {
                    return chip(
                      s,
                      paramSpecimen.toUpperCase() == s.toUpperCase(),
                      () => setState(() => paramSpecimen = s),
                      activeColor: null,
                      inactiveBg: null,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Reference ranges moved inside Add Parameter form
                if (paramValueType == 'numeric' ||
                    paramValueType == 'countPerHpf' ||
                    paramValueType == 'countPerLpf')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: sectionCard(
                      'Reference Ranges',
                      Icons.analytics,
                      _buildRefRangeForm(),
                      accent: purpleAccent,
                      trailing: refBadge(tempRefRanges),
                    ),
                  ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _addParameter,
                    icon: Icon(
                      editingParamIndex != null ? Icons.save : Icons.add,
                      color: Colors.white,
                    ),
                    label: Text(
                      editingParamIndex != null
                          ? 'Update Parameter'
                          : 'Add Parameter',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (editingParamIndex != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: dangerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _clearParamForm,
                      icon: const Icon(Icons.cancel, color: dangerColor),
                      label: const Text(
                        'Cancel Edit',
                        style: TextStyle(
                          color: dangerColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            accent: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildParamCard(int index, TestParameter param) {
    final isEditing = editingParamIndex == index;
    return GestureDetector(
      onTap: () => _loadParamForEdit(index, param),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEditing ? successColor.withValues(alpha: 0.05) : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEditing
                ? successColor
                : Colors.grey.withValues(alpha: 0.2),
            width: isEditing ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isEditing
                    ? successColor
                    : successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: isEditing
                    ? const Icon(Icons.edit, color: Colors.white, size: 16)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: successColor,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        param.name,
                        style: TextStyle(
                          fontWeight: isEditing
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 14,
                          color: isEditing ? successColor : Colors.black87,
                        ),
                      ),
                      if (isEditing) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: successColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'EDITING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${param.valueType.name.toUpperCase()} • ${param.unit.isNotEmpty ? param.unit : (param.qualitativeRef ?? '-')} • ₹${param.price}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if (param.referenceRanges.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Ranges: ${param.referenceRanges.entries.map((e) => "${keyLabel(e.key)}: ${e.value}").join(", ")}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: dangerColor,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  parameters.removeAt(index);
                  if (editingParamIndex == index) {
                    _clearParamForm();
                  } else if (editingParamIndex != null &&
                      editingParamIndex! > index) {
                    editingParamIndex = editingParamIndex! - 1;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefRangeForm() {
    final curKey = currentAgeRange == 'pregnant'
        ? 'pregnant'
        : (currentAgeRange != null
              ? '${currentAgeRange}_$currentGender'
              : null);
    final hasRangeForCurrent =
        curKey != null && tempRefRanges.containsKey(curKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Age Group',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ageRangeConfigs.map((a) {
            final aKey = a['key'] as String;
            final sel = currentAgeRange == aKey;
            final hasVal = tempRefRanges.keys.any((k) {
              if (k == 'pregnant' && aKey == 'pregnant') return true;
              if (k.contains('_')) {
                final ageKey = k.substring(0, k.lastIndexOf('_'));
                return ageKey == aKey;
              }
              return false;
            });
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  currentAgeRange = a['key'] as String;

                  // Smart load: if current gender has no data but others do, switch to one that does
                  String key = currentAgeRange == 'pregnant'
                      ? 'pregnant'
                      : '${currentAgeRange}_$currentGender';

                  if (!tempRefRanges.containsKey(key) &&
                      currentAgeRange != 'pregnant') {
                    const fallbackGenders = ['MF', 'M', 'F'];
                    for (final g in fallbackGenders) {
                      final testKey = '${currentAgeRange}_$g';
                      if (tempRefRanges.containsKey(testKey)) {
                        currentGender = g;
                        key = testKey;
                        break;
                      }
                    }
                  }

                  if (tempRefRanges.containsKey(key)) {
                    final val = tempRefRanges[key]!;
                    if (val.contains('-')) {
                      final parts = val.split('-');
                      refMinCtrl.text = parts[0];
                      refMaxCtrl.text = parts[1];
                    } else if (val.startsWith('≤')) {
                      refMinCtrl.clear();
                      refMaxCtrl.text = val.substring(1);
                    } else if (val.startsWith('≥')) {
                      refMinCtrl.text = val.substring(1);
                      refMaxCtrl.clear();
                    } else {
                      refMinCtrl.text = val;
                      refMaxCtrl.clear();
                    }
                  } else {
                    refMinCtrl.clear();
                    refMaxCtrl.clear();
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: sel
                      ? LinearGradient(
                          colors: hasVal
                              ? [
                                  successColor,
                                  successColor.withValues(alpha: 0.8),
                                ]
                              : [purpleAccent, const Color(0xFFA78BFA)],
                        )
                      : null,
                  color: sel ? null : (hasVal ? successColor : sectionBg),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sel
                        ? Colors.transparent
                        : (hasVal
                              ? successColor
                              : purpleAccent.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      a['icon'] as IconData,
                      size: 14,
                      color: sel || hasVal ? Colors.white : purpleAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      a['label'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: sel || hasVal ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (hasVal) ...[
                      const SizedBox(width: 4),
                      Icon(
                        sel ? Icons.edit : Icons.check_circle,
                        size: 12,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (currentAgeRange != null && currentAgeRange != 'pregnant') ...[
          const SizedBox(height: 12),
          const Text(
            'Gender',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _genderBtn('MF', 'All'),
              const SizedBox(width: 8),
              _genderBtn('M', 'Male'),
              const SizedBox(width: 8),
              _genderBtn('F', 'Female'),
            ],
          ),
        ],
        if (currentAgeRange != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: refMinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputDeco('Min', Icons.remove),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: refMaxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputDeco('Max', Icons.add),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: hasRangeForCurrent
                    ? successColor
                    : purpleAccent,
                side: BorderSide(
                  color: hasRangeForCurrent ? successColor : purpleAccent,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _addRefRange,
              icon: Icon(hasRangeForCurrent ? Icons.sync : Icons.add, size: 18),
              label: Text(hasRangeForCurrent ? 'Update Range' : 'Add Range'),
            ),
          ),
        ],
        if (tempRefRanges.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...tempRefRanges.entries.map((e) {
            final normKey = _normalizeAgeKey(e.key);
            final isCurrentEdit =
                (currentAgeRange != null) &&
                (normKey ==
                    (currentAgeRange == 'pregnant'
                        ? 'pregnant'
                        : '${currentAgeRange}_$currentGender'));

            return GestureDetector(
              onTap: () {
                // Trigger edit for this specific entry
                setState(() {
                  final normKey = _normalizeAgeKey(e.key);
                  if (normKey == 'pregnant') {
                    currentAgeRange = 'pregnant';
                    currentGender = 'F';
                  } else {
                    final parts = normKey.split('_');
                    if (parts.length >= 2) {
                      currentGender = parts.last;
                      currentAgeRange = parts
                          .sublist(0, parts.length - 1)
                          .join('_');
                    }
                  }

                  final val = e.value;
                  if (val.contains('-')) {
                    final parts = val.split('-');
                    refMinCtrl.text = parts[0];
                    refMaxCtrl.text = parts[1];
                  } else if (val.startsWith('≤')) {
                    refMinCtrl.clear();
                    refMaxCtrl.text = val.substring(1);
                  } else if (val.startsWith('≥')) {
                    refMinCtrl.text = val.substring(1);
                    refMaxCtrl.clear();
                  } else {
                    refMinCtrl.text = val;
                    refMaxCtrl.clear();
                  }
                });
                HapticFeedback.selectionClick();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isCurrentEdit
                      ? successColor.withValues(alpha: 0.15)
                      : successColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrentEdit
                        ? successColor
                        : successColor.withValues(alpha: 0.2),
                    width: isCurrentEdit ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCurrentEdit ? Icons.edit : Icons.check_circle_outline,
                      size: 14,
                      color: successColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${keyLabel(e.key)}: ${e.value}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrentEdit
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isCurrentEdit ? successColor : Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => tempRefRanges.remove(e.key)),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: dangerColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _genderBtn(String key, String label) {
    final sel = currentGender == key;
    final hasVal =
        currentAgeRange != null &&
        tempRefRanges.containsKey(
          currentAgeRange == 'pregnant'
              ? 'pregnant'
              : '${currentAgeRange}_$key',
        );

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            currentGender = key;
            // Auto-populate for editing if range exists for current age group/gender
            if (currentAgeRange != null) {
              final rangeKey = currentAgeRange == 'pregnant'
                  ? 'pregnant'
                  : '${currentAgeRange}_$currentGender';
              if (tempRefRanges.containsKey(rangeKey)) {
                final val = tempRefRanges[rangeKey]!;
                if (val.contains('-')) {
                  final parts = val.split('-');
                  refMinCtrl.text = parts[0];
                  refMaxCtrl.text = parts[1];
                } else if (val.startsWith('≤')) {
                  refMinCtrl.clear();
                  refMaxCtrl.text = val.substring(1);
                } else if (val.startsWith('≥')) {
                  refMinCtrl.text = val.substring(1);
                  refMaxCtrl.clear();
                } else {
                  refMinCtrl.text = val;
                  refMaxCtrl.clear();
                }
              } else {
                refMinCtrl.clear();
                refMaxCtrl.clear();
              }
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: sel
                ? LinearGradient(
                    colors: hasVal
                        ? [successColor, successColor.withValues(alpha: 0.8)]
                        : [accentColor, primaryLight],
                  )
                : null,
            color: sel
                ? null
                : (hasVal ? successColor.withValues(alpha: 0.1) : sectionBg),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: sel
                  ? Colors.transparent
                  : (hasVal ? successColor : Colors.transparent),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: sel
                        ? Colors.white
                        : (hasVal ? successColor : primaryColor),
                  ),
                ),
                if (hasVal && !sel) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle, size: 10, color: successColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 4: Review
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionCard(
            'Summary',
            Icons.summarize,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow(
                  'Type',
                  selectedType == 'TEST' ? 'Laboratory Test' : 'Medical Scan',
                ),
                if (selectedType == 'TEST') ...[
                  _summaryRow(
                    'Category',
                    selectedCategory == 'Other'
                        ? customCategoryCtrl.text.trim()
                        : selectedCategory,
                  ),
                  _summaryRow('Parameters', '${parameters.length}'),
                ] else ...[
                  _summaryRow(
                    'Scan',
                    selectedModality == 'Other'
                        ? customModalityCtrl.text.trim()
                        : selectedModality,
                  ),
                  _summaryRow(
                    'Option',
                    selectedRegion == 'Other'
                        ? customRegionCtrl.text.trim()
                        : selectedRegion,
                  ),
                  if (amountCtrl.text.isNotEmpty)
                    _summaryRow('Amount', amountCtrl.text),
                ],
                if (testNameCtrl.text.isNotEmpty)
                  _summaryRow('Name', testNameCtrl.text),
              ],
            ),
            accent: infoColor,
          ),

          if (selectedType == 'TEST' && parameters.isNotEmpty)
            sectionCard(
              'Parameters',
              Icons.list_alt,
              Column(
                children: parameters
                    .asMap()
                    .entries
                    .map((e) => _buildParamCard(e.key, e.value))
                    .toList(),
              ),
              accent: successColor,
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _prevStep,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    infoColor, //currentStep == 3 ? successColor : primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: currentStep == 3 ? _submit : _nextStep,
              icon: Icon(
                currentStep == 3 ? Icons.check_circle : Icons.arrow_forward,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                currentStep == 3 ? 'Create' : 'Next',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadHospital();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _pageController = PageController(initialPage: 0);
    fetchAllTestsScans();
  }

  Future<void> fetchAllTestsScans() async {
    try {
      final all = await TestAndScanService().fetchAll();

      //I/flutter (11223): all data: [{id: 2, hospital_Id: 1, title: EEG, type: SCAN, amount: 0, createdAt: 2025-11-10T07:54:46.918Z, updatedAt: 2025-11-10T07:54:46.918Z, options: [{id: 3, hospital_Id: 1, scanTestId: 2, optionName: SKULL, type: null, unit: -, price: 1000, reference: null, createdAt: 2025-11-10T07:54:46.918Z, updatedAt: 2025-11-10T07:54:46.918Z}]}, {id: 1, hospital_Id: 1, title: X-RAY, type: SCAN, amount: 0, createdAt: 2025-11-10T07:54:46.918Z, updatedAt: 2025-11-10T07:54:46.918Z, options: [{id: 1, hospital_Id: 1, scanTestId: 1, optionName: SKULL, type: , unit: -, price: 100, reference: null, createdAt: 2025-11-10T07:54:46.918Z, updatedAt: 2025-11-10T07:54:46.918Z}, {id: 2, hospital_Id: 1, scanTestId: 1, optionName: KUB, type: null, unit: -, price: 200, reference: null, createdAt: 2025-11-10T07:54:46.918Z, updatedAt: 2025-11-10T07:54:46.918Z}]}]
      final tests = <String>{};
      final scans = <String, Set<String>>{};
      final tIds = <String, int>{};
      final tParams = <String, List<TestParameter>>{};

      for (var item in all) {
        if (item is Map<String, dynamic>) {
          final type = item['type']?.toString();
          final title = item['title']?.toString();

          if (type == 'TEST' && title != null) {
            final upTitle = title.toUpperCase();
            tests.add(upTitle);
            final id = item['id'];
            if (id is int) tIds[upTitle] = id;

            // Check if it's a "custom" test (not in our static list)
            bool isStatic = false;
            for (var key in testCategoryDetails.keys) {
              if (key.toUpperCase() == upTitle) {
                isStatic = true;
                break;
              }
            }
            if (!isStatic && !extraTestCategories.contains(upTitle)) {
              extraTestCategories.add(upTitle);
            }

            final options = item['options'];
            if (options is List) {
              final List<TestParameter> params = [];
              for (var opt in options) {
                if (opt is Map<String, dynamic>) {
                  // Handle "TYPE-SPECIMEN" format
                  final fullType = opt['type']?.toString() ?? 'numeric';
                  String typeStr = fullType;
                  String specimen = opt['specimen']?.toString() ?? '';

                  if (fullType.contains('-')) {
                    final parts = fullType.split('-');
                    typeStr = parts[0].toLowerCase();
                    if (specimen.isEmpty) specimen = parts[1];
                  }

                  // Handle structured reference ranges
                  Map<String, String> refMap = {};
                  final dynamicRawRefs =
                      opt['reference'] ?? opt['referenceRanges'];
                  if (dynamicRawRefs is List) {
                    for (var r in dynamicRawRefs) {
                      if (r is Map) {
                        r.forEach((ageRangeLabel, genderData) {
                          // Standardize age part (e.g. "NEWBORN" -> "0_1")
                          final norm = _normalizeAgeKey(
                            ageRangeLabel.toString(),
                          );
                          final normalizedAge = norm.contains('_')
                              ? norm.split('_').take(2).join('_')
                              : norm;

                          if (genderData is Map) {
                            genderData.forEach((genderLabel, range) {
                              String gCode = 'MF';
                              final upG = genderLabel.toString().toUpperCase();
                              if (upG == 'MALE' || upG == 'M') {
                                gCode = 'M';
                              } else if (upG == 'FEMALE' || upG == 'F') {
                                gCode = 'F';
                              }

                              if (normalizedAge == 'pregnant') {
                                refMap['pregnant'] = range.toString();
                              } else {
                                refMap['${normalizedAge}_$gCode'] = range
                                    .toString();
                              }
                            });
                          } else {
                            // Fallback for simple key-value pairs
                            refMap[_normalizeAgeKey(ageRangeLabel.toString())] =
                                genderData.toString();
                          }
                        });
                      }
                    }
                  } else if (dynamicRawRefs is Map) {
                    dynamicRawRefs.forEach((k, v) {
                      refMap[_normalizeAgeKey(k.toString())] = v.toString();
                    });
                  }

                  params.add(
                    TestParameter(
                      name: opt['optionName']?.toString() ?? '',
                      subsection: opt['subsection']?.toString() ?? 'TOTAL',
                      valueType: ValueType.values.firstWhere(
                        (e) => e.name.toLowerCase() == typeStr.toLowerCase(),
                        orElse: () => ValueType.numeric,
                      ),
                      unit: opt['unit']?.toString() ?? '',
                      method: opt['method']?.toString() ?? '',
                      specimen: specimen,
                      price:
                          double.tryParse(opt['price']?.toString() ?? '0') ??
                          0.0,
                      referenceRanges: refMap,
                      qualitativeRef:
                          (opt['reference'] != null &&
                              opt['reference'] is String &&
                              (opt['reference'] as String).trim().isNotEmpty)
                          ? opt['reference'].toString()
                          : (opt['qualitativeRef'] != null &&
                                opt['qualitativeRef'].toString().isNotEmpty)
                          ? opt['qualitativeRef'].toString()
                          : null,
                    ),
                  );
                }
              }
              tParams[upTitle] = params;
            }
          } else if (type == 'SCAN' && title != null) {
            // Ensure the set exists
            if (!scans.containsKey(title)) {
              scans[title] = {};
            }
            if (!imagingModalities.containsKey(title) &&
                title != 'Other' &&
                !extraScanModalities.contains(title)) {
              extraScanModalities.add(title);
            }
            // Store ID and Options
            final id = item['id'];
            if (id != null) {
              existingScanIds[title] = id;
            }
            final options = item['options'];
            if (options is List) {
              existingScanOptions[title] = List<Map<String, dynamic>>.from(
                options,
              );
              for (var opt in options) {
                if (opt is Map<String, dynamic>) {
                  final optName = opt['optionName']?.toString();
                  final price = opt['price']?.toString();
                  if (optName != null) {
                    scans[title]!.add(optName);
                    if (price != null) {
                      if (!existingScanAmounts.containsKey(title)) {
                        existingScanAmounts[title] = {};
                      }
                      existingScanAmounts[title]![optName] = price;
                    }
                  }
                }
              }
            }
          }
        }
      }

      setState(() {
        existingTestCategories = tests;
        existingScanRegions = scans;
        existingTestIds = tIds;
        existingTestParameters = tParams;
      });
    } catch (e) {
      debugPrint('Error processing existing tests/scans: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    testNameCtrl.dispose();
    searchCtrl.dispose();
    paramNameCtrl.dispose();
    methodCtrl.dispose();
    customUnitCtrl.dispose();
    customQualCtrl.dispose();
    descCtrl.dispose();
    refMinCtrl.dispose();
    refMaxCtrl.dispose();
    customCategoryCtrl.dispose();
    customModalityCtrl.dispose();
    customRegionCtrl.dispose();
    amountCtrl.dispose();
    paramPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHospital() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hospitalName = prefs.getString('hospitalName') ?? hospitalName;
      hospitalPlace = prefs.getString('hospitalPlace') ?? hospitalPlace;
      hospitalPhoto = prefs.getString('hospitalPhoto') ?? "";
      hospitalId = prefs.getString('hospitalId') ?? "";
    });
  }
}
