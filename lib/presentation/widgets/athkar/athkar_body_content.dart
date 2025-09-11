import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/athkar/athkar_cubit.dart';
import 'package:huda/presentation/widgets/athkar/error_state.dart';
import 'package:huda/presentation/widgets/athkar/loaded_state_content.dart';
import 'package:huda/presentation/widgets/athkar/loading_state.dart';
import 'package:huda/presentation/widgets/athkar/offline_state.dart';

class AthkarBodyContent extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final String searchQuery;

  const AthkarBodyContent({
    super.key,
    required this.fadeAnimation,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: BlocBuilder<AthkarCubit, AthkarState>(
        builder: (context, state) {
          if (state is AthkarLoading) {
            return const LoadingState();
          } else if (state is AthkarLoaded) {
            return LoadedStateContent(
              fadeAnimation: fadeAnimation,
              athkarList: state.athkar,
              searchQuery: searchQuery,
            );
          } else if (state is AthkarOffline) {
            return const OfflineState();
          } else if (state is AthkarError) {
            return ErrorState(message: state.message);
          }
          return const SizedBox();
        },
      ),
    );
  }
}
