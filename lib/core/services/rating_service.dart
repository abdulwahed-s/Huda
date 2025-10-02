import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/rating/rating_cubit.dart';
import 'package:huda/presentation/widgets/rating/app_rating_dialog.dart';

class RatingService {
  static RatingService? _instance;
  RatingService._internal();

  static RatingService get instance {
    _instance ??= RatingService._internal();
    return _instance!;
  }

  Future<void> checkAndShowRatingDialog(BuildContext context) async {
    try {
      final ratingCubit = context.read<RatingCubit>();
      await ratingCubit.checkIfShouldShowDialog();

      final state = ratingCubit.state;
      if (state is RatingReady && state.shouldShow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            _showRatingDialog(context);
          }
        });
      }
    } catch (e) {
      debugPrint('RatingService error: $e');
    }
  }

  void showRatingDialog(BuildContext context) {
    _showRatingDialog(context);
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: context.read<RatingCubit>(),
          child: const AppRatingDialog(),
        );
      },
    );
  }

  Future<bool> shouldShowRating(BuildContext context) async {
    try {
      final ratingCubit = context.read<RatingCubit>();
      await ratingCubit.checkIfShouldShowDialog();

      final state = ratingCubit.state;
      return state is RatingReady && state.shouldShow;
    } catch (e) {
      debugPrint('RatingService shouldShowRating error: $e');
      return false;
    }
  }

  Future<void> resetRatingPreferences(BuildContext context) async {
    try {
      final ratingCubit = context.read<RatingCubit>();

      await ratingCubit.rateMyApp.reset();
    } catch (e) {
      debugPrint('RatingService resetRatingPreferences error: $e');
    }
  }
}
