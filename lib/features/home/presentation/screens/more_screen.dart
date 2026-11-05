import 'package:flutter/material.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/theme/theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.tr(context, 'more'),
          style: AppTypography.bold(fontSize: 20, color: AppColors.fontColor),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(AppLocalizations.tr(context, 'cv_title')),
            onTap: () => Navigator.pushNamed(context, RoutesName.profile),
          ),
          ListTile(
            title: Text(AppLocalizations.tr(context, 'cv_result_title')),
            onTap: () => Navigator.pushNamed(context, RoutesName.completeProfile),
          ),
        ],
      ),
    );
  }
}
