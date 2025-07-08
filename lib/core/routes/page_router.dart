import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/cubit/quran/quran_cubit.dart';
import 'package:huda/presentation/screens/home_quran.dart';

class PageRouter {
  Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoute.home:
        return MaterialPageRoute(
          builder: (_) => BlocProvider<QuranCubit>(
            create: (context) => QuranCubit(),
            child: HomeQuran(),
          ),
        );
    }
    return null;
  }
}
