import 'package:flutter/material.dart';
import 'package:rashed_app/core/theme/theme.dart';
import 'item_detail_screen.dart';

class ItemListScreen extends StatelessWidget {
  const ItemListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'العناصر',
          style: AppTypography.bold(fontSize: 20, color: AppColors.fontColor),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 20,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              tileColor: AppColors.inputBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                'Item ${index + 1}',
                style:
                    AppTypography.bold(fontSize: 16, color: AppColors.fontColor),
              ),
              subtitle: Text(
                'Description for item ${index + 1}',
                style:
                    AppTypography.regular(fontSize: 14, color: AppColors.hintColor),
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ItemDetailScreen()),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
