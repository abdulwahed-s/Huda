import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/hadith_details/hadith_details_cubit.dart';
import 'package:huda/presentation/screens/hadith_chapters.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/hadith/hadith_refs.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_reader.dart';

class HadithDetails extends StatefulWidget {
  const HadithDetails({
    super.key,
    required this.chapterNumber,
    required this.bookName,
    required this.chapterName,
    this.collectionTitle,
  });

  final String chapterNumber;

  final String bookName;

  final String chapterName;

  final String? collectionTitle;

  static Widget page({
    required String chapterNumber,
    required String bookName,
    required String chapterName,
    String? collectionTitle,
  }) => BlocProvider<HadithDetailsCubit>(
    create: (_) =>
        HadithChapters.createDetailsCubit()
          ..fetchHadithDetails(chapterNumber, bookName, 1),
    child: HadithDetails(
      chapterNumber: chapterNumber,
      bookName: bookName,
      chapterName: chapterName,
      collectionTitle: collectionTitle,
    ),
  );

  @override
  State<HadithDetails> createState() => _HadithDetailsState();
}

class _HadithDetailsState extends State<HadithDetails> {
  final _memory = HadithReaderMemory();

  @override
  Widget build(BuildContext context) {
    final collection = HadithCollectionRef(
      slug: widget.bookName,
      title: widget.collectionTitle ?? widget.bookName,
    );
    return HudaRevealScope(
      child: HudaScaffold(
        title: collection.title,
        body: HadithReader(
          collection: collection,
          book: HadithBookRef(
            number: widget.chapterNumber,
            title: widget.chapterName,
          ),
          memory: _memory,
        ),
      ),
    );
  }
}
