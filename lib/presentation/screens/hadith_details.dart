import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/hadith_details/hadith_details_cubit.dart';
import 'package:huda/presentation/screens/hadith_chapters.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/hadith/hadith_refs.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_reader.dart';

/// A book's hadith on a page of its own, for `AppRoute.hadithDetails`.
/// The collection screen opens books inside itself (pushed on phones, in
/// its reader pane on wide windows); this is the same reader for other
/// callers. Standard tier.
class HadithDetails extends StatefulWidget {
  const HadithDetails({
    super.key,
    required this.chapterNumber,
    required this.bookName,
    required this.chapterName,
    this.collectionTitle,
  });

  /// The book's number in the collection.
  final String chapterNumber;

  /// The collection's slug.
  final String bookName;

  /// The book's name.
  final String chapterName;

  /// The collection's name; the slug when not given.
  final String? collectionTitle;

  /// The page with its cubit, asking for the book's first page.
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
