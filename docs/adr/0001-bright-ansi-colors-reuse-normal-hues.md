# Bright ANSI colors reuse the normal hues

Terminals have 16 ANSI slots but the palette has 8 hues. The six bright colors map to the same roles as their normal counterparts instead of adding `*_bright` roles. Lifting would push Dark's pastels toward glowing near-white, and lightening Light's hues would drop them below the 4.5:1 contrast floor they were darkened to pass.

## Consequences

Tools that use bright colors as emphasis show no hue difference. Black and white slots are mapped separately to neutral roles, so bright black still differs from black.
