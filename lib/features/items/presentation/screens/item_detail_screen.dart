import 'package:flutter/material.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/theme/theme.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.tr(context, 'item_details'),
          style: AppTypography.bold(fontSize: 20, color: AppColors.fontColor),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 240,
              width: double.infinity,
              color: AppColors.black5,
              child: const Icon(
                Icons.image,
                size: 90,
                color: AppColors.hintColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.tr(context, 'item_name'),
                    style:
                        AppTypography.bold(fontSize: 24, color: AppColors.fontColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$100',
                    style:
                        AppTypography.bold(fontSize: 28, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.tr(context, 'description'),
                    style:
                        AppTypography.regular(fontSize: 16, color: AppColors.fontColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.tr(context, 'item_body'),
                    style:
                        AppTypography.regular(fontSize: 14, color: AppColors.hintColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
