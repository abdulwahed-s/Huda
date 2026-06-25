import 'package:flutter/material.dart';

class StarRatingInput extends StatefulWidget {
  final double initialRating;
  final int itemCount;
  final double itemSize;
  final double spacing;
  final Color color;
  final Color unratedColor;
  final bool allowHalfRating;
  final double minRating;
  final ValueChanged<double> onRatingUpdate;

  const StarRatingInput({
    super.key,
    this.initialRating = 0,
    this.itemCount = 5,
    required this.itemSize,
    this.spacing = 8,
    required this.color,
    required this.unratedColor,
    this.allowHalfRating = true,
    this.minRating = 1,
    required this.onRatingUpdate,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput> {
  late double _rating = widget.initialRating;

  @override
  void didUpdateWidget(StarRatingInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialRating != oldWidget.initialRating &&
        widget.initialRating != _rating) {
      _rating = widget.initialRating;
    }
  }

  double get _extent => widget.itemSize + widget.spacing;
  double get _totalWidth => widget.itemCount * _extent;

  double _ratingFromDx(double dx) {
    final stars = dx / _extent;
    final index = stars.floor();
    final frac = stars - index;
    double rating;
    if (widget.allowHalfRating) {
      rating = index + (frac <= 0.5 ? 0.5 : 1.0);
    } else {
      rating = index + 1.0;
    }
    return rating.clamp(widget.minRating, widget.itemCount.toDouble());
  }

  void _update(double dx, bool isRtl) {
    final effectiveDx = isRtl ? _totalWidth - dx : dx;
    final rating = _ratingFromDx(effectiveDx);
    if (rating != _rating) {
      setState(() => _rating = rating);
    }
    widget.onRatingUpdate(rating);
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _update(d.localPosition.dx, isRtl),
      onHorizontalDragStart: (d) => _update(d.localPosition.dx, isRtl),
      onHorizontalDragUpdate: (d) => _update(d.localPosition.dx, isRtl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < widget.itemCount; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              child: _star((_rating - i).clamp(0.0, 1.0), isRtl),
            ),
        ],
      ),
    );
  }

  Widget _star(double fill, bool isRtl) {
    final size = widget.itemSize;
    if (fill <= 0.0) {
      return Icon(Icons.star_rounded, size: size, color: widget.unratedColor);
    }

    final filledStar = Icon(
      Icons.star_rounded,
      size: size,
      color: widget.color,
      shadows: [
        Shadow(color: widget.color.withValues(alpha: 0.4), blurRadius: 8),
      ],
    );

    if (fill >= 1.0) return filledStar;

    return Stack(
      children: [
        Icon(Icons.star_rounded, size: size, color: widget.unratedColor),
        ClipRect(
          clipper: _FractionClipper(fill, fromRight: isRtl),
          child: filledStar,
        ),
      ],
    );
  }
}

class _FractionClipper extends CustomClipper<Rect> {
  final double fraction;
  final bool fromRight;

  _FractionClipper(this.fraction, {this.fromRight = false});

  @override
  Rect getClip(Size size) => fromRight
      ? Rect.fromLTWH(
          size.width * (1 - fraction), 0, size.width * fraction, size.height)
      : Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_FractionClipper oldClipper) =>
      oldClipper.fraction != fraction || oldClipper.fromRight != fromRight;
}
