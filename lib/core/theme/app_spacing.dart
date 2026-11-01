import 'design_tokens.dart';

/// App-wide spacing and sizing constants
/// Based on 8px grid system
abstract final class AppSpacing {
  // ============================================================================
  // SPACING - 8px base unit (aligned with DesignTokens)
  // ============================================================================

  static const double xs = DesignTokens.space4; // 4px
  static const double sm = DesignTokens.space8; // 8px
  static const double md = DesignTokens.space16; // 16px
  static const double lg = DesignTokens.space24; // 24px
  static const double xl = DesignTokens.space32; // 32px
  static const double xxl = DesignTokens.space48; // 48px

  // ============================================================================
  // BORDER RADIUS - Softer, more modern
  // ============================================================================

  static const double cardRadius = DesignTokens.cardRadius; // 20px (was 24px)
  static const double controlRadius =
      DesignTokens.buttonRadius; // 16px (was 18px)
  static const double navigationRadius =
      DesignTokens.radiusXl; // 24px (was 30px)

  // ============================================================================
  // COMPONENT SIZES
  // ============================================================================

  static const double iconChipSize = 44;
  static const double contentWidth = DesignTokens.contentMaxWidth; // 960px
  static const double railBreakpoint = DesignTokens.breakpointTablet; // 840px
}
