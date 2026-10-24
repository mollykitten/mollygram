"""Neon curl for the home page hero: one bright tube and one dim thread on two parallax layers.

The shapes come from the prototype the owner picked (viewBox 0 0 320 200). Colors and widths
come from CSS variables, so both themes share one SVG. The glow is a single blur merged with
the source stroke, rendered once.
"""

NEAR = "M335 150 C282 162 230 132 240 86 C248 50 296 44 301 80 C305 106 275 116 262 99 C252 86 265 72 279 80"
FAR = "M196 215 C240 182 298 194 335 170"

HEAD = ('class="mg-layer mg-{n}" data-z="{z}" viewBox="0 0 320 200" preserveAspectRatio="xMidYMid slice" '
        'fill="none" stroke-linecap="round" stroke-linejoin="round"')


def scene(uid="mg"):
    far = (f'<svg {HEAD.format(n="far", z=".25")}><defs><filter id="{uid}-t" x="-20%" y="-50%" width="140%" height="200%">'
           f'<feGaussianBlur stdDeviation="2.2"/></filter></defs>'
           f'<path class="mg-thread" d="{FAR}" filter="url(#{uid}-t)"/></svg>')
    near = (f'<svg {HEAD.format(n="near", z="1")}><defs><filter id="{uid}-g" filterUnits="userSpaceOnUse" x="-100" y="-100" width="540" height="400">'
            f'<feGaussianBlur stdDeviation="5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>'
            f'<path class="mg-neon" d="{NEAR}" filter="url(#{uid}-g)"/><path class="mg-core" d="{NEAR}"/></svg>')
    return far + near
