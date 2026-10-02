# Third-party notices

## Surf

Legacy Surf is a fork of the Surf iOS client and client core from
<https://github.com/seg6/surf> at commit
`8923842c69095241412cafa7abe1845d58dd4e74` (Surf 0.17.0).

Copyright 2026 seg6. Licensed under the MIT License; the license, with the
LegacyReborn Project notice for the modifications, is bundled as `LICENSE.txt`.

Legacy Surf is not affiliated with or endorsed by seg6. It speaks the Surf
protocol to an unmodified Surf server.

## Deta Surf application icon

The application icon is Surf's icon, unchanged. Surf sourced it from
`deta/surf/app/build/resources/prod/icon.png` at commit
`07969419e3d9bd3825c8b79f429d8384a1cf451b`, retrieved on 2026-08-26. The
unmodified source asset retained in `Artwork` has SHA-256
`a7fe7713e95bb66a476e9f65cbff4fae4441c52dfd12f284548f321382e9f594`.
The packaged icon and launch-screen PNGs are resized/composited derivatives.
The modern opaque icons also use
`packages/icons/src/lib/assets/plane.png` from the same commit. Its unmodified
source has SHA-256
`c2eecccb48ad6a929549c9411ec6506653831fec7405122474e5c1f7e6d5eb30`.

Copyright 2025 Deta GmbH

Copyright 2026 Negative Entropy L.L.C

Licensed under the Apache License, Version 2.0. The full license is retained in
`Artwork/DETA-SURF-LICENSE.txt` and bundled with the app.

Neither Surf nor Legacy Surf is affiliated with or endorsed by Deta GmbH or
Negative Entropy L.L.C. Their names and trademarks are not used to imply
sponsorship.

## Lucide icons

Interface icons not drawn by the iOS 6 skin come from the Lucide icon font in
`lucide-static` 1.34.0, retrieved from
<https://registry.npmjs.org/lucide-static/-/lucide-static-1.34.0.tgz>. The
downloaded package archive has SHA-256
`a265596d6ec6f1eec640872086a157e9a04e36387506ffefc81d7f9f0626cba8`.

Copyright 2026 Lucide Icons and Contributors. Licensed under the ISC License.
Some Lucide glyphs are derived from Feather Icons, copyright 2013–present
Cole Bemis, licensed under the MIT License. The copyright and permission
notices are reproduced in `Artwork/LUCIDE-LICENSE.txt`.

## quirc

The iOS 6 camera QR fallback uses quirc from <https://github.com/dlbeer/quirc>
at commit `927d680904dc95fdff4cd9d022eb374b438ff8f2`.

Copyright 2010–2012 Daniel Beer. Licensed under the ISC License; see
`Classes/quirc/LICENSE`, bundled as `QUIRC-LICENSE.txt`.

## iOS 6 skin

The skeuomorphic artwork is drawn at runtime by `Classes/RBClassicSkin.m`; no
Apple images are copied. Its colors were matched to iOS 6 Safari and UIKit.
The linen and pinstripe backdrops are the patterns iOS 6 itself provides.
