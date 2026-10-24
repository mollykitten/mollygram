"""Neon tubes for the home page hero: three depth layers of round-capped paths.

Shapes echo the wordmark (arches like "m", bars like "l", broken rings like "o")
without spelling anything. Each layer draws the same paths three times: a wide
blurred halo, a tighter halo and a pale core. The blur is rendered once.
"""

LAYERS = {
    "far": ["M-40 700 V420 A190 190 0 0 1 340 420 V700", "M340 420 A190 190 0 0 1 720 420 V700",
            "M1000 80 A150 150 0 1 1 940 -30", "M1380 700 V300 A150 150 0 0 1 1680 300 V700"],
    "mid": ["M780 700 V470 A130 130 0 0 1 1040 470 V700", "M1040 470 A130 130 0 0 1 1300 470 V700",
            "M1361 234 A90 90 0 1 0 1299 234"],
    "near": ["M1170 640 V450 A100 100 0 0 1 1370 450 V640", "M1370 520 V400 A100 100 0 0 1 1570 400 V640",
             "M1255 300 A74 74 0 1 0 1205 300", "M1480 90 V250", "M1540 50 V250"],
}
SW = {"far": 5, "mid": 9, "near": 15}
OP = {"far": .5, "mid": .75, "near": 1}
BL = {"far": (10, 3), "mid": (14, 5), "near": (18, 6)}

def scene(uid="mg"):
    """Return the three SVG layers as one HTML string (no <use>: Zensical's script rewrites <use href>)."""
    out = []
    for layer in ("far", "mid", "near"):
        sw = SW[layer]
        big, small = BL[layer]
        paths = "".join(f'<path d="{p}"/>' for p in LAYERS[layer])
        region = 'filterUnits="userSpaceOnUse" x="-400" y="-400" width="2400" height="1500"'
        out.append(
            f'<svg class="mg-layer mg-{layer}" viewBox="0 0 1600 700" preserveAspectRatio="xMaxYMin slice" '
            f'fill="none" stroke-linecap="round" stroke-linejoin="round">'
            f'<defs><filter id="{uid}-{layer}-1" {region}><feGaussianBlur stdDeviation="{big * sw / 8:.1f}"/></filter>'
            f'<filter id="{uid}-{layer}-2" {region}><feGaussianBlur stdDeviation="{small * sw / 8:.1f}"/></filter></defs>'
            f'<g opacity="{OP[layer]}">'
            f'<g stroke="#FF2E88" stroke-width="{sw * 3}" opacity=".45" filter="url(#{uid}-{layer}-1)">{paths}</g>'
            f'<g stroke="#FF2E88" stroke-width="{sw * 1.7:.1f}" opacity=".85" filter="url(#{uid}-{layer}-2)">{paths}</g>'
            f'<g stroke="#FFD9EA" stroke-width="{sw}">{paths}</g></g></svg>'
        )
    return "".join(out)
