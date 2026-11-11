import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/theme/theme.dart';
import 'package:rashed_app/features/auth/presentation/cubit/profile/auth_profile_cubit.dart';
import 'package:rashed_app/features/auth/presentation/cubit/profile/auth_profile_state.dart';

class ConnectedAccountsSheet extends HookWidget {
  const ConnectedAccountsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final password = useTextEditingController();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: BlocConsumer<AuthProfileCubit, AuthProfileState>(
        listener: (context, state) {
          if (state is AuthProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.message(context, state.message),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final linked =
              state is AuthProfileLoaded && state.user.linkedinLinked;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.tr(context, 'connected_accounts'),
                key: const Key('connected_accounts_title'),
                style: AppTypography.bold(
                  fontSize: 18,
                  color: AppColors.fontColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.tr(
                  context,
                  linked ? 'linkedin_linked_status' : 'linkedin_not_linked',
                ),
                key: const Key('linkedin_link_status'),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('linkedin_current_password'),
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.tr(context, 'current_password'),
                ),
              ),
              const SizedBox(height: 16),
              if (state is AuthProfileLoading)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton(
                  key: const Key('connect_linkedin'),
                  onPressed: () {
                    context.read<AuthProfileCubit>().connectLinkedIn(
                          context,
                          password.text,
                        );
                  },
                  child: Text(
                    AppLocalizations.tr(context, 'login_with_linkedin'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
