(function () {
  'use strict';

  // Written in plain ES5 on purpose: iOS 12's WebKit is Safari 12.
  var S = {
    emptyTitle: '',
    emptySub: '',
    copy: 'Copy',
    copyCode: 'Copy',
    copied: 'Copied',
    regenerate: 'Regenerate',
    retry: 'Retry',
    edit: 'Edit',
    save: 'Save',
    share: 'Share',
    thinking: 'Thinking…',
    thoughtFor: 'Thought for %d s',
    thoughtShort: 'Thought'
  };

  var msgsEl = document.getElementById('messages');
  var toastEl = document.getElementById('toast');
  var current = null;     // the reply that is being streamed right now
  var stick = true;       // follow the bottom while streaming, unless the user scrolled up
  var toastTimer = null;
  var RENDER_INTERVAL = 70;   // ms: smooth streaming cadence
  var COLLAPSE_HEIGHT = 240;  // px: messages taller than this get a compact box + bottom-right arrow

  function ensureScrollable() {
    try {
      // An empty chat has nothing to scroll: keep the page locked so the greeting card cannot be dragged.
      var empty = !!document.getElementById('empty');
      var ov = empty ? 'hidden' : 'auto';
      var ta = empty ? 'none' : 'pan-y';
      document.documentElement.style.overflowY = ov;
      document.documentElement.style.touchAction = ta;
      document.body.style.overflowY = ov;
      document.body.style.touchAction = ta;
      document.body.style.webkitOverflowScrolling = 'touch';
      if (msgsEl) {
        msgsEl.style.overflowY = 'visible';
        msgsEl.style.touchAction = ta;
      }
    } catch (e) {}
  }

  ensureScrollable();

  function post(obj) {
    try { window.webkit.messageHandlers.native.postMessage(obj); } catch (e) { /* not inside the app */ }
  }

  function nearBottom() {
    return window.innerHeight + window.pageYOffset >= document.documentElement.scrollHeight - 60;
  }

  function toBottom(force) {
    ensureScrollable();
    if (force || stick) {
      window.scrollTo(0, document.documentElement.scrollHeight);
    }
  }

  // Page errors go to the app's diagnostic log, so a problem can be reported with the real message.
  window.onerror = function (message, source, line) {
    post({ type: 'jserror', message: String(message), line: line });
    return false;
  };

  window.addEventListener('scroll', function () { stick = nearBottom(); updateJump(); }, false);
  window.addEventListener('touchmove', function () { ensureScrollable(); }, { passive: true });

  // "Scroll to latest" button: shown when the reader is away from the bottom (e.g. a reply grows below the screen).
  var jumpEl = document.createElement('div');
  jumpEl.id = 'jump';
  jumpEl.innerHTML = '<svg viewBox="0 0 24 24" width="22" height="22"><path d="M12 5v13M6 13l6 6 6-6" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  document.body.appendChild(jumpEl);
  var jumpAnim = null;

  function updateJump() {
    var away = document.documentElement.scrollHeight - (window.innerHeight + window.pageYOffset) > 120;
    var show = away && !document.getElementById('empty');
    jumpEl.className = show ? 'show' : '';
  }

  // Eased scroll to the bottom (iOS 12 has no smooth scrollTo).
  function glideToBottom() {
    if (jumpAnim) { cancelAnimationFrame(jumpAnim); }
    var from = window.pageYOffset, start = null;
    var dur = 240;
    function step(t) {
      if (start === null) { start = t; }
      var k = Math.min(1, (t - start) / dur);
      var e = 1 - Math.pow(1 - k, 3);
      var to = document.documentElement.scrollHeight - window.innerHeight;
      window.scrollTo(0, from + (to - from) * e);
      if (k < 1) { jumpAnim = requestAnimationFrame(step); } else { jumpAnim = null; stick = true; updateJump(); }
    }
    jumpAnim = requestAnimationFrame(step);
  }

  jumpEl.addEventListener('click', function () { glideToBottom(); }, false);
  window.addEventListener('touchstart', function () { if (jumpAnim) { cancelAnimationFrame(jumpAnim); jumpAnim = null; } }, { passive: true });

  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) { e.className = cls; }
    if (text !== undefined && text !== null) { e.textContent = text; }
    return e;
  }

  function toast(msg) {
    toastEl.textContent = msg;
    toastEl.className = 'show';
    if (toastTimer) { clearTimeout(toastTimer); }
    toastTimer = setTimeout(function () { toastEl.className = ''; }, 1400);
  }

  function arrowSVG(expanded) {
    if (expanded) {
      return '<svg viewBox="0 0 24 24" width="16" height="16"><path d="M6 15l6-6 6 6" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>';
    }
    return '<svg viewBox="0 0 24 24" width="16" height="16"><path d="M6 9l6 6 6-6" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  }

  function applyCollapseIfNeeded(row, targetEl) {
    if (!row || !targetEl || row._streaming) return;
    var existingBtn = row.querySelector('.msg-expand-btn');
    if (existingBtn && existingBtn.parentNode) {
      existingBtn.parentNode.removeChild(existingBtn);
    }
    targetEl.classList.remove('msg-collapsible');
    targetEl.classList.remove('msg-collapsed');
    targetEl.classList.remove('msg-expanded');
    targetEl.style.maxHeight = '';

    // Replies are always shown in full, in one piece: there is no "show more" fold any more.
    return;
    var fullHeight = targetEl.scrollHeight || targetEl.offsetHeight || 0;
    if (fullHeight <= COLLAPSE_HEIGHT + 40) return;

    var collapsed = (row._userExpanded === true) ? false : true;
    targetEl.classList.add('msg-collapsible');
    if (collapsed) {
      targetEl.classList.add('msg-collapsed');
      targetEl.style.maxHeight = COLLAPSE_HEIGHT + 'px';
    } else {
      targetEl.classList.add('msg-expanded');
      targetEl.style.maxHeight = 'none';
    }

    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'msg-expand-btn' + (collapsed ? '' : ' is-expanded');
    btn.setAttribute('aria-label', collapsed ? 'Mở rộng' : 'Thu gọn');
    btn.innerHTML = arrowSVG(!collapsed);

    btn.addEventListener('click', function (ev) {
      if (ev && ev.stopPropagation) ev.stopPropagation();
      var nowCollapsed = targetEl.classList.contains('msg-collapsed');
      if (nowCollapsed) {
        targetEl.classList.remove('msg-collapsed');
        targetEl.classList.add('msg-expanded');
        targetEl.style.maxHeight = 'none';
        btn.classList.add('is-expanded');
        btn.setAttribute('aria-label', 'Thu gọn');
        btn.innerHTML = arrowSVG(true);
        row._userExpanded = true;
      } else {
        targetEl.classList.remove('msg-expanded');
        targetEl.classList.add('msg-collapsed');
        targetEl.style.maxHeight = COLLAPSE_HEIGHT + 'px';
        btn.classList.remove('is-expanded');
        btn.setAttribute('aria-label', 'Mở rộng');
        btn.innerHTML = arrowSVG(false);
        row._userExpanded = false;
      }
      updateJump();
    }, false);

    row.appendChild(btn);
  }

  function refreshAllCollapsibles() {
    if (!msgsEl) return;
    var rows = msgsEl.querySelectorAll('.row.user, .row.assistant');
    for (var i = 0; i < rows.length; i++) {
      var r = rows[i];
      if (r._streaming) continue;
      var target = r.querySelector('.body.md') || r.querySelector('.bubble');
      if (target) applyCollapseIfNeeded(r, target);
    }
  }

  function showEmpty() {
    msgsEl.innerHTML = '';
    var box = el('div', 'empty');
    box.id = 'empty';
    box.appendChild(el('div', 'logo'));
    box.appendChild(el('h1', null, S.emptyTitle));
    box.appendChild(el('p', null, S.emptySub));
    msgsEl.appendChild(box);
    jumpEl.className = '';
    document.documentElement.classList.add('is-empty');
    ensureScrollable();
    window.scrollTo(0, 0);
    post({ type: 'empty', value: true });
  }

  function removeEmpty() {
    var e = document.getElementById('empty');
    if (!e) { return; }
    if (e.parentNode) { e.parentNode.removeChild(e); }
    document.documentElement.classList.remove('is-empty');
    ensureScrollable();
    post({ type: 'empty', value: false });
  }

  function clearErrors() {
    var errs = msgsEl.querySelectorAll('.row.error');
    for (var i = 0; i < errs.length; i++) {
      errs[i].parentNode.removeChild(errs[i]);
    }
  }

  function actionButton(label, handler) {
    var b = el('button', 'act', label);
    b.type = 'button';
    b.addEventListener('click', handler, false);
    return b;
  }

  function buildActions(row) {
    var old = row.querySelector('.actions');
    if (old) { row.removeChild(old); }
    var box = el('div', 'actions');
    box.appendChild(actionButton(S.copy, function () {
      post({ type: 'copy', text: row._text || '' });
      toast(S.copied);
    }));
    box.appendChild(actionButton(S.save, function () {
      post({ type: 'save', text: row._text || '' });
    }));
    row.appendChild(box);
  }

  // The "Regenerate" button only belongs to the very last reply.
  function refreshRegenerate() {
    var old = msgsEl.querySelectorAll('.regen');
    for (var i = 0; i < old.length; i++) {
      old[i].parentNode.removeChild(old[i]);
    }
    var rows = msgsEl.children;
    var last = rows.length ? rows[rows.length - 1] : null;
    if (last && last.className.indexOf('assistant') >= 0 && !last._streaming) {
      var acts = last.querySelector('.actions');
      if (acts) {
        var b = actionButton(S.regenerate, function () { post({ type: 'regenerate' }); });
        b.className = 'act regen';
        acts.appendChild(b);
      }
    }
  }

  function extLabel(att) {
    if (att.kind === 'pdf') { return 'PDF'; }
    if (att.kind === 'image') { return 'IMG'; }
    var m = /\.([A-Za-z0-9]{1,5})$/.exec(att.name || '');
    return m ? m[1].toUpperCase() : 'TXT';
  }

  function bindImageTap(img, id) {
    img.addEventListener('click', function () { post({ type: 'image', id: id }); }, false);
  }

  function buildUserActions(row, messageIndex) {
    var box = el('div', 'actions');
    box.appendChild(actionButton(S.copy, function () {
      post({ type: 'copy', text: row._text || '' });
      toast(S.copied);
    }));
    box.appendChild(actionButton(S.edit, function () {
      post({ type: 'edit', index: messageIndex });
    }));
    row.appendChild(box);
  }

  // A user message: optional attachments (photo thumbnails / file chips) above the text.
  function addUser(text, atts, messageIndex) {
    var row = el('div', 'row user');
    var bubble = el('div', 'bubble');
    if (atts && atts.length) {
      var box = el('div', 'atts');
      for (var i = 0; i < atts.length; i++) {
        var a = atts[i];
        if (a.kind === 'image' && a.thumb) {
          var img = document.createElement('img');
          img.className = 'thumb';
          img.src = a.thumb;
          img.alt = a.name || '';
          bindImageTap(img, a.id);
          box.appendChild(img);
        } else {
          var chip = el('div', 'file');
          chip.appendChild(el('span', 'ext', extLabel(a)));
          chip.appendChild(el('span', 'fname', a.name || ''));
          box.appendChild(chip);
        }
      }
      bubble.appendChild(box);
    }
    if (text) { bubble.appendChild(el('div', 'btext', text)); }
    row.appendChild(bubble);
    row._text = text || '';
    msgsEl.appendChild(row);
    buildUserActions(row, messageIndex);
    applyCollapseIfNeeded(row, bubble);
  }

  function renderInto(node, text) {
    node.innerHTML = window.MD ? window.MD.render(text) : '';
    if (!window.MD) { node.textContent = text; }
  }

  function addAssistant(text, atts) {
    var row = el('div', 'row assistant');
    var imageId = null;
    if (atts && atts.length) {
      var media = el('div', 'assistant-media');
      for (var i = 0; i < atts.length; i++) {
        var a = atts[i];
        if (a.kind === 'image' && a.thumb) {
          var img = document.createElement('img');
          img.className = 'generated-image';
          img.src = a.thumb;
          img.alt = a.name || 'Generated image';
          bindImageTap(img, a.id);
          media.appendChild(img);
          imageId = a.id;
        }
      }
      if (media.childNodes.length) { row.appendChild(media); }
    }
    var body = el('div', 'body md');
    if (text) {
      renderInto(body, text);
      row.appendChild(body);
    }
    row._text = text || '';
    msgsEl.appendChild(row);
    if (text) {
      buildActions(row);
      applyCollapseIfNeeded(row, body);
    }
    if (imageId) {
      var actions = row.querySelector('.actions');
      if (!actions) { actions = el('div', 'actions'); row.appendChild(actions); }
      actions.appendChild(actionButton(S.share, function () { post({ type: 'shareImage', id: imageId }); }));
    }
  }


  // ---- "Thinking…" line: a light sweeps over the words while the star turns; tap it to read the thoughts as they come;
  // when the answer starts it folds away and settles into "Thought for 4 s" (tap again to read the thoughts).
  var SVG_NS = 'http://www.w3.org/2000/svg';
  var STAR = 'M12 1.6c.8 5.3 5.1 9.6 10.4 10.4-5.3.8-9.6 5.1-10.4 10.4C11.2 17.1 6.9 12.8 1.6 12 6.9 11.2 11.2 6.9 12 1.6Z';
  var CHEVRON = 'm9.5 6 6 6-6 6';
  var thinkSeq = 0;

  function reducedMotion() {
    try { return !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches); } catch (e) { return false; }
  }

  function svgIcon(cls, pathData, filled) {
    var svg = document.createElementNS(SVG_NS, 'svg');
    svg.setAttribute('viewBox', '0 0 24 24');
    svg.setAttribute('aria-hidden', 'true');
    if (cls) { svg.setAttribute('class', cls); }
    var path = document.createElementNS(SVG_NS, 'path');
    path.setAttribute('d', pathData);
    if (!filled) { path.setAttribute('class', 'stroke'); }
    svg.appendChild(path);
    return svg;
  }

  function cleanThought(s) {
    return String(s).replace(/\*\*/g, '').replace(/^#+\s*/, '').replace(/^[-*]\s+/, '').replace(/^\s+|\s+$/g, '');
  }

  function makeThinking(label) {
    var id = 'think' + (++thinkSeq);
    var root = el('div', 'think');
    var head = el('button', 'think-h');
    head.type = 'button';
    head.setAttribute('aria-expanded', 'false');
    head.setAttribute('aria-controls', id);
    var icon = el('span', 'think-ic');
    icon.setAttribute('aria-hidden', 'true');
    icon.appendChild(svgIcon('', STAR, true));
    var tx = el('span', 'think-tx');
    var a = el('span', 'think-a', label);
    var b = el('span', 'think-b');
    b.setAttribute('aria-hidden', 'true');
    tx.appendChild(a);
    tx.appendChild(b);
    var cv = svgIcon('think-cv', CHEVRON, false);
    head.appendChild(icon);
    head.appendChild(tx);
    head.appendChild(cv);
    var panel = el('div', 'think-pn');
    panel.id = id;
    var list = el('div', 'think-ls');
    panel.appendChild(list);
    root.appendChild(head);
    root.appendChild(panel);
    var live = el('p', 'think-live');
    live.setAttribute('role', 'status');
    root.appendChild(live);
    var th = { root: root, head: head, icon: icon, a: a, b: b, panel: panel, list: list, live: live,
               lines: [], text: '', open: false, done: false, start: Date.now() };
    head.addEventListener('click', function () { if (th.lines.length) { setThinkOpen(th, !th.open); } });
    head.addEventListener('keydown', function (e) {
      if ((e.key === 'Escape' || e.keyCode === 27) && th.open) { e.preventDefault(); setThinkOpen(th, false); }
    });
    return th;
  }

  function fitThinkPanel(th) {
    if (!th.open) { return; }
    th.panel.style.height = th.list.offsetHeight + 'px';
  }

  function setThinkOpen(th, open) {
    th.open = open;
    th.head.setAttribute('aria-expanded', open ? 'true' : 'false');
    th.root.className = th.root.className.replace(/\s*\bis-open\b/g, '') + (open ? ' is-open' : '');
    var panel = th.panel;
    if (open) {
      panel.style.height = th.list.offsetHeight + 'px';
    } else {
      panel.style.height = panel.offsetHeight + 'px';   // from "auto" to a number so it can shrink smoothly
      void panel.offsetHeight;
      panel.style.height = '0px';
    }
    if (current && current.row && current.row._thinking === th && stick) { setTimeout(function () { toBottom(false); }, 520); }
  }

  function addThinkLine(th, text) {
    var line = el('p', 'think-ln');
    var inner = el('span', '', text);
    line.appendChild(inner);
    th.list.appendChild(line);
    th.lines.push(inner);
    if (th.lines.length === 1) { th.root.className += ' has-lines'; }
    // appear on the next frame so the transition runs
    setTimeout(function () { line.className += ' is-on'; }, 20);
    return inner;
  }

  function feedThought(th, s) {
    if (!th || th.done || !s) { return; }
    th.text += s;
    var paragraphs = th.text.split(/\n{2,}/);
    var shown = 0;
    for (var i = 0; i < paragraphs.length; i++) {
      var clean = cleanThought(paragraphs[i]);
      if (!clean) { continue; }
      if (shown < th.lines.length) {
        if (th.lines[shown].textContent !== clean) { th.lines[shown].textContent = clean; }
      } else {
        addThinkLine(th, clean);
      }
      shown++;
    }
    fitThinkPanel(th);
  }

  // The star slows to a stop on a quarter turn (CSS has no way to ask where an animation is, so read the matrix).
  function settleStar(th) {
    var icon = th.icon;
    try {
      var m = window.getComputedStyle(icon).transform;
      var v = /matrix\(([^)]+)\)/.exec(m || '');
      if (!v) { icon.style.animation = 'none'; return; }
      var n = v[1].split(',');
      var ca = parseFloat(n[0]), sb = parseFloat(n[1]);
      var deg = Math.atan2(sb, ca) * 180 / Math.PI;
      var scale = Math.sqrt(ca * ca + sb * sb);
      icon.style.webkitAnimation = 'none';
      icon.style.animation = 'none';
      icon.style.webkitTransform = icon.style.transform = 'rotate(' + deg + 'deg) scale(' + scale + ')';
      void icon.offsetWidth;
      var target = Math.ceil((deg + 25) / 90) * 90;
      icon.style.webkitTransition = icon.style.transition = 'transform .75s cubic-bezier(.3,1.45,.5,1)';
      icon.style.webkitTransform = icon.style.transform = 'rotate(' + target + 'deg) scale(1)';
    } catch (e) { icon.style.animation = 'none'; }
  }

  // The answer starts (or the reply ends): fold the thoughts away and show how long it took.
  function finishThinking(row) {
    var th = row && row._thinking;
    if (!th || th.done) { return; }
    th.done = true;
    var secs = Math.max(1, Math.round((Date.now() - th.start) / 1000));
    if (!th.lines.length && Date.now() - th.start < 2000) {   // an instant answer: nothing to say about it
      if (th.root.parentNode) { th.root.parentNode.removeChild(th.root); }
      row._thinking = null;
      return;
    }
    var label = (S.thoughtFor || S.thoughtShort).replace('%d', secs);
    th.b.textContent = label;
    th.root.className += ' is-done';
    th.a.setAttribute('aria-hidden', 'true');
    th.b.removeAttribute('aria-hidden');
    th.live.textContent = label;
    if (th.open) { setThinkOpen(th, false); }
    if (!reducedMotion()) { settleStar(th); } else { th.icon.style.animation = 'none'; }
  }

  // Smooth typing: incoming text waits in c.pending and is released in small steps. The step grows with the backlog, so a
  // burst from the network still catches up quickly while short pieces appear one after another (no stop-and-jump).
  var PACE_INTERVAL = 22;

  // Re-rendering the whole reply costs more the longer it gets, so long replies are redrawn less often.
  function renderDelay(len) {
    return Math.min(1500, Math.max(RENDER_INTERVAL, Math.floor(len / 40)));
  }

  function renderStreaming(c) {
    if (current !== c) { return; }
    if (window.MD && typeof window.MD.setStreaming === 'function') { window.MD.setStreaming(true); }
    try {
      renderInto(c.content, c.text);
    } finally {
      if (window.MD && typeof window.MD.setStreaming === 'function') { window.MD.setStreaming(false); }
    }
    if (stick) { toBottom(false); }
    updateJump();
  }

  function scheduleRender(c) {
    if (!c.rendered) {
      c.rendered = true;
      renderStreaming(c);
    } else if (!c.timer) {
      c.timer = setTimeout(function () {
        c.timer = null;
        renderStreaming(c);
      }, renderDelay(c.text.length));
    }
  }

  function paceStep(c) {
    c.pacer = setTimeout(function () {
      c.pacer = null;
      if (current !== c || !c.pending) { return; }
      var backlog = c.pending.length;
      var n = Math.min(400, Math.max(2, Math.ceil(backlog / 8)));
      c.text += c.pending.slice(0, n);
      c.pending = c.pending.slice(n);
      scheduleRender(c);
      if (c.pending.length) { paceStep(c); }
    }, PACE_INTERVAL);
  }

  window.ChatUI = {
    setStrings: function (obj) {
      for (var k in obj) {
        if (Object.prototype.hasOwnProperty.call(obj, k)) { S[k] = obj[k]; }
      }
      if (window.MD) { window.MD.setCopyLabel(S.copyCode); }
    },

    clear: function () {
      current = null;
      window.scrollTo(0, 0);
      showEmpty();
      stick = true;
      window.scrollTo(0, 0);
      if (window.requestAnimationFrame) { window.requestAnimationFrame(function () { window.scrollTo(0, 0); }); }
    },

    load: function (list) {
      current = null;
      msgsEl.innerHTML = '';
      if (!list || !list.length) {
        showEmpty();
        return;
      }
      document.documentElement.classList.remove('is-empty');
      ensureScrollable();
      post({ type: 'empty', value: false });
      for (var i = 0; i < list.length; i++) {
        if (list[i].role === 'user') {
          addUser(list[i].text, list[i].attachments, list[i].index !== undefined ? list[i].index : i);
        } else {
          addAssistant(list[i].text, list[i].attachments);
        }
      }
      refreshRegenerate();
      setTimeout(function () {
        refreshAllCollapsibles();
        ensureScrollable();
        stick = true;
        toBottom(true);
        updateJump();
      }, 20);
    },

    addUser: function (text, atts, messageIndex) {
      removeEmpty();
      clearErrors();
      addUser(text, atts, messageIndex);
      stick = true;
      toBottom(true);
    },

    begin: function () {
      removeEmpty();
      clearErrors();
      var row = el('div', 'row assistant');
      row._streaming = true;
      var th = makeThinking(S.thinking);
      var body = el('div', 'body md');
      var content = el('div', 'mdc');
      var dot = el('span', 'dot');
      body.appendChild(content);
      body.appendChild(dot);
      row.appendChild(th.root);
      row.appendChild(body);
      row._thinking = th;
      msgsEl.appendChild(row);
      current = { row: row, body: body, content: content, dot: dot, status: null, text: '', pending: '', pacer: null, timer: null, rendered: false };
      refreshRegenerate();
      updateJump();
    },

    // A piece of the model's reasoning summary (while it is still thinking).
    thought: function (s) {
      if (!current || !current.row || !current.row._thinking) { return; }
      feedThought(current.row._thinking, s);
      if (stick) { toBottom(false); }
    },

    delta: function (s) {
      if (!current || !s) { return; }
      var c = current;
      finishThinking(c.row);   // the answer started: fold the thoughts away
      c.pending += s;
      if (!c.pacer) { paceStep(c); }
    },

    end: function (finalText) {
      if (!current) { return; }
      var c = current;
      current = null;
      if (c.timer) { clearTimeout(c.timer); c.timer = null; }
      if (c.pacer) { clearTimeout(c.pacer); c.pacer = null; }
      if (c.pending) { c.text += c.pending; c.pending = ''; }
      if (c.dot.parentNode) { c.dot.parentNode.removeChild(c.dot); }
      c.row._streaming = false;
      var text = (finalText !== undefined && finalText !== null && finalText !== '') ? finalText : c.text;
      if (!text) {
        c.row.parentNode.removeChild(c.row);
      } else {
        finishThinking(c.row);
        renderInto(c.content, text);
        c.row._text = text;
        buildActions(c.row);
        applyCollapseIfNeeded(c.row, c.body);
      }
      refreshRegenerate();
      ensureScrollable();
      updateJump();
    },

    error: function (msg, canRetry) {
      clearErrors();
      var row = el('div', 'row error');
      row.appendChild(el('div', 'errtext', msg));
      if (canRetry) {
        var b = actionButton(S.retry, function () { post({ type: 'regenerate' }); });
        b.className = 'act retry';
        row.appendChild(b);
      }
      msgsEl.appendChild(row);
      refreshRegenerate();
      stick = true;
      toBottom(true);
    },

    // The history drawer slides the whole chat sideways: the greeting card fades back a little while it moves.
    setDrawer: function (open) {
      document.documentElement.classList.toggle('drawer-open', !!open);
    },

    scrollTop: function () {
      window.scrollTo(0, 0);
    },

    scrollEnd: function () {
      ensureScrollable();
      if (document.getElementById('empty')) { window.scrollTo(0, 0); return; }
      if (current) { updateJump(); return; }
      stick = true;
      toBottom(true);
    }
  };

  msgsEl.addEventListener('click', function (e) {
    var node = e.target;
    while (node && node !== msgsEl) {
      if (node.classList && node.classList.contains('copycode')) {
        var block = node.parentNode ? node.parentNode.parentNode : null;
        var code = block ? block.querySelector('pre code') : null;
        if (code) { post({ type: 'copy', text: code.textContent }); toast(S.copied); }
        return;
      }
      node = node.parentNode;
    }
  }, false);

  window.addEventListener('load', function () {
    ensureScrollable();
    post({ type: 'ready' });
  }, false);
})();
