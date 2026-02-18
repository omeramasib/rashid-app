import 'package:flutter/material.dart';
import 'package:rashed_app/core/theme/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'الإشعارات',
          style: AppTypography.bold(fontSize: 20, color: AppColors.fontColor),
        ),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          final isUnread = index < 3;
          return Container(
            color: isUnread ? AppColors.inputBg : AppColors.white,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.notifications, color: AppColors.white),
              ),
              title: Text(
                'إشعار ${index + 1}',
                style: AppTypography.bold(fontSize: 16, color: AppColors.fontColor),
              ),
              subtitle: Text(
                'هذا نص إشعار تجريبي رقم ${index + 1}',
                style:
                    AppTypography.regular(fontSize: 14, color: AppColors.hintColor),
              ),
              trailing: isUnread
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
