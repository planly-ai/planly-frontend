import 'package:flutter/material.dart';
import 'package:planly_ai/app/constants/app_constants.dart';

class AgentBlockCard extends StatefulWidget {
  final String title;
  final String content;
  final bool isStreaming;
  final AgentBlockCardStyle style;
  final TextStyle? contentTextStyle;

  const AgentBlockCard({
    super.key,
    required this.title,
    required this.content,
    required this.isStreaming,
    required this.style,
    this.contentTextStyle,
  });

  @override
  State<AgentBlockCard> createState() => _AgentBlockCardState();
}

class AgentBlockCardStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;
  final Color iconColor;
  final IconData icon;

  const AgentBlockCardStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.titleColor,
    required this.iconColor,
    required this.icon,
  });

  factory AgentBlockCardStyle.thinking(ColorScheme colorScheme) {
    return AgentBlockCardStyle(
      backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
      borderColor: Colors.transparent,
      titleColor: colorScheme.primary,
      iconColor: colorScheme.primary,
      icon: Icons.psychology_alt_outlined,
    );
  }

  factory AgentBlockCardStyle.toolCall(ColorScheme colorScheme) {
    return AgentBlockCardStyle(
      backgroundColor: colorScheme.tertiaryContainer.withValues(alpha: 0.26),
      borderColor: Colors.transparent,
      titleColor: colorScheme.onTertiaryContainer,
      iconColor: colorScheme.onTertiaryContainer.withValues(alpha: 0.82),
      icon: Icons.construction_outlined,
    );
  }
}

class _AgentBlockCardState extends State<AgentBlockCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isStreaming;
  }

  @override
  void didUpdateWidget(covariant AgentBlockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isStreaming && widget.isStreaming) {
      setState(() {
        _expanded = true;
      });
    } else if (oldWidget.isStreaming && !widget.isStreaming) {
      setState(() {
        _expanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedContent = widget.content.trimRight();
    final hasContent = normalizedContent.trim().isNotEmpty;
    final preview = hasContent
        ? normalizedContent.trim().replaceAll('\n', ' ')
        : '';
    final contentStyle =
        widget.contentTextStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.92),
          height: 1.35,
        );

    return Container(
      decoration: BoxDecoration(
        color: widget.style.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(AppConstants.borderRadiusLarge),
          bottomLeft: Radius.circular(AppConstants.borderRadiusLarge),
          bottomRight: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(AppConstants.borderRadiusLarge),
              bottomLeft: Radius.circular(AppConstants.borderRadiusLarge),
              bottomRight: Radius.circular(AppConstants.borderRadiusLarge),
            ),
            onTap: hasContent
                ? () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    widget.style.icon,
                    size: 16,
                    color: widget.style.iconColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: widget.style.titleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: widget.style.iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: _expanded && hasContent
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Text(normalizedContent, style: contentStyle),
                  )
                : (!widget.isStreaming && hasContent)
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    child: Text(
                      preview,
                      style: contentStyle?.copyWith(
                        color: contentStyle.color?.withValues(alpha: 0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
