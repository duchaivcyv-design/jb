(function () {
  'use strict';

  // Turns a model reply (Markdown with optional LaTeX) into safe HTML.
  // Uses markdown-it, highlight.js and KaTeX from vendor.js. Plain ES5: iOS 12's WebKit is Safari 12.

  var copyLabel = 'Copy';
  var CACHE_LIMIT = 4000;
  var MAX_HIGHLIGHT_CHARS = 60000;
  var MAX_MATH_CHARS = 4000;

  // While a reply streams in, the whole text is re-rendered many times. Code blocks that are still growing are shown
  // un-highlighted and are not cached (every intermediate version would otherwise be kept: memory grows with the
  // square of the reply and iOS kills the page). The final render (when the reply ends) highlights everything.
  var STREAM_PLAIN_CHARS = 2500;
  var CACHE_CHAR_LIMIT = 3000000;
  var streamingMode = false;
  var hlChars = 0;

  var hlCache = Object.create(null), hlCount = 0;
  var mathCache = Object.create(null), mathCount = 0;

  function escapeHtml(s) {
    return String(s === undefined || s === null ? '' : s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function evictHalf(map) {
    var keys = Object.keys(map);
    var half = Math.floor(keys.length / 2);
    for (var i = 0; i < half; i++) {
      delete map[keys[i]];
    }
    return keys.length - half;
  }

  function measureCache(map) {
    var total = 0, keys = Object.keys(map);
    for (var i = 0; i < keys.length; i++) { total += keys[i].length + String(map[keys[i]]).length; }
    return total;
  }

  function putCache(isHl, key, val) {
    if (isHl) {
      if (hlCount >= CACHE_LIMIT || hlChars > CACHE_CHAR_LIMIT) {
        hlCount = evictHalf(hlCache);
        hlChars = measureCache(hlCache);
      }
      if (hlCache[key] === undefined) { hlCount++; }
      hlChars += key.length + String(val).length;
      hlCache[key] = val;
    } else {
      if (mathCount >= CACHE_LIMIT) { mathCount = evictHalf(mathCache); }
      if (mathCache[key] === undefined) { mathCount++; }
      mathCache[key] = val;
    }
  }

  // ---------------------------------------------------------------------------------------------
  // Highlighting and math, both cached: a reply is re-rendered many times while it streams in.
  // ---------------------------------------------------------------------------------------------

  function highlight(code, lang) {
    var raw = String(code === undefined || code === null ? '' : code);
    if (raw.length > MAX_HIGHLIGHT_CHARS) {
      return escapeHtml(raw);
    }
    if (streamingMode && raw.length > STREAM_PLAIN_CHARS) {
      return escapeHtml(raw);
    }
    var key = 'k' + (lang || '') + '\u0000' + raw;
    if (hlCache[key] !== undefined) { return hlCache[key]; }

    var html;
    try {
      if (lang && window.hljs && typeof window.hljs.getLanguage === 'function' && window.hljs.getLanguage(lang)) {
        html = window.hljs.highlight(raw, { language: lang, ignoreIllegals: true }).value;
      } else {
        html = escapeHtml(raw);
      }
    } catch (e) {
      html = escapeHtml(raw);
    }
    putCache(true, key, html);
    return html;
  }

  function renderMath(tex, display) {
    var raw = String(tex === undefined || tex === null ? '' : tex);
    if (!raw || raw.length > MAX_MATH_CHARS) {
      return '<code>' + escapeHtml(raw) + '</code>';
    }
    var key = (display ? 'D' : 'I') + raw;
    if (mathCache[key] !== undefined) { return mathCache[key]; }

    var html;
    try {
      if (!window.katex || typeof window.katex.renderToString !== 'function') {
        throw new Error('KaTeX unavailable');
      }
      html = window.katex.renderToString(raw, {
        displayMode: !!display,
        throwOnError: false,
        strict: 'ignore',
        output: 'html',
        trust: false,
        maxExpand: 1000,
        maxSize: 50,
        errorColor: '#B3402A'
      });
    } catch (e) {
      html = '<code>' + escapeHtml(raw) + '</code>';
    }
    putCache(false, key, html);
    return html;
  }

  // ---------------------------------------------------------------------------------------------
  // Math must be lifted out BEFORE markdown runs (markdown would eat underscores, asterisks, backslashes).
  // Code is skipped. Placeholders use private-use characters that cannot appear in normal text.
  // ---------------------------------------------------------------------------------------------

  function hold(items, tex, display) {
    items.push({ tex: tex, display: !!display });
    return '\uE000' + (items.length - 1) + '\uE001';
  }

  function splitFences(src) {
    var lines = src.split('\n'), segs = [], cur = [], inFence = false, fch = '', flen = 0;
    function flush(isCode) {
      if (cur.length) {
        segs.push({ code: isCode, text: cur.join('\n') });
        cur = [];
      }
    }
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      var m = /^ {0,3}(`{3,}|~{3,})/.exec(line);
      if (!inFence) {
        if (m) {
          flush(false);
          inFence = true;
          fch = m[1].charAt(0);
          flen = m[1].length;
        }
        cur.push(line);
      } else {
        cur.push(line);
        if (m && m[1].charAt(0) === fch && m[1].length >= flen && /^ {0,3}[`~]+\s*$/.test(line)) {
          flush(true);
          inFence = false;
        }
      }
    }
    flush(inFence);
    return segs;
  }

  function protectMath(s, items) {
    var chunks = [], i = 0, n = s.length;
    while (i < n) {
      var c = s.charAt(i);

      if (c === '\\') {
        var nx = s.charAt(i + 1);
        if (nx === '$' || nx === '\\') {
          chunks.push(c + nx);
          i += 2;
          continue;
        }
        if (nx === '[' || nx === '(') {
          var close = nx === '[' ? '\\]' : '\\)';
          var end = s.indexOf(close, i + 2);
          if (end > i + 2 && end - (i + 2) <= MAX_MATH_CHARS) {
            chunks.push(hold(items, s.substring(i + 2, end), nx === '['));
            i = end + 2;
            continue;
          }
        }
        chunks.push(c);
        i++;
        continue;
      }

      if (c === '`') {
        var run = 1;
        while (i + run < n && s.charAt(i + run) === '`') { run++; }
        var ticks = s.substr(i, run);
        var endTick = s.indexOf(ticks, i + run);
        if (endTick >= i + run) {
          chunks.push(s.substring(i, endTick + run));
          i = endTick + run;
          continue;
        }
        chunks.push(ticks);
        i += run;
        continue;
      }

      if (c === '$') {
        if (s.charAt(i + 1) === '$') {
          var e2 = s.indexOf('$$', i + 2);
          if (e2 > i + 2 && e2 - (i + 2) <= MAX_MATH_CHARS) {
            chunks.push(hold(items, s.substring(i + 2, e2), true));
            i = e2 + 2;
            continue;
          }
          chunks.push('$$');
          i += 2;
          continue;
        }
        var after = s.charAt(i + 1);
        if (after && !/\s/.test(after)) {
          var j = i + 1, found = -1;
          while (j < n && j - (i + 1) <= MAX_MATH_CHARS) {
            var d = s.charAt(j);
            if (d === '\n' && s.charAt(j + 1) === '\n') { break; }
            if (d === '\\') { j += 2; continue; }
            if (d === '$') {
              if (!/\s/.test(s.charAt(j - 1)) && !/[0-9]/.test(s.charAt(j + 1))) {
                found = j;
              }
              break;
            }
            j++;
          }
          if (found > i + 1) {
            chunks.push(hold(items, s.substring(i + 1, found), false));
            i = found + 1;
            continue;
          }
        }
        chunks.push('$');
        i++;
        continue;
      }

      chunks.push(c);
      i++;
    }
    return chunks.join('');
  }

  // ---------------------------------------------------------------------------------------------
  // markdown-it
  // ---------------------------------------------------------------------------------------------

  function isSafeImageSrc(src) {
    if (!src) return false;
    var trimmed = String(src).replace(/^\s+|\s+$/g, '');
    return /^https?:\/\/[^\s"'<>]+$/i.test(trimmed) ||
           /^data:image\/(png|jpe?g|gif|webp);base64,[a-zA-Z0-9+\/=]+$/i.test(trimmed);
  }

  function codeBlock(code, lang) {
    var cleanLang = String(lang || '').toLowerCase().replace(/[^a-z0-9_+#.-]/g, '');
    var label = cleanLang || 'code';
    var trimmedCode = String(code || '').replace(/\n$/, '');
    return '<div class="codeblock"><div class="codehead"><span class="lang">' + escapeHtml(label) +
           '</span><button type="button" class="act copycode">' + escapeHtml(copyLabel) + '</button></div>' +
           '<pre><code class="hljs">' + highlight(trimmedCode, cleanLang) + '</code></pre></div>\n';
  }

  var md = null;
  try {
    if (typeof window.markdownit === 'function') {
      md = window.markdownit({ html: false, linkify: true, breaks: true, typographer: false });
      md.linkify.set({ fuzzyLink: false, fuzzyEmail: false, fuzzyIP: false });
      md.renderer.rules.fence = function (tokens, idx) {
        var tok = tokens[idx];
        var info = (tok.info || '').trim().split(/\s+/)[0];
        return codeBlock(tok.content, info);
      };
      md.renderer.rules.code_block = function (tokens, idx) {
        return codeBlock(tokens[idx].content, '');
      };
      md.renderer.rules.table_open = function () { return '<div class="tablewrap"><table>\n'; };
      md.renderer.rules.table_close = function () { return '</table></div>\n'; };
      md.renderer.rules.image = function (tokens, idx) {
        var tok = tokens[idx];
        var src = tok.attrGet('src') || '';
        var alt = tok.content || (tok.children && tok.children.length
          ? tok.children.map(function (c) { return c.content || ''; }).join('')
          : 'Image');
        if (!isSafeImageSrc(src)) {
          return '<span>' + escapeHtml(alt) + '</span>';
        }
        return '<img class="generated-image" src="' + escapeHtml(src) + '" alt="' + escapeHtml(alt) + '" loading="lazy" />';
      };
    }
  } catch (e) {
    md = null;
  }

  function render(text) {
    var src = String(text === undefined || text === null ? '' : text).replace(/[\uE000\uE001]/g, '');
    if (!md) {
      return '<div style="white-space:pre-wrap">' + escapeHtml(src) + '</div>';
    }

    var items = [];
    var segs = splitFences(src);
    var parts = new Array(segs.length);
    for (var i = 0; i < segs.length; i++) {
      parts[i] = segs[i].code ? segs[i].text : protectMath(segs[i].text, items);
    }
    var html = md.render(parts.join('\n'));
    if (items.length) {
      html = html.replace(/\uE000(\d+)\uE001/g, function (m, idx) {
        var item = items[parseInt(idx, 10)];
        return item ? renderMath(item.tex, item.display) : '';
      });
    }
    return html;
  }

  window.MD = {
    render: render,
    setCopyLabel: function (label) {
      if (label !== undefined && label !== null && String(label).length > 0) {
        copyLabel = String(label);
      }
    },
    setStreaming: function (on) { streamingMode = !!on; },
    ready: !!md
  };
})();
