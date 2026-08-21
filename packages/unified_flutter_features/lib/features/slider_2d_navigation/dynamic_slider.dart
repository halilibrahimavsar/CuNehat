import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unified_flutter_features/core/texts/slider_texts.dart';
import 'models/slider_metrics.dart';
import 'models/slider_models.dart';
import 'constants/slider_config.dart';
import 'helpers/drag_settle.dart';
import 'helpers/slider_state_helper.dart';
import 'widgets/mini_buttons_overlay.dart';
import 'widgets/slider_knob.dart';

/// A 2D navigation slider with state transitions and mini button/sub-menu support.
///
/// Example usage:
/// ```dart
/// class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
///   late final AnimationController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = AnimationController(vsync: this, value: 0.0);
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return DynamicSlider(
///       controller: _controller,
///       onStateTap: (state) {
///         // triggered when state changes
///       },
///       miniButtons: {
///         SliderState.savedMoney: [
///           MiniButtonData(
///             icon: Icons.add,
///             label: 'Add',
///             color: Colors.green,
///             onTap: () {},
///           ),
///         ],
///       },
///       subMenuItems: {
///         SliderState.transactions: [
///           SubMenuItem(
///             icon: Icons.list,
///             label: 'All Transactions',
///             onTap: () {},
///             isDefault: true,
///           ),
///         ],
///       },
///     );
///   }
/// }
/// ```
class DynamicSlider extends StatefulWidget {
  /// Animation controller that controls the slider position (0.0 to 1.0).
  final AnimationController controller;

  /// Callback when the slider value changes during dragging.
  final ValueChanged<double>? onValueChanged;

  /// Callback when a slider state is tapped or becomes active.
  final ValueChanged<SliderState>? onStateTap;

  /// Mini buttons that appear when tapping the knob for specific states.
  final Map<SliderState, List<MiniButtonData>> miniButtons;

  /// Sub-menu items that appear in vertical carousel for specific states.
  final Map<SliderState, List<SubMenuItem>> subMenuItems;

  /// Selected sub-menu index for each state (0-based, excluding title item).
  final Map<SliderState, int> selectedSubIndex;

  /// Localized texts for the slider labels.
  final SliderTexts texts;

  /// Dikey navigasyonu bir kez tanıtan "göz kırpma" (peek) animasyonunun
  /// oynatılacağı durumlar.
  ///
  /// Kullanıcıların aşağı sürüklemeyi bulamamasının sebebi ipuçlarının
  /// hepsinin PASİF olmasıydı. Hareket, duran bir oktan çok daha güçlü bir
  /// çağrıdır: çark bir öğe boyu iner ve yaylanarak geri döner.
  final Set<SliderState> peekStates;

  /// Bir durumun tanıtımı oynatıldığında çağrılır; kalıcılık uygulamaya ait
  /// (paket `SharedPreferences` bilmez).
  final ValueChanged<SliderState>? onPeekPlayed;

  /// Tanıtımın oynayabilmesi için sağlanması gereken ek koşul.
  ///
  /// false döndüğünde tanıtım **düşmez, ertelenir**: "görüldü" işaretlenmez,
  /// bir sonraki fırsatta (durum değişimi ya da rebuild) yeniden denenir.
  /// Uygulama bunu interaktif tanıtım turu oynarken kapatır — tur tam ekran
  /// bir overlay çizdiğinden tanıtım onun ARKASINDA harcanırdı.
  ///
  /// Yan etkisi olmamalı; kare başına birden çok kez çağrılabilir.
  final bool Function()? canPeek;

  const DynamicSlider({
    super.key,
    required this.controller,
    this.onValueChanged,
    this.onStateTap,
    this.miniButtons = const {},
    this.subMenuItems = const {},
    this.selectedSubIndex = const {},
    this.texts = const SliderTexts(),
    this.peekStates = const {},
    this.onPeekPlayed,
    this.canPeek,
  });

  @override
  State<DynamicSlider> createState() => _DynamicSliderState();
}

class _DynamicSliderState extends State<DynamicSlider> {
  bool _isDragging = false;
  bool _isVerticalDragging = false;
  double _widgetWidth = 0.0;
  SliderState? _lastState;

  /// Son çözülen ölçüler. Overlay konumu build dışında (dokunuşta)
  /// hesaplandığı için saklanır.
  SliderMetrics? _metrics;

  Size get _knobSize => Size(
        _metrics?.knobWidth ?? SliderConfig.knobWidth,
        _metrics?.knobHeight ?? SliderConfig.knobHeight,
      );

  late FixedExtentScrollController _carouselController;

  /// Çarkta ortalanmış öğenin indeksi (0 = ana başlık). Hem yığın
  /// göstergesini hem '+' rozetinin görünürlüğünü sürer; state'te tutulur ki
  /// her oturma sonrası tazelensin.
  int _selectedCarouselIndex = 0;

  bool get _isMainSelected => _selectedCarouselIndex == 0;

  /// Dikey sürüklemenin BAŞLADIĞI çark indeksi; dokunsal geri bildirimin
  /// ölçütü budur.
  int _verticalDragStartIndex = 0;

  /// Tanıtım animasyonu oynatılmış durumlar (oturum içi) ve süren oynatma.
  final Set<SliderState> _peeked = <SliderState>{};
  bool _isPeeking = false;

  // Mini buttons overlay state
  bool _showMiniButtons = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _knobKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _carouselController = FixedExtentScrollController();
    _lastState = _getCurrentState();
    widget.controller.addListener(_onControllerChange);
    widget.controller.addStatusListener(_onControllerStatus);
    _carouselController.addListener(_updateCarouselSelection);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateCarouselSelection();
      _syncCarouselToSelection(animate: false);
      _maybePeek();
    });
  }

  @override
  void didUpdateWidget(covariant DynamicSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChange);
      oldWidget.controller.removeStatusListener(_onControllerStatus);
      widget.controller.addListener(_onControllerChange);
      widget.controller.addStatusListener(_onControllerStatus);
      _lastState = _getCurrentState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncCarouselToSelection(animate: false);
        _updateCarouselSelection();
      });
    }
    if (!mapEquals(oldWidget.selectedSubIndex, widget.selectedSubIndex) ||
        oldWidget.subMenuItems != widget.subMenuItems) {
      _syncCarouselToSelection();
    }
    // Ertelenmiş tanıtım için ucuz bir yeniden deneme fırsatı: kapı
    // (`canPeek`) çoğu zaman bir rebuild ile açılır — tur bitince kaydırıcıya
    // ulaşan başka bir sinyal yok.
    _maybePeek();
  }

  @override
  void dispose() {
    _removeMiniButtons();
    _carouselController.removeListener(_updateCarouselSelection);
    _carouselController.dispose();
    widget.controller.removeListener(_onControllerChange);
    widget.controller.removeStatusListener(_onControllerStatus);
    super.dispose();
  }

  SliderState _getCurrentState() {
    return SliderStateHelper.getStateFromValue(
      widget.controller.value,
      SliderState.values.length,
    );
  }

  void _onControllerChange() {
    final currentState = _getCurrentState();

    // Hide mini buttons when dragging
    if (_isDragging && _showMiniButtons) {
      _hideMiniButtons();
    }

    if (_lastState != currentState) {
      // Jest başına TEK dokunsal geri bildirim. Eskiden bir sürükleme üç
      // titreşim üretiyordu: burada heavyImpact, sürükleme bitişinde
      // heavyImpact, `_navigateToState` içinde mediumImpact.
      HapticFeedback.selectionClick();
      _lastState = currentState;

      // Execute default/main title callback when state changes
      _executeDefaultCallback(currentState);

      _resetCarouselForState(currentState);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateCarouselSelection();
      });
    }
  }

  void _resetCarouselForState(SliderState state) {
    final subItems = widget.subMenuItems[state] ?? [];
    if (subItems.isEmpty) return;

    final selectedIndex = widget.selectedSubIndex[state];
    final targetIndex = selectedIndex != null
        ? (selectedIndex + 1).clamp(0, subItems.length)
        : 0;

    if (!_carouselController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resetCarouselForState(state);
      });
      return;
    }

    _carouselController.animateToItem(
      targetIndex,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _syncCarouselToSelection({bool animate = true}) {
    if (_isVerticalDragging) return;

    final state = _getCurrentState();
    final subItems = widget.subMenuItems[state] ?? [];
    if (subItems.isEmpty) return;

    // null seçim = ana başlık: uygulama seçimi temizlediğinde (closeToMain)
    // carousel de başlığa dönmeli; yoksa knob alt menü etiketinde asılı kalır
    // ve ekran (ana görünüm) ile çelişir.
    final selectedIndex = widget.selectedSubIndex[state];
    final targetIndex = selectedIndex != null
        ? (selectedIndex + 1).clamp(0, subItems.length)
        : 0;

    if (!_carouselController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncCarouselToSelection(animate: animate);
      });
      return;
    }

    if (_carouselController.selectedItem == targetIndex) return;

    if (animate) {
      _carouselController.animateToItem(
        targetIndex,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      _carouselController.jumpToItem(targetIndex);
    }
  }

  void _executeDefaultCallback(SliderState state) {
    final subItems = widget.subMenuItems[state] ?? [];

    // Find main title or default item and execute its callback
    for (final item in subItems) {
      if (item.isMainTitle || item.isDefault) {
        item.onTap();
        break;
      }
    }

    // If no main/default item found, execute main state callback
    if (subItems.isEmpty ||
        !subItems.any((item) => item.isMainTitle || item.isDefault)) {
      widget.onStateTap?.call(state);
    }
  }

  void _showMiniButtonsOverlay() {
    final state = _getCurrentState();
    final buttons = widget.miniButtons[state] ?? [];
    if (buttons.isEmpty) return;

    final RenderBox? renderBox =
        _knobKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final sliderValue = widget.controller.value;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: MiniButtonsOverlay(
          position: position,
          knobSize: _knobSize,
          buttons: buttons,
          sliderValue: sliderValue,
          onButtonTap: (index) {
            buttons[index].onTap();
            _hideMiniButtons();
          },
          onDismiss: _hideMiniButtons,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMiniButtons() {
    setState(() => _showMiniButtons = false);
    _removeMiniButtons();
  }

  void _removeMiniButtons() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleMiniButtons() {
    if (_showMiniButtons) {
      _hideMiniButtons();
    } else {
      setState(() => _showMiniButtons = true);
      _showMiniButtonsOverlay();
    }
  }

  /// Tanıtım animasyonu ancak kaydırıcı DURDUĞUNDA oynar; yatay geçişin
  /// ortasında oynarsa iki hareket üst üste biner.
  void _onControllerStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _maybePeek();
    }
  }

  void _maybePeek() {
    if (!mounted || _isPeeking) return;
    final state = _getCurrentState();
    if (!widget.peekStates.contains(state) || _peeked.contains(state)) return;
    if ((widget.subMenuItems[state] ?? const <SubMenuItem>[]).isEmpty) return;
    if (_isDragging || _isVerticalDragging) return;
    if (widget.controller.isAnimating) return;
    // ERTELE, düşürme: "görüldü" yazılmaz.
    if (!(widget.canPeek?.call() ?? true)) return;

    if (!_carouselController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybePeek();
      });
      return;
    }
    // Kullanıcı zaten alt sayfadaysa tanıtacak bir şey yok.
    if (_carouselController.selectedItem != 0) return;

    _peeked.add(state);
    widget.onPeekPlayed?.call(state);
    unawaited(_playPeek());
  }

  Future<void> _playPeek() async {
    final itemExtent = _metrics?.itemExtent;
    if (itemExtent == null || !_carouselController.hasClients) return;
    _isPeeking = true;
    try {
      // 0.45 öğe boyu: komşu etiket belirgin şekilde yukarı gelir ama
      // `selectedItem` 0'da kalır (yuvarlama), yani seçim değişmez.
      await _carouselController.animateTo(
        _carouselController.position.pixels + itemExtent * 0.45,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      if (!mounted || !_carouselController.hasClients) return;
      await _carouselController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 460),
        curve: Curves.elasticOut,
      );
    } finally {
      _isPeeking = false;
    }
  }

  void _updateCarouselSelection() {
    final state = _getCurrentState();
    final subItems = widget.subMenuItems[state] ?? [];

    final index = subItems.isEmpty || !_carouselController.hasClients
        ? 0
        : _carouselController.selectedItem.clamp(0, subItems.length);

    if (mounted && _selectedCarouselIndex != index) {
      setState(() => _selectedCarouselIndex = index);
    }
  }

  double _calculateTransitionProgress(double value) {
    if (SliderState.values.length <= 1) return 1.0;

    final step = 1.0 / (SliderState.values.length - 1);
    final closestIndex = (value / step).round();
    final closestValue = closestIndex * step;
    final distance = (value - closestValue).abs();
    final maxDist = step / 2;

    if (maxDist <= 0) return 1.0;

    final t = 1.0 - (distance / maxDist).clamp(0.0, 1.0);
    return Curves.easeOutCirc.transform(t);
  }

  void _navigateToState(SliderState state) {
    final target =
        SliderStateHelper.getTargetValue(state, SliderState.values.length);
    widget.controller.animateTo(
      target,
      duration: SliderConfig.animationDuration,
      curve: SliderConfig.animationCurve,
    );
  }

  /// Knob'a ve çarka girecek TÜM etiketler. Knob genişliği en uzununa göre
  /// çözülür; yoksa durum değiştikçe knob boyut değiştirirdi.
  Iterable<String> get _allLabels sync* {
    for (final state in SliderState.values) {
      yield SliderStateHelper.getLabelForState(state, widget.texts);
      for (final item in widget.subMenuItems[state] ?? const <SubMenuItem>[]) {
        yield item.label;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Yazı ölçeği kaydırıcıya özgü olarak kırpılır: kırpılmazsa x2.0'da
    // kaydırıcı ekranın altını yer. Ölçüler de aynı kırpılmış ölçekten
    // türetilir, böylece hiçbir etiket kesilmez.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: SliderConfig.maxTextScale,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _widgetWidth = constraints.maxWidth;
          // LayoutBuilder gövdesi kare başına DEĞİL, yalnız kısıt/rebuild
          // değişiminde koşar; ölçüm maliyeti sürükleme sırasında ödenmez.
          final metrics = SliderMetrics.resolve(
            context: context,
            labels: _allLabels,
            trackWidth: constraints.maxWidth,
          );
          _metrics = metrics;

          return AnimatedBuilder(
            animation: widget.controller,
            builder: (context, child) {
              final value = widget.controller.value;
              final state = _getCurrentState();
              final activeColor = SliderStateHelper.getColorForState(state);
              final subItems = widget.subMenuItems[state] ?? [];
              // The add ('+') affordance and the mini-button tap are only valid
              // when the main title (carousel index 0) is centered. In subviews
              // the centered item is a submenu entry, so hide/disable them.
              final isMainSelected = _isMainSelected;
              final sectionWidth = _widgetWidth / SliderState.values.length;
              final knobPosition = SliderConfig.trackPadding +
                  (value * (_widgetWidth - metrics.knobWidth)) -
                  8;
              final transitionProgress = _calculateTransitionProgress(value);

              return SizedBox(
                height: metrics.sliderHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Track background
                    _buildTrack(activeColor),

                    // State sections
                    for (int i = 0; i < SliderState.values.length; i++)
                      _buildStateSection(
                        SliderState.values[i],
                        i * sectionWidth,
                        sectionWidth,
                        state == SliderState.values[i],
                      ),

                    // Knob
                    Positioned(
                      left: knobPosition,
                      top: 0,
                      bottom: 0,
                      child: SliderKnob(
                        knobKey: _knobKey,
                        metrics: metrics,
                        currentState: state,
                        activeColor: activeColor,
                        subMenuItems: subItems,
                        carouselController: _carouselController,
                        isDragging: _isDragging,
                        transitionProgress: transitionProgress,
                        selectedIndex: _selectedCarouselIndex,
                        showAddButton: isMainSelected,
                        texts: widget.texts,
                        onTap: isMainSelected
                            ? () {
                                _toggleMiniButtons();
                              }
                            : () {},
                        onMainTitleTap: () => widget.onStateTap?.call(state),
                        onHorizontalDragStart: () =>
                            setState(() => _isDragging = true),
                        onHorizontalDrag: (details) {
                          final trackWidth = _widgetWidth - metrics.knobWidth;
                          if (trackWidth <= 0) return;
                          final newValue = (widget.controller.value +
                                  details.delta.dx / trackWidth)
                              .clamp(0.0, 1.0);
                          widget.controller.value = newValue;
                          widget.onValueChanged?.call(newValue);
                        },
                        onHorizontalDragEnd: (details) {
                          setState(() => _isDragging = false);
                          // Konum + hız: hızlı bir fiske kısa yol almış olsa
                          // bile bir sayfa ilerletir. Eskiden yalnız konuma
                          // bakılıyor ve %20'lik hızlı fiske yutuluyordu.
                          final maxIndex = SliderState.values.length - 1;
                          final target = resolveDragTarget(
                            position: widget.controller.value * maxIndex,
                            direction: flingDirection(
                              details.velocity.pixelsPerSecond.dx,
                            ),
                            maxIndex: maxIndex,
                          );
                          _navigateToState(SliderState.values[target]);
                        },
                        onVerticalDrag: subItems.isNotEmpty
                            ? (details) {
                                if (!_carouselController.hasClients) return;
                                if (!_isVerticalDragging) {
                                  _verticalDragStartIndex =
                                      _carouselController.selectedItem;
                                  _isVerticalDragging = true;
                                }
                                final position = _carouselController.position;
                                final newOffset =
                                    (position.pixels - details.delta.dy)
                                        .clamp(
                                          position.minScrollExtent,
                                          position.maxScrollExtent,
                                        )
                                        .toDouble();
                                _carouselController.jumpTo(newOffset);
                              }
                            : null,
                        onVerticalDragEnd: subItems.isNotEmpty
                            ? (details) {
                                _isVerticalDragging = false;
                                final itemHeight = metrics.itemExtent;
                                final carouselItems = [
                                  SubMenuItem(
                                      icon: Icons.title,
                                      label: SliderStateHelper.getLabelForState(
                                          state, widget.texts),
                                      onTap: () {}),
                                  ...subItems
                                ];
                                final position =
                                    _carouselController.offset / itemHeight;
                                // Parmak YUKARI kaydırınca offset artar, yani
                                // sonraki öğeye gidilir: hızın işareti ters.
                                final targetIndex = resolveDragTarget(
                                  position: position,
                                  direction: flingDirection(
                                    -details.velocity.pixelsPerSecond.dy,
                                  ),
                                  maxIndex: carouselItems.length - 1,
                                );
                                // Ölçüt SEÇİMİN DEĞİŞMESİ; sürükleme
                                // başındaki indeksle karşılaştırılır. Bitişteki
                                // yuvarlamayla karşılaştırmak, fiske olmadan
                                // yapılan gerçek geçişleri sessiz bırakırdı.
                                if (targetIndex != _verticalDragStartIndex) {
                                  HapticFeedback.selectionClick();
                                }
                                _carouselController.animateToItem(
                                  targetIndex,
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOutCubic,
                                );
                                if (targetIndex == 0) {
                                  widget.onStateTap?.call(state);
                                  return;
                                }
                                carouselItems[targetIndex].onTap();
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTrack(Color activeColor) {
    return Positioned(
      top: SliderConfig.trackPaddingVertical,
      bottom: SliderConfig.trackPaddingVertical,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SliderConfig.trackRadius),
          color: activeColor.withValues(alpha: 0.08),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStateSection(
    SliderState targetState,
    double left,
    double width,
    bool isActive,
  ) {
    final label = SliderStateHelper.getLabelForState(targetState, widget.texts);

    final icon = SliderStateHelper.getIconForState(targetState);
    final color = SliderStateHelper.getColorForState(targetState);

    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () {
          if (isActive) widget.onStateTap?.call(targetState);
          _navigateToState(targetState);
        },
        behavior: HitTestBehavior.translucent,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isActive ? 0.0 : 1.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isActive ? color : color.withValues(alpha: 0.9),
                  size: isActive ? 24 : 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isActive ? 13 : 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? color : color.withValues(alpha: 0.4),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
