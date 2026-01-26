import 'package:flutter/material.dart';

import '../../../../Mediacl_Staff/Pages/OutPatient/Page/InjectionPage.dart';

// ══════════════════════════════════════════════════════════════════════════════
// COLOR THEME
// ══════════════════════════════════════════════════════════════════════════════
const Color primaryLight = Color(0xFFBF955E);
const Color accentColor = Color(0xFFBF955E);
const Color bgGradientStart = Colors.white;
const Color bgGradientEnd = Colors.white;
const Color cardBg = Colors.white;
const Color sectionBg = Color(0xFFF0FDFA);
const Color dangerColor = Color(0xFFEF4444);
const Color warningColor = Color(0xFFF59E0B);
const Color successColor = Color(0xFF10B981);
const Color purpleAccent = Color(0xFF8B5CF6);
const Color infoColor = Color(0xFF3B82F6);

// ══════════════════════════════════════════════════════════════════════════════
// VALUE TYPES
// ══════════════════════════════════════════════════════════════════════════════
enum ValueType {
  numeric,
  qualitative,
  normal,
  countPerHpf,
  countPerLpf,
  descriptive,
  ratio,
  titer,
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPREHENSIVE TEST CATEGORIES (Global Standards)
// ══════════════════════════════════════════════════════════════════════════════
final Map<String, Map<String, dynamic>> testCategoryDetails = {
  // HEMATOLOGY
  'Complete Blood Count': const {
    'dept': 'Hematology',
    'icon': Icons.bloodtype,
    'subsections': ['HAEMATOLOGY'],
  },
  'Coagulation Profile': const {
    'dept': 'Hematology',
    'icon': Icons.water_drop,
    'subsections': ['HAEMATOLOGY'],
  },
  'ESR': const {
    'dept': 'Hematology',
    'icon': Icons.speed,
    'subsections': ['HAEMATOLOGY'],
  },
  'Peripheral Smear': const {
    'dept': 'Hematology',
    'icon': Icons.lens_blur,
    'subsections': ['HAEMATOLOGY'],
  },
  'Reticulocyte Count': const {
    'dept': 'Hematology',
    'icon': Icons.adjust,
    'subsections': ['HAEMATOLOGY'],
  },
  'Hemoglobin Electrophoresis': const {
    'dept': 'Hematology',
    'icon': Icons.electric_bolt,
    'subsections': ['HAEMATOLOGY'],
  },

  // BIOCHEMISTRY - METABOLIC
  'Blood Sugar': const {
    'dept': 'Biochemistry',
    'icon': Icons.medication_liquid,
    'subsections': ['BIOCHEMISTRY'],
  },
  'HbA1c': const {
    'dept': 'Biochemistry',
    'icon': Icons.donut_small,
    'subsections': ['BIOCHEMISTRY'],
  },
  'OGTT': const {
    'dept': 'Biochemistry',
    'icon': Icons.timeline,
    'subsections': ['BIOCHEMISTRY'],
  },

  // BIOCHEMISTRY - ORGAN FUNCTION
  'Liver Function Test': const {
    'dept': 'Biochemistry',
    'icon': Icons.spa,
    'subsections': ['BIOCHEMISTRY'],
  },
  'Kidney Function Test': const {
    'dept': 'Biochemistry',
    'icon': Icons.filter_alt,
    'subsections': ['BIOCHEMISTRY'],
  },
  'Lipid Profile': const {
    'dept': 'Biochemistry',
    'icon': Icons.water,
    'subsections': ['BIOCHEMISTRY'],
  },
  'Cardiac Markers': const {
    'dept': 'Biochemistry',
    'icon': Icons.favorite,
    'subsections': ['BIOCHEMISTRY'],
  },
  'Electrolytes': const {
    'dept': 'Biochemistry',
    'icon': Icons.bolt,
    'subsections': ['BIOCHEMISTRY'],
  },
  'Bone Profile': const {
    'dept': 'Biochemistry',
    'icon': Icons.architecture,
    'subsections': ['BIOCHEMISTRY'],
  },
  'Iron Studies': const {
    'dept': 'Biochemistry',
    'icon': Icons.iron,
    'subsections': ['BIOCHEMISTRY'],
  },
  'Pancreatic Enzymes': const {
    'dept': 'Biochemistry',
    'icon': Icons.bubble_chart,
    'subsections': ['BIOCHEMISTRY'],
  },

  // ENDOCRINE
  'Thyroid Profile': {
    'dept': 'Endocrinology',
    'icon': Icons.type_specimen_rounded,
    'subsections': const ['ENDOCRINOLOGY'],
  },
  'Hormone Panel': const {
    'dept': 'Endocrinology',
    'icon': Icons.science,
    'subsections': ['ENDOCRINOLOGY'],
  },
  'Cortisol': const {
    'dept': 'Endocrinology',
    'icon': Icons.tonality,
    'subsections': ['ENDOCRINOLOGY'],
  },
  'Insulin': const {
    'dept': 'Endocrinology',
    'icon': Icons.vaccines,
    'subsections': ['ENDOCRINOLOGY'],
  },
  'Fertility Hormones': const {
    'dept': 'Endocrinology',
    'icon': Icons.child_friendly,
    'subsections': ['ENDOCRINOLOGY'],
  },

  // IMMUNOLOGY/SEROLOGY
  'Hepatitis Panel': const {
    'dept': 'Serology',
    'icon': Icons.coronavirus,
    'subsections': ['SEROLOGY'],
  },
  'HIV Screening': const {
    'dept': 'Serology',
    'icon': Icons.shield,
    'subsections': ['SEROLOGY'],
  },
  'Autoimmune Markers': const {
    'dept': 'Immunology',
    'icon': Icons.security,
    'subsections': ['IMMUNOLOGY'],
  },
  'Allergy Panel': const {
    'dept': 'Immunology',
    'icon': Icons.grass,
    'subsections': ['IMMUNOLOGY'],
  },
  'Inflammatory Markers': const {
    'dept': 'Immunology',
    'icon': Icons.local_fire_department,
    'subsections': ['IMMUNOLOGY'],
  },
  'TORCH Panel': const {
    'dept': 'Serology',
    'icon': Icons.pregnant_woman,
    'subsections': ['SEROLOGY'],
  },

  // MICROBIOLOGY
  'Culture & Sensitivity': const {
    'dept': 'Microbiology',
    'icon': Icons.bug_report,
    'subsections': ['MICROBIOLOGY'],
  },
  'Gram Stain': const {
    'dept': 'Microbiology',
    'icon': Icons.colorize,
    'subsections': ['MICROBIOLOGY'],
  },
  'AFB': const {
    'dept': 'Microbiology',
    'icon': Icons.air,
    'subsections': ['MICROBIOLOGY'],
  },
  'Widal Test': const {
    'dept': 'Microbiology',
    'icon': Icons.thermostat,
    'subsections': ['SEROLOGY'],
  },

  // URINALYSIS
  'Urine Routine': const {
    'dept': 'Clinical Pathology',
    'icon': Icons.water_drop_outlined,
    'subsections': [
      'PHYSICAL EXAMINATION',
      'CHEMICAL EXAMINATION',
      'MICROSCOPIC EXAMINATION',
    ],
  },
  '24-Hour Urine': const {
    'dept': 'Clinical Pathology',
    'icon': Icons.timer,
    'subsections': ['BIOCHEMISTRY'],
  },
  'Urine Culture': const {
    'dept': 'Microbiology',
    'icon': Icons.science_outlined,
    'subsections': ['MICROBIOLOGY'],
  },

  // STOOL
  'Stool Routine': const {
    'dept': 'Clinical Pathology',
    'icon': Icons.opacity,
    'subsections': [
      'PHYSICAL EXAMINATION',
      'CHEMICAL EXAMINATION',
      'MICROSCOPIC EXAMINATION',
    ],
  },
  'Occult Blood': const {
    'dept': 'Clinical Pathology',
    'icon': Icons.search,
    'subsections': ['CHEMICAL EXAMINATION'],
  },
  'Stool Culture': const {
    'dept': 'Microbiology',
    'icon': Icons.biotech,
    'subsections': ['MICROBIOLOGY'],
  },

  // BODY FLUIDS
  'CSF Analysis': const {
    'dept': 'Clinical Pathology',
    'icon': Icons.water,
    'subsections': ['PHYSICAL', 'CHEMICAL', 'MICROSCOPIC'],
  },
  'Semen Analysis': const {
    'dept': 'Clinical Pathology',
    'icon': Icons.science,
    'subsections': ['PHYSICAL EXAMINATION', 'MICROSCOPIC EXAMINATION'],
  },
  'Synovial Fluid': const {
    'dept': 'Clinical Pathology',
    'icon': Icons.water,
    'subsections': ['PHYSICAL', 'CHEMICAL', 'MICROSCOPIC'],
  },
  'Pleural Fluid': const {
    'dept': 'Clinical Pathology',
    'icon': Icons.air,
    'subsections': ['PHYSICAL', 'CHEMICAL', 'MICROSCOPIC'],
  },
  'Ascitic Fluid': const {
    'dept': 'Clinical Pathology',
    'icon': Icons.waves,
    'subsections': ['PHYSICAL', 'CHEMICAL', 'MICROSCOPIC'],
  },

  // SPECIAL
  'Tumor Markers': const {
    'dept': 'Biochemistry',
    'icon': Icons.biotech,
    'subsections': ['BIOCHEMISTRY'],
  },
  'Drug Levels': const {
    'dept': 'Toxicology',
    'icon': Icons.medication,
    'subsections': ['TOXICOLOGY'],
  },
  'Vitamin Levels': const {
    'dept': 'Biochemistry',
    'icon': Icons.wb_sunny,
    'subsections': ['BIOCHEMISTRY'],
  },
  'Arterial Blood Gas': const {
    'dept': 'Biochemistry',
    'icon': Icons.air,
    'subsections': ['BIOCHEMISTRY'],
  },

  // OTHER
  'Other': const {'dept': 'Other', 'icon': Icons.more_horiz, 'subsections': []},
};

// Legacy format for backward compatibility
Map<String, List<String>> get testCategorySubsections =>
    testCategoryDetails.map(
      (key, value) =>
          MapEntry(key, List<String>.from(value['subsections'] as List)),
    );

// ══════════════════════════════════════════════════════════════════════════════
// IMAGING MODALITIES (Global Standards)
// ══════════════════════════════════════════════════════════════════════════════
const Map<String, Map<String, dynamic>> imagingModalities = {
  'X-RAY': {
    'icon': Icons.camera_alt,
    'regions': [
      'Chest PA',
      'Chest Lateral',
      'Abdomen',
      'Cervical Spine',
      'Thoracic Spine',
      'Lumbar Spine',
      'Skull',
      'Pelvis',
      'KUB',
      'Upper Limb',
      'Lower Limb',
      'Dental',
      'Other',
    ],
  },
  'CT SCAN': {
    'icon': Icons.donut_large,
    'regions': [
      'Brain Plain',
      'Brain with Contrast',
      'Chest',
      'HRCT Chest',
      'Abdomen',
      'Pelvis',
      'Whole Abdomen',
      'Spine',
      'CT Angiography',
      'CT Urography',
      'Virtual Colonoscopy',
      'PNS',
      'Temporal Bone',
      'Other',
    ],
  },
  'MRI': {
    'icon': Icons.blur_circular,
    'regions': [
      'Brain',
      'Brain with Contrast',
      'MR Angiography',
      'Cervical Spine',
      'Thoracic Spine',
      'Lumbar Spine',
      'Whole Spine',
      'Knee',
      'Shoulder',
      'Hip',
      'Wrist',
      'Ankle',
      'Cardiac MRI',
      'MRCP',
      'Abdomen',
      'Pelvis',
      'Breast',
      'Other',
    ],
  },
  'ULTRASOUND': {
    'icon': Icons.waves,
    'regions': [
      'Abdomen',
      'Pelvis',
      'KUB',
      'Thyroid',
      'Breast',
      'Scrotal',
      'Obstetric',
      'NT Scan',
      'Anomaly Scan',
      'Growth Scan',
      'Doppler - Arterial',
      'Doppler - Venous',
      'Echocardiography',
      'Carotid Doppler',
      'Musculoskeletal',
      'Small Parts',
      'Transvaginal',
      'Other',
    ],
  },
  'MAMMOGRAPHY': {
    'icon': Icons.adjust,
    'regions': [
      'Screening Bilateral',
      'Diagnostic',
      'Spot Compression',
      'Magnification',
      'With Biopsy Guidance',
      'Other',
    ],
  },
  'FLUOROSCOPY': {
    'icon': Icons.videocam,
    'regions': [
      'Barium Swallow',
      'Barium Meal',
      'Barium Follow Through',
      'Barium Enema',
      'HSG',
      'MCU/VCUG',
      'Fistulogram',
      'Other',
    ],
  },
  'NUCLEAR MEDICINE': {
    'icon': Icons.radio_button_checked,
    'regions': [
      'Thyroid Scan',
      'Whole Body Bone Scan',
      'DMSA Renal',
      'DTPA Renal',
      'Cardiac SPECT',
      'PET-CT',
      'Parathyroid',
      'GI Bleed Scan',
      'Lung V/Q',
      'Other',
    ],
  },
  'INTERVENTIONAL': {
    'icon': Icons.healing,
    'regions': [
      'Angiography',
      'Angioplasty',
      'PTBD',
      'Nephrostomy',
      'Biopsy',
      'Drainage',
      'Embolization',
      'TIPS',
      'Other',
    ],
  },
  'DEXA': {
    'icon': Icons.accessibility,
    'regions': ['Whole Body', 'Spine', 'Femur', 'Forearm', 'Other'],
  },
  'Other': {
    'icon': Icons.more_horiz,
    'regions': ['Other'],
  },
};

// Legacy format
List<String> get scanCategories => imagingModalities.keys.toList();

// ══════════════════════════════════════════════════════════════════════════════
// SPECIMEN TYPES
// ══════════════════════════════════════════════════════════════════════════════
const List<String> specimenTypes = [
  'Venous Blood',
  'Arterial Blood',
  'Capillary Blood',
  'Fasting Blood',
  'Random Blood',
  'Post-prandial Blood',
  'Serum',
  'Plasma',
  'Whole Blood',
  'EDTA Blood',
  'Citrated Blood',
  'Spot Urine',
  'Midstream Urine',
  'First Morning Urine',
  '24-Hour Urine',
  'Catheter Urine',
  'Stool',
  'CSF',
  'Synovial Fluid',
  'Pleural Fluid',
  'Ascitic Fluid',
  'Pericardial Fluid',
  'Semen',
  'Sputum',
  'BAL',
  'Throat Swab',
  'Nasal Swab',
  'Wound Swab',
  'Tissue Biopsy',
  'FNAC',
  'Bone Marrow',
  'Other',
];

// ══════════════════════════════════════════════════════════════════════════════
// UNITS (Comprehensive International Standards)
// ══════════════════════════════════════════════════════════════════════════════
const List<String> numericUnits = [
  // Concentration
  'g/dL',
  'mg/dL',
  'µg/dL',
  'ng/dL',
  'pg/mL',
  'ng/mL',
  'µg/mL',
  'g/L',
  'mg/L',
  'µg/L',
  'mmol/L', 'µmol/L', 'nmol/L', 'pmol/L', 'mEq/L',
  'IU/mL', 'mIU/mL', 'U/L', 'IU/L', 'kU/L',
  // Cells
  'cells/µL', 'cells/mm³', 'cells/L', '/µL', '/mm³',
  'x10³/µL', 'x10⁶/µL', 'x10⁹/L', 'x10¹²/L',
  'million/mL', 'million/µL',
  // Hematology
  'fL', 'pg', '%',
  // Time
  'sec', 'min', 'hours', 'days',
  // Ratios
  'ratio', 'INR', 'index',
  // Volume
  'mL', 'L', 'dL', 'mL/min', 'mL/min/1.73m²', 'L/min',
  // Speed/Rate
  'mm/hr', 'mm/1st hr', 'mm/2nd hr',
  // Pressure
  'mmHg', 'kPa',
  // Temperature
  '°C', '°F',
  // Weight/Mass
  'kg', 'g', 'mg', 'µg', 'ng', 'pg',
  // Specific Gravity
  'SG',
  // Custom
  'Others',
];

const List<String> countUnits = [
  '/hpf',
  '/lpf',
  '/µL',
  '/mm³',
  '/field',
  'Others',
];

// ══════════════════════════════════════════════════════════════════════════════
// QUALITATIVE OPTIONS
// ══════════════════════════════════════════════════════════════════════════════
const List<String> qualitativeOptions = [
  // Presence
  'Negative',
  'Positive',
  'Nil',
  'Absent',
  'Present',
  'Trace',
  '1+',
  '2+',
  '3+',
  '4+',
  // Appearance
  'Clear', 'Turbid', 'Slightly Turbid', 'Hazy', 'Cloudy',
  // Color - Urine
  'Pale Yellow',
  'Yellow',
  'Straw',
  'Dark Yellow',
  'Amber',
  'Orange',
  'Red',
  'Brown',
  'Colorless',
  // Color - Stool
  'Brown', 'Yellow-Brown', 'Green', 'Clay-Colored', 'Black', 'Maroon',
  // Consistency
  'Formed', 'Semi-formed', 'Soft', 'Loose', 'Watery', 'Mucoid',
  // Status
  'Normal', 'Abnormal', 'Reactive', 'Non-Reactive', 'Equivocal', 'Borderline',
  // Blood Type
  'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  // Organisms
  'Seen',
  'Not Seen',
  'Few',
  'Moderate',
  'Many',
  'Plenty',
  'Occasional',
  'Rare',
  'Numerous',
  // Custom
  'Others',
];

// ══════════════════════════════════════════════════════════════════════════════
// AGE RANGES FOR REFERENCE VALUES
// ══════════════════════════════════════════════════════════════════════════════
const List<Map<String, dynamic>> ageRangeConfigs = [
  {
    'key': '0_1',
    'label': 'Newborn',
    'desc': '0-1 mo',
    'icon': Icons.child_friendly,
  },
  {
    'key': '1_12',
    'label': 'Infant',
    'desc': '1-12 mo',
    'icon': Icons.baby_changing_station,
  },
  {
    'key': '12_72',
    'label': 'Toddler/Child',
    'desc': '1-6 yr',
    'icon': Icons.child_care,
  },
  {'key': '72_144', 'label': 'Child', 'desc': '6-12 yr', 'icon': Icons.face},
  {
    'key': '144_216',
    'label': 'Adolescent',
    'desc': '12-18 yr',
    'icon': Icons.person_outline,
  },
  {
    'key': '216_780',
    'label': 'Adult',
    'desc': '18-65 yr',
    'icon': Icons.person,
  },
  {'key': '780_0', 'label': 'Elderly', 'desc': '65+ yr', 'icon': Icons.elderly},
  {
    'key': 'pregnant',
    'label': 'Pregnant',
    'desc': '',
    'icon': Icons.pregnant_woman,
  },
];

// ══════════════════════════════════════════════════════════════════════════════
// QUICK TEMPLATES FOR COMMON TESTS
// ══════════════════════════════════════════════════════════════════════════════
const Map<String, List<Map<String, dynamic>>> testTemplates = {
  'Complete Blood Count': [
    {
      'name': 'Hemoglobin',
      'valueType': 'numeric',
      'unit': 'g/dL',
      'specimen': 'EDTA Blood',
      'refs': {'216_780_M': '13.5-17.5', '216_780_F': '12.0-16.0'},
    },
    {
      'name': 'RBC Count',
      'valueType': 'numeric',
      'unit': 'x10⁶/µL',
      'specimen': 'EDTA Blood',
      'refs': {'216_780_M': '4.5-5.5', '216_780_F': '4.0-5.0'},
    },
    {
      'name': 'WBC Count',
      'valueType': 'numeric',
      'unit': 'x10³/µL',
      'specimen': 'EDTA Blood',
      'refs': {'216_780_MF': '4.0-11.0'},
    },
    {
      'name': 'Platelet Count',
      'valueType': 'numeric',
      'unit': 'x10³/µL',
      'specimen': 'EDTA Blood',
      'refs': {'216_780_MF': '150-450'},
    },
    {
      'name': 'Hematocrit',
      'valueType': 'numeric',
      'unit': '%',
      'specimen': 'EDTA Blood',
      'refs': {'216_780_M': '40-54', '216_780_F': '36-48'},
    },
    {
      'name': 'MCV',
      'valueType': 'numeric',
      'unit': 'fL',
      'specimen': 'EDTA Blood',
      'refs': {'216_780_MF': '80-100'},
    },
    {
      'name': 'MCH',
      'valueType': 'numeric',
      'unit': 'pg',
      'specimen': 'EDTA Blood',
      'refs': {'216_780_MF': '27-32'},
    },
    {
      'name': 'MCHC',
      'valueType': 'numeric',
      'unit': 'g/dL',
      'specimen': 'EDTA Blood',
      'refs': {'216_780_MF': '32-36'},
    },
    {
      'name': 'RDW',
      'valueType': 'numeric',
      'unit': '%',
      'specimen': 'EDTA Blood',
      'refs': {'216_780_MF': '11.5-14.5'},
    },
    {
      'name': 'Neutrophils',
      'valueType': 'numeric',
      'unit': '%',
      'specimen': 'EDTA Blood',
      'refs': {'216_780_MF': '40-70'},
    },
    {
      'name': 'Lymphocytes',
      'valueType': 'numeric',
      'unit': '%',
      'specimen': 'EDTA Blood',
      'refs': {'216_780_MF': '20-45'},
    },
    {
      'name': 'Monocytes',
      'valueType': 'numeric',
      'unit': '%',
      'specimen': 'EDTA Blood',
      'refs': {'216_780_MF': '2-8'},
    },
    {
      'name': 'Eosinophils',
      'valueType': 'numeric',
      'unit': '%',
      'specimen': 'EDTA Blood',
      'refs': {'216_780_MF': '1-6'},
    },
    {
      'name': 'Basophils',
      'valueType': 'numeric',
      'unit': '%',
      'specimen': 'EDTA Blood',
      'refs': {'216_780_MF': '0-2'},
    },
  ],
  'Liver Function Test': [
    {
      'name': 'Total Bilirubin',
      'valueType': 'numeric',
      'unit': 'mg/dL',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '0.1-1.2'},
    },
    {
      'name': 'Direct Bilirubin',
      'valueType': 'numeric',
      'unit': 'mg/dL',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '0.0-0.3'},
    },
    {
      'name': 'AST (SGOT)',
      'valueType': 'numeric',
      'unit': 'U/L',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '0-40'},
    },
    {
      'name': 'ALT (SGPT)',
      'valueType': 'numeric',
      'unit': 'U/L',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '0-41'},
    },
    {
      'name': 'ALP',
      'valueType': 'numeric',
      'unit': 'U/L',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '44-147'},
    },
    {
      'name': 'GGT',
      'valueType': 'numeric',
      'unit': 'U/L',
      'specimen': 'Serum',
      'refs': {'216_780_M': '8-61', '216_780_F': '5-36'},
    },
    {
      'name': 'Total Protein',
      'valueType': 'numeric',
      'unit': 'g/dL',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '6.0-8.3'},
    },
    {
      'name': 'Albumin',
      'valueType': 'numeric',
      'unit': 'g/dL',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '3.5-5.0'},
    },
    {
      'name': 'Globulin',
      'valueType': 'numeric',
      'unit': 'g/dL',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '2.0-3.5'},
    },
    {
      'name': 'A:G Ratio',
      'valueType': 'numeric',
      'unit': 'ratio',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '1.0-2.5'},
    },
  ],
  'Kidney Function Test': [
    {
      'name': 'Blood Urea',
      'valueType': 'numeric',
      'unit': 'mg/dL',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '15-40'},
    },
    {
      'name': 'Creatinine',
      'valueType': 'numeric',
      'unit': 'mg/dL',
      'specimen': 'Serum',
      'refs': {'216_780_M': '0.7-1.3', '216_780_F': '0.6-1.1'},
    },
    {
      'name': 'BUN',
      'valueType': 'numeric',
      'unit': 'mg/dL',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '7-20'},
    },
    {
      'name': 'eGFR',
      'valueType': 'numeric',
      'unit': 'mL/min/1.73m²',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '>90'},
    },
    {
      'name': 'Uric Acid',
      'valueType': 'numeric',
      'unit': 'mg/dL',
      'specimen': 'Serum',
      'refs': {'216_780_M': '3.4-7.0', '216_780_F': '2.4-6.0'},
    },
  ],
  'Lipid Profile': [
    {
      'name': 'Total Cholesterol',
      'valueType': 'numeric',
      'unit': 'mg/dL',
      'specimen': 'Fasting Blood',
      'refs': {'216_780_MF': '<200'},
    },
    {
      'name': 'Triglycerides',
      'valueType': 'numeric',
      'unit': 'mg/dL',
      'specimen': 'Fasting Blood',
      'refs': {'216_780_MF': '<150'},
    },
    {
      'name': 'HDL Cholesterol',
      'valueType': 'numeric',
      'unit': 'mg/dL',
      'specimen': 'Fasting Blood',
      'refs': {'216_780_M': '>40', '216_780_F': '>50'},
    },
    {
      'name': 'LDL Cholesterol',
      'valueType': 'numeric',
      'unit': 'mg/dL',
      'specimen': 'Fasting Blood',
      'refs': {'216_780_MF': '<100'},
    },
    {
      'name': 'VLDL Cholesterol',
      'valueType': 'numeric',
      'unit': 'mg/dL',
      'specimen': 'Fasting Blood',
      'refs': {'216_780_MF': '<30'},
    },
    {
      'name': 'Total/HDL Ratio',
      'valueType': 'numeric',
      'unit': 'ratio',
      'specimen': 'Fasting Blood',
      'refs': {'216_780_MF': '<5.0'},
    },
  ],
  'Thyroid Profile': [
    {
      'name': 'TSH',
      'valueType': 'numeric',
      'unit': 'µIU/mL',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '0.4-4.0'},
    },
    {
      'name': 'Free T4',
      'valueType': 'numeric',
      'unit': 'ng/dL',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '0.8-1.8'},
    },
    {
      'name': 'Free T3',
      'valueType': 'numeric',
      'unit': 'pg/mL',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '2.3-4.2'},
    },
    {
      'name': 'Total T4',
      'valueType': 'numeric',
      'unit': 'µg/dL',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '5.0-12.0'},
    },
    {
      'name': 'Total T3',
      'valueType': 'numeric',
      'unit': 'ng/dL',
      'specimen': 'Serum',
      'refs': {'216_780_MF': '80-200'},
    },
  ],
  'Urine Routine': [
    {
      'name': 'Color',
      'valueType': 'qualitative',
      'qualRef': 'Pale Yellow',
      'specimen': 'Spot Urine',
      'subsection': 'PHYSICAL EXAMINATION',
    },
    {
      'name': 'Appearance',
      'valueType': 'qualitative',
      'qualRef': 'Clear',
      'specimen': 'Spot Urine',
      'subsection': 'PHYSICAL EXAMINATION',
    },
    {
      'name': 'Specific Gravity',
      'valueType': 'numeric',
      'unit': 'SG',
      'specimen': 'Spot Urine',
      'refs': {'216_780_MF': '1.005-1.030'},
      'subsection': 'PHYSICAL EXAMINATION',
    },
    {
      'name': 'pH',
      'valueType': 'numeric',
      'unit': '',
      'specimen': 'Spot Urine',
      'refs': {'216_780_MF': '5.0-8.0'},
      'subsection': 'CHEMICAL EXAMINATION',
    },
    {
      'name': 'Protein',
      'valueType': 'qualitative',
      'qualRef': 'Nil',
      'specimen': 'Spot Urine',
      'subsection': 'CHEMICAL EXAMINATION',
    },
    {
      'name': 'Glucose',
      'valueType': 'qualitative',
      'qualRef': 'Nil',
      'specimen': 'Spot Urine',
      'subsection': 'CHEMICAL EXAMINATION',
    },
    {
      'name': 'Ketones',
      'valueType': 'qualitative',
      'qualRef': 'Nil',
      'specimen': 'Spot Urine',
      'subsection': 'CHEMICAL EXAMINATION',
    },
    {
      'name': 'Blood',
      'valueType': 'qualitative',
      'qualRef': 'Nil',
      'specimen': 'Spot Urine',
      'subsection': 'CHEMICAL EXAMINATION',
    },
    {
      'name': 'Bilirubin',
      'valueType': 'qualitative',
      'qualRef': 'Nil',
      'specimen': 'Spot Urine',
      'subsection': 'CHEMICAL EXAMINATION',
    },
    {
      'name': 'Urobilinogen',
      'valueType': 'qualitative',
      'qualRef': 'Normal',
      'specimen': 'Spot Urine',
      'subsection': 'CHEMICAL EXAMINATION',
    },
    {
      'name': 'Nitrite',
      'valueType': 'qualitative',
      'qualRef': 'Negative',
      'specimen': 'Spot Urine',
      'subsection': 'CHEMICAL EXAMINATION',
    },
    {
      'name': 'Leukocyte Esterase',
      'valueType': 'qualitative',
      'qualRef': 'Negative',
      'specimen': 'Spot Urine',
      'subsection': 'CHEMICAL EXAMINATION',
    },
    {
      'name': 'RBCs',
      'valueType': 'countPerHpf',
      'unit': '/hpf',
      'specimen': 'Spot Urine',
      'refs': {'216_780_MF': '0-2'},
      'subsection': 'MICROSCOPIC EXAMINATION',
    },
    {
      'name': 'WBCs',
      'valueType': 'countPerHpf',
      'unit': '/hpf',
      'specimen': 'Spot Urine',
      'refs': {'216_780_MF': '0-5'},
      'subsection': 'MICROSCOPIC EXAMINATION',
    },
    {
      'name': 'Epithelial Cells',
      'valueType': 'qualitative',
      'qualRef': 'Few',
      'specimen': 'Spot Urine',
      'subsection': 'MICROSCOPIC EXAMINATION',
    },
    {
      'name': 'Casts',
      'valueType': 'qualitative',
      'qualRef': 'Nil',
      'specimen': 'Spot Urine',
      'subsection': 'MICROSCOPIC EXAMINATION',
    },
    {
      'name': 'Crystals',
      'valueType': 'qualitative',
      'qualRef': 'Nil',
      'specimen': 'Spot Urine',
      'subsection': 'MICROSCOPIC EXAMINATION',
    },
    {
      'name': 'Bacteria',
      'valueType': 'qualitative',
      'qualRef': 'Nil',
      'specimen': 'Spot Urine',
      'subsection': 'MICROSCOPIC EXAMINATION',
    },
  ],
};

// ══════════════════════════════════════════════════════════════════════════════
// TEST PARAMETER MODEL
// ══════════════════════════════════════════════════════════════════════════════
class TestParameter {
  String name;
  String subsection;
  ValueType valueType;
  String unit;
  String method;
  String specimen;
  double price;
  Map<String, String> referenceRanges;
  String? qualitativeRef;
  String? criticalLow;
  String? criticalHigh;

  TestParameter({
    required this.name,
    required this.subsection,
    required this.valueType,
    this.unit = '',
    this.method = '',
    this.specimen = '',
    this.price = 0.0,
    Map<String, String>? referenceRanges,
    this.qualitativeRef,
    this.criticalLow,
    this.criticalHigh,
  }) : referenceRanges = referenceRanges ?? {};

  Map<String, dynamic> toJson() {
    // Helper to stringify reference ranges for the single 'reference' string column
    dynamic refData = (qualitativeRef ?? '').toUpperCase();

    // Check if we have numeric ranges to format as JSON
    if ((valueType == ValueType.numeric ||
            valueType == ValueType.countPerHpf ||
            valueType == ValueType.countPerLpf) &&
        referenceRanges.isNotEmpty) {
      // Match user's desired format: [{"INFANT": {"ALL": "10-20"}}, ...]
      final List<Map<String, Map<String, String>>> jsonList = [];
      final Map<String, Map<String, String>> grouped = {};

      for (var entry in referenceRanges.entries) {
        final k = entry.key; // e.g. 0_1_M, 1_12_MF, or pregnant
        final v = entry.value;

        String ageBase = k;
        String genderCode = 'MF';

        if (k == 'pregnant') {
          ageBase = 'pregnant';
          genderCode = 'F';
        } else if (k.contains('_')) {
          final parts = k.split('_');
          if (parts.length >= 3) {
            ageBase = '${parts[0]}_${parts[1]}';
            genderCode = parts[2];
          } else if (parts.length == 2 &&
              (parts[1] == 'MF' || parts[1] == 'M' || parts[1] == 'F')) {
            ageBase = parts[0];
            genderCode = parts[1];
          }
        }

        // Get descriptive label for the age group
        String ageLabel = ageBase.toUpperCase();
        try {
          final config = ageRangeConfigs.firstWhere(
            (a) => a['key'] == ageBase,
            orElse: () => {'label': ageBase},
          );
          ageLabel =
              config['label']?.toString().toUpperCase() ??
              ageBase.toUpperCase();
        } catch (_) {}

        final String gLabel = genderCode == 'MF'
            ? 'ALL'
            : (genderCode == 'M' ? 'MALE' : 'FEMALE');

        if (!grouped.containsKey(ageLabel)) {
          grouped[ageLabel] = {};
        }
        grouped[ageLabel]![gLabel] = v;
      }

      grouped.forEach((label, genders) {
        jsonList.add({label: genders});
      });

      if (jsonList.isNotEmpty) {
        refData = jsonList;
      }
    }

    return {
      'name': name.toUpperCase(),
      'optionName': name.toUpperCase(),
      'subsection': subsection.toUpperCase(),
      'valueType': valueType.name,
      'type':
          '${valueType.name.toUpperCase()}-${specimen.toUpperCase()}', // Requested format
      'price': price,
      'unit': unit.toUpperCase(),
      'method': method.toUpperCase(),
      'specimen': specimen.toUpperCase(),
      'reference': refData,
      'referenceRanges':
          valueType == ValueType.numeric ||
              valueType == ValueType.countPerHpf ||
              valueType == ValueType.countPerLpf
          ? referenceRanges
          : {},
      'qualitativeRef': (qualitativeRef ?? '').toUpperCase(),
      'criticalLow': (criticalLow ?? '').toUpperCase(),
      'criticalHigh': (criticalHigh ?? '').toUpperCase(),
    };
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ══════════════════════════════════════════════════════════════════════════════
void showSnack(
  String msg, {
  bool error = false,
  required BuildContext context,
}) {
  final overlay = Overlay.of(context);

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 64,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedSlide(
          offset: const Offset(0, 0),
          duration: const Duration(milliseconds: 250),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: error ? dangerColor : successColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  error ? Icons.warning : Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  Future.delayed(const Duration(seconds: 3), () {
    entry.remove();
  });
}

InputDecoration inputDeco(String label, IconData icon) => InputDecoration(
  labelText: label,
  prefixIcon: Container(
    margin: const EdgeInsets.all(8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: primaryColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, color: primaryColor, size: 18),
  ),
  filled: true,
  fillColor: sectionBg.withValues(alpha: 0.5),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.15)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: primaryColor, width: 2),
  ),
);

Widget sectionCard(
  String title,
  IconData icon,
  Widget child, {
  Color? accent,
  Widget? trailing,
}) {
  final c = accent ?? primaryColor;
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: c.withValues(alpha: 0.1)),
      boxShadow: [
        BoxShadow(
          color: c.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.withValues(alpha: 0.08), c.withValues(alpha: 0.02)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c, c.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.all(16), child: child),
      ],
    ),
  );
}

Widget chip(
  String label,
  bool selected,
  VoidCallback onTap, {
  Color? activeColor,
  Color? inactiveBg,
}) {
  final c = activeColor ?? primaryColor;
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(colors: [c, c.withValues(alpha: 0.8)])
            : null,
        color: selected ? null : (inactiveBg ?? sectionBg),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? Colors.transparent : c.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: (selected || (inactiveBg != null && inactiveBg != sectionBg))
              ? Colors.white
              : c,
        ),
      ),
    ),
  );
}

PreferredSizeWidget buildAppBar(
  BuildContext context, {
  String title = 'Create Test / Scan',
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(65),
    child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryColor, primaryLight]),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget buildHospitalCard({
  required String hospitalName,
  required String hospitalPlace,
  required String hospitalPhoto,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [primaryColor, primaryLight]),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: hospitalPhoto.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    hospitalPhoto,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.local_hospital, color: primaryColor),
                  ),
                )
              : const Icon(Icons.local_hospital, color: primaryColor, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hospitalName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      hospitalPlace,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget refBadge(Map<String, String> tempRefRanges) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: tempRefRanges.isNotEmpty
        ? successColor.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
    '${tempRefRanges.length}',
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: tempRefRanges.isNotEmpty ? successColor : Colors.grey,
    ),
  ),
);

String keyLabel(String key) {
  if (key == 'pregnant') return 'Pregnant';
  final parts = key.split('_');

  String label = key;
  String genderCode = 'MF';

  if (parts.length >= 3) {
    // Standard format: 0_1_M
    final ageKey = '${parts[0]}_${parts[1]}';
    final config = ageRangeConfigs.firstWhere(
      (a) => a['key'] == ageKey,
      orElse: () => {'label': ageKey},
    );
    label = config['label']?.toString() ?? ageKey;
    genderCode = parts[2];
  } else if (parts.length == 2) {
    // Possible formats: NEWBORN_M, 0_1_F (if split weirdly), or custom keys
    final config = ageRangeConfigs.firstWhere(
      (a) => a['key'] == key, // might be 0_1
      orElse: () => {'label': ''},
    );

    if (config['label'] != '') {
      label = config['label'];
    } else {
      // Check if second part is a gender
      final possibleG = parts[1].toUpperCase();
      if (['M', 'F', 'MF', 'MALE', 'FEMALE', 'ALL'].contains(possibleG)) {
        genderCode = (possibleG == 'M' || possibleG == 'MALE')
            ? 'M'
            : ((possibleG == 'F' || possibleG == 'FEMALE') ? 'F' : 'MF');
        label = parts[0];
      }
    }
  }

  // Prettify label
  label = label[0].toUpperCase() + label.substring(1).toLowerCase();
  if (label.contains('_')) label = label.replaceAll('_', ' ');

  final g = genderCode == 'MF'
      ? 'All'
      : (genderCode == 'M' ? 'Male' : 'Female');
  return '$label ($g)';
}

// Step indicator for wizard
Widget buildStepIndicator(int currentStep, List<String> steps) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Expanded(
            child: Container(
              height: 3,
              color: index ~/ 2 < currentStep
                  ? successColor
                  : Colors.grey.shade300,
            ),
          );
        }
        final stepIndex = index ~/ 2;
        final isActive = stepIndex == currentStep;
        final isCompleted = stepIndex < currentStep;
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive || isCompleted
                ? const LinearGradient(colors: [successColor, successColor])
                : null,
            color: isActive || isCompleted ? null : Colors.grey.shade200,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
          ),
        );
      }),
    ),
  );
}

// Category card with icon
Widget buildCategoryCard(
  String name,
  IconData icon,
  bool isSelected,
  VoidCallback onTap, {
  String? subtitle,
  Color? color,
}) {
  final c = color ?? primaryColor;
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(colors: [c, c.withValues(alpha: 0.8)])
            : null,
        color: isSelected ? null : cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.transparent : c.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: c.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.white : c, size: 28),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget previewRow(String label, dynamic value, {bool isBold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(
          value?.toString() ?? '-',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
            color: isBold ? successColor : primaryColor,
          ),
        ),
      ],
    ),
  );
}

Widget buildStep1(
  String hospitalName,
  String hospitalPlace,
  String hospitalPhoto,
  Widget Function(String type, IconData icon, String title, String subtitle)
  buildTypeCard,
) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        buildHospitalCard(
          hospitalName: hospitalName,
          hospitalPlace: hospitalPlace,
          hospitalPhoto: hospitalPhoto,
        ),
        sectionCard(
          'Select Type',
          Icons.category,
          Column(
            children: [
              const Text(
                'What would you like to create?',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: buildTypeCard(
                      'TEST',
                      Icons.science,
                      'Laboratory Test',
                      'Blood tests, urine tests, etc.',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: buildTypeCard(
                      'SCAN',
                      Icons.document_scanner,
                      'Medical Scan',
                      'X-Ray, CT, MRI, Ultrasound',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
