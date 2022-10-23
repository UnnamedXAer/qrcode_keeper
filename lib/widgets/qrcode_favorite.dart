import 'package:flutter/material.dart';

class QRCodeFavorite extends StatefulWidget {
  const QRCodeFavorite({
    required this.favorite,
    this.onTap,
    this.size = 28.0,
    this.starsCnt = 1,
    super.key,
  });
  final bool favorite;
  final VoidCallback? onTap;
  final int starsCnt;
  final double size;

  @override
  State<QRCodeFavorite> createState() => _QRCodeFavoriteState();
}

class _QRCodeFavoriteState extends State<QRCodeFavorite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: widget.favorite ? 1 : 0,
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.elasticOut.flipped,
    );

    _scaleAnimation = Tween(
      begin: 1.0,
      end: 1.2,
    ).animate(curve)
      ..addListener(() {
        setState(() {});
      });

    _colorAnimation = ColorTween(
      begin: const Color.fromRGBO(136, 136, 136, 1),
      end: Colors.amber.shade400,
    ).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap == null ? null : _onTap,
      child: Center(
        child: Container(
          width: widget.starsCnt * widget.size + 2 * 16,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < widget.starsCnt; i++)
                  Icon(
                    Icons.money_outlined,
                    color: _colorAnimation.value,
                    size: widget.size,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap() {
    if (_controller.isAnimating) {
      return;
    }

    if (_controller.isCompleted) {
      _controller.reverse(from: _controller.value);
    } else {
      _controller.forward(from: _controller.value);
    }

    widget.onTap!();
  }
}
