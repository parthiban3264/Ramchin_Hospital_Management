import 'package:flutter/material.dart';
import 'package:hospitrax/Admin/Pages/admin_edit_profile_page.dart';

import 'bulk_existing_batch.dart';
import 'bulk_upload_exist.dart';

class BulkUploadExistTabsPage extends StatelessWidget {
  const BulkUploadExistTabsPage({super.key});

  static const Color royal = primaryColor;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: royal,
            child: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: "Medicine Wise"),
                Tab(text: "Batch Wise"),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                BulkUploadMedicineExistPage(),
                BulkUploadExistBatchPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
