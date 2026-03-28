import 'package:flutter/material.dart';

import '../../Pages/NotificationsPage.dart';

class FlowChartInstructionPage extends StatefulWidget {
  const FlowChartInstructionPage({super.key});

  @override
  State<FlowChartInstructionPage> createState() =>
      _FlowChartInstructionPageState();
}

class _FlowChartInstructionPageState extends State<FlowChartInstructionPage> {
  List<RowItem> allItems = [
    RowItem(
      image: "assets/instruction_buttons/reg.jpeg",
      title: "Register",
      description:
          "To register a patient, enter basic details like mobile number, name, gender, and address. Fields marked with * are required. You can also use the microphone icon to enter details by voice.\n\n"
          "If needed, add medical information such as emergency case, sugar test, blood group, and the patient’s problem.\n\n"
          "Next, choose a doctor from the list. Make sure the correct doctor is selected.\n\n"
          "Then tap the 'Register Patient' button to complete the process. The patient will be saved successfully.\n\n"
          "Make sure all required details are filled correctly before submitting. An internet connection may be needed. You can view and manage patients later in the app.",
    ),
    RowItem(
      image: "assets/instruction_buttons/vitals.jpeg",
      title: "vitals",
      description: "Use this button to login and access your dashboard.",
    ),
    RowItem(
      image: "assets/instruction_buttons/patientQueue.jpeg",
      title: "Patient Queue",
      description: "Manage your profile settings and update your information.",
    ),
    RowItem(
      image: "assets/instruction_buttons/injection.jpeg",
      title: "Injection",
      description:
          "Submit your data after completing all required step.Submit your data after completing all required steps.Submit your data after completing all required steps.Submit your data after completing all required steps.",
    ),
  ];

  List<RowItem> filteredItems = [];
  Set<int> expandedIndexes = {};

  @override
  void initState() {
    super.initState();
    filteredItems = allItems;
  }

  void searchItems(String query) {
    final results = allItems.where((item) {
      return item.title.toLowerCase().contains(query.toLowerCase()) ||
          item.description.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredItems = results;
    });
  }

  /// FULL SCREEN FLOWCHART VIEWER
  void openFlowChart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SafeArea(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Image.asset("assets/flowchart.png"),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Color(0xFFBF955E),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Flow & Instructions",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            /// FLOWCHART IMAGE (CLICKABLE)
            GestureDetector(
              onTap: () => openFlowChart(context),
              child: Container(
                margin: const EdgeInsets.all(16),
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    "assets/flowchart.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            /// SEARCH BOX
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: searchItems,
                decoration: InputDecoration(
                  hintText: "Search Buttons Instr...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// SECTION TITLE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Buttons & Description",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// FILTERED LIST
            Column(
              children: List.generate(filteredItems.length, (index) {
                final item = filteredItems[index];
                bool isEven = index % 2 == 0;

                Widget imageBox = GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${item.title} clicked")),
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(item.image!, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                );

                Widget description = Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),

                        /// DESCRIPTION TEXT
                        Text(
                          item.description,
                          maxLines: expandedIndexes.contains(index) ? null : 2,
                          overflow: expandedIndexes.contains(index)
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),

                        /// READ MORE / LESS BUTTON
                        if (item.description.length > 60) // optional condition
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (expandedIndexes.contains(index)) {
                                  expandedIndexes.remove(index);
                                } else {
                                  expandedIndexes.add(index);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                expandedIndexes.contains(index)
                                    ? "Read Less"
                                    : "Read More",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
                ;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // ✅ ADD THIS
                    children: isEven
                        ? [imageBox, const SizedBox(width: 12), description]
                        : [description, const SizedBox(width: 12), imageBox],
                  ),
                );
              }),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class RowItem {
  final String title;
  final String description;
  final String? image;

  RowItem({required this.title, required this.description, this.image});
}
