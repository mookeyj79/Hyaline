// Picks the variant before the page paints: ?variant= in the address, then the
// page's own data-variant (the files in dist/), then the visitor's last choice,
// then the OS setting. Both theme.css files are loaded, so a switch repaints in place.
window.HyalineVariant = (function () {
  const KEY = "hyaline-variant";
  const root = document.documentElement;
  function valid(v) { return v === "dark" || v === "light"; }
  function save(v) { try { localStorage.setItem(KEY, v); } catch (e) { /* storage blocked */ } }
  function stored() { try { return localStorage.getItem(KEY); } catch (e) { return null; } }
  function pick() {
    const asked = new URLSearchParams(location.search).get("variant");
    if (valid(asked)) { save(asked); return asked; }
    if (valid(root.dataset.variant)) return root.dataset.variant;
    if (valid(stored())) return stored();
    return window.matchMedia && matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
  }
  // Called by the switch: remember the choice and keep it in the address, so a reload or a shared link keeps it.
  function choose(v) {
    save(v);
    const url = new URL(location.href);
    url.searchParams.set("variant", v);
    history.replaceState(null, "", url);
  }
  root.dataset.variant = pick();
  return { choose: choose };
})();
