/**
 * WEARSY API Routes Definition
 * Gom toàn bộ API endpoints theo Rule 1 trong AGENTS.md
 */

export const ApiRoutes = {
  HEALTH: {
    ROOT: '/health',
  },
  AUTH: {
    PREFIX: '/auth',
    REGISTER: '/auth/register',
    LOGIN: '/auth/login',
    GOOGLE: '/auth/google',
    FACEBOOK: '/auth/facebook',
    LOGOUT: '/auth/logout',
    CHANGE_PASSWORD: '/auth/change-password',
    SEND_OTP: '/auth/send-otp',
    VERIFY_OTP: '/auth/verify-otp',
  },
  USERS: {
    PREFIX: '/users',
    PROFILE: '/users/profile',
    STYLE_PROFILE: '/users/style-profile',
    UPGRADE_VIP: '/users/upgrade-vip',
  },
  WARDROBE: {
    PREFIX: '/wardrobe',
    UPLOAD: '/wardrobe/upload',
    ANALYZE_IMAGE: '/wardrobe/analyze-image',
    SCAN_BULK: '/wardrobe/scan-bulk',
    BULK_COMMIT: '/wardrobe/bulk-commit',
    ITEMS: '/wardrobe/items',
    ITEM_BY_ID: '/wardrobe/items/:id',
  },
  OUTFITS: {
    PREFIX: '/outfits',
    RECOMMEND: '/outfits/recommend',
    RECOMMEND_BY_CONTEXT: '/outfits/recommend-by-context',
  },
  SHOPPING: {
    PREFIX: '/shopping',
    COMPATIBILITY_CHECK: '/shopping/compatibility-check',
    MISSING_ITEMS: '/shopping/missing-items',
    HISTORY: '/shopping/history',
    SAMPLE_PRODUCTS: '/shopping/sample-products',
  },
  GAMIFICATION: {
    PREFIX: '/gamification',
    COLOR_SCORE: '/gamification/color-score',
    CHALLENGES: '/gamification/challenges',
  },
} as const;
