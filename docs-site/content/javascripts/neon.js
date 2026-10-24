/* Parallax for the home page neon scene: transform only, one rAF loop, no layout reads in the frame. */
(function () {
  var DEPTH = { "mg-far": 0.08, "mg-mid": 0.2, "mg-near": 0.38 };
  var reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
  var fine = window.matchMedia("(hover: hover) and (pointer: fine) and (min-width: 701px)");
  var layers = [], px = 0, py = 0, tx = 0, ty = 0, sy = 0, raf = 0, bound = false;

  function frame() {
    raf = 0;
    px += (tx - px) * 0.08;
    py += (ty - py) * 0.08;
    for (var i = 0; i < layers.length; i++) {
      var l = layers[i];
      l.el.style.transform = "translate3d(" + (px * l.d * 60).toFixed(2) + "px," + (-sy * l.d + py * l.d * 40).toFixed(2) + "px,0)";
    }
    if (Math.abs(tx - px) > 0.002 || Math.abs(ty - py) > 0.002) raf = requestAnimationFrame(frame);
  }
  function kick() { if (!raf && layers.length) raf = requestAnimationFrame(frame); }
  function onScroll() { sy = Math.min(window.scrollY, 800); kick(); }
  function onMove(e) {
    tx = e.clientX / window.innerWidth - 0.5;
    ty = e.clientY / window.innerHeight - 0.5;
    kick();
  }
  function init() {
    layers = [];
    if (reduce.matches) return;
    var scene = document.querySelector(".mg-scene");
    if (!scene) return;
    Object.keys(DEPTH).forEach(function (c) {
      var el = scene.querySelector("." + c);
      if (el) layers.push({ el: el, d: DEPTH[c] });
    });
    sy = Math.min(window.scrollY, 800);
    if (!bound) {
      window.addEventListener("scroll", onScroll, { passive: true });
      window.addEventListener("pointermove", function (e) { if (fine.matches && layers.length) onMove(e); }, { passive: true });
      bound = true;
    }
    kick();
  }
  if (window.document$ && window.document$.subscribe) window.document$.subscribe(init);
  else if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
