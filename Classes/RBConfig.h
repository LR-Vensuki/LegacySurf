#import <Foundation/Foundation.h>

#ifndef RBCompatibilityVersion
#error RBCompatibilityVersion must be supplied by the Makefile from COMPATIBILITY_VERSION
#endif
// The upstream Surf client release this build tracks. The Surf server
// compares it with its embedded client, so it is reported unchanged.
#ifndef RBAppVersion
#error RBAppVersion must be supplied by the Makefile from SURF_BASE_VERSION
#endif
// The Legacy Surf release shown to the user.
#ifndef RBLegacyVersion
#error RBLegacyVersion must be supplied by the Makefile from VERSION
#endif
// Legacy Surf keeps its own data beside an installed upstream Surf.
#define RBLogDirectory @"/var/mobile/Library/LegacySurf"
#define RBLogFile @"/var/mobile/Library/LegacySurf/legacysurf.log"

// Surf 0.15.4 identifies compatibility generation 1 with this legacy token.
// Sending it beside the ordered generation keeps new clients compatible with
// the published 0.15.4 backend during the migration.
static inline NSString *RBWireCompatibilityVersion(void) {
    return [RBCompatibilityVersion isEqualToString:@"1"] ? @"20260831-1"
                                                          : RBCompatibilityVersion;
}

// NSUserDefaults keys (settings screen).
#define RBLegacyDefaultsServerURLKey @"RBServerURL"
#define RBLegacyDefaultsPasswordKey @"RBPassword"
#define RBLegacyDefaultsServersKey @"RBServers"
#define RBDefaultsLastPasteboardKey @"RBLastPasteboard" // last URL offered from the pasteboard
#define RBDefaultsReaderNightKey @"RBReaderNight" // NSNumber bool; reader dark mode
#define RBDefaultsDiagnosticsKey @"RBDiagnosticsOverlay" // NSNumber bool; live performance panel
#define RBDefaultsMobileLayoutKey @"RBMobileLayout" // NSNumber bool; request mobile sites and viewport behavior
#define RBDefaultsOfferCopiedLinksKey @"RBOfferCopiedLinks" // NSNumber bool; prompt for clipboard URLs
#define RBDefaultsDarkModeKey @"RBDarkMode" // NSNumber bool; native UI and remote Chromium appearance
#define RBDefaultsBottomBrowserBarKey @"RBBottomBrowserBar" // NSNumber bool; iPad browser rail edge
