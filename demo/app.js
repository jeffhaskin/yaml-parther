/* ============================================================================
   yaml-parther demo — app.js  (one ES module)
   - POSTs /api/parse per the frozen contract; OR renders a fixture (?fixture=)
   - builds the typed tree, the radiogroup toggle, keyboard model, 3 renderers
   - motion: WAAPI for the interactive few (toggle spring, press release),
     CSS keyframes for the many (first-render stagger, expand settle),
     live edge = pseudo-element OPACITY (never an animated shadow)
   ============================================================================ */

const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];

const REDUCED = window.matchMedia("(prefers-reduced-motion: reduce)");
const reduced = () => REDUCED.matches;

const CARDS_MAX_DEPTH = 3;
const MAX_CHILDREN = 200; // wide-sibling render cap
const COLLAPSE_DEPTH = 2; // collapse-by-default past this depth

/* ---- type metadata: glyph (text or svg sprite id) + class + label ------- */
const TYPE = {
  "hash-table": { cls: "t-map", label: "MAP", text: "{ }", svg: null, lt: "lt-map" },
  vector: { cls: "t-vec", label: "VEC", text: "[ ]", svg: null, lt: "lt-vec" },
  integer: { cls: "t-int", label: "INT", text: "#", svg: null, lt: "lt-int" },
  float: { cls: "t-flt", label: "FLT", text: "≈", svg: null, lt: "lt-flt" },
  string: { cls: "t-str", label: "STR", text: '" "', svg: null, lt: "lt-str" },
  true: { cls: "t-true", label: "T", text: null, svg: "g-true", lt: "lt-true" },
  false: { cls: "t-nil", label: "NIL", text: null, svg: "g-nil", lt: "lt-nil" },
  null: { cls: "t-null", label: "NULL", text: null, svg: "g-null", lt: "lt-null" },
};

const isContainer = (n) => n.type === "hash-table" || n.type === "vector";
const childCountOf = (n) =>
  n.type === "hash-table"
    ? n.childCount ?? (n.entries ? n.entries.length : 0)
    : n.type === "vector"
    ? n.childCount ?? (n.items ? n.items.length : 0)
    : 0;

/* glyph element for a type (svg via sprite when the font can't be trusted) */
function glyphEl(type, { count = null } = {}) {
  const t = TYPE[type];
  const wrap = el("span", "tag__glyph");
  if (t.svg) {
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    const use = document.createElementNS("http://www.w3.org/2000/svg", "use");
    use.setAttribute("href", "#" + t.svg);
    svg.appendChild(use);
    svg.setAttribute("aria-hidden", "true");
    wrap.appendChild(svg);
  } else {
    wrap.textContent = t.text;
  }
  const frag = document.createDocumentFragment();
  frag.appendChild(wrap);
  if (count != null) {
    const c = el("span", "tag__count");
    const open = type === "hash-table" ? "{" : "[";
    const close = type === "hash-table" ? "}" : "]";
    c.textContent = `${open}${fmtInt(count)}${close}`;
    frag.appendChild(c);
  }
  return frag;
}

/* a full type tag: glyph (+count) — color flows from .t-* on parent */
function tagEl(type, { count = null, label = false } = {}) {
  const t = TYPE[type];
  const tag = el("span", `tag ${t.cls}`);
  tag.appendChild(glyphEl(type, { count }));
  if (label) {
    const l = el("span", "tag__label");
    l.textContent = t.label;
    tag.appendChild(l);
  }
  return tag;
}

function el(tag, cls) {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  return e;
}
const fmtInt = (n) => Number(n).toLocaleString("en-US");

/* ============================ STATE ==================================== */
const stage = $("#stage");
const state = {
  view: "tree",
  docs: [], // array of {root, repl, stats} for multi-document streams
  docIndex: 0,
};

/* ============================ TOGGLE (one object) ====================== */
const toggle = $("#view-toggle");
const pill = $(".toggle__pill", toggle);
const opts = $$(".toggle__opt", toggle);

function sizePill() {
  // FLIP-style: measure the active option's box; pill is absolute + translateX
  const active = opts.find((o) => o.dataset.view === state.view) || opts[0];
  const w = active.offsetWidth;
  toggle.style.setProperty("--pill-w", w + "px");
  // equal-width labels: lock each option to the widest so width never animates
}
function pillTargetX() {
  const active = opts.find((o) => o.dataset.view === state.view) || opts[0];
  return active.offsetLeft - opts[0].offsetLeft;
}

function setView(next, { animate = true, focus = false } = {}) {
  if (next === state.view && animate) return;
  const fromX = pillTargetXForView(state.view);
  state.view = next;

  // ARIA + roving tabindex — single source of truth
  opts.forEach((o) => {
    const on = o.dataset.view === next;
    o.setAttribute("aria-checked", on ? "true" : "false");
    o.tabIndex = on ? 0 : -1;
    if (on && focus) o.focus();
  });

  // everything else is driven by CSS off data-view
  stage.dataset.view = next;
  $("#view-tree").hidden = next !== "tree";
  $("#view-repl").hidden = next !== "repl";
  $("#view-cards").hidden = next !== "cards";

  // announce
  announce(
    next === "tree" ? "Tree view" : next === "repl" ? "REPL view" : "Cards view"
  );

  // pill spring (WAAPI) + asymmetric cross-fade
  const toX = pillTargetX();
  if (animate && !reduced()) {
    springPill(fromX, toX);
    crossFadePanels();
  } else {
    pill.style.setProperty("--pill-x", toX + "px");
  }
  // ensure the now-active view is rendered
  renderActiveView();
}

function pillTargetXForView(view) {
  const active = opts.find((o) => o.dataset.view === view) || opts[0];
  return active.offsetLeft - opts[0].offsetLeft;
}

/* the signature toggle spring: translateX only, one ~3.5% overshoot, no ring */
function springPill(fromX, toX) {
  const overshoot = (toX - fromX) * 0.035;
  pill.animate(
    [
      { transform: `translateX(${fromX}px)` },
      { transform: `translateX(${toX + overshoot}px)`, offset: 0.7 },
      { transform: `translateX(${toX}px)` },
    ],
    { duration: 320, easing: "cubic-bezier(.22,1,.36,1)", fill: "forwards" }
  );
  pill.style.setProperty("--pill-x", toX + "px");
}

/* panels do NOT slide — asymmetric cross-fade in the shared grid cell */
function crossFadePanels() {
  const active = $(`#view-${state.view}`);
  if (!active) return;
  active.animate(
    [
      { opacity: 0, transform: "translateY(6px) scale(.99)" },
      { opacity: 1, transform: "none" },
    ],
    { duration: 180, delay: 40, easing: "ease-out", fill: "backwards" }
  );
}

/* keyboard model for the radiogroup: ←/→/↑/↓ wrap, Home/End, selection-follows-focus */
toggle.addEventListener("keydown", (e) => {
  const idx = opts.findIndex((o) => o.dataset.view === state.view);
  let next = null;
  switch (e.key) {
    case "ArrowRight":
    case "ArrowDown":
      next = (idx + 1) % opts.length;
      break;
    case "ArrowLeft":
    case "ArrowUp":
      next = (idx - 1 + opts.length) % opts.length;
      break;
    case "Home":
      next = 0;
      break;
    case "End":
      next = opts.length - 1;
      break;
    default:
      return;
  }
  e.preventDefault();
  setView(opts[next].dataset.view, { animate: true, focus: true });
});
opts.forEach((o) =>
  o.addEventListener("click", () =>
    setView(o.dataset.view, { animate: true, focus: true })
  )
);

/* ============================ LIVE EDGE will-change discipline ========= */
/* add will-change:opacity on enter/focus, remove on transitionend.
   never on idle nodes. Delegated so huge trees don't carry N listeners.   */
function bindLiveEdge(container) {
  const arm = (e) => {
    const row = e.target.closest(".row, .card");
    if (!row || !container.contains(row)) return;
    row.style.willChange = "opacity";
  };
  const disarm = (e) => {
    const row = e.target.closest(".row, .card");
    if (!row) return;
    // pseudo-element transition fires transitionend on the host
    row.style.willChange = "";
  };
  container.addEventListener("pointerover", arm);
  container.addEventListener("focusin", arm);
  container.addEventListener("pointerout", disarm);
  container.addEventListener("focusout", disarm);
}

/* ============================ press-release spring (WAAPI one-shot) ===== */
function pressRelease(target) {
  if (reduced()) return;
  target.animate(
    [
      { transform: "scale(.97)" },
      { transform: "scale(1.02)", offset: 0.6 },
      { transform: "scale(1)" },
    ],
    { duration: 140, easing: "cubic-bezier(.34,1.56,.64,1)" }
  );
}

/* ============================ TREE RENDERER ============================ */
const treeRoot = $("#tree-root");

/* render the tree from the in-memory JSON. children built on demand.       */
function renderTree(root, stats) {
  treeRoot.innerHTML = "";
  treeRoot.dataset.animate = "none";
  const rootNode = buildNode({ node: root, key: null, depth: 0, level: 1 });
  treeRoot.appendChild(rootNode);
  treeRoot.setAttribute("role", "tree");

  // first-render stagger: declarative via CSS keyframes + per-row --delay.
  // set --delay on each *currently mounted* row (top-down), capped 700ms.
  if (!reduced()) {
    let i = 0;
    $$(".row", treeRoot).forEach((r) => {
      const depth = Number(r.dataset.depth || 0);
      r.style.setProperty("--delay", Math.min(depth * 24, 700) + "ms");
      i++;
    });
  }
  // toggle the animate flag on next frame so the keyframes actually play
  requestAnimationFrame(() => {
    treeRoot.dataset.animate = "in";
  });
}

/* build a node element (row + lazy children wrapper). Mounts children only
   when expanded (collapse-by-default past COLLAPSE_DEPTH).                  */
function buildNode({ node, key, index, depth, level }) {
  const wrap = el("div", "node");
  const t = TYPE[node.type];
  wrap.dataset.depth = depth;
  const container = isContainer(node);
  const count = container ? childCountOf(node) : 0;

  // expansion default: expanded if depth < COLLAPSE_DEPTH and non-empty
  const startExpanded = container && count > 0 && depth < COLLAPSE_DEPTH;
  wrap.dataset.expanded = container ? String(startExpanded) : "false";

  // -- the row --
  const row = el("div", `row ${t.cls}`);
  row.dataset.depth = depth;
  row.dataset.container = String(container);
  row.setAttribute("role", "treeitem");
  row.setAttribute("aria-level", level);
  row.tabIndex = -1; // roving; first row gets 0 after build
  if (container) row.setAttribute("aria-expanded", String(startExpanded));

  // twisty
  const tw = el("span", "twisty" + (container && count > 0 ? "" : " is-empty"));
  if (container && count > 0) {
    const svg = svgUse("g-chevron");
    tw.appendChild(svg);
  }
  row.appendChild(tw);

  // glyph (type) — leads. Containers show the bare glyph; scalars too.
  const g = el("span", `tag ${t.cls}`);
  g.appendChild(glyphEl(node.type, { count: null }));
  row.appendChild(g);

  // key slot (key may itself be a typed NODE — hash-table keys)
  const keyWrap = el("span", "row__key");
  if (key != null) {
    keyWrap.appendChild(renderKey(key));
  } else if (index != null) {
    const ix = el("span", "row__index");
    ix.textContent = `[${index}]`;
    keyWrap.appendChild(ix);
  } else {
    const root = el("span", "key");
    root.textContent = "root";
    keyWrap.appendChild(root);
  }
  row.appendChild(keyWrap);

  // lead dots
  row.appendChild(el("span", "row__lead"));

  // value / summary slot
  const valWrap = el("span", "row__value");
  if (container) {
    // containers ALWAYS show LABEL [count] on the right (B.2: `VEC [2]`)
    valWrap.appendChild(summaryEl(node, count));
  } else {
    valWrap.appendChild(scalarValueEl(node));
  }
  row.appendChild(valWrap);

  wrap.appendChild(row);

  // -- children wrapper (grid-template-rows animation target) --
  if (container && count > 0) {
    const childrenEl = el("div", "children");
    const inner = el("div", "children__inner");
    inner.setAttribute("role", "group");
    childrenEl.appendChild(inner);
    wrap.appendChild(childrenEl);
    if (startExpanded) mountChildren(wrap, node, depth, level);
    wrap._node = node; // stash for lazy mount
    wrap._level = level;
  }

  // interaction
  if (container && count > 0) {
    row.addEventListener("click", () => toggleNode(wrap));
  }

  return wrap;
}

/* render a hash-table key, which is itself a typed NODE */
function renderKey(keyNode) {
  // string keys read as plain Inter; non-string keys carry their glyph + mono
  if (keyNode.type === "string") {
    const k = el("span", "key");
    k.textContent = keyNode.value;
    return k;
  }
  // typed key: glyph + the lisp/printed form, so `7` vs `"7"` differ visibly
  const frag = document.createDocumentFragment();
  const tg = tagEl(keyNode.type, { label: false });
  frag.appendChild(tg);
  const k = el("span", "key key--typed " + TYPE[keyNode.type].cls);
  k.style.color = "var(--type)";
  k.textContent = scalarText(keyNode);
  frag.appendChild(k);
  return frag;
}

/* the printed text of a scalar (uses lisp/value per contract) */
function scalarText(node) {
  switch (node.type) {
    case "string":
      return JSON.stringify(node.value); // shows the quotes
    case "integer":
      return node.lisp ?? String(node.value);
    case "float":
      return node.lisp ?? String(node.value);
    case "true":
      return "T";
    case "false":
      return "NIL";
    case "null":
      return "NULL";
    default:
      return node.repl ?? "";
  }
}

/* a scalar value element for the tree value slot.
   T / NIL / NULL render with their SVG glyph so they stay shape-distinct.   */
function scalarValueEl(node) {
  const t = TYPE[node.type];
  if (node.type === "true" || node.type === "false" || node.type === "null") {
    // value is the bare printed form (T / NIL / NULL); the LEADING row glyph
    // already carries the shape — no duplicate glyph here (B.2).
    const v = el("span", `value ${t.cls}`);
    v.style.color = "var(--type)";
    v.textContent =
      node.type === "true" ? "T" : node.type === "false" ? "NIL" : "NULL";
    return v;
  }
  const v = el("span", `value ${t.cls}` + (node.type === "string" ? " value--str" : ""));
  v.style.color = "var(--type)";
  v.textContent =
    node.type === "string"
      ? JSON.stringify(node.value)
      : node.lisp ?? String(node.value);
  return v;
}

/* container summary on the value slot: LABEL [count] (B.2: `VEC [2]`).
   Shown whether collapsed or expanded — read cardinality without expanding. */
function summaryEl(node, count) {
  const s = el("span", `summary ${TYPE[node.type].cls}`);
  if (node.truncated) {
    s.title = "truncated by node budget — expand to load";
  }
  const t = TYPE[node.type];
  const lab = el("span", "summary__label");
  lab.textContent = t.label;
  s.appendChild(lab);
  const c = el("span", "summary__count");
  const open = node.type === "hash-table" ? "{" : "[";
  const close = node.type === "hash-table" ? "}" : "]";
  c.textContent = `${open}${fmtInt(count)}${close}`;
  s.appendChild(c);
  return s;
}

/* mount the direct children of a container (lazy) */
function mountChildren(wrap, node, depth, level) {
  const inner = $(".children__inner", wrap);
  if (!inner || inner._mounted) return;
  inner._mounted = true;

  const kids = node.type === "hash-table" ? node.entries || [] : node.items || [];
  const total = childCountOf(node);
  const shown = Math.min(kids.length, MAX_CHILDREN);

  for (let i = 0; i < shown; i++) {
    let childWrap;
    if (node.type === "hash-table") {
      const { key, val } = kids[i];
      childWrap = buildNode({ node: val, key, depth: depth + 1, level: level + 1 });
    } else {
      childWrap = buildNode({
        node: kids[i],
        index: String(i),
        depth: depth + 1,
        level: level + 1,
      });
    }
    inner.appendChild(childWrap);
  }

  // truthful "+N more" — exact remaining from childCount
  const remaining = total - shown;
  if (remaining > 0) {
    const more = el("button", "more");
    more.type = "button";
    more.innerHTML = `<span class="more__n">+${fmtInt(remaining)}</span> more ${
      node.type === "hash-table" ? "entries" : "items"
    } not rendered`;
    more.title = `${fmtInt(total)} total · first ${fmtInt(shown)} shown`;
    inner.appendChild(more);
  }

  // small-multiples: align sibling values into a soft column by giving every
  // direct-child key the same min-width (the widest in the group).
  alignGroupKeys(inner);
}

/* measure direct-child .row__key widths and set a shared --key-w so the
   value column lines up within a sibling group (a mapping reads like a table) */
function alignGroupKeys(inner) {
  // measure on next frame (after layout) to read natural key widths
  requestAnimationFrame(() => {
    let max = 0;
    const keys = $$(":scope > .node > .row > .row__key", inner);
    for (const k of keys) {
      // temporarily clear the shared width to measure intrinsic size
      k.style.minWidth = "auto";
      max = Math.max(max, k.scrollWidth);
    }
    // cap so one very long key doesn't push values off-screen
    const w = Math.min(max, 320);
    inner.style.setProperty("--key-w", w + "px");
    for (const k of keys) k.style.minWidth = "";
  });
}

/* expand/collapse honoring the LOCKED motion:
   expand: row opens 0fr->1fr + children settle (CSS).
   collapse: content-first (fade) THEN geometry (row collapses).            */
function toggleNode(wrap) {
  const expanded = wrap.dataset.expanded === "true";
  const row = $(":scope > .row", wrap);
  const depth = Number(wrap.dataset.depth);
  const level = wrap._level;

  if (!expanded) {
    // ensure children mounted on demand
    mountChildren(wrap, wrap._node, depth, level);
    wrap.dataset.expanded = "true";
    row.setAttribute("aria-expanded", "true");
    pressRelease(row);
    if (!reduced()) {
      wrap.dataset.settling = "true";
      // clear the settle flag after the longest child delay + duration
      window.setTimeout(() => (wrap.dataset.settling = "false"), 360);
    }
  } else {
    // collapse exit: content-first then geometry (non-negotiable)
    if (reduced()) {
      wrap.dataset.expanded = "false";
      row.setAttribute("aria-expanded", "false");
      return;
    }
    const inner = $(".children__inner", wrap);
    inner.animate([{ opacity: 1 }, { opacity: 0 }], {
      duration: 90,
      easing: "ease-in",
      fill: "forwards",
    });
    window.setTimeout(() => {
      wrap.dataset.expanded = "false";
      row.setAttribute("aria-expanded", "false");
      // restore inner opacity for next expand (grid handles the geometry)
      inner.getAnimations().forEach((a) => a.cancel());
    }, 90);
  }
}

/* ---- tree keyboard model (role=tree): ↑/↓ rows, →/← expand, Enter toggle */
treeRoot.addEventListener("keydown", (e) => {
  const rows = $$(".row", treeRoot).filter((r) => isVisibleRow(r));
  const cur = document.activeElement.closest(".row");
  let i = rows.indexOf(cur);
  switch (e.key) {
    case "ArrowDown":
      e.preventDefault();
      focusRow(rows[Math.min(i + 1, rows.length - 1)]);
      break;
    case "ArrowUp":
      e.preventDefault();
      focusRow(rows[Math.max(i - 1, 0)]);
      break;
    case "ArrowRight":
      e.preventDefault();
      if (cur && cur.dataset.container === "true") {
        const w = cur.closest(".node");
        if (w.dataset.expanded === "false") toggleNode(w);
        else focusRow(rows[Math.min(i + 1, rows.length - 1)]);
      }
      break;
    case "ArrowLeft":
      e.preventDefault();
      if (cur) {
        const w = cur.closest(".node");
        if (w.dataset.container === "true" && w.dataset.expanded === "true")
          toggleNode(w);
        else {
          const parent = w.parentElement.closest(".node");
          if (parent) focusRow($(":scope > .row", parent));
        }
      }
      break;
    case "Enter":
    case " ":
      if (cur && cur.dataset.container === "true") {
        e.preventDefault();
        toggleNode(cur.closest(".node"));
      }
      break;
    case "Home":
      e.preventDefault();
      focusRow(rows[0]);
      break;
    case "End":
      e.preventDefault();
      focusRow(rows[rows.length - 1]);
      break;
  }
});
function focusRow(row) {
  if (!row) return;
  $$(".row", treeRoot).forEach((r) => (r.tabIndex = -1));
  row.tabIndex = 0;
  row.focus();
}
function isVisibleRow(row) {
  // a row is visible if no ancestor node is collapsed
  let n = row.closest(".node").parentElement;
  while (n && n !== treeRoot) {
    const node = n.closest(".node");
    if (!node) break;
    if (node.dataset.expanded === "false") return false;
    n = node.parentElement;
  }
  return true;
}

/* ============================ REPL RENDERER =========================== */
const replCode = $("#repl-code");
const replPanel = $("#repl");

/* *print-level* / *print-length* honored locally so a huge tree can't dump
   infinitely. The contract already caps the tree; these mirror the printer's
   own ellipsis so we show a truthful `… (+N more)` rather than nothing.       */
const REPL_PRINT_LEVEL = 12; // nesting depth before "#" (matches contract)
const REPL_PRINT_LENGTH = 200; // siblings before "… (+N more)"

/* Render the REPL view by RECURSIVELY deriving the printed form from the typed
   tree (the same `root` the Tree view walks) — NOT just the top-level opaque
   `repl` string. A hash-table prints its GENUINE opaque header followed by a
   clearly-labeled DERIVED block; we never invent contents inside `#<…>`.       */
function renderRepl(doc) {
  replCode.innerHTML = "";
  const env = el("span", "repl__env");
  env.textContent =
    ";; *print-readably* nil · *print-pretty* t · addresses dimmed · floats shown as Nd0\n";
  replCode.appendChild(env);

  const root = doc.root;
  if (!root) {
    // no tree (shouldn't happen for ok docs) — fall back to the raw string
    replCode.appendChild(highlightLisp(doc.repl || "NULL"));
    return;
  }
  // build the derived text once (used by both render + copy), then render it.
  const lines = [];
  emitNode(root, { indent: 0, depth: 0, lines });
  // render line-by-line so we can color each token but keep `pre` whitespace.
  for (const ln of lines) {
    if (ln.kind === "comment") {
      replCode.appendChild(span("repl__derived", ln.text + "\n"));
    } else {
      replCode.appendChild(highlightLisp(ln.text + "\n"));
    }
  }
  // stash the full derived plain text for the copy button.
  replPanel._copyText = lines.map((l) => l.text).join("\n");
}

const pad = (n) => " ".repeat(n);

/* Emit the multi-line derived form for a node into `lines`.
   - hash-table: opaque header + a labeled alist (`(hash-table-alist …)`);
     entries are dotted pairs `("key" . value)`, `.` aligned in the group.
   - vector: `#( … )` with items inline (scalars) or expanded (collections).
   - scalar: its own genuine `repl`.                                            */
function emitNode(node, { indent, depth, lines, prefix = "" }) {
  if (node.type === "hash-table") {
    emitHashTable(node, { indent, depth, lines, prefix });
  } else if (node.type === "vector") {
    emitVector(node, { indent, depth, lines, prefix });
  } else {
    lines.push({ kind: "code", text: prefix + scalarRepl(node) });
  }
}

/* Render a HASH-TABLE as its genuine opaque header followed by a clearly
   labeled, reconstructable ALIST — exactly what `(alexandria:hash-table-alist
   ht)` returns: a list of dotted pairs `("key" . value)`. We never fabricate
   contents inside `#<…>`; the alist is plainly a derived form BELOW it.
   `prefix` puts the header at the right column (e.g. after a parent's
   `("key" . `); `indent` is the column the alist body indents to.            */
function emitHashTable(node, { indent, depth, lines, prefix, headerEmitted = false }) {
  // genuine opaque header (verbatim from the server) — never fabricated.
  // headerEmitted: the caller already printed the header on a dotted-pair line
  // (nested table as a cdr), so we go straight to the derived alist.
  if (!headerEmitted) {
    const header = node.repl || "#<HASH-TABLE>";
    lines.push({ kind: "code", text: prefix + header });
  }

  if (depth >= REPL_PRINT_LEVEL) return; // *print-level* guard
  const entries = node.entries || [];
  const total = node.childCount ?? entries.length;
  if (total === 0) {
    // honest empty alist for an empty table
    lines.push({ kind: "comment", text: pad(indent) + ";; (hash-table-alist …) => NIL" });
    return;
  }

  // the labeled derived block (clearly a reconstructable alist, not the print)
  lines.push({
    kind: "comment",
    text:
      pad(indent) +
      ";; (hash-table-alist …) — the same contents as a reconstructable alist:",
  });

  const shown = Math.min(entries.length, REPL_PRINT_LENGTH);
  const remaining = total - shown;
  // align the dotted-pair `.` within this sibling group: widest key-repl wins.
  let keyW = 0;
  for (let i = 0; i < shown; i++) {
    keyW = Math.max(keyW, scalarRepl(entries[i].key).length);
  }
  // the alist's own `(` sits at `indent`; each pair is one column further in,
  // so the pairs line up vertically under the alist opener.
  const listCol = pad(indent);
  const pairCol = pad(indent + 1);
  for (let i = 0; i < shown; i++) {
    const { key, val } = entries[i];
    const kRepl = scalarRepl(key);
    const open = i === 0 ? listCol + "(" : pairCol; // first pair opens the list
    const lead = open + "(" + kRepl + pad(keyW - kRepl.length) + " . ";
    const isLast = i === shown - 1 && remaining <= 0;
    const closeList = isLast ? ")" : ""; // close the alist on its final pair

    if (val.type === "hash-table") {
      // the cdr is itself a hash-table: print its genuine opaque header inside
      // the dotted pair (the pair closes right after it), then expand ITS alist
      // indented one level under this pair so the nesting is honest.
      const subHeader = val.repl || "#<HASH-TABLE>";
      lines.push({ kind: "code", text: lead + subHeader + ")" + closeList });
      const subEntries = val.entries || [];
      const subTotal = val.childCount ?? subEntries.length;
      if (depth + 1 < REPL_PRINT_LEVEL && subTotal > 0) {
        emitHashTable(val, {
          indent: indent + 3,
          depth: depth + 1,
          lines,
          // suppress the header line we already emitted on the pair
          prefix: pad(indent + 3),
          headerEmitted: true,
        });
      }
    } else if (val.type === "vector") {
      // the cdr is a vector: scalars inline `#(…)`; nested collections expand,
      // one element per line, indented under the value start.
      emitVector(val, {
        indent: lead.length,
        depth: depth + 1,
        lines,
        prefix: lead,
        closeWith: ")" + closeList,
      });
    } else {
      lines.push({
        kind: "code",
        text: lead + scalarRepl(val) + ")" + closeList,
      });
    }
  }
  if (remaining > 0) {
    // *print-length* truncation, kept Lisp-honest: an explicit `…` element in
    // the list, then close the alist. Reads as a list that simply goes on.
    lines.push({ kind: "code", text: pairCol + "…)" });
    lines.push({
      kind: "comment",
      text: pairCol + `;; +${fmtInt(remaining)} more pairs`,
    });
  }
}

/* Emit a vector as honest Lisp `#( … )`. `closeWith` is an optional suffix
   (e.g. the dotted-pair / alist closing parens) appended to the vector's own
   terminal token, so paren-matching stays exact when a vector is a cdr.       */
function emitVector(node, { indent, depth, lines, prefix, closeWith = "" }) {
  const items = node.items || [];
  const total = node.childCount ?? items.length;
  if (depth >= REPL_PRINT_LEVEL) {
    lines.push({ kind: "code", text: prefix + "#" + closeWith });
    return;
  }
  // a vector of pure scalars prints inline on one line: #("a" "b" 1)
  const allScalar = items.every((it) => !isContainer(it));
  const shown = Math.min(items.length, REPL_PRINT_LENGTH);
  if (allScalar && total <= REPL_PRINT_LENGTH) {
    const inner = items.map((it) => scalarRepl(it)).join(" ");
    lines.push({ kind: "code", text: prefix + `#(${inner})` + closeWith });
    return;
  }
  // otherwise expand: one item per line, indented under the opener.
  lines.push({ kind: "code", text: prefix + "#(" });
  const itemIndent = indent + 2;
  for (let i = 0; i < shown; i++) {
    const it = items[i];
    if (isContainer(it)) {
      emitNode(it, {
        indent: itemIndent,
        depth: depth + 1,
        lines,
        prefix: pad(itemIndent),
      });
    } else {
      lines.push({ kind: "code", text: pad(itemIndent) + scalarRepl(it) });
    }
  }
  const remaining = total - shown;
  if (remaining > 0) {
    lines.push({
      kind: "code",
      text: pad(itemIndent) + "…",
    });
    lines.push({
      kind: "comment",
      text: pad(itemIndent) + `;; +${fmtInt(remaining)} more items`,
    });
  }
  lines.push({ kind: "code", text: pad(indent) + ")" + closeWith });
}

/* the genuine printed form of a scalar node (its own `repl`). Falls back to a
   derived form only if the server omitted it. Strings quoted, ints, 4.5d0
   floats, T/NIL/NULL — all already in `node.repl`.                            */
function scalarRepl(node) {
  if (node.repl != null) return node.repl;
  // defensive fallbacks (the contract always provides repl)
  switch (node.type) {
    case "string":
      return JSON.stringify(node.value ?? "");
    case "integer":
    case "float":
      return node.lisp ?? String(node.value);
    case "true":
      return "T";
    case "false":
      return "NIL";
    case "null":
      return "NULL";
    case "hash-table":
      return "#<HASH-TABLE>";
    case "vector":
      return "#()";
    default:
      return String(node.value ?? "");
  }
}

/* tokenize + color the genuine prin1 string with the SAME 8 type hues.
   This is a *display* highlighter over the verbatim string — never parsed
   for data. We classify tokens; the address span gets .lt-addr (muted).    */
function highlightLisp(src) {
  const frag = document.createDocumentFragment();
  // token regex (ordered): address, the HASH-TABLE opaque header (sky/map),
  // the dotted-pair `.` (a standalone period between car & cdr — muted punct,
  // matched space-bounded so it never collides with a float's `.`), strings,
  // d0-floats, plain floats, integers, T/NIL/NULL, the truncation `…`,
  // :KEYWORD, parens/brackets/#<>, whitespace.
  const re =
    /(\{[0-9A-Fa-f]{4,}\})|(#<HASH-TABLE\b)|(?<= )(\.)(?= )|("(?:[^"\\]|\\.)*")|(#\()|(\bNULL\b)|(\bNIL\b)|(\bT\b)|(-?\d+\.\d+d-?\d+|-?\d+d-?\d+|-?\d+\.\d+e-?\d+)|(-?\d+\.\d+)|(-?\d+)|(…)|(:[A-Za-z%*+/<>=!?.\-]+)|([()\[\]#<>])|(\s+)/g;
  let m;
  let last = 0;
  while ((m = re.exec(src)) !== null) {
    if (m.index > last) frag.appendChild(text(src.slice(last, m.index)));
    last = re.lastIndex;
    if (m[1]) frag.appendChild(span("lt-addr", m[1])); // volatile address
    else if (m[2]) frag.appendChild(span("lt-map", m[2])); // #<HASH-TABLE header
    else if (m[3]) frag.appendChild(span("lt-punct", m[3])); // dotted-pair `.`
    else if (m[4]) frag.appendChild(span("lt-str", m[4])); // string
    else if (m[5]) frag.appendChild(span("lt-vec", m[5])); // #(
    else if (m[6]) frag.appendChild(span("lt-null", m[6])); // NULL
    else if (m[7]) frag.appendChild(span("lt-nil", m[7])); // NIL
    else if (m[8]) frag.appendChild(span("lt-true", m[8])); // T
    else if (m[9]) frag.appendChild(span("lt-flt", m[9])); // d0 float
    else if (m[10]) frag.appendChild(span("lt-flt", m[10])); // plain float
    else if (m[11]) frag.appendChild(span("lt-int", m[11])); // integer
    else if (m[12]) frag.appendChild(span("lt-punct", m[12])); // truncation …
    else if (m[13]) frag.appendChild(span("lt-key", m[13])); // :KEYWORD
    else if (m[14]) frag.appendChild(span("lt-punct", m[14])); // parens/punct
    else frag.appendChild(text(m[0])); // whitespace
  }
  if (last < src.length) frag.appendChild(text(src.slice(last)));
  return frag;
}
const span = (cls, t) => {
  const s = el("span", cls);
  s.textContent = t;
  return s;
};
const text = (t) => document.createTextNode(t);

/* identity toggle (show/hide volatile address) */
$("#identity-btn").addEventListener("click", (e) => {
  const btn = e.currentTarget;
  const on = btn.getAttribute("aria-pressed") !== "true";
  btn.setAttribute("aria-pressed", String(on));
  replPanel.dataset.identity = String(on);
});

/* copy button */
$("#copy-btn").addEventListener("click", async (e) => {
  const btn = e.currentTarget;
  // copy the FULL rendered REPL text (the expanded derived form), not the
  // one-line opaque header. Falls back to the raw repl string if unbuilt.
  const src =
    replPanel._copyText || state.docs[state.docIndex]?.repl || "";
  try {
    await navigator.clipboard.writeText(src);
  } catch {
    /* ignore — file:// may block clipboard */
  }
  const orig = btn.innerHTML;
  btn.classList.add("btn--ok");
  btn.innerHTML = `<svg aria-hidden="true"><use href="#g-check" /></svg>copied`;
  pressRelease(btn);
  setTimeout(() => {
    btn.classList.remove("btn--ok");
    btn.innerHTML = orig;
  }, 1400);
});

/* ============================ CARDS RENDERER ========================== */
const cardsRoot = $("#cards-root");

function renderCards(root) {
  cardsRoot.innerHTML = "";
  // the root container becomes the top-level grid of cards
  if (!isContainer(root)) {
    // a scalar document → a single small card
    cardsRoot.appendChild(scalarCard("root", root));
    return;
  }
  const grid = el("div", "cardgrid");
  const kids =
    root.type === "hash-table" ? root.entries || [] : root.items || [];
  const total = childCountOf(root);
  const shown = Math.min(kids.length, MAX_CHILDREN);
  for (let i = 0; i < shown; i++) {
    if (root.type === "hash-table") {
      const { key, val } = kids[i];
      grid.appendChild(buildCard(keyLabel(key), val, 1));
    } else {
      grid.appendChild(buildCard(`[${i}]`, kids[i], 1));
    }
  }
  if (total - shown > 0) grid.appendChild(moreCard(total - shown, root.type));
  cardsRoot.appendChild(grid);
}

function keyLabel(keyNode) {
  return keyNode.type === "string" ? keyNode.value : scalarText(keyNode);
}

/* build a card for a container/scalar at a given depth.
   Depth >= CARDS_MAX_DEPTH: STOP drawing boxes → handoff chip.             */
function buildCard(key, node, depth) {
  if (!isContainer(node)) return scalarCard(key, node);

  const count = childCountOf(node);
  const t = TYPE[node.type];
  const card = el("div", `card ${t.cls}` + (depth >= 2 ? " card--raised" : ""));

  // head: glyph · key ········ LABEL {count}  (B.4)
  card.appendChild(cardHead(node.type, key, count));

  // body
  const body = el("div", "card__body");
  const kids = node.type === "hash-table" ? node.entries || [] : node.items || [];

  // a vector of pure scalars → one tight inline list, not N cards
  if (node.type === "vector" && kids.every((it) => !isContainer(it))) {
    const seq = el("div", "inlineseq");
    const shown = Math.min(kids.length, MAX_CHILDREN);
    for (let i = 0; i < shown; i++) seq.appendChild(scalarChip(kids[i]));
    if (count - shown > 0) {
      const more = el("span", "chip chip__more");
      more.textContent = `+${fmtInt(count - shown)} more`;
      seq.appendChild(more);
    }
    body.appendChild(seq);
    card.appendChild(body);
    return card;
  }

  const shown = Math.min(kids.length, MAX_CHILDREN);
  for (let i = 0; i < shown; i++) {
    let childKey, childVal;
    if (node.type === "hash-table") {
      childKey = keyLabel(kids[i].key);
      childVal = kids[i].val;
    } else {
      childKey = `[${i}]`;
      childVal = kids[i];
    }
    if (isContainer(childVal)) {
      if (depth + 1 >= CARDS_MAX_DEPTH) {
        // depth >= 3 → handoff chip (hands off to Tree focused at that node)
        body.appendChild(handoffField(childKey, childVal));
      } else {
        body.appendChild(buildCard(childKey, childVal, depth + 1));
      }
    } else {
      body.appendChild(scalarField(childKey, childVal));
    }
  }
  if (count - shown > 0) {
    const f = el("div", "field");
    const more = el("span", "chip chip__more");
    more.textContent = `+${fmtInt(count - shown)} more`;
    f.appendChild(more);
    body.appendChild(f);
  }
  card.appendChild(body);
  return card;
}

/* card header: leading glyph · key ········ LABEL {count} (B.4 order) */
function cardHead(type, key, count) {
  const t = TYPE[type];
  const head = el("div", `card__head ${t.cls}`);
  const g = el("span", `tag ${t.cls}`);
  g.appendChild(glyphEl(type, { count: null }));
  head.appendChild(g);
  const k = el("span", "card__key");
  k.textContent = key;
  head.appendChild(k);
  if (count != null) {
    const meta = el("span", "card__meta");
    const lab = el("span", "card__metalabel");
    lab.textContent = t.label;
    meta.appendChild(lab);
    const c = el("span", "card__metacount");
    const open = type === "hash-table" ? "{" : "[";
    const close = type === "hash-table" ? "}" : "]";
    c.textContent = `${open}${fmtInt(count)}${close}`;
    meta.appendChild(c);
    head.appendChild(meta);
  }
  return head;
}

function scalarCard(key, node) {
  const t = TYPE[node.type];
  const card = el("div", `card ${t.cls}`);
  card.appendChild(cardHead(node.type, key, null));
  const body = el("div", "card__body");
  const f = el("div", "field");
  const fv = el("span", `field__val ${t.cls}`);
  fv.style.color = "var(--type)";
  fv.appendChild(scalarValueInline(node));
  f.appendChild(el("span", "field__key")).textContent = "value";
  f.appendChild(fv);
  body.appendChild(f);
  card.appendChild(body);
  return card;
}

function scalarField(key, node) {
  const t = TYPE[node.type];
  const f = el("div", "field");
  const fk = el("span", "field__key");
  fk.appendChild(tagEl(node.type, { label: false }));
  const kspan = el("span");
  kspan.textContent = key;
  fk.appendChild(kspan);
  f.appendChild(fk);
  const fv = el("span", `field__val ${t.cls}`);
  fv.style.color = "var(--type)";
  fv.appendChild(scalarValueInline(node));
  f.appendChild(fv);
  return f;
}

function handoffField(key, node) {
  const count = childCountOf(node);
  const t = TYPE[node.type];
  const f = el("div", "field");
  const fk = el("span", "field__key");
  const kspan = el("span");
  kspan.textContent = key;
  fk.appendChild(kspan);
  f.appendChild(fk);
  const chip = el("button", `chip ${t.cls}`);
  chip.type = "button";
  chip.style.color = "var(--type)";
  chip.appendChild(glyphEl(node.type, { count }));
  const open = el("span", "chip__more");
  open.textContent = "open in tree →";
  chip.appendChild(open);
  chip.title = `depth-capped — open ${TYPE[node.type].label} in Tree`;
  chip.addEventListener("click", () => {
    pressRelease(chip);
    setView("tree", { animate: true, focus: false });
    // (a fuller impl would scroll/focus the matching tree node)
  });
  f.appendChild(chip);
  return f;
}

function scalarChip(node) {
  const t = TYPE[node.type];
  const c = el("span", `chip ${t.cls}`);
  c.style.color = "var(--type)";
  c.appendChild(scalarValueInline(node, true));
  return c;
}

/* inline scalar value. withGlyph=true keeps the T/NIL/NULL shape glyph
   (used in chips that have no leading glyph); fields pass false to avoid a
   duplicate of the leading field-key glyph. */
function scalarValueInline(node, withGlyph = false) {
  const t = TYPE[node.type];
  const frag = document.createDocumentFragment();
  if (node.type === "true" || node.type === "false" || node.type === "null") {
    if (withGlyph && t.svg) frag.appendChild(svgUse(t.svg));
    const s = el("span");
    s.textContent = node.type === "true" ? "T" : node.type === "false" ? "NIL" : "NULL";
    frag.appendChild(s);
  } else {
    const s = el("span");
    s.textContent =
      node.type === "string"
        ? JSON.stringify(node.value)
        : node.lisp ?? String(node.value);
    frag.appendChild(s);
  }
  return frag;
}

function moreCard(remaining, parentType) {
  const card = el("div", "card t-null");
  const head = el("div", "card__head");
  const k = el("span", "card__key");
  k.textContent = `+${fmtInt(remaining)} more ${
    parentType === "hash-table" ? "entries" : "items"
  }`;
  k.style.color = "var(--text-secondary)";
  head.appendChild(k);
  card.appendChild(head);
  return card;
}

/* helper: an inline <svg><use> */
function svgUse(id) {
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  const use = document.createElementNS("http://www.w3.org/2000/svg", "use");
  use.setAttribute("href", "#" + id);
  svg.appendChild(use);
  svg.setAttribute("aria-hidden", "true");
  return svg;
}

/* ============================ ERROR RENDERER ========================== */
const errorwrap = $("#errorwrap");
function renderError(err, sourceYaml = "") {
  errorwrap.innerHTML = "";
  const card = el("div", "errorcard");
  const head = el("div", "errorcard__head");
  // Lead with a plain-language verdict: every condition the parser raises means
  // the document is not valid YAML. The precise condition stays on as detail.
  const isYaml = /yaml/i.test(err.condition || "yaml-parse-error");
  const verdict = el("span", "errorcard__verdict");
  verdict.textContent = isYaml ? "Invalid YAML 1.2" : "Error";
  head.appendChild(verdict);
  const cond = el("span", "errorcard__cond");
  cond.textContent = err.condition || "yaml-parse-error";
  head.appendChild(cond);
  if (err.line != null) {
    const loc = el("span", "errorcard__loc");
    loc.textContent = `line ${err.line}:${err.column ?? 0}`;
    head.appendChild(loc);
  }

  // Build a plain-text version of the whole error (verdict, condition, location,
  // message, and the source excerpt with caret) so it can be copied in one
  // click and pasted verbatim.
  let copyText =
    (isYaml ? "Invalid YAML 1.2 — " : "") + (err.condition || "yaml-parse-error");
  if (err.line != null) copyText += ` at line ${err.line}:${err.column ?? 0}`;
  copyText += `\n${err.message || "Could not parse the document."}`;
  if (sourceYaml && err.line != null) {
    const cl = sourceYaml.split("\n");
    const cln = err.line - 1;
    for (let i = Math.max(0, cln - 1); i < Math.min(cl.length, cln + 2); i++) {
      copyText += `\n${String(i + 1).padStart(3, " ")} │ ${cl[i]}`;
      if (i === cln && err.column != null) {
        copyText += `\n${" ".repeat(6 + err.column)}^`;
      }
    }
  }

  // Copy button — same pattern as the REPL view's copy control.
  const copyBtn = el("button", "btn errorcard__copy");
  copyBtn.type = "button";
  copyBtn.innerHTML = `<svg aria-hidden="true"><use href="#g-copy" /></svg>copy`;
  copyBtn.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(copyText);
    } catch {
      /* ignore — file:// may block clipboard */
    }
    const orig = copyBtn.innerHTML;
    copyBtn.classList.add("btn--ok");
    copyBtn.innerHTML = `<svg aria-hidden="true"><use href="#g-check" /></svg>copied`;
    if (typeof pressRelease === "function") pressRelease(copyBtn);
    setTimeout(() => {
      copyBtn.classList.remove("btn--ok");
      copyBtn.innerHTML = orig;
    }, 1400);
  });
  head.appendChild(copyBtn);

  card.appendChild(head);

  const body = el("div", "errorcard__body");
  const msg = el("div", "errorcard__msg");
  msg.textContent = err.message || "Could not parse the document.";
  body.appendChild(msg);

  // a small source excerpt with a caret, if we have the line
  if (sourceYaml && err.line != null) {
    const lines = sourceYaml.split("\n");
    const ln = err.line - 1;
    const src = el("div", "errorcard__src");
    const start = Math.max(0, ln - 1);
    const end = Math.min(lines.length, ln + 2);
    for (let i = start; i < end; i++) {
      const num = String(i + 1).padStart(3, " ");
      if (i === ln) {
        const a = span("", `${num} │ `);
        const b = el("span", "errorcard__mark");
        b.textContent = lines[i];
        src.appendChild(a);
        src.appendChild(b);
        src.appendChild(text("\n"));
        const caret = err.column != null ? " ".repeat(6 + err.column) + "^" : "";
        src.appendChild(span("errorcard__caret", caret + "\n"));
      } else {
        src.appendChild(text(`${num} │ ${lines[i]}\n`));
      }
    }
    body.appendChild(src);
  }
  card.appendChild(body);
  errorwrap.appendChild(card);
  errorwrap.hidden = false;
}
function clearError() {
  errorwrap.hidden = true;
  errorwrap.innerHTML = "";
}

/* ============================ STATUS + ANNOUNCE ====================== */
function setStatus(stats) {
  $("#st-nodes").textContent = stats ? fmtInt(stats.nodes) : "—";
  $("#st-levels").textContent = stats ? fmtInt(stats.levels) : "—";
  $("#st-showing").textContent = stats ? fmtInt(stats.rendered) : "—";
}
let liveTimer;
function announce(msg) {
  const live = $("#st-live");
  live.textContent = msg;
}

/* ============================ ORCHESTRATION ========================== */
let _renderedViews = { tree: false, repl: false, cards: false };

function loadDoc(doc) {
  // doc: {root, repl, stats}
  clearError();
  $("#dropzone").hidden = true;
  _renderedViews = { tree: false, repl: false, cards: false };
  setStatus(doc.stats);
  renderActiveView();
}

function renderActiveView() {
  const doc = state.docs[state.docIndex];
  if (!doc) return;
  if (state.view === "tree" && !_renderedViews.tree) {
    if (doc.empty) renderEmpty(treeRoot, doc.root);
    else renderTree(doc.root, doc.stats);
    _renderedViews.tree = true;
    bindLiveEdge(treeRoot);
    // give the root row keyboard focusability
    const first = $(".row", treeRoot);
    if (first) first.tabIndex = 0;
  } else if (state.view === "repl" && !_renderedViews.repl) {
    renderRepl(doc);
    _renderedViews.repl = true;
  } else if (state.view === "cards" && !_renderedViews.cards) {
    if (doc.empty) renderEmpty(cardsRoot, doc.root);
    else renderCards(doc.root);
    _renderedViews.cards = true;
    bindLiveEdge(cardsRoot);
  }
}

function renderEmpty(container, root) {
  container.innerHTML = "";
  const note = el("div", "emptynote");
  const tag = tagEl(root.type, { label: true });
  note.appendChild(tag);
  const t = el("div");
  t.textContent =
    root.type === "null"
      ? "empty document — parsed to the symbol NULL"
      : "empty document";
  note.appendChild(t);
  container.appendChild(note);
}

/* ---- multi-document stream tab strip ---- */
function buildDocStrip() {
  const strip = $("#docstrip");
  if (state.docs.length <= 1) {
    strip.hidden = true;
    strip.innerHTML = "";
    return;
  }
  strip.hidden = false;
  strip.innerHTML = "";
  state.docs.forEach((d, i) => {
    const tab = el("button", "doctab");
    tab.setAttribute("role", "tab");
    tab.setAttribute("aria-selected", String(i === state.docIndex));
    tab.textContent = `doc ${i + 1}`;
    tab.addEventListener("click", () => {
      state.docIndex = i;
      $$(".doctab", strip).forEach((t, j) =>
        t.setAttribute("aria-selected", String(j === i))
      );
      loadDoc(state.docs[i]);
    });
    strip.appendChild(tab);
  });
}

/* ---- ingest a server/fixture envelope ---- */
function ingest(envelope, sourceYaml = "") {
  if (!envelope.ok) {
    $("#dropzone").hidden = true;
    setStatus(null);
    renderError(envelope.error || {}, sourceYaml);
    return;
  }
  // single-doc OR multi-document stream
  let docs;
  if (Array.isArray(envelope.documents)) {
    docs = envelope.documents.map((d) => normalizeDoc(d));
  } else {
    docs = [normalizeDoc(envelope)];
  }
  state.docs = docs;
  state.docIndex = 0;
  buildDocStrip();
  loadDoc(docs[0]);
}

function normalizeDoc(d) {
  const root = d.root;
  const empty =
    !root ||
    root.type === "null" ||
    (isContainer(root) && childCountOf(root) === 0);
  return {
    root: root || { type: "null", repl: "NULL" },
    repl: d.repl ?? "",
    stats: d.stats ?? { nodes: 0, levels: 0, rendered: 0 },
    empty,
  };
}

/* ============================ NETWORK ================================ */
async function parse(yaml, multi = false) {
  showLoaderGated();
  try {
    const res = await fetch("/api/parse", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ yaml, multi }),
    });
    const data = await res.json();
    ingest(data, yaml);
  } catch (e) {
    renderError(
      { condition: "network-error", message: String(e) },
      yaml
    );
  } finally {
    hideLoader();
  }
}

/* loader gated behind 150ms (local parse usually <120ms → never shows) */
let loaderTimer;
function showLoaderGated() {
  clearTimeout(loaderTimer);
  loaderTimer = setTimeout(() => ($("#shimmer").hidden = false), 150);
}
function hideLoader() {
  clearTimeout(loaderTimer);
  $("#shimmer").hidden = true;
}

/* ============================ FILE DROP / PASTE ====================== */
function armDrop(on) {
  stage.dataset.armed = String(on);
}
["dragenter", "dragover"].forEach((ev) =>
  stage.addEventListener(ev, (e) => {
    e.preventDefault();
    armDrop(true);
  })
);
["dragleave", "drop"].forEach((ev) =>
  stage.addEventListener(ev, (e) => {
    if (ev === "dragleave" && stage.contains(e.relatedTarget)) return;
    armDrop(false);
  })
);
stage.addEventListener("drop", async (e) => {
  e.preventDefault();
  const file = e.dataTransfer.files[0];
  if (!file) return;
  const text = await file.text();
  parse(text, /---/.test(text.slice(text.indexOf("\n"))));
});
window.addEventListener("paste", (e) => {
  if ($("#dropzone").hidden) return; // only the empty state accepts paste
  const text = e.clipboardData.getData("text");
  if (text.trim()) parse(text, text.includes("\n---"));
});

/* native file picker — same parse path as drop/paste. The <label> wrapping a
   visually-hidden <input> keeps it one keyboard-operable control (Space/Enter
   on the label opens the OS picker). */
$("#file-input").addEventListener("change", async (e) => {
  const file = e.target.files && e.target.files[0];
  if (!file) return;
  const txt = await file.text();
  parse(txt, /\n---/.test(txt));
  e.target.value = ""; // allow re-selecting the same file
});

/* ============================ THEME ================================== */
$("#theme-btn").addEventListener("click", () => {
  const root = document.documentElement;
  root.dataset.theme = root.dataset.theme === "light" ? "dark" : "light";
});

/* ============================ BOOT =================================== */
async function boot() {
  // size the toggle pill to equal-width segments (no width animation)
  // lock all options to the widest measured width
  let maxW = 0;
  opts.forEach((o) => (maxW = Math.max(maxW, o.offsetWidth)));
  opts.forEach((o) => (o.style.width = maxW + "px"));
  toggle.style.setProperty("--pill-w", maxW + "px");
  pill.style.setProperty("--pill-x", "0px");

  const params = new URLSearchParams(location.search);
  const fx = params.get("fixture");
  const v = params.get("view");

  if (fx) {
    // DEV PATH: render straight from a fixture, no backend needed
    try {
      const res = await fetch(`./fixtures/${fx}`);
      const data = await res.json();
      ingest(data, data._sourceYaml || "");
    } catch (e) {
      renderError({ condition: "fixture-load-error", message: String(e) });
    }
  }
  // else: empty state with dropzone visible (real backend path waits for drop)

  if (v && ["tree", "repl", "cards"].includes(v)) {
    setView(v, { animate: false });
  }
}

REDUCED.addEventListener?.("change", () => {
  /* re-render not required; CSS branch handles statics */
});

boot();

/* expose for the screenshot harness */
window.__app = { setView, ingest, parse, state };
