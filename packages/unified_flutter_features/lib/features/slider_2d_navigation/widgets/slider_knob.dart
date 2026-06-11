import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../models/slider_models.dart';
import '../constants/slider_config.dart';
import '../helpers/slider_state_helper.dart';
import 'vertical_carousel.dart';

class SliderKnob extends StatelessWidget {
  final GlobalKey knobKey;
  final SliderState currentState;
  final Color activeColor;
  final List<SubMenuItem> subMenuItems;
  final FixedExtentScrollController carouselController;
  final bool isDragging;
  final double transitionProgress;
  final bool showUpArrow;
  final bool showDownArrow;

  /// Whether the add ('+') affordance should be shown. Only true when the main
  /// title is centered in the carousel (i.e. tapping opens the mini buttons).
  final bool showAddButton;
  final VoidCallback onTap;
  final VoidCallback? onMainTitleTap;
  final VoidCallback onHorizontalDragStart;
  final GestureDragUpdateCallback onHorizontalDrag;
  final VoidCallback onHorizontalDragEnd;
  final GestureDragUpdateCallback? onVerticalDrag;
  final GestureDragEndCallback? onVerticalDragEnd;

  const SliderKnob({
    super.key,
    required this.knobKey,
    required this.currentState,
    required this.activeColor,
    required this.subMenuItems,
    required this.carouselController,
    required this.isDragging,
    required this.transitionProgress,
    required this.showUpArrow,
    required this.showDownArrow,
    this.showAddButton = true,
    required this.onTap,
    this.onMainTitleTap,
    required this.onHorizontalDragStart,
    required this.onHorizontalDrag,
    required this.onHorizontalDragEnd,
    this.onVerticalDrag,
    this.onVerticalDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final label = SliderStateHelper.getLabelForState(currentState);
    final hasSubMenu = subMenuItems.isNotEmpty;

    // Build carousel items: title + sub menu items
    final carouselItems = hasSubMenu
        ? [
            SubMenuItem(
              icon: Icons.title,
              label: label,
              onTap: () {},
              isMainTitle: true,
            ),
            ...subMenuItems,
          ]
        : <SubMenuItem>[];

    return GestureDetector(
      key: knobKey,
      onHorizontalDragStart: (_) => onHorizontalDragStart(),
      onHorizontalDragUpdate: onHorizontalDrag,
      onHorizontalDragEnd: (_) => onHorizontalDragEnd(),
      onVerticalDragUpdate: onVerticalDrag,
      onVerticalDragEnd: onVerticalDragEnd,
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        height: SliderConfig.sliderHeight,
        width: SliderConfig.knobWidth,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: SliderConfig.knobHeight,
              width: SliderConfig.knobWidth,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(SliderConfig.knobHeight / 2),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [activeColor, activeColor.withValues(alpha: 0.8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.6),
                    blurRadius: isDragging ? 20 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Glass background
                  _buildGlassBackground(),

                  // Static label (if no sub menu)
                  if (!hasSubMenu) _buildStaticLabel(label),

                  // Plus icon (only when adding is available, i.e. main title)
                  if (showAddButton) _buildPlusIcon(),

                  // Direction arrows
                  _buildArrows(),
                ],
              ),
            ),
            // Carousel (if has sub menu)
            if (hasSubMenu)
              Positioned.fill(
                child: _buildCarousel(context, carouselItems),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassBackground() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(SliderConfig.knobHeight / 2),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SliderConfig.knobHeight / 2),
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel(BuildContext context, List<SubMenuItem> items) {
    return Opacity(
      opacity: transitionProgress,
      child: Transform.scale(
        scale: 0.5 + (0.5 * transitionProgress),
        child: ShaderMask(
          shaderCallback: (rect) {
            final onSurface = Theme.of(context).colorScheme.onSurface;
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                onSurface.withValues(alpha: 0.6),
                onSurface.withValues(alpha: 0.6),
                Colors.white,
                Colors.white,
                onSurface.withValues(alpha: 0.6),
                onSurface.withValues(alpha: 0.6),
              ],
              stops: const [0.0, 0.30, 0.42, 0.58, 0.70, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcIn,
          child: VerticalCarousel(
            controller: carouselController,
            physics: const NeverScrollableScrollPhysics(),
            onItemTapped: (index) {
              if (index == 0) {
                onTap();
                onMainTitleTap?.call();
                HapticFeedback.lightImpact();
                return;
              }
              if (index < items.length) {
                items[index].onTap();
                HapticFeedback.lightImpact();
              }
            },
            children: items.map((item) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SliderConfig.knobLabelStyle,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticLabel(String label) {
    return Center(
      child: Text(
        label,
        style: SliderConfig.knobLabelStyle.copyWith(
          fontSize: isDragging ? 12 : 10,
          shadows: [const Shadow(color: Colors.black26, blurRadius: 2)],
        ),
      ),
    );
  }

  Widget _buildPlusIcon() {
    return Positioned(
      top: -2,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 28,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Icon(Icons.add, color: activeColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildArrows() {
    // Calculate if we should show left/right arrows based on slider position
    // Show left arrow if not at the leftmost position
    final bool showLeftArrow =
        transitionProgress > 0.8 && currentState != SliderState.values.first;
    // Show right arrow if not at the rightmost position
    final bool showRightArrow =
        transitionProgress > 0.8 && currentState != SliderState.values.last;

    return Stack(
      children: [
        // Left arrow
        Align(
          alignment: Alignment.centerLeft,
          child: Transform.translate(
            offset: const Offset(-SliderConfig.arrowOffsetHorizontal, 0),
            child: _Arrow(
              icon: Icons.arrow_back_ios,
              color: activeColor,
              isVisible: showLeftArrow,
            ),
          ),
        ),
        // Right arrow
        Align(
          alignment: Alignment.centerRight,
          child: Transform.translate(
            offset: const Offset(SliderConfig.arrowOffsetHorizontal, 0),
            child: _Arrow(
              icon: Icons.arrow_forward_ios,
              color: activeColor,
              isVisible: showRightArrow,
            ),
          ),
        ),
        // Up arrow
        Align(
          alignment: Alignment.topCenter,
          child: Transform.translate(
            offset: const Offset(0, -SliderConfig.arrowOffsetUp),
            child: _Arrow(
              icon: Icons.keyboard_arrow_up,
              color: activeColor,
              size: SliderConfig.arrowSizeVertical,
              isVisible: showUpArrow,
            ),
          ),
        ),
        // Down arrow
        Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: const Offset(0, SliderConfig.arrowOffsetDown),
            child: _Arrow(
              icon: Icons.keyboard_arrow_down,
              color: activeColor,
              size: SliderConfig.arrowSizeVertical,
              isVisible: showDownArrow,
            ),
          ),
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool isVisible;

  const _Arrow({
    required this.icon,
    required this.color,
    this.size = SliderConfig.arrowSize,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isVisible ? 1.0 : 0.0,
      child: Icon(
        icon,
        color: color.withValues(alpha: SliderConfig.arrowAlpha),
        size: size,
      ),
    );
  }
}
