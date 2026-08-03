import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/app_review_service.dart';
import 'package:huda/cubit/rating/rating_cubit.dart';
import 'package:huda/presentation/widgets/rating/app_rating_dialog.dart';

class RatingService {
  static RatingService? _instance;
  Future<void>? _activeDialogRequest;

  RatingService._internal();

  static RatingService get instance {
    _instance ??= RatingService._internal();
    return _instance!;
  }

  Future<void> checkAndShowRatingDialog(BuildContext context) {
    return _runExclusively(() async {
      try {
        final ratingCubit = context.read<RatingCubit>();
        await ratingCubit.checkIfShouldShowDialog();

        final state = ratingCubit.state;
        if (context.mounted && state is RatingReady && state.shouldShow) {
          await _showRatingDialog(context);
        }
      } catch (e) {
        debugPrint('RatingService error: $e');
      }
    });
  }

  Future<void> showRatingDialog(BuildContext context) {
    return _runExclusively(
      () => _showRatingDialog(context, showDismissActions: false),
    );
  }

  Future<void> _runExclusively(Future<void> Function() action) {
    final activeRequest = _activeDialogRequest;
    if (activeRequest != null) return activeRequest;

    final request = Future.sync(action);
    _activeDialogRequest = request;
    return request.whenComplete(() {
      if (identical(_activeDialogRequest, request)) {
        _activeDialogRequest = null;
      }
    });
  }

  Future<void> _showRatingDialog(BuildContext context,
      {bool showDismissActions = true}) async {
    if (!context.mounted) return;

    final ratingCubit = context.read<RatingCubit>();
    await showDialog<void>(
      context: context,
      barrierDismissible: !showDismissActions,
      builder: (_) {
        return BlocProvider.value(
          value: ratingCubit,
          child: AppRatingDialog(showDismissActions: showDismissActions),
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
      await AppReviewService.reset();
    } catch (e) {
      debugPrint('RatingService resetRatingPreferences error: $e');
    }
  }
}
