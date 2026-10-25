/* Parallax for the home page neon curl. Transform only; the CSS transition (.5s) smooths the release. */
(function () {
  var reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
  var fine = window.matchMedia("(hover: hover) and (pointer: fine) and (min-width: 701px)");
  var layers = [], scene = null, cx = 0, cy = 0, sy = 0, raf = 0, bound = false;

  function frame() {
    raf = 0;
    for (var i = 0; i < layers.length; i++) {
      var l = layers[i];
      l.el.style.transform = "translate3d(" + (-cx * 14 * l.z).toFixed(2) + "px," + (-cy * 10 * l.z - sy * 0.08 * l.z).toFixed(2) + "px,0)";
    }
  }
  function kick() { if (!raf && layers.length) raf = requestAnimationFrame(frame); }
  function onScroll() { sy = Math.min(window.scrollY, 700); kick(); }
  function onMove(e) {
    if (!scene || !fine.matches) return;
    var r = scene.getBoundingClientRect();
    cx = (e.clientX - r.left) / r.width - 0.5;
    cy = (e.clientY - r.top) / r.height - 0.5;
    cx = Math.max(-0.5, Math.min(0.5, cx));
    cy = Math.max(-0.5, Math.min(0.5, cy));
    kick();
  }
  function onLeave() { cx = 0; cy = 0; kick(); }
  function init() {
    layers = []; scene = null;
    if (reduce.matches) return;
    scene = document.querySelector(".mg-scene");
    if (!scene) return;
    scene.querySelectorAll(".mg-layer").forEach(function (el) { layers.push({ el: el, z: parseFloat(el.getAttribute("data-z")) || 0 }); });
    sy = Math.min(window.scrollY, 700);
    if (!bound) {
      window.addEventListener("scroll", onScroll, { passive: true });
      window.addEventListener("pointermove", onMove, { passive: true });
      document.addEventListener("pointerleave", onLeave);
      bound = true;
    }
    kick();
  }
  if (window.document$ && window.document$.subscribe) window.document$.subscribe(init);
  else if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
