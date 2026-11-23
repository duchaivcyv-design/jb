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
    thinking: 'Thinking…'
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
          if (a.kind === 'file') { chip.style.cursor = 'pointer'; chip.addEventListener('click', (function (id) { return function () { post({ type: 'file', id: id }); }; })(a.id), false); }
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

  // Smooth typing: incoming text waits in c.pending and is released in small steps. The step grows with the backlog,
// so a long burst still catches up quickly while short pieces appear one after another.
var PACE_INTERVAL = 22;
var STALL_AFTER_MS = 4000;

function scheduleRender(c) {
  if (c.status && c.status.parentNode) { c.status.parentNode.removeChild(c.status); c.status = null; }
  if (!c.rendered) {
    c.rendered = true;
    renderInto(c.content, c.text);
    if (stick) { toBottom(false); }
    updateJump();
  } else if (!c.timer) {
    c.timer = setTimeout(function () {
      c.timer = null;
      if (current === c) {
        renderInto(c.content, c.text);
        if (stick) { toBottom(false); }
        updateJump();
      }
    }, RENDER_INTERVAL);
  }
}

function paceStep(c) {
  c.pacer = setTimeout(function step() {
    c.pacer = null;
    if (current !== c) { return; }
    if (!c.pending) { return; }
    var backlog = c.pending.length;
    var n = Math.min(400, Math.max(2, Math.ceil(backlog / 8)));
    c.text += c.pending.slice(0, n);
    c.pending = c.pending.slice(n);
    scheduleRender(c);
    if (c.pending.length) { paceStep(c); }
  }, PACE_INTERVAL);
}

function startStallWatch(c) {
  c.lastDelta = Date.now();
  c.stallTimer = setInterval(function () {
    if (current !== c) { return; }
    var idle = Math.floor((Date.now() - c.lastDelta) / 1000);
    if (idle * 1000 < STALL_AFTER_MS) {
      if (c.waitEl && c.waitEl.parentNode) { c.waitEl.parentNode.removeChild(c.waitEl); }
      c.waitEl = null;
      return;
    }
    if (!c.waitEl) {
      c.waitEl = el('div', 'thinking-label', '');
      c.row.appendChild(c.waitEl);
    }
    c.waitEl.textContent = ((S && S.waiting) || 'Đang chờ phản hồi…') + ' ' + idle + 's';
  }, 1000);
}

function stopStallWatch(c) {
  if (c.stallTimer) { clearInterval(c.stallTimer); c.stallTimer = null; }
  if (c.waitEl && c.waitEl.parentNode) { c.waitEl.parentNode.removeChild(c.waitEl); }
  c.waitEl = null;
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

    setStatus: function (text) {
      if (current && current.status) current.status.textContent = text;
    },

    begin: function () {
      removeEmpty();
      clearErrors();
      var row = el('div', 'row assistant');
      row._streaming = true;
      var status = el('div', 'thinking-label', S.thinking);
      var body = el('div', 'body md');
      var content = el('div', 'mdc');
      var dot = el('span', 'dot');
      body.appendChild(content);
      body.appendChild(dot);
      row.appendChild(status);
      row.appendChild(body);
      msgsEl.appendChild(row);
      current = {
        row: row,
        body: body,
        content: content,
        dot: dot,
        status: status,
        text: '',
        timer: null,
        rendered: false,
        pending: '',
        pacer: null,
        stallTimer: null,
        waitEl: null,
        lastDelta: Date.now()
      };
      startStallWatch(current);
      refreshRegenerate();
      updateJump();
    },

    delta: function (s) {
      if (!current || !s) { return; }
      var c = current;
      c.lastDelta = Date.now();
      if (c.status && c.status.parentNode) { c.status.parentNode.removeChild(c.status); c.status = null; }
      if (c.waitEl && c.waitEl.parentNode) { c.waitEl.parentNode.removeChild(c.waitEl); c.waitEl = null; }
      c.pending += s;
      if (!c.pacer) { paceStep(c); }
    },

    end: function (finalText) {
      if (!current) { return; }
      var c = current;
      current = null;
      if (c.pacer) { clearTimeout(c.pacer); c.pacer = null; }
      if (c.pending) { c.text += c.pending; c.pending = ''; }
      if (c.timer) { clearTimeout(c.timer); c.timer = null; }
      stopStallWatch(c);
      if (c.dot.parentNode) { c.dot.parentNode.removeChild(c.dot); }
      if (c.status && c.status.parentNode) { c.status.parentNode.removeChild(c.status); }
      c.row._streaming = false;
      var text = (finalText !== undefined && finalText !== null && finalText !== '') ? finalText : c.text;
      if (!text) {
        c.row.parentNode.removeChild(c.row);
      } else {
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
