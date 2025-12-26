import 'package:flutter/material.dart';
import '../../../../Services/cosmetic_Service.dart';

class OtherCard extends StatefulWidget {
  final Function(List<Map<String, dynamic>>)? onAdd;

  const OtherCard({super.key, this.onAdd});

  @override
  State<OtherCard> createState() => _OtherCardState();
}

class _OtherCardState extends State<OtherCard> {
  final TextEditingController searchController = TextEditingController();
  final CosmeticService service = CosmeticService();

  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> addedProducts = [];

  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchCosmetics();
  }

  Future<void> fetchCosmetics() async {
    try {
      final data = await service.getAllCosmetics();
      setState(() {
        allProducts = List<Map<String, dynamic>>.from(data);
        filteredProducts = allProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void filterProducts(String query) {
    setState(() {
      filteredProducts = allProducts
          .where(
            (p) => p['name'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  // ✅ ADD OR INCREASE QTY (NO CONFIRMATION)
  void addProduct(Map<String, dynamic> product) {
    final index = addedProducts.indexWhere((p) => p['id'] == product['id']);

    setState(() {
      if (index >= 0) {
        addedProducts[index]['qty'] += 1;
      } else {
        addedProducts.add({...product, "qty": 1});
      }
    });

    widget.onAdd?.call(addedProducts);
  }

  // 🗑️ REMOVE ITEM
  void removeProduct(int index) {
    setState(() {
      addedProducts.removeAt(index);
    });
    widget.onAdd?.call(addedProducts);
  }

  Widget _productImage(String? url) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: url == null || url.isEmpty
          ? const Icon(Icons.spa, color: Colors.blue)
          : ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.blue),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    return SafeArea(
      child: Column(
        children: [
          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: searchController,
              onChanged: filterProducts,
              decoration: InputDecoration(
                hintText: "Search cosmetics",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 🧾 ADDED SUMMARY (WITH DELETE)
          if (addedProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: Card(
                  elevation: 5,
                  shadowColor: Colors.blue.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.receipt_long, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  "Added Items",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${addedProducts.length} items",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ITEM LIST
                        ...addedProducts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final qty = item['qty'] as int;
                          final price = (item['amount'] as num).toDouble();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                // Bullet
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Name
                                Expanded(
                                  child: Text(
                                    item['name'],
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),

                                // Qty
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "× $qty",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Price
                                Text(
                                  "₹${(price * qty).toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(width: 6),

                                // 🗑️ DELETE ICON
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => removeProduct(index),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 10),
                        const Divider(),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Tap + to increase quantity",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // 📦 PRODUCT LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final item = filteredProducts[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: _productImage(item['imageUrl']),
                      title: Text(
                        item['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "${item['type']} • ${item['unit']}\n₹${item['amount']}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.green,
                          size: 32,
                        ),
                        onPressed: () => addProduct(item), // ✅ DIRECT ADD
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
