import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/network_cubit.dart';

class NetworkStatusBar extends StatefulWidget {
  const NetworkStatusBar({super.key});

  @override
  State<NetworkStatusBar> createState() => _NetworkStatusBarState();
}

class _NetworkStatusBarState extends State<NetworkStatusBar> {
  bool _isDisconnected = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkCubit, NetworkState>(
      listener: (context, state) {
        final wasConnected = !_isDisconnected;
        _isDisconnected = state is Disconnected;

        if (wasConnected && _isDisconnected) {
          setState(() {});
        }
      },
      child: _isDisconnected
          ? const PersistentNetworkMessage()
          : const SizedBox.shrink(),
    );
  }
}

class BounceUpText extends StatefulWidget {
  final String text;
  final Duration duration;
  final TextStyle style;

  const BounceUpText({
    super.key,
    required this.text,
    this.duration = const Duration(milliseconds: 200),
    this.style = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  });

  @override
  State<BounceUpText> createState() => _BounceUpTextState();
}

class _BounceUpTextState extends State<BounceUpText>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();
    final textChars = widget.text.split('');

    _controllers = List.generate(
      textChars.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    _animations = _controllers
        .map((controller) => Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
            )))
        .toList();

    _opacityAnimations = _controllers
        .map((controller) => Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.easeOut,
            )))
        .toList();

    _startAnimation();
  }

  void _startAnimation() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.text.split('').asMap().entries.map((entry) {
        final index = entry.key;
        final char = entry.value;

        if (char == ' ') {
          return const SizedBox(width: 4);
        }

        return AnimatedBuilder(
          animation:
              Listenable.merge([_animations[index], _opacityAnimations[index]]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, (1 - _animations[index].value) * 20),
              child: Opacity(
                opacity: _opacityAnimations[index].value.clamp(0.0, 1.0),
                child: Text(
                  char,
                  style: widget.style,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class SlidingMessage extends StatefulWidget {
  final String message;
  final Duration duration;
  final Color backgroundColor;

  const SlidingMessage({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 3),
    this.backgroundColor = Colors.red,
  });

  @override
  State<SlidingMessage> createState() => _SlidingMessageState();
}

class _SlidingMessageState extends State<SlidingMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isDismissed) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            BounceUpText(
              text: widget.message,
            ),
          ],
        ),
      ),
    );
  }
}

class PersistentNetworkMessage extends StatefulWidget {
  const PersistentNetworkMessage({super.key});

  @override
  State<PersistentNetworkMessage> createState() =>
      _PersistentNetworkMessageState();
}

class _PersistentNetworkMessageState extends State<PersistentNetworkMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _startRepeatingAnimation();
  }

  void _startRepeatingAnimation() {
    // Sadece bir kez başlat - tekrar etme
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            const RepeatingBounceUpText(
              text: 'İnternet bağlantısı yok',
            ),
          ],
        ),
      ),
    );
  }
}

class RepeatingBounceUpText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const RepeatingBounceUpText({
    super.key,
    required this.text,
    this.style = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  });

  @override
  State<RepeatingBounceUpText> createState() => _RepeatingBounceUpTextState();
}

class _RepeatingBounceUpTextState extends State<RepeatingBounceUpText>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();
    final textChars = widget.text.split('');

    _controllers = List.generate(
      textChars.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    _animations = _controllers
        .map((controller) => Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
            )))
        .toList();

    _opacityAnimations = _controllers
        .map((controller) => Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.easeOut,
            )))
        .toList();

    _startRepeatingAnimation();
  }

  void _startRepeatingAnimation() {
    _startAnimation();

    // Her 2 saniyede bir animasyonu tekrarla
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _resetAnimation().then((_) {
          if (mounted) {
            _startRepeatingAnimation();
          }
        });
      }
    });
  }

  void _startAnimation() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  Future<void> _resetAnimation() async {
    // Tüm controller'ları aynı anda resetle
    for (var controller in _controllers) {
      controller.reset();
    }
    // Kısa bir bekleme
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.text.split('').asMap().entries.map((entry) {
        final index = entry.key;
        final char = entry.value;

        if (char == ' ') {
          return const SizedBox(width: 4);
        }

        return AnimatedBuilder(
          animation:
              Listenable.merge([_animations[index], _opacityAnimations[index]]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, (1 - _animations[index].value) * 20),
              child: Opacity(
                opacity: _opacityAnimations[index].value.clamp(0.0, 1.0),
                child: Text(
                  char,
                  style: widget.style,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class NetworkIndicator extends StatelessWidget {
  final double size;
  final Color? connectedColor;
  final Color? disconnectedColor;

  const NetworkIndicator({
    super.key,
    this.size = 12,
    this.connectedColor,
    this.disconnectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) {
        Color color;
        IconData icon;

        switch (state) {
          case Checking():
            color = Colors.orange;
            icon = Icons.sync;
          case Connected():
            color = connectedColor ?? Colors.green;
            icon = Icons.wifi;
          case Disconnected():
            color = disconnectedColor ?? Colors.red;
            icon = Icons.wifi_off;
          case Initial():
            color = Colors.grey;
            icon = Icons.help_outline;
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.6,
          ),
        );
      },
    );
  }
}
