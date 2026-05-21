// HappSea: Only load the locales actually used in production.
// Chatwoot ships 56 languages (~25 MB raw, ~11 MB minified) but HappSea
// operates exclusively in Spanish. Keeping `en` as a fallback for any
// string not yet translated in `es`.
// To restore a locale, add it back here and to the export object below.
import en from './locale/en';
import es from './locale/es';

export default {
  en,
  es,
};
