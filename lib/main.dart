import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/routes/page_router.dart';
import 'package:huda/core/services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  await getIt<CacheHelper>().init();
  runApp(MyApp(
    pageRouter: PageRouter(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.pageRouter});
  final PageRouter pageRouter;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: pageRouter.generateRoute,
    );
  }
}
