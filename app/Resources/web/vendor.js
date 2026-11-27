/*! markdown-it 14.2.0 https://github.com/markdown-it/markdown-it @license MIT */
!(function(t, e) {
  "object" == typeof exports && "undefined" != typeof module ? module.exports = e() : "function" == typeof define && define.amd ? define(e) : (t = "undefined" != typeof globalThis ? globalThis : t || self).markdownit = e();
})(this, function() {
  "use strict";
  const t = {};
  function e(r2, n2) {
    "string" != typeof n2 && (n2 = e.defaultChars);
    const s2 = (function(e2) {
      let r3 = t[e2];
      if (r3) return r3;
      r3 = t[e2] = [];
      for (let t2 = 0; t2 < 128; t2++) {
        const e3 = String.fromCharCode(t2);
        r3.push(e3);
      }
      for (let t2 = 0; t2 < e2.length; t2++) {
        const n3 = e2.charCodeAt(t2);
        r3[n3] = "%" + ("0" + n3.toString(16).toUpperCase()).slice(-2);
      }
      return r3;
    })(n2);
    return r2.replace(/(%[a-f0-9]{2})+/gi, function(t2) {
      let e2 = "";
      for (let r3 = 0, n3 = t2.length; r3 < n3; r3 += 3) {
        const i2 = parseInt(t2.slice(r3 + 1, r3 + 3), 16);
        if (i2 < 128) e2 += s2[i2];
        else {
          if (192 == (224 & i2) && r3 + 3 < n3) {
            const n4 = parseInt(t2.slice(r3 + 4, r3 + 6), 16);
            if (128 == (192 & n4)) {
              const t3 = i2 << 6 & 1984 | 63 & n4;
              e2 += t3 < 128 ? "\uFFFD\uFFFD" : String.fromCharCode(t3), r3 += 3;
              continue;
            }
          }
          if (224 == (240 & i2) && r3 + 6 < n3) {
            const n4 = parseInt(t2.slice(r3 + 4, r3 + 6), 16), s3 = parseInt(t2.slice(r3 + 7, r3 + 9), 16);
            if (128 == (192 & n4) && 128 == (192 & s3)) {
              const t3 = i2 << 12 & 61440 | n4 << 6 & 4032 | 63 & s3;
              e2 += t3 < 2048 || t3 >= 55296 && t3 <= 57343 ? "\uFFFD\uFFFD\uFFFD" : String.fromCharCode(t3), r3 += 6;
              continue;
            }
          }
          if (240 == (248 & i2) && r3 + 9 < n3) {
            const n4 = parseInt(t2.slice(r3 + 4, r3 + 6), 16), s3 = parseInt(t2.slice(r3 + 7, r3 + 9), 16), o2 = parseInt(t2.slice(r3 + 10, r3 + 12), 16);
            if (128 == (192 & n4) && 128 == (192 & s3) && 128 == (192 & o2)) {
              let t3 = i2 << 18 & 1835008 | n4 << 12 & 258048 | s3 << 6 & 4032 | 63 & o2;
              t3 < 65536 || t3 > 1114111 ? e2 += "\uFFFD\uFFFD\uFFFD\uFFFD" : (t3 -= 65536, e2 += String.fromCharCode(55296 + (t3 >> 10), 56320 + (1023 & t3))), r3 += 9;
              continue;
            }
          }
          e2 += "\uFFFD";
        }
      }
      return e2;
    });
  }
  e.defaultChars = ";/?:@&=+$,#", e.componentChars = "";
  const r = {};
  function n(t2, e2, s2) {
    "string" != typeof e2 && (s2 = e2, e2 = n.defaultChars), void 0 === s2 && (s2 = true);
    const i2 = (function(t3) {
      let e3 = r[t3];
      if (e3) return e3;
      e3 = r[t3] = [];
      for (let t4 = 0; t4 < 128; t4++) {
        const r2 = String.fromCharCode(t4);
        /^[0-9a-z]$/i.test(r2) ? e3.push(r2) : e3.push("%" + ("0" + t4.toString(16).toUpperCase()).slice(-2));
      }
      for (let r2 = 0; r2 < t3.length; r2++) e3[t3.charCodeAt(r2)] = t3[r2];
      return e3;
    })(e2);
    let o2 = "";
    for (let e3 = 0, r2 = t2.length; e3 < r2; e3++) {
      const n2 = t2.charCodeAt(e3);
      if (s2 && 37 === n2 && e3 + 2 < r2 && /^[0-9a-f]{2}$/i.test(t2.slice(e3 + 1, e3 + 3))) o2 += t2.slice(e3, e3 + 3), e3 += 2;
      else if (n2 < 128) o2 += i2[n2];
      else if (n2 >= 55296 && n2 <= 57343) {
        if (n2 >= 55296 && n2 <= 56319 && e3 + 1 < r2) {
          const r3 = t2.charCodeAt(e3 + 1);
          if (r3 >= 56320 && r3 <= 57343) {
            o2 += encodeURIComponent(t2[e3] + t2[e3 + 1]), e3++;
            continue;
          }
        }
        o2 += "%EF%BF%BD";
      } else o2 += encodeURIComponent(t2[e3]);
    }
    return o2;
  }
  function s(t2) {
    let e2 = "";
    return e2 += t2.protocol || "", e2 += t2.slashes ? "//" : "", e2 += t2.auth ? t2.auth + "@" : "", t2.hostname && -1 !== t2.hostname.indexOf(":") ? e2 += "[" + t2.hostname + "]" : e2 += t2.hostname || "", e2 += t2.port ? ":" + t2.port : "", e2 += t2.pathname || "", e2 += t2.search || "", e2 += t2.hash || "", e2;
  }
  function i() {
    this.protocol = null, this.slashes = null, this.auth = null, this.port = null, this.hostname = null, this.hash = null, this.search = null, this.pathname = null;
  }
  n.defaultChars = ";/?:@&=+$,-_.!~*'()#", n.componentChars = "-_.!~*'()";
  const o = /^([a-z0-9.+-]+:)/i, u = /:[0-9]*$/, c = /^(\/\/?(?!\/)[^\?\s]*)(\?[^\s]*)?$/, a = ["{", "}", "|", "\\", "^", "`"].concat(["<", ">", '"', "`", " ", "\r", "\n", "	"]), l = ["'"].concat(a), h = ["%", "/", "?", ";", "#"].concat(l), p = ["/", "?", "#"], f = /^[+a-z0-9A-Z_-]{0,63}$/, d = /^([+a-z0-9A-Z_-]{0,63})(.*)$/, _ = { javascript: true, "javascript:": true }, m = { http: true, https: true, ftp: true, gopher: true, file: true, "http:": true, "https:": true, "ftp:": true, "gopher:": true, "file:": true };
  function g(t2, e2) {
    if (t2 && t2 instanceof i) return t2;
    const r2 = new i();
    return r2.parse(t2, e2), r2;
  }
  i.prototype.parse = function(t2, e2) {
    let r2, n2, s2, i2 = t2;
    if (i2 = i2.trim(), !e2 && 1 === t2.split("#").length) {
      const t3 = c.exec(i2);
      if (t3) return this.pathname = t3[1], t3[2] && (this.search = t3[2]), this;
    }
    let u2 = o.exec(i2);
    if (u2 && (u2 = u2[0], r2 = u2.toLowerCase(), this.protocol = u2, i2 = i2.substr(u2.length)), (e2 || u2 || i2.match(/^\/\/[^@\/]+@[^@\/]+/)) && (s2 = "//" === i2.substr(0, 2), !s2 || u2 && _[u2] || (i2 = i2.substr(2), this.slashes = true)), !_[u2] && (s2 || u2 && !m[u2])) {
      let t3, e3, r3 = -1;
      for (let t4 = 0; t4 < p.length; t4++) n2 = i2.indexOf(p[t4]), -1 !== n2 && (-1 === r3 || n2 < r3) && (r3 = n2);
      e3 = -1 === r3 ? i2.lastIndexOf("@") : i2.lastIndexOf("@", r3), -1 !== e3 && (t3 = i2.slice(0, e3), i2 = i2.slice(e3 + 1), this.auth = t3), r3 = -1;
      for (let t4 = 0; t4 < h.length; t4++) n2 = i2.indexOf(h[t4]), -1 !== n2 && (-1 === r3 || n2 < r3) && (r3 = n2);
      -1 === r3 && (r3 = i2.length), ":" === i2[r3 - 1] && r3--;
      const s3 = i2.slice(0, r3);
      i2 = i2.slice(r3), this.parseHost(s3), this.hostname = this.hostname || "";
      const o2 = "[" === this.hostname[0] && "]" === this.hostname[this.hostname.length - 1];
      if (!o2) {
        const t4 = this.hostname.split(/\./);
        for (let e4 = 0, r4 = t4.length; e4 < r4; e4++) {
          const r5 = t4[e4];
          if (r5 && !r5.match(f)) {
            let n3 = "";
            for (let t5 = 0, e5 = r5.length; t5 < e5; t5++) r5.charCodeAt(t5) > 127 ? n3 += "x" : n3 += r5[t5];
            if (!n3.match(f)) {
              const n4 = t4.slice(0, e4), s4 = t4.slice(e4 + 1), o3 = r5.match(d);
              o3 && (n4.push(o3[1]), s4.unshift(o3[2])), s4.length && (i2 = s4.join(".") + i2), this.hostname = n4.join(".");
              break;
            }
          }
        }
      }
      this.hostname.length > 255 && (this.hostname = ""), o2 && (this.hostname = this.hostname.substr(1, this.hostname.length - 2));
    }
    const a2 = i2.indexOf("#");
    -1 !== a2 && (this.hash = i2.substr(a2), i2 = i2.slice(0, a2));
    const l2 = i2.indexOf("?");
    return -1 !== l2 && (this.search = i2.substr(l2), i2 = i2.slice(0, l2)), i2 && (this.pathname = i2), m[r2] && this.hostname && !this.pathname && (this.pathname = ""), this;
  }, i.prototype.parseHost = function(t2) {
    let e2 = u.exec(t2);
    e2 && (e2 = e2[0], ":" !== e2 && (this.port = e2.substr(1)), t2 = t2.substr(0, t2.length - e2.length)), t2 && (this.hostname = t2);
  };
  var k, D = Object.freeze({ __proto__: null, decode: e, encode: n, format: s, parse: g }), C = /[\0-\uD7FF\uE000-\uFFFF]|[\uD800-\uDBFF][\uDC00-\uDFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF]/, y = /[\0-\x1F\x7F-\x9F]/, E = /[!-#%-\*,-\/:;\?@\[-\]_\{\}\xA1\xA7\xAB\xB6\xB7\xBB\xBF\u037E\u0387\u055A-\u055F\u0589\u058A\u05BE\u05C0\u05C3\u05C6\u05F3\u05F4\u0609\u060A\u060C\u060D\u061B\u061D-\u061F\u066A-\u066D\u06D4\u0700-\u070D\u07F7-\u07F9\u0830-\u083E\u085E\u0964\u0965\u0970\u09FD\u0A76\u0AF0\u0C77\u0C84\u0DF4\u0E4F\u0E5A\u0E5B\u0F04-\u0F12\u0F14\u0F3A-\u0F3D\u0F85\u0FD0-\u0FD4\u0FD9\u0FDA\u104A-\u104F\u10FB\u1360-\u1368\u1400\u166E\u169B\u169C\u16EB-\u16ED\u1735\u1736\u17D4-\u17D6\u17D8-\u17DA\u1800-\u180A\u1944\u1945\u1A1E\u1A1F\u1AA0-\u1AA6\u1AA8-\u1AAD\u1B5A-\u1B60\u1B7D\u1B7E\u1BFC-\u1BFF\u1C3B-\u1C3F\u1C7E\u1C7F\u1CC0-\u1CC7\u1CD3\u2010-\u2027\u2030-\u2043\u2045-\u2051\u2053-\u205E\u207D\u207E\u208D\u208E\u2308-\u230B\u2329\u232A\u2768-\u2775\u27C5\u27C6\u27E6-\u27EF\u2983-\u2998\u29D8-\u29DB\u29FC\u29FD\u2CF9-\u2CFC\u2CFE\u2CFF\u2D70\u2E00-\u2E2E\u2E30-\u2E4F\u2E52-\u2E5D\u3001-\u3003\u3008-\u3011\u3014-\u301F\u3030\u303D\u30A0\u30FB\uA4FE\uA4FF\uA60D-\uA60F\uA673\uA67E\uA6F2-\uA6F7\uA874-\uA877\uA8CE\uA8CF\uA8F8-\uA8FA\uA8FC\uA92E\uA92F\uA95F\uA9C1-\uA9CD\uA9DE\uA9DF\uAA5C-\uAA5F\uAADE\uAADF\uAAF0\uAAF1\uABEB\uFD3E\uFD3F\uFE10-\uFE19\uFE30-\uFE52\uFE54-\uFE61\uFE63\uFE68\uFE6A\uFE6B\uFF01-\uFF03\uFF05-\uFF0A\uFF0C-\uFF0F\uFF1A\uFF1B\uFF1F\uFF20\uFF3B-\uFF3D\uFF3F\uFF5B\uFF5D\uFF5F-\uFF65]|\uD800[\uDD00-\uDD02\uDF9F\uDFD0]|\uD801\uDD6F|\uD802[\uDC57\uDD1F\uDD3F\uDE50-\uDE58\uDE7F\uDEF0-\uDEF6\uDF39-\uDF3F\uDF99-\uDF9C]|\uD803[\uDEAD\uDF55-\uDF59\uDF86-\uDF89]|\uD804[\uDC47-\uDC4D\uDCBB\uDCBC\uDCBE-\uDCC1\uDD40-\uDD43\uDD74\uDD75\uDDC5-\uDDC8\uDDCD\uDDDB\uDDDD-\uDDDF\uDE38-\uDE3D\uDEA9]|\uD805[\uDC4B-\uDC4F\uDC5A\uDC5B\uDC5D\uDCC6\uDDC1-\uDDD7\uDE41-\uDE43\uDE60-\uDE6C\uDEB9\uDF3C-\uDF3E]|\uD806[\uDC3B\uDD44-\uDD46\uDDE2\uDE3F-\uDE46\uDE9A-\uDE9C\uDE9E-\uDEA2\uDF00-\uDF09]|\uD807[\uDC41-\uDC45\uDC70\uDC71\uDEF7\uDEF8\uDF43-\uDF4F\uDFFF]|\uD809[\uDC70-\uDC74]|\uD80B[\uDFF1\uDFF2]|\uD81A[\uDE6E\uDE6F\uDEF5\uDF37-\uDF3B\uDF44]|\uD81B[\uDE97-\uDE9A\uDFE2]|\uD82F\uDC9F|\uD836[\uDE87-\uDE8B]|\uD83A[\uDD5E\uDD5F]/, A = /[\$\+<->\^`\|~\xA2-\xA6\xA8\xA9\xAC\xAE-\xB1\xB4\xB8\xD7\xF7\u02C2-\u02C5\u02D2-\u02DF\u02E5-\u02EB\u02ED\u02EF-\u02FF\u0375\u0384\u0385\u03F6\u0482\u058D-\u058F\u0606-\u0608\u060B\u060E\u060F\u06DE\u06E9\u06FD\u06FE\u07F6\u07FE\u07FF\u0888\u09F2\u09F3\u09FA\u09FB\u0AF1\u0B70\u0BF3-\u0BFA\u0C7F\u0D4F\u0D79\u0E3F\u0F01-\u0F03\u0F13\u0F15-\u0F17\u0F1A-\u0F1F\u0F34\u0F36\u0F38\u0FBE-\u0FC5\u0FC7-\u0FCC\u0FCE\u0FCF\u0FD5-\u0FD8\u109E\u109F\u1390-\u1399\u166D\u17DB\u1940\u19DE-\u19FF\u1B61-\u1B6A\u1B74-\u1B7C\u1FBD\u1FBF-\u1FC1\u1FCD-\u1FCF\u1FDD-\u1FDF\u1FED-\u1FEF\u1FFD\u1FFE\u2044\u2052\u207A-\u207C\u208A-\u208C\u20A0-\u20C0\u2100\u2101\u2103-\u2106\u2108\u2109\u2114\u2116-\u2118\u211E-\u2123\u2125\u2127\u2129\u212E\u213A\u213B\u2140-\u2144\u214A-\u214D\u214F\u218A\u218B\u2190-\u2307\u230C-\u2328\u232B-\u2426\u2440-\u244A\u249C-\u24E9\u2500-\u2767\u2794-\u27C4\u27C7-\u27E5\u27F0-\u2982\u2999-\u29D7\u29DC-\u29FB\u29FE-\u2B73\u2B76-\u2B95\u2B97-\u2BFF\u2CE5-\u2CEA\u2E50\u2E51\u2E80-\u2E99\u2E9B-\u2EF3\u2F00-\u2FD5\u2FF0-\u2FFF\u3004\u3012\u3013\u3020\u3036\u3037\u303E\u303F\u309B\u309C\u3190\u3191\u3196-\u319F\u31C0-\u31E3\u31EF\u3200-\u321E\u322A-\u3247\u3250\u3260-\u327F\u328A-\u32B0\u32C0-\u33FF\u4DC0-\u4DFF\uA490-\uA4C6\uA700-\uA716\uA720\uA721\uA789\uA78A\uA828-\uA82B\uA836-\uA839\uAA77-\uAA79\uAB5B\uAB6A\uAB6B\uFB29\uFBB2-\uFBC2\uFD40-\uFD4F\uFDCF\uFDFC-\uFDFF\uFE62\uFE64-\uFE66\uFE69\uFF04\uFF0B\uFF1C-\uFF1E\uFF3E\uFF40\uFF5C\uFF5E\uFFE0-\uFFE6\uFFE8-\uFFEE\uFFFC\uFFFD]|\uD800[\uDD37-\uDD3F\uDD79-\uDD89\uDD8C-\uDD8E\uDD90-\uDD9C\uDDA0\uDDD0-\uDDFC]|\uD802[\uDC77\uDC78\uDEC8]|\uD805\uDF3F|\uD807[\uDFD5-\uDFF1]|\uD81A[\uDF3C-\uDF3F\uDF45]|\uD82F\uDC9C|\uD833[\uDF50-\uDFC3]|\uD834[\uDC00-\uDCF5\uDD00-\uDD26\uDD29-\uDD64\uDD6A-\uDD6C\uDD83\uDD84\uDD8C-\uDDA9\uDDAE-\uDDEA\uDE00-\uDE41\uDE45\uDF00-\uDF56]|\uD835[\uDEC1\uDEDB\uDEFB\uDF15\uDF35\uDF4F\uDF6F\uDF89\uDFA9\uDFC3]|\uD836[\uDC00-\uDDFF\uDE37-\uDE3A\uDE6D-\uDE74\uDE76-\uDE83\uDE85\uDE86]|\uD838[\uDD4F\uDEFF]|\uD83B[\uDCAC\uDCB0\uDD2E\uDEF0\uDEF1]|\uD83C[\uDC00-\uDC2B\uDC30-\uDC93\uDCA0-\uDCAE\uDCB1-\uDCBF\uDCC1-\uDCCF\uDCD1-\uDCF5\uDD0D-\uDDAD\uDDE6-\uDE02\uDE10-\uDE3B\uDE40-\uDE48\uDE50\uDE51\uDE60-\uDE65\uDF00-\uDFFF]|\uD83D[\uDC00-\uDED7\uDEDC-\uDEEC\uDEF0-\uDEFC\uDF00-\uDF76\uDF7B-\uDFD9\uDFE0-\uDFEB\uDFF0]|\uD83E[\uDC00-\uDC0B\uDC10-\uDC47\uDC50-\uDC59\uDC60-\uDC87\uDC90-\uDCAD\uDCB0\uDCB1\uDD00-\uDE53\uDE60-\uDE6D\uDE70-\uDE7C\uDE80-\uDE88\uDE90-\uDEBD\uDEBF-\uDEC5\uDECE-\uDEDB\uDEE0-\uDEE8\uDEF0-\uDEF8\uDF00-\uDF92\uDF94-\uDFCA]/, b = /[ \xA0\u1680\u2000-\u200A\u2028\u2029\u202F\u205F\u3000]/, F = Object.freeze({ __proto__: null, Any: C, Cc: y, Cf: /[\xAD\u0600-\u0605\u061C\u06DD\u070F\u0890\u0891\u08E2\u180E\u200B-\u200F\u202A-\u202E\u2060-\u2064\u2066-\u206F\uFEFF\uFFF9-\uFFFB]|\uD804[\uDCBD\uDCCD]|\uD80D[\uDC30-\uDC3F]|\uD82F[\uDCA0-\uDCA3]|\uD834[\uDD73-\uDD7A]|\uDB40[\uDC01\uDC20-\uDC7F]/, P: E, S: A, Z: b }), x = new Uint16Array('\u1D41<\xD5\u0131\u028A\u049D\u057B\u05D0\u0675\u06DE\u07A2\u07D6\u080F\u0A4A\u0A91\u0DA1\u0E6D\u0F09\u0F26\u10CA\u1228\u12E1\u1415\u149D\u14C3\u14DF\u1525\0\0\0\0\0\0\u156B\u16CD\u198D\u1C12\u1DDD\u1F7E\u2060\u21B0\u228D\u23C0\u23FB\u2442\u2824\u2912\u2D08\u2E48\u2FCE\u3016\u32BA\u3639\u37AC\u38FE\u3A28\u3A71\u3AE0\u3B2E\u0800EMabcfglmnoprstu\\bfms\x7F\x84\x8B\x90\x95\x98\xA6\xB3\xB9\xC8\xCFlig\u803B\xC6\u40C6P\u803B&\u4026cute\u803B\xC1\u40C1reve;\u4102\u0100iyx}rc\u803B\xC2\u40C2;\u4410r;\uC000\u{1D504}rave\u803B\xC0\u40C0pha;\u4391acr;\u4100d;\u6A53\u0100gp\x9D\xA1on;\u4104f;\uC000\u{1D538}plyFunction;\u6061ing\u803B\xC5\u40C5\u0100cs\xBE\xC3r;\uC000\u{1D49C}ign;\u6254ilde\u803B\xC3\u40C3ml\u803B\xC4\u40C4\u0400aceforsu\xE5\xFB\xFE\u0117\u011C\u0122\u0127\u012A\u0100cr\xEA\xF2kslash;\u6216\u0176\xF6\xF8;\u6AE7ed;\u6306y;\u4411\u0180crt\u0105\u010B\u0114ause;\u6235noullis;\u612Ca;\u4392r;\uC000\u{1D505}pf;\uC000\u{1D539}eve;\u42D8c\xF2\u0113mpeq;\u624E\u0700HOacdefhilorsu\u014D\u0151\u0156\u0180\u019E\u01A2\u01B5\u01B7\u01BA\u01DC\u0215\u0273\u0278\u027Ecy;\u4427PY\u803B\xA9\u40A9\u0180cpy\u015D\u0162\u017Aute;\u4106\u0100;i\u0167\u0168\u62D2talDifferentialD;\u6145leys;\u612D\u0200aeio\u0189\u018E\u0194\u0198ron;\u410Cdil\u803B\xC7\u40C7rc;\u4108nint;\u6230ot;\u410A\u0100dn\u01A7\u01ADilla;\u40B8terDot;\u40B7\xF2\u017Fi;\u43A7rcle\u0200DMPT\u01C7\u01CB\u01D1\u01D6ot;\u6299inus;\u6296lus;\u6295imes;\u6297o\u0100cs\u01E2\u01F8kwiseContourIntegral;\u6232eCurly\u0100DQ\u0203\u020FoubleQuote;\u601Duote;\u6019\u0200lnpu\u021E\u0228\u0247\u0255on\u0100;e\u0225\u0226\u6237;\u6A74\u0180git\u022F\u0236\u023Aruent;\u6261nt;\u622FourIntegral;\u622E\u0100fr\u024C\u024E;\u6102oduct;\u6210nterClockwiseContourIntegral;\u6233oss;\u6A2Fcr;\uC000\u{1D49E}p\u0100;C\u0284\u0285\u62D3ap;\u624D\u0580DJSZacefios\u02A0\u02AC\u02B0\u02B4\u02B8\u02CB\u02D7\u02E1\u02E6\u0333\u048D\u0100;o\u0179\u02A5trahd;\u6911cy;\u4402cy;\u4405cy;\u440F\u0180grs\u02BF\u02C4\u02C7ger;\u6021r;\u61A1hv;\u6AE4\u0100ay\u02D0\u02D5ron;\u410E;\u4414l\u0100;t\u02DD\u02DE\u6207a;\u4394r;\uC000\u{1D507}\u0100af\u02EB\u0327\u0100cm\u02F0\u0322ritical\u0200ADGT\u0300\u0306\u0316\u031Ccute;\u40B4o\u0174\u030B\u030D;\u42D9bleAcute;\u42DDrave;\u4060ilde;\u42DCond;\u62C4ferentialD;\u6146\u0470\u033D\0\0\0\u0342\u0354\0\u0405f;\uC000\u{1D53B}\u0180;DE\u0348\u0349\u034D\u40A8ot;\u60DCqual;\u6250ble\u0300CDLRUV\u0363\u0372\u0382\u03CF\u03E2\u03F8ontourIntegra\xEC\u0239o\u0274\u0379\0\0\u037B\xBB\u0349nArrow;\u61D3\u0100eo\u0387\u03A4ft\u0180ART\u0390\u0396\u03A1rrow;\u61D0ightArrow;\u61D4e\xE5\u02CAng\u0100LR\u03AB\u03C4eft\u0100AR\u03B3\u03B9rrow;\u67F8ightArrow;\u67FAightArrow;\u67F9ight\u0100AT\u03D8\u03DErrow;\u61D2ee;\u62A8p\u0241\u03E9\0\0\u03EFrrow;\u61D1ownArrow;\u61D5erticalBar;\u6225n\u0300ABLRTa\u0412\u042A\u0430\u045E\u047F\u037Crrow\u0180;BU\u041D\u041E\u0422\u6193ar;\u6913pArrow;\u61F5reve;\u4311eft\u02D2\u043A\0\u0446\0\u0450ightVector;\u6950eeVector;\u695Eector\u0100;B\u0459\u045A\u61BDar;\u6956ight\u01D4\u0467\0\u0471eeVector;\u695Fector\u0100;B\u047A\u047B\u61C1ar;\u6957ee\u0100;A\u0486\u0487\u62A4rrow;\u61A7\u0100ct\u0492\u0497r;\uC000\u{1D49F}rok;\u4110\u0800NTacdfglmopqstux\u04BD\u04C0\u04C4\u04CB\u04DE\u04E2\u04E7\u04EE\u04F5\u0521\u052F\u0536\u0552\u055D\u0560\u0565G;\u414AH\u803B\xD0\u40D0cute\u803B\xC9\u40C9\u0180aiy\u04D2\u04D7\u04DCron;\u411Arc\u803B\xCA\u40CA;\u442Dot;\u4116r;\uC000\u{1D508}rave\u803B\xC8\u40C8ement;\u6208\u0100ap\u04FA\u04FEcr;\u4112ty\u0253\u0506\0\0\u0512mallSquare;\u65FBerySmallSquare;\u65AB\u0100gp\u0526\u052Aon;\u4118f;\uC000\u{1D53C}silon;\u4395u\u0100ai\u053C\u0549l\u0100;T\u0542\u0543\u6A75ilde;\u6242librium;\u61CC\u0100ci\u0557\u055Ar;\u6130m;\u6A73a;\u4397ml\u803B\xCB\u40CB\u0100ip\u056A\u056Fsts;\u6203onentialE;\u6147\u0280cfios\u0585\u0588\u058D\u05B2\u05CCy;\u4424r;\uC000\u{1D509}lled\u0253\u0597\0\0\u05A3mallSquare;\u65FCerySmallSquare;\u65AA\u0370\u05BA\0\u05BF\0\0\u05C4f;\uC000\u{1D53D}All;\u6200riertrf;\u6131c\xF2\u05CB\u0600JTabcdfgorst\u05E8\u05EC\u05EF\u05FA\u0600\u0612\u0616\u061B\u061D\u0623\u066C\u0672cy;\u4403\u803B>\u403Emma\u0100;d\u05F7\u05F8\u4393;\u43DCreve;\u411E\u0180eiy\u0607\u060C\u0610dil;\u4122rc;\u411C;\u4413ot;\u4120r;\uC000\u{1D50A};\u62D9pf;\uC000\u{1D53E}eater\u0300EFGLST\u0635\u0644\u064E\u0656\u065B\u0666qual\u0100;L\u063E\u063F\u6265ess;\u62DBullEqual;\u6267reater;\u6AA2ess;\u6277lantEqual;\u6A7Eilde;\u6273cr;\uC000\u{1D4A2};\u626B\u0400Aacfiosu\u0685\u068B\u0696\u069B\u069E\u06AA\u06BE\u06CARDcy;\u442A\u0100ct\u0690\u0694ek;\u42C7;\u405Eirc;\u4124r;\u610ClbertSpace;\u610B\u01F0\u06AF\0\u06B2f;\u610DizontalLine;\u6500\u0100ct\u06C3\u06C5\xF2\u06A9rok;\u4126mp\u0144\u06D0\u06D8ownHum\xF0\u012Fqual;\u624F\u0700EJOacdfgmnostu\u06FA\u06FE\u0703\u0707\u070E\u071A\u071E\u0721\u0728\u0744\u0778\u078B\u078F\u0795cy;\u4415lig;\u4132cy;\u4401cute\u803B\xCD\u40CD\u0100iy\u0713\u0718rc\u803B\xCE\u40CE;\u4418ot;\u4130r;\u6111rave\u803B\xCC\u40CC\u0180;ap\u0720\u072F\u073F\u0100cg\u0734\u0737r;\u412AinaryI;\u6148lie\xF3\u03DD\u01F4\u0749\0\u0762\u0100;e\u074D\u074E\u622C\u0100gr\u0753\u0758ral;\u622Bsection;\u62C2isible\u0100CT\u076C\u0772omma;\u6063imes;\u6062\u0180gpt\u077F\u0783\u0788on;\u412Ef;\uC000\u{1D540}a;\u4399cr;\u6110ilde;\u4128\u01EB\u079A\0\u079Ecy;\u4406l\u803B\xCF\u40CF\u0280cfosu\u07AC\u07B7\u07BC\u07C2\u07D0\u0100iy\u07B1\u07B5rc;\u4134;\u4419r;\uC000\u{1D50D}pf;\uC000\u{1D541}\u01E3\u07C7\0\u07CCr;\uC000\u{1D4A5}rcy;\u4408kcy;\u4404\u0380HJacfos\u07E4\u07E8\u07EC\u07F1\u07FD\u0802\u0808cy;\u4425cy;\u440Cppa;\u439A\u0100ey\u07F6\u07FBdil;\u4136;\u441Ar;\uC000\u{1D50E}pf;\uC000\u{1D542}cr;\uC000\u{1D4A6}\u0580JTaceflmost\u0825\u0829\u082C\u0850\u0863\u09B3\u09B8\u09C7\u09CD\u0A37\u0A47cy;\u4409\u803B<\u403C\u0280cmnpr\u0837\u083C\u0841\u0844\u084Dute;\u4139bda;\u439Bg;\u67EAlacetrf;\u6112r;\u619E\u0180aey\u0857\u085C\u0861ron;\u413Ddil;\u413B;\u441B\u0100fs\u0868\u0970t\u0500ACDFRTUVar\u087E\u08A9\u08B1\u08E0\u08E6\u08FC\u092F\u095B\u0390\u096A\u0100nr\u0883\u088FgleBracket;\u67E8row\u0180;BR\u0899\u089A\u089E\u6190ar;\u61E4ightArrow;\u61C6eiling;\u6308o\u01F5\u08B7\0\u08C3bleBracket;\u67E6n\u01D4\u08C8\0\u08D2eeVector;\u6961ector\u0100;B\u08DB\u08DC\u61C3ar;\u6959loor;\u630Aight\u0100AV\u08EF\u08F5rrow;\u6194ector;\u694E\u0100er\u0901\u0917e\u0180;AV\u0909\u090A\u0910\u62A3rrow;\u61A4ector;\u695Aiangle\u0180;BE\u0924\u0925\u0929\u62B2ar;\u69CFqual;\u62B4p\u0180DTV\u0937\u0942\u094CownVector;\u6951eeVector;\u6960ector\u0100;B\u0956\u0957\u61BFar;\u6958ector\u0100;B\u0965\u0966\u61BCar;\u6952ight\xE1\u039Cs\u0300EFGLST\u097E\u098B\u0995\u099D\u09A2\u09ADqualGreater;\u62DAullEqual;\u6266reater;\u6276ess;\u6AA1lantEqual;\u6A7Dilde;\u6272r;\uC000\u{1D50F}\u0100;e\u09BD\u09BE\u62D8ftarrow;\u61DAidot;\u413F\u0180npw\u09D4\u0A16\u0A1Bg\u0200LRlr\u09DE\u09F7\u0A02\u0A10eft\u0100AR\u09E6\u09ECrrow;\u67F5ightArrow;\u67F7ightArrow;\u67F6eft\u0100ar\u03B3\u0A0Aight\xE1\u03BFight\xE1\u03CAf;\uC000\u{1D543}er\u0100LR\u0A22\u0A2CeftArrow;\u6199ightArrow;\u6198\u0180cht\u0A3E\u0A40\u0A42\xF2\u084C;\u61B0rok;\u4141;\u626A\u0400acefiosu\u0A5A\u0A5D\u0A60\u0A77\u0A7C\u0A85\u0A8B\u0A8Ep;\u6905y;\u441C\u0100dl\u0A65\u0A6FiumSpace;\u605Flintrf;\u6133r;\uC000\u{1D510}nusPlus;\u6213pf;\uC000\u{1D544}c\xF2\u0A76;\u439C\u0480Jacefostu\u0AA3\u0AA7\u0AAD\u0AC0\u0B14\u0B19\u0D91\u0D97\u0D9Ecy;\u440Acute;\u4143\u0180aey\u0AB4\u0AB9\u0ABEron;\u4147dil;\u4145;\u441D\u0180gsw\u0AC7\u0AF0\u0B0Eative\u0180MTV\u0AD3\u0ADF\u0AE8ediumSpace;\u600Bhi\u0100cn\u0AE6\u0AD8\xEB\u0AD9eryThi\xEE\u0AD9ted\u0100GL\u0AF8\u0B06reaterGreate\xF2\u0673essLes\xF3\u0A48Line;\u400Ar;\uC000\u{1D511}\u0200Bnpt\u0B22\u0B28\u0B37\u0B3Areak;\u6060BreakingSpace;\u40A0f;\u6115\u0680;CDEGHLNPRSTV\u0B55\u0B56\u0B6A\u0B7C\u0BA1\u0BEB\u0C04\u0C5E\u0C84\u0CA6\u0CD8\u0D61\u0D85\u6AEC\u0100ou\u0B5B\u0B64ngruent;\u6262pCap;\u626DoubleVerticalBar;\u6226\u0180lqx\u0B83\u0B8A\u0B9Bement;\u6209ual\u0100;T\u0B92\u0B93\u6260ilde;\uC000\u2242\u0338ists;\u6204reater\u0380;EFGLST\u0BB6\u0BB7\u0BBD\u0BC9\u0BD3\u0BD8\u0BE5\u626Fqual;\u6271ullEqual;\uC000\u2267\u0338reater;\uC000\u226B\u0338ess;\u6279lantEqual;\uC000\u2A7E\u0338ilde;\u6275ump\u0144\u0BF2\u0BFDownHump;\uC000\u224E\u0338qual;\uC000\u224F\u0338e\u0100fs\u0C0A\u0C27tTriangle\u0180;BE\u0C1A\u0C1B\u0C21\u62EAar;\uC000\u29CF\u0338qual;\u62ECs\u0300;EGLST\u0C35\u0C36\u0C3C\u0C44\u0C4B\u0C58\u626Equal;\u6270reater;\u6278ess;\uC000\u226A\u0338lantEqual;\uC000\u2A7D\u0338ilde;\u6274ested\u0100GL\u0C68\u0C79reaterGreater;\uC000\u2AA2\u0338essLess;\uC000\u2AA1\u0338recedes\u0180;ES\u0C92\u0C93\u0C9B\u6280qual;\uC000\u2AAF\u0338lantEqual;\u62E0\u0100ei\u0CAB\u0CB9verseElement;\u620CghtTriangle\u0180;BE\u0CCB\u0CCC\u0CD2\u62EBar;\uC000\u29D0\u0338qual;\u62ED\u0100qu\u0CDD\u0D0CuareSu\u0100bp\u0CE8\u0CF9set\u0100;E\u0CF0\u0CF3\uC000\u228F\u0338qual;\u62E2erset\u0100;E\u0D03\u0D06\uC000\u2290\u0338qual;\u62E3\u0180bcp\u0D13\u0D24\u0D4Eset\u0100;E\u0D1B\u0D1E\uC000\u2282\u20D2qual;\u6288ceeds\u0200;EST\u0D32\u0D33\u0D3B\u0D46\u6281qual;\uC000\u2AB0\u0338lantEqual;\u62E1ilde;\uC000\u227F\u0338erset\u0100;E\u0D58\u0D5B\uC000\u2283\u20D2qual;\u6289ilde\u0200;EFT\u0D6E\u0D6F\u0D75\u0D7F\u6241qual;\u6244ullEqual;\u6247ilde;\u6249erticalBar;\u6224cr;\uC000\u{1D4A9}ilde\u803B\xD1\u40D1;\u439D\u0700Eacdfgmoprstuv\u0DBD\u0DC2\u0DC9\u0DD5\u0DDB\u0DE0\u0DE7\u0DFC\u0E02\u0E20\u0E22\u0E32\u0E3F\u0E44lig;\u4152cute\u803B\xD3\u40D3\u0100iy\u0DCE\u0DD3rc\u803B\xD4\u40D4;\u441Eblac;\u4150r;\uC000\u{1D512}rave\u803B\xD2\u40D2\u0180aei\u0DEE\u0DF2\u0DF6cr;\u414Cga;\u43A9cron;\u439Fpf;\uC000\u{1D546}enCurly\u0100DQ\u0E0E\u0E1AoubleQuote;\u601Cuote;\u6018;\u6A54\u0100cl\u0E27\u0E2Cr;\uC000\u{1D4AA}ash\u803B\xD8\u40D8i\u016C\u0E37\u0E3Cde\u803B\xD5\u40D5es;\u6A37ml\u803B\xD6\u40D6er\u0100BP\u0E4B\u0E60\u0100ar\u0E50\u0E53r;\u603Eac\u0100ek\u0E5A\u0E5C;\u63DEet;\u63B4arenthesis;\u63DC\u0480acfhilors\u0E7F\u0E87\u0E8A\u0E8F\u0E92\u0E94\u0E9D\u0EB0\u0EFCrtialD;\u6202y;\u441Fr;\uC000\u{1D513}i;\u43A6;\u43A0usMinus;\u40B1\u0100ip\u0EA2\u0EADncareplan\xE5\u069Df;\u6119\u0200;eio\u0EB9\u0EBA\u0EE0\u0EE4\u6ABBcedes\u0200;EST\u0EC8\u0EC9\u0ECF\u0EDA\u627Aqual;\u6AAFlantEqual;\u627Cilde;\u627Eme;\u6033\u0100dp\u0EE9\u0EEEuct;\u620Fortion\u0100;a\u0225\u0EF9l;\u621D\u0100ci\u0F01\u0F06r;\uC000\u{1D4AB};\u43A8\u0200Ufos\u0F11\u0F16\u0F1B\u0F1FOT\u803B"\u4022r;\uC000\u{1D514}pf;\u611Acr;\uC000\u{1D4AC}\u0600BEacefhiorsu\u0F3E\u0F43\u0F47\u0F60\u0F73\u0FA7\u0FAA\u0FAD\u1096\u10A9\u10B4\u10BEarr;\u6910G\u803B\xAE\u40AE\u0180cnr\u0F4E\u0F53\u0F56ute;\u4154g;\u67EBr\u0100;t\u0F5C\u0F5D\u61A0l;\u6916\u0180aey\u0F67\u0F6C\u0F71ron;\u4158dil;\u4156;\u4420\u0100;v\u0F78\u0F79\u611Cerse\u0100EU\u0F82\u0F99\u0100lq\u0F87\u0F8Eement;\u620Builibrium;\u61CBpEquilibrium;\u696Fr\xBB\u0F79o;\u43A1ght\u0400ACDFTUVa\u0FC1\u0FEB\u0FF3\u1022\u1028\u105B\u1087\u03D8\u0100nr\u0FC6\u0FD2gleBracket;\u67E9row\u0180;BL\u0FDC\u0FDD\u0FE1\u6192ar;\u61E5eftArrow;\u61C4eiling;\u6309o\u01F5\u0FF9\0\u1005bleBracket;\u67E7n\u01D4\u100A\0\u1014eeVector;\u695Dector\u0100;B\u101D\u101E\u61C2ar;\u6955loor;\u630B\u0100er\u102D\u1043e\u0180;AV\u1035\u1036\u103C\u62A2rrow;\u61A6ector;\u695Biangle\u0180;BE\u1050\u1051\u1055\u62B3ar;\u69D0qual;\u62B5p\u0180DTV\u1063\u106E\u1078ownVector;\u694FeeVector;\u695Cector\u0100;B\u1082\u1083\u61BEar;\u6954ector\u0100;B\u1091\u1092\u61C0ar;\u6953\u0100pu\u109B\u109Ef;\u611DndImplies;\u6970ightarrow;\u61DB\u0100ch\u10B9\u10BCr;\u611B;\u61B1leDelayed;\u69F4\u0680HOacfhimoqstu\u10E4\u10F1\u10F7\u10FD\u1119\u111E\u1151\u1156\u1161\u1167\u11B5\u11BB\u11BF\u0100Cc\u10E9\u10EEHcy;\u4429y;\u4428FTcy;\u442Ccute;\u415A\u0280;aeiy\u1108\u1109\u110E\u1113\u1117\u6ABCron;\u4160dil;\u415Erc;\u415C;\u4421r;\uC000\u{1D516}ort\u0200DLRU\u112A\u1134\u113E\u1149ownArrow\xBB\u041EeftArrow\xBB\u089AightArrow\xBB\u0FDDpArrow;\u6191gma;\u43A3allCircle;\u6218pf;\uC000\u{1D54A}\u0272\u116D\0\0\u1170t;\u621Aare\u0200;ISU\u117B\u117C\u1189\u11AF\u65A1ntersection;\u6293u\u0100bp\u118F\u119Eset\u0100;E\u1197\u1198\u628Fqual;\u6291erset\u0100;E\u11A8\u11A9\u6290qual;\u6292nion;\u6294cr;\uC000\u{1D4AE}ar;\u62C6\u0200bcmp\u11C8\u11DB\u1209\u120B\u0100;s\u11CD\u11CE\u62D0et\u0100;E\u11CD\u11D5qual;\u6286\u0100ch\u11E0\u1205eeds\u0200;EST\u11ED\u11EE\u11F4\u11FF\u627Bqual;\u6AB0lantEqual;\u627Dilde;\u627FTh\xE1\u0F8C;\u6211\u0180;es\u1212\u1213\u1223\u62D1rset\u0100;E\u121C\u121D\u6283qual;\u6287et\xBB\u1213\u0580HRSacfhiors\u123E\u1244\u1249\u1255\u125E\u1271\u1276\u129F\u12C2\u12C8\u12D1ORN\u803B\xDE\u40DEADE;\u6122\u0100Hc\u124E\u1252cy;\u440By;\u4426\u0100bu\u125A\u125C;\u4009;\u43A4\u0180aey\u1265\u126A\u126Fron;\u4164dil;\u4162;\u4422r;\uC000\u{1D517}\u0100ei\u127B\u1289\u01F2\u1280\0\u1287efore;\u6234a;\u4398\u0100cn\u128E\u1298kSpace;\uC000\u205F\u200ASpace;\u6009lde\u0200;EFT\u12AB\u12AC\u12B2\u12BC\u623Cqual;\u6243ullEqual;\u6245ilde;\u6248pf;\uC000\u{1D54B}ipleDot;\u60DB\u0100ct\u12D6\u12DBr;\uC000\u{1D4AF}rok;\u4166\u0AE1\u12F7\u130E\u131A\u1326\0\u132C\u1331\0\0\0\0\0\u1338\u133D\u1377\u1385\0\u13FF\u1404\u140A\u1410\u0100cr\u12FB\u1301ute\u803B\xDA\u40DAr\u0100;o\u1307\u1308\u619Fcir;\u6949r\u01E3\u1313\0\u1316y;\u440Eve;\u416C\u0100iy\u131E\u1323rc\u803B\xDB\u40DB;\u4423blac;\u4170r;\uC000\u{1D518}rave\u803B\xD9\u40D9acr;\u416A\u0100di\u1341\u1369er\u0100BP\u1348\u135D\u0100ar\u134D\u1350r;\u405Fac\u0100ek\u1357\u1359;\u63DFet;\u63B5arenthesis;\u63DDon\u0100;P\u1370\u1371\u62C3lus;\u628E\u0100gp\u137B\u137Fon;\u4172f;\uC000\u{1D54C}\u0400ADETadps\u1395\u13AE\u13B8\u13C4\u03E8\u13D2\u13D7\u13F3rrow\u0180;BD\u1150\u13A0\u13A4ar;\u6912ownArrow;\u61C5ownArrow;\u6195quilibrium;\u696Eee\u0100;A\u13CB\u13CC\u62A5rrow;\u61A5own\xE1\u03F3er\u0100LR\u13DE\u13E8eftArrow;\u6196ightArrow;\u6197i\u0100;l\u13F9\u13FA\u43D2on;\u43A5ing;\u416Ecr;\uC000\u{1D4B0}ilde;\u4168ml\u803B\xDC\u40DC\u0480Dbcdefosv\u1427\u142C\u1430\u1433\u143E\u1485\u148A\u1490\u1496ash;\u62ABar;\u6AEBy;\u4412ash\u0100;l\u143B\u143C\u62A9;\u6AE6\u0100er\u1443\u1445;\u62C1\u0180bty\u144C\u1450\u147Aar;\u6016\u0100;i\u144F\u1455cal\u0200BLST\u1461\u1465\u146A\u1474ar;\u6223ine;\u407Ceparator;\u6758ilde;\u6240ThinSpace;\u600Ar;\uC000\u{1D519}pf;\uC000\u{1D54D}cr;\uC000\u{1D4B1}dash;\u62AA\u0280cefos\u14A7\u14AC\u14B1\u14B6\u14BCirc;\u4174dge;\u62C0r;\uC000\u{1D51A}pf;\uC000\u{1D54E}cr;\uC000\u{1D4B2}\u0200fios\u14CB\u14D0\u14D2\u14D8r;\uC000\u{1D51B};\u439Epf;\uC000\u{1D54F}cr;\uC000\u{1D4B3}\u0480AIUacfosu\u14F1\u14F5\u14F9\u14FD\u1504\u150F\u1514\u151A\u1520cy;\u442Fcy;\u4407cy;\u442Ecute\u803B\xDD\u40DD\u0100iy\u1509\u150Drc;\u4176;\u442Br;\uC000\u{1D51C}pf;\uC000\u{1D550}cr;\uC000\u{1D4B4}ml;\u4178\u0400Hacdefos\u1535\u1539\u153F\u154B\u154F\u155D\u1560\u1564cy;\u4416cute;\u4179\u0100ay\u1544\u1549ron;\u417D;\u4417ot;\u417B\u01F2\u1554\0\u155BoWidt\xE8\u0AD9a;\u4396r;\u6128pf;\u6124cr;\uC000\u{1D4B5}\u0BE1\u1583\u158A\u1590\0\u15B0\u15B6\u15BF\0\0\0\0\u15C6\u15DB\u15EB\u165F\u166D\0\u1695\u169B\u16B2\u16B9\0\u16BEcute\u803B\xE1\u40E1reve;\u4103\u0300;Ediuy\u159C\u159D\u15A1\u15A3\u15A8\u15AD\u623E;\uC000\u223E\u0333;\u623Frc\u803B\xE2\u40E2te\u80BB\xB4\u0306;\u4430lig\u803B\xE6\u40E6\u0100;r\xB2\u15BA;\uC000\u{1D51E}rave\u803B\xE0\u40E0\u0100ep\u15CA\u15D6\u0100fp\u15CF\u15D4sym;\u6135\xE8\u15D3ha;\u43B1\u0100ap\u15DFc\u0100cl\u15E4\u15E7r;\u4101g;\u6A3F\u0264\u15F0\0\0\u160A\u0280;adsv\u15FA\u15FB\u15FF\u1601\u1607\u6227nd;\u6A55;\u6A5Clope;\u6A58;\u6A5A\u0380;elmrsz\u1618\u1619\u161B\u161E\u163F\u164F\u1659\u6220;\u69A4e\xBB\u1619sd\u0100;a\u1625\u1626\u6221\u0461\u1630\u1632\u1634\u1636\u1638\u163A\u163C\u163E;\u69A8;\u69A9;\u69AA;\u69AB;\u69AC;\u69AD;\u69AE;\u69AFt\u0100;v\u1645\u1646\u621Fb\u0100;d\u164C\u164D\u62BE;\u699D\u0100pt\u1654\u1657h;\u6222\xBB\xB9arr;\u637C\u0100gp\u1663\u1667on;\u4105f;\uC000\u{1D552}\u0380;Eaeiop\u12C1\u167B\u167D\u1682\u1684\u1687\u168A;\u6A70cir;\u6A6F;\u624Ad;\u624Bs;\u4027rox\u0100;e\u12C1\u1692\xF1\u1683ing\u803B\xE5\u40E5\u0180cty\u16A1\u16A6\u16A8r;\uC000\u{1D4B6};\u402Amp\u0100;e\u12C1\u16AF\xF1\u0288ilde\u803B\xE3\u40E3ml\u803B\xE4\u40E4\u0100ci\u16C2\u16C8onin\xF4\u0272nt;\u6A11\u0800Nabcdefiklnoprsu\u16ED\u16F1\u1730\u173C\u1743\u1748\u1778\u177D\u17E0\u17E6\u1839\u1850\u170D\u193D\u1948\u1970ot;\u6AED\u0100cr\u16F6\u171Ek\u0200ceps\u1700\u1705\u170D\u1713ong;\u624Cpsilon;\u43F6rime;\u6035im\u0100;e\u171A\u171B\u623Dq;\u62CD\u0176\u1722\u1726ee;\u62BDed\u0100;g\u172C\u172D\u6305e\xBB\u172Drk\u0100;t\u135C\u1737brk;\u63B6\u0100oy\u1701\u1741;\u4431quo;\u601E\u0280cmprt\u1753\u175B\u1761\u1764\u1768aus\u0100;e\u010A\u0109ptyv;\u69B0s\xE9\u170Cno\xF5\u0113\u0180ahw\u176F\u1771\u1773;\u43B2;\u6136een;\u626Cr;\uC000\u{1D51F}g\u0380costuvw\u178D\u179D\u17B3\u17C1\u17D5\u17DB\u17DE\u0180aiu\u1794\u1796\u179A\xF0\u0760rc;\u65EFp\xBB\u1371\u0180dpt\u17A4\u17A8\u17ADot;\u6A00lus;\u6A01imes;\u6A02\u0271\u17B9\0\0\u17BEcup;\u6A06ar;\u6605riangle\u0100du\u17CD\u17D2own;\u65BDp;\u65B3plus;\u6A04e\xE5\u1444\xE5\u14ADarow;\u690D\u0180ako\u17ED\u1826\u1835\u0100cn\u17F2\u1823k\u0180lst\u17FA\u05AB\u1802ozenge;\u69EBriangle\u0200;dlr\u1812\u1813\u1818\u181D\u65B4own;\u65BEeft;\u65C2ight;\u65B8k;\u6423\u01B1\u182B\0\u1833\u01B2\u182F\0\u1831;\u6592;\u65914;\u6593ck;\u6588\u0100eo\u183E\u184D\u0100;q\u1843\u1846\uC000=\u20E5uiv;\uC000\u2261\u20E5t;\u6310\u0200ptwx\u1859\u185E\u1867\u186Cf;\uC000\u{1D553}\u0100;t\u13CB\u1863om\xBB\u13CCtie;\u62C8\u0600DHUVbdhmptuv\u1885\u1896\u18AA\u18BB\u18D7\u18DB\u18EC\u18FF\u1905\u190A\u1910\u1921\u0200LRlr\u188E\u1890\u1892\u1894;\u6557;\u6554;\u6556;\u6553\u0280;DUdu\u18A1\u18A2\u18A4\u18A6\u18A8\u6550;\u6566;\u6569;\u6564;\u6567\u0200LRlr\u18B3\u18B5\u18B7\u18B9;\u655D;\u655A;\u655C;\u6559\u0380;HLRhlr\u18CA\u18CB\u18CD\u18CF\u18D1\u18D3\u18D5\u6551;\u656C;\u6563;\u6560;\u656B;\u6562;\u655Fox;\u69C9\u0200LRlr\u18E4\u18E6\u18E8\u18EA;\u6555;\u6552;\u6510;\u650C\u0280;DUdu\u06BD\u18F7\u18F9\u18FB\u18FD;\u6565;\u6568;\u652C;\u6534inus;\u629Flus;\u629Eimes;\u62A0\u0200LRlr\u1919\u191B\u191D\u191F;\u655B;\u6558;\u6518;\u6514\u0380;HLRhlr\u1930\u1931\u1933\u1935\u1937\u1939\u193B\u6502;\u656A;\u6561;\u655E;\u653C;\u6524;\u651C\u0100ev\u0123\u1942bar\u803B\xA6\u40A6\u0200ceio\u1951\u1956\u195A\u1960r;\uC000\u{1D4B7}mi;\u604Fm\u0100;e\u171A\u171Cl\u0180;bh\u1968\u1969\u196B\u405C;\u69C5sub;\u67C8\u016C\u1974\u197El\u0100;e\u1979\u197A\u6022t\xBB\u197Ap\u0180;Ee\u012F\u1985\u1987;\u6AAE\u0100;q\u06DC\u06DB\u0CE1\u19A7\0\u19E8\u1A11\u1A15\u1A32\0\u1A37\u1A50\0\0\u1AB4\0\0\u1AC1\0\0\u1B21\u1B2E\u1B4D\u1B52\0\u1BFD\0\u1C0C\u0180cpr\u19AD\u19B2\u19DDute;\u4107\u0300;abcds\u19BF\u19C0\u19C4\u19CA\u19D5\u19D9\u6229nd;\u6A44rcup;\u6A49\u0100au\u19CF\u19D2p;\u6A4Bp;\u6A47ot;\u6A40;\uC000\u2229\uFE00\u0100eo\u19E2\u19E5t;\u6041\xEE\u0693\u0200aeiu\u19F0\u19FB\u1A01\u1A05\u01F0\u19F5\0\u19F8s;\u6A4Don;\u410Ddil\u803B\xE7\u40E7rc;\u4109ps\u0100;s\u1A0C\u1A0D\u6A4Cm;\u6A50ot;\u410B\u0180dmn\u1A1B\u1A20\u1A26il\u80BB\xB8\u01ADptyv;\u69B2t\u8100\xA2;e\u1A2D\u1A2E\u40A2r\xE4\u01B2r;\uC000\u{1D520}\u0180cei\u1A3D\u1A40\u1A4Dy;\u4447ck\u0100;m\u1A47\u1A48\u6713ark\xBB\u1A48;\u43C7r\u0380;Ecefms\u1A5F\u1A60\u1A62\u1A6B\u1AA4\u1AAA\u1AAE\u65CB;\u69C3\u0180;el\u1A69\u1A6A\u1A6D\u42C6q;\u6257e\u0261\u1A74\0\0\u1A88rrow\u0100lr\u1A7C\u1A81eft;\u61BAight;\u61BB\u0280RSacd\u1A92\u1A94\u1A96\u1A9A\u1A9F\xBB\u0F47;\u64C8st;\u629Birc;\u629Aash;\u629Dnint;\u6A10id;\u6AEFcir;\u69C2ubs\u0100;u\u1ABB\u1ABC\u6663it\xBB\u1ABC\u02EC\u1AC7\u1AD4\u1AFA\0\u1B0Aon\u0100;e\u1ACD\u1ACE\u403A\u0100;q\xC7\xC6\u026D\u1AD9\0\0\u1AE2a\u0100;t\u1ADE\u1ADF\u402C;\u4040\u0180;fl\u1AE8\u1AE9\u1AEB\u6201\xEE\u1160e\u0100mx\u1AF1\u1AF6ent\xBB\u1AE9e\xF3\u024D\u01E7\u1AFE\0\u1B07\u0100;d\u12BB\u1B02ot;\u6A6Dn\xF4\u0246\u0180fry\u1B10\u1B14\u1B17;\uC000\u{1D554}o\xE4\u0254\u8100\xA9;s\u0155\u1B1Dr;\u6117\u0100ao\u1B25\u1B29rr;\u61B5ss;\u6717\u0100cu\u1B32\u1B37r;\uC000\u{1D4B8}\u0100bp\u1B3C\u1B44\u0100;e\u1B41\u1B42\u6ACF;\u6AD1\u0100;e\u1B49\u1B4A\u6AD0;\u6AD2dot;\u62EF\u0380delprvw\u1B60\u1B6C\u1B77\u1B82\u1BAC\u1BD4\u1BF9arr\u0100lr\u1B68\u1B6A;\u6938;\u6935\u0270\u1B72\0\0\u1B75r;\u62DEc;\u62DFarr\u0100;p\u1B7F\u1B80\u61B6;\u693D\u0300;bcdos\u1B8F\u1B90\u1B96\u1BA1\u1BA5\u1BA8\u622Arcap;\u6A48\u0100au\u1B9B\u1B9Ep;\u6A46p;\u6A4Aot;\u628Dr;\u6A45;\uC000\u222A\uFE00\u0200alrv\u1BB5\u1BBF\u1BDE\u1BE3rr\u0100;m\u1BBC\u1BBD\u61B7;\u693Cy\u0180evw\u1BC7\u1BD4\u1BD8q\u0270\u1BCE\0\0\u1BD2re\xE3\u1B73u\xE3\u1B75ee;\u62CEedge;\u62CFen\u803B\xA4\u40A4earrow\u0100lr\u1BEE\u1BF3eft\xBB\u1B80ight\xBB\u1BBDe\xE4\u1BDD\u0100ci\u1C01\u1C07onin\xF4\u01F7nt;\u6231lcty;\u632D\u0980AHabcdefhijlorstuwz\u1C38\u1C3B\u1C3F\u1C5D\u1C69\u1C75\u1C8A\u1C9E\u1CAC\u1CB7\u1CFB\u1CFF\u1D0D\u1D7B\u1D91\u1DAB\u1DBB\u1DC6\u1DCDr\xF2\u0381ar;\u6965\u0200glrs\u1C48\u1C4D\u1C52\u1C54ger;\u6020eth;\u6138\xF2\u1133h\u0100;v\u1C5A\u1C5B\u6010\xBB\u090A\u016B\u1C61\u1C67arow;\u690Fa\xE3\u0315\u0100ay\u1C6E\u1C73ron;\u410F;\u4434\u0180;ao\u0332\u1C7C\u1C84\u0100gr\u02BF\u1C81r;\u61CAtseq;\u6A77\u0180glm\u1C91\u1C94\u1C98\u803B\xB0\u40B0ta;\u43B4ptyv;\u69B1\u0100ir\u1CA3\u1CA8sht;\u697F;\uC000\u{1D521}ar\u0100lr\u1CB3\u1CB5\xBB\u08DC\xBB\u101E\u0280aegsv\u1CC2\u0378\u1CD6\u1CDC\u1CE0m\u0180;os\u0326\u1CCA\u1CD4nd\u0100;s\u0326\u1CD1uit;\u6666amma;\u43DDin;\u62F2\u0180;io\u1CE7\u1CE8\u1CF8\u40F7de\u8100\xF7;o\u1CE7\u1CF0ntimes;\u62C7n\xF8\u1CF7cy;\u4452c\u026F\u1D06\0\0\u1D0Arn;\u631Eop;\u630D\u0280lptuw\u1D18\u1D1D\u1D22\u1D49\u1D55lar;\u4024f;\uC000\u{1D555}\u0280;emps\u030B\u1D2D\u1D37\u1D3D\u1D42q\u0100;d\u0352\u1D33ot;\u6251inus;\u6238lus;\u6214quare;\u62A1blebarwedg\xE5\xFAn\u0180adh\u112E\u1D5D\u1D67ownarrow\xF3\u1C83arpoon\u0100lr\u1D72\u1D76ef\xF4\u1CB4igh\xF4\u1CB6\u0162\u1D7F\u1D85karo\xF7\u0F42\u026F\u1D8A\0\0\u1D8Ern;\u631Fop;\u630C\u0180cot\u1D98\u1DA3\u1DA6\u0100ry\u1D9D\u1DA1;\uC000\u{1D4B9};\u4455l;\u69F6rok;\u4111\u0100dr\u1DB0\u1DB4ot;\u62F1i\u0100;f\u1DBA\u1816\u65BF\u0100ah\u1DC0\u1DC3r\xF2\u0429a\xF2\u0FA6angle;\u69A6\u0100ci\u1DD2\u1DD5y;\u445Fgrarr;\u67FF\u0900Dacdefglmnopqrstux\u1E01\u1E09\u1E19\u1E38\u0578\u1E3C\u1E49\u1E61\u1E7E\u1EA5\u1EAF\u1EBD\u1EE1\u1F2A\u1F37\u1F44\u1F4E\u1F5A\u0100Do\u1E06\u1D34o\xF4\u1C89\u0100cs\u1E0E\u1E14ute\u803B\xE9\u40E9ter;\u6A6E\u0200aioy\u1E22\u1E27\u1E31\u1E36ron;\u411Br\u0100;c\u1E2D\u1E2E\u6256\u803B\xEA\u40EAlon;\u6255;\u444Dot;\u4117\u0100Dr\u1E41\u1E45ot;\u6252;\uC000\u{1D522}\u0180;rs\u1E50\u1E51\u1E57\u6A9Aave\u803B\xE8\u40E8\u0100;d\u1E5C\u1E5D\u6A96ot;\u6A98\u0200;ils\u1E6A\u1E6B\u1E72\u1E74\u6A99nters;\u63E7;\u6113\u0100;d\u1E79\u1E7A\u6A95ot;\u6A97\u0180aps\u1E85\u1E89\u1E97cr;\u4113ty\u0180;sv\u1E92\u1E93\u1E95\u6205et\xBB\u1E93p\u01001;\u1E9D\u1EA4\u0133\u1EA1\u1EA3;\u6004;\u6005\u6003\u0100gs\u1EAA\u1EAC;\u414Bp;\u6002\u0100gp\u1EB4\u1EB8on;\u4119f;\uC000\u{1D556}\u0180als\u1EC4\u1ECE\u1ED2r\u0100;s\u1ECA\u1ECB\u62D5l;\u69E3us;\u6A71i\u0180;lv\u1EDA\u1EDB\u1EDF\u43B5on\xBB\u1EDB;\u43F5\u0200csuv\u1EEA\u1EF3\u1F0B\u1F23\u0100io\u1EEF\u1E31rc\xBB\u1E2E\u0269\u1EF9\0\0\u1EFB\xED\u0548ant\u0100gl\u1F02\u1F06tr\xBB\u1E5Dess\xBB\u1E7A\u0180aei\u1F12\u1F16\u1F1Als;\u403Dst;\u625Fv\u0100;D\u0235\u1F20D;\u6A78parsl;\u69E5\u0100Da\u1F2F\u1F33ot;\u6253rr;\u6971\u0180cdi\u1F3E\u1F41\u1EF8r;\u612Fo\xF4\u0352\u0100ah\u1F49\u1F4B;\u43B7\u803B\xF0\u40F0\u0100mr\u1F53\u1F57l\u803B\xEB\u40EBo;\u60AC\u0180cip\u1F61\u1F64\u1F67l;\u4021s\xF4\u056E\u0100eo\u1F6C\u1F74ctatio\xEE\u0559nential\xE5\u0579\u09E1\u1F92\0\u1F9E\0\u1FA1\u1FA7\0\0\u1FC6\u1FCC\0\u1FD3\0\u1FE6\u1FEA\u2000\0\u2008\u205Allingdotse\xF1\u1E44y;\u4444male;\u6640\u0180ilr\u1FAD\u1FB3\u1FC1lig;\u8000\uFB03\u0269\u1FB9\0\0\u1FBDg;\u8000\uFB00ig;\u8000\uFB04;\uC000\u{1D523}lig;\u8000\uFB01lig;\uC000fj\u0180alt\u1FD9\u1FDC\u1FE1t;\u666Dig;\u8000\uFB02ns;\u65B1of;\u4192\u01F0\u1FEE\0\u1FF3f;\uC000\u{1D557}\u0100ak\u05BF\u1FF7\u0100;v\u1FFC\u1FFD\u62D4;\u6AD9artint;\u6A0D\u0100ao\u200C\u2055\u0100cs\u2011\u2052\u03B1\u201A\u2030\u2038\u2045\u2048\0\u2050\u03B2\u2022\u2025\u2027\u202A\u202C\0\u202E\u803B\xBD\u40BD;\u6153\u803B\xBC\u40BC;\u6155;\u6159;\u615B\u01B3\u2034\0\u2036;\u6154;\u6156\u02B4\u203E\u2041\0\0\u2043\u803B\xBE\u40BE;\u6157;\u615C5;\u6158\u01B6\u204C\0\u204E;\u615A;\u615D8;\u615El;\u6044wn;\u6322cr;\uC000\u{1D4BB}\u0880Eabcdefgijlnorstv\u2082\u2089\u209F\u20A5\u20B0\u20B4\u20F0\u20F5\u20FA\u20FF\u2103\u2112\u2138\u0317\u213E\u2152\u219E\u0100;l\u064D\u2087;\u6A8C\u0180cmp\u2090\u2095\u209Dute;\u41F5ma\u0100;d\u209C\u1CDA\u43B3;\u6A86reve;\u411F\u0100iy\u20AA\u20AErc;\u411D;\u4433ot;\u4121\u0200;lqs\u063E\u0642\u20BD\u20C9\u0180;qs\u063E\u064C\u20C4lan\xF4\u0665\u0200;cdl\u0665\u20D2\u20D5\u20E5c;\u6AA9ot\u0100;o\u20DC\u20DD\u6A80\u0100;l\u20E2\u20E3\u6A82;\u6A84\u0100;e\u20EA\u20ED\uC000\u22DB\uFE00s;\u6A94r;\uC000\u{1D524}\u0100;g\u0673\u061Bmel;\u6137cy;\u4453\u0200;Eaj\u065A\u210C\u210E\u2110;\u6A92;\u6AA5;\u6AA4\u0200Eaes\u211B\u211D\u2129\u2134;\u6269p\u0100;p\u2123\u2124\u6A8Arox\xBB\u2124\u0100;q\u212E\u212F\u6A88\u0100;q\u212E\u211Bim;\u62E7pf;\uC000\u{1D558}\u0100ci\u2143\u2146r;\u610Am\u0180;el\u066B\u214E\u2150;\u6A8E;\u6A90\u8300>;cdlqr\u05EE\u2160\u216A\u216E\u2173\u2179\u0100ci\u2165\u2167;\u6AA7r;\u6A7Aot;\u62D7Par;\u6995uest;\u6A7C\u0280adels\u2184\u216A\u2190\u0656\u219B\u01F0\u2189\0\u218Epro\xF8\u209Er;\u6978q\u0100lq\u063F\u2196les\xF3\u2088i\xED\u066B\u0100en\u21A3\u21ADrtneqq;\uC000\u2269\uFE00\xC5\u21AA\u0500Aabcefkosy\u21C4\u21C7\u21F1\u21F5\u21FA\u2218\u221D\u222F\u2268\u227Dr\xF2\u03A0\u0200ilmr\u21D0\u21D4\u21D7\u21DBrs\xF0\u1484f\xBB\u2024il\xF4\u06A9\u0100dr\u21E0\u21E4cy;\u444A\u0180;cw\u08F4\u21EB\u21EFir;\u6948;\u61ADar;\u610Firc;\u4125\u0180alr\u2201\u220E\u2213rts\u0100;u\u2209\u220A\u6665it\xBB\u220Alip;\u6026con;\u62B9r;\uC000\u{1D525}s\u0100ew\u2223\u2229arow;\u6925arow;\u6926\u0280amopr\u223A\u223E\u2243\u225E\u2263rr;\u61FFtht;\u623Bk\u0100lr\u2249\u2253eftarrow;\u61A9ightarrow;\u61AAf;\uC000\u{1D559}bar;\u6015\u0180clt\u226F\u2274\u2278r;\uC000\u{1D4BD}as\xE8\u21F4rok;\u4127\u0100bp\u2282\u2287ull;\u6043hen\xBB\u1C5B\u0AE1\u22A3\0\u22AA\0\u22B8\u22C5\u22CE\0\u22D5\u22F3\0\0\u22F8\u2322\u2367\u2362\u237F\0\u2386\u23AA\u23B4cute\u803B\xED\u40ED\u0180;iy\u0771\u22B0\u22B5rc\u803B\xEE\u40EE;\u4438\u0100cx\u22BC\u22BFy;\u4435cl\u803B\xA1\u40A1\u0100fr\u039F\u22C9;\uC000\u{1D526}rave\u803B\xEC\u40EC\u0200;ino\u073E\u22DD\u22E9\u22EE\u0100in\u22E2\u22E6nt;\u6A0Ct;\u622Dfin;\u69DCta;\u6129lig;\u4133\u0180aop\u22FE\u231A\u231D\u0180cgt\u2305\u2308\u2317r;\u412B\u0180elp\u071F\u230F\u2313in\xE5\u078Ear\xF4\u0720h;\u4131f;\u62B7ed;\u41B5\u0280;cfot\u04F4\u232C\u2331\u233D\u2341are;\u6105in\u0100;t\u2338\u2339\u621Eie;\u69DDdo\xF4\u2319\u0280;celp\u0757\u234C\u2350\u235B\u2361al;\u62BA\u0100gr\u2355\u2359er\xF3\u1563\xE3\u234Darhk;\u6A17rod;\u6A3C\u0200cgpt\u236F\u2372\u2376\u237By;\u4451on;\u412Ff;\uC000\u{1D55A}a;\u43B9uest\u803B\xBF\u40BF\u0100ci\u238A\u238Fr;\uC000\u{1D4BE}n\u0280;Edsv\u04F4\u239B\u239D\u23A1\u04F3;\u62F9ot;\u62F5\u0100;v\u23A6\u23A7\u62F4;\u62F3\u0100;i\u0777\u23AElde;\u4129\u01EB\u23B8\0\u23BCcy;\u4456l\u803B\xEF\u40EF\u0300cfmosu\u23CC\u23D7\u23DC\u23E1\u23E7\u23F5\u0100iy\u23D1\u23D5rc;\u4135;\u4439r;\uC000\u{1D527}ath;\u4237pf;\uC000\u{1D55B}\u01E3\u23EC\0\u23F1r;\uC000\u{1D4BF}rcy;\u4458kcy;\u4454\u0400acfghjos\u240B\u2416\u2422\u2427\u242D\u2431\u2435\u243Bppa\u0100;v\u2413\u2414\u43BA;\u43F0\u0100ey\u241B\u2420dil;\u4137;\u443Ar;\uC000\u{1D528}reen;\u4138cy;\u4445cy;\u445Cpf;\uC000\u{1D55C}cr;\uC000\u{1D4C0}\u0B80ABEHabcdefghjlmnoprstuv\u2470\u2481\u2486\u248D\u2491\u250E\u253D\u255A\u2580\u264E\u265E\u2665\u2679\u267D\u269A\u26B2\u26D8\u275D\u2768\u278B\u27C0\u2801\u2812\u0180art\u2477\u247A\u247Cr\xF2\u09C6\xF2\u0395ail;\u691Barr;\u690E\u0100;g\u0994\u248B;\u6A8Bar;\u6962\u0963\u24A5\0\u24AA\0\u24B1\0\0\0\0\0\u24B5\u24BA\0\u24C6\u24C8\u24CD\0\u24F9ute;\u413Amptyv;\u69B4ra\xEE\u084Cbda;\u43BBg\u0180;dl\u088E\u24C1\u24C3;\u6991\xE5\u088E;\u6A85uo\u803B\xAB\u40ABr\u0400;bfhlpst\u0899\u24DE\u24E6\u24E9\u24EB\u24EE\u24F1\u24F5\u0100;f\u089D\u24E3s;\u691Fs;\u691D\xEB\u2252p;\u61ABl;\u6939im;\u6973l;\u61A2\u0180;ae\u24FF\u2500\u2504\u6AABil;\u6919\u0100;s\u2509\u250A\u6AAD;\uC000\u2AAD\uFE00\u0180abr\u2515\u2519\u251Drr;\u690Crk;\u6772\u0100ak\u2522\u252Cc\u0100ek\u2528\u252A;\u407B;\u405B\u0100es\u2531\u2533;\u698Bl\u0100du\u2539\u253B;\u698F;\u698D\u0200aeuy\u2546\u254B\u2556\u2558ron;\u413E\u0100di\u2550\u2554il;\u413C\xEC\u08B0\xE2\u2529;\u443B\u0200cqrs\u2563\u2566\u256D\u257Da;\u6936uo\u0100;r\u0E19\u1746\u0100du\u2572\u2577har;\u6967shar;\u694Bh;\u61B2\u0280;fgqs\u258B\u258C\u0989\u25F3\u25FF\u6264t\u0280ahlrt\u2598\u25A4\u25B7\u25C2\u25E8rrow\u0100;t\u0899\u25A1a\xE9\u24F6arpoon\u0100du\u25AF\u25B4own\xBB\u045Ap\xBB\u0966eftarrows;\u61C7ight\u0180ahs\u25CD\u25D6\u25DErrow\u0100;s\u08F4\u08A7arpoon\xF3\u0F98quigarro\xF7\u21F0hreetimes;\u62CB\u0180;qs\u258B\u0993\u25FAlan\xF4\u09AC\u0280;cdgs\u09AC\u260A\u260D\u261D\u2628c;\u6AA8ot\u0100;o\u2614\u2615\u6A7F\u0100;r\u261A\u261B\u6A81;\u6A83\u0100;e\u2622\u2625\uC000\u22DA\uFE00s;\u6A93\u0280adegs\u2633\u2639\u263D\u2649\u264Bppro\xF8\u24C6ot;\u62D6q\u0100gq\u2643\u2645\xF4\u0989gt\xF2\u248C\xF4\u099Bi\xED\u09B2\u0180ilr\u2655\u08E1\u265Asht;\u697C;\uC000\u{1D529}\u0100;E\u099C\u2663;\u6A91\u0161\u2669\u2676r\u0100du\u25B2\u266E\u0100;l\u0965\u2673;\u696Alk;\u6584cy;\u4459\u0280;acht\u0A48\u2688\u268B\u2691\u2696r\xF2\u25C1orne\xF2\u1D08ard;\u696Bri;\u65FA\u0100io\u269F\u26A4dot;\u4140ust\u0100;a\u26AC\u26AD\u63B0che\xBB\u26AD\u0200Eaes\u26BB\u26BD\u26C9\u26D4;\u6268p\u0100;p\u26C3\u26C4\u6A89rox\xBB\u26C4\u0100;q\u26CE\u26CF\u6A87\u0100;q\u26CE\u26BBim;\u62E6\u0400abnoptwz\u26E9\u26F4\u26F7\u271A\u272F\u2741\u2747\u2750\u0100nr\u26EE\u26F1g;\u67ECr;\u61FDr\xEB\u08C1g\u0180lmr\u26FF\u270D\u2714eft\u0100ar\u09E6\u2707ight\xE1\u09F2apsto;\u67FCight\xE1\u09FDparrow\u0100lr\u2725\u2729ef\xF4\u24EDight;\u61AC\u0180afl\u2736\u2739\u273Dr;\u6985;\uC000\u{1D55D}us;\u6A2Dimes;\u6A34\u0161\u274B\u274Fst;\u6217\xE1\u134E\u0180;ef\u2757\u2758\u1800\u65CAnge\xBB\u2758ar\u0100;l\u2764\u2765\u4028t;\u6993\u0280achmt\u2773\u2776\u277C\u2785\u2787r\xF2\u08A8orne\xF2\u1D8Car\u0100;d\u0F98\u2783;\u696D;\u600Eri;\u62BF\u0300achiqt\u2798\u279D\u0A40\u27A2\u27AE\u27BBquo;\u6039r;\uC000\u{1D4C1}m\u0180;eg\u09B2\u27AA\u27AC;\u6A8D;\u6A8F\u0100bu\u252A\u27B3o\u0100;r\u0E1F\u27B9;\u601Arok;\u4142\u8400<;cdhilqr\u082B\u27D2\u2639\u27DC\u27E0\u27E5\u27EA\u27F0\u0100ci\u27D7\u27D9;\u6AA6r;\u6A79re\xE5\u25F2mes;\u62C9arr;\u6976uest;\u6A7B\u0100Pi\u27F5\u27F9ar;\u6996\u0180;ef\u2800\u092D\u181B\u65C3r\u0100du\u2807\u280Dshar;\u694Ahar;\u6966\u0100en\u2817\u2821rtneqq;\uC000\u2268\uFE00\xC5\u281E\u0700Dacdefhilnopsu\u2840\u2845\u2882\u288E\u2893\u28A0\u28A5\u28A8\u28DA\u28E2\u28E4\u0A83\u28F3\u2902Dot;\u623A\u0200clpr\u284E\u2852\u2863\u287Dr\u803B\xAF\u40AF\u0100et\u2857\u2859;\u6642\u0100;e\u285E\u285F\u6720se\xBB\u285F\u0100;s\u103B\u2868to\u0200;dlu\u103B\u2873\u2877\u287Bow\xEE\u048Cef\xF4\u090F\xF0\u13D1ker;\u65AE\u0100oy\u2887\u288Cmma;\u6A29;\u443Cash;\u6014asuredangle\xBB\u1626r;\uC000\u{1D52A}o;\u6127\u0180cdn\u28AF\u28B4\u28C9ro\u803B\xB5\u40B5\u0200;acd\u1464\u28BD\u28C0\u28C4s\xF4\u16A7ir;\u6AF0ot\u80BB\xB7\u01B5us\u0180;bd\u28D2\u1903\u28D3\u6212\u0100;u\u1D3C\u28D8;\u6A2A\u0163\u28DE\u28E1p;\u6ADB\xF2\u2212\xF0\u0A81\u0100dp\u28E9\u28EEels;\u62A7f;\uC000\u{1D55E}\u0100ct\u28F8\u28FDr;\uC000\u{1D4C2}pos\xBB\u159D\u0180;lm\u2909\u290A\u290D\u43BCtimap;\u62B8\u0C00GLRVabcdefghijlmoprstuvw\u2942\u2953\u297E\u2989\u2998\u29DA\u29E9\u2A15\u2A1A\u2A58\u2A5D\u2A83\u2A95\u2AA4\u2AA8\u2B04\u2B07\u2B44\u2B7F\u2BAE\u2C34\u2C67\u2C7C\u2CE9\u0100gt\u2947\u294B;\uC000\u22D9\u0338\u0100;v\u2950\u0BCF\uC000\u226B\u20D2\u0180elt\u295A\u2972\u2976ft\u0100ar\u2961\u2967rrow;\u61CDightarrow;\u61CE;\uC000\u22D8\u0338\u0100;v\u297B\u0C47\uC000\u226A\u20D2ightarrow;\u61CF\u0100Dd\u298E\u2993ash;\u62AFash;\u62AE\u0280bcnpt\u29A3\u29A7\u29AC\u29B1\u29CCla\xBB\u02DEute;\u4144g;\uC000\u2220\u20D2\u0280;Eiop\u0D84\u29BC\u29C0\u29C5\u29C8;\uC000\u2A70\u0338d;\uC000\u224B\u0338s;\u4149ro\xF8\u0D84ur\u0100;a\u29D3\u29D4\u666El\u0100;s\u29D3\u0B38\u01F3\u29DF\0\u29E3p\u80BB\xA0\u0B37mp\u0100;e\u0BF9\u0C00\u0280aeouy\u29F4\u29FE\u2A03\u2A10\u2A13\u01F0\u29F9\0\u29FB;\u6A43on;\u4148dil;\u4146ng\u0100;d\u0D7E\u2A0Aot;\uC000\u2A6D\u0338p;\u6A42;\u443Dash;\u6013\u0380;Aadqsx\u0B92\u2A29\u2A2D\u2A3B\u2A41\u2A45\u2A50rr;\u61D7r\u0100hr\u2A33\u2A36k;\u6924\u0100;o\u13F2\u13F0ot;\uC000\u2250\u0338ui\xF6\u0B63\u0100ei\u2A4A\u2A4Ear;\u6928\xED\u0B98ist\u0100;s\u0BA0\u0B9Fr;\uC000\u{1D52B}\u0200Eest\u0BC5\u2A66\u2A79\u2A7C\u0180;qs\u0BBC\u2A6D\u0BE1\u0180;qs\u0BBC\u0BC5\u2A74lan\xF4\u0BE2i\xED\u0BEA\u0100;r\u0BB6\u2A81\xBB\u0BB7\u0180Aap\u2A8A\u2A8D\u2A91r\xF2\u2971rr;\u61AEar;\u6AF2\u0180;sv\u0F8D\u2A9C\u0F8C\u0100;d\u2AA1\u2AA2\u62FC;\u62FAcy;\u445A\u0380AEadest\u2AB7\u2ABA\u2ABE\u2AC2\u2AC5\u2AF6\u2AF9r\xF2\u2966;\uC000\u2266\u0338rr;\u619Ar;\u6025\u0200;fqs\u0C3B\u2ACE\u2AE3\u2AEFt\u0100ar\u2AD4\u2AD9rro\xF7\u2AC1ightarro\xF7\u2A90\u0180;qs\u0C3B\u2ABA\u2AEAlan\xF4\u0C55\u0100;s\u0C55\u2AF4\xBB\u0C36i\xED\u0C5D\u0100;r\u0C35\u2AFEi\u0100;e\u0C1A\u0C25i\xE4\u0D90\u0100pt\u2B0C\u2B11f;\uC000\u{1D55F}\u8180\xAC;in\u2B19\u2B1A\u2B36\u40ACn\u0200;Edv\u0B89\u2B24\u2B28\u2B2E;\uC000\u22F9\u0338ot;\uC000\u22F5\u0338\u01E1\u0B89\u2B33\u2B35;\u62F7;\u62F6i\u0100;v\u0CB8\u2B3C\u01E1\u0CB8\u2B41\u2B43;\u62FE;\u62FD\u0180aor\u2B4B\u2B63\u2B69r\u0200;ast\u0B7B\u2B55\u2B5A\u2B5Flle\xEC\u0B7Bl;\uC000\u2AFD\u20E5;\uC000\u2202\u0338lint;\u6A14\u0180;ce\u0C92\u2B70\u2B73u\xE5\u0CA5\u0100;c\u0C98\u2B78\u0100;e\u0C92\u2B7D\xF1\u0C98\u0200Aait\u2B88\u2B8B\u2B9D\u2BA7r\xF2\u2988rr\u0180;cw\u2B94\u2B95\u2B99\u619B;\uC000\u2933\u0338;\uC000\u219D\u0338ghtarrow\xBB\u2B95ri\u0100;e\u0CCB\u0CD6\u0380chimpqu\u2BBD\u2BCD\u2BD9\u2B04\u0B78\u2BE4\u2BEF\u0200;cer\u0D32\u2BC6\u0D37\u2BC9u\xE5\u0D45;\uC000\u{1D4C3}ort\u026D\u2B05\0\0\u2BD6ar\xE1\u2B56m\u0100;e\u0D6E\u2BDF\u0100;q\u0D74\u0D73su\u0100bp\u2BEB\u2BED\xE5\u0CF8\xE5\u0D0B\u0180bcp\u2BF6\u2C11\u2C19\u0200;Ees\u2BFF\u2C00\u0D22\u2C04\u6284;\uC000\u2AC5\u0338et\u0100;e\u0D1B\u2C0Bq\u0100;q\u0D23\u2C00c\u0100;e\u0D32\u2C17\xF1\u0D38\u0200;Ees\u2C22\u2C23\u0D5F\u2C27\u6285;\uC000\u2AC6\u0338et\u0100;e\u0D58\u2C2Eq\u0100;q\u0D60\u2C23\u0200gilr\u2C3D\u2C3F\u2C45\u2C47\xEC\u0BD7lde\u803B\xF1\u40F1\xE7\u0C43iangle\u0100lr\u2C52\u2C5Ceft\u0100;e\u0C1A\u2C5A\xF1\u0C26ight\u0100;e\u0CCB\u2C65\xF1\u0CD7\u0100;m\u2C6C\u2C6D\u43BD\u0180;es\u2C74\u2C75\u2C79\u4023ro;\u6116p;\u6007\u0480DHadgilrs\u2C8F\u2C94\u2C99\u2C9E\u2CA3\u2CB0\u2CB6\u2CD3\u2CE3ash;\u62ADarr;\u6904p;\uC000\u224D\u20D2ash;\u62AC\u0100et\u2CA8\u2CAC;\uC000\u2265\u20D2;\uC000>\u20D2nfin;\u69DE\u0180Aet\u2CBD\u2CC1\u2CC5rr;\u6902;\uC000\u2264\u20D2\u0100;r\u2CCA\u2CCD\uC000<\u20D2ie;\uC000\u22B4\u20D2\u0100At\u2CD8\u2CDCrr;\u6903rie;\uC000\u22B5\u20D2im;\uC000\u223C\u20D2\u0180Aan\u2CF0\u2CF4\u2D02rr;\u61D6r\u0100hr\u2CFA\u2CFDk;\u6923\u0100;o\u13E7\u13E5ear;\u6927\u1253\u1A95\0\0\0\0\0\0\0\0\0\0\0\0\0\u2D2D\0\u2D38\u2D48\u2D60\u2D65\u2D72\u2D84\u1B07\0\0\u2D8D\u2DAB\0\u2DC8\u2DCE\0\u2DDC\u2E19\u2E2B\u2E3E\u2E43\u0100cs\u2D31\u1A97ute\u803B\xF3\u40F3\u0100iy\u2D3C\u2D45r\u0100;c\u1A9E\u2D42\u803B\xF4\u40F4;\u443E\u0280abios\u1AA0\u2D52\u2D57\u01C8\u2D5Alac;\u4151v;\u6A38old;\u69BClig;\u4153\u0100cr\u2D69\u2D6Dir;\u69BF;\uC000\u{1D52C}\u036F\u2D79\0\0\u2D7C\0\u2D82n;\u42DBave\u803B\xF2\u40F2;\u69C1\u0100bm\u2D88\u0DF4ar;\u69B5\u0200acit\u2D95\u2D98\u2DA5\u2DA8r\xF2\u1A80\u0100ir\u2D9D\u2DA0r;\u69BEoss;\u69BBn\xE5\u0E52;\u69C0\u0180aei\u2DB1\u2DB5\u2DB9cr;\u414Dga;\u43C9\u0180cdn\u2DC0\u2DC5\u01CDron;\u43BF;\u69B6pf;\uC000\u{1D560}\u0180ael\u2DD4\u2DD7\u01D2r;\u69B7rp;\u69B9\u0380;adiosv\u2DEA\u2DEB\u2DEE\u2E08\u2E0D\u2E10\u2E16\u6228r\xF2\u1A86\u0200;efm\u2DF7\u2DF8\u2E02\u2E05\u6A5Dr\u0100;o\u2DFE\u2DFF\u6134f\xBB\u2DFF\u803B\xAA\u40AA\u803B\xBA\u40BAgof;\u62B6r;\u6A56lope;\u6A57;\u6A5B\u0180clo\u2E1F\u2E21\u2E27\xF2\u2E01ash\u803B\xF8\u40F8l;\u6298i\u016C\u2E2F\u2E34de\u803B\xF5\u40F5es\u0100;a\u01DB\u2E3As;\u6A36ml\u803B\xF6\u40F6bar;\u633D\u0AE1\u2E5E\0\u2E7D\0\u2E80\u2E9D\0\u2EA2\u2EB9\0\0\u2ECB\u0E9C\0\u2F13\0\0\u2F2B\u2FBC\0\u2FC8r\u0200;ast\u0403\u2E67\u2E72\u0E85\u8100\xB6;l\u2E6D\u2E6E\u40B6le\xEC\u0403\u0269\u2E78\0\0\u2E7Bm;\u6AF3;\u6AFDy;\u443Fr\u0280cimpt\u2E8B\u2E8F\u2E93\u1865\u2E97nt;\u4025od;\u402Eil;\u6030enk;\u6031r;\uC000\u{1D52D}\u0180imo\u2EA8\u2EB0\u2EB4\u0100;v\u2EAD\u2EAE\u43C6;\u43D5ma\xF4\u0A76ne;\u660E\u0180;tv\u2EBF\u2EC0\u2EC8\u43C0chfork\xBB\u1FFD;\u43D6\u0100au\u2ECF\u2EDFn\u0100ck\u2ED5\u2EDDk\u0100;h\u21F4\u2EDB;\u610E\xF6\u21F4s\u0480;abcdemst\u2EF3\u2EF4\u1908\u2EF9\u2EFD\u2F04\u2F06\u2F0A\u2F0E\u402Bcir;\u6A23ir;\u6A22\u0100ou\u1D40\u2F02;\u6A25;\u6A72n\u80BB\xB1\u0E9Dim;\u6A26wo;\u6A27\u0180ipu\u2F19\u2F20\u2F25ntint;\u6A15f;\uC000\u{1D561}nd\u803B\xA3\u40A3\u0500;Eaceinosu\u0EC8\u2F3F\u2F41\u2F44\u2F47\u2F81\u2F89\u2F92\u2F7E\u2FB6;\u6AB3p;\u6AB7u\xE5\u0ED9\u0100;c\u0ECE\u2F4C\u0300;acens\u0EC8\u2F59\u2F5F\u2F66\u2F68\u2F7Eppro\xF8\u2F43urlye\xF1\u0ED9\xF1\u0ECE\u0180aes\u2F6F\u2F76\u2F7Approx;\u6AB9qq;\u6AB5im;\u62E8i\xED\u0EDFme\u0100;s\u2F88\u0EAE\u6032\u0180Eas\u2F78\u2F90\u2F7A\xF0\u2F75\u0180dfp\u0EEC\u2F99\u2FAF\u0180als\u2FA0\u2FA5\u2FAAlar;\u632Eine;\u6312urf;\u6313\u0100;t\u0EFB\u2FB4\xEF\u0EFBrel;\u62B0\u0100ci\u2FC0\u2FC5r;\uC000\u{1D4C5};\u43C8ncsp;\u6008\u0300fiopsu\u2FDA\u22E2\u2FDF\u2FE5\u2FEB\u2FF1r;\uC000\u{1D52E}pf;\uC000\u{1D562}rime;\u6057cr;\uC000\u{1D4C6}\u0180aeo\u2FF8\u3009\u3013t\u0100ei\u2FFE\u3005rnion\xF3\u06B0nt;\u6A16st\u0100;e\u3010\u3011\u403F\xF1\u1F19\xF4\u0F14\u0A80ABHabcdefhilmnoprstux\u3040\u3051\u3055\u3059\u30E0\u310E\u312B\u3147\u3162\u3172\u318E\u3206\u3215\u3224\u3229\u3258\u326E\u3272\u3290\u32B0\u32B7\u0180art\u3047\u304A\u304Cr\xF2\u10B3\xF2\u03DDail;\u691Car\xF2\u1C65ar;\u6964\u0380cdenqrt\u3068\u3075\u3078\u307F\u308F\u3094\u30CC\u0100eu\u306D\u3071;\uC000\u223D\u0331te;\u4155i\xE3\u116Emptyv;\u69B3g\u0200;del\u0FD1\u3089\u308B\u308D;\u6992;\u69A5\xE5\u0FD1uo\u803B\xBB\u40BBr\u0580;abcfhlpstw\u0FDC\u30AC\u30AF\u30B7\u30B9\u30BC\u30BE\u30C0\u30C3\u30C7\u30CAp;\u6975\u0100;f\u0FE0\u30B4s;\u6920;\u6933s;\u691E\xEB\u225D\xF0\u272El;\u6945im;\u6974l;\u61A3;\u619D\u0100ai\u30D1\u30D5il;\u691Ao\u0100;n\u30DB\u30DC\u6236al\xF3\u0F1E\u0180abr\u30E7\u30EA\u30EEr\xF2\u17E5rk;\u6773\u0100ak\u30F3\u30FDc\u0100ek\u30F9\u30FB;\u407D;\u405D\u0100es\u3102\u3104;\u698Cl\u0100du\u310A\u310C;\u698E;\u6990\u0200aeuy\u3117\u311C\u3127\u3129ron;\u4159\u0100di\u3121\u3125il;\u4157\xEC\u0FF2\xE2\u30FA;\u4440\u0200clqs\u3134\u3137\u313D\u3144a;\u6937dhar;\u6969uo\u0100;r\u020E\u020Dh;\u61B3\u0180acg\u314E\u315F\u0F44l\u0200;ips\u0F78\u3158\u315B\u109Cn\xE5\u10BBar\xF4\u0FA9t;\u65AD\u0180ilr\u3169\u1023\u316Esht;\u697D;\uC000\u{1D52F}\u0100ao\u3177\u3186r\u0100du\u317D\u317F\xBB\u047B\u0100;l\u1091\u3184;\u696C\u0100;v\u318B\u318C\u43C1;\u43F1\u0180gns\u3195\u31F9\u31FCht\u0300ahlrst\u31A4\u31B0\u31C2\u31D8\u31E4\u31EErrow\u0100;t\u0FDC\u31ADa\xE9\u30C8arpoon\u0100du\u31BB\u31BFow\xEE\u317Ep\xBB\u1092eft\u0100ah\u31CA\u31D0rrow\xF3\u0FEAarpoon\xF3\u0551ightarrows;\u61C9quigarro\xF7\u30CBhreetimes;\u62CCg;\u42DAingdotse\xF1\u1F32\u0180ahm\u320D\u3210\u3213r\xF2\u0FEAa\xF2\u0551;\u600Foust\u0100;a\u321E\u321F\u63B1che\xBB\u321Fmid;\u6AEE\u0200abpt\u3232\u323D\u3240\u3252\u0100nr\u3237\u323Ag;\u67EDr;\u61FEr\xEB\u1003\u0180afl\u3247\u324A\u324Er;\u6986;\uC000\u{1D563}us;\u6A2Eimes;\u6A35\u0100ap\u325D\u3267r\u0100;g\u3263\u3264\u4029t;\u6994olint;\u6A12ar\xF2\u31E3\u0200achq\u327B\u3280\u10BC\u3285quo;\u603Ar;\uC000\u{1D4C7}\u0100bu\u30FB\u328Ao\u0100;r\u0214\u0213\u0180hir\u3297\u329B\u32A0re\xE5\u31F8mes;\u62CAi\u0200;efl\u32AA\u1059\u1821\u32AB\u65B9tri;\u69CEluhar;\u6968;\u611E\u0D61\u32D5\u32DB\u32DF\u332C\u3338\u3371\0\u337A\u33A4\0\0\u33EC\u33F0\0\u3428\u3448\u345A\u34AD\u34B1\u34CA\u34F1\0\u3616\0\0\u3633cute;\u415Bqu\xEF\u27BA\u0500;Eaceinpsy\u11ED\u32F3\u32F5\u32FF\u3302\u330B\u330F\u331F\u3326\u3329;\u6AB4\u01F0\u32FA\0\u32FC;\u6AB8on;\u4161u\xE5\u11FE\u0100;d\u11F3\u3307il;\u415Frc;\u415D\u0180Eas\u3316\u3318\u331B;\u6AB6p;\u6ABAim;\u62E9olint;\u6A13i\xED\u1204;\u4441ot\u0180;be\u3334\u1D47\u3335\u62C5;\u6A66\u0380Aacmstx\u3346\u334A\u3357\u335B\u335E\u3363\u336Drr;\u61D8r\u0100hr\u3350\u3352\xEB\u2228\u0100;o\u0A36\u0A34t\u803B\xA7\u40A7i;\u403Bwar;\u6929m\u0100in\u3369\xF0nu\xF3\xF1t;\u6736r\u0100;o\u3376\u2055\uC000\u{1D530}\u0200acoy\u3382\u3386\u3391\u33A0rp;\u666F\u0100hy\u338B\u338Fcy;\u4449;\u4448rt\u026D\u3399\0\0\u339Ci\xE4\u1464ara\xEC\u2E6F\u803B\xAD\u40AD\u0100gm\u33A8\u33B4ma\u0180;fv\u33B1\u33B2\u33B2\u43C3;\u43C2\u0400;deglnpr\u12AB\u33C5\u33C9\u33CE\u33D6\u33DE\u33E1\u33E6ot;\u6A6A\u0100;q\u12B1\u12B0\u0100;E\u33D3\u33D4\u6A9E;\u6AA0\u0100;E\u33DB\u33DC\u6A9D;\u6A9Fe;\u6246lus;\u6A24arr;\u6972ar\xF2\u113D\u0200aeit\u33F8\u3408\u340F\u3417\u0100ls\u33FD\u3404lsetm\xE9\u336Ahp;\u6A33parsl;\u69E4\u0100dl\u1463\u3414e;\u6323\u0100;e\u341C\u341D\u6AAA\u0100;s\u3422\u3423\u6AAC;\uC000\u2AAC\uFE00\u0180flp\u342E\u3433\u3442tcy;\u444C\u0100;b\u3438\u3439\u402F\u0100;a\u343E\u343F\u69C4r;\u633Ff;\uC000\u{1D564}a\u0100dr\u344D\u0402es\u0100;u\u3454\u3455\u6660it\xBB\u3455\u0180csu\u3460\u3479\u349F\u0100au\u3465\u346Fp\u0100;s\u1188\u346B;\uC000\u2293\uFE00p\u0100;s\u11B4\u3475;\uC000\u2294\uFE00u\u0100bp\u347F\u348F\u0180;es\u1197\u119C\u3486et\u0100;e\u1197\u348D\xF1\u119D\u0180;es\u11A8\u11AD\u3496et\u0100;e\u11A8\u349D\xF1\u11AE\u0180;af\u117B\u34A6\u05B0r\u0165\u34AB\u05B1\xBB\u117Car\xF2\u1148\u0200cemt\u34B9\u34BE\u34C2\u34C5r;\uC000\u{1D4C8}tm\xEE\xF1i\xEC\u3415ar\xE6\u11BE\u0100ar\u34CE\u34D5r\u0100;f\u34D4\u17BF\u6606\u0100an\u34DA\u34EDight\u0100ep\u34E3\u34EApsilo\xEE\u1EE0h\xE9\u2EAFs\xBB\u2852\u0280bcmnp\u34FB\u355E\u1209\u358B\u358E\u0480;Edemnprs\u350E\u350F\u3511\u3515\u351E\u3523\u352C\u3531\u3536\u6282;\u6AC5ot;\u6ABD\u0100;d\u11DA\u351Aot;\u6AC3ult;\u6AC1\u0100Ee\u3528\u352A;\u6ACB;\u628Alus;\u6ABFarr;\u6979\u0180eiu\u353D\u3552\u3555t\u0180;en\u350E\u3545\u354Bq\u0100;q\u11DA\u350Feq\u0100;q\u352B\u3528m;\u6AC7\u0100bp\u355A\u355C;\u6AD5;\u6AD3c\u0300;acens\u11ED\u356C\u3572\u3579\u357B\u3326ppro\xF8\u32FAurlye\xF1\u11FE\xF1\u11F3\u0180aes\u3582\u3588\u331Bppro\xF8\u331Aq\xF1\u3317g;\u666A\u0680123;Edehlmnps\u35A9\u35AC\u35AF\u121C\u35B2\u35B4\u35C0\u35C9\u35D5\u35DA\u35DF\u35E8\u35ED\u803B\xB9\u40B9\u803B\xB2\u40B2\u803B\xB3\u40B3;\u6AC6\u0100os\u35B9\u35BCt;\u6ABEub;\u6AD8\u0100;d\u1222\u35C5ot;\u6AC4s\u0100ou\u35CF\u35D2l;\u67C9b;\u6AD7arr;\u697Bult;\u6AC2\u0100Ee\u35E4\u35E6;\u6ACC;\u628Blus;\u6AC0\u0180eiu\u35F4\u3609\u360Ct\u0180;en\u121C\u35FC\u3602q\u0100;q\u1222\u35B2eq\u0100;q\u35E7\u35E4m;\u6AC8\u0100bp\u3611\u3613;\u6AD4;\u6AD6\u0180Aan\u361C\u3620\u362Drr;\u61D9r\u0100hr\u3626\u3628\xEB\u222E\u0100;o\u0A2B\u0A29war;\u692Alig\u803B\xDF\u40DF\u0BE1\u3651\u365D\u3660\u12CE\u3673\u3679\0\u367E\u36C2\0\0\0\0\0\u36DB\u3703\0\u3709\u376C\0\0\0\u3787\u0272\u3656\0\0\u365Bget;\u6316;\u43C4r\xEB\u0E5F\u0180aey\u3666\u366B\u3670ron;\u4165dil;\u4163;\u4442lrec;\u6315r;\uC000\u{1D531}\u0200eiko\u3686\u369D\u36B5\u36BC\u01F2\u368B\0\u3691e\u01004f\u1284\u1281a\u0180;sv\u3698\u3699\u369B\u43B8ym;\u43D1\u0100cn\u36A2\u36B2k\u0100as\u36A8\u36AEppro\xF8\u12C1im\xBB\u12ACs\xF0\u129E\u0100as\u36BA\u36AE\xF0\u12C1rn\u803B\xFE\u40FE\u01EC\u031F\u36C6\u22E7es\u8180\xD7;bd\u36CF\u36D0\u36D8\u40D7\u0100;a\u190F\u36D5r;\u6A31;\u6A30\u0180eps\u36E1\u36E3\u3700\xE1\u2A4D\u0200;bcf\u0486\u36EC\u36F0\u36F4ot;\u6336ir;\u6AF1\u0100;o\u36F9\u36FC\uC000\u{1D565}rk;\u6ADA\xE1\u3362rime;\u6034\u0180aip\u370F\u3712\u3764d\xE5\u1248\u0380adempst\u3721\u374D\u3740\u3751\u3757\u375C\u375Fngle\u0280;dlqr\u3730\u3731\u3736\u3740\u3742\u65B5own\xBB\u1DBBeft\u0100;e\u2800\u373E\xF1\u092E;\u625Cight\u0100;e\u32AA\u374B\xF1\u105Aot;\u65ECinus;\u6A3Alus;\u6A39b;\u69CDime;\u6A3Bezium;\u63E2\u0180cht\u3772\u377D\u3781\u0100ry\u3777\u377B;\uC000\u{1D4C9};\u4446cy;\u445Brok;\u4167\u0100io\u378B\u378Ex\xF4\u1777head\u0100lr\u3797\u37A0eftarro\xF7\u084Fightarrow\xBB\u0F5D\u0900AHabcdfghlmoprstuw\u37D0\u37D3\u37D7\u37E4\u37F0\u37FC\u380E\u381C\u3823\u3834\u3851\u385D\u386B\u38A9\u38CC\u38D2\u38EA\u38F6r\xF2\u03EDar;\u6963\u0100cr\u37DC\u37E2ute\u803B\xFA\u40FA\xF2\u1150r\u01E3\u37EA\0\u37EDy;\u445Eve;\u416D\u0100iy\u37F5\u37FArc\u803B\xFB\u40FB;\u4443\u0180abh\u3803\u3806\u380Br\xF2\u13ADlac;\u4171a\xF2\u13C3\u0100ir\u3813\u3818sht;\u697E;\uC000\u{1D532}rave\u803B\xF9\u40F9\u0161\u3827\u3831r\u0100lr\u382C\u382E\xBB\u0957\xBB\u1083lk;\u6580\u0100ct\u3839\u384D\u026F\u383F\0\0\u384Arn\u0100;e\u3845\u3846\u631Cr\xBB\u3846op;\u630Fri;\u65F8\u0100al\u3856\u385Acr;\u416B\u80BB\xA8\u0349\u0100gp\u3862\u3866on;\u4173f;\uC000\u{1D566}\u0300adhlsu\u114B\u3878\u387D\u1372\u3891\u38A0own\xE1\u13B3arpoon\u0100lr\u3888\u388Cef\xF4\u382Digh\xF4\u382Fi\u0180;hl\u3899\u389A\u389C\u43C5\xBB\u13FAon\xBB\u389Aparrows;\u61C8\u0180cit\u38B0\u38C4\u38C8\u026F\u38B6\0\0\u38C1rn\u0100;e\u38BC\u38BD\u631Dr\xBB\u38BDop;\u630Eng;\u416Fri;\u65F9cr;\uC000\u{1D4CA}\u0180dir\u38D9\u38DD\u38E2ot;\u62F0lde;\u4169i\u0100;f\u3730\u38E8\xBB\u1813\u0100am\u38EF\u38F2r\xF2\u38A8l\u803B\xFC\u40FCangle;\u69A7\u0780ABDacdeflnoprsz\u391C\u391F\u3929\u392D\u39B5\u39B8\u39BD\u39DF\u39E4\u39E8\u39F3\u39F9\u39FD\u3A01\u3A20r\xF2\u03F7ar\u0100;v\u3926\u3927\u6AE8;\u6AE9as\xE8\u03E1\u0100nr\u3932\u3937grt;\u699C\u0380eknprst\u34E3\u3946\u394B\u3952\u395D\u3964\u3996app\xE1\u2415othin\xE7\u1E96\u0180hir\u34EB\u2EC8\u3959op\xF4\u2FB5\u0100;h\u13B7\u3962\xEF\u318D\u0100iu\u3969\u396Dgm\xE1\u33B3\u0100bp\u3972\u3984setneq\u0100;q\u397D\u3980\uC000\u228A\uFE00;\uC000\u2ACB\uFE00setneq\u0100;q\u398F\u3992\uC000\u228B\uFE00;\uC000\u2ACC\uFE00\u0100hr\u399B\u399Fet\xE1\u369Ciangle\u0100lr\u39AA\u39AFeft\xBB\u0925ight\xBB\u1051y;\u4432ash\xBB\u1036\u0180elr\u39C4\u39D2\u39D7\u0180;be\u2DEA\u39CB\u39CFar;\u62BBq;\u625Alip;\u62EE\u0100bt\u39DC\u1468a\xF2\u1469r;\uC000\u{1D533}tr\xE9\u39AEsu\u0100bp\u39EF\u39F1\xBB\u0D1C\xBB\u0D59pf;\uC000\u{1D567}ro\xF0\u0EFBtr\xE9\u39B4\u0100cu\u3A06\u3A0Br;\uC000\u{1D4CB}\u0100bp\u3A10\u3A18n\u0100Ee\u3980\u3A16\xBB\u397En\u0100Ee\u3992\u3A1E\xBB\u3990igzag;\u699A\u0380cefoprs\u3A36\u3A3B\u3A56\u3A5B\u3A54\u3A61\u3A6Airc;\u4175\u0100di\u3A40\u3A51\u0100bg\u3A45\u3A49ar;\u6A5Fe\u0100;q\u15FA\u3A4F;\u6259erp;\u6118r;\uC000\u{1D534}pf;\uC000\u{1D568}\u0100;e\u1479\u3A66at\xE8\u1479cr;\uC000\u{1D4CC}\u0AE3\u178E\u3A87\0\u3A8B\0\u3A90\u3A9B\0\0\u3A9D\u3AA8\u3AAB\u3AAF\0\0\u3AC3\u3ACE\0\u3AD8\u17DC\u17DFtr\xE9\u17D1r;\uC000\u{1D535}\u0100Aa\u3A94\u3A97r\xF2\u03C3r\xF2\u09F6;\u43BE\u0100Aa\u3AA1\u3AA4r\xF2\u03B8r\xF2\u09EBa\xF0\u2713is;\u62FB\u0180dpt\u17A4\u3AB5\u3ABE\u0100fl\u3ABA\u17A9;\uC000\u{1D569}im\xE5\u17B2\u0100Aa\u3AC7\u3ACAr\xF2\u03CEr\xF2\u0A01\u0100cq\u3AD2\u17B8r;\uC000\u{1D4CD}\u0100pt\u17D6\u3ADCr\xE9\u17D4\u0400acefiosu\u3AF0\u3AFD\u3B08\u3B0C\u3B11\u3B15\u3B1B\u3B21c\u0100uy\u3AF6\u3AFBte\u803B\xFD\u40FD;\u444F\u0100iy\u3B02\u3B06rc;\u4177;\u444Bn\u803B\xA5\u40A5r;\uC000\u{1D536}cy;\u4457pf;\uC000\u{1D56A}cr;\uC000\u{1D4CE}\u0100cm\u3B26\u3B29y;\u444El\u803B\xFF\u40FF\u0500acdefhiosw\u3B42\u3B48\u3B54\u3B58\u3B64\u3B69\u3B6D\u3B74\u3B7A\u3B80cute;\u417A\u0100ay\u3B4D\u3B52ron;\u417E;\u4437ot;\u417C\u0100et\u3B5D\u3B61tr\xE6\u155Fa;\u43B6r;\uC000\u{1D537}cy;\u4436grarr;\u61DDpf;\uC000\u{1D56B}cr;\uC000\u{1D4CF}\u0100jn\u3B85\u3B87;\u600Dj;\u600C'.split("").map((t2) => t2.charCodeAt(0))), w = new Uint16Array("\u0200aglq	\x1B\u026D\0\0p;\u4026os;\u4027t;\u403Et;\u403Cuot;\u4022".split("").map((t2) => t2.charCodeAt(0)));
  const v = /* @__PURE__ */ new Map([[0, 65533], [128, 8364], [130, 8218], [131, 402], [132, 8222], [133, 8230], [134, 8224], [135, 8225], [136, 710], [137, 8240], [138, 352], [139, 8249], [140, 338], [142, 381], [145, 8216], [146, 8217], [147, 8220], [148, 8221], [149, 8226], [150, 8211], [151, 8212], [152, 732], [153, 8482], [154, 353], [155, 8250], [156, 339], [158, 382], [159, 376]]), z = null !== (k = String.fromCodePoint) && void 0 !== k ? k : function(t2) {
    let e2 = "";
    return t2 > 65535 && (t2 -= 65536, e2 += String.fromCharCode(t2 >>> 10 & 1023 | 55296), t2 = 56320 | 1023 & t2), e2 += String.fromCharCode(t2), e2;
  };
  var S;
  !(function(t2) {
    t2[t2.NUM = 35] = "NUM", t2[t2.SEMI = 59] = "SEMI", t2[t2.EQUALS = 61] = "EQUALS", t2[t2.ZERO = 48] = "ZERO", t2[t2.NINE = 57] = "NINE", t2[t2.LOWER_A = 97] = "LOWER_A", t2[t2.LOWER_F = 102] = "LOWER_F", t2[t2.LOWER_X = 120] = "LOWER_X", t2[t2.LOWER_Z = 122] = "LOWER_Z", t2[t2.UPPER_A = 65] = "UPPER_A", t2[t2.UPPER_F = 70] = "UPPER_F", t2[t2.UPPER_Z = 90] = "UPPER_Z";
  })(S || (S = {}));
  var q, B, L;
  function I(t2) {
    return t2 >= S.ZERO && t2 <= S.NINE;
  }
  function M(t2) {
    return t2 >= S.UPPER_A && t2 <= S.UPPER_F || t2 >= S.LOWER_A && t2 <= S.LOWER_F;
  }
  function T(t2) {
    return t2 === S.EQUALS || (function(t3) {
      return t3 >= S.UPPER_A && t3 <= S.UPPER_Z || t3 >= S.LOWER_A && t3 <= S.LOWER_Z || I(t3);
    })(t2);
  }
  !(function(t2) {
    t2[t2.VALUE_LENGTH = 49152] = "VALUE_LENGTH", t2[t2.BRANCH_LENGTH = 16256] = "BRANCH_LENGTH", t2[t2.JUMP_TABLE = 127] = "JUMP_TABLE";
  })(q || (q = {})), (function(t2) {
    t2[t2.EntityStart = 0] = "EntityStart", t2[t2.NumericStart = 1] = "NumericStart", t2[t2.NumericDecimal = 2] = "NumericDecimal", t2[t2.NumericHex = 3] = "NumericHex", t2[t2.NamedEntity = 4] = "NamedEntity";
  })(B || (B = {})), (function(t2) {
    t2[t2.Legacy = 0] = "Legacy", t2[t2.Strict = 1] = "Strict", t2[t2.Attribute = 2] = "Attribute";
  })(L || (L = {}));
  class R {
    constructor(t2, e2, r2) {
      this.decodeTree = t2, this.emitCodePoint = e2, this.errors = r2, this.state = B.EntityStart, this.consumed = 1, this.result = 0, this.treeIndex = 0, this.excess = 1, this.decodeMode = L.Strict;
    }
    startEntity(t2) {
      this.decodeMode = t2, this.state = B.EntityStart, this.result = 0, this.treeIndex = 0, this.excess = 1, this.consumed = 1;
    }
    write(t2, e2) {
      switch (this.state) {
        case B.EntityStart:
          return t2.charCodeAt(e2) === S.NUM ? (this.state = B.NumericStart, this.consumed += 1, this.stateNumericStart(t2, e2 + 1)) : (this.state = B.NamedEntity, this.stateNamedEntity(t2, e2));
        case B.NumericStart:
          return this.stateNumericStart(t2, e2);
        case B.NumericDecimal:
          return this.stateNumericDecimal(t2, e2);
        case B.NumericHex:
          return this.stateNumericHex(t2, e2);
        case B.NamedEntity:
          return this.stateNamedEntity(t2, e2);
      }
    }
    stateNumericStart(t2, e2) {
      return e2 >= t2.length ? -1 : (32 | t2.charCodeAt(e2)) === S.LOWER_X ? (this.state = B.NumericHex, this.consumed += 1, this.stateNumericHex(t2, e2 + 1)) : (this.state = B.NumericDecimal, this.stateNumericDecimal(t2, e2));
    }
    addToNumericResult(t2, e2, r2, n2) {
      if (e2 !== r2) {
        const s2 = r2 - e2;
        this.result = this.result * Math.pow(n2, s2) + parseInt(t2.substr(e2, s2), n2), this.consumed += s2;
      }
    }
    stateNumericHex(t2, e2) {
      const r2 = e2;
      for (; e2 < t2.length; ) {
        const n2 = t2.charCodeAt(e2);
        if (!I(n2) && !M(n2)) return this.addToNumericResult(t2, r2, e2, 16), this.emitNumericEntity(n2, 3);
        e2 += 1;
      }
      return this.addToNumericResult(t2, r2, e2, 16), -1;
    }
    stateNumericDecimal(t2, e2) {
      const r2 = e2;
      for (; e2 < t2.length; ) {
        const n2 = t2.charCodeAt(e2);
        if (!I(n2)) return this.addToNumericResult(t2, r2, e2, 10), this.emitNumericEntity(n2, 2);
        e2 += 1;
      }
      return this.addToNumericResult(t2, r2, e2, 10), -1;
    }
    emitNumericEntity(t2, e2) {
      var r2;
      if (this.consumed <= e2) return null === (r2 = this.errors) || void 0 === r2 || r2.absenceOfDigitsInNumericCharacterReference(this.consumed), 0;
      if (t2 === S.SEMI) this.consumed += 1;
      else if (this.decodeMode === L.Strict) return 0;
      return this.emitCodePoint((function(t3) {
        var e3;
        return t3 >= 55296 && t3 <= 57343 || t3 > 1114111 ? 65533 : null !== (e3 = v.get(t3)) && void 0 !== e3 ? e3 : t3;
      })(this.result), this.consumed), this.errors && (t2 !== S.SEMI && this.errors.missingSemicolonAfterCharacterReference(), this.errors.validateNumericCharacterReference(this.result)), this.consumed;
    }
    stateNamedEntity(t2, e2) {
      const { decodeTree: r2 } = this;
      let n2 = r2[this.treeIndex], s2 = (n2 & q.VALUE_LENGTH) >> 14;
      for (; e2 < t2.length; e2++, this.excess++) {
        const i2 = t2.charCodeAt(e2);
        if (this.treeIndex = P(r2, n2, this.treeIndex + Math.max(1, s2), i2), this.treeIndex < 0) return 0 === this.result || this.decodeMode === L.Attribute && (0 === s2 || T(i2)) ? 0 : this.emitNotTerminatedNamedEntity();
        if (n2 = r2[this.treeIndex], s2 = (n2 & q.VALUE_LENGTH) >> 14, 0 !== s2) {
          if (i2 === S.SEMI) return this.emitNamedEntityData(this.treeIndex, s2, this.consumed + this.excess);
          this.decodeMode !== L.Strict && (this.result = this.treeIndex, this.consumed += this.excess, this.excess = 0);
        }
      }
      return -1;
    }
    emitNotTerminatedNamedEntity() {
      var t2;
      const { result: e2, decodeTree: r2 } = this, n2 = (r2[e2] & q.VALUE_LENGTH) >> 14;
      return this.emitNamedEntityData(e2, n2, this.consumed), null === (t2 = this.errors) || void 0 === t2 || t2.missingSemicolonAfterCharacterReference(), this.consumed;
    }
    emitNamedEntityData(t2, e2, r2) {
      const { decodeTree: n2 } = this;
      return this.emitCodePoint(1 === e2 ? n2[t2] & ~q.VALUE_LENGTH : n2[t2 + 1], r2), 3 === e2 && this.emitCodePoint(n2[t2 + 2], r2), r2;
    }
    end() {
      var t2;
      switch (this.state) {
        case B.NamedEntity:
          return 0 === this.result || this.decodeMode === L.Attribute && this.result !== this.treeIndex ? 0 : this.emitNotTerminatedNamedEntity();
        case B.NumericDecimal:
          return this.emitNumericEntity(0, 2);
        case B.NumericHex:
          return this.emitNumericEntity(0, 3);
        case B.NumericStart:
          return null === (t2 = this.errors) || void 0 === t2 || t2.absenceOfDigitsInNumericCharacterReference(this.consumed), 0;
        case B.EntityStart:
          return 0;
      }
    }
  }
  function N(t2) {
    let e2 = "";
    const r2 = new R(t2, (t3) => e2 += z(t3));
    return function(t3, n2) {
      let s2 = 0, i2 = 0;
      for (; (i2 = t3.indexOf("&", i2)) >= 0; ) {
        e2 += t3.slice(s2, i2), r2.startEntity(n2);
        const o3 = r2.write(t3, i2 + 1);
        if (o3 < 0) {
          s2 = i2 + r2.end();
          break;
        }
        s2 = i2 + o3, i2 = 0 === o3 ? s2 + 1 : s2;
      }
      const o2 = e2 + t3.slice(s2);
      return e2 = "", o2;
    };
  }
  function P(t2, e2, r2, n2) {
    const s2 = (e2 & q.BRANCH_LENGTH) >> 7, i2 = e2 & q.JUMP_TABLE;
    if (0 === s2) return 0 !== i2 && n2 === i2 ? r2 : -1;
    if (i2) {
      const e3 = n2 - i2;
      return e3 < 0 || e3 >= s2 ? -1 : t2[r2 + e3] - 1;
    }
    let o2 = r2, u2 = o2 + s2 - 1;
    for (; o2 <= u2; ) {
      const e3 = o2 + u2 >>> 1, r3 = t2[e3];
      if (r3 < n2) o2 = e3 + 1;
      else {
        if (!(r3 > n2)) return t2[e3 + s2];
        u2 = e3 - 1;
      }
    }
    return -1;
  }
  const O = N(x);
  function j(t2) {
    return "[object String]" === (function(t3) {
      return Object.prototype.toString.call(t3);
    })(t2);
  }
  N(w);
  const Z = Object.prototype.hasOwnProperty;
  function $(t2) {
    return Array.prototype.slice.call(arguments, 1).forEach(function(e2) {
      if (e2) {
        if ("object" != typeof e2) throw new TypeError(e2 + "must be object");
        Object.keys(e2).forEach(function(r2) {
          t2[r2] = e2[r2];
        });
      }
    }), t2;
  }
  function U(t2, e2, r2) {
    return [].concat(t2.slice(0, e2), r2, t2.slice(e2 + 1));
  }
  function H(t2) {
    return !(t2 >= 55296 && t2 <= 57343) && (!(t2 >= 64976 && t2 <= 65007) && (!!(65535 & ~t2 && 65534 != (65535 & t2)) && (!(t2 >= 0 && t2 <= 8) && (11 !== t2 && (!(t2 >= 14 && t2 <= 31) && (!(t2 >= 127 && t2 <= 159) && !(t2 > 1114111)))))));
  }
  function V(t2) {
    if (t2 > 65535) {
      const e2 = 55296 + ((t2 -= 65536) >> 10), r2 = 56320 + (1023 & t2);
      return String.fromCharCode(e2, r2);
    }
    return String.fromCharCode(t2);
  }
  const G = /\\([!"#$%&'()*+,\-./:;<=>?@[\\\]^_`{|}~])/g, W = new RegExp(G.source + "|" + /&([a-z#][a-z0-9]{1,31});/gi.source, "gi"), J = /^#((?:x[a-f0-9]{1,8}|[0-9]{1,8}))$/i;
  function Q(t2, e2) {
    if (35 === e2.charCodeAt(0) && J.test(e2)) {
      const r3 = "x" === e2[1].toLowerCase() ? parseInt(e2.slice(2), 16) : parseInt(e2.slice(1), 10);
      return H(r3) ? V(r3) : t2;
    }
    const r2 = (function(t3, e3 = L.Legacy) {
      return O(t3, e3);
    })(t2);
    return r2 !== t2 ? r2 : t2;
  }
  function X(t2) {
    return t2.indexOf("\\") < 0 && t2.indexOf("&") < 0 ? t2 : t2.replace(W, function(t3, e2, r2) {
      return e2 || Q(t3, r2);
    });
  }
  const Y = /[&<>"]/, K = /[&<>"]/g, tt = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" };
  function et(t2) {
    return tt[t2];
  }
  function rt(t2) {
    return Y.test(t2) ? t2.replace(K, et) : t2;
  }
  const nt = /[.?*+^$[\]\\(){}|-]/g;
  function st(t2) {
    switch (t2) {
      case 9:
      case 32:
        return true;
    }
    return false;
  }
  function it(t2) {
    if (t2 >= 8192 && t2 <= 8202) return true;
    switch (t2) {
      case 9:
      case 10:
      case 11:
      case 12:
      case 13:
      case 32:
      case 160:
      case 5760:
      case 8239:
      case 8287:
      case 12288:
        return true;
    }
    return false;
  }
  function ot(t2) {
    return E.test(t2) || A.test(t2);
  }
  function ut(t2) {
    return ot(V(t2));
  }
  function ct(t2) {
    switch (t2) {
      case 33:
      case 34:
      case 35:
      case 36:
      case 37:
      case 38:
      case 39:
      case 40:
      case 41:
      case 42:
      case 43:
      case 44:
      case 45:
      case 46:
      case 47:
      case 58:
      case 59:
      case 60:
      case 61:
      case 62:
      case 63:
      case 64:
      case 91:
      case 92:
      case 93:
      case 94:
      case 95:
      case 96:
      case 123:
      case 124:
      case 125:
      case 126:
        return true;
      default:
        return false;
    }
  }
  function at(t2) {
    return t2 = t2.trim().replace(/\s+/g, " "), "\u1E7E" === "\u1E9E".toLowerCase() && (t2 = t2.replace(/\u1e9e/g, "\xDF")), t2.toLowerCase().toUpperCase();
  }
  function lt(t2) {
    return 32 === t2 || 9 === t2 || 10 === t2 || 13 === t2;
  }
  function ht(t2) {
    let e2 = 0;
    for (; e2 < t2.length && lt(t2.charCodeAt(e2)); e2++) ;
    let r2 = t2.length - 1;
    for (; r2 >= e2 && lt(t2.charCodeAt(r2)); r2--) ;
    return t2.slice(e2, r2 + 1);
  }
  const pt = { mdurl: D, ucmicro: F };
  var ft = Object.freeze({ __proto__: null, arrayReplaceAt: U, asciiTrim: ht, assign: $, escapeHtml: rt, escapeRE: function(t2) {
    return t2.replace(nt, "\\$&");
  }, fromCodePoint: V, has: function(t2, e2) {
    return Z.call(t2, e2);
  }, isMdAsciiPunct: ct, isPunctChar: ot, isPunctCharCode: ut, isSpace: st, isString: j, isValidEntityCode: H, isWhiteSpace: it, lib: pt, normalizeReference: at, unescapeAll: X, unescapeMd: function(t2) {
    return t2.indexOf("\\") < 0 ? t2 : t2.replace(G, "$1");
  } });
  var dt = Object.freeze({ __proto__: null, parseLinkDestination: function(t2, e2, r2) {
    let n2, s2 = e2;
    const i2 = { ok: false, pos: 0, str: "" };
    if (60 === t2.charCodeAt(s2)) {
      for (s2++; s2 < r2; ) {
        if (n2 = t2.charCodeAt(s2), 10 === n2) return i2;
        if (60 === n2) return i2;
        if (62 === n2) return i2.pos = s2 + 1, i2.str = X(t2.slice(e2 + 1, s2)), i2.ok = true, i2;
        92 === n2 && s2 + 1 < r2 ? s2 += 2 : s2++;
      }
      return i2;
    }
    let o2 = 0;
    for (; s2 < r2 && (n2 = t2.charCodeAt(s2), 32 !== n2) && !(n2 < 32 || 127 === n2); ) if (92 === n2 && s2 + 1 < r2) {
      if (32 === t2.charCodeAt(s2 + 1)) break;
      s2 += 2;
    } else {
      if (40 === n2 && (o2++, o2 > 32)) return i2;
      if (41 === n2) {
        if (0 === o2) break;
        o2--;
      }
      s2++;
    }
    return e2 === s2 || 0 !== o2 || (i2.str = X(t2.slice(e2, s2)), i2.pos = s2, i2.ok = true), i2;
  }, parseLinkLabel: function(t2, e2, r2) {
    let n2, s2, i2, o2;
    const u2 = t2.posMax, c2 = t2.pos;
    for (t2.pos = e2 + 1, n2 = 1; t2.pos < u2; ) {
      if (i2 = t2.src.charCodeAt(t2.pos), 93 === i2 && (n2--, 0 === n2)) {
        s2 = true;
        break;
      }
      if (o2 = t2.pos, t2.md.inline.skipToken(t2), 91 === i2) {
        if (o2 === t2.pos - 1) n2++;
        else if (r2) return t2.pos = c2, -1;
      }
    }
    let a2 = -1;
    return s2 && (a2 = t2.pos), t2.pos = c2, a2;
  }, parseLinkTitle: function(t2, e2, r2, n2) {
    let s2, i2 = e2;
    const o2 = { ok: false, can_continue: false, pos: 0, str: "", marker: 0 };
    if (n2) o2.str = n2.str, o2.marker = n2.marker;
    else {
      if (i2 >= r2) return o2;
      let n3 = t2.charCodeAt(i2);
      if (34 !== n3 && 39 !== n3 && 40 !== n3) return o2;
      e2++, i2++, 40 === n3 && (n3 = 41), o2.marker = n3;
    }
    for (; i2 < r2; ) {
      if (s2 = t2.charCodeAt(i2), s2 === o2.marker) return o2.pos = i2 + 1, o2.str += X(t2.slice(e2, i2)), o2.ok = true, o2;
      if (40 === s2 && 41 === o2.marker) return o2;
      92 === s2 && i2 + 1 < r2 && i2++, i2++;
    }
    return o2.can_continue = true, o2.str += X(t2.slice(e2, i2)), o2;
  } });
  const _t = {};
  function mt() {
    this.rules = $({}, _t);
  }
  function gt() {
    this.__rules__ = [], this.__cache__ = null;
  }
  function kt(t2, e2, r2) {
    this.type = t2, this.tag = e2, this.attrs = null, this.map = null, this.nesting = r2, this.level = 0, this.children = null, this.content = "", this.markup = "", this.info = "", this.meta = null, this.block = false, this.hidden = false;
  }
  function Dt(t2, e2, r2) {
    this.src = t2, this.env = r2, this.tokens = [], this.inlineMode = false, this.md = e2;
  }
  _t.code_inline = function(t2, e2, r2, n2, s2) {
    const i2 = t2[e2];
    return "<code" + s2.renderAttrs(i2) + ">" + rt(i2.content) + "</code>";
  }, _t.code_block = function(t2, e2, r2, n2, s2) {
    const i2 = t2[e2];
    return "<pre" + s2.renderAttrs(i2) + "><code>" + rt(t2[e2].content) + "</code></pre>\n";
  }, _t.fence = function(t2, e2, r2, n2, s2) {
    const i2 = t2[e2], o2 = i2.info ? X(i2.info).trim() : "";
    let u2, c2 = "", a2 = "";
    if (o2) {
      const t3 = o2.split(/(\s+)/g);
      c2 = t3[0], a2 = t3.slice(2).join("");
    }
    if (u2 = r2.highlight && r2.highlight(i2.content, c2, a2) || rt(i2.content), 0 === u2.indexOf("<pre")) return u2 + "\n";
    if (o2) {
      const t3 = i2.attrIndex("class"), e3 = i2.attrs ? i2.attrs.slice() : [];
      t3 < 0 ? e3.push(["class", r2.langPrefix + c2]) : (e3[t3] = e3[t3].slice(), e3[t3][1] += " " + r2.langPrefix + c2);
      const n3 = { attrs: e3 };
      return `<pre><code${s2.renderAttrs(n3)}>${u2}</code></pre>
`;
    }
    return `<pre><code${s2.renderAttrs(i2)}>${u2}</code></pre>
`;
  }, _t.image = function(t2, e2, r2, n2, s2) {
    const i2 = t2[e2];
    return i2.attrs[i2.attrIndex("alt")][1] = s2.renderInlineAsText(i2.children, r2, n2), s2.renderToken(t2, e2, r2);
  }, _t.hardbreak = function(t2, e2, r2) {
    return r2.xhtmlOut ? "<br />\n" : "<br>\n";
  }, _t.softbreak = function(t2, e2, r2) {
    return r2.breaks ? r2.xhtmlOut ? "<br />\n" : "<br>\n" : "\n";
  }, _t.text = function(t2, e2) {
    return rt(t2[e2].content);
  }, _t.html_block = function(t2, e2) {
    return t2[e2].content;
  }, _t.html_inline = function(t2, e2) {
    return t2[e2].content;
  }, mt.prototype.renderAttrs = function(t2) {
    let e2, r2, n2;
    if (!t2.attrs) return "";
    for (n2 = "", e2 = 0, r2 = t2.attrs.length; e2 < r2; e2++) n2 += " " + rt(t2.attrs[e2][0]) + '="' + rt(t2.attrs[e2][1]) + '"';
    return n2;
  }, mt.prototype.renderToken = function(t2, e2, r2) {
    const n2 = t2[e2];
    let s2 = "";
    if (n2.hidden) return "";
    n2.block && -1 !== n2.nesting && e2 && t2[e2 - 1].hidden && (s2 += "\n"), s2 += (-1 === n2.nesting ? "</" : "<") + n2.tag, s2 += this.renderAttrs(n2), 0 === n2.nesting && r2.xhtmlOut && (s2 += " /");
    let i2 = false;
    if (n2.block && (i2 = true, 1 === n2.nesting && e2 + 1 < t2.length)) {
      const r3 = t2[e2 + 1];
      ("inline" === r3.type || r3.hidden || -1 === r3.nesting && r3.tag === n2.tag) && (i2 = false);
    }
    return s2 += i2 ? ">\n" : ">", s2;
  }, mt.prototype.renderInline = function(t2, e2, r2) {
    let n2 = "";
    const s2 = this.rules;
    for (let i2 = 0, o2 = t2.length; i2 < o2; i2++) {
      const o3 = t2[i2].type;
      void 0 !== s2[o3] ? n2 += s2[o3](t2, i2, e2, r2, this) : n2 += this.renderToken(t2, i2, e2);
    }
    return n2;
  }, mt.prototype.renderInlineAsText = function(t2, e2, r2) {
    let n2 = "";
    for (let s2 = 0, i2 = t2.length; s2 < i2; s2++) switch (t2[s2].type) {
      case "text":
      case "html_inline":
      case "html_block":
        n2 += t2[s2].content;
        break;
      case "image":
        n2 += this.renderInlineAsText(t2[s2].children, e2, r2);
        break;
      case "softbreak":
      case "hardbreak":
        n2 += "\n";
    }
    return n2;
  }, mt.prototype.render = function(t2, e2, r2) {
    let n2 = "";
    const s2 = this.rules;
    for (let i2 = 0, o2 = t2.length; i2 < o2; i2++) {
      const o3 = t2[i2].type;
      "inline" === o3 ? n2 += this.renderInline(t2[i2].children, e2, r2) : void 0 !== s2[o3] ? n2 += s2[o3](t2, i2, e2, r2, this) : n2 += this.renderToken(t2, i2, e2, r2);
    }
    return n2;
  }, gt.prototype.__find__ = function(t2) {
    for (let e2 = 0; e2 < this.__rules__.length; e2++) if (this.__rules__[e2].name === t2) return e2;
    return -1;
  }, gt.prototype.__compile__ = function() {
    const t2 = this, e2 = [""];
    t2.__rules__.forEach(function(t3) {
      t3.enabled && t3.alt.forEach(function(t4) {
        e2.indexOf(t4) < 0 && e2.push(t4);
      });
    }), t2.__cache__ = {}, e2.forEach(function(e3) {
      t2.__cache__[e3] = [], t2.__rules__.forEach(function(r2) {
        r2.enabled && (e3 && r2.alt.indexOf(e3) < 0 || t2.__cache__[e3].push(r2.fn));
      });
    });
  }, gt.prototype.at = function(t2, e2, r2) {
    const n2 = this.__find__(t2), s2 = r2 || {};
    if (-1 === n2) throw new Error("Parser rule not found: " + t2);
    this.__rules__[n2].fn = e2, this.__rules__[n2].alt = s2.alt || [], this.__cache__ = null;
  }, gt.prototype.before = function(t2, e2, r2, n2) {
    const s2 = this.__find__(t2), i2 = n2 || {};
    if (-1 === s2) throw new Error("Parser rule not found: " + t2);
    this.__rules__.splice(s2, 0, { name: e2, enabled: true, fn: r2, alt: i2.alt || [] }), this.__cache__ = null;
  }, gt.prototype.after = function(t2, e2, r2, n2) {
    const s2 = this.__find__(t2), i2 = n2 || {};
    if (-1 === s2) throw new Error("Parser rule not found: " + t2);
    this.__rules__.splice(s2 + 1, 0, { name: e2, enabled: true, fn: r2, alt: i2.alt || [] }), this.__cache__ = null;
  }, gt.prototype.push = function(t2, e2, r2) {
    const n2 = r2 || {};
    this.__rules__.push({ name: t2, enabled: true, fn: e2, alt: n2.alt || [] }), this.__cache__ = null;
  }, gt.prototype.enable = function(t2, e2) {
    Array.isArray(t2) || (t2 = [t2]);
    const r2 = [];
    return t2.forEach(function(t3) {
      const n2 = this.__find__(t3);
      if (n2 < 0) {
        if (e2) return;
        throw new Error("Rules manager: invalid rule name " + t3);
      }
      this.__rules__[n2].enabled = true, r2.push(t3);
    }, this), this.__cache__ = null, r2;
  }, gt.prototype.enableOnly = function(t2, e2) {
    Array.isArray(t2) || (t2 = [t2]), this.__rules__.forEach(function(t3) {
      t3.enabled = false;
    }), this.enable(t2, e2);
  }, gt.prototype.disable = function(t2, e2) {
    Array.isArray(t2) || (t2 = [t2]);
    const r2 = [];
    return t2.forEach(function(t3) {
      const n2 = this.__find__(t3);
      if (n2 < 0) {
        if (e2) return;
        throw new Error("Rules manager: invalid rule name " + t3);
      }
      this.__rules__[n2].enabled = false, r2.push(t3);
    }, this), this.__cache__ = null, r2;
  }, gt.prototype.getRules = function(t2) {
    return null === this.__cache__ && this.__compile__(), this.__cache__[t2] || [];
  }, kt.prototype.attrIndex = function(t2) {
    if (!this.attrs) return -1;
    const e2 = this.attrs;
    for (let r2 = 0, n2 = e2.length; r2 < n2; r2++) if (e2[r2][0] === t2) return r2;
    return -1;
  }, kt.prototype.attrPush = function(t2) {
    this.attrs ? this.attrs.push(t2) : this.attrs = [t2];
  }, kt.prototype.attrSet = function(t2, e2) {
    const r2 = this.attrIndex(t2), n2 = [t2, e2];
    r2 < 0 ? this.attrPush(n2) : this.attrs[r2] = n2;
  }, kt.prototype.attrGet = function(t2) {
    const e2 = this.attrIndex(t2);
    let r2 = null;
    return e2 >= 0 && (r2 = this.attrs[e2][1]), r2;
  }, kt.prototype.attrJoin = function(t2, e2) {
    const r2 = this.attrIndex(t2);
    r2 < 0 ? this.attrPush([t2, e2]) : this.attrs[r2][1] = this.attrs[r2][1] + " " + e2;
  }, Dt.prototype.Token = kt;
  const Ct = /\r\n?|\n/g, yt = /\0/g;
  function Et(t2) {
    return /^<a[>\s]/i.test(t2);
  }
  function At(t2) {
    return /^<\/a\s*>/i.test(t2);
  }
  const bt = /\+-|\.\.|\?\?\?\?|!!!!|,,|--/, Ft = /\((c|tm|r)\)/i, xt = /\((c|tm|r)\)/gi, wt = { c: "\xA9", r: "\xAE", tm: "\u2122" };
  function vt(t2, e2) {
    return wt[e2.toLowerCase()];
  }
  function zt(t2) {
    let e2 = 0;
    for (let r2 = t2.length - 1; r2 >= 0; r2--) {
      const n2 = t2[r2];
      "text" !== n2.type || e2 || (n2.content = n2.content.replace(xt, vt)), "link_open" === n2.type && "auto" === n2.info && e2--, "link_close" === n2.type && "auto" === n2.info && e2++;
    }
  }
  function St(t2) {
    let e2 = 0;
    for (let r2 = t2.length - 1; r2 >= 0; r2--) {
      const n2 = t2[r2];
      "text" !== n2.type || e2 || bt.test(n2.content) && (n2.content = n2.content.replace(/\+-/g, "\xB1").replace(/\.{2,}/g, "\u2026").replace(/([?!])\u2026/g, "$1..").replace(/([?!]){4,}/g, "$1$1$1").replace(/,{2,}/g, ",").replace(/(^|[^-])---(?=[^-]|$)/gm, "$1\u2014").replace(/(^|\s)--(?=\s|$)/gm, "$1\u2013").replace(/(^|[^-\s])--(?=[^-\s]|$)/gm, "$1\u2013")), "link_open" === n2.type && "auto" === n2.info && e2--, "link_close" === n2.type && "auto" === n2.info && e2++;
    }
  }
  const qt = /['"]/, Bt = /['"]/g;
  function Lt(t2, e2, r2, n2) {
    t2[e2] || (t2[e2] = []), t2[e2].push({ pos: r2, ch: n2 });
  }
  function It(t2, e2) {
    let r2;
    const n2 = [], s2 = {};
    for (let i2 = 0; i2 < t2.length; i2++) {
      const o2 = t2[i2], u2 = t2[i2].level;
      for (r2 = n2.length - 1; r2 >= 0 && !(n2[r2].level <= u2); r2--) ;
      if (n2.length = r2 + 1, "text" !== o2.type) continue;
      const c2 = o2.content;
      let a2 = 0;
      const l2 = c2.length;
      t: for (; a2 < l2; ) {
        Bt.lastIndex = a2;
        const o3 = Bt.exec(c2);
        if (!o3) break;
        let h2 = true, p2 = true;
        a2 = o3.index + 1;
        const f2 = "'" === o3[0];
        let d2 = 32;
        if (o3.index - 1 >= 0) d2 = c2.charCodeAt(o3.index - 1);
        else for (r2 = i2 - 1; r2 >= 0 && ("softbreak" !== t2[r2].type && "hardbreak" !== t2[r2].type); r2--) if (t2[r2].content) {
          d2 = t2[r2].content.charCodeAt(t2[r2].content.length - 1);
          break;
        }
        let _2 = 32;
        if (a2 < l2) _2 = c2.charCodeAt(a2);
        else for (r2 = i2 + 1; r2 < t2.length && ("softbreak" !== t2[r2].type && "hardbreak" !== t2[r2].type); r2++) if (t2[r2].content) {
          _2 = t2[r2].content.charCodeAt(0);
          break;
        }
        const m2 = ct(d2) || ut(d2), g2 = ct(_2) || ut(_2), k2 = it(d2), D2 = it(_2);
        if (D2 ? h2 = false : g2 && (k2 || m2 || (h2 = false)), k2 ? p2 = false : m2 && (D2 || g2 || (p2 = false)), 34 === _2 && '"' === o3[0] && d2 >= 48 && d2 <= 57 && (p2 = h2 = false), h2 && p2 && (h2 = m2, p2 = g2), h2 || p2) {
          if (p2) for (r2 = n2.length - 1; r2 >= 0; r2--) {
            let t3 = n2[r2];
            if (n2[r2].level < u2) break;
            if (t3.single === f2 && n2[r2].level === u2) {
              let u3, c3;
              t3 = n2[r2], f2 ? (u3 = e2.md.options.quotes[2], c3 = e2.md.options.quotes[3]) : (u3 = e2.md.options.quotes[0], c3 = e2.md.options.quotes[1]), Lt(s2, i2, o3.index, c3), Lt(s2, t3.token, t3.pos, u3), n2.length = r2;
              continue t;
            }
          }
          h2 ? n2.push({ token: i2, pos: o3.index, single: f2, level: u2 }) : p2 && f2 && Lt(s2, i2, o3.index, "\u2019");
        } else f2 && Lt(s2, i2, o3.index, "\u2019");
      }
    }
    Object.keys(s2).forEach(function(e3) {
      t2[e3].content = (function(t3, e4) {
        let r3 = "", n3 = 0;
        e4.sort((t4, e5) => t4.pos - e5.pos);
        for (let s3 = 0; s3 < e4.length; s3++) {
          const i2 = e4[s3];
          r3 += t3.slice(n3, i2.pos) + i2.ch, n3 = i2.pos + 1;
        }
        return r3 + t3.slice(n3);
      })(t2[e3].content, s2[e3]);
    });
  }
  const Mt = [["normalize", function(t2) {
    let e2;
    e2 = t2.src.replace(Ct, "\n"), e2 = e2.replace(yt, "\uFFFD"), t2.src = e2;
  }], ["block", function(t2) {
    let e2;
    t2.inlineMode ? (e2 = new t2.Token("inline", "", 0), e2.content = t2.src, e2.map = [0, 1], e2.children = [], t2.tokens.push(e2)) : t2.md.block.parse(t2.src, t2.md, t2.env, t2.tokens);
  }], ["inline", function(t2) {
    const e2 = t2.tokens;
    for (let r2 = 0, n2 = e2.length; r2 < n2; r2++) {
      const n3 = e2[r2];
      "inline" === n3.type && t2.md.inline.parse(n3.content, t2.md, t2.env, n3.children);
    }
  }], ["linkify", function(t2) {
    const e2 = t2.tokens;
    if (t2.md.options.linkify) for (let r2 = 0, n2 = e2.length; r2 < n2; r2++) {
      if ("inline" !== e2[r2].type || !t2.md.linkify.pretest(e2[r2].content)) continue;
      let n3 = e2[r2].children, s2 = 0;
      for (let i2 = n3.length - 1; i2 >= 0; i2--) {
        const o2 = n3[i2];
        if ("link_close" !== o2.type) {
          if ("html_inline" === o2.type && (Et(o2.content) && s2 > 0 && s2--, At(o2.content) && s2++), !(s2 > 0) && "text" === o2.type && t2.md.linkify.test(o2.content)) {
            const s3 = o2.content;
            let u2 = t2.md.linkify.match(s3);
            const c2 = [];
            let a2 = o2.level, l2 = 0;
            u2.length > 0 && 0 === u2[0].index && i2 > 0 && "text_special" === n3[i2 - 1].type && (u2 = u2.slice(1));
            for (let e3 = 0; e3 < u2.length; e3++) {
              const r3 = u2[e3].url, n4 = t2.md.normalizeLink(r3);
              if (!t2.md.validateLink(n4)) continue;
              let i3 = u2[e3].text;
              i3 = u2[e3].schema ? "mailto:" !== u2[e3].schema || /^mailto:/i.test(i3) ? t2.md.normalizeLinkText(i3) : t2.md.normalizeLinkText("mailto:" + i3).replace(/^mailto:/, "") : t2.md.normalizeLinkText("http://" + i3).replace(/^http:\/\//, "");
              const o3 = u2[e3].index;
              if (o3 > l2) {
                const e4 = new t2.Token("text", "", 0);
                e4.content = s3.slice(l2, o3), e4.level = a2, c2.push(e4);
              }
              const h2 = new t2.Token("link_open", "a", 1);
              h2.attrs = [["href", n4]], h2.level = a2++, h2.markup = "linkify", h2.info = "auto", c2.push(h2);
              const p2 = new t2.Token("text", "", 0);
              p2.content = i3, p2.level = a2, c2.push(p2);
              const f2 = new t2.Token("link_close", "a", -1);
              f2.level = --a2, f2.markup = "linkify", f2.info = "auto", c2.push(f2), l2 = u2[e3].lastIndex;
            }
            if (l2 < s3.length) {
              const e3 = new t2.Token("text", "", 0);
              e3.content = s3.slice(l2), e3.level = a2, c2.push(e3);
            }
            e2[r2].children = n3 = U(n3, i2, c2);
          }
        } else for (i2--; n3[i2].level !== o2.level && "link_open" !== n3[i2].type; ) i2--;
      }
    }
  }], ["replacements", function(t2) {
    let e2;
    if (t2.md.options.typographer) for (e2 = t2.tokens.length - 1; e2 >= 0; e2--) "inline" === t2.tokens[e2].type && (Ft.test(t2.tokens[e2].content) && zt(t2.tokens[e2].children), bt.test(t2.tokens[e2].content) && St(t2.tokens[e2].children));
  }], ["smartquotes", function(t2) {
    if (t2.md.options.typographer) for (let e2 = t2.tokens.length - 1; e2 >= 0; e2--) "inline" === t2.tokens[e2].type && qt.test(t2.tokens[e2].content) && It(t2.tokens[e2].children, t2);
  }], ["text_join", function(t2) {
    let e2, r2;
    const n2 = t2.tokens, s2 = n2.length;
    for (let t3 = 0; t3 < s2; t3++) {
      if ("inline" !== n2[t3].type) continue;
      const s3 = n2[t3].children, i2 = s3.length;
      for (e2 = 0; e2 < i2; e2++) "text_special" === s3[e2].type && (s3[e2].type = "text");
      for (e2 = r2 = 0; e2 < i2; e2++) "text" === s3[e2].type && e2 + 1 < i2 && "text" === s3[e2 + 1].type ? s3[e2 + 1].content = s3[e2].content + s3[e2 + 1].content : (e2 !== r2 && (s3[r2] = s3[e2]), r2++);
      e2 !== r2 && (s3.length = r2);
    }
  }]];
  function Tt() {
    this.ruler = new gt();
    for (let t2 = 0; t2 < Mt.length; t2++) this.ruler.push(Mt[t2][0], Mt[t2][1]);
  }
  function Rt(t2, e2, r2, n2) {
    this.src = t2, this.md = e2, this.env = r2, this.tokens = n2, this.bMarks = [], this.eMarks = [], this.tShift = [], this.sCount = [], this.bsCount = [], this.blkIndent = 0, this.line = 0, this.lineMax = 0, this.tight = false, this.ddIndent = -1, this.listIndent = -1, this.parentType = "root", this.level = 0;
    const s2 = this.src;
    for (let t3 = 0, e3 = 0, r3 = 0, n3 = 0, i2 = s2.length, o2 = false; e3 < i2; e3++) {
      const u2 = s2.charCodeAt(e3);
      if (!o2) {
        if (st(u2)) {
          r3++, 9 === u2 ? n3 += 4 - n3 % 4 : n3++;
          continue;
        }
        o2 = true;
      }
      10 !== u2 && e3 !== i2 - 1 || (10 !== u2 && e3++, this.bMarks.push(t3), this.eMarks.push(e3), this.tShift.push(r3), this.sCount.push(n3), this.bsCount.push(0), o2 = false, r3 = 0, n3 = 0, t3 = e3 + 1);
    }
    this.bMarks.push(s2.length), this.eMarks.push(s2.length), this.tShift.push(0), this.sCount.push(0), this.bsCount.push(0), this.lineMax = this.bMarks.length - 1;
  }
  Tt.prototype.process = function(t2) {
    const e2 = this.ruler.getRules("");
    for (let r2 = 0, n2 = e2.length; r2 < n2; r2++) e2[r2](t2);
  }, Tt.prototype.State = Dt, Rt.prototype.push = function(t2, e2, r2) {
    const n2 = new kt(t2, e2, r2);
    return n2.block = true, r2 < 0 && this.level--, n2.level = this.level, r2 > 0 && this.level++, this.tokens.push(n2), n2;
  }, Rt.prototype.isEmpty = function(t2) {
    return this.bMarks[t2] + this.tShift[t2] >= this.eMarks[t2];
  }, Rt.prototype.skipEmptyLines = function(t2) {
    for (let e2 = this.lineMax; t2 < e2 && !(this.bMarks[t2] + this.tShift[t2] < this.eMarks[t2]); t2++) ;
    return t2;
  }, Rt.prototype.skipSpaces = function(t2) {
    for (let e2 = this.src.length; t2 < e2; t2++) {
      if (!st(this.src.charCodeAt(t2))) break;
    }
    return t2;
  }, Rt.prototype.skipSpacesBack = function(t2, e2) {
    if (t2 <= e2) return t2;
    for (; t2 > e2; ) if (!st(this.src.charCodeAt(--t2))) return t2 + 1;
    return t2;
  }, Rt.prototype.skipChars = function(t2, e2) {
    for (let r2 = this.src.length; t2 < r2 && this.src.charCodeAt(t2) === e2; t2++) ;
    return t2;
  }, Rt.prototype.skipCharsBack = function(t2, e2, r2) {
    if (t2 <= r2) return t2;
    for (; t2 > r2; ) if (e2 !== this.src.charCodeAt(--t2)) return t2 + 1;
    return t2;
  }, Rt.prototype.getLines = function(t2, e2, r2, n2) {
    if (t2 >= e2) return "";
    const s2 = new Array(e2 - t2);
    for (let i2 = 0, o2 = t2; o2 < e2; o2++, i2++) {
      let t3 = 0;
      const u2 = this.bMarks[o2];
      let c2, a2 = u2;
      for (c2 = o2 + 1 < e2 || n2 ? this.eMarks[o2] + 1 : this.eMarks[o2]; a2 < c2 && t3 < r2; ) {
        const e3 = this.src.charCodeAt(a2);
        if (st(e3)) 9 === e3 ? t3 += 4 - (t3 + this.bsCount[o2]) % 4 : t3++;
        else {
          if (!(a2 - u2 < this.tShift[o2])) break;
          t3++;
        }
        a2++;
      }
      s2[i2] = t3 > r2 ? new Array(t3 - r2 + 1).join(" ") + this.src.slice(a2, c2) : this.src.slice(a2, c2);
    }
    return s2.join("");
  }, Rt.prototype.Token = kt;
  function Nt(t2, e2) {
    const r2 = t2.bMarks[e2] + t2.tShift[e2], n2 = t2.eMarks[e2];
    return t2.src.slice(r2, n2);
  }
  function Pt(t2) {
    const e2 = [], r2 = t2.length;
    let n2 = 0, s2 = t2.charCodeAt(n2), i2 = false, o2 = 0, u2 = "";
    for (; n2 < r2; ) 124 === s2 && (i2 ? (u2 += t2.substring(o2, n2 - 1), o2 = n2) : (e2.push(u2 + t2.substring(o2, n2)), u2 = "", o2 = n2 + 1)), i2 = 92 === s2, n2++, s2 = t2.charCodeAt(n2);
    return e2.push(u2 + t2.substring(o2)), e2;
  }
  function Ot(t2, e2) {
    const r2 = t2.eMarks[e2];
    let n2 = t2.bMarks[e2] + t2.tShift[e2];
    const s2 = t2.src.charCodeAt(n2++);
    if (42 !== s2 && 45 !== s2 && 43 !== s2) return -1;
    if (n2 < r2) {
      if (!st(t2.src.charCodeAt(n2))) return -1;
    }
    return n2;
  }
  function jt(t2, e2) {
    const r2 = t2.bMarks[e2] + t2.tShift[e2], n2 = t2.eMarks[e2];
    let s2 = r2;
    if (s2 + 1 >= n2) return -1;
    let i2 = t2.src.charCodeAt(s2++);
    if (i2 < 48 || i2 > 57) return -1;
    for (; ; ) {
      if (s2 >= n2) return -1;
      if (i2 = t2.src.charCodeAt(s2++), !(i2 >= 48 && i2 <= 57)) {
        if (41 === i2 || 46 === i2) break;
        return -1;
      }
      if (s2 - r2 >= 10) return -1;
    }
    return s2 < n2 && (i2 = t2.src.charCodeAt(s2), !st(i2)) ? -1 : s2;
  }
  const Zt = `<[A-Za-z][A-Za-z0-9\\-]*(?:\\s+[a-zA-Z_:][a-zA-Z0-9:._-]*(?:\\s*=\\s*(?:[^"'=<>\`\\x00-\\x20]+|'[^']*'|"[^"]*"))?)*\\s*\\/?>`, $t = "<\\/[A-Za-z][A-Za-z0-9\\-]*\\s*>", Ut = new RegExp("^(?:" + Zt + "|" + $t + "|<\!---?>|<\!--(?:[^-]|-[^-]|--[^>])*-->|<[?][\\s\\S]*?[?]>|<![A-Za-z][^>]*>|<!\\[CDATA\\[[\\s\\S]*?\\]\\]>)"), Ht = new RegExp("^(?:" + Zt + "|" + $t + ")"), Vt = [[/^<(script|pre|style|textarea)(?=(\s|>|$))/i, /<\/(script|pre|style|textarea)>/i, true], [/^<\!--/, /-->/, true], [/^<\?/, /\?>/, true], [/^<![A-Z]/, />/, true], [/^<!\[CDATA\[/, /\]\]>/, true], [new RegExp("^</?(" + ["address", "article", "aside", "base", "basefont", "blockquote", "body", "caption", "center", "col", "colgroup", "dd", "details", "dialog", "dir", "div", "dl", "dt", "fieldset", "figcaption", "figure", "footer", "form", "frame", "frameset", "h1", "h2", "h3", "h4", "h5", "h6", "head", "header", "hr", "html", "iframe", "legend", "li", "link", "main", "menu", "menuitem", "nav", "noframes", "ol", "optgroup", "option", "p", "param", "search", "section", "summary", "table", "tbody", "td", "tfoot", "th", "thead", "title", "tr", "track", "ul"].join("|") + ")(?=(\\s|/?>|$))", "i"), /^$/, true], [new RegExp(Ht.source + "\\s*$"), /^$/, false]];
  const Gt = [["table", function(t2, e2, r2, n2) {
    if (e2 + 2 > r2) return false;
    let s2 = e2 + 1;
    if (t2.sCount[s2] < t2.blkIndent) return false;
    if (t2.sCount[s2] - t2.blkIndent >= 4) return false;
    let i2 = t2.bMarks[s2] + t2.tShift[s2];
    if (i2 >= t2.eMarks[s2]) return false;
    const o2 = t2.src.charCodeAt(i2++);
    if (124 !== o2 && 45 !== o2 && 58 !== o2) return false;
    if (i2 >= t2.eMarks[s2]) return false;
    const u2 = t2.src.charCodeAt(i2++);
    if (124 !== u2 && 45 !== u2 && 58 !== u2 && !st(u2)) return false;
    if (45 === o2 && st(u2)) return false;
    for (; i2 < t2.eMarks[s2]; ) {
      const e3 = t2.src.charCodeAt(i2);
      if (124 !== e3 && 45 !== e3 && 58 !== e3 && !st(e3)) return false;
      i2++;
    }
    let c2 = Nt(t2, e2 + 1), a2 = c2.split("|");
    const l2 = [];
    for (let t3 = 0; t3 < a2.length; t3++) {
      const e3 = a2[t3].trim();
      if (!e3) {
        if (0 === t3 || t3 === a2.length - 1) continue;
        return false;
      }
      if (!/^:?-+:?$/.test(e3)) return false;
      58 === e3.charCodeAt(e3.length - 1) ? l2.push(58 === e3.charCodeAt(0) ? "center" : "right") : 58 === e3.charCodeAt(0) ? l2.push("left") : l2.push("");
    }
    if (c2 = Nt(t2, e2).trim(), -1 === c2.indexOf("|")) return false;
    if (t2.sCount[e2] - t2.blkIndent >= 4) return false;
    a2 = Pt(c2), a2.length && "" === a2[0] && a2.shift(), a2.length && "" === a2[a2.length - 1] && a2.pop();
    const h2 = a2.length;
    if (0 === h2 || h2 !== l2.length) return false;
    if (n2) return true;
    const p2 = t2.parentType;
    t2.parentType = "table";
    const f2 = t2.md.block.ruler.getRules("blockquote"), d2 = [e2, 0];
    t2.push("table_open", "table", 1).map = d2, t2.push("thead_open", "thead", 1).map = [e2, e2 + 1], t2.push("tr_open", "tr", 1).map = [e2, e2 + 1];
    for (let e3 = 0; e3 < a2.length; e3++) {
      const r3 = t2.push("th_open", "th", 1);
      l2[e3] && (r3.attrs = [["style", "text-align:" + l2[e3]]]);
      const n3 = t2.push("inline", "", 0);
      n3.content = a2[e3].trim(), n3.children = [], t2.push("th_close", "th", -1);
    }
    let _2;
    t2.push("tr_close", "tr", -1), t2.push("thead_close", "thead", -1);
    let m2 = 0;
    for (s2 = e2 + 2; s2 < r2 && !(t2.sCount[s2] < t2.blkIndent); s2++) {
      let n3 = false;
      for (let e3 = 0, i3 = f2.length; e3 < i3; e3++) if (f2[e3](t2, s2, r2, true)) {
        n3 = true;
        break;
      }
      if (n3) break;
      if (c2 = Nt(t2, s2).trim(), !c2) break;
      if (t2.sCount[s2] - t2.blkIndent >= 4) break;
      if (a2 = Pt(c2), a2.length && "" === a2[0] && a2.shift(), a2.length && "" === a2[a2.length - 1] && a2.pop(), m2 += h2 - a2.length, m2 > 65536) break;
      if (s2 === e2 + 2) {
        t2.push("tbody_open", "tbody", 1).map = _2 = [e2 + 2, 0];
      }
      t2.push("tr_open", "tr", 1).map = [s2, s2 + 1];
      for (let e3 = 0; e3 < h2; e3++) {
        const r3 = t2.push("td_open", "td", 1);
        l2[e3] && (r3.attrs = [["style", "text-align:" + l2[e3]]]);
        const n4 = t2.push("inline", "", 0);
        n4.content = a2[e3] ? a2[e3].trim() : "", n4.children = [], t2.push("td_close", "td", -1);
      }
      t2.push("tr_close", "tr", -1);
    }
    return _2 && (t2.push("tbody_close", "tbody", -1), _2[1] = s2), t2.push("table_close", "table", -1), d2[1] = s2, t2.parentType = p2, t2.line = s2, true;
  }, ["paragraph", "reference"]], ["code", function(t2, e2, r2) {
    if (t2.sCount[e2] - t2.blkIndent < 4) return false;
    let n2 = e2 + 1, s2 = n2;
    for (; n2 < r2; ) if (t2.isEmpty(n2)) n2++;
    else {
      if (!(t2.sCount[n2] - t2.blkIndent >= 4)) break;
      n2++, s2 = n2;
    }
    t2.line = s2;
    const i2 = t2.push("code_block", "code", 0);
    return i2.content = t2.getLines(e2, s2, 4 + t2.blkIndent, false) + "\n", i2.map = [e2, t2.line], true;
  }], ["fence", function(t2, e2, r2, n2) {
    let s2 = t2.bMarks[e2] + t2.tShift[e2], i2 = t2.eMarks[e2];
    if (t2.sCount[e2] - t2.blkIndent >= 4) return false;
    if (s2 + 3 > i2) return false;
    const o2 = t2.src.charCodeAt(s2);
    if (126 !== o2 && 96 !== o2) return false;
    let u2 = s2;
    s2 = t2.skipChars(s2, o2);
    let c2 = s2 - u2;
    if (c2 < 3) return false;
    const a2 = t2.src.slice(u2, s2), l2 = t2.src.slice(s2, i2);
    if (96 === o2 && l2.indexOf(String.fromCharCode(o2)) >= 0) return false;
    if (n2) return true;
    let h2 = e2, p2 = false;
    for (; (h2++, !(h2 >= r2)) && (s2 = u2 = t2.bMarks[h2] + t2.tShift[h2], i2 = t2.eMarks[h2], !(s2 < i2 && t2.sCount[h2] < t2.blkIndent)); ) if (t2.src.charCodeAt(s2) === o2 && !(t2.sCount[h2] - t2.blkIndent >= 4 || (s2 = t2.skipChars(s2, o2), s2 - u2 < c2 || (s2 = t2.skipSpaces(s2), s2 < i2)))) {
      p2 = true;
      break;
    }
    c2 = t2.sCount[e2], t2.line = h2 + (p2 ? 1 : 0);
    const f2 = t2.push("fence", "code", 0);
    return f2.info = l2, f2.content = t2.getLines(e2 + 1, h2, c2, true), f2.markup = a2, f2.map = [e2, t2.line], true;
  }, ["paragraph", "reference", "blockquote", "list"]], ["blockquote", function(t2, e2, r2, n2) {
    let s2 = t2.bMarks[e2] + t2.tShift[e2], i2 = t2.eMarks[e2];
    const o2 = t2.lineMax;
    if (t2.sCount[e2] - t2.blkIndent >= 4) return false;
    if (62 !== t2.src.charCodeAt(s2)) return false;
    if (n2) return true;
    const u2 = [], c2 = [], a2 = [], l2 = [], h2 = t2.md.block.ruler.getRules("blockquote"), p2 = t2.parentType;
    t2.parentType = "blockquote";
    let f2, d2 = false;
    for (f2 = e2; f2 < r2; f2++) {
      const e3 = t2.sCount[f2] < t2.blkIndent;
      if (s2 = t2.bMarks[f2] + t2.tShift[f2], i2 = t2.eMarks[f2], s2 >= i2) break;
      if (62 === t2.src.charCodeAt(s2++) && !e3) {
        let e4, r3, n4 = t2.sCount[f2] + 1;
        32 === t2.src.charCodeAt(s2) ? (s2++, n4++, r3 = false, e4 = true) : 9 === t2.src.charCodeAt(s2) ? (e4 = true, (t2.bsCount[f2] + n4) % 4 == 3 ? (s2++, n4++, r3 = false) : r3 = true) : e4 = false;
        let o3 = n4;
        for (u2.push(t2.bMarks[f2]), t2.bMarks[f2] = s2; s2 < i2; ) {
          const e5 = t2.src.charCodeAt(s2);
          if (!st(e5)) break;
          9 === e5 ? o3 += 4 - (o3 + t2.bsCount[f2] + (r3 ? 1 : 0)) % 4 : o3++, s2++;
        }
        d2 = s2 >= i2, c2.push(t2.bsCount[f2]), t2.bsCount[f2] = t2.sCount[f2] + 1 + (e4 ? 1 : 0), a2.push(t2.sCount[f2]), t2.sCount[f2] = o3 - n4, l2.push(t2.tShift[f2]), t2.tShift[f2] = s2 - t2.bMarks[f2];
        continue;
      }
      if (d2) break;
      let n3 = false;
      for (let e4 = 0, s3 = h2.length; e4 < s3; e4++) if (h2[e4](t2, f2, r2, true)) {
        n3 = true;
        break;
      }
      if (n3) {
        t2.lineMax = f2, 0 !== t2.blkIndent && (u2.push(t2.bMarks[f2]), c2.push(t2.bsCount[f2]), l2.push(t2.tShift[f2]), a2.push(t2.sCount[f2]), t2.sCount[f2] -= t2.blkIndent);
        break;
      }
      u2.push(t2.bMarks[f2]), c2.push(t2.bsCount[f2]), l2.push(t2.tShift[f2]), a2.push(t2.sCount[f2]), t2.sCount[f2] = -1;
    }
    const _2 = t2.blkIndent;
    t2.blkIndent = 0;
    const m2 = t2.push("blockquote_open", "blockquote", 1);
    m2.markup = ">";
    const g2 = [e2, 0];
    m2.map = g2, t2.md.block.tokenize(t2, e2, f2), t2.push("blockquote_close", "blockquote", -1).markup = ">", t2.lineMax = o2, t2.parentType = p2, g2[1] = t2.line;
    for (let r3 = 0; r3 < l2.length; r3++) t2.bMarks[r3 + e2] = u2[r3], t2.tShift[r3 + e2] = l2[r3], t2.sCount[r3 + e2] = a2[r3], t2.bsCount[r3 + e2] = c2[r3];
    return t2.blkIndent = _2, true;
  }, ["paragraph", "reference", "blockquote", "list"]], ["hr", function(t2, e2, r2, n2) {
    const s2 = t2.eMarks[e2];
    if (t2.sCount[e2] - t2.blkIndent >= 4) return false;
    let i2 = t2.bMarks[e2] + t2.tShift[e2];
    const o2 = t2.src.charCodeAt(i2++);
    if (42 !== o2 && 45 !== o2 && 95 !== o2) return false;
    let u2 = 1;
    for (; i2 < s2; ) {
      const e3 = t2.src.charCodeAt(i2++);
      if (e3 !== o2 && !st(e3)) return false;
      e3 === o2 && u2++;
    }
    if (u2 < 3) return false;
    if (n2) return true;
    t2.line = e2 + 1;
    const c2 = t2.push("hr", "hr", 0);
    return c2.map = [e2, t2.line], c2.markup = Array(u2 + 1).join(String.fromCharCode(o2)), true;
  }, ["paragraph", "reference", "blockquote", "list"]], ["list", function(t2, e2, r2, n2) {
    let s2, i2, o2, u2, c2 = e2, a2 = true;
    if (t2.sCount[c2] - t2.blkIndent >= 4) return false;
    if (t2.listIndent >= 0 && t2.sCount[c2] - t2.listIndent >= 4 && t2.sCount[c2] < t2.blkIndent) return false;
    let l2, h2, p2, f2 = false;
    if (n2 && "paragraph" === t2.parentType && t2.sCount[c2] >= t2.blkIndent && (f2 = true), (p2 = jt(t2, c2)) >= 0) {
      if (l2 = true, o2 = t2.bMarks[c2] + t2.tShift[c2], h2 = Number(t2.src.slice(o2, p2 - 1)), f2 && 1 !== h2) return false;
    } else {
      if (!((p2 = Ot(t2, c2)) >= 0)) return false;
      l2 = false;
    }
    if (f2 && t2.skipSpaces(p2) >= t2.eMarks[c2]) return false;
    if (n2) return true;
    const d2 = t2.src.charCodeAt(p2 - 1), _2 = t2.tokens.length;
    l2 ? (u2 = t2.push("ordered_list_open", "ol", 1), 1 !== h2 && (u2.attrs = [["start", h2]])) : u2 = t2.push("bullet_list_open", "ul", 1);
    const m2 = [c2, 0];
    u2.map = m2, u2.markup = String.fromCharCode(d2);
    let g2 = false;
    const k2 = t2.md.block.ruler.getRules("list"), D2 = t2.parentType;
    for (t2.parentType = "list"; c2 < r2; ) {
      i2 = p2, s2 = t2.eMarks[c2];
      const e3 = t2.sCount[c2] + p2 - (t2.bMarks[c2] + t2.tShift[c2]);
      let n3 = e3;
      for (; i2 < s2; ) {
        const e4 = t2.src.charCodeAt(i2);
        if (9 === e4) n3 += 4 - (n3 + t2.bsCount[c2]) % 4;
        else {
          if (32 !== e4) break;
          n3++;
        }
        i2++;
      }
      const h3 = i2;
      let f3;
      f3 = h3 >= s2 ? 1 : n3 - e3, f3 > 4 && (f3 = 1);
      const _3 = e3 + f3;
      u2 = t2.push("list_item_open", "li", 1), u2.markup = String.fromCharCode(d2);
      const m3 = [c2, 0];
      u2.map = m3, l2 && (u2.info = t2.src.slice(o2, p2 - 1));
      const D3 = t2.tight, C2 = t2.tShift[c2], y2 = t2.sCount[c2], E2 = t2.listIndent;
      if (t2.listIndent = t2.blkIndent, t2.blkIndent = _3, t2.tight = true, t2.tShift[c2] = h3 - t2.bMarks[c2], t2.sCount[c2] = n3, h3 >= s2 && t2.isEmpty(c2 + 1) ? t2.line = Math.min(t2.line + 2, r2) : t2.md.block.tokenize(t2, c2, r2, true), t2.tight && !g2 || (a2 = false), g2 = t2.line - c2 > 1 && t2.isEmpty(t2.line - 1), t2.blkIndent = t2.listIndent, t2.listIndent = E2, t2.tShift[c2] = C2, t2.sCount[c2] = y2, t2.tight = D3, u2 = t2.push("list_item_close", "li", -1), u2.markup = String.fromCharCode(d2), c2 = t2.line, m3[1] = c2, c2 >= r2) break;
      if (t2.sCount[c2] < t2.blkIndent) break;
      if (t2.sCount[c2] - t2.blkIndent >= 4) break;
      let A2 = false;
      for (let e4 = 0, n4 = k2.length; e4 < n4; e4++) if (k2[e4](t2, c2, r2, true)) {
        A2 = true;
        break;
      }
      if (A2) break;
      if (l2) {
        if (p2 = jt(t2, c2), p2 < 0) break;
        o2 = t2.bMarks[c2] + t2.tShift[c2];
      } else if (p2 = Ot(t2, c2), p2 < 0) break;
      if (d2 !== t2.src.charCodeAt(p2 - 1)) break;
    }
    return u2 = l2 ? t2.push("ordered_list_close", "ol", -1) : t2.push("bullet_list_close", "ul", -1), u2.markup = String.fromCharCode(d2), m2[1] = c2, t2.line = c2, t2.parentType = D2, a2 && (function(t3, e3) {
      const r3 = t3.level + 2;
      for (let n3 = e3 + 2, s3 = t3.tokens.length - 2; n3 < s3; n3++) t3.tokens[n3].level === r3 && "paragraph_open" === t3.tokens[n3].type && (t3.tokens[n3 + 2].hidden = true, t3.tokens[n3].hidden = true, n3 += 2);
    })(t2, _2), true;
  }, ["paragraph", "reference", "blockquote"]], ["reference", function(t2, e2, r2, n2) {
    let s2 = t2.bMarks[e2] + t2.tShift[e2], i2 = t2.eMarks[e2], o2 = e2 + 1;
    if (t2.sCount[e2] - t2.blkIndent >= 4) return false;
    if (91 !== t2.src.charCodeAt(s2)) return false;
    function u2(e3) {
      const r3 = t2.lineMax;
      if (e3 >= r3 || t2.isEmpty(e3)) return null;
      let n3 = false;
      if (t2.sCount[e3] - t2.blkIndent > 3 && (n3 = true), t2.sCount[e3] < 0 && (n3 = true), !n3) {
        const n4 = t2.md.block.ruler.getRules("reference"), s4 = t2.parentType;
        t2.parentType = "reference";
        let i4 = false;
        for (let s5 = 0, o3 = n4.length; s5 < o3; s5++) if (n4[s5](t2, e3, r3, true)) {
          i4 = true;
          break;
        }
        if (t2.parentType = s4, i4) return null;
      }
      const s3 = t2.bMarks[e3] + t2.tShift[e3], i3 = t2.eMarks[e3];
      return t2.src.slice(s3, i3 + 1);
    }
    let c2 = t2.src.slice(s2, i2 + 1);
    i2 = c2.length;
    let a2 = -1;
    for (s2 = 1; s2 < i2; s2++) {
      const t3 = c2.charCodeAt(s2);
      if (91 === t3) return false;
      if (93 === t3) {
        a2 = s2;
        break;
      }
      if (10 === t3) {
        const t4 = u2(o2);
        null !== t4 && (c2 += t4, i2 = c2.length, o2++);
      } else if (92 === t3 && (s2++, s2 < i2 && 10 === c2.charCodeAt(s2))) {
        const t4 = u2(o2);
        null !== t4 && (c2 += t4, i2 = c2.length, o2++);
      }
    }
    if (a2 < 0 || 58 !== c2.charCodeAt(a2 + 1)) return false;
    for (s2 = a2 + 2; s2 < i2; s2++) {
      const t3 = c2.charCodeAt(s2);
      if (10 === t3) {
        const t4 = u2(o2);
        null !== t4 && (c2 += t4, i2 = c2.length, o2++);
      } else if (!st(t3)) break;
    }
    const l2 = t2.md.helpers.parseLinkDestination(c2, s2, i2);
    if (!l2.ok) return false;
    const h2 = t2.md.normalizeLink(l2.str);
    if (!t2.md.validateLink(h2)) return false;
    s2 = l2.pos;
    const p2 = s2, f2 = o2, d2 = s2;
    for (; s2 < i2; s2++) {
      const t3 = c2.charCodeAt(s2);
      if (10 === t3) {
        const t4 = u2(o2);
        null !== t4 && (c2 += t4, i2 = c2.length, o2++);
      } else if (!st(t3)) break;
    }
    let _2, m2 = t2.md.helpers.parseLinkTitle(c2, s2, i2);
    for (; m2.can_continue; ) {
      const e3 = u2(o2);
      if (null === e3) break;
      c2 += e3, s2 = i2, i2 = c2.length, o2++, m2 = t2.md.helpers.parseLinkTitle(c2, s2, i2, m2);
    }
    for (s2 < i2 && d2 !== s2 && m2.ok ? (_2 = m2.str, s2 = m2.pos) : (_2 = "", s2 = p2, o2 = f2); s2 < i2; ) {
      if (!st(c2.charCodeAt(s2))) break;
      s2++;
    }
    if (s2 < i2 && 10 !== c2.charCodeAt(s2) && _2) for (_2 = "", s2 = p2, o2 = f2; s2 < i2; ) {
      if (!st(c2.charCodeAt(s2))) break;
      s2++;
    }
    if (s2 < i2 && 10 !== c2.charCodeAt(s2)) return false;
    const g2 = at(c2.slice(1, a2));
    return !!g2 && (n2 || (void 0 === t2.env.references && (t2.env.references = {}), void 0 === t2.env.references[g2] && (t2.env.references[g2] = { title: _2, href: h2 }), t2.line = o2), true);
  }], ["html_block", function(t2, e2, r2, n2) {
    let s2 = t2.bMarks[e2] + t2.tShift[e2], i2 = t2.eMarks[e2];
    if (t2.sCount[e2] - t2.blkIndent >= 4) return false;
    if (!t2.md.options.html) return false;
    if (60 !== t2.src.charCodeAt(s2)) return false;
    let o2 = t2.src.slice(s2, i2), u2 = 0;
    for (; u2 < Vt.length && !Vt[u2][0].test(o2); u2++) ;
    if (u2 === Vt.length) return false;
    if (n2) return Vt[u2][2];
    let c2 = e2 + 1;
    const a2 = Vt[u2][1].test("");
    if (!Vt[u2][1].test(o2)) {
      for (; c2 < r2 && (!(t2.sCount[c2] < t2.blkIndent) || !a2 && t2.isEmpty(c2)); c2++) if (s2 = t2.bMarks[c2] + t2.tShift[c2], i2 = t2.eMarks[c2], o2 = t2.src.slice(s2, i2), Vt[u2][1].test(o2)) {
        0 !== o2.length && c2++;
        break;
      }
    }
    t2.line = c2;
    const l2 = t2.push("html_block", "", 0);
    return l2.map = [e2, c2], l2.content = t2.getLines(e2, c2, t2.blkIndent, true), true;
  }, ["paragraph", "reference", "blockquote"]], ["heading", function(t2, e2, r2, n2) {
    let s2 = t2.bMarks[e2] + t2.tShift[e2], i2 = t2.eMarks[e2];
    if (t2.sCount[e2] - t2.blkIndent >= 4) return false;
    let o2 = t2.src.charCodeAt(s2);
    if (35 !== o2 || s2 >= i2) return false;
    let u2 = 1;
    for (o2 = t2.src.charCodeAt(++s2); 35 === o2 && s2 < i2 && u2 <= 6; ) u2++, o2 = t2.src.charCodeAt(++s2);
    if (u2 > 6 || s2 < i2 && !st(o2)) return false;
    if (n2) return true;
    i2 = t2.skipSpacesBack(i2, s2);
    const c2 = t2.skipCharsBack(i2, 35, s2);
    c2 > s2 && st(t2.src.charCodeAt(c2 - 1)) && (i2 = c2), t2.line = e2 + 1;
    const a2 = t2.push("heading_open", "h" + String(u2), 1);
    a2.markup = "########".slice(0, u2), a2.map = [e2, t2.line];
    const l2 = t2.push("inline", "", 0);
    return l2.content = ht(t2.src.slice(s2, i2)), l2.map = [e2, t2.line], l2.children = [], t2.push("heading_close", "h" + String(u2), -1).markup = "########".slice(0, u2), true;
  }, ["paragraph", "reference", "blockquote"]], ["lheading", function(t2, e2, r2) {
    const n2 = t2.md.block.ruler.getRules("paragraph");
    if (t2.sCount[e2] - t2.blkIndent >= 4) return false;
    const s2 = t2.parentType;
    t2.parentType = "paragraph";
    let i2, o2 = 0, u2 = e2 + 1;
    for (; u2 < r2 && !t2.isEmpty(u2); u2++) {
      if (t2.sCount[u2] - t2.blkIndent > 3) continue;
      if (t2.sCount[u2] >= t2.blkIndent) {
        let e4 = t2.bMarks[u2] + t2.tShift[u2];
        const r3 = t2.eMarks[u2];
        if (e4 < r3 && (i2 = t2.src.charCodeAt(e4), (45 === i2 || 61 === i2) && (e4 = t2.skipChars(e4, i2), e4 = t2.skipSpaces(e4), e4 >= r3))) {
          o2 = 61 === i2 ? 1 : 2;
          break;
        }
      }
      if (t2.sCount[u2] < 0) continue;
      let e3 = false;
      for (let s3 = 0, i3 = n2.length; s3 < i3; s3++) if (n2[s3](t2, u2, r2, true)) {
        e3 = true;
        break;
      }
      if (e3) break;
    }
    if (!o2) return t2.parentType = s2, false;
    const c2 = ht(t2.getLines(e2, u2, t2.blkIndent, false));
    t2.line = u2 + 1;
    const a2 = t2.push("heading_open", "h" + String(o2), 1);
    a2.markup = String.fromCharCode(i2), a2.map = [e2, t2.line];
    const l2 = t2.push("inline", "", 0);
    return l2.content = c2, l2.map = [e2, t2.line - 1], l2.children = [], t2.push("heading_close", "h" + String(o2), -1).markup = String.fromCharCode(i2), t2.parentType = s2, true;
  }], ["paragraph", function(t2, e2, r2) {
    const n2 = t2.md.block.ruler.getRules("paragraph"), s2 = t2.parentType;
    let i2 = e2 + 1;
    for (t2.parentType = "paragraph"; i2 < r2 && !t2.isEmpty(i2); i2++) {
      if (t2.sCount[i2] - t2.blkIndent > 3) continue;
      if (t2.sCount[i2] < 0) continue;
      let e3 = false;
      for (let s3 = 0, o3 = n2.length; s3 < o3; s3++) if (n2[s3](t2, i2, r2, true)) {
        e3 = true;
        break;
      }
      if (e3) break;
    }
    const o2 = ht(t2.getLines(e2, i2, t2.blkIndent, false));
    t2.line = i2, t2.push("paragraph_open", "p", 1).map = [e2, t2.line];
    const u2 = t2.push("inline", "", 0);
    return u2.content = o2, u2.map = [e2, t2.line], u2.children = [], t2.push("paragraph_close", "p", -1), t2.parentType = s2, true;
  }]];
  function Wt() {
    this.ruler = new gt();
    for (let t2 = 0; t2 < Gt.length; t2++) this.ruler.push(Gt[t2][0], Gt[t2][1], { alt: (Gt[t2][2] || []).slice() });
  }
  function Jt(t2, e2, r2, n2) {
    this.src = t2, this.env = r2, this.md = e2, this.tokens = n2, this.tokens_meta = Array(n2.length), this.pos = 0, this.posMax = this.src.length, this.level = 0, this.pending = "", this.pendingLevel = 0, this.cache = {}, this.delimiters = [], this._prev_delimiters = [], this.backticks = {}, this.backticksScanned = false, this.linkLevel = 0;
  }
  function Qt(t2) {
    switch (t2) {
      case 10:
      case 33:
      case 35:
      case 36:
      case 37:
      case 38:
      case 42:
      case 43:
      case 45:
      case 58:
      case 60:
      case 61:
      case 62:
      case 64:
      case 91:
      case 92:
      case 93:
      case 94:
      case 95:
      case 96:
      case 123:
      case 125:
      case 126:
        return true;
      default:
        return false;
    }
  }
  Wt.prototype.tokenize = function(t2, e2, r2) {
    const n2 = this.ruler.getRules(""), s2 = n2.length, i2 = t2.md.options.maxNesting;
    let o2 = e2, u2 = false;
    for (; o2 < r2 && (t2.line = o2 = t2.skipEmptyLines(o2), !(o2 >= r2)) && !(t2.sCount[o2] < t2.blkIndent); ) {
      if (t2.level >= i2) {
        t2.line = r2;
        break;
      }
      const e3 = t2.line;
      let c2 = false;
      for (let i3 = 0; i3 < s2; i3++) if (c2 = n2[i3](t2, o2, r2, false), c2) {
        if (e3 >= t2.line) throw new Error("block rule didn't increment state.line");
        break;
      }
      if (!c2) throw new Error("none of the block rules matched");
      t2.tight = !u2, t2.isEmpty(t2.line - 1) && (u2 = true), o2 = t2.line, o2 < r2 && t2.isEmpty(o2) && (u2 = true, o2++, t2.line = o2);
    }
  }, Wt.prototype.parse = function(t2, e2, r2, n2) {
    if (!t2) return;
    const s2 = new this.State(t2, e2, r2, n2);
    this.tokenize(s2, s2.line, s2.lineMax);
  }, Wt.prototype.State = Rt, Jt.prototype.pushPending = function() {
    const t2 = new kt("text", "", 0);
    return t2.content = this.pending, t2.level = this.pendingLevel, this.tokens.push(t2), this.pending = "", t2;
  }, Jt.prototype.push = function(t2, e2, r2) {
    this.pending && this.pushPending();
    const n2 = new kt(t2, e2, r2);
    let s2 = null;
    return r2 < 0 && (this.level--, this.delimiters = this._prev_delimiters.pop()), n2.level = this.level, r2 > 0 && (this.level++, this._prev_delimiters.push(this.delimiters), this.delimiters = [], s2 = { delimiters: this.delimiters }), this.pendingLevel = this.level, this.tokens.push(n2), this.tokens_meta.push(s2), n2;
  }, Jt.prototype.scanDelims = function(t2, e2) {
    const r2 = this.posMax, n2 = this.src.charCodeAt(t2);
    let s2;
    if (0 === t2) s2 = 32;
    else if (1 === t2) s2 = this.src.charCodeAt(0), 55296 == (63488 & s2) && (s2 = 65533);
    else if (s2 = this.src.charCodeAt(t2 - 1), 56320 == (64512 & s2)) {
      const e3 = this.src.charCodeAt(t2 - 2);
      s2 = 55296 == (64512 & e3) ? 65536 + (e3 - 55296 << 10) + (s2 - 56320) : 65533;
    } else 55296 == (64512 & s2) && (s2 = 65533);
    let i2 = t2;
    for (; i2 < r2 && this.src.charCodeAt(i2) === n2; ) i2++;
    const o2 = i2 - t2;
    let u2 = i2 < r2 ? this.src.charCodeAt(i2) : 32;
    if (55296 == (64512 & u2)) {
      const t3 = this.src.charCodeAt(i2 + 1);
      u2 = 56320 == (64512 & t3) ? 65536 + (u2 - 55296 << 10) + (t3 - 56320) : 65533;
    } else 56320 == (64512 & u2) && (u2 = 65533);
    const c2 = ct(s2) || ut(s2), a2 = ct(u2) || ut(u2), l2 = it(s2), h2 = it(u2), p2 = !h2 && (!a2 || l2 || c2), f2 = !l2 && (!c2 || h2 || a2);
    return { can_open: p2 && (e2 || !f2 || c2), can_close: f2 && (e2 || !p2 || a2), length: o2 };
  }, Jt.prototype.Token = kt;
  const Xt = /(?:^|[^a-z0-9.+-])([a-z][a-z0-9.+-]*)$/i;
  const Yt = [];
  for (let t2 = 0; t2 < 256; t2++) Yt.push(0);
  function Kt(t2, e2) {
    let r2;
    const n2 = [], s2 = e2.length;
    for (let i2 = 0; i2 < s2; i2++) {
      const s3 = e2[i2];
      if (126 !== s3.marker) continue;
      if (-1 === s3.end) continue;
      const o2 = e2[s3.end];
      r2 = t2.tokens[s3.token], r2.type = "s_open", r2.tag = "s", r2.nesting = 1, r2.markup = "~~", r2.content = "", r2 = t2.tokens[o2.token], r2.type = "s_close", r2.tag = "s", r2.nesting = -1, r2.markup = "~~", r2.content = "", "text" === t2.tokens[o2.token - 1].type && "~" === t2.tokens[o2.token - 1].content && n2.push(o2.token - 1);
    }
    for (; n2.length; ) {
      const e3 = n2.pop();
      let s3 = e3 + 1;
      for (; s3 < t2.tokens.length && "s_close" === t2.tokens[s3].type; ) s3++;
      s3--, e3 !== s3 && (r2 = t2.tokens[s3], t2.tokens[s3] = t2.tokens[e3], t2.tokens[e3] = r2);
    }
  }
  "\\!\"#$%&'()*+,./:;<=>?@[]^_`{|}~-".split("").forEach(function(t2) {
    Yt[t2.charCodeAt(0)] = 1;
  });
  var te = { tokenize: function(t2, e2) {
    const r2 = t2.pos, n2 = t2.src.charCodeAt(r2);
    if (e2) return false;
    if (126 !== n2) return false;
    const s2 = t2.scanDelims(t2.pos, true);
    let i2 = s2.length;
    const o2 = String.fromCharCode(n2);
    if (i2 < 2) return false;
    let u2;
    i2 % 2 && (u2 = t2.push("text", "", 0), u2.content = o2, i2--);
    for (let e3 = 0; e3 < i2; e3 += 2) u2 = t2.push("text", "", 0), u2.content = o2 + o2, t2.delimiters.push({ marker: n2, length: 0, token: t2.tokens.length - 1, end: -1, open: s2.can_open, close: s2.can_close });
    return t2.pos += s2.length, true;
  }, postProcess: function(t2) {
    const e2 = t2.tokens_meta, r2 = t2.tokens_meta.length;
    Kt(t2, t2.delimiters);
    for (let n2 = 0; n2 < r2; n2++) e2[n2] && e2[n2].delimiters && Kt(t2, e2[n2].delimiters);
  } };
  function ee(t2, e2) {
    for (let r2 = e2.length - 1; r2 >= 0; r2--) {
      const n2 = e2[r2];
      if (95 !== n2.marker && 42 !== n2.marker) continue;
      if (-1 === n2.end) continue;
      const s2 = e2[n2.end], i2 = r2 > 0 && e2[r2 - 1].end === n2.end + 1 && e2[r2 - 1].marker === n2.marker && e2[r2 - 1].token === n2.token - 1 && e2[n2.end + 1].token === s2.token + 1, o2 = String.fromCharCode(n2.marker), u2 = t2.tokens[n2.token];
      u2.type = i2 ? "strong_open" : "em_open", u2.tag = i2 ? "strong" : "em", u2.nesting = 1, u2.markup = i2 ? o2 + o2 : o2, u2.content = "";
      const c2 = t2.tokens[s2.token];
      c2.type = i2 ? "strong_close" : "em_close", c2.tag = i2 ? "strong" : "em", c2.nesting = -1, c2.markup = i2 ? o2 + o2 : o2, c2.content = "", i2 && (t2.tokens[e2[r2 - 1].token].content = "", t2.tokens[e2[n2.end + 1].token].content = "", r2--);
    }
  }
  var re = { tokenize: function(t2, e2) {
    const r2 = t2.pos, n2 = t2.src.charCodeAt(r2);
    if (e2) return false;
    if (95 !== n2 && 42 !== n2) return false;
    const s2 = t2.scanDelims(t2.pos, 42 === n2);
    for (let e3 = 0; e3 < s2.length; e3++) {
      t2.push("text", "", 0).content = String.fromCharCode(n2), t2.delimiters.push({ marker: n2, length: s2.length, token: t2.tokens.length - 1, end: -1, open: s2.can_open, close: s2.can_close });
    }
    return t2.pos += s2.length, true;
  }, postProcess: function(t2) {
    const e2 = t2.tokens_meta, r2 = t2.tokens_meta.length;
    ee(t2, t2.delimiters);
    for (let n2 = 0; n2 < r2; n2++) e2[n2] && e2[n2].delimiters && ee(t2, e2[n2].delimiters);
  } };
  const ne = /^([a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)$/, se = /^([a-zA-Z][a-zA-Z0-9+.-]{1,31}):([^<>\x00-\x20]*)$/;
  const ie = /^&#((?:x[a-f0-9]{1,6}|[0-9]{1,7}));/i, oe = /^&([a-z][a-z0-9]{1,31});/i;
  function ue(t2) {
    const e2 = {}, r2 = t2.length;
    if (!r2) return;
    let n2 = 0, s2 = -2;
    const i2 = [];
    for (let o2 = 0; o2 < r2; o2++) {
      const r3 = t2[o2];
      if (i2.push(0), t2[n2].marker === r3.marker && s2 === r3.token - 1 || (n2 = o2), s2 = r3.token, r3.length = r3.length || 0, !r3.close) continue;
      e2.hasOwnProperty(r3.marker) || (e2[r3.marker] = [-1, -1, -1, -1, -1, -1]);
      const u2 = e2[r3.marker][(r3.open ? 3 : 0) + r3.length % 3];
      let c2 = n2 - i2[n2] - 1, a2 = c2;
      for (; c2 > u2; c2 -= i2[c2] + 1) {
        const e3 = t2[c2];
        if (e3.marker === r3.marker && (e3.open && e3.end < 0)) {
          let n3 = false;
          if ((e3.close || r3.open) && (e3.length + r3.length) % 3 == 0 && (e3.length % 3 == 0 && r3.length % 3 == 0 || (n3 = true)), !n3) {
            const n4 = c2 > 0 && !t2[c2 - 1].open ? i2[c2 - 1] + 1 : 0;
            i2[o2] = o2 - c2 + n4, i2[c2] = n4, r3.open = false, e3.end = o2, e3.close = false, a2 = -1, s2 = -2;
            break;
          }
        }
      }
      -1 !== a2 && (e2[r3.marker][(r3.open ? 3 : 0) + (r3.length || 0) % 3] = a2);
    }
  }
  const ce = [["text", function(t2, e2) {
    let r2 = t2.pos;
    for (; r2 < t2.posMax && !Qt(t2.src.charCodeAt(r2)); ) r2++;
    return r2 !== t2.pos && (e2 || (t2.pending += t2.src.slice(t2.pos, r2)), t2.pos = r2, true);
  }], ["linkify", function(t2, e2) {
    if (!t2.md.options.linkify) return false;
    if (t2.linkLevel > 0) return false;
    const r2 = t2.pos;
    if (r2 + 3 > t2.posMax) return false;
    if (58 !== t2.src.charCodeAt(r2)) return false;
    if (47 !== t2.src.charCodeAt(r2 + 1)) return false;
    if (47 !== t2.src.charCodeAt(r2 + 2)) return false;
    const n2 = t2.pending.match(Xt);
    if (!n2) return false;
    const s2 = n2[1], i2 = t2.md.linkify.matchAtStart(t2.src.slice(r2 - s2.length));
    if (!i2) return false;
    let o2 = i2.url;
    if (o2.length <= s2.length) return false;
    let u2 = o2.length;
    for (; u2 > 0 && 42 === o2.charCodeAt(u2 - 1); ) u2--;
    u2 !== o2.length && (o2 = o2.slice(0, u2));
    const c2 = t2.md.normalizeLink(o2);
    if (!t2.md.validateLink(c2)) return false;
    if (!e2) {
      t2.pending = t2.pending.slice(0, -s2.length);
      const e3 = t2.push("link_open", "a", 1);
      e3.attrs = [["href", c2]], e3.markup = "linkify", e3.info = "auto";
      t2.push("text", "", 0).content = t2.md.normalizeLinkText(o2);
      const r3 = t2.push("link_close", "a", -1);
      r3.markup = "linkify", r3.info = "auto";
    }
    return t2.pos += o2.length - s2.length, true;
  }], ["newline", function(t2, e2) {
    let r2 = t2.pos;
    if (10 !== t2.src.charCodeAt(r2)) return false;
    const n2 = t2.pending.length - 1, s2 = t2.posMax;
    if (!e2) if (n2 >= 0 && 32 === t2.pending.charCodeAt(n2)) if (n2 >= 1 && 32 === t2.pending.charCodeAt(n2 - 1)) {
      let e3 = n2 - 1;
      for (; e3 >= 1 && 32 === t2.pending.charCodeAt(e3 - 1); ) e3--;
      t2.pending = t2.pending.slice(0, e3), t2.push("hardbreak", "br", 0);
    } else t2.pending = t2.pending.slice(0, -1), t2.push("softbreak", "br", 0);
    else t2.push("softbreak", "br", 0);
    for (r2++; r2 < s2 && st(t2.src.charCodeAt(r2)); ) r2++;
    return t2.pos = r2, true;
  }], ["escape", function(t2, e2) {
    let r2 = t2.pos;
    const n2 = t2.posMax;
    if (92 !== t2.src.charCodeAt(r2)) return false;
    if (r2++, r2 >= n2) return false;
    let s2 = t2.src.charCodeAt(r2);
    if (10 === s2) {
      for (e2 || t2.push("hardbreak", "br", 0), r2++; r2 < n2 && (s2 = t2.src.charCodeAt(r2), st(s2)); ) r2++;
      return t2.pos = r2, true;
    }
    let i2 = t2.src[r2];
    if (s2 >= 55296 && s2 <= 56319 && r2 + 1 < n2) {
      const e3 = t2.src.charCodeAt(r2 + 1);
      e3 >= 56320 && e3 <= 57343 && (i2 += t2.src[r2 + 1], r2++);
    }
    const o2 = "\\" + i2;
    if (!e2) {
      const e3 = t2.push("text_special", "", 0);
      s2 < 256 && 0 !== Yt[s2] ? e3.content = i2 : e3.content = o2, e3.markup = o2, e3.info = "escape";
    }
    return t2.pos = r2 + 1, true;
  }], ["backticks", function(t2, e2) {
    let r2 = t2.pos;
    if (96 !== t2.src.charCodeAt(r2)) return false;
    const n2 = r2;
    r2++;
    const s2 = t2.posMax;
    for (; r2 < s2 && 96 === t2.src.charCodeAt(r2); ) r2++;
    const i2 = t2.src.slice(n2, r2), o2 = i2.length;
    if (t2.backticksScanned && (t2.backticks[o2] || 0) <= n2) return e2 || (t2.pending += i2), t2.pos += o2, true;
    let u2, c2 = r2;
    for (; -1 !== (u2 = t2.src.indexOf("`", c2)); ) {
      for (c2 = u2 + 1; c2 < s2 && 96 === t2.src.charCodeAt(c2); ) c2++;
      const n3 = c2 - u2;
      if (n3 === o2) {
        if (!e2) {
          const e3 = t2.push("code_inline", "code", 0);
          e3.markup = i2, e3.content = t2.src.slice(r2, u2).replace(/\n/g, " ").replace(/^ (.+) $/, "$1");
        }
        return t2.pos = c2, true;
      }
      t2.backticks[n3] = u2;
    }
    return t2.backticksScanned = true, e2 || (t2.pending += i2), t2.pos += o2, true;
  }], ["strikethrough", te.tokenize], ["emphasis", re.tokenize], ["link", function(t2, e2) {
    let r2, n2, s2, i2, o2 = "", u2 = "", c2 = t2.pos, a2 = true;
    if (91 !== t2.src.charCodeAt(t2.pos)) return false;
    const l2 = t2.pos, h2 = t2.posMax, p2 = t2.pos + 1, f2 = t2.md.helpers.parseLinkLabel(t2, t2.pos, true);
    if (f2 < 0) return false;
    let d2 = f2 + 1;
    if (d2 < h2 && 40 === t2.src.charCodeAt(d2)) {
      for (a2 = false, d2++; d2 < h2 && (r2 = t2.src.charCodeAt(d2), st(r2) || 10 === r2); d2++) ;
      if (d2 >= h2) return false;
      if (c2 = d2, s2 = t2.md.helpers.parseLinkDestination(t2.src, d2, t2.posMax), s2.ok) {
        for (o2 = t2.md.normalizeLink(s2.str), t2.md.validateLink(o2) ? d2 = s2.pos : o2 = "", c2 = d2; d2 < h2 && (r2 = t2.src.charCodeAt(d2), st(r2) || 10 === r2); d2++) ;
        if (s2 = t2.md.helpers.parseLinkTitle(t2.src, d2, t2.posMax), d2 < h2 && c2 !== d2 && s2.ok) for (u2 = s2.str, d2 = s2.pos; d2 < h2 && (r2 = t2.src.charCodeAt(d2), st(r2) || 10 === r2); d2++) ;
      }
      (d2 >= h2 || 41 !== t2.src.charCodeAt(d2)) && (a2 = true), d2++;
    }
    if (a2) {
      if (void 0 === t2.env.references) return false;
      if (d2 < h2 && 91 === t2.src.charCodeAt(d2) ? (c2 = d2 + 1, d2 = t2.md.helpers.parseLinkLabel(t2, d2), d2 >= 0 ? n2 = t2.src.slice(c2, d2++) : d2 = f2 + 1) : d2 = f2 + 1, n2 || (n2 = t2.src.slice(p2, f2)), i2 = t2.env.references[at(n2)], !i2) return t2.pos = l2, false;
      o2 = i2.href, u2 = i2.title;
    }
    if (!e2) {
      t2.pos = p2, t2.posMax = f2;
      const e3 = [["href", o2]];
      t2.push("link_open", "a", 1).attrs = e3, u2 && e3.push(["title", u2]), t2.linkLevel++, t2.md.inline.tokenize(t2), t2.linkLevel--, t2.push("link_close", "a", -1);
    }
    return t2.pos = d2, t2.posMax = h2, true;
  }], ["image", function(t2, e2) {
    let r2, n2, s2, i2, o2, u2, c2, a2, l2 = "";
    const h2 = t2.pos, p2 = t2.posMax;
    if (33 !== t2.src.charCodeAt(t2.pos)) return false;
    if (91 !== t2.src.charCodeAt(t2.pos + 1)) return false;
    const f2 = t2.pos + 2, d2 = t2.md.helpers.parseLinkLabel(t2, t2.pos + 1, false);
    if (d2 < 0) return false;
    if (i2 = d2 + 1, i2 < p2 && 40 === t2.src.charCodeAt(i2)) {
      for (i2++; i2 < p2 && (r2 = t2.src.charCodeAt(i2), st(r2) || 10 === r2); i2++) ;
      if (i2 >= p2) return false;
      for (a2 = i2, u2 = t2.md.helpers.parseLinkDestination(t2.src, i2, t2.posMax), u2.ok && (l2 = t2.md.normalizeLink(u2.str), t2.md.validateLink(l2) ? i2 = u2.pos : l2 = ""), a2 = i2; i2 < p2 && (r2 = t2.src.charCodeAt(i2), st(r2) || 10 === r2); i2++) ;
      if (u2 = t2.md.helpers.parseLinkTitle(t2.src, i2, t2.posMax), i2 < p2 && a2 !== i2 && u2.ok) for (c2 = u2.str, i2 = u2.pos; i2 < p2 && (r2 = t2.src.charCodeAt(i2), st(r2) || 10 === r2); i2++) ;
      else c2 = "";
      if (i2 >= p2 || 41 !== t2.src.charCodeAt(i2)) return t2.pos = h2, false;
      i2++;
    } else {
      if (void 0 === t2.env.references) return false;
      if (i2 < p2 && 91 === t2.src.charCodeAt(i2) ? (a2 = i2 + 1, i2 = t2.md.helpers.parseLinkLabel(t2, i2), i2 >= 0 ? s2 = t2.src.slice(a2, i2++) : i2 = d2 + 1) : i2 = d2 + 1, s2 || (s2 = t2.src.slice(f2, d2)), o2 = t2.env.references[at(s2)], !o2) return t2.pos = h2, false;
      l2 = o2.href, c2 = o2.title;
    }
    if (!e2) {
      n2 = t2.src.slice(f2, d2);
      const e3 = [];
      t2.md.inline.parse(n2, t2.md, t2.env, e3);
      const r3 = t2.push("image", "img", 0), s3 = [["src", l2], ["alt", ""]];
      r3.attrs = s3, r3.children = e3, r3.content = n2, c2 && s3.push(["title", c2]);
    }
    return t2.pos = i2, t2.posMax = p2, true;
  }], ["autolink", function(t2, e2) {
    let r2 = t2.pos;
    if (60 !== t2.src.charCodeAt(r2)) return false;
    const n2 = t2.pos, s2 = t2.posMax;
    for (; ; ) {
      if (++r2 >= s2) return false;
      const e3 = t2.src.charCodeAt(r2);
      if (60 === e3) return false;
      if (62 === e3) break;
    }
    const i2 = t2.src.slice(n2 + 1, r2);
    if (se.test(i2)) {
      const r3 = t2.md.normalizeLink(i2);
      if (!t2.md.validateLink(r3)) return false;
      if (!e2) {
        const e3 = t2.push("link_open", "a", 1);
        e3.attrs = [["href", r3]], e3.markup = "autolink", e3.info = "auto";
        t2.push("text", "", 0).content = t2.md.normalizeLinkText(i2);
        const n3 = t2.push("link_close", "a", -1);
        n3.markup = "autolink", n3.info = "auto";
      }
      return t2.pos += i2.length + 2, true;
    }
    if (ne.test(i2)) {
      const r3 = t2.md.normalizeLink("mailto:" + i2);
      if (!t2.md.validateLink(r3)) return false;
      if (!e2) {
        const e3 = t2.push("link_open", "a", 1);
        e3.attrs = [["href", r3]], e3.markup = "autolink", e3.info = "auto";
        t2.push("text", "", 0).content = t2.md.normalizeLinkText(i2);
        const n3 = t2.push("link_close", "a", -1);
        n3.markup = "autolink", n3.info = "auto";
      }
      return t2.pos += i2.length + 2, true;
    }
    return false;
  }], ["html_inline", function(t2, e2) {
    if (!t2.md.options.html) return false;
    const r2 = t2.posMax, n2 = t2.pos;
    if (60 !== t2.src.charCodeAt(n2) || n2 + 2 >= r2) return false;
    const s2 = t2.src.charCodeAt(n2 + 1);
    if (33 !== s2 && 63 !== s2 && 47 !== s2 && !(function(t3) {
      const e3 = 32 | t3;
      return e3 >= 97 && e3 <= 122;
    })(s2)) return false;
    const i2 = t2.src.slice(n2).match(Ut);
    if (!i2) return false;
    if (!e2) {
      const e3 = t2.push("html_inline", "", 0);
      e3.content = i2[0], o2 = e3.content, /^<a[>\s]/i.test(o2) && t2.linkLevel++, (function(t3) {
        return /^<\/a\s*>/i.test(t3);
      })(e3.content) && t2.linkLevel--;
    }
    var o2;
    return t2.pos += i2[0].length, true;
  }], ["entity", function(t2, e2) {
    const r2 = t2.pos, n2 = t2.posMax;
    if (38 !== t2.src.charCodeAt(r2)) return false;
    if (r2 + 1 >= n2) return false;
    if (35 === t2.src.charCodeAt(r2 + 1)) {
      const n3 = t2.src.slice(r2).match(ie);
      if (n3) {
        if (!e2) {
          const e3 = "x" === n3[1][0].toLowerCase() ? parseInt(n3[1].slice(1), 16) : parseInt(n3[1], 10), r3 = t2.push("text_special", "", 0);
          r3.content = H(e3) ? V(e3) : V(65533), r3.markup = n3[0], r3.info = "entity";
        }
        return t2.pos += n3[0].length, true;
      }
    } else {
      const n3 = t2.src.slice(r2).match(oe);
      if (n3) {
        const r3 = (s2 = n3[0], O(s2, L.Strict));
        if (r3 !== n3[0]) {
          if (!e2) {
            const e3 = t2.push("text_special", "", 0);
            e3.content = r3, e3.markup = n3[0], e3.info = "entity";
          }
          return t2.pos += n3[0].length, true;
        }
      }
    }
    var s2;
    return false;
  }]], ae = [["balance_pairs", function(t2) {
    const e2 = t2.tokens_meta, r2 = t2.tokens_meta.length;
    ue(t2.delimiters);
    for (let t3 = 0; t3 < r2; t3++) e2[t3] && e2[t3].delimiters && ue(e2[t3].delimiters);
  }], ["strikethrough", te.postProcess], ["emphasis", re.postProcess], ["fragments_join", function(t2) {
    let e2, r2, n2 = 0;
    const s2 = t2.tokens, i2 = t2.tokens.length;
    for (e2 = r2 = 0; e2 < i2; e2++) s2[e2].nesting < 0 && n2--, s2[e2].level = n2, s2[e2].nesting > 0 && n2++, "text" === s2[e2].type && e2 + 1 < i2 && "text" === s2[e2 + 1].type ? s2[e2 + 1].content = s2[e2].content + s2[e2 + 1].content : (e2 !== r2 && (s2[r2] = s2[e2]), r2++);
    e2 !== r2 && (s2.length = r2);
  }]];
  function le() {
    this.ruler = new gt();
    for (let t2 = 0; t2 < ce.length; t2++) this.ruler.push(ce[t2][0], ce[t2][1]);
    this.ruler2 = new gt();
    for (let t2 = 0; t2 < ae.length; t2++) this.ruler2.push(ae[t2][0], ae[t2][1]);
  }
  function he(t2) {
    return Array.prototype.slice.call(arguments, 1).forEach(function(e2) {
      e2 && Object.keys(e2).forEach(function(r2) {
        t2[r2] = e2[r2];
      });
    }), t2;
  }
  function pe(t2) {
    return Object.prototype.toString.call(t2);
  }
  function fe(t2) {
    return "[object Function]" === pe(t2);
  }
  function de(t2) {
    return t2.replace(/[.?*+^$[\]\\(){}|-]/g, "\\$&");
  }
  le.prototype.skipToken = function(t2) {
    const e2 = t2.pos, r2 = this.ruler.getRules(""), n2 = r2.length, s2 = t2.md.options.maxNesting, i2 = t2.cache;
    if (void 0 !== i2[e2]) return void (t2.pos = i2[e2]);
    let o2 = false;
    if (t2.level < s2) {
      for (let s3 = 0; s3 < n2; s3++) if (t2.level++, o2 = r2[s3](t2, true), t2.level--, o2) {
        if (e2 >= t2.pos) throw new Error("inline rule didn't increment state.pos");
        break;
      }
    } else t2.pos = t2.posMax;
    o2 || t2.pos++, i2[e2] = t2.pos;
  }, le.prototype.tokenize = function(t2) {
    const e2 = this.ruler.getRules(""), r2 = e2.length, n2 = t2.posMax, s2 = t2.md.options.maxNesting;
    for (; t2.pos < n2; ) {
      const i2 = t2.pos;
      let o2 = false;
      if (t2.level < s2) {
        for (let n3 = 0; n3 < r2; n3++) if (o2 = e2[n3](t2, false), o2) {
          if (i2 >= t2.pos) throw new Error("inline rule didn't increment state.pos");
          break;
        }
      }
      if (o2) {
        if (t2.pos >= n2) break;
      } else t2.pending += t2.src[t2.pos++];
    }
    t2.pending && t2.pushPending();
  }, le.prototype.parse = function(t2, e2, r2, n2) {
    const s2 = new this.State(t2, e2, r2, n2);
    this.tokenize(s2);
    const i2 = this.ruler2.getRules(""), o2 = i2.length;
    for (let t3 = 0; t3 < o2; t3++) i2[t3](s2);
  }, le.prototype.State = Jt;
  const _e = { fuzzyLink: true, fuzzyEmail: true, fuzzyIP: false };
  const me = { "http:": { validate: function(t2, e2, r2) {
    const n2 = t2.slice(e2);
    return r2.re.http || (r2.re.http = new RegExp("^\\/\\/" + r2.re.src_auth + r2.re.src_host_port_strict + r2.re.src_path, "i")), r2.re.http.test(n2) ? n2.match(r2.re.http)[0].length : 0;
  } }, "https:": "http:", "ftp:": "http:", "//": { validate: function(t2, e2, r2) {
    const n2 = t2.slice(e2);
    return r2.re.no_http || (r2.re.no_http = new RegExp("^" + r2.re.src_auth + "(?:localhost|(?:(?:" + r2.re.src_domain + ")\\.)+" + r2.re.src_domain_root + ")" + r2.re.src_port + r2.re.src_host_terminator + r2.re.src_path, "i")), r2.re.no_http.test(n2) ? e2 >= 3 && ":" === t2[e2 - 3] || e2 >= 3 && "/" === t2[e2 - 3] ? 0 : n2.match(r2.re.no_http)[0].length : 0;
  } }, "mailto:": { validate: function(t2, e2, r2) {
    const n2 = t2.slice(e2);
    return r2.re.mailto || (r2.re.mailto = new RegExp("^" + r2.re.src_email_name + "@" + r2.re.src_host_strict, "i")), r2.re.mailto.test(n2) ? n2.match(r2.re.mailto)[0].length : 0;
  } } }, ge = "biz|com|edu|gov|net|org|pro|web|xxx|aero|asia|coop|info|museum|name|shop|\u0440\u0444".split("|");
  function ke(t2) {
    const e2 = t2.re = (function(t3) {
      const e3 = {};
      t3 = t3 || {}, e3.src_Any = C.source, e3.src_Cc = y.source, e3.src_Z = b.source, e3.src_P = E.source, e3.src_ZPCc = [e3.src_Z, e3.src_P, e3.src_Cc].join("|"), e3.src_ZCc = [e3.src_Z, e3.src_Cc].join("|");
      const r3 = "[><\uFF5C]";
      return e3.src_pseudo_letter = "(?:(?![><\uFF5C]|" + e3.src_ZPCc + ")" + e3.src_Any + ")", e3.src_ip4 = "(?:(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)", e3.src_auth = "(?:(?:(?!" + e3.src_ZCc + "|[@/\\[\\]()]).)+@)?", e3.src_port = "(?::(?:6(?:[0-4]\\d{3}|5(?:[0-4]\\d{2}|5(?:[0-2]\\d|3[0-5])))|[1-5]?\\d{1,4}))?", e3.src_host_terminator = "(?=$|[><\uFF5C]|" + e3.src_ZPCc + ")(?!" + (t3["---"] ? "-(?!--)|" : "-|") + "_|:\\d|\\.-|\\.(?!$|" + e3.src_ZPCc + "))", e3.src_path = "(?:[/?#](?:(?!" + e3.src_ZCc + "|" + r3 + `|[()[\\]{}.,"'?!\\-;]).|\\[(?:(?!` + e3.src_ZCc + "|\\]).)*\\]|\\((?:(?!" + e3.src_ZCc + "|[)]).)*\\)|\\{(?:(?!" + e3.src_ZCc + '|[}]).)*\\}|\\"(?:(?!' + e3.src_ZCc + `|["]).)+\\"|\\'(?:(?!` + e3.src_ZCc + "|[']).)+\\'|\\'(?=" + e3.src_pseudo_letter + "|[-])|\\.{2,}[a-zA-Z0-9%/&]|\\.(?!" + e3.src_ZCc + "|[.]|$)|" + (t3["---"] ? "\\-(?!--(?:[^-]|$))(?:-*)|" : "\\-+|") + ",(?!" + e3.src_ZCc + "|$)|;(?!" + e3.src_ZCc + "|$)|\\!+(?!" + e3.src_ZCc + "|[!]|$)|\\?(?!" + e3.src_ZCc + "|[?]|$))+|\\/)?", e3.src_email_name = '[\\-;:&=\\+\\$,\\.a-zA-Z0-9_][\\-;:&=\\+\\$,\\"\\.a-zA-Z0-9_]*', e3.src_xn = "xn--[a-z0-9\\-]{1,59}", e3.src_domain_root = "(?:" + e3.src_xn + "|" + e3.src_pseudo_letter + "{1,63})", e3.src_domain = "(?:" + e3.src_xn + "|(?:" + e3.src_pseudo_letter + ")|(?:" + e3.src_pseudo_letter + "(?:-|" + e3.src_pseudo_letter + "){0,61}" + e3.src_pseudo_letter + "))", e3.src_host = "(?:(?:(?:(?:" + e3.src_domain + ")\\.)*" + e3.src_domain + "))", e3.tpl_host_fuzzy = "(?:" + e3.src_ip4 + "|(?:(?:(?:" + e3.src_domain + ")\\.)+(?:%TLDS%)))", e3.tpl_host_no_ip_fuzzy = "(?:(?:(?:" + e3.src_domain + ")\\.)+(?:%TLDS%))", e3.src_host_strict = e3.src_host + e3.src_host_terminator, e3.tpl_host_fuzzy_strict = e3.tpl_host_fuzzy + e3.src_host_terminator, e3.src_host_port_strict = e3.src_host + e3.src_port + e3.src_host_terminator, e3.tpl_host_port_fuzzy_strict = e3.tpl_host_fuzzy + e3.src_port + e3.src_host_terminator, e3.tpl_host_port_no_ip_fuzzy_strict = e3.tpl_host_no_ip_fuzzy + e3.src_port + e3.src_host_terminator, e3.tpl_host_fuzzy_test = "localhost|www\\.|\\.\\d{1,3}\\.|(?:\\.(?:%TLDS%)(?:" + e3.src_ZPCc + "|>|$))", e3.tpl_email_fuzzy = '(^|[><\uFF5C]|"|\\(|' + e3.src_ZCc + ")(" + e3.src_email_name + "@" + e3.tpl_host_fuzzy_strict + ")", e3.tpl_link_fuzzy = "(^|(?![.:/\\-_@])(?:[$+<=>^`|\uFF5C]|" + e3.src_ZPCc + "))((?![$+<=>^`|\uFF5C])" + e3.tpl_host_port_fuzzy_strict + e3.src_path + ")", e3.tpl_link_no_ip_fuzzy = "(^|(?![.:/\\-_@])(?:[$+<=>^`|\uFF5C]|" + e3.src_ZPCc + "))((?![$+<=>^`|\uFF5C])" + e3.tpl_host_port_no_ip_fuzzy_strict + e3.src_path + ")", e3;
    })(t2.__opts__), r2 = t2.__tlds__.slice();
    function n2(t3) {
      return t3.replace("%TLDS%", e2.src_tlds);
    }
    t2.onCompile(), t2.__tlds_replaced__ || r2.push("a[cdefgilmnoqrstuwxz]|b[abdefghijmnorstvwyz]|c[acdfghiklmnoruvwxyz]|d[ejkmoz]|e[cegrstu]|f[ijkmor]|g[abdefghilmnpqrstuwy]|h[kmnrtu]|i[delmnoqrst]|j[emop]|k[eghimnprwyz]|l[abcikrstuvy]|m[acdeghklmnopqrstuvwxyz]|n[acefgilopruz]|om|p[aefghklmnrstwy]|qa|r[eosuw]|s[abcdeghijklmnortuvxyz]|t[cdfghjklmnortvwz]|u[agksyz]|v[aceginu]|w[fs]|y[et]|z[amw]"), r2.push(e2.src_xn), e2.src_tlds = r2.join("|"), e2.email_fuzzy = RegExp(n2(e2.tpl_email_fuzzy), "i"), e2.link_fuzzy = RegExp(n2(e2.tpl_link_fuzzy), "i"), e2.link_no_ip_fuzzy = RegExp(n2(e2.tpl_link_no_ip_fuzzy), "i"), e2.host_fuzzy_test = RegExp(n2(e2.tpl_host_fuzzy_test), "i");
    const s2 = [];
    function i2(t3, e3) {
      throw new Error('(LinkifyIt) Invalid schema "' + t3 + '": ' + e3);
    }
    t2.__compiled__ = {}, Object.keys(t2.__schemas__).forEach(function(e3) {
      const r3 = t2.__schemas__[e3];
      if (null === r3) return;
      const n3 = { validate: null, link: null };
      if (t2.__compiled__[e3] = n3, "[object Object]" === pe(r3)) return !(function(t3) {
        return "[object RegExp]" === pe(t3);
      })(r3.validate) ? fe(r3.validate) ? n3.validate = r3.validate : i2(e3, r3) : n3.validate = /* @__PURE__ */ (function(t3) {
        return function(e4, r4) {
          const n4 = e4.slice(r4);
          return t3.test(n4) ? n4.match(t3)[0].length : 0;
        };
      })(r3.validate), void (fe(r3.normalize) ? n3.normalize = r3.normalize : r3.normalize ? i2(e3, r3) : n3.normalize = function(t3, e4) {
        e4.normalize(t3);
      });
      !(function(t3) {
        return "[object String]" === pe(t3);
      })(r3) ? i2(e3, r3) : s2.push(e3);
    }), s2.forEach(function(e3) {
      t2.__compiled__[t2.__schemas__[e3]] && (t2.__compiled__[e3].validate = t2.__compiled__[t2.__schemas__[e3]].validate, t2.__compiled__[e3].normalize = t2.__compiled__[t2.__schemas__[e3]].normalize);
    }), t2.__compiled__[""] = { validate: null, normalize: function(t3, e3) {
      e3.normalize(t3);
    } };
    const o2 = Object.keys(t2.__compiled__).filter(function(e3) {
      return e3.length > 0 && t2.__compiled__[e3];
    }).map(de).join("|");
    t2.re.schema_test = RegExp("(^|(?!_)(?:[><\uFF5C]|" + e2.src_ZPCc + "))(" + o2 + ")", "i"), t2.re.schema_search = RegExp("(^|(?!_)(?:[><\uFF5C]|" + e2.src_ZPCc + "))(" + o2 + ")", "ig"), t2.re.schema_at_start = RegExp("^" + t2.re.schema_search.source, "i"), t2.re.pretest = RegExp("(" + t2.re.schema_test.source + ")|(" + t2.re.host_fuzzy_test.source + ")|@", "i"), (function(t3) {
      t3.__index__ = -1, t3.__text_cache__ = "";
    })(t2);
  }
  function De(t2, e2) {
    const r2 = t2.__index__, n2 = t2.__last_index__, s2 = t2.__text_cache__.slice(r2, n2);
    this.schema = t2.__schema__.toLowerCase(), this.index = r2 + e2, this.lastIndex = n2 + e2, this.raw = s2, this.text = s2, this.url = s2;
  }
  function Ce(t2, e2) {
    const r2 = new De(t2, e2);
    return t2.__compiled__[r2.schema].normalize(r2, t2), r2;
  }
  function ye(t2, e2) {
    if (!(this instanceof ye)) return new ye(t2, e2);
    var r2;
    e2 || (r2 = t2, Object.keys(r2 || {}).reduce(function(t3, e3) {
      return t3 || _e.hasOwnProperty(e3);
    }, false) && (e2 = t2, t2 = {})), this.__opts__ = he({}, _e, e2), this.__index__ = -1, this.__last_index__ = -1, this.__schema__ = "", this.__text_cache__ = "", this.__schemas__ = he({}, me, t2), this.__compiled__ = {}, this.__tlds__ = ge, this.__tlds_replaced__ = false, this.re = {}, ke(this);
  }
  ye.prototype.add = function(t2, e2) {
    return this.__schemas__[t2] = e2, ke(this), this;
  }, ye.prototype.set = function(t2) {
    return this.__opts__ = he(this.__opts__, t2), this;
  }, ye.prototype.test = function(t2) {
    if (this.__text_cache__ = t2, this.__index__ = -1, !t2.length) return false;
    let e2, r2, n2, s2, i2, o2, u2, c2, a2;
    if (this.re.schema_test.test(t2)) {
      for (u2 = this.re.schema_search, u2.lastIndex = 0; null !== (e2 = u2.exec(t2)); ) if (s2 = this.testSchemaAt(t2, e2[2], u2.lastIndex), s2) {
        this.__schema__ = e2[2], this.__index__ = e2.index + e2[1].length, this.__last_index__ = e2.index + e2[0].length + s2;
        break;
      }
    }
    return this.__opts__.fuzzyLink && this.__compiled__["http:"] && (c2 = t2.search(this.re.host_fuzzy_test), c2 >= 0 && (this.__index__ < 0 || c2 < this.__index__) && null !== (r2 = t2.match(this.__opts__.fuzzyIP ? this.re.link_fuzzy : this.re.link_no_ip_fuzzy)) && (i2 = r2.index + r2[1].length, (this.__index__ < 0 || i2 < this.__index__) && (this.__schema__ = "", this.__index__ = i2, this.__last_index__ = r2.index + r2[0].length))), this.__opts__.fuzzyEmail && this.__compiled__["mailto:"] && (a2 = t2.indexOf("@"), a2 >= 0 && null !== (n2 = t2.match(this.re.email_fuzzy)) && (i2 = n2.index + n2[1].length, o2 = n2.index + n2[0].length, (this.__index__ < 0 || i2 < this.__index__ || i2 === this.__index__ && o2 > this.__last_index__) && (this.__schema__ = "mailto:", this.__index__ = i2, this.__last_index__ = o2))), this.__index__ >= 0;
  }, ye.prototype.pretest = function(t2) {
    return this.re.pretest.test(t2);
  }, ye.prototype.testSchemaAt = function(t2, e2, r2) {
    return this.__compiled__[e2.toLowerCase()] ? this.__compiled__[e2.toLowerCase()].validate(t2, r2, this) : 0;
  }, ye.prototype.match = function(t2) {
    const e2 = [];
    let r2 = 0;
    this.__index__ >= 0 && this.__text_cache__ === t2 && (e2.push(Ce(this, r2)), r2 = this.__last_index__);
    let n2 = r2 ? t2.slice(r2) : t2;
    for (; this.test(n2); ) e2.push(Ce(this, r2)), n2 = n2.slice(this.__last_index__), r2 += this.__last_index__;
    return e2.length ? e2 : null;
  }, ye.prototype.matchAtStart = function(t2) {
    if (this.__text_cache__ = t2, this.__index__ = -1, !t2.length) return null;
    const e2 = this.re.schema_at_start.exec(t2);
    if (!e2) return null;
    const r2 = this.testSchemaAt(t2, e2[2], e2[0].length);
    return r2 ? (this.__schema__ = e2[2], this.__index__ = e2.index + e2[1].length, this.__last_index__ = e2.index + e2[0].length + r2, Ce(this, 0)) : null;
  }, ye.prototype.tlds = function(t2, e2) {
    return t2 = Array.isArray(t2) ? t2 : [t2], e2 ? (this.__tlds__ = this.__tlds__.concat(t2).sort().filter(function(t3, e3, r2) {
      return t3 !== r2[e3 - 1];
    }).reverse(), ke(this), this) : (this.__tlds__ = t2.slice(), this.__tlds_replaced__ = true, ke(this), this);
  }, ye.prototype.normalize = function(t2) {
    t2.schema || (t2.url = "http://" + t2.url), "mailto:" !== t2.schema || /^mailto:/i.test(t2.url) || (t2.url = "mailto:" + t2.url);
  }, ye.prototype.onCompile = function() {
  };
  const Ee = 2147483647, Ae = 36, be = /^xn--/, Fe = /[^\0-\x7F]/, xe = /[\x2E\u3002\uFF0E\uFF61]/g, we = { overflow: "Overflow: input needs wider integers to process", "not-basic": "Illegal input >= 0x80 (not a basic code point)", "invalid-input": "Invalid input" }, ve = Math.floor, ze = String.fromCharCode;
  function Se(t2) {
    throw new RangeError(we[t2]);
  }
  function qe(t2, e2) {
    const r2 = t2.split("@");
    let n2 = "";
    r2.length > 1 && (n2 = r2[0] + "@", t2 = r2[1]);
    const s2 = (function(t3, e3) {
      const r3 = [];
      let n3 = t3.length;
      for (; n3--; ) r3[n3] = e3(t3[n3]);
      return r3;
    })((t2 = t2.replace(xe, ".")).split("."), e2).join(".");
    return n2 + s2;
  }
  function Be(t2) {
    const e2 = [];
    let r2 = 0;
    const n2 = t2.length;
    for (; r2 < n2; ) {
      const s2 = t2.charCodeAt(r2++);
      if (s2 >= 55296 && s2 <= 56319 && r2 < n2) {
        const n3 = t2.charCodeAt(r2++);
        56320 == (64512 & n3) ? e2.push(((1023 & s2) << 10) + (1023 & n3) + 65536) : (e2.push(s2), r2--);
      } else e2.push(s2);
    }
    return e2;
  }
  const Le = function(t2) {
    return t2 >= 48 && t2 < 58 ? t2 - 48 + 26 : t2 >= 65 && t2 < 91 ? t2 - 65 : t2 >= 97 && t2 < 123 ? t2 - 97 : Ae;
  }, Ie = function(t2, e2) {
    return t2 + 22 + 75 * (t2 < 26) - ((0 != e2) << 5);
  }, Me = function(t2, e2, r2) {
    let n2 = 0;
    for (t2 = r2 ? ve(t2 / 700) : t2 >> 1, t2 += ve(t2 / e2); t2 > 455; n2 += Ae) t2 = ve(t2 / 35);
    return ve(n2 + 36 * t2 / (t2 + 38));
  }, Te = function(t2) {
    const e2 = [], r2 = t2.length;
    let n2 = 0, s2 = 128, i2 = 72, o2 = t2.lastIndexOf("-");
    o2 < 0 && (o2 = 0);
    for (let r3 = 0; r3 < o2; ++r3) t2.charCodeAt(r3) >= 128 && Se("not-basic"), e2.push(t2.charCodeAt(r3));
    for (let u2 = o2 > 0 ? o2 + 1 : 0; u2 < r2; ) {
      const o3 = n2;
      for (let e3 = 1, s3 = Ae; ; s3 += Ae) {
        u2 >= r2 && Se("invalid-input");
        const o4 = Le(t2.charCodeAt(u2++));
        o4 >= Ae && Se("invalid-input"), o4 > ve((Ee - n2) / e3) && Se("overflow"), n2 += o4 * e3;
        const c3 = s3 <= i2 ? 1 : s3 >= i2 + 26 ? 26 : s3 - i2;
        if (o4 < c3) break;
        const a2 = Ae - c3;
        e3 > ve(Ee / a2) && Se("overflow"), e3 *= a2;
      }
      const c2 = e2.length + 1;
      i2 = Me(n2 - o3, c2, 0 == o3), ve(n2 / c2) > Ee - s2 && Se("overflow"), s2 += ve(n2 / c2), n2 %= c2, e2.splice(n2++, 0, s2);
    }
    return String.fromCodePoint(...e2);
  }, Re = function(t2) {
    const e2 = [], r2 = (t2 = Be(t2)).length;
    let n2 = 128, s2 = 0, i2 = 72;
    for (const r3 of t2) r3 < 128 && e2.push(ze(r3));
    const o2 = e2.length;
    let u2 = o2;
    for (o2 && e2.push("-"); u2 < r2; ) {
      let r3 = Ee;
      for (const e3 of t2) e3 >= n2 && e3 < r3 && (r3 = e3);
      const c2 = u2 + 1;
      r3 - n2 > ve((Ee - s2) / c2) && Se("overflow"), s2 += (r3 - n2) * c2, n2 = r3;
      for (const r4 of t2) if (r4 < n2 && ++s2 > Ee && Se("overflow"), r4 === n2) {
        let t3 = s2;
        for (let r5 = Ae; ; r5 += Ae) {
          const n3 = r5 <= i2 ? 1 : r5 >= i2 + 26 ? 26 : r5 - i2;
          if (t3 < n3) break;
          const s3 = t3 - n3, o3 = Ae - n3;
          e2.push(ze(Ie(n3 + s3 % o3, 0))), t3 = ve(s3 / o3);
        }
        e2.push(ze(Ie(t3, 0))), i2 = Me(s2, c2, u2 === o2), s2 = 0, ++u2;
      }
      ++s2, ++n2;
    }
    return e2.join("");
  }, Ne = function(t2) {
    return qe(t2, function(t3) {
      return Fe.test(t3) ? "xn--" + Re(t3) : t3;
    });
  }, Pe = function(t2) {
    return qe(t2, function(t3) {
      return be.test(t3) ? Te(t3.slice(4).toLowerCase()) : t3;
    });
  };
  const Oe = { default: { options: { html: false, xhtmlOut: false, breaks: false, langPrefix: "language-", linkify: false, typographer: false, quotes: "\u201C\u201D\u2018\u2019", highlight: null, maxNesting: 100 }, components: { core: {}, block: {}, inline: {} } }, zero: { options: { html: false, xhtmlOut: false, breaks: false, langPrefix: "language-", linkify: false, typographer: false, quotes: "\u201C\u201D\u2018\u2019", highlight: null, maxNesting: 20 }, components: { core: { rules: ["normalize", "block", "inline", "text_join"] }, block: { rules: ["paragraph"] }, inline: { rules: ["text"], rules2: ["balance_pairs", "fragments_join"] } } }, commonmark: { options: { html: true, xhtmlOut: true, breaks: false, langPrefix: "language-", linkify: false, typographer: false, quotes: "\u201C\u201D\u2018\u2019", highlight: null, maxNesting: 20 }, components: { core: { rules: ["normalize", "block", "inline", "text_join"] }, block: { rules: ["blockquote", "code", "fence", "heading", "hr", "html_block", "lheading", "list", "reference", "paragraph"] }, inline: { rules: ["autolink", "backticks", "emphasis", "entity", "escape", "html_inline", "image", "link", "newline", "text"], rules2: ["balance_pairs", "emphasis", "fragments_join"] } } } }, je = /^(vbscript|javascript|file|data):/, Ze = /^data:image\/(gif|png|jpeg|webp);/;
  function $e(t2) {
    const e2 = t2.trim().toLowerCase();
    return !je.test(e2) || Ze.test(e2);
  }
  const Ue = ["http:", "https:", "mailto:"];
  function He(t2) {
    const e2 = g(t2, true);
    if (e2.hostname && (!e2.protocol || Ue.indexOf(e2.protocol) >= 0)) try {
      e2.hostname = Ne(e2.hostname);
    } catch (t3) {
    }
    return n(s(e2));
  }
  function Ve(t2) {
    const r2 = g(t2, true);
    if (r2.hostname && (!r2.protocol || Ue.indexOf(r2.protocol) >= 0)) try {
      r2.hostname = Pe(r2.hostname);
    } catch (t3) {
    }
    return e(s(r2), e.defaultChars + "%");
  }
  function Ge(t2, e2) {
    if (!(this instanceof Ge)) return new Ge(t2, e2);
    e2 || j(t2) || (e2 = t2 || {}, t2 = "default"), this.inline = new le(), this.block = new Wt(), this.core = new Tt(), this.renderer = new mt(), this.linkify = new ye(), this.validateLink = $e, this.normalizeLink = He, this.normalizeLinkText = Ve, this.utils = ft, this.helpers = $({}, dt), this.options = {}, this.configure(t2), e2 && this.set(e2);
  }
  return Ge.prototype.set = function(t2) {
    return $(this.options, t2), this;
  }, Ge.prototype.configure = function(t2) {
    const e2 = this;
    if (j(t2)) {
      const e3 = t2;
      if (!(t2 = Oe[e3])) throw new Error('Wrong `markdown-it` preset "' + e3 + '", check name');
    }
    if (!t2) throw new Error("Wrong `markdown-it` preset, can't be empty");
    return t2.options && e2.set(t2.options), t2.components && Object.keys(t2.components).forEach(function(r2) {
      t2.components[r2].rules && e2[r2].ruler.enableOnly(t2.components[r2].rules), t2.components[r2].rules2 && e2[r2].ruler2.enableOnly(t2.components[r2].rules2);
    }), this;
  }, Ge.prototype.enable = function(t2, e2) {
    let r2 = [];
    Array.isArray(t2) || (t2 = [t2]), ["core", "block", "inline"].forEach(function(e3) {
      r2 = r2.concat(this[e3].ruler.enable(t2, true));
    }, this), r2 = r2.concat(this.inline.ruler2.enable(t2, true));
    const n2 = t2.filter(function(t3) {
      return r2.indexOf(t3) < 0;
    });
    if (n2.length && !e2) throw new Error("MarkdownIt. Failed to enable unknown rule(s): " + n2);
    return this;
  }, Ge.prototype.disable = function(t2, e2) {
    let r2 = [];
    Array.isArray(t2) || (t2 = [t2]), ["core", "block", "inline"].forEach(function(e3) {
      r2 = r2.concat(this[e3].ruler.disable(t2, true));
    }, this), r2 = r2.concat(this.inline.ruler2.disable(t2, true));
    const n2 = t2.filter(function(t3) {
      return r2.indexOf(t3) < 0;
    });
    if (n2.length && !e2) throw new Error("MarkdownIt. Failed to disable unknown rule(s): " + n2);
    return this;
  }, Ge.prototype.use = function(t2) {
    const e2 = [this].concat(Array.prototype.slice.call(arguments, 1));
    return t2.apply(t2, e2), this;
  }, Ge.prototype.parse = function(t2, e2) {
    if ("string" != typeof t2) throw new Error("Input data should be a String");
    const r2 = new this.core.State(t2, this, e2);
    return this.core.process(r2), r2.tokens;
  }, Ge.prototype.render = function(t2, e2) {
    return e2 = e2 || {}, this.renderer.render(this.parse(t2, e2), this.options, e2);
  }, Ge.prototype.parseInline = function(t2, e2) {
    const r2 = new this.core.State(t2, this, e2);
    return r2.inlineMode = true, this.core.process(r2), r2.tokens;
  }, Ge.prototype.renderInline = function(t2, e2) {
    return e2 = e2 || {}, this.renderer.render(this.parseInline(t2, e2), this.options, e2);
  }, Ge;
});;
(()=>{var k=(e,n)=>()=>{try{return n||e((n={exports:{}}).exports,n),n.exports}catch(t){throw n=0,t}};var fn=k((Rr,En)=>{function rn(e){return e instanceof Map?e.clear=e.delete=e.set=function(){throw new Error("map is read-only")}:e instanceof Set&&(e.add=e.clear=e.delete=function(){throw new Error("set is read-only")}),Object.freeze(e),Object.getOwnPropertyNames(e).forEach(n=>{let t=e[n],a=typeof t;(a==="object"||a==="function")&&!Object.isFrozen(t)&&rn(t)}),e}var Se=class{constructor(n){n.data===void 0&&(n.data={}),this.data=n.data,this.isMatchIgnored=!1}ignoreMatch(){this.isMatchIgnored=!0}};function sn(e){return e.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#x27;")}function re(e,...n){let t=Object.create(null);for(let a in e)t[a]=e[a];return n.forEach(function(a){for(let s in a)t[s]=a[s]}),t}var ma="</span>",Je=e=>!!e.scope,_a=(e,{prefix:n})=>{if(e.startsWith("language:"))return e.replace("language:","language-");if(e.includes(".")){let t=e.split(".");return[`${n}${t.shift()}`,...t.map((a,s)=>`${a}${"_".repeat(s+1)}`)].join(" ")}return`${n}${e}`},Ke=class{constructor(n,t){this.buffer="",this.classPrefix=t.classPrefix,n.walk(this)}addText(n){this.buffer+=sn(n)}openNode(n){if(!Je(n))return;let t=_a(n.scope,{prefix:this.classPrefix});this.span(t)}closeNode(n){Je(n)&&(this.buffer+=ma)}value(){return this.buffer}span(n){this.buffer+=`<span class="${n}">`}},je=(e={})=>{let n={children:[]};return Object.assign(n,e),n},He=class e{constructor(){this.rootNode=je(),this.stack=[this.rootNode]}get top(){return this.stack[this.stack.length-1]}get root(){return this.rootNode}add(n){this.top.children.push(n)}openNode(n){let t=je({scope:n});this.add(t),this.stack.push(t)}closeNode(){if(this.stack.length>1)return this.stack.pop()}closeAllNodes(){for(;this.closeNode(););}toJSON(){return JSON.stringify(this.rootNode,null,4)}walk(n){return this.constructor._walk(n,this.rootNode)}static _walk(n,t){return typeof t=="string"?n.addText(t):t.children&&(n.openNode(t),t.children.forEach(a=>this._walk(n,a)),n.closeNode(t)),n}static _collapse(n){typeof n!="string"&&n.children&&(n.children.every(t=>typeof t=="string")?n.children=[n.children.join("")]:n.children.forEach(t=>{e._collapse(t)}))}},qe=class extends He{constructor(n){super(),this.options=n}addText(n){n!==""&&this.add(n)}startScope(n){this.openNode(n)}endScope(){this.closeNode()}__addSublanguage(n,t){let a=n.root;t&&(a.scope=`language:${t}`),this.add(a)}toHTML(){return new Ke(this,this.options).value()}finalize(){return this.closeAllNodes(),!0}};function _e(e){return e?typeof e=="string"?e:e.source:null}function on(e){return ce("(?=",e,")")}function Ea(e){return ce("(?:",e,")*")}function fa(e){return ce("(?:",e,")?")}function ce(...e){return e.map(t=>_e(t)).join("")}function ha(e){let n=e[e.length-1];return typeof n=="object"&&n.constructor===Object?(e.splice(e.length-1,1),n):{}}function Oe(...e){return"("+(ha(e).capture?"":"?:")+e.map(a=>_e(a)).join("|")+")"}function cn(e){return new RegExp(e.toString()+"|").exec("").length-1}function Na(e,n){let t=e&&e.exec(n);return t&&t.index===0}var ya=new RegExp(Oe(/\[(?:[^\\\]]|\\.)*\]/,/\(\?<(?![=!])[^>]+>/,/\(\?'[^']+'/,/\(\??/,/\\([1-9][0-9]*)/,/\\./));function We(e,{joinWith:n}){let t=0;return e.map(a=>{t+=1;let s=t,u=_e(a),r="";for(;u.length>0;){let i=ya.exec(u);if(!i){r+=u;break}r+=u.substring(0,i.index),u=u.substring(i.index+i[0].length),i[0][0]==="\\"&&i[1]?r+="\\"+String(Number(i[1])+s):(r+=i[0],(i[0]==="("||/^\(\?[<']/.test(i[0]))&&t++)}return r}).map(a=>`(${a})`).join(n)}var Ta=/\b\B/,ln="[a-zA-Z]\\w*",Ye="[a-zA-Z_]\\w*",dn="\\b\\d+(\\.\\d+)?",un="(-?)(\\b0[xX][a-fA-F0-9]+|(\\b\\d+(\\.\\d*)?|\\.\\d+)([eE][-+]?\\d+)?)",gn="\\b(0b[01]+)",va="!|!=|!==|%|%=|&|&&|&=|\\*|\\*=|\\+|\\+=|,|-|-=|/=|/|:|;|<<|<<=|<=|<|===|==|=|>>>=|>>=|>=|>>>|>>|>|\\?|\\[|\\{|\\(|\\^|\\^=|\\||\\|=|\\|\\||~",Sa=(e={})=>{let n=/^#![ ]*\//;return e.binary&&(e.begin=ce(n,/.*\b/,e.binary,/\b.*/)),re({scope:"meta",begin:n,end:/$/,relevance:0,"on:begin":(t,a)=>{t.index!==0&&a.ignoreMatch()}},e)},Ee={begin:"\\\\[\\s\\S]",relevance:0},Aa={scope:"string",begin:"'",end:"'",illegal:"\\n",contains:[Ee]},Oa={scope:"string",begin:'"',end:'"',illegal:"\\n",contains:[Ee]},wa={begin:/\b(a|an|the|are|I'm|isn't|don't|doesn't|won't|but|just|should|pretty|simply|enough|gonna|going|wtf|so|such|will|you|your|they|like|more)\b/},we=function(e,n,t={}){let a=re({scope:"comment",begin:e,end:n,contains:[]},t);a.contains.push({scope:"doctag",begin:"[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)",end:/(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):/,excludeBegin:!0,relevance:0});let s=Oe("I","a","is","so","us","to","at","if","in","it","on",/[A-Za-z]+['](d|ve|re|ll|t|s|n)/,/[A-Za-z]+[-][a-z]+/,/[A-Za-z][a-z]{2,}/);return a.contains.push({begin:ce(/[ ]+/,"(",s,/[.]?[:]?([.][ ]|[ ])/,"){3}")}),a},Ra=we("//","$"),Ma=we("/\\*","\\*/"),ka=we("#","$"),xa={scope:"number",begin:dn,relevance:0},Ca={scope:"number",begin:un,relevance:0},Ia={scope:"number",begin:gn,relevance:0},Da={scope:"regexp",begin:/\/(?=[^/\n]*\/)/,end:/\/[gimuy]*/,contains:[Ee,{begin:/\[/,end:/\]/,relevance:0,contains:[Ee]}]},La={scope:"title",begin:ln,relevance:0},Ba={scope:"title",begin:Ye,relevance:0},Ua={begin:"\\.\\s*"+Ye,relevance:0},Pa=function(e){return Object.assign(e,{"on:begin":(n,t)=>{t.data._beginMatch=n[1]},"on:end":(n,t)=>{t.data._beginMatch!==n[1]&&t.ignoreMatch()}})},ve=Object.freeze({__proto__:null,APOS_STRING_MODE:Aa,BACKSLASH_ESCAPE:Ee,BINARY_NUMBER_MODE:Ia,BINARY_NUMBER_RE:gn,COMMENT:we,C_BLOCK_COMMENT_MODE:Ma,C_LINE_COMMENT_MODE:Ra,C_NUMBER_MODE:Ca,C_NUMBER_RE:un,END_SAME_AS_BEGIN:Pa,HASH_COMMENT_MODE:ka,IDENT_RE:ln,MATCH_NOTHING_RE:Ta,METHOD_GUARD:Ua,NUMBER_MODE:xa,NUMBER_RE:dn,PHRASAL_WORDS_MODE:wa,QUOTE_STRING_MODE:Oa,REGEXP_MODE:Da,RE_STARTERS_RE:va,SHEBANG:Sa,TITLE_MODE:La,UNDERSCORE_IDENT_RE:Ye,UNDERSCORE_TITLE_MODE:Ba});function Fa(e,n){e.input[e.index-1]==="."&&n.ignoreMatch()}function za(e,n){e.className!==void 0&&(e.scope=e.className,delete e.className)}function $a(e,n){n&&e.beginKeywords&&(e.begin="\\b("+e.beginKeywords.split(" ").join("|")+")(?!\\.)(?=\\b|\\s)",e.__beforeBegin=Fa,e.keywords=e.keywords||e.beginKeywords,delete e.beginKeywords,e.relevance===void 0&&(e.relevance=0))}function Ga(e,n){Array.isArray(e.illegal)&&(e.illegal=Oe(...e.illegal))}function Ka(e,n){if(e.match){if(e.begin||e.end)throw new Error("begin & end are not supported with match");e.begin=e.match,delete e.match}}function Ha(e,n){e.relevance===void 0&&(e.relevance=1)}var qa=(e,n)=>{if(!e.beforeMatch)return;if(e.starts)throw new Error("beforeMatch cannot be used with starts");let t=Object.assign({},e);Object.keys(e).forEach(a=>{delete e[a]}),e.keywords=t.keywords,e.begin=ce(t.beforeMatch,on(t.begin)),e.starts={relevance:0,contains:[Object.assign(t,{endsParent:!0})]},e.relevance=0,delete t.beforeMatch},Za=["of","and","for","in","not","or","if","then","parent","list","value"],Wa="keyword";function bn(e,n,t=Wa){let a=Object.create(null);return typeof e=="string"?s(t,e.split(" ")):Array.isArray(e)?s(t,e):Object.keys(e).forEach(function(u){Object.assign(a,bn(e[u],n,u))}),a;function s(u,r){n&&(r=r.map(i=>i.toLowerCase())),r.forEach(function(i){let o=i.split("|");a[o[0]]=[u,Ya(o[0],o[1])]})}}function Ya(e,n){return n?Number(n):Xa(e)?0:1}function Xa(e){return Za.includes(e.toLowerCase())}var en={},oe=e=>{console.error(e)},nn=(e,...n)=>{console.log(`WARN: ${e}`,...n)},ue=(e,n)=>{en[`${e}/${n}`]||(console.log(`Deprecated as of ${e}. ${n}`),en[`${e}/${n}`]=!0)},Ae=new Error;function pn(e,n,{key:t}){let a=0,s=e[t],u={},r={};for(let i=1;i<=n.length;i++)r[i+a]=s[i],u[i+a]=!0,a+=cn(n[i-1]);e[t]=r,e[t]._emit=u,e[t]._multi=!0}function Va(e){if(Array.isArray(e.begin)){if(e.skip||e.excludeBegin||e.returnBegin)throw oe("skip, excludeBegin, returnBegin not compatible with beginScope: {}"),Ae;if(typeof e.beginScope!="object"||e.beginScope===null)throw oe("beginScope must be object"),Ae;pn(e,e.begin,{key:"beginScope"}),e.begin=We(e.begin,{joinWith:""})}}function Qa(e){if(Array.isArray(e.end)){if(e.skip||e.excludeEnd||e.returnEnd)throw oe("skip, excludeEnd, returnEnd not compatible with endScope: {}"),Ae;if(typeof e.endScope!="object"||e.endScope===null)throw oe("endScope must be object"),Ae;pn(e,e.end,{key:"endScope"}),e.end=We(e.end,{joinWith:""})}}function Ja(e){e.scope&&typeof e.scope=="object"&&e.scope!==null&&(e.beginScope=e.scope,delete e.scope)}function ja(e){Ja(e),typeof e.beginScope=="string"&&(e.beginScope={_wrap:e.beginScope}),typeof e.endScope=="string"&&(e.endScope={_wrap:e.endScope}),Va(e),Qa(e)}function ei(e){function n(r,i){return new RegExp(_e(r),"m"+(e.case_insensitive?"i":"")+(e.unicodeRegex?"u":"")+(i?"g":""))}class t{constructor(){this.matchIndexes={},this.regexes=[],this.matchAt=1,this.position=0}addRule(i,o){o.position=this.position++,this.matchIndexes[this.matchAt]=o,this.regexes.push([o,i]),this.matchAt+=cn(i)+1}compile(){this.regexes.length===0&&(this.exec=()=>null);let i=this.regexes.map(o=>o[1]);this.matcherRe=n(We(i,{joinWith:"|"}),!0),this.lastIndex=0}exec(i){this.matcherRe.lastIndex=this.lastIndex;let o=this.matcherRe.exec(i);if(!o)return null;let c=o.findIndex((m,g)=>g>0&&m!==void 0),d=this.matchIndexes[c];return o.splice(0,c),Object.assign(o,d)}}class a{constructor(){this.rules=[],this.multiRegexes=[],this.count=0,this.lastIndex=0,this.regexIndex=0}getMatcher(i){if(this.multiRegexes[i])return this.multiRegexes[i];let o=new t;return this.rules.slice(i).forEach(([c,d])=>o.addRule(c,d)),o.compile(),this.multiRegexes[i]=o,o}resumingScanAtSamePosition(){return this.regexIndex!==0}considerAll(){this.regexIndex=0}addRule(i,o){this.rules.push([i,o]),o.type==="begin"&&this.count++}exec(i){let o=this.getMatcher(this.regexIndex);o.lastIndex=this.lastIndex;let c=o.exec(i);if(this.resumingScanAtSamePosition()&&!(c&&c.index===this.lastIndex)){let d=this.getMatcher(0);d.lastIndex=this.lastIndex+1,c=d.exec(i)}return c&&(this.regexIndex+=c.position+1,this.regexIndex===this.count&&this.considerAll()),c}}function s(r){let i=new a;return r.contains.forEach(o=>i.addRule(o.begin,{rule:o,type:"begin"})),r.terminatorEnd&&i.addRule(r.terminatorEnd,{type:"end"}),r.illegal&&i.addRule(r.illegal,{type:"illegal"}),i}function u(r,i){let o=r;if(r.isCompiled)return o;[za,Ka,ja,qa].forEach(d=>d(r,i)),e.compilerExtensions.forEach(d=>d(r,i)),r.__beforeBegin=null,[$a,Ga,Ha].forEach(d=>d(r,i)),r.isCompiled=!0;let c=null;return typeof r.keywords=="object"&&r.keywords.$pattern&&(r.keywords=Object.assign({},r.keywords),c=r.keywords.$pattern,delete r.keywords.$pattern),c=c||/\w+/,r.keywords&&(r.keywords=bn(r.keywords,e.case_insensitive)),o.keywordPatternRe=n(c,!0),i&&(r.begin||(r.begin=/\B|\b/),o.beginRe=n(o.begin),!r.end&&!r.endsWithParent&&(r.end=/\B|\b/),r.end&&(o.endRe=n(o.end)),o.terminatorEnd=_e(o.end)||"",r.endsWithParent&&i.terminatorEnd&&(o.terminatorEnd+=(r.end?"|":"")+i.terminatorEnd)),r.illegal&&(o.illegalRe=n(r.illegal)),r.contains||(r.contains=[]),r.contains=[].concat(...r.contains.map(function(d){return ni(d==="self"?r:d)})),r.contains.forEach(function(d){u(d,o)}),r.starts&&u(r.starts,i),o.matcher=s(o),o}if(e.compilerExtensions||(e.compilerExtensions=[]),e.contains&&e.contains.includes("self"))throw new Error("ERR: contains `self` is not supported at the top-level of a language.  See documentation.");return e.classNameAliases=re(e.classNameAliases||{}),u(e)}function mn(e){return e?e.endsWithParent||mn(e.starts):!1}function ni(e){return e.variants&&!e.cachedVariants&&(e.cachedVariants=e.variants.map(function(n){return re(e,{variants:null},n)})),e.cachedVariants?e.cachedVariants:mn(e)?re(e,{starts:e.starts?re(e.starts):null}):Object.isFrozen(e)?re(e):e}var ti="11.12.0",Ze=class extends Error{constructor(n,t){super(n),this.name="HTMLInjectionError",this.html=t}},Ge=sn,tn=re,an=Symbol("nomatch"),ai=7,_n=function(e){let n=Object.create(null),t=Object.create(null),a=[],s=!0,u="Could not find the language '{}', did you forget to load/include a language module?",r={disableAutodetect:!0,name:"Plain text",contains:[]},i={ignoreUnescapedHTML:!1,throwUnescapedHTML:!1,noHighlightRe:/^(no-?highlight)$/i,languageDetectRe:/\blang(?:uage)?-([\w-]+)\b/i,classPrefix:"hljs-",cssSelector:"pre code",languages:null,__emitter:qe};function o(l){return i.noHighlightRe.test(l)}function c(l){let _=l.className+" ";_+=l.parentNode?l.parentNode.className:"";let E=i.languageDetectRe.exec(_);if(E){let w=D(E[1]);return w||(nn(u.replace("{}",E[1])),nn("Falling back to no-highlight mode for this block.",l)),w?E[1]:"no-highlight"}return _.split(/\s+/).find(w=>o(w)||D(w))}function d(l,_,E){let w="",B="";typeof _=="object"?(w=l,E=_.ignoreIllegals,B=_.language):(ue("10.7.0","highlight(lang, code, ...args) has been deprecated."),ue("10.7.0",`Please use highlight(code, options) instead.
https://github.com/highlightjs/highlight.js/issues/2277`),B=l,w=_),E===void 0&&(E=!0);let $={code:w,language:B};q("before:highlight",$);let K=$.result?$.result:m($.language,$.code,E);return K.code=$.code,q("after:highlight",K),K}function m(l,_,E,w){let B=Object.create(null);function $(b,f){return b.keywords[f]}function K(){if(!v.keywords){W.addText(G);return}let b=0;v.keywordPatternRe.lastIndex=0;let f=v.keywordPatternRe.exec(G),I="";for(;f;){I+=G.substring(b,f.index);let P=ee.case_insensitive?f[0].toLowerCase():f[0],Y=$(v,P);if(Y){let[ae,ba]=Y;if(W.addText(I),I="",B[P]=(B[P]||0)+1,B[P]<=ai&&(Te+=ba),ae.startsWith("_"))I+=f[0];else{let pa=ee.classNameAliases[ae]||ae;Q(f[0],pa)}}else I+=f[0];b=v.keywordPatternRe.lastIndex,f=v.keywordPatternRe.exec(G)}I+=G.substring(b),W.addText(I)}function j(){if(G==="")return;let b=null;if(typeof v.subLanguage=="string"){if(!n[v.subLanguage]){W.addText(G);return}b=m(v.subLanguage,G,!0,ye[v.subLanguage]),ye[v.subLanguage]=b._top}else b=p(G,v.subLanguage.length?v.subLanguage:null);v.relevance>0&&(Te+=b.relevance),W.__addSublanguage(b._emitter,b.language)}function V(){v.subLanguage!=null?j():K(),G=""}function Q(b,f){b!==""&&(W.startScope(f),W.addText(b),W.endScope())}function le(b,f){let I=1,P=f.length-1;for(;I<=P;){if(!b._emit[I]){I++;continue}let Y=ee.classNameAliases[b[I]]||b[I],ae=f[I];Y?Q(ae,Y):(G=ae,K(),G=""),I++}}function he(b,f){return b.scope&&typeof b.scope=="string"&&W.openNode(ee.classNameAliases[b.scope]||b.scope),b.beginScope&&(b.beginScope._wrap?(Q(G,ee.classNameAliases[b.beginScope._wrap]||b.beginScope._wrap),G=""):b.beginScope._multi&&(le(b.beginScope,f),G="")),v=Object.create(b,{parent:{value:v}}),v}function me(b,f,I){let P=Na(b.endRe,I);if(P){if(b["on:end"]){let Y=new Se(b);b["on:end"](f,Y),Y.isMatchIgnored&&(P=!1)}if(P){for(;b.endsParent&&b.parent;)b=b.parent;return b}}if(b.endsWithParent)return me(b.parent,f,I)}function Be(b){return v.matcher.regexIndex===0?(G+=b[0],1):($e=!0,0)}function Ue(b){let f=b[0],I=b.rule,P=new Se(I),Y=[I.__beforeBegin,I["on:begin"]];for(let ae of Y)if(ae&&(ae(b,P),P.isMatchIgnored))return Be(f);return I.skip?G+=f:(I.excludeBegin&&(G+=f),V(),!I.returnBegin&&!I.excludeBegin&&(G=f)),he(I,b),I.returnBegin?0:f.length}function Pe(b){let f=b[0],I=_.substring(b.index),P=me(v,b,I);if(!P)return an;let Y=v;v.endScope&&v.endScope._wrap?(V(),Q(f,v.endScope._wrap)):v.endScope&&v.endScope._multi?(V(),le(v.endScope,b)):Y.skip?G+=f:(Y.returnEnd||Y.excludeEnd||(G+=f),V(),Y.excludeEnd&&(G=f));do v.scope&&W.closeNode(),!v.skip&&!v.subLanguage&&(Te+=v.relevance),v=v.parent;while(v!==P.parent);return P.starts&&he(P.starts,b),Y.returnEnd?0:f.length}function Fe(){let b=[];for(let f=v;f!==ee;f=f.parent)f.scope&&b.unshift(f.scope);b.forEach(f=>W.openNode(f))}let de={};function Ne(b,f){let I=f&&f[0];if(G+=b,I==null)return V(),0;if(de.type==="begin"&&f.type==="end"&&de.index===f.index&&I===""){if(G+=_.slice(f.index,f.index+1),!s){let P=new Error(`0 width match regex (${l})`);throw P.languageName=l,P.badRule=de.rule,P}return 1}if(de=f,f.type==="begin")return Ue(f);if(f.type==="illegal"&&!E){let P=new Error('Illegal lexeme "'+I+'" for mode "'+(v.scope||"<unnamed>")+'"');throw P.mode=v,P}else if(f.type==="end"){let P=Pe(f);if(P!==an)return P}if(f.type==="illegal"&&I==="")return f.index===_.length||(G+=`
`),1;if(ze>1e5&&ze>f.index*3)throw new Error("potential infinite loop, way more iterations than matches");return G+=I,I.length}let ee=D(l);if(!ee)throw oe(u.replace("{}",l)),new Error('Unknown language: "'+l+'"');let F=ei(ee),ie="",v=w||F,ye={},W=new i.__emitter(i);Fe();let G="",Te=0,se=0,ze=0,$e=!1;try{if(ee.__emitTokens)ee.__emitTokens(_,W);else{for(v.matcher.considerAll();;){ze++,$e?$e=!1:v.matcher.considerAll(),v.matcher.lastIndex=se;let b=v.matcher.exec(_);if(!b)break;let f=_.substring(se,b.index),I=Ne(f,b);se=b.index+I}Ne(_.substring(se))}return W.finalize(),ie=W.toHTML(),{language:l,value:ie,relevance:Te,illegal:!1,_emitter:W,_top:v}}catch(b){if(b.message&&b.message.includes("Illegal"))return{language:l,value:Ge(_),illegal:!0,relevance:0,_illegalBy:{message:b.message,index:se,context:_.slice(se-100,se+100),mode:b.mode,resultSoFar:ie},_emitter:W};if(s)return{language:l,value:Ge(_),illegal:!1,relevance:0,errorRaised:b,_emitter:W,_top:v};throw b}}function g(l){let _={value:Ge(l),illegal:!1,relevance:0,_top:r,_emitter:new i.__emitter(i)};return _._emitter.addText(l),_}function p(l,_){_=_||i.languages||Object.keys(n);let E=g(l),w=_.filter(D).filter(O).map(V=>m(V,l,!1));w.unshift(E);let B=w.sort((V,Q)=>{if(V.relevance!==Q.relevance)return Q.relevance-V.relevance;if(V.language&&Q.language){if(D(V.language).supersetOf===Q.language)return 1;if(D(Q.language).supersetOf===V.language)return-1}return 0}),[$,K]=B,j=$;return j.secondBest=K,j}function y(l,_,E){let w=_&&t[_]||E;l.classList.add("hljs"),l.classList.add(`language-${w}`)}function h(l){let _=null,E=c(l);if(o(E))return;if(q("before:highlightElement",{el:l,language:E}),l.dataset.highlighted){console.log("Element previously highlighted. To highlight again, first unset `dataset.highlighted`.",l);return}if(l.children.length>0&&(i.ignoreUnescapedHTML||(console.warn("One of your code blocks includes unescaped HTML. This is a potentially serious security risk."),console.warn("https://github.com/highlightjs/highlight.js/wiki/security"),console.warn("The element with unescaped HTML:"),console.warn(l)),i.throwUnescapedHTML))throw new Ze("One of your code blocks includes unescaped HTML.",l.innerHTML);_=l;let w=_.textContent,B=E?d(w,{language:E,ignoreIllegals:!0}):p(w);l.innerHTML=B.value,l.dataset.highlighted="yes",y(l,E,B.language),l.result={language:B.language,re:B.relevance,relevance:B.relevance},B.secondBest&&(l.secondBest={language:B.secondBest.language,relevance:B.secondBest.relevance}),q("after:highlightElement",{el:l,result:B,text:w})}function T(l){i=tn(i,l)}let N=()=>{S(),ue("10.6.0","initHighlighting() deprecated.  Use highlightAll() now.")};function C(){S(),ue("10.6.0","initHighlightingOnLoad() deprecated.  Use highlightAll() now.")}let R=!1;function S(){function l(){S()}if(document.readyState==="loading"){R||window.addEventListener("DOMContentLoaded",l,!1),R=!0;return}document.querySelectorAll(i.cssSelector).forEach(h)}function A(l,_){let E=null;try{E=_(e)}catch(w){if(oe("Language definition for '{}' could not be registered.".replace("{}",l)),s)oe(w);else throw w;E=r}E.name||(E.name=l),n[l]=E,E.rawDefinition=_.bind(null,e),E.aliases&&U(E.aliases,{languageName:l})}function M(l){delete n[l];for(let _ of Object.keys(t))t[_]===l&&delete t[_]}function L(){return Object.keys(n)}function D(l){return l=(l||"").toLowerCase(),n[l]||n[t[l]]}function U(l,{languageName:_}){typeof l=="string"&&(l=[l]),l.forEach(E=>{t[E.toLowerCase()]=_})}function O(l){let _=D(l);return _&&!_.disableAutodetect}function H(l){l["before:highlightBlock"]&&!l["before:highlightElement"]&&(l["before:highlightElement"]=_=>{l["before:highlightBlock"](Object.assign({block:_.el},_))}),l["after:highlightBlock"]&&!l["after:highlightElement"]&&(l["after:highlightElement"]=_=>{l["after:highlightBlock"](Object.assign({block:_.el},_))})}function J(l){H(l),a.push(l)}function ne(l){let _=a.indexOf(l);_!==-1&&a.splice(_,1)}function q(l,_){let E=l;a.forEach(function(w){w[E]&&w[E](_)})}function Z(l){return ue("10.7.0","highlightBlock will be removed entirely in v12.0"),ue("10.7.0","Please use highlightElement now."),h(l)}Object.assign(e,{highlight:d,highlightAuto:p,highlightAll:S,highlightElement:h,highlightBlock:Z,configure:T,initHighlighting:N,initHighlightingOnLoad:C,registerLanguage:A,unregisterLanguage:M,listLanguages:L,getLanguage:D,registerAliases:U,autoDetection:O,inherit:tn,addPlugin:J,removePlugin:ne}),e.debugMode=function(){s=!1},e.safeMode=function(){s=!0},e.versionString=ti,e.regex={concat:ce,lookahead:on,either:Oe,optional:fa,anyNumberOfTimes:Ea};for(let l in ve)typeof ve[l]=="object"&&rn(ve[l]);return Object.assign(e,ve),e},ge=_n({});ge.newInstance=()=>_n({});En.exports=ge;ge.HighlightJS=ge;ge.default=ge});var Nn=k((Mr,hn)=>{function ii(e){let n=e.regex,t=n.concat(/[\p{L}_]/u,n.optional(/[\p{L}0-9_.-]*:/u),/[\p{L}0-9_.-]*/u),a=/[\p{L}0-9._:-]+/u,s={className:"symbol",begin:/&[a-z]+;|&#[0-9]+;|&#x[a-f0-9]+;/},u={begin:/\s/,contains:[{className:"keyword",begin:/#?[a-z_][a-z1-9_-]+/,illegal:/\n/}]},r=e.inherit(u,{begin:/\(/,end:/\)/}),i=e.inherit(e.APOS_STRING_MODE,{className:"string"}),o=e.inherit(e.QUOTE_STRING_MODE,{className:"string"}),c={endsWithParent:!0,illegal:/</,relevance:0,contains:[{className:"attr",begin:a,relevance:0},{begin:/=\s*/,relevance:0,contains:[{className:"string",endsParent:!0,variants:[{begin:/"/,end:/"/,contains:[s]},{begin:/'/,end:/'/,contains:[s]},{begin:/[^\s"'=<>`]+/}]}]}]};return{name:"HTML, XML",aliases:["html","xhtml","rss","atom","xjb","xsd","xsl","plist","wsf","svg"],case_insensitive:!0,unicodeRegex:!0,contains:[{className:"meta",begin:/<![a-z]/,end:/>/,relevance:10,contains:[u,o,i,r,{begin:/\[/,end:/\]/,contains:[{className:"meta",begin:/<![a-z]/,end:/>/,contains:[u,r,o,i]}]}]},e.COMMENT(/<\!--/,/-->/,{relevance:10}),{begin:/<!\[CDATA\[/,end:/\]\]>/,relevance:10},s,{className:"meta",end:/\?>/,variants:[{begin:/<\?xml/,relevance:10,contains:[o]},{begin:/<\?[a-z][a-z0-9]+/}]},{className:"tag",begin:/<style(?=\s|>)/,end:/>/,keywords:{name:"style"},contains:[c],starts:{end:/<\/style>/,returnEnd:!0,subLanguage:"css"}},{className:"tag",begin:/<script(?=\s|>)/,end:/>/,keywords:{name:"script"},contains:[c],starts:{end:/<\/script>/,returnEnd:!0,subLanguage:"javascript"}},{className:"tag",begin:/<>|<\/>/},{className:"tag",begin:n.concat(/</,n.lookahead(n.concat(t,n.either(/\/>/,/>/,/\s/)))),end:/\/?>/,contains:[{className:"name",begin:t,relevance:0,starts:c}]},{className:"tag",begin:n.concat(/<\//,n.lookahead(n.concat(t,/>/))),contains:[{className:"name",begin:t,relevance:0},{begin:/>/,relevance:0,endsParent:!0}]}]}}hn.exports=ii});var Tn=k((kr,yn)=>{function ri(e){let n=e.regex,t={},a={begin:/\$\{/,end:/\}/,contains:["self",{begin:/:-/,contains:[t]}]};Object.assign(t,{className:"variable",variants:[{begin:n.concat(/\$[\w\d#@][\w\d_]*/,"(?![\\w\\d])(?![$])")},a]});let s={className:"subst",begin:/\$\(/,end:/\)/,contains:[e.BACKSLASH_ESCAPE]},u=e.inherit(e.COMMENT(),{match:[/(^|\s)/,/#.*$/],scope:{2:"comment"}}),r={begin:/<<-?\s*(?=\w+)/,starts:{contains:[e.END_SAME_AS_BEGIN({begin:/(\w+)/,end:/(\w+)/,className:"string"})]}},i={className:"string",begin:/"/,end:/"/,contains:[e.BACKSLASH_ESCAPE,t,s]};s.contains.push(i);let o={match:/\\"/},c={className:"string",begin:/'/,end:/'/},d={match:/\\'/},m={begin:/\$?\(\(/,end:/\)\)/,contains:[{begin:/\d+#[0-9a-f]+/,className:"number"},e.NUMBER_MODE,t]},g=["fish","bash","zsh","sh","csh","ksh","tcsh","dash","scsh"],p=e.SHEBANG({binary:`(${g.join("|")})`,relevance:10}),y={className:"function",begin:/\w[\w\d_]*\s*\(\s*\)\s*\{/,returnBegin:!0,contains:[e.inherit(e.TITLE_MODE,{begin:/\w[\w\d_]*/})],relevance:0},h=["if","then","else","elif","fi","time","for","while","until","in","do","done","case","esac","coproc","function","select"],T=["true","false"],N={match:/(\/[a-z._-]+)+/},C=["break","cd","continue","eval","exec","exit","export","getopts","hash","pwd","readonly","return","shift","test","times","trap","umask","unset"],R=["alias","bind","builtin","caller","command","declare","echo","enable","help","let","local","logout","mapfile","printf","read","readarray","source","sudo","type","typeset","ulimit","unalias"],S=["autoload","bg","bindkey","bye","cap","chdir","clone","comparguments","compcall","compctl","compdescribe","compfiles","compgroups","compquote","comptags","comptry","compvalues","dirs","disable","disown","echotc","echoti","emulate","fc","fg","float","functions","getcap","getln","history","integer","jobs","kill","limit","log","noglob","popd","print","pushd","pushln","rehash","sched","setcap","setopt","stat","suspend","ttyctl","unfunction","unhash","unlimit","unsetopt","vared","wait","whence","where","which","zcompile","zformat","zftp","zle","zmodload","zparseopts","zprof","zpty","zregexparse","zsocket","zstyle","ztcp"],A=["chcon","chgrp","chown","chmod","cp","dd","df","dir","dircolors","ln","ls","mkdir","mkfifo","mknod","mktemp","mv","realpath","rm","rmdir","shred","sync","touch","truncate","vdir","b2sum","base32","base64","cat","cksum","comm","csplit","cut","expand","fmt","fold","head","join","md5sum","nl","numfmt","od","paste","ptx","pr","sha1sum","sha224sum","sha256sum","sha384sum","sha512sum","shuf","sort","split","sum","tac","tail","tr","tsort","unexpand","uniq","wc","arch","basename","chroot","date","dirname","du","echo","env","expr","factor","groups","hostid","id","link","logname","nice","nohup","nproc","pathchk","pinky","printenv","printf","pwd","readlink","runcon","seq","sleep","stat","stdbuf","stty","tee","test","timeout","tty","uname","unlink","uptime","users","who","whoami","yes"];return{name:"Bash",aliases:["sh","zsh"],keywords:{$pattern:/\b[a-z][a-z0-9._-]+\b/,keyword:h,literal:T,built_in:[...C,...R,"set","shopt",...S,...A]},contains:[p,e.SHEBANG(),y,m,u,r,N,i,o,c,d,t]}}yn.exports=ri});var Sn=k((xr,vn)=>{function si(e){let n=e.regex,t=e.COMMENT("//","$",{contains:[{begin:/\\\n/}]}),a="decltype\\(auto\\)",s="[a-zA-Z_]\\w*::",r="("+a+"|"+n.optional(s)+"[a-zA-Z_]\\w*"+n.optional("<[^<>]+>")+")",i=n.concat(/\batomic_/,n.either("bool","char","schar","uchar","short","ushort","int","uint","long","ulong","llong","ullong","char16_t","char32_t","wchar_t","int_least8_t","uint_least8_t","int_least16_t","uint_least16_t","int_least32_t","uint_least32_t","int_least64_t","uint_least64_t","int_fast8_t","uint_fast8_t","int_fast16_t","uint_fast16_t","int_fast32_t","uint_fast32_t","int_fast64_t","uint_fast64_t","intptr_t","uintptr_t","size_t","ptrdiff_t","intmax_t","uintmax_t"),/\b/),o={className:"type",variants:[{begin:"\\b[a-z\\d_]*_t\\b"},{match:i}]},d={className:"string",variants:[{begin:'(u8?|U|L)?"',end:'"',illegal:"\\n",contains:[e.BACKSLASH_ESCAPE]},{begin:"(u8?|U|L)?'("+"\\\\(x[0-9A-Fa-f]{2}|u[0-9A-Fa-f]{4,8}|[0-7]{3}|\\S)"+"|.)",end:"'",illegal:"."},e.END_SAME_AS_BEGIN({begin:/(?:u8?|U|L)?R"([^()\\\s"]{0,16})\(/,end:/\)([^()\\\s"]{0,16})"/})]},m={className:"number",variants:[{match:/\b(0b[01']+)/},{match:/(-?)\b([\d']+(\.[\d']*)?|\.[\d']+)((ll|LL|l|L)(u|U)?|(u|U)(ll|LL|l|L)?|f|F|b|B)/},{match:/(-?)\b(0[xX][a-fA-F0-9]+(?:'[a-fA-F0-9]+)*(?:\.[a-fA-F0-9]*(?:'[a-fA-F0-9]*)*)?(?:[pP][-+]?[0-9]+)?(l|L)?(u|U)?)/},{match:/(-?)\b\d+(?:'\d+)*(?:\.\d*(?:'\d*)*)?(?:[eE][-+]?\d+)?/}],relevance:0},g={scope:"meta",begin:/#\s*include\b/,end:/$/,keywords:{keyword:"include"},contains:[{begin:/\\\n/},d,{scope:"string",begin:/<.*?>/},t,e.C_BLOCK_COMMENT_MODE]},p={className:"meta",begin:/#\s*[a-z]+\b/,end:/$/,keywords:{keyword:"if else elif endif define undef warning error line pragma _Pragma ifdef ifndef elifdef elifndef include"},contains:[{begin:/\\\n/,relevance:0},e.inherit(d,{className:"string"}),t,e.C_BLOCK_COMMENT_MODE]},y=[g,p],h={className:"title",begin:n.optional(s)+e.IDENT_RE,relevance:0},T=n.optional(s)+e.IDENT_RE+"\\s*\\(",N=12,S={keyword:["asm","auto","break","case","continue","default","do","else","enum","extern","for","fortran","goto","if","inline","register","restrict","return","sizeof","typeof","typeof_unqual","struct","switch","typedef","union","volatile","while","_Alignas","_Alignof","_Atomic","_Generic","_Noreturn","_Static_assert","_Thread_local","alignas","alignof","noreturn","static_assert","thread_local","_Pragma"],type:["float","double","signed","unsigned","int","short","long","char","void","_Bool","_BitInt","_Complex","_Imaginary","_Decimal32","_Decimal64","_Decimal96","_Decimal128","_Decimal64x","_Decimal128x","_Float16","_Float32","_Float64","_Float128","_Float32x","_Float64x","_Float128x","const","static","constexpr","complex","bool","imaginary"],literal:"true false NULL",built_in:"std string wstring cin cout cerr clog stdin stdout stderr stringstream istringstream ostringstream auto_ptr deque list queue stack vector map set pair bitset multiset multimap unordered_set unordered_map unordered_multiset unordered_multimap priority_queue make_pair array shared_ptr abort terminate abs acos asin atan2 atan calloc ceil cosh cos exit exp fabs floor fmod fprintf fputs free frexp fscanf future isalnum isalpha iscntrl isdigit isgraph islower isprint ispunct isspace isupper isxdigit tolower toupper labs ldexp log10 log malloc realloc memchr memcmp memcpy memset modf pow printf putchar puts scanf sinh sin snprintf sprintf sqrt sscanf strcat strchr strcmp strcpy strcspn strlen strncat strncmp strncpy strpbrk strrchr strspn strstr tanh tan vfprintf vprintf vsprintf endl initializer_list unique_ptr"},A=[...y,o,t,e.C_BLOCK_COMMENT_MODE,m,d],M={variants:[{begin:/=/,end:/;/},{begin:/\(/,end:/\)/},{beginKeywords:"new throw return else",end:/;/}],keywords:S,contains:A.concat([{begin:/\(/,end:/\)/,keywords:S,contains:A.concat(["self"]),relevance:0}]),relevance:0},L={begin:"("+r+"[\\*&\\s]+){1,"+N+"}"+T,returnBegin:!0,end:/[{;=]/,excludeEnd:!0,keywords:S,illegal:/[^\w\s\*&:<>.]/,contains:[{begin:a,keywords:S,relevance:0},{begin:T,returnBegin:!0,contains:[e.inherit(h,{className:"title.function"})],relevance:0},{relevance:0,match:/,/},{className:"params",begin:/\(/,end:/\)/,keywords:S,relevance:0,contains:[t,e.C_BLOCK_COMMENT_MODE,d,m,o,{begin:/\(/,end:/\)/,keywords:S,relevance:0,contains:["self",t,e.C_BLOCK_COMMENT_MODE,d,m,o]}]},o,t,e.C_BLOCK_COMMENT_MODE,...y]};return{name:"C",aliases:["h"],keywords:S,disableAutodetect:!0,illegal:"</",contains:[].concat(M,L,A,[...y,{begin:e.IDENT_RE+"::",keywords:S},{className:"class",beginKeywords:"enum class struct union",end:/[{;:<>=]/,contains:[{beginKeywords:"final class struct"},e.TITLE_MODE]}]),exports:{preprocessor:p,strings:d,keywords:S}}}vn.exports=si});var On=k((Cr,An)=>{function oi(e){let n=e.regex,t=e.COMMENT("//","$",{contains:[{begin:/\\\n/}]}),a="decltype\\(auto\\)",s="[a-zA-Z_]\\w*::",r="(?!struct)("+a+"|"+n.optional(s)+"[a-zA-Z_]\\w*"+n.optional("<[^<>]+>")+")",i={className:"type",begin:"\\b[a-z\\d_]*_t\\b"},c={className:"string",variants:[{begin:'(u8?|U|L)?"',end:'"',illegal:"\\n",contains:[e.BACKSLASH_ESCAPE]},{begin:"(u8?|U|L)?'("+"\\\\(x[0-9A-Fa-f]{2}|u[0-9A-Fa-f]{4,8}|[0-7]{3}|\\S)"+"|.)",end:"'",illegal:"."},e.END_SAME_AS_BEGIN({begin:/(?:u8?|U|L)?R"([^()\\\s"]{0,16})\(/,end:/\)([^()\\\s"]{0,16})"/})]},d={className:"number",variants:[{begin:"[+-]?(?:(?:\\b[0-9](?:'?[0-9])*\\.(?:[0-9](?:'?[0-9])*)?|\\.[0-9](?:'?[0-9])*)(?:[Ee][+-]?[0-9](?:'?[0-9])*)?|\\b[0-9](?:'?[0-9])*[Ee][+-]?[0-9](?:'?[0-9])*|\\b0[Xx](?:[0-9A-Fa-f](?:'?[0-9A-Fa-f])*(?:\\.(?:[0-9A-Fa-f](?:'?[0-9A-Fa-f])*)?)?|\\.[0-9A-Fa-f](?:'?[0-9A-Fa-f])*)[Pp][+-]?[0-9](?:'?[0-9])*)(?:[Ff](?:16|32|64|128)?|(BF|bf)16|[Ll]|)"},{begin:"[+-]?\\b(?:0[Bb][01](?:'?[01])*|0[Xx][0-9A-Fa-f](?:'?[0-9A-Fa-f])*|0(?:'?[0-7])*|[1-9](?:'?[0-9])*)(?:[Uu](?:LL?|ll?)|[Uu][Zz]?|(?:LL?|ll?)[Uu]?|[Zz][Uu]|)"}],relevance:0},m={scope:"meta",begin:/#\s*include\b/,end:/$/,keywords:{keyword:"include"},contains:[{begin:/\\\n/},c,{scope:"string",begin:/<.*?>/},t,e.C_BLOCK_COMMENT_MODE]},g={className:"meta",begin:/#\s*[a-z]+\b/,end:/$/,keywords:{keyword:"if else elif endif define undef warning error line pragma _Pragma ifdef ifndef include"},contains:[{begin:/\\\n/,relevance:0},e.inherit(c,{className:"string"}),t,e.C_BLOCK_COMMENT_MODE]},p=[m,g],y={className:"title",begin:n.optional(s)+e.IDENT_RE,relevance:0},h=n.optional(s)+e.IDENT_RE+"\\s*\\(",T=12,N=["alignas","alignof","and","and_eq","asm","atomic_cancel","atomic_commit","atomic_noexcept","auto","bitand","bitor","break","case","catch","class","co_await","co_return","co_yield","compl","concept","const_cast|10","consteval","constexpr","constinit","continue","decltype","default","delete","do","dynamic_cast|10","else","enum","explicit","export","extern","false","final","for","friend","goto","if","import","inline","module","mutable","namespace","new","noexcept","not","not_eq","nullptr","operator","or","or_eq","override","private","protected","public","reflexpr","register","reinterpret_cast|10","requires","return","sizeof","static_assert","static_cast|10","struct","switch","synchronized","template","this","thread_local","throw","transaction_safe","transaction_safe_dynamic","true","try","typedef","typeid","typename","union","using","virtual","volatile","while","xor","xor_eq"],C=["bool","char","char16_t","char32_t","char8_t","double","float","int","long","short","void","wchar_t","unsigned","signed","const","static"],R=["any","auto_ptr","barrier","binary_semaphore","bitset","complex","condition_variable","condition_variable_any","counting_semaphore","deque","false_type","flat_map","flat_set","future","imaginary","initializer_list","istringstream","jthread","latch","lock_guard","multimap","multiset","mutex","optional","ostringstream","packaged_task","pair","promise","priority_queue","queue","recursive_mutex","recursive_timed_mutex","scoped_lock","set","shared_future","shared_lock","shared_mutex","shared_timed_mutex","shared_ptr","stack","string_view","stringstream","timed_mutex","thread","true_type","tuple","unique_lock","unique_ptr","unordered_map","unordered_multimap","unordered_multiset","unordered_set","variant","vector","weak_ptr","wstring","wstring_view"],S=["abort","abs","acos","apply","as_const","asin","atan","atan2","calloc","ceil","cerr","cin","clog","cos","cosh","cout","declval","endl","exchange","exit","exp","fabs","floor","fmod","forward","fprintf","fputs","free","frexp","fscanf","future","invoke","isalnum","isalpha","iscntrl","isdigit","isgraph","islower","isprint","ispunct","isspace","isupper","isxdigit","labs","launder","ldexp","log","log10","make_pair","make_shared","make_shared_for_overwrite","make_tuple","make_unique","malloc","memchr","memcmp","memcpy","memset","modf","move","pow","printf","putchar","puts","realloc","scanf","sin","sinh","snprintf","sprintf","sqrt","sscanf","std","stderr","stdin","stdout","strcat","strchr","strcmp","strcpy","strcspn","strlen","strncat","strncmp","strncpy","strpbrk","strrchr","strspn","strstr","swap","tan","tanh","terminate","to_underlying","tolower","toupper","vfprintf","visit","vprintf","vsprintf"],L={type:C,keyword:N,literal:["NULL","false","nullopt","nullptr","true"],built_in:["_Pragma"],_type_hints:R},D={className:"function.dispatch",relevance:0,keywords:{_hint:S},begin:n.concat(/\b/,`(?!${N.join("|")})`,e.IDENT_RE,n.lookahead(/(<[^<>]+>|)\s*\(/))},U=[D,...p,i,t,e.C_BLOCK_COMMENT_MODE,d,c],O={variants:[{begin:/=/,end:/;/},{begin:/\(/,end:/\)/},{beginKeywords:"new throw return else",end:/;/}],keywords:L,contains:U.concat([{begin:/\(/,end:/\)/,keywords:L,contains:U.concat(["self"]),relevance:0}]),relevance:0},H={className:"function",begin:"("+r+"[\\*&\\s]+){1,"+T+"}"+h,returnBegin:!0,end:/[{;=]/,excludeEnd:!0,keywords:L,illegal:/[^\w\s\*&:<>.]/,contains:[{begin:a,keywords:L,relevance:0},{begin:h,returnBegin:!0,contains:[y],relevance:0},{begin:/::/,relevance:0},{begin:/:/,endsWithParent:!0,contains:[c,d]},{relevance:0,match:/,/},{className:"params",begin:/\(/,end:/\)/,keywords:L,relevance:0,contains:[t,e.C_BLOCK_COMMENT_MODE,c,d,i,{begin:/\(/,end:/\)/,keywords:L,relevance:0,contains:["self",t,e.C_BLOCK_COMMENT_MODE,c,d,i]}]},i,t,e.C_BLOCK_COMMENT_MODE,...p]};return{name:"C++",aliases:["cc","c++","h++","hpp","hh","hxx","cxx"],keywords:L,illegal:"</",classNameAliases:{"function.dispatch":"built_in"},contains:[].concat(O,H,D,U,[...p,{begin:"\\b(deque|list|queue|priority_queue|pair|stack|vector|map|set|bitset|multiset|multimap|unordered_map|unordered_set|unordered_multiset|unordered_multimap|array|tuple|optional|variant|function|flat_map|flat_set)\\s*<(?!<)",end:">",keywords:L,contains:["self",i]},{begin:e.IDENT_RE+"::",keywords:L},{match:[/\b(?:enum(?:\s+(?:class|struct))?|class|struct|union)/,/\s+/,/\w+/],className:{1:"keyword",3:"title.class"}}])}}An.exports=oi});var Rn=k((Ir,wn)=>{function ci(e){let n=["bool","byte","char","decimal","delegate","double","dynamic","enum","float","int","long","nint","nuint","object","sbyte","short","string","ulong","uint","ushort"],t=["public","private","protected","static","internal","protected","abstract","async","extern","override","unsafe","virtual","new","sealed","partial"],a=["default","false","null","true"],s=["abstract","as","base","break","case","catch","class","const","continue","do","else","event","explicit","extern","finally","fixed","for","foreach","goto","if","implicit","in","interface","internal","is","lock","namespace","new","operator","out","override","params","private","protected","public","readonly","record","ref","return","scoped","sealed","sizeof","stackalloc","static","struct","switch","this","throw","try","typeof","unchecked","unsafe","using","virtual","void","volatile","while"],u=["add","alias","and","ascending","args","async","await","by","descending","dynamic","equals","file","from","get","global","group","init","into","join","let","nameof","not","notnull","on","or","orderby","partial","record","remove","required","scoped","select","set","unmanaged","value|0","var","when","where","with","yield"],r={keyword:s.concat(u),built_in:n,literal:a},i=e.inherit(e.TITLE_MODE,{begin:"[a-zA-Z](\\.?\\w)*"}),o="\\d(_*\\d)*",c="([uU][lL]?|[lL][uU]?)?",m={className:"number",variants:[{begin:"\\b0[bB]_*[01](_*[01])*"+c},{begin:"(-?)\\b0[xX]_*[a-fA-F0-9](_*[a-fA-F0-9])*"+c},{begin:"(-?)(\\b"+o+"(\\.("+o+")?)?|\\."+o+")([eE][-+]?"+o+")?"+"([fFdDmM]|[uU][lL]?|[lL][uU]?)?"}],relevance:0},g={className:"string",begin:/"""("*)(?!")(.|\n)*?"""\1/,relevance:1},p={className:"string",begin:'@"',end:'"',contains:[{begin:'""'}]},y=e.inherit(p,{illegal:/\n/}),h={className:"subst",begin:/\{/,end:/\}/,keywords:r},T=e.inherit(h,{illegal:/\n/}),N={className:"string",begin:/\$"/,end:'"',illegal:/\n/,contains:[{begin:/\{\{/},{begin:/\}\}/},e.BACKSLASH_ESCAPE,T]},C={className:"string",begin:/\$@"/,end:'"',contains:[{begin:/\{\{/},{begin:/\}\}/},{begin:'""'},h]},R=e.inherit(C,{illegal:/\n/,contains:[{begin:/\{\{/},{begin:/\}\}/},{begin:'""'},T]});h.contains=[C,N,p,e.APOS_STRING_MODE,e.QUOTE_STRING_MODE,m,e.C_BLOCK_COMMENT_MODE],T.contains=[R,N,y,e.APOS_STRING_MODE,e.QUOTE_STRING_MODE,m,e.inherit(e.C_BLOCK_COMMENT_MODE,{illegal:/\n/})];let S={variants:[g,C,N,p,e.APOS_STRING_MODE,e.QUOTE_STRING_MODE]},A={begin:"<",end:">",contains:[{beginKeywords:"in out"},i]},M=e.IDENT_RE+"(<"+e.IDENT_RE+"(\\s*,\\s*"+e.IDENT_RE+")*>)?(\\[\\])?",L={begin:"@"+e.IDENT_RE,relevance:0};return{name:"C#",aliases:["cs","c#"],keywords:r,illegal:/::/,contains:[e.COMMENT("///","$",{returnBegin:!0,contains:[{className:"doctag",variants:[{begin:"///",relevance:0},{begin:"<\!--|-->"},{begin:"</?",end:">"}]}]}),e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE,{className:"meta",begin:"#",end:"$",keywords:{keyword:"if else elif endif define undef warning error line region endregion pragma checksum"}},S,m,{beginKeywords:"class interface",relevance:0,end:/[{;=]/,illegal:/[^\s:,]/,contains:[{beginKeywords:"where class"},i,A,e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE]},{beginKeywords:"namespace",relevance:0,end:/[{;=]/,illegal:/[^\s:]/,contains:[i,e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE]},{beginKeywords:"record",relevance:0,end:/[{;=]/,illegal:/[^\s:]/,contains:[i,A,e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE]},{className:"meta",begin:"^\\s*\\[(?=[\\w])",excludeBegin:!0,end:"\\]",excludeEnd:!0,contains:[{className:"string",begin:/"/,end:/"/}]},{beginKeywords:"new return throw await else",relevance:0},{className:"function",begin:"("+M+"\\s+)+"+e.IDENT_RE+"\\s*(<[^=]+>\\s*)?\\(",returnBegin:!0,end:/\s*[{;=]/,excludeEnd:!0,keywords:r,contains:[{beginKeywords:t.join(" "),relevance:0},{begin:e.IDENT_RE+"\\s*(<[^=]+>\\s*)?\\(",returnBegin:!0,contains:[e.TITLE_MODE,A],relevance:0},{match:/\(\)/},{className:"params",begin:/\(/,end:/\)/,excludeBegin:!0,excludeEnd:!0,keywords:r,relevance:0,contains:[S,m,e.C_BLOCK_COMMENT_MODE]},e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE]},L]}}wn.exports=ci});var kn=k((Dr,Mn)=>{var li=e=>({IMPORTANT:{scope:"meta",begin:"!important"},BLOCK_COMMENT:e.C_BLOCK_COMMENT_MODE,HEXCOLOR:{scope:"number",begin:/#(([0-9a-fA-F]{3,4})|(([0-9a-fA-F]{2}){3,4}))\b/},UNICODE_RANGE:{scope:"number",begin:/\b[Uu]\+[0-9A-Fa-f][0-9A-Fa-f?]{0,5}(-[0-9A-Fa-f][0-9A-Fa-f]{0,5})?/},FUNCTION_DISPATCH:{className:"built_in",begin:/[\w-]+(?=\()/},ATTRIBUTE_SELECTOR_MODE:{scope:"selector-attr",begin:/\[/,end:/\]/,illegal:"$",contains:[e.APOS_STRING_MODE,e.QUOTE_STRING_MODE]},CSS_NUMBER_MODE:{scope:"number",begin:e.NUMBER_RE+"(%|em|ex|ch|rem|vw|vh|vmin|vmax|cm|mm|in|pt|pc|px|deg|grad|rad|turn|s|ms|Hz|kHz|dpi|dpcm|dppx)?",relevance:0},CSS_VARIABLE:{className:"attr",begin:/--[A-Za-z_][A-Za-z0-9_-]*/}}),di=["a","abbr","address","article","aside","audio","b","blockquote","body","button","canvas","caption","cite","code","dd","del","details","dfn","div","dl","dt","em","fieldset","figcaption","figure","footer","form","h1","h2","h3","h4","h5","h6","header","hgroup","html","i","iframe","img","input","ins","kbd","label","legend","li","main","mark","menu","nav","object","ol","optgroup","option","p","picture","q","quote","samp","section","select","source","span","strong","summary","sup","table","tbody","td","textarea","tfoot","th","thead","time","tr","ul","var","video"],ui=["defs","g","marker","mask","pattern","svg","switch","symbol","feBlend","feColorMatrix","feComponentTransfer","feComposite","feConvolveMatrix","feDiffuseLighting","feDisplacementMap","feFlood","feGaussianBlur","feImage","feMerge","feMorphology","feOffset","feSpecularLighting","feTile","feTurbulence","linearGradient","radialGradient","stop","circle","ellipse","image","line","path","polygon","polyline","rect","text","use","textPath","tspan","foreignObject","clipPath"],gi=[...di,...ui],bi=["any-hover","any-pointer","aspect-ratio","color","color-gamut","color-index","device-aspect-ratio","device-height","device-width","display-mode","forced-colors","grid","height","hover","inverted-colors","monochrome","orientation","overflow-block","overflow-inline","pointer","prefers-color-scheme","prefers-contrast","prefers-reduced-motion","prefers-reduced-transparency","resolution","scan","scripting","update","width","min-width","max-width","min-height","max-height"].sort().reverse(),pi=["active","any-link","blank","checked","current","default","defined","dir","disabled","drop","empty","enabled","first","first-child","first-of-type","fullscreen","future","focus","focus-visible","focus-within","has","host","host-context","hover","indeterminate","in-range","invalid","is","lang","last-child","last-of-type","left","link","local-link","not","nth-child","nth-col","nth-last-child","nth-last-col","nth-last-of-type","nth-of-type","only-child","only-of-type","optional","out-of-range","past","placeholder-shown","read-only","read-write","required","right","root","scope","target","target-within","user-invalid","valid","visited","where"].sort().reverse(),mi=["after","backdrop","before","cue","cue-region","first-letter","first-line","grammar-error","marker","part","placeholder","selection","slotted","spelling-error"].sort().reverse(),_i=["accent-color","align-content","align-items","align-self","alignment-baseline","all","anchor-name","animation","animation-composition","animation-delay","animation-direction","animation-duration","animation-fill-mode","animation-iteration-count","animation-name","animation-play-state","animation-range","animation-range-end","animation-range-start","animation-timeline","animation-timing-function","appearance","aspect-ratio","backdrop-filter","backface-visibility","background","background-attachment","background-blend-mode","background-clip","background-color","background-image","background-origin","background-position","background-position-x","background-position-y","background-repeat","background-size","baseline-shift","block-size","border","border-block","border-block-color","border-block-end","border-block-end-color","border-block-end-style","border-block-end-width","border-block-start","border-block-start-color","border-block-start-style","border-block-start-width","border-block-style","border-block-width","border-bottom","border-bottom-color","border-bottom-left-radius","border-bottom-right-radius","border-bottom-style","border-bottom-width","border-collapse","border-color","border-end-end-radius","border-end-start-radius","border-image","border-image-outset","border-image-repeat","border-image-slice","border-image-source","border-image-width","border-inline","border-inline-color","border-inline-end","border-inline-end-color","border-inline-end-style","border-inline-end-width","border-inline-start","border-inline-start-color","border-inline-start-style","border-inline-start-width","border-inline-style","border-inline-width","border-left","border-left-color","border-left-style","border-left-width","border-radius","border-right","border-right-color","border-right-style","border-right-width","border-spacing","border-start-end-radius","border-start-start-radius","border-style","border-top","border-top-color","border-top-left-radius","border-top-right-radius","border-top-style","border-top-width","border-width","bottom","box-align","box-decoration-break","box-direction","box-flex","box-flex-group","box-lines","box-ordinal-group","box-orient","box-pack","box-shadow","box-sizing","break-after","break-before","break-inside","caption-side","caret-color","clear","clip","clip-path","clip-rule","color","color-interpolation","color-interpolation-filters","color-profile","color-rendering","color-scheme","column-count","column-fill","column-gap","column-rule","column-rule-color","column-rule-style","column-rule-width","column-span","column-width","columns","contain","contain-intrinsic-block-size","contain-intrinsic-height","contain-intrinsic-inline-size","contain-intrinsic-size","contain-intrinsic-width","container","container-name","container-type","content","content-visibility","corner-bottom-left-shape","corner-bottom-right-shape","corner-shape","corner-top-left-shape","corner-top-right-shape","counter-increment","counter-reset","counter-set","cue","cue-after","cue-before","cursor","cx","cy","direction","display","dominant-baseline","empty-cells","enable-background","field-sizing","fill","fill-opacity","fill-rule","filter","flex","flex-basis","flex-direction","flex-flow","flex-grow","flex-shrink","flex-wrap","float","flood-color","flood-opacity","flow","font","font-display","font-family","font-feature-settings","font-kerning","font-language-override","font-optical-sizing","font-palette","font-size","font-size-adjust","font-smooth","font-smoothing","font-stretch","font-style","font-synthesis","font-synthesis-position","font-synthesis-small-caps","font-synthesis-style","font-synthesis-weight","font-variant","font-variant-alternates","font-variant-caps","font-variant-east-asian","font-variant-emoji","font-variant-ligatures","font-variant-numeric","font-variant-position","font-variation-settings","font-weight","forced-color-adjust","gap","glyph-orientation-horizontal","glyph-orientation-vertical","grid","grid-area","grid-auto-columns","grid-auto-flow","grid-auto-rows","grid-column","grid-column-end","grid-column-start","grid-gap","grid-row","grid-row-end","grid-row-start","grid-template","grid-template-areas","grid-template-columns","grid-template-rows","hanging-punctuation","height","hyphenate-character","hyphenate-limit-chars","hyphens","icon","image-orientation","image-rendering","image-resolution","ime-mode","initial-letter","initial-letter-align","inline-size","inset","inset-area","inset-block","inset-block-end","inset-block-start","inset-inline","inset-inline-end","inset-inline-start","isolation","justify-content","justify-items","justify-self","kerning","left","letter-spacing","lighting-color","line-break","line-height","line-height-step","list-style","list-style-image","list-style-position","list-style-type","margin","margin-block","margin-block-end","margin-block-start","margin-bottom","margin-inline","margin-inline-end","margin-inline-start","margin-left","margin-right","margin-top","margin-trim","marker","marker-end","marker-mid","marker-start","marks","mask","mask-border","mask-border-mode","mask-border-outset","mask-border-repeat","mask-border-slice","mask-border-source","mask-border-width","mask-clip","mask-composite","mask-image","mask-mode","mask-origin","mask-position","mask-repeat","mask-size","mask-type","masonry-auto-flow","math-depth","math-shift","math-style","max-block-size","max-height","max-inline-size","max-width","min-block-size","min-height","min-inline-size","min-width","mix-blend-mode","nav-down","nav-index","nav-left","nav-right","nav-up","none","normal","object-fit","object-position","offset","offset-anchor","offset-distance","offset-path","offset-position","offset-rotate","opacity","order","orphans","outline","outline-color","outline-offset","outline-style","outline-width","overflow","overflow-anchor","overflow-block","overflow-clip-margin","overflow-inline","overflow-wrap","overflow-x","overflow-y","overlay","overscroll-behavior","overscroll-behavior-block","overscroll-behavior-inline","overscroll-behavior-x","overscroll-behavior-y","padding","padding-block","padding-block-end","padding-block-start","padding-bottom","padding-inline","padding-inline-end","padding-inline-start","padding-left","padding-right","padding-top","page","page-break-after","page-break-before","page-break-inside","paint-order","pause","pause-after","pause-before","perspective","perspective-origin","place-content","place-items","place-self","pointer-events","position","position-anchor","position-visibility","print-color-adjust","quotes","r","resize","rest","rest-after","rest-before","right","rotate","row-gap","ruby-align","ruby-position","scale","scroll-behavior","scroll-margin","scroll-margin-block","scroll-margin-block-end","scroll-margin-block-start","scroll-margin-bottom","scroll-margin-inline","scroll-margin-inline-end","scroll-margin-inline-start","scroll-margin-left","scroll-margin-right","scroll-margin-top","scroll-padding","scroll-padding-block","scroll-padding-block-end","scroll-padding-block-start","scroll-padding-bottom","scroll-padding-inline","scroll-padding-inline-end","scroll-padding-inline-start","scroll-padding-left","scroll-padding-right","scroll-padding-top","scroll-snap-align","scroll-snap-stop","scroll-snap-type","scroll-timeline","scroll-timeline-axis","scroll-timeline-name","scrollbar-color","scrollbar-gutter","scrollbar-width","shape-image-threshold","shape-margin","shape-outside","shape-rendering","speak","speak-as","src","stop-color","stop-opacity","stroke","stroke-dasharray","stroke-dashoffset","stroke-linecap","stroke-linejoin","stroke-miterlimit","stroke-opacity","stroke-width","tab-size","table-layout","text-align","text-align-all","text-align-last","text-anchor","text-combine-upright","text-decoration","text-decoration-color","text-decoration-line","text-decoration-skip","text-decoration-skip-ink","text-decoration-style","text-decoration-thickness","text-emphasis","text-emphasis-color","text-emphasis-position","text-emphasis-style","text-indent","text-justify","text-orientation","text-overflow","text-rendering","text-shadow","text-size-adjust","text-transform","text-underline-offset","text-underline-position","text-wrap","text-wrap-mode","text-wrap-style","timeline-scope","top","touch-action","transform","transform-box","transform-origin","transform-style","transition","transition-behavior","transition-delay","transition-duration","transition-property","transition-timing-function","translate","unicode-bidi","unicode-range","user-modify","user-select","vector-effect","vertical-align","view-timeline","view-timeline-axis","view-timeline-inset","view-timeline-name","view-transition-name","visibility","voice-balance","voice-duration","voice-family","voice-pitch","voice-range","voice-rate","voice-stress","voice-volume","white-space","white-space-collapse","widows","width","will-change","word-break","word-spacing","word-wrap","writing-mode","x","y","z-index","zoom"].sort().reverse();function Ei(e){let n=e.regex,t=li(e),a={begin:/-(webkit|moz|ms|o)-(?=[a-z])/},s="and or not only",u=/@-?\w[\w]*(-\w+)*/,r="[a-zA-Z-][a-zA-Z0-9_-]*",i=[e.APOS_STRING_MODE,e.QUOTE_STRING_MODE];return{name:"CSS",case_insensitive:!0,illegal:/[=|'\$]/,keywords:{keyframePosition:"from to"},classNameAliases:{keyframePosition:"selector-tag"},contains:[t.BLOCK_COMMENT,a,t.CSS_NUMBER_MODE,{className:"selector-id",begin:/#[A-Za-z0-9_-]+/,relevance:0},{className:"selector-class",begin:"\\."+r,relevance:0},t.ATTRIBUTE_SELECTOR_MODE,{className:"selector-pseudo",variants:[{begin:":("+pi.join("|")+")"},{begin:":(:)?("+mi.join("|")+")"}]},t.CSS_VARIABLE,{className:"attribute",begin:"\\b("+_i.join("|")+")\\b"},{begin:/:/,end:/[;}{]/,contains:[t.BLOCK_COMMENT,t.HEXCOLOR,t.IMPORTANT,t.CSS_NUMBER_MODE,t.UNICODE_RANGE,...i,{begin:/(url|data-uri)\(/,end:/\)/,relevance:0,keywords:{built_in:"url data-uri"},contains:[...i,{className:"string",begin:/[^)]/,endsWithParent:!0,excludeEnd:!0}]},t.FUNCTION_DISPATCH]},{begin:n.lookahead(/@/),end:"[{;]",relevance:0,illegal:/:/,contains:[{className:"keyword",begin:u},{begin:/\s/,endsWithParent:!0,excludeEnd:!0,relevance:0,keywords:{$pattern:/[a-z-]+/,keyword:s,attribute:bi.join(" ")},contains:[{begin:/[a-z-]+(?=:)/,className:"attribute"},...i,t.CSS_NUMBER_MODE]}]},{className:"selector-tag",begin:"\\b("+gi.join("|")+")\\b"}]}}Mn.exports=Ei});var Cn=k((Lr,xn)=>{function fi(e){let n=e.regex,t={begin:/<\/?[A-Za-z_]/,end:">",subLanguage:"xml",relevance:0},a={match:/^ {0,3}([-*_])[ \t]*(?:\1[ \t]*){2,}$/},s={className:"code",variants:[{begin:"(`{3,})[^`](.|\\n)*?\\1`*[ ]*"},{begin:"(~{3,})[^~](.|\\n)*?\\1~*[ ]*"},{begin:"```",end:"```+[ ]*$"},{begin:"~~~",end:"~~~+[ ]*$"},{begin:"`.+?`"},{begin:"(?=^( {4}|\\t))",contains:[{begin:"^( {4}|\\t)",end:"(\\n)$"}],relevance:0}]},u={className:"bullet",begin:"^[ 	]*([*+-]|(\\d+\\.))(?=\\s+)",end:"\\s+",excludeEnd:!0},r={begin:/^\[[^\n]+\]:/,returnBegin:!0,contains:[{className:"symbol",begin:/\[/,end:/\]/,excludeBegin:!0,excludeEnd:!0},{className:"link",begin:/:\s*/,end:/$/,excludeBegin:!0}]},i=/[A-Za-z][A-Za-z0-9+.-]*/,o={variants:[{begin:/\[.+?\]\[.*?\]/,relevance:0},{begin:/\[.+?\]\(((data|javascript|mailto):|(?:http|ftp)s?:\/\/).*?\)/,relevance:2},{begin:n.concat(/\[.+?\]\(/,i,/:\/\/.*?\)/),relevance:2},{begin:/\[.+?\]\([./?&#].*?\)/,relevance:1},{begin:/\[.*?\]\(.*?\)/,relevance:0}],returnBegin:!0,contains:[{match:/\[(?=\])/},{className:"string",relevance:0,begin:"\\[",end:"\\]",excludeBegin:!0,returnEnd:!0},{className:"link",relevance:0,begin:"\\]\\(",end:"\\)",excludeBegin:!0,excludeEnd:!0},{className:"symbol",relevance:0,begin:"\\]\\[",end:"\\]",excludeBegin:!0,excludeEnd:!0}]},c={className:"strong",contains:[],variants:[{begin:/_{2}(?!\s)/,end:/_{2}/},{begin:/\*{2}(?!\s)/,end:/\*{2}/}]},d={className:"emphasis",contains:[],variants:[{begin:/\*(?![*\s])/,end:/\*/},{begin:/_(?![_\s])/,end:/_/,relevance:0}]},m=e.inherit(c,{contains:[]}),g=e.inherit(d,{contains:[]});c.contains.push(g),d.contains.push(m);let p=[t,o];return[c,d,m,g].forEach(N=>{N.contains=N.contains.concat(p)}),p=p.concat(c,d),{name:"Markdown",aliases:["md","mkdown","mkd"],contains:[{className:"section",variants:[{begin:"^#{1,6}",end:"$",contains:p},{begin:"(?=^.+?\\n[=-]{2,}$)",contains:[{begin:"^[=-]*$"},{begin:"^",end:"\\n",contains:p}]}]},t,u,a,c,d,{className:"quote",begin:"^>\\s+",contains:p,end:"$"},s,o,r,{scope:"literal",match:/&([a-zA-Z0-9]+|#[0-9]{1,7}|#[Xx][0-9a-fA-F]{1,6});/}]}}xn.exports=fi});var Dn=k((Br,In)=>{function hi(e){let n=e.regex;return{name:"Diff",aliases:["patch"],contains:[{className:"meta",relevance:10,match:n.either(/^@@ +-\d+,\d+ +\+\d+,\d+ +@@/,/^@@ +-\d+ +\+\d+,\d+ +@@/,/^@@ +-\d+,\d+ +\+\d+ +@@/,/^@@ +-\d+ +\+\d+ +@@/,/^\*\*\* +\d+,\d+ +\*\*\*\*$/,/^--- +\d+,\d+ +----$/)},{className:"comment",variants:[{begin:n.either(/Index: /,/^index/,/={3,}/,/^-{3}/,/^\*{3} /,/^\+{3}/,/^diff --git/),end:/$/},{match:/^\*{15}$/}]},{className:"addition",begin:/^\+/,end:/$/},{className:"deletion",begin:/^-/,end:/$/},{className:"addition",begin:/^!/,end:/$/}]}}In.exports=hi});var Bn=k((Ur,Ln)=>{function Ni(e){let n=e.regex,t="([a-zA-Z_]\\w*[!?=]?|[-+~]@|<<|>>|=~|===?|<=>|[<>]=?|\\*\\*|[-/+%^&*~`|]|\\[\\]=?)",a=n.either(/\b([A-Z]+[a-z0-9]+)+/,/\b([A-Z]+[a-z0-9]+)+[A-Z]+/),s=n.concat(a,/(::\w+)*/),r={"variable.constant":["__FILE__","__LINE__","__ENCODING__"],"variable.language":["self","super"],keyword:["alias","and","begin","BEGIN","break","case","class","defined","do","else","elsif","end","END","ensure","for","if","in","module","next","not","or","redo","require","rescue","retry","return","then","undef","unless","until","when","while","yield",...["include","extend","prepend","public","private","protected","raise","throw"]],built_in:["proc","lambda","attr_accessor","attr_reader","attr_writer","define_method","private_constant","module_function"],literal:["true","false","nil"]},i={className:"doctag",begin:"@[A-Za-z]+"},o={begin:"#<",end:">"},c=[e.COMMENT("#","$",{contains:[i]}),e.COMMENT("^=begin","^=end",{contains:[i],relevance:10}),e.COMMENT("^__END__",e.MATCH_NOTHING_RE)],d={className:"subst",begin:/#\{/,end:/\}/,keywords:r},m={className:"string",contains:[e.BACKSLASH_ESCAPE,d],variants:[{begin:/'/,end:/'/},{begin:/"/,end:/"/},{begin:/`/,end:/`/},{begin:/%[qQwWx]?\(/,end:/\)/},{begin:/%[qQwWx]?\[/,end:/\]/},{begin:/%[qQwWx]?\{/,end:/\}/},{begin:/%[qQwWx]?</,end:/>/},{begin:/%[qQwWx]?\//,end:/\//},{begin:/%[qQwWx]?%/,end:/%/},{begin:/%[qQwWx]?-/,end:/-/},{begin:/%[qQwWx]?\|/,end:/\|/},{begin:/\B\?(\\\d{1,3})/},{begin:/\B\?(\\x[A-Fa-f0-9]{1,2})/},{begin:/\B\?(\\u\{?[A-Fa-f0-9]{1,6}\}?)/},{begin:/\B\?(\\M-\\C-|\\M-\\c|\\c\\M-|\\M-|\\C-\\M-)[\x20-\x7e]/},{begin:/\B\?\\(c|C-)[\x20-\x7e]/},{begin:/\B\?\\?\S/},{begin:n.concat(/<<[-~]?'?/,n.lookahead(/(\w+)(?=\W)[^\n]*\n(?:[^\n]*\n)*?\s*\1\b/)),contains:[e.END_SAME_AS_BEGIN({begin:/(\w+)/,end:/(\w+)/,contains:[e.BACKSLASH_ESCAPE,d]})]}]},g="[1-9](_?[0-9])*|0",p="[0-9](_?[0-9])*",y={className:"number",relevance:0,variants:[{begin:`\\b(${g})(\\.(${p}))?([eE][+-]?(${p})|r)?i?\\b`},{begin:"\\b0[dD][0-9](_?[0-9])*r?i?\\b"},{begin:"\\b0[bB][0-1](_?[0-1])*r?i?\\b"},{begin:"\\b0[oO][0-7](_?[0-7])*r?i?\\b"},{begin:"\\b0[xX][0-9a-fA-F](_?[0-9a-fA-F])*r?i?\\b"},{begin:"\\b0(_?[0-7])+r?i?\\b"}]},h={variants:[{match:/\(\)/},{className:"params",begin:/\(/,end:/(?=\))/,excludeBegin:!0,endsParent:!0,keywords:r}]},M=[m,{variants:[{match:[/class\s+/,s,/\s+<\s+/,s]},{match:[/\b(class|module)\s+/,s]}],scope:{2:"title.class",4:"title.class.inherited"},keywords:r},{match:[/(include|extend)\s+/,s],scope:{2:"title.class"},keywords:r},{relevance:0,match:[s,/\.new[. (]/],scope:{1:"title.class"}},{relevance:0,match:/\b[A-Z][A-Z_0-9]+\b/,className:"variable.constant"},{relevance:0,match:a,scope:"title.class"},{match:[/def/,/\s+/,t],scope:{1:"keyword",3:"title.function"},contains:[h]},{begin:"::"},{className:"symbol",begin:e.UNDERSCORE_IDENT_RE+"(!|\\?)?:",relevance:0},{className:"symbol",begin:":(?!\\s)",contains:[m,{begin:t}],relevance:0},y,{className:"variable",begin:"(\\$\\W)|((\\$|@@?)(\\w+))(?=[^@$?])(?![A-Za-z])(?![@$?'])"},{className:"params",begin:/\|(?!=)/,end:/\|/,excludeBegin:!0,excludeEnd:!0,relevance:0,keywords:r},{begin:"("+e.RE_STARTERS_RE+"|unless)\\s*",keywords:"unless",contains:[{className:"regexp",contains:[e.BACKSLASH_ESCAPE,d],illegal:/\n/,variants:[{begin:"/",end:"/[a-z]*"},{begin:/%r\{/,end:/\}[a-z]*/},{begin:"%r\\(",end:"\\)[a-z]*"},{begin:"%r!",end:"![a-z]*"},{begin:"%r\\[",end:"\\][a-z]*"}]}].concat(o,c),relevance:0}].concat(o,c);d.contains=M,h.contains=M;let O=[{begin:/^\s*=>/,starts:{end:"$",contains:M}},{className:"meta.prompt",begin:"^("+"[>?]>"+"|"+"[\\w#]+\\(\\w+\\):\\d+:\\d+[>*]"+"|"+"(\\w+-)?\\d+\\.\\d+\\.\\d+(p\\d+)?[^\\d][^>]+>"+")(?=[ ])",starts:{end:"$",keywords:r,contains:M}}];return c.unshift(o),{name:"Ruby",aliases:["rb","gemspec","podspec","thor","irb"],keywords:r,illegal:/\/\*/,contains:[e.SHEBANG({binary:"ruby"})].concat(O).concat(c).concat(M)}}Ln.exports=Ni});var Pn=k((Pr,Un)=>{function yi(e){let u={keyword:["break","case","chan","const","continue","default","defer","else","fallthrough","for","func","go","goto","if","import","interface","map","package","range","return","select","struct","switch","type","var"],type:["bool","byte","complex64","complex128","error","float32","float64","int8","int16","int32","int64","string","uint8","uint16","uint32","uint64","int","uint","uintptr","rune"],literal:["true","false","iota","nil"],built_in:["append","cap","close","complex","copy","imag","len","make","new","panic","print","println","real","recover","delete"]};return{name:"Go",aliases:["golang"],keywords:u,illegal:"</",contains:[e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE,{className:"string",variants:[e.QUOTE_STRING_MODE,e.APOS_STRING_MODE,{begin:"`",end:"`"}]},{className:"number",variants:[{match:/-?\b0[xX]\.[a-fA-F0-9](_?[a-fA-F0-9])*[pP][+-]?\d(_?\d)*i?/,relevance:0},{match:/-?\b0[xX](_?[a-fA-F0-9])+((\.([a-fA-F0-9](_?[a-fA-F0-9])*)?)?[pP][+-]?\d(_?\d)*)?i?/,relevance:0},{match:/-?\b0[oO](_?[0-7])*i?/,relevance:0},{match:/-?\b0[bB](_?[01])*i?/,relevance:0},{match:/-?\.\d(_?\d)*([eE][+-]?\d(_?\d)*)?i?/,relevance:0},{match:/-?\b\d(_?\d)*(\.(\d(_?\d)*)?)?([eE][+-]?\d(_?\d)*)?i?/,relevance:0}]},{begin:/:=/},{className:"function",beginKeywords:"func",end:"\\s*(\\{|$)",excludeEnd:!0,contains:[e.TITLE_MODE,{className:"params",begin:/\(/,end:/\)/,endsParent:!0,keywords:u,illegal:/["']/}]}]}}Un.exports=yi});var zn=k((Fr,Fn)=>{function Ti(e){let n=e.regex,t=/[_A-Za-z][_0-9A-Za-z]*/;return{name:"GraphQL",aliases:["gql"],case_insensitive:!0,disableAutodetect:!1,keywords:{keyword:["query","mutation","subscription","type","input","schema","directive","interface","union","scalar","fragment","enum","on"],literal:["true","false","null"]},contains:[e.HASH_COMMENT_MODE,e.QUOTE_STRING_MODE,e.NUMBER_MODE,{scope:"punctuation",match:/[.]{3}/,relevance:0},{scope:"punctuation",begin:/[\!\(\)\:\=\[\]\{\|\}]{1}/,relevance:0},{scope:"variable",begin:/\$/,end:/\W/,excludeEnd:!0,relevance:0},{scope:"meta",match:/@\w+/,excludeEnd:!0},{scope:"symbol",begin:n.concat(t,n.lookahead(/\s*:/)),relevance:0}],illegal:[/[;<']/,/BEGIN/]}}Fn.exports=Ti});var Gn=k((zr,$n)=>{function vi(e){let n=e.regex,t={className:"number",relevance:0,variants:[{begin:/([+-]+)?[\d]+_[\d_]+/},{begin:e.NUMBER_RE}]},a=e.COMMENT();a.variants=[{begin:/;/,end:/$/},{begin:/#/,end:/$/}];let s={className:"variable",variants:[{begin:/\$[\w\d"][\w\d_]*/},{begin:/\$\{(.*?)\}/}]},u={className:"literal",begin:/\bon|off|true|false|yes|no\b/},r={className:"string",contains:[e.BACKSLASH_ESCAPE],variants:[{begin:"'''",end:"'''",relevance:10},{begin:'"""',end:'"""',relevance:10},{begin:'"',end:'"'},{begin:"'",end:"'"}]},i={begin:/\[/,end:/\]/,contains:[a,u,s,r,t,"self"],relevance:0},o=/[A-Za-z0-9_-]+/,c=/"(\\"|[^"])*"/,d=/'[^']*'/,m=n.either(o,c,d),g=n.concat(m,"(\\s*\\.\\s*",m,")*",n.lookahead(/\s*=\s*[^#\s]/));return{name:"TOML, also INI",aliases:["toml"],case_insensitive:!0,illegal:/\S/,contains:[a,{className:"section",begin:/\[+/,end:/\]+/},{begin:g,className:"attr",starts:{end:/$/,contains:[a,i,u,s,r,t]}}]}}$n.exports=vi});var Zn=k(($r,qn)=>{var be="[0-9](_*[0-9])*",Re=`\\.(${be})`,Me="[0-9a-fA-F](_*[0-9a-fA-F])*",Kn={className:"number",variants:[{begin:`(\\b(${be})((${Re})|\\.)?|(${Re}))[eE][+-]?(${be})[fFdD]?\\b`},{begin:`\\b(${be})((${Re})[fFdD]?\\b|\\.([fFdD]\\b)?)`},{begin:`(${Re})[fFdD]?\\b`},{begin:`\\b(${be})[fFdD]\\b`},{begin:`\\b0[xX]((${Me})\\.?|(${Me})?\\.(${Me}))[pP][+-]?(${be})[fFdD]?\\b`},{begin:"\\b(0|[1-9](_*[0-9])*)[lL]?\\b"},{begin:`\\b0[xX](${Me})[lL]?\\b`},{begin:"\\b0(_*[0-7])*[lL]?\\b"},{begin:"\\b0[bB][01](_*[01])*[lL]?\\b"}],relevance:0};function Hn(e,n,t){return t===-1?"":e.replace(n,a=>Hn(e,n,t-1))}function Si(e){let n=e.regex,t="[\xC0-\u02B8a-zA-Z_$][\xC0-\u02B8a-zA-Z_$0-9]*",a="(?:(?:\\s*\\[\\s*])+)?",s=t+"<@@@>"+a,r="(?:"+("\\?(?:\\s+(?:extends|super)\\s+"+s+")?")+"|"+s+")",i=Hn("(?:\\s*<\\s*"+r+"(?:\\s*,\\s*"+r+")*\\s*>)?",/<@@@>/g,2),g={keyword:["synchronized","abstract","private","var","static","if","const ","for","while","strictfp","finally","protected","import","native","final","void","enum","else","break","transient","catch","instanceof","volatile","case","assert","package","default","public","try","switch","continue","throws","protected","public","private","module","requires","exports","do","sealed","yield","permits","goto","when"],literal:["false","true","null"],type:["char","boolean","long","float","int","byte","short","double"],built_in:["super","this"]},p={className:"meta",begin:"@"+t,contains:[{begin:/\(/,end:/\)/,contains:["self"]}]},y={className:"params",begin:/\(/,end:/\)/,keywords:g,relevance:0,contains:[e.C_BLOCK_COMMENT_MODE],endsParent:!0};return{name:"Java",aliases:["jsp"],keywords:g,illegal:/<\/|#/,contains:[e.COMMENT("/\\*\\*","\\*/",{relevance:0,contains:[{begin:/\w+@/,relevance:0},{className:"doctag",begin:"@[A-Za-z]+"}]}),{begin:/import java\.[a-z]+\./,keywords:"import",relevance:2},e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE,{begin:/"""/,end:/"""/,className:"string",contains:[e.BACKSLASH_ESCAPE]},e.APOS_STRING_MODE,e.QUOTE_STRING_MODE,{match:[/\b(?:class|interface|enum|extends|implements|new)/,/\s+/,t],className:{1:"keyword",3:"title.class"}},{match:/non-sealed/,scope:"keyword"},{beginKeywords:"new throw return else yield assert",relevance:0},{begin:[t,n.concat(i,a,/\s+/),t,a,/\s*/,/=(?!=)/],className:{1:"type",3:"variable",6:"operator"}},{begin:[/record/,/\s+/,t],className:{1:"keyword",3:"title.class"},contains:[y,e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE]},{begin:[t,n.concat(i,a,/\s+/),t,/\s*(?=\()/],className:{1:"type",3:"title.function"},keywords:g,contains:[{className:"params",begin:/\(/,end:/\)/,keywords:g,relevance:0,contains:[p,e.APOS_STRING_MODE,e.QUOTE_STRING_MODE,Kn,e.C_BLOCK_COMMENT_MODE]},e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE]},Kn,p]}}qn.exports=Si});var Jn=k((Gr,Qn)=>{var Wn="[A-Za-z$_][0-9A-Za-z$_]*",Ai=["as","in","of","if","for","while","finally","var","new","function","do","return","void","else","break","catch","instanceof","with","throw","case","default","try","switch","continue","typeof","delete","let","yield","const","class","debugger","async","await","static","import","from","export","extends","using"],Oi=["true","false","null","undefined","NaN","Infinity"],Yn=["Object","Function","Boolean","Symbol","Math","Date","Number","BigInt","String","RegExp","Array","Float32Array","Float64Array","Int8Array","Uint8Array","Uint8ClampedArray","Int16Array","Int32Array","Uint16Array","Uint32Array","BigInt64Array","BigUint64Array","Set","Map","WeakSet","WeakMap","ArrayBuffer","SharedArrayBuffer","Atomics","DataView","JSON","Promise","Generator","GeneratorFunction","AsyncFunction","Reflect","Proxy","Intl","WebAssembly"],Xn=["Error","EvalError","InternalError","RangeError","ReferenceError","SyntaxError","TypeError","URIError"],Vn=["setInterval","setTimeout","clearInterval","clearTimeout","require","exports","eval","isFinite","isNaN","parseFloat","parseInt","decodeURI","decodeURIComponent","encodeURI","encodeURIComponent","escape","unescape"],wi=["arguments","this","super","console","window","document","localStorage","sessionStorage","module","self","global"],Ri=[].concat(Vn,Yn,Xn);function Mi(e){let n=e.regex,t=(E,{after:w})=>{let B="</"+E[0].slice(1);return E.input.indexOf(B,w)!==-1},a=Wn,s={begin:"<>",end:"</>"},u=/<[A-Za-z0-9\\._:-]+\s*\/>/,r={begin:/<[A-Za-z0-9\\._:-]+/,end:/\/[A-Za-z0-9\\._:-]+>|\/>/,isTrulyOpeningTag:(E,w)=>{let B=E[0].length+E.index,$=E.input[B];if($==="<"||$===","){w.ignoreMatch();return}$===">"&&(t(E,{after:B})||w.ignoreMatch());let K,j=E.input.substring(B);if(K=j.match(/^\s*=/)){w.ignoreMatch();return}if((K=j.match(/^\s+extends\s+/))&&K.index===0){w.ignoreMatch();return}}},i={$pattern:Wn,keyword:Ai,literal:Oi,built_in:Ri,"variable.language":wi},o="[0-9](_?[0-9])*",c=`\\.(${o})`,d="0|[1-9](_?[0-9])*|0[0-7]*[89][0-9]*",m={className:"number",variants:[{begin:`(\\b(${d})((${c})|\\.)?|(${c}))[eE][+-]?(${o})\\b`},{begin:`\\b(${d})\\b((${c})\\b|\\.)?|(${c})\\b`},{begin:"\\b(0|[1-9](_?[0-9])*)n\\b"},{begin:"\\b0[xX][0-9a-fA-F](_?[0-9a-fA-F])*n?\\b"},{begin:"\\b0[bB][0-1](_?[0-1])*n?\\b"},{begin:"\\b0[oO][0-7](_?[0-7])*n?\\b"},{begin:"\\b0[0-7]+n?\\b"}],relevance:0},g={className:"subst",begin:"\\$\\{",end:"\\}",keywords:i,contains:[]},p={begin:".?html`",end:"",starts:{end:"`",returnEnd:!1,contains:[e.BACKSLASH_ESCAPE,g],subLanguage:"xml"}},y={begin:".?css`",end:"",starts:{end:"`",returnEnd:!1,contains:[e.BACKSLASH_ESCAPE,g],subLanguage:"css"}},h={begin:".?gql`",end:"",starts:{end:"`",returnEnd:!1,contains:[e.BACKSLASH_ESCAPE,g],subLanguage:"graphql"}},T={className:"string",begin:"`",end:"`",contains:[e.BACKSLASH_ESCAPE,g]},C={className:"comment",variants:[e.COMMENT(/\/\*\*(?!\/)/,"\\*/",{relevance:0,contains:[{begin:"(?=@[A-Za-z]+)",relevance:0,contains:[{className:"doctag",begin:"@[A-Za-z]+"},{className:"type",begin:"\\{",end:"\\}",excludeEnd:!0,excludeBegin:!0,relevance:0},{className:"variable",begin:a+"(?=\\s*(-)|$)",endsParent:!0,relevance:0},{begin:/(?=[^\n])\s/,relevance:0}]}]}),e.C_BLOCK_COMMENT_MODE,e.C_LINE_COMMENT_MODE]},R=[e.APOS_STRING_MODE,e.QUOTE_STRING_MODE,p,y,h,T,{match:/\$\d+/},m];g.contains=R.concat({begin:/\{/,end:/\}/,keywords:i,contains:["self"].concat(R)});let S=[].concat(C,g.contains),A=S.concat([{begin:/(\s*)\(/,end:/\)/,keywords:i,contains:["self"].concat(S)}]),M={className:"params",begin:/(\s*)\(/,end:/\)/,excludeBegin:!0,excludeEnd:!0,keywords:i,contains:A},L={variants:[{match:[/class/,/\s+/,a,/\s+/,/extends/,/\s+/,n.concat(a,"(",n.concat(/\./,a),")*")],scope:{1:"keyword",3:"title.class",5:"keyword",7:"title.class.inherited"}},{match:[/class/,/\s+/,a],scope:{1:"keyword",3:"title.class"}}]},D={relevance:0,match:n.either(/\bJSON/,/\b[A-Z][a-z]+([A-Z][a-z]*|\d)*/,/\b[A-Z]{2,}([A-Z][a-z]+|\d)+([A-Z][a-z]*)*/,/\b[A-Z]{2,}[a-z]+([A-Z][a-z]+|\d)*([A-Z][a-z]*)*/),className:"title.class",keywords:{_:[...Yn,...Xn]}},U={label:"use_strict",className:"meta",relevance:10,begin:/^\s*['"]use (strict|asm)['"]/},O={variants:[{match:[/function/,/\s+/,a,/(?=\s*\()/]},{match:[/function/,/\s*(?=\()/]}],className:{1:"keyword",3:"title.function"},label:"func.def",contains:[M],illegal:/%/},H={relevance:0,match:/\b[A-Z][A-Z_0-9]+\b/,className:"variable.constant"};function J(E){return n.concat("(?!",E.join("|"),")")}let ne={match:n.concat(/\b/,J([...Vn,"super","import","await"].map(E=>`${E}\\s*\\(`)),a,n.lookahead(/\s*\(/)),className:"title.function",relevance:0},q={begin:n.concat(/\./,n.lookahead(n.concat(a,/(?![0-9A-Za-z$_(])/))),end:a,excludeBegin:!0,keywords:"prototype",className:"property",relevance:0},Z={match:[/get|set/,/\s+/,a,/(?=\()/],className:{1:"keyword",3:"title.function"},contains:[{begin:/\(\)/},M]},l="(\\([^()]*(\\([^()]*(\\([^()]*\\)[^()]*)*\\)[^()]*)*\\)|"+e.UNDERSCORE_IDENT_RE+")\\s*=>",_={match:[/const|var|let/,/\s+/,a,/\s*/,/=\s*/,/(async\s*)?/,n.lookahead(l)],keywords:"async",className:{1:"keyword",3:"title.function"},contains:[M]};return{name:"JavaScript",aliases:["js","jsx","mjs","cjs"],keywords:i,exports:{PARAMS_CONTAINS:A,CLASS_REFERENCE:D},illegal:/#(?![$_A-Za-z])/,contains:[e.SHEBANG({label:"shebang",binary:"node",relevance:5}),U,e.APOS_STRING_MODE,e.QUOTE_STRING_MODE,p,y,h,T,C,{match:/\$\d+/},m,D,{scope:"attr",match:a+n.lookahead(":"),relevance:0},_,{begin:"("+e.RE_STARTERS_RE+"|\\b(case|return|throw)\\b)\\s*",keywords:"return throw case",relevance:0,contains:[C,e.REGEXP_MODE,{className:"function",begin:l,returnBegin:!0,end:"\\s*=>",contains:[{className:"params",variants:[{begin:e.UNDERSCORE_IDENT_RE,relevance:0},{className:null,begin:/\(\s*\)/,skip:!0},{begin:/(\s*)\(/,end:/\)/,excludeBegin:!0,excludeEnd:!0,keywords:i,contains:A}]}]},{begin:/,/,relevance:0},{match:/\s+/,relevance:0},{variants:[{begin:s.begin,end:s.end},{match:u},{begin:r.begin,"on:begin":r.isTrulyOpeningTag,end:r.end}],subLanguage:"xml",contains:[{begin:r.begin,end:r.end,skip:!0,contains:["self"]}]}]},O,{beginKeywords:"while if switch catch for"},{begin:"\\b(?!function)"+e.UNDERSCORE_IDENT_RE+"\\([^()]*(\\([^()]*(\\([^()]*\\)[^()]*)*\\)[^()]*)*\\)\\s*\\{",returnBegin:!0,label:"func.def",contains:[M,e.inherit(e.TITLE_MODE,{begin:a,className:"title.function"})]},{match:/\.\.\./,relevance:0},q,{match:"\\$"+a,relevance:0},{match:[/\bconstructor(?=\s*\()/],className:{1:"title.function"},contains:[M]},ne,H,L,Z,{match:/\$[(.]/}]}}Qn.exports=Mi});var et=k((Kr,jn)=>{var ki="([-+]?)(\\b0[xX][a-fA-F0-9]+|(\\b\\d+(\\.\\d*)?|\\.\\d+)([eE][-+]?\\d+)?)|NaN|[-+]?Infinity",xi={scope:"number",match:ki,relevance:0};function Ci(e){let n={className:"attr",begin:/(("(\\.|[^\\"\r\n])*")|('(\\.|[^\\'\r\n])*'))(?=\s*:)/,relevance:1.01},t={match:/[{}[\],:]/,className:"punctuation",relevance:0},a=["true","false","null"],s={scope:"literal",beginKeywords:a.join(" ")};return{name:"JSON",aliases:["jsonc","json5"],keywords:{literal:a},contains:[n,t,e.APOS_STRING_MODE,e.QUOTE_STRING_MODE,s,xi,e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE],illegal:"\\S"}}jn.exports=Ci});var tt=k((Hr,nt)=>{var pe="[0-9](_*[0-9])*",ke=`\\.(${pe})`,xe="[0-9a-fA-F](_*[0-9a-fA-F])*",Ii={className:"number",variants:[{begin:`(\\b(${pe})((${ke})|\\.)?|(${ke}))[eE][+-]?(${pe})[fFdD]?\\b`},{begin:`\\b(${pe})((${ke})[fFdD]?\\b|\\.([fFdD]\\b)?)`},{begin:`(${ke})[fFdD]?\\b`},{begin:`\\b(${pe})[fFdD]\\b`},{begin:`\\b0[xX]((${xe})\\.?|(${xe})?\\.(${xe}))[pP][+-]?(${pe})[fFdD]?\\b`},{begin:"\\b(0|[1-9](_*[0-9])*)[lL]?\\b"},{begin:`\\b0[xX](${xe})[lL]?\\b`},{begin:"\\b0(_*[0-7])*[lL]?\\b"},{begin:"\\b0[bB][01](_*[01])*[lL]?\\b"}],relevance:0};function Di(e){let n={keyword:"abstract as val var vararg get set class object open private protected public noinline crossinline dynamic final enum if else do while for when throw try catch finally import package is in fun override companion reified inline lateinit init interface annotation data sealed internal infix operator out by constructor super tailrec where const inner suspend typealias external expect actual",built_in:"Byte Short Char Int Long Boolean Float Double Void Unit Nothing",literal:"true false null"},t={className:"keyword",begin:/\b(break|continue|return|this)\b/,starts:{contains:[{className:"symbol",begin:/@\w+/}]}},a={className:"symbol",begin:e.UNDERSCORE_IDENT_RE+"@"},s={className:"subst",begin:/\$\{/,end:/\}/,contains:[e.C_NUMBER_MODE]},u={className:"variable",begin:"\\$"+e.UNDERSCORE_IDENT_RE},r={className:"string",variants:[{begin:'"""',end:'"""(?=[^"])',contains:[u,s]},{begin:"'",end:"'",illegal:/\n/,contains:[e.BACKSLASH_ESCAPE]},{begin:'"',end:'"',illegal:/\n/,contains:[e.BACKSLASH_ESCAPE,u,s]}]};s.contains.push(r);let i={className:"meta",begin:"@(?:file|property|field|get|set|receiver|param|setparam|delegate)\\s*:(?:\\s*"+e.UNDERSCORE_IDENT_RE+")?"},o={className:"meta",begin:"@"+e.UNDERSCORE_IDENT_RE,contains:[{begin:/\(/,end:/\)/,contains:[e.inherit(r,{className:"string"}),"self"]}]},c=Ii,d=e.COMMENT("/\\*","\\*/",{contains:[e.C_BLOCK_COMMENT_MODE]}),m={variants:[{className:"type",begin:e.UNDERSCORE_IDENT_RE},{begin:/\(/,end:/\)/,contains:[]}]},g=m;return g.variants[1].contains=[m],m.variants[1].contains=[g],{name:"Kotlin",aliases:["kt","kts","ktm","ktx"],keywords:n,contains:[e.COMMENT("/\\*\\*","\\*/",{relevance:0,contains:[{className:"doctag",begin:"@[A-Za-z]+"}]}),e.C_LINE_COMMENT_MODE,d,t,a,i,o,{className:"function",beginKeywords:"fun",end:"[(]|$",returnBegin:!0,excludeEnd:!0,keywords:n,relevance:5,contains:[{begin:e.UNDERSCORE_IDENT_RE+"\\s*\\(",returnBegin:!0,relevance:0,contains:[e.UNDERSCORE_TITLE_MODE]},{className:"type",begin:/</,end:/>/,keywords:"reified",relevance:0},{className:"params",begin:/\(/,end:/\)/,endsParent:!0,keywords:n,relevance:0,contains:[{begin:/:/,end:/[=,\/]/,endsWithParent:!0,contains:[m,e.C_LINE_COMMENT_MODE,d],relevance:0},e.C_LINE_COMMENT_MODE,d,i,o,r,e.C_NUMBER_MODE]},d]},{begin:[/class|interface|trait/,/\s+/,e.UNDERSCORE_IDENT_RE],beginScope:{3:"title.class"},keywords:"class interface trait",end:/[:\{(]|$/,excludeEnd:!0,illegal:"extends implements",contains:[{beginKeywords:"public protected internal private constructor"},e.UNDERSCORE_TITLE_MODE,{className:"type",begin:/</,end:/>/,excludeBegin:!0,excludeEnd:!0,relevance:0},{className:"type",begin:/[,:]\s*/,end:/[<\(,){\s]|$/,excludeBegin:!0,returnEnd:!0},i,o]},r,{className:"meta",begin:"^#!/usr/bin/env",end:"$",illegal:`
`},c]}}nt.exports=Di});var st=k((qr,rt)=>{var Li=e=>({IMPORTANT:{scope:"meta",begin:"!important"},BLOCK_COMMENT:e.C_BLOCK_COMMENT_MODE,HEXCOLOR:{scope:"number",begin:/#(([0-9a-fA-F]{3,4})|(([0-9a-fA-F]{2}){3,4}))\b/},UNICODE_RANGE:{scope:"number",begin:/\b[Uu]\+[0-9A-Fa-f][0-9A-Fa-f?]{0,5}(-[0-9A-Fa-f][0-9A-Fa-f]{0,5})?/},FUNCTION_DISPATCH:{className:"built_in",begin:/[\w-]+(?=\()/},ATTRIBUTE_SELECTOR_MODE:{scope:"selector-attr",begin:/\[/,end:/\]/,illegal:"$",contains:[e.APOS_STRING_MODE,e.QUOTE_STRING_MODE]},CSS_NUMBER_MODE:{scope:"number",begin:e.NUMBER_RE+"(%|em|ex|ch|rem|vw|vh|vmin|vmax|cm|mm|in|pt|pc|px|deg|grad|rad|turn|s|ms|Hz|kHz|dpi|dpcm|dppx)?",relevance:0},CSS_VARIABLE:{className:"attr",begin:/--[A-Za-z_][A-Za-z0-9_-]*/}}),Bi=["a","abbr","address","article","aside","audio","b","blockquote","body","button","canvas","caption","cite","code","dd","del","details","dfn","div","dl","dt","em","fieldset","figcaption","figure","footer","form","h1","h2","h3","h4","h5","h6","header","hgroup","html","i","iframe","img","input","ins","kbd","label","legend","li","main","mark","menu","nav","object","ol","optgroup","option","p","picture","q","quote","samp","section","select","source","span","strong","summary","sup","table","tbody","td","textarea","tfoot","th","thead","time","tr","ul","var","video"],Ui=["defs","g","marker","mask","pattern","svg","switch","symbol","feBlend","feColorMatrix","feComponentTransfer","feComposite","feConvolveMatrix","feDiffuseLighting","feDisplacementMap","feFlood","feGaussianBlur","feImage","feMerge","feMorphology","feOffset","feSpecularLighting","feTile","feTurbulence","linearGradient","radialGradient","stop","circle","ellipse","image","line","path","polygon","polyline","rect","text","use","textPath","tspan","foreignObject","clipPath"],Pi=[...Bi,...Ui],Fi=["any-hover","any-pointer","aspect-ratio","color","color-gamut","color-index","device-aspect-ratio","device-height","device-width","display-mode","forced-colors","grid","height","hover","inverted-colors","monochrome","orientation","overflow-block","overflow-inline","pointer","prefers-color-scheme","prefers-contrast","prefers-reduced-motion","prefers-reduced-transparency","resolution","scan","scripting","update","width","min-width","max-width","min-height","max-height"].sort().reverse(),at=["active","any-link","blank","checked","current","default","defined","dir","disabled","drop","empty","enabled","first","first-child","first-of-type","fullscreen","future","focus","focus-visible","focus-within","has","host","host-context","hover","indeterminate","in-range","invalid","is","lang","last-child","last-of-type","left","link","local-link","not","nth-child","nth-col","nth-last-child","nth-last-col","nth-last-of-type","nth-of-type","only-child","only-of-type","optional","out-of-range","past","placeholder-shown","read-only","read-write","required","right","root","scope","target","target-within","user-invalid","valid","visited","where"].sort().reverse(),it=["after","backdrop","before","cue","cue-region","first-letter","first-line","grammar-error","marker","part","placeholder","selection","slotted","spelling-error"].sort().reverse(),zi=["accent-color","align-content","align-items","align-self","alignment-baseline","all","anchor-name","animation","animation-composition","animation-delay","animation-direction","animation-duration","animation-fill-mode","animation-iteration-count","animation-name","animation-play-state","animation-range","animation-range-end","animation-range-start","animation-timeline","animation-timing-function","appearance","aspect-ratio","backdrop-filter","backface-visibility","background","background-attachment","background-blend-mode","background-clip","background-color","background-image","background-origin","background-position","background-position-x","background-position-y","background-repeat","background-size","baseline-shift","block-size","border","border-block","border-block-color","border-block-end","border-block-end-color","border-block-end-style","border-block-end-width","border-block-start","border-block-start-color","border-block-start-style","border-block-start-width","border-block-style","border-block-width","border-bottom","border-bottom-color","border-bottom-left-radius","border-bottom-right-radius","border-bottom-style","border-bottom-width","border-collapse","border-color","border-end-end-radius","border-end-start-radius","border-image","border-image-outset","border-image-repeat","border-image-slice","border-image-source","border-image-width","border-inline","border-inline-color","border-inline-end","border-inline-end-color","border-inline-end-style","border-inline-end-width","border-inline-start","border-inline-start-color","border-inline-start-style","border-inline-start-width","border-inline-style","border-inline-width","border-left","border-left-color","border-left-style","border-left-width","border-radius","border-right","border-right-color","border-right-style","border-right-width","border-spacing","border-start-end-radius","border-start-start-radius","border-style","border-top","border-top-color","border-top-left-radius","border-top-right-radius","border-top-style","border-top-width","border-width","bottom","box-align","box-decoration-break","box-direction","box-flex","box-flex-group","box-lines","box-ordinal-group","box-orient","box-pack","box-shadow","box-sizing","break-after","break-before","break-inside","caption-side","caret-color","clear","clip","clip-path","clip-rule","color","color-interpolation","color-interpolation-filters","color-profile","color-rendering","color-scheme","column-count","column-fill","column-gap","column-rule","column-rule-color","column-rule-style","column-rule-width","column-span","column-width","columns","contain","contain-intrinsic-block-size","contain-intrinsic-height","contain-intrinsic-inline-size","contain-intrinsic-size","contain-intrinsic-width","container","container-name","container-type","content","content-visibility","corner-bottom-left-shape","corner-bottom-right-shape","corner-shape","corner-top-left-shape","corner-top-right-shape","counter-increment","counter-reset","counter-set","cue","cue-after","cue-before","cursor","cx","cy","direction","display","dominant-baseline","empty-cells","enable-background","field-sizing","fill","fill-opacity","fill-rule","filter","flex","flex-basis","flex-direction","flex-flow","flex-grow","flex-shrink","flex-wrap","float","flood-color","flood-opacity","flow","font","font-display","font-family","font-feature-settings","font-kerning","font-language-override","font-optical-sizing","font-palette","font-size","font-size-adjust","font-smooth","font-smoothing","font-stretch","font-style","font-synthesis","font-synthesis-position","font-synthesis-small-caps","font-synthesis-style","font-synthesis-weight","font-variant","font-variant-alternates","font-variant-caps","font-variant-east-asian","font-variant-emoji","font-variant-ligatures","font-variant-numeric","font-variant-position","font-variation-settings","font-weight","forced-color-adjust","gap","glyph-orientation-horizontal","glyph-orientation-vertical","grid","grid-area","grid-auto-columns","grid-auto-flow","grid-auto-rows","grid-column","grid-column-end","grid-column-start","grid-gap","grid-row","grid-row-end","grid-row-start","grid-template","grid-template-areas","grid-template-columns","grid-template-rows","hanging-punctuation","height","hyphenate-character","hyphenate-limit-chars","hyphens","icon","image-orientation","image-rendering","image-resolution","ime-mode","initial-letter","initial-letter-align","inline-size","inset","inset-area","inset-block","inset-block-end","inset-block-start","inset-inline","inset-inline-end","inset-inline-start","isolation","justify-content","justify-items","justify-self","kerning","left","letter-spacing","lighting-color","line-break","line-height","line-height-step","list-style","list-style-image","list-style-position","list-style-type","margin","margin-block","margin-block-end","margin-block-start","margin-bottom","margin-inline","margin-inline-end","margin-inline-start","margin-left","margin-right","margin-top","margin-trim","marker","marker-end","marker-mid","marker-start","marks","mask","mask-border","mask-border-mode","mask-border-outset","mask-border-repeat","mask-border-slice","mask-border-source","mask-border-width","mask-clip","mask-composite","mask-image","mask-mode","mask-origin","mask-position","mask-repeat","mask-size","mask-type","masonry-auto-flow","math-depth","math-shift","math-style","max-block-size","max-height","max-inline-size","max-width","min-block-size","min-height","min-inline-size","min-width","mix-blend-mode","nav-down","nav-index","nav-left","nav-right","nav-up","none","normal","object-fit","object-position","offset","offset-anchor","offset-distance","offset-path","offset-position","offset-rotate","opacity","order","orphans","outline","outline-color","outline-offset","outline-style","outline-width","overflow","overflow-anchor","overflow-block","overflow-clip-margin","overflow-inline","overflow-wrap","overflow-x","overflow-y","overlay","overscroll-behavior","overscroll-behavior-block","overscroll-behavior-inline","overscroll-behavior-x","overscroll-behavior-y","padding","padding-block","padding-block-end","padding-block-start","padding-bottom","padding-inline","padding-inline-end","padding-inline-start","padding-left","padding-right","padding-top","page","page-break-after","page-break-before","page-break-inside","paint-order","pause","pause-after","pause-before","perspective","perspective-origin","place-content","place-items","place-self","pointer-events","position","position-anchor","position-visibility","print-color-adjust","quotes","r","resize","rest","rest-after","rest-before","right","rotate","row-gap","ruby-align","ruby-position","scale","scroll-behavior","scroll-margin","scroll-margin-block","scroll-margin-block-end","scroll-margin-block-start","scroll-margin-bottom","scroll-margin-inline","scroll-margin-inline-end","scroll-margin-inline-start","scroll-margin-left","scroll-margin-right","scroll-margin-top","scroll-padding","scroll-padding-block","scroll-padding-block-end","scroll-padding-block-start","scroll-padding-bottom","scroll-padding-inline","scroll-padding-inline-end","scroll-padding-inline-start","scroll-padding-left","scroll-padding-right","scroll-padding-top","scroll-snap-align","scroll-snap-stop","scroll-snap-type","scroll-timeline","scroll-timeline-axis","scroll-timeline-name","scrollbar-color","scrollbar-gutter","scrollbar-width","shape-image-threshold","shape-margin","shape-outside","shape-rendering","speak","speak-as","src","stop-color","stop-opacity","stroke","stroke-dasharray","stroke-dashoffset","stroke-linecap","stroke-linejoin","stroke-miterlimit","stroke-opacity","stroke-width","tab-size","table-layout","text-align","text-align-all","text-align-last","text-anchor","text-combine-upright","text-decoration","text-decoration-color","text-decoration-line","text-decoration-skip","text-decoration-skip-ink","text-decoration-style","text-decoration-thickness","text-emphasis","text-emphasis-color","text-emphasis-position","text-emphasis-style","text-indent","text-justify","text-orientation","text-overflow","text-rendering","text-shadow","text-size-adjust","text-transform","text-underline-offset","text-underline-position","text-wrap","text-wrap-mode","text-wrap-style","timeline-scope","top","touch-action","transform","transform-box","transform-origin","transform-style","transition","transition-behavior","transition-delay","transition-duration","transition-property","transition-timing-function","translate","unicode-bidi","unicode-range","user-modify","user-select","vector-effect","vertical-align","view-timeline","view-timeline-axis","view-timeline-inset","view-timeline-name","view-transition-name","visibility","voice-balance","voice-duration","voice-family","voice-pitch","voice-range","voice-rate","voice-stress","voice-volume","white-space","white-space-collapse","widows","width","will-change","word-break","word-spacing","word-wrap","writing-mode","x","y","z-index","zoom"].sort().reverse(),$i=at.concat(it).sort().reverse();function Gi(e){let n=Li(e),t=$i,a="and or not only",s="[\\w-]+",u="("+s+"|@\\{"+s+"\\})",r=[],i=[],o=function(R){return{className:"string",begin:"~?"+R+".*?"+R}},c=function(R,S,A){return{className:R,begin:S,relevance:A}},d={$pattern:/[a-z-]+/,keyword:a,attribute:Fi.join(" ")},m={begin:"\\(",end:"\\)",contains:i,keywords:d,relevance:0};i.push(e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE,o("'"),o('"'),n.CSS_NUMBER_MODE,{begin:"(url|data-uri)\\(",starts:{className:"string",end:"[\\)\\n]",excludeEnd:!0}},n.UNICODE_RANGE,n.HEXCOLOR,m,c("variable","@@?"+s,10),c("variable","@\\{"+s+"\\}"),c("built_in","~?`[^`]*?`"),{className:"attribute",begin:s+"\\s*:",end:":",returnBegin:!0,excludeEnd:!0},n.IMPORTANT,{beginKeywords:"and not"},n.FUNCTION_DISPATCH);let g=i.concat({begin:/\{/,end:/\}/,contains:r}),p={beginKeywords:"when",endsWithParent:!0,contains:[{beginKeywords:"and not"}].concat(i)},y={begin:u+"\\s*:",returnBegin:!0,end:/[;}]/,relevance:0,contains:[{begin:/-(webkit|moz|ms|o)-/},n.CSS_VARIABLE,{className:"attribute",begin:"\\b("+zi.join("|")+")\\b",end:/(?=:)/,starts:{endsWithParent:!0,illegal:"[<=$]",relevance:0,contains:i}}]},h={className:"keyword",begin:"@(import|media|charset|font-face|(-[a-z]+-)?keyframes|supports|document|namespace|page|viewport|host)\\b",starts:{end:"[;{}]",keywords:d,returnEnd:!0,contains:i,relevance:0}},T={className:"variable",variants:[{begin:"@"+s+"\\s*:",relevance:15},{begin:"@"+s}],starts:{end:"[;}]",returnEnd:!0,contains:g}},N={variants:[{begin:"[\\.#:&\\[>]",end:"[;{}]"},{begin:u,end:/\{/}],returnBegin:!0,returnEnd:!0,illegal:`[<='$"]`,relevance:0,contains:[e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE,p,c("keyword","all\\b"),c("variable","@\\{"+s+"\\}"),{begin:"\\b("+Pi.join("|")+")\\b",className:"selector-tag"},n.CSS_NUMBER_MODE,c("selector-tag",u,0),c("selector-id","#"+u),c("selector-class","\\."+u,0),c("selector-tag","&",0),n.ATTRIBUTE_SELECTOR_MODE,{className:"selector-pseudo",begin:":("+at.join("|")+")"},{className:"selector-pseudo",begin:":(:)?("+it.join("|")+")"},{begin:/\(/,end:/\)/,relevance:0,contains:g},{begin:"!important"},n.FUNCTION_DISPATCH]},C={begin:s+`:(:)?(${t.join("|")})`,returnBegin:!0,contains:[N]};return r.push(e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE,h,T,C,y,N,p,n.FUNCTION_DISPATCH),{name:"Less",case_insensitive:!0,illegal:`[=>'/<($"]`,contains:r}}rt.exports=Gi});var ct=k((Zr,ot)=>{function Ki(e){let n="\\[=*\\[",t="\\]=*\\]",a={begin:n,end:t,contains:["self"]},s=[e.COMMENT("--(?!"+n+")","$"),e.COMMENT("--"+n,t,{contains:[a],relevance:10})];return{name:"Lua",aliases:["pluto"],keywords:{$pattern:e.UNDERSCORE_IDENT_RE,literal:"true false nil",keyword:"and break do else elseif end for goto if in local global not or repeat return then until while",built_in:"_G _ENV _VERSION __index __newindex __mode __call __metatable __tostring __len __gc __add __sub __mul __div __mod __pow __concat __unm __eq __lt __le assert collectgarbage dofile error getfenv getmetatable ipairs load loadfile loadstring module next pairs pcall print rawequal rawget rawset require select setfenv setmetatable tonumber tostring type unpack xpcall arg self coroutine resume yield status wrap create running debug getupvalue debug sethook getmetatable gethook setmetatable setlocal traceback setfenv getinfo setupvalue getlocal getregistry getfenv io lines write close flush open output type read stderr stdin input stdout popen tmpfile math log max acos huge ldexp pi cos tanh pow deg tan cosh sinh random randomseed frexp ceil floor rad abs sqrt modf asin min mod fmod log10 atan2 exp sin atan os exit setlocale date getenv difftime remove time clock tmpname rename execute package preload loadlib loaded loaders cpath config path seeall string sub upper len gfind rep find match char dump gmatch reverse byte format gsub lower table setn insert getn foreachi maxn foreach concat sort remove"},contains:s.concat([{className:"function",beginKeywords:"function",end:"\\)",contains:[e.inherit(e.TITLE_MODE,{begin:"([_a-zA-Z]\\w*\\.)*([_a-zA-Z]\\w*:)?[_a-zA-Z]\\w*"}),{className:"params",begin:"\\(",endsWithParent:!0,contains:s}].concat(s)},e.C_NUMBER_MODE,e.APOS_STRING_MODE,e.QUOTE_STRING_MODE,{className:"string",begin:n,end:t,contains:[a],relevance:5}])}}ot.exports=Ki});var dt=k((Wr,lt)=>{function Hi(e){let n={className:"variable",variants:[{begin:"\\$\\("+e.UNDERSCORE_IDENT_RE+"\\)",contains:[e.BACKSLASH_ESCAPE]},{begin:/\$[@%<?\^\+\*]/}]},t={className:"string",begin:/"/,end:/"/,contains:[e.BACKSLASH_ESCAPE,n]},a={className:"variable",begin:/\$\([\w-]+\s/,end:/\)/,keywords:{built_in:"subst patsubst strip findstring filter filter-out sort word wordlist firstword lastword dir notdir suffix basename addsuffix addprefix join wildcard realpath abspath error warning shell origin flavor foreach if or and call eval file value"},contains:[n,t]},s={begin:"^"+e.UNDERSCORE_IDENT_RE+"\\s*(?=[:+?]?=)"},u={className:"meta",begin:/^\.PHONY:/,end:/$/,keywords:{$pattern:/[\.\w]+/,keyword:".PHONY"}},r={className:"section",begin:/^[^\s]+:/,end:/$/,contains:[n]};return{name:"Makefile",aliases:["mk","mak","make"],keywords:{$pattern:/[\w-]+/,keyword:"define endef undefine ifdef ifndef ifeq ifneq else endif include -include sinclude override export unexport private vpath"},contains:[e.HASH_COMMENT_MODE,n,t,a,s,u,r]}}lt.exports=Hi});var gt=k((Yr,ut)=>{function qi(e){let n=e.regex,t=["abs","accept","alarm","and","atan2","bind","binmode","bless","break","caller","chdir","chmod","chomp","chop","chown","chr","chroot","class","close","closedir","connect","continue","cos","crypt","dbmclose","dbmopen","defined","delete","die","do","dump","each","else","elsif","endgrent","endhostent","endnetent","endprotoent","endpwent","endservent","eof","eval","exec","exists","exit","exp","fcntl","field","fileno","flock","for","foreach","fork","format","formline","getc","getgrent","getgrgid","getgrnam","gethostbyaddr","gethostbyname","gethostent","getlogin","getnetbyaddr","getnetbyname","getnetent","getpeername","getpgrp","getpriority","getprotobyname","getprotobynumber","getprotoent","getpwent","getpwnam","getpwuid","getservbyname","getservbyport","getservent","getsockname","getsockopt","given","glob","gmtime","goto","grep","gt","hex","if","index","int","ioctl","join","keys","kill","last","lc","lcfirst","length","link","listen","local","localtime","log","lstat","lt","ma","map","method","mkdir","msgctl","msgget","msgrcv","msgsnd","my","ne","next","no","not","oct","open","opendir","or","ord","our","pack","package","pipe","pop","pos","print","printf","prototype","push","q|0","qq","quotemeta","qw","qx","rand","read","readdir","readline","readlink","readpipe","recv","redo","ref","rename","require","reset","return","reverse","rewinddir","rindex","rmdir","say","scalar","seek","seekdir","select","semctl","semget","semop","send","setgrent","sethostent","setnetent","setpgrp","setpriority","setprotoent","setpwent","setservent","setsockopt","shift","shmctl","shmget","shmread","shmwrite","shutdown","sin","sleep","socket","socketpair","sort","splice","split","sprintf","sqrt","srand","stat","state","study","sub","substr","symlink","syscall","sysopen","sysread","sysseek","system","syswrite","tell","telldir","tie","tied","time","times","tr","truncate","uc","ucfirst","umask","undef","unless","unlink","unpack","unshift","untie","until","use","utime","values","vec","wait","waitpid","wantarray","warn","when","while","write","x|0","xor","y|0"],a=/[dualxmsipngr]{0,12}/,s={$pattern:/[\w.]+/,keyword:t.join(" ")},u={className:"subst",begin:"[$@]\\{",end:"\\}",keywords:s},r={begin:/->\{/,end:/\}/},i={scope:"attr",match:/\s+:\s*\w+(\s*\(.*?\))?/},o={scope:"variable",variants:[{begin:/\$\d/},{begin:n.concat(/[$%@](?!")(\^\w\b|#\w+(::\w+)*|\{\w+\}|\w+(::\w*)*)/,"(?![A-Za-z])(?![@$%])")},{begin:/[$%@](?!")[^\s\w{=]|\$=/,relevance:0}],contains:[i]},c={className:"number",variants:[{match:/0?\.[0-9][0-9_]+\b/},{match:/\bv?(0|[1-9][0-9_]*(\.[0-9_]+)?|[1-9][0-9_]*)\b/},{match:/\b0[0-7][0-7_]*\b/},{match:/\b0x[0-9a-fA-F][0-9a-fA-F_]*\b/},{match:/\b0b[0-1][0-1_]*\b/}],relevance:0},d=[e.BACKSLASH_ESCAPE,u,o],m=[/!/,/\//,/\|/,/\?/,/'/,/"/,/#/],g=(h,T,N="\\1")=>{let C=N==="\\1"?N:n.concat(N,T);return n.concat(n.concat("(?:",h,")"),T,/(?:\\.|[^\\\/])*?/,C,/(?:\\.|[^\\\/])*?/,N,a)},p=(h,T,N)=>n.concat(n.concat("(?:",h,")"),T,/(?:\\.|[^\\\/])*?/,N,a),y=[o,e.HASH_COMMENT_MODE,e.COMMENT(/^=\w/,/=cut/,{endsWithParent:!0}),r,{className:"string",contains:d,variants:[{begin:"q[qwxr]?\\s*\\(",end:"\\)",relevance:5},{begin:"q[qwxr]?\\s*\\[",end:"\\]",relevance:5},{begin:"q[qwxr]?\\s*\\{",end:"\\}",relevance:5},{begin:"q[qwxr]?\\s*\\|",end:"\\|",relevance:5},{begin:"q[qwxr]?\\s*<",end:">",relevance:5},{begin:"qw\\s+q",end:"q",relevance:5},{begin:"'",end:"'",contains:[e.BACKSLASH_ESCAPE]},{begin:'"',end:'"'},{begin:"`",end:"`",contains:[e.BACKSLASH_ESCAPE]},{begin:/\{\w+\}/,relevance:0},{begin:"-?\\w+\\s*=>",relevance:0}]},c,{begin:"(\\/\\/|"+e.RE_STARTERS_RE+"|\\b(split|return|print|reverse|grep)\\b)\\s*",keywords:"split return print reverse grep",relevance:0,contains:[e.HASH_COMMENT_MODE,{className:"regexp",variants:[{begin:g("s|tr|y",n.either(...m,{capture:!0}))},{begin:g("s|tr|y","\\(","\\)")},{begin:g("s|tr|y","\\[","\\]")},{begin:g("s|tr|y","\\{","\\}")}],relevance:2},{className:"regexp",variants:[{begin:/(m|qr)\/\//,relevance:0},{begin:p("(?:m|qr)?",/\//,/\//)},{begin:p("m|qr",n.either(...m,{capture:!0}),/\1/)},{begin:p("m|qr",/\(/,/\)/)},{begin:p("m|qr",/\[/,/\]/)},{begin:p("m|qr",/\{/,/\}/)}]}]},{className:"function",beginKeywords:"sub method",end:"(\\s*\\(.*?\\))?[;{]",excludeEnd:!0,relevance:5,contains:[e.TITLE_MODE,i]},{className:"class",beginKeywords:"class",end:"[;{]",excludeEnd:!0,relevance:5,contains:[e.TITLE_MODE,i,c]},{begin:"-\\w\\b",relevance:0},{begin:"^__DATA__$",end:"^__END__$",subLanguage:"mojolicious",contains:[{begin:"^@@.*",end:"$",className:"comment"}]}];return u.contains=y,r.contains=y,{name:"Perl",aliases:["pl","pm"],keywords:s,contains:y}}ut.exports=qi});var pt=k((Xr,bt)=>{function Zi(e){let n={className:"built_in",begin:"\\b(AV|CA|CF|CG|CI|CL|CM|CN|CT|MK|MP|MTK|MTL|NS|SCN|SK|UI|WK|XC)\\w+"},t=/[a-zA-Z@][a-zA-Z0-9_]*/,i={"variable.language":["this","super"],$pattern:t,keyword:["while","export","sizeof","typedef","const","struct","for","union","volatile","static","mutable","if","do","return","goto","enum","else","break","extern","asm","case","default","register","explicit","typename","switch","continue","inline","readonly","assign","readwrite","self","@synchronized","id","typeof","nonatomic","IBOutlet","IBAction","strong","weak","copy","in","out","inout","bycopy","byref","oneway","__strong","__weak","__block","__autoreleasing","@private","@protected","@public","@try","@property","@end","@throw","@catch","@finally","@autoreleasepool","@synthesize","@dynamic","@selector","@optional","@required","@encode","@package","@import","@defs","@compatibility_alias","__bridge","__bridge_transfer","__bridge_retained","__bridge_retain","__covariant","__contravariant","__kindof","_Nonnull","_Nullable","_Null_unspecified","__FUNCTION__","__PRETTY_FUNCTION__","__attribute__","getter","setter","retain","unsafe_unretained","nonnull","nullable","null_unspecified","null_resettable","class","instancetype","NS_DESIGNATED_INITIALIZER","NS_UNAVAILABLE","NS_REQUIRES_SUPER","NS_RETURNS_INNER_POINTER","NS_INLINE","NS_AVAILABLE","NS_DEPRECATED","NS_ENUM","NS_OPTIONS","NS_SWIFT_UNAVAILABLE","NS_ASSUME_NONNULL_BEGIN","NS_ASSUME_NONNULL_END","NS_REFINED_FOR_SWIFT","NS_SWIFT_NAME","NS_SWIFT_NOTHROW","NS_DURING","NS_HANDLER","NS_ENDHANDLER","NS_VALUERETURN","NS_VOIDRETURN"],literal:["false","true","FALSE","TRUE","nil","YES","NO","NULL"],built_in:["dispatch_once_t","dispatch_queue_t","dispatch_sync","dispatch_async","dispatch_once"],type:["int","float","char","unsigned","signed","short","long","double","wchar_t","unichar","void","bool","BOOL","id|0","_Bool"]},o={$pattern:t,keyword:["@interface","@class","@protocol","@implementation"]};return{name:"Objective-C",aliases:["mm","objc","obj-c","obj-c++","objective-c++"],keywords:i,illegal:"</",contains:[n,e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE,e.C_NUMBER_MODE,e.QUOTE_STRING_MODE,e.APOS_STRING_MODE,{className:"string",variants:[{begin:'@"',end:'"',illegal:"\\n",contains:[e.BACKSLASH_ESCAPE]}]},{className:"meta",begin:/#\s*[a-z]+\b/,end:/$/,keywords:{keyword:"if else elif endif define undef warning error line pragma ifdef ifndef include"},contains:[{begin:/\\\n/,relevance:0},e.inherit(e.QUOTE_STRING_MODE,{className:"string"}),{className:"string",begin:/<.*?>/,end:/$/,illegal:"\\n"},e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE]},{className:"class",begin:"("+o.keyword.join("|")+")\\b",end:/(\{|$)/,excludeEnd:!0,keywords:o,contains:[e.UNDERSCORE_TITLE_MODE]},{begin:"\\."+e.UNDERSCORE_IDENT_RE,relevance:0}]}}bt.exports=Zi});var _t=k((Vr,mt)=>{function Wi(e){let n=e.regex,t=/(?![A-Za-z0-9])(?![$])/,a=n.concat(/[a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*/,t),s=n.concat(/(\\?[A-Z][a-z0-9_\x7f-\xff]+|\\?[A-Z]+(?=[A-Z][a-z0-9_\x7f-\xff])){1,}/,t),u=n.concat(/[A-Z]+/,t),r={scope:"variable",match:"\\$+"+a},i={scope:"meta",variants:[{begin:/<\?php/,relevance:10},{begin:/<\?=/},{begin:/<\?/,relevance:.1},{begin:/\?>/}]},o={scope:"subst",variants:[{begin:/\$\w+/},{begin:/\{\$/,end:/\}/}]},c=e.inherit(e.APOS_STRING_MODE,{illegal:null}),d=e.inherit(e.QUOTE_STRING_MODE,{illegal:null,contains:e.QUOTE_STRING_MODE.contains.concat(o)}),m={begin:/<<<[ \t]*(?:(\w+)|"(\w+)")\n/,end:/[ \t]*(\w+)\b/,contains:e.QUOTE_STRING_MODE.contains.concat(o),"on:begin":(q,Z)=>{Z.data._beginMatch=q[1]||q[2]},"on:end":(q,Z)=>{Z.data._beginMatch!==q[1]&&Z.ignoreMatch()}},g=e.END_SAME_AS_BEGIN({begin:/<<<[ \t]*'(\w+)'\n/,end:/[ \t]*(\w+)\b/}),p=`[ 	
]`,y={scope:"string",variants:[d,c,m,g]},h={scope:"number",variants:[{begin:"\\b0[bB][01]+(?:_[01]+)*\\b"},{begin:"\\b0[oO][0-7]+(?:_[0-7]+)*\\b"},{begin:"\\b0[xX][\\da-fA-F]+(?:_[\\da-fA-F]+)*\\b"},{begin:"(?:\\b\\d+(?:_\\d+)*(\\.(?:\\d+(?:_\\d+)*))?|\\B\\.\\d+)(?:[eE][+-]?\\d+)?"}],relevance:0},T=["false","null","true"],N=["__CLASS__","__DIR__","__FILE__","__FUNCTION__","__COMPILER_HALT_OFFSET__","__LINE__","__METHOD__","__NAMESPACE__","__TRAIT__","die","echo","exit","include","include_once","print","require","require_once","array","abstract","and","as","binary","bool","boolean","break","callable","case","catch","class","clone","const","continue","declare","default","do","double","else","elseif","empty","enddeclare","endfor","endforeach","endif","endswitch","endwhile","enum","eval","extends","final","finally","float","for","foreach","from","global","goto","if","implements","instanceof","insteadof","int","integer","interface","isset","iterable","list","match|0","mixed","new","never","object","or","private","protected","public","readonly","real","return","string","switch","throw","trait","try","unset","use","var","void","while","xor","yield"],C=["Error|0","AppendIterator","ArgumentCountError","ArithmeticError","ArrayIterator","ArrayObject","AssertionError","BadFunctionCallException","BadMethodCallException","CachingIterator","CallbackFilterIterator","CompileError","Countable","DirectoryIterator","DivisionByZeroError","DomainException","EmptyIterator","ErrorException","Exception","FilesystemIterator","FilterIterator","GlobIterator","InfiniteIterator","InvalidArgumentException","IteratorIterator","LengthException","LimitIterator","LogicException","MultipleIterator","NoRewindIterator","OutOfBoundsException","OutOfRangeException","OuterIterator","OverflowException","ParentIterator","ParseError","RangeException","RecursiveArrayIterator","RecursiveCachingIterator","RecursiveCallbackFilterIterator","RecursiveDirectoryIterator","RecursiveFilterIterator","RecursiveIterator","RecursiveIteratorIterator","RecursiveRegexIterator","RecursiveTreeIterator","RegexIterator","RuntimeException","SeekableIterator","SplDoublyLinkedList","SplFileInfo","SplFileObject","SplFixedArray","SplHeap","SplMaxHeap","SplMinHeap","SplObjectStorage","SplObserver","SplPriorityQueue","SplQueue","SplStack","SplSubject","SplTempFileObject","TypeError","UnderflowException","UnexpectedValueException","UnhandledMatchError","ArrayAccess","BackedEnum","Closure","Fiber","Generator","Iterator","IteratorAggregate","Serializable","Stringable","Throwable","Traversable","UnitEnum","WeakReference","WeakMap","Directory","__PHP_Incomplete_Class","parent","php_user_filter","self","static","stdClass"],S={keyword:N,literal:(q=>{let Z=[];return q.forEach(l=>{Z.push(l),l.toLowerCase()===l?Z.push(l.toUpperCase()):Z.push(l.toLowerCase())}),Z})(T),built_in:C},A=q=>q.map(Z=>Z.replace(/\|\d+$/,"")),M={variants:[{match:[/new/,n.concat(p,"+"),n.concat("(?!",A(C).join("\\b|"),"\\b)"),s],scope:{1:"keyword",4:"title.class"}}]},L=n.concat(a,"\\b(?!\\()"),D={variants:[{match:[n.concat(/::/,n.lookahead(/(?!class\b)/)),L],scope:{2:"variable.constant"}},{match:[/::/,/class/],scope:{2:"variable.language"}},{match:[s,n.concat(/::/,n.lookahead(/(?!class\b)/)),L],scope:{1:"title.class",3:"variable.constant"}},{match:[s,n.concat("::",n.lookahead(/(?!class\b)/))],scope:{1:"title.class"}},{match:[s,/::/,/class/],scope:{1:"title.class",3:"variable.language"}}]},U={scope:"attr",match:n.concat(a,n.lookahead(":"),n.lookahead(/(?!::)/))},O={relevance:0,begin:/\(/,end:/\)/,keywords:S,contains:[U,r,D,e.C_BLOCK_COMMENT_MODE,e.C_LINE_COMMENT_MODE,e.HASH_COMMENT_MODE,y,h,M]},H={relevance:0,match:[/\b/,n.concat("(?!fn\\b|function\\b|",A(N).join("\\b|"),"|",A(C).join("\\b|"),"\\b)"),a,n.concat(p,"*"),n.lookahead(/(?=\()/)],scope:{3:"title.function.invoke"},contains:[O]};O.contains.push(H);let J=[U,D,e.C_BLOCK_COMMENT_MODE,e.C_LINE_COMMENT_MODE,e.HASH_COMMENT_MODE,y,h,M],ne={begin:n.concat(/#\[\s*\\?/,n.either(s,u)),beginScope:"meta",end:/]/,endScope:"meta",keywords:{literal:T,keyword:["new","array"]},contains:[{begin:/\[/,end:/]/,keywords:{literal:T,keyword:["new","array"]},contains:["self",...J]},...J,{scope:"meta",variants:[{match:s},{match:u}]}]};return{case_insensitive:!1,keywords:S,contains:[ne,e.HASH_COMMENT_MODE,e.COMMENT("//","$"),e.COMMENT("/\\*","\\*/",{contains:[{scope:"doctag",match:"@[A-Za-z]+"}]}),{match:/__halt_compiler\(\);/,keywords:"__halt_compiler",starts:{scope:"comment",end:e.MATCH_NOTHING_RE,contains:[{match:/\?>/,scope:"meta",endsParent:!0}]}},i,{scope:"variable.language",match:/\$this\b/},r,H,D,{match:[/const/,/\s/,a],scope:{1:"keyword",3:"variable.constant"}},M,{scope:"function",relevance:0,beginKeywords:"fn function",end:/[;{]/,excludeEnd:!0,illegal:"[$%\\[]",contains:[{beginKeywords:"use"},e.UNDERSCORE_TITLE_MODE,{begin:"=>",endsParent:!0},{scope:"params",begin:"\\(",end:"\\)",excludeBegin:!0,excludeEnd:!0,keywords:S,contains:["self",ne,r,D,e.C_BLOCK_COMMENT_MODE,e.C_LINE_COMMENT_MODE,e.HASH_COMMENT_MODE,y,h]}]},{scope:"class",variants:[{beginKeywords:"enum",illegal:/[($"]/},{beginKeywords:"class interface trait",illegal:/[:($"]/}],relevance:0,end:/\{/,excludeEnd:!0,contains:[{beginKeywords:"extends implements"},e.UNDERSCORE_TITLE_MODE]},{beginKeywords:"namespace",relevance:0,end:";",illegal:/[.']/,contains:[e.inherit(e.UNDERSCORE_TITLE_MODE,{scope:"title.class"})]},{beginKeywords:"use",relevance:0,end:";",contains:[{match:/\b(as|const|function)\b/,scope:"keyword"},e.UNDERSCORE_TITLE_MODE]},y,h]}}mt.exports=Wi});var ft=k((Qr,Et)=>{function Yi(e){return{name:"PHP template",subLanguage:"xml",contains:[{begin:/<\?(php|=)?/,end:/\?>/,subLanguage:"php",contains:[{begin:"/\\*",end:"\\*/",skip:!0},{begin:'b"',end:'"',skip:!0},{begin:"b'",end:"'",skip:!0},e.inherit(e.APOS_STRING_MODE,{illegal:null,className:null,contains:null,skip:!0}),e.inherit(e.QUOTE_STRING_MODE,{illegal:null,className:null,contains:null,skip:!0})]}]}}Et.exports=Yi});var Nt=k((Jr,ht)=>{function Xi(e){return{name:"Plain text",aliases:["text","txt"],disableAutodetect:!0}}ht.exports=Xi});var Tt=k((jr,yt)=>{function Vi(e){let n=e.regex,t=/[\p{XID_Start}_]\p{XID_Continue}*/u,a=["and","as","assert","async","await","break","case","class","continue","def","del","elif","else","except","finally","for","from","global","if","import","in","is","lambda","lazy","match","nonlocal|10","not","or","pass","raise","return","try","while","with","yield"],i={$pattern:/[A-Za-z]\w+|__\w+__/,keyword:a,built_in:["__import__","abs","aiter","all","anext","any","ascii","bin","bool","breakpoint","bytearray","bytes","callable","chr","classmethod","compile","complex","delattr","dict","dir","divmod","enumerate","eval","exec","filter","float","format","frozendict","frozenset","getattr","globals","hasattr","hash","help","hex","id","input","int","isinstance","issubclass","iter","len","list","locals","map","max","memoryview","min","next","object","oct","open","ord","pow","print","property","range","repr","reversed","round","sentinel","set","setattr","slice","sorted","staticmethod","str","sum","super","tuple","type","vars","zip"],literal:["__debug__","Ellipsis","False","None","NotImplemented","True"],type:["Any","Callable","Coroutine","Dict","List","Literal","Generic","Optional","Sequence","Set","Tuple","Type","Union"]},o={className:"meta",begin:/^(>>>|\.\.\.) /},c={className:"subst",begin:/\{/,end:/\}/,keywords:i,illegal:/#/},d={begin:/\{\{/,relevance:0},m={className:"string",contains:[e.BACKSLASH_ESCAPE],variants:[{begin:/([uU]|[bB]|[rR]|[bB][rR]|[rR][bB])?'''/,end:/'''/,contains:[e.BACKSLASH_ESCAPE,o],relevance:10},{begin:/([uU]|[bB]|[rR]|[bB][rR]|[rR][bB])?"""/,end:/"""/,contains:[e.BACKSLASH_ESCAPE,o],relevance:10},{begin:/([fFtT][rR]|[rR][fFtT]|[fFtT])'''/,end:/'''/,contains:[e.BACKSLASH_ESCAPE,o,d,c]},{begin:/([fFtT][rR]|[rR][fFtT]|[fFtT])"""/,end:/"""/,contains:[e.BACKSLASH_ESCAPE,o,d,c]},{begin:/([uU]|[rR])'/,end:/'/,relevance:10},{begin:/([uU]|[rR])"/,end:/"/,relevance:10},{begin:/([bB]|[bB][rR]|[rR][bB])'/,end:/'/},{begin:/([bB]|[bB][rR]|[rR][bB])"/,end:/"/},{begin:/([fFtT][rR]|[rR][fFtT]|[fFtT])'/,end:/'/,contains:[e.BACKSLASH_ESCAPE,d,c]},{begin:/([fFtT][rR]|[rR][fFtT]|[fFtT])"/,end:/"/,contains:[e.BACKSLASH_ESCAPE,d,c]},e.APOS_STRING_MODE,e.QUOTE_STRING_MODE]},g="[0-9](_?[0-9])*",p=`(\\b(${g}))?\\.(${g})|\\b(${g})\\.`,y=`\\b|${a.join("|")}`,h={className:"number",relevance:0,variants:[{begin:`(\\b(${g})|(${p}))[eE][+-]?(${g})[jJ]?(?=${y})`},{begin:`(${p})[jJ]?`},{begin:`\\b([1-9](_?[0-9])*|0+(_?0)*)[lLjJ]?(?=${y})`},{begin:`\\b0[bB](_?[01])+[lL]?(?=${y})`},{begin:`\\b0[oO](_?[0-7])+[lL]?(?=${y})`},{begin:`\\b0[xX](_?[0-9a-fA-F])+[lL]?(?=${y})`},{begin:`\\b(${g})[jJ](?=${y})`}]},T={className:"comment",begin:n.lookahead(/# type:/),end:/$/,keywords:i,contains:[{begin:/# type:/},{begin:/#/,end:/\b\B/,endsWithParent:!0}]},N={className:"params",variants:[{className:"",begin:/\(\s*\)/,skip:!0},{begin:/\(/,end:/\)/,excludeBegin:!0,excludeEnd:!0,keywords:i,contains:["self",o,h,m,e.HASH_COMMENT_MODE]}]};return c.contains=[m,h,o],{name:"Python",aliases:["py","gyp","ipython"],unicodeRegex:!0,keywords:i,illegal:/(<\/|\?)|=>/,contains:[o,h,{scope:"variable.language",match:/\bself\b/},{beginKeywords:"if",relevance:0},{match:/\bor\b/,scope:"keyword"},m,T,e.HASH_COMMENT_MODE,{match:[/\bdef/,/\s+/,t],scope:{1:"keyword",3:"title.function"},contains:[N]},{variants:[{match:[/\bclass/,/\s+/,t,/\s*/,/\(\s*/,t,/\s*\)/]},{match:[/\bclass/,/\s+/,t]}],scope:{1:"keyword",3:"title.class",6:"title.class.inherited"}},{className:"meta",begin:/^[\t ]*@/,end:/(?=#)|$/,contains:[h,N,m]}]}}yt.exports=Vi});var St=k((es,vt)=>{function Qi(e){return{aliases:["pycon"],contains:[{className:"meta.prompt",starts:{end:/ |$/,starts:{end:"$",subLanguage:"python"}},variants:[{begin:/^>>>(?=[ ]|$)/},{begin:/^\.\.\.(?=[ ]|$)/}]}]}}vt.exports=Qi});var Ot=k((ns,At)=>{function Ji(e){let n=e.regex,t=/(?:(?:[a-zA-Z]|\.[._a-zA-Z])[._a-zA-Z0-9]*)|\.(?!\d)/,a=n.either(/0[xX][0-9a-fA-F]+\.[0-9a-fA-F]*[pP][+-]?\d+i?/,/0[xX][0-9a-fA-F]+(?:[pP][+-]?\d+)?[Li]?/,/(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?[Li]?/),s=/[=!<>:]=|\|\||&&|:::?|<-|<<-|->>|->|\|>|[-+*\/?!$&|:<=>@^~]|\*\*/,u=n.either(/[()]/,/[{}]/,/\[\[/,/[[\]]/,/\\/,/,/);return{name:"R",keywords:{$pattern:t,keyword:"function if in break next repeat else for while",literal:"NULL NA TRUE FALSE Inf NaN NA_integer_|10 NA_real_|10 NA_character_|10 NA_complex_|10",built_in:"LETTERS letters month.abb month.name pi T F abs acos acosh all any anyNA Arg as.call as.character as.complex as.double as.environment as.integer as.logical as.null.default as.numeric as.raw asin asinh atan atanh attr attributes baseenv browser c call ceiling class Conj cos cosh cospi cummax cummin cumprod cumsum digamma dim dimnames emptyenv exp expression floor forceAndCall gamma gc.time globalenv Im interactive invisible is.array is.atomic is.call is.character is.complex is.double is.environment is.expression is.finite is.function is.infinite is.integer is.language is.list is.logical is.matrix is.na is.name is.nan is.null is.numeric is.object is.pairlist is.raw is.recursive is.single is.symbol lazyLoadDBfetch length lgamma list log max min missing Mod names nargs nzchar oldClass on.exit pos.to.env proc.time prod quote range Re rep retracemem return round seq_along seq_len seq.int sign signif sin sinh sinpi sqrt standardGeneric substitute sum switch tan tanh tanpi tracemem trigamma trunc unclass untracemem UseMethod xtfrm"},contains:[e.COMMENT(/#'/,/$/,{contains:[{scope:"doctag",match:/@examples/,starts:{end:n.lookahead(n.either(/\n^#'\s*(?=@[a-zA-Z]+)/,/\n^(?!#')/)),endsParent:!0}},{scope:"doctag",begin:"@param",end:/$/,contains:[{scope:"variable",variants:[{match:t},{match:/`(?:\\.|[^`\\])+`/}],endsParent:!0}]},{scope:"doctag",match:/@[a-zA-Z]+/},{scope:"keyword",match:/\\[a-zA-Z]+/}]}),e.HASH_COMMENT_MODE,{scope:"string",contains:[e.BACKSLASH_ESCAPE],variants:[e.END_SAME_AS_BEGIN({begin:/[rR]"(-*)\(/,end:/\)(-*)"/}),e.END_SAME_AS_BEGIN({begin:/[rR]"(-*)\{/,end:/\}(-*)"/}),e.END_SAME_AS_BEGIN({begin:/[rR]"(-*)\[/,end:/\](-*)"/}),e.END_SAME_AS_BEGIN({begin:/[rR]'(-*)\(/,end:/\)(-*)'/}),e.END_SAME_AS_BEGIN({begin:/[rR]'(-*)\{/,end:/\}(-*)'/}),e.END_SAME_AS_BEGIN({begin:/[rR]'(-*)\[/,end:/\](-*)'/}),{begin:'"',end:'"',relevance:0},{begin:"'",end:"'",relevance:0}]},{relevance:0,variants:[{scope:{1:"operator",2:"number"},match:[s,a]},{scope:{1:"operator",2:"number"},match:[/%[^%]*%/,a]},{scope:{1:"punctuation",2:"number"},match:[u,a]},{scope:{2:"number"},match:[/[^a-zA-Z0-9._]|^/,a]}]},{scope:{3:"operator"},match:[t,/\s+/,/<-/,/\s+/]},{scope:"operator",relevance:0,variants:[{match:s},{match:/%[^%]*%/}]},{scope:"punctuation",relevance:0,match:u},{begin:"`",end:"`",contains:[{begin:/\\./}]}]}}At.exports=Ji});var Rt=k((ts,wt)=>{function ji(e){let n=e.regex,t=/(r#)?/,a=n.concat(t,e.UNDERSCORE_IDENT_RE),s=n.concat(t,e.IDENT_RE),u={scope:"title.function.invoke",relevance:0,begin:n.concat(/\b/,/(?!(?:let|for|while|if|else|match)\b)/,s,n.lookahead(/\s*\(/))},r="([ui](8|16|32|64|128|size)|f(16|32|64|128))?",i=["abstract","as","async","await","become","box","break","const","continue","crate","do","dyn","else","enum","extern","false","final","fn","for","if","impl","in","let","loop","macro","match","mod","move","mut","override","priv","pub","raw","ref","return","self","Self","static","struct","super","trait","true","try","type","typeof","union","unsafe","unsized","use","virtual","where","while","yield"],o=["true","false","Some","None","Ok","Err"],c=["drop ","Copy","Send","Sized","Sync","Drop","Fn","FnMut","FnOnce","ToOwned","Clone","Debug","PartialEq","PartialOrd","Eq","Ord","AsRef","AsMut","Into","From","Default","Iterator","Extend","IntoIterator","DoubleEndedIterator","ExactSizeIterator","SliceConcatExt","ToString","assert!","assert_eq!","bitflags!","bytes!","cfg!","col!","concat!","concat_idents!","debug_assert!","debug_assert_eq!","env!","eprintln!","panic!","file!","format!","format_args!","include_bytes!","include_str!","line!","local_data_key!","module_path!","option_env!","print!","println!","select!","stringify!","try!","unimplemented!","unreachable!","vec!","write!","writeln!","macro_rules!","assert_ne!","debug_assert_ne!"],d=["i8","i16","i32","i64","i128","isize","u8","u16","u32","u64","u128","usize","f16","f32","f64","f128","str","char","bool","Box","Option","Result","String","Vec"];return{name:"Rust",aliases:["rs"],keywords:{$pattern:e.IDENT_RE+"!?",type:d,keyword:i,literal:o,built_in:c},illegal:"</",contains:[e.C_LINE_COMMENT_MODE,e.COMMENT("/\\*","\\*/",{contains:["self"]}),e.inherit(e.QUOTE_STRING_MODE,{begin:/b?"/,illegal:null}),{scope:"symbol",begin:/'[a-zA-Z_][a-zA-Z0-9_]*(?!')/},{scope:"string",variants:[{begin:/b?r(#*)"(.|\n)*?"\1(?!#)/},{begin:/b?'/,end:/'/,contains:[{scope:"char.escape",match:/\\('|"|\\|\w|x\w{2}|u\w{4}|U\w{8})/}]}]},{scope:"number",variants:[{begin:"\\b0b([01_]+)"+r},{begin:"\\b0o([0-7_]+)"+r},{begin:"\\b0x([A-Fa-f0-9_]+)"+r},{begin:"\\b(\\d[\\d_]*(\\.[0-9_]+)?([eE][+-]?[0-9_]+)?)"+r}],relevance:0},{begin:[/\bsafe/,/\s+/,/extern/],scope:{1:"keyword",3:"keyword"}},{begin:[/fn/,/\s+/,a],scope:{1:"keyword",3:"title.function"}},{scope:"meta",begin:"#!?\\[",end:"\\]",contains:[{scope:"string",begin:/"/,end:/"/,contains:[e.BACKSLASH_ESCAPE]}]},{begin:[/let/,/\s+/,/(?:mut\s+)?/,a],scope:{1:"keyword",3:"keyword",4:"variable"}},{begin:[/for/,/\s+/,a,/\s+/,/in/],scope:{1:"keyword",3:"variable",5:"keyword"}},{begin:[/type/,/\s+/,a],scope:{1:"keyword",3:"title.class"}},{begin:[/(?:trait|enum|struct|union|impl|for)/,/\s+/,a],scope:{1:"keyword",3:"title.class"}},{begin:e.IDENT_RE+"::",keywords:{keyword:"Self",built_in:c,type:d}},{scope:"punctuation",begin:"->"},u]}}wt.exports=ji});var kt=k((as,Mt)=>{var er=e=>({IMPORTANT:{scope:"meta",begin:"!important"},BLOCK_COMMENT:e.C_BLOCK_COMMENT_MODE,HEXCOLOR:{scope:"number",begin:/#(([0-9a-fA-F]{3,4})|(([0-9a-fA-F]{2}){3,4}))\b/},UNICODE_RANGE:{scope:"number",begin:/\b[Uu]\+[0-9A-Fa-f][0-9A-Fa-f?]{0,5}(-[0-9A-Fa-f][0-9A-Fa-f]{0,5})?/},FUNCTION_DISPATCH:{className:"built_in",begin:/[\w-]+(?=\()/},ATTRIBUTE_SELECTOR_MODE:{scope:"selector-attr",begin:/\[/,end:/\]/,illegal:"$",contains:[e.APOS_STRING_MODE,e.QUOTE_STRING_MODE]},CSS_NUMBER_MODE:{scope:"number",begin:e.NUMBER_RE+"(%|em|ex|ch|rem|vw|vh|vmin|vmax|cm|mm|in|pt|pc|px|deg|grad|rad|turn|s|ms|Hz|kHz|dpi|dpcm|dppx)?",relevance:0},CSS_VARIABLE:{className:"attr",begin:/--[A-Za-z_][A-Za-z0-9_-]*/}}),nr=["a","abbr","address","article","aside","audio","b","blockquote","body","button","canvas","caption","cite","code","dd","del","details","dfn","div","dl","dt","em","fieldset","figcaption","figure","footer","form","h1","h2","h3","h4","h5","h6","header","hgroup","html","i","iframe","img","input","ins","kbd","label","legend","li","main","mark","menu","nav","object","ol","optgroup","option","p","picture","q","quote","samp","section","select","source","span","strong","summary","sup","table","tbody","td","textarea","tfoot","th","thead","time","tr","ul","var","video"],tr=["defs","g","marker","mask","pattern","svg","switch","symbol","feBlend","feColorMatrix","feComponentTransfer","feComposite","feConvolveMatrix","feDiffuseLighting","feDisplacementMap","feFlood","feGaussianBlur","feImage","feMerge","feMorphology","feOffset","feSpecularLighting","feTile","feTurbulence","linearGradient","radialGradient","stop","circle","ellipse","image","line","path","polygon","polyline","rect","text","use","textPath","tspan","foreignObject","clipPath"],ar=[...nr,...tr],ir=["any-hover","any-pointer","aspect-ratio","color","color-gamut","color-index","device-aspect-ratio","device-height","device-width","display-mode","forced-colors","grid","height","hover","inverted-colors","monochrome","orientation","overflow-block","overflow-inline","pointer","prefers-color-scheme","prefers-contrast","prefers-reduced-motion","prefers-reduced-transparency","resolution","scan","scripting","update","width","min-width","max-width","min-height","max-height"].sort().reverse(),rr=["active","any-link","blank","checked","current","default","defined","dir","disabled","drop","empty","enabled","first","first-child","first-of-type","fullscreen","future","focus","focus-visible","focus-within","has","host","host-context","hover","indeterminate","in-range","invalid","is","lang","last-child","last-of-type","left","link","local-link","not","nth-child","nth-col","nth-last-child","nth-last-col","nth-last-of-type","nth-of-type","only-child","only-of-type","optional","out-of-range","past","placeholder-shown","read-only","read-write","required","right","root","scope","target","target-within","user-invalid","valid","visited","where"].sort().reverse(),sr=["after","backdrop","before","cue","cue-region","first-letter","first-line","grammar-error","marker","part","placeholder","selection","slotted","spelling-error"].sort().reverse(),or=["accent-color","align-content","align-items","align-self","alignment-baseline","all","anchor-name","animation","animation-composition","animation-delay","animation-direction","animation-duration","animation-fill-mode","animation-iteration-count","animation-name","animation-play-state","animation-range","animation-range-end","animation-range-start","animation-timeline","animation-timing-function","appearance","aspect-ratio","backdrop-filter","backface-visibility","background","background-attachment","background-blend-mode","background-clip","background-color","background-image","background-origin","background-position","background-position-x","background-position-y","background-repeat","background-size","baseline-shift","block-size","border","border-block","border-block-color","border-block-end","border-block-end-color","border-block-end-style","border-block-end-width","border-block-start","border-block-start-color","border-block-start-style","border-block-start-width","border-block-style","border-block-width","border-bottom","border-bottom-color","border-bottom-left-radius","border-bottom-right-radius","border-bottom-style","border-bottom-width","border-collapse","border-color","border-end-end-radius","border-end-start-radius","border-image","border-image-outset","border-image-repeat","border-image-slice","border-image-source","border-image-width","border-inline","border-inline-color","border-inline-end","border-inline-end-color","border-inline-end-style","border-inline-end-width","border-inline-start","border-inline-start-color","border-inline-start-style","border-inline-start-width","border-inline-style","border-inline-width","border-left","border-left-color","border-left-style","border-left-width","border-radius","border-right","border-right-color","border-right-style","border-right-width","border-spacing","border-start-end-radius","border-start-start-radius","border-style","border-top","border-top-color","border-top-left-radius","border-top-right-radius","border-top-style","border-top-width","border-width","bottom","box-align","box-decoration-break","box-direction","box-flex","box-flex-group","box-lines","box-ordinal-group","box-orient","box-pack","box-shadow","box-sizing","break-after","break-before","break-inside","caption-side","caret-color","clear","clip","clip-path","clip-rule","color","color-interpolation","color-interpolation-filters","color-profile","color-rendering","color-scheme","column-count","column-fill","column-gap","column-rule","column-rule-color","column-rule-style","column-rule-width","column-span","column-width","columns","contain","contain-intrinsic-block-size","contain-intrinsic-height","contain-intrinsic-inline-size","contain-intrinsic-size","contain-intrinsic-width","container","container-name","container-type","content","content-visibility","corner-bottom-left-shape","corner-bottom-right-shape","corner-shape","corner-top-left-shape","corner-top-right-shape","counter-increment","counter-reset","counter-set","cue","cue-after","cue-before","cursor","cx","cy","direction","display","dominant-baseline","empty-cells","enable-background","field-sizing","fill","fill-opacity","fill-rule","filter","flex","flex-basis","flex-direction","flex-flow","flex-grow","flex-shrink","flex-wrap","float","flood-color","flood-opacity","flow","font","font-display","font-family","font-feature-settings","font-kerning","font-language-override","font-optical-sizing","font-palette","font-size","font-size-adjust","font-smooth","font-smoothing","font-stretch","font-style","font-synthesis","font-synthesis-position","font-synthesis-small-caps","font-synthesis-style","font-synthesis-weight","font-variant","font-variant-alternates","font-variant-caps","font-variant-east-asian","font-variant-emoji","font-variant-ligatures","font-variant-numeric","font-variant-position","font-variation-settings","font-weight","forced-color-adjust","gap","glyph-orientation-horizontal","glyph-orientation-vertical","grid","grid-area","grid-auto-columns","grid-auto-flow","grid-auto-rows","grid-column","grid-column-end","grid-column-start","grid-gap","grid-row","grid-row-end","grid-row-start","grid-template","grid-template-areas","grid-template-columns","grid-template-rows","hanging-punctuation","height","hyphenate-character","hyphenate-limit-chars","hyphens","icon","image-orientation","image-rendering","image-resolution","ime-mode","initial-letter","initial-letter-align","inline-size","inset","inset-area","inset-block","inset-block-end","inset-block-start","inset-inline","inset-inline-end","inset-inline-start","isolation","justify-content","justify-items","justify-self","kerning","left","letter-spacing","lighting-color","line-break","line-height","line-height-step","list-style","list-style-image","list-style-position","list-style-type","margin","margin-block","margin-block-end","margin-block-start","margin-bottom","margin-inline","margin-inline-end","margin-inline-start","margin-left","margin-right","margin-top","margin-trim","marker","marker-end","marker-mid","marker-start","marks","mask","mask-border","mask-border-mode","mask-border-outset","mask-border-repeat","mask-border-slice","mask-border-source","mask-border-width","mask-clip","mask-composite","mask-image","mask-mode","mask-origin","mask-position","mask-repeat","mask-size","mask-type","masonry-auto-flow","math-depth","math-shift","math-style","max-block-size","max-height","max-inline-size","max-width","min-block-size","min-height","min-inline-size","min-width","mix-blend-mode","nav-down","nav-index","nav-left","nav-right","nav-up","none","normal","object-fit","object-position","offset","offset-anchor","offset-distance","offset-path","offset-position","offset-rotate","opacity","order","orphans","outline","outline-color","outline-offset","outline-style","outline-width","overflow","overflow-anchor","overflow-block","overflow-clip-margin","overflow-inline","overflow-wrap","overflow-x","overflow-y","overlay","overscroll-behavior","overscroll-behavior-block","overscroll-behavior-inline","overscroll-behavior-x","overscroll-behavior-y","padding","padding-block","padding-block-end","padding-block-start","padding-bottom","padding-inline","padding-inline-end","padding-inline-start","padding-left","padding-right","padding-top","page","page-break-after","page-break-before","page-break-inside","paint-order","pause","pause-after","pause-before","perspective","perspective-origin","place-content","place-items","place-self","pointer-events","position","position-anchor","position-visibility","print-color-adjust","quotes","r","resize","rest","rest-after","rest-before","right","rotate","row-gap","ruby-align","ruby-position","scale","scroll-behavior","scroll-margin","scroll-margin-block","scroll-margin-block-end","scroll-margin-block-start","scroll-margin-bottom","scroll-margin-inline","scroll-margin-inline-end","scroll-margin-inline-start","scroll-margin-left","scroll-margin-right","scroll-margin-top","scroll-padding","scroll-padding-block","scroll-padding-block-end","scroll-padding-block-start","scroll-padding-bottom","scroll-padding-inline","scroll-padding-inline-end","scroll-padding-inline-start","scroll-padding-left","scroll-padding-right","scroll-padding-top","scroll-snap-align","scroll-snap-stop","scroll-snap-type","scroll-timeline","scroll-timeline-axis","scroll-timeline-name","scrollbar-color","scrollbar-gutter","scrollbar-width","shape-image-threshold","shape-margin","shape-outside","shape-rendering","speak","speak-as","src","stop-color","stop-opacity","stroke","stroke-dasharray","stroke-dashoffset","stroke-linecap","stroke-linejoin","stroke-miterlimit","stroke-opacity","stroke-width","tab-size","table-layout","text-align","text-align-all","text-align-last","text-anchor","text-combine-upright","text-decoration","text-decoration-color","text-decoration-line","text-decoration-skip","text-decoration-skip-ink","text-decoration-style","text-decoration-thickness","text-emphasis","text-emphasis-color","text-emphasis-position","text-emphasis-style","text-indent","text-justify","text-orientation","text-overflow","text-rendering","text-shadow","text-size-adjust","text-transform","text-underline-offset","text-underline-position","text-wrap","text-wrap-mode","text-wrap-style","timeline-scope","top","touch-action","transform","transform-box","transform-origin","transform-style","transition","transition-behavior","transition-delay","transition-duration","transition-property","transition-timing-function","translate","unicode-bidi","unicode-range","user-modify","user-select","vector-effect","vertical-align","view-timeline","view-timeline-axis","view-timeline-inset","view-timeline-name","view-transition-name","visibility","voice-balance","voice-duration","voice-family","voice-pitch","voice-range","voice-rate","voice-stress","voice-volume","white-space","white-space-collapse","widows","width","will-change","word-break","word-spacing","word-wrap","writing-mode","x","y","z-index","zoom"].sort().reverse();function cr(e){let n=er(e),t=sr,a=rr,s="@[a-z-]+",u="and or not only",i={className:"variable",begin:"(\\$"+"[a-zA-Z-][a-zA-Z0-9_-]*"+")\\b",relevance:0};return{name:"SCSS",case_insensitive:!0,illegal:"[=/|']",contains:[e.C_LINE_COMMENT_MODE,e.C_BLOCK_COMMENT_MODE,n.CSS_NUMBER_MODE,{className:"selector-id",begin:"#[A-Za-z0-9_-]+",relevance:0},{className:"selector-class",begin:"\\.[A-Za-z0-9_-]+",relevance:0},n.ATTRIBUTE_SELECTOR_MODE,{className:"selector-tag",begin:"\\b("+ar.join("|")+")\\b",relevance:0},{className:"selector-pseudo",begin:":("+a.join("|")+")"},{className:"selector-pseudo",begin:":(:)?("+t.join("|")+")"},i,{begin:/\(/,end:/\)/,contains:[n.CSS_NUMBER_MODE]},n.CSS_VARIABLE,{className:"attribute",begin:"\\b("+or.join("|")+")\\b"},{begin:"\\b(whitespace|wait|w-resize|visible|vertical-text|vertical-ideographic|uppercase|upper-roman|upper-alpha|underline|transparent|top|thin|thick|text|text-top|text-bottom|tb-rl|table-header-group|table-footer-group|sw-resize|super|strict|static|square|solid|small-caps|separate|se-resize|scroll|s-resize|rtl|row-resize|ridge|right|repeat|repeat-y|repeat-x|relative|progress|pointer|overline|outside|outset|oblique|nowrap|not-allowed|normal|none|nw-resize|no-repeat|no-drop|newspaper|ne-resize|n-resize|move|middle|medium|ltr|lr-tb|lowercase|lower-roman|lower-alpha|loose|list-item|line|line-through|line-edge|lighter|left|keep-all|justify|italic|inter-word|inter-ideograph|inside|inset|inline|inline-block|inherit|inactive|ideograph-space|ideograph-parenthesis|ideograph-numeric|ideograph-alpha|horizontal|hidden|help|hand|groove|fixed|ellipsis|e-resize|double|dotted|distribute|distribute-space|distribute-letter|distribute-all-lines|disc|disabled|default|decimal|dashed|crosshair|collapse|col-resize|circle|char|center|capitalize|break-word|break-all|bottom|both|bolder|bold|block|bidi-override|below|baseline|auto|always|all-scroll|absolute|table|table-cell)\\b"},{begin:/:/,end:/[;}{]/,relevance:0,contains:[n.BLOCK_COMMENT,i,n.HEXCOLOR,n.CSS_NUMBER_MODE,n.UNICODE_RANGE,e.QUOTE_STRING_MODE,e.APOS_STRING_MODE,n.IMPORTANT,n.FUNCTION_DISPATCH]},{begin:"@(page|font-face)",keywords:{$pattern:s,keyword:"@page @font-face"}},{begin:"@",end:"[{;]",returnBegin:!0,keywords:{$pattern:/[a-z-]+/,keyword:u,attribute:ir.join(" ")},contains:[{begin:s,className:"keyword"},{begin:/[a-z-]+(?=:)/,className:"attribute"},i,e.QUOTE_STRING_MODE,e.APOS_STRING_MODE,n.HEXCOLOR,n.CSS_NUMBER_MODE]},n.FUNCTION_DISPATCH]}}Mt.exports=cr});var Ct=k((is,xt)=>{function lr(e){return{name:"Shell Session",aliases:["console","shellsession"],contains:[{className:"meta.prompt",begin:/^\s{0,3}[./~\w\d[\]()@-]*[>%$#][ ]?/,starts:{end:/[^\\](?=\s*$)/,subLanguage:"bash"}}]}}xt.exports=lr});var Dt=k((rs,It)=>{function dr(e){let n=e.regex,t=e.COMMENT("--","$"),a={scope:"string",variants:[{begin:/'/,end:/'/,contains:[{match:/''/}]}]},s={begin:/"/,end:/"/,contains:[{match:/""/}]},u=["true","false","unknown"],r=["double precision","large object","with timezone","without timezone"],i=["bigint","binary","blob","boolean","char","character","clob","date","dec","decfloat","decimal","float","int","integer","interval","nchar","nclob","national","numeric","real","row","smallint","time","timestamp","varchar","varying","varbinary"],o=["add","asc","collation","desc","final","first","last","view"],c=["abs","acos","all","allocate","alter","and","any","are","array","array_agg","array_max_cardinality","as","asensitive","asin","asymmetric","at","atan","atomic","authorization","avg","begin","begin_frame","begin_partition","between","bigint","binary","blob","boolean","both","by","call","called","cardinality","cascaded","case","cast","ceil","ceiling","char","char_length","character","character_length","check","classifier","clob","close","coalesce","collate","collect","column","commit","condition","connect","constraint","contains","convert","copy","corr","corresponding","cos","cosh","count","covar_pop","covar_samp","create","cross","cube","cume_dist","current","current_catalog","current_date","current_default_transform_group","current_path","current_role","current_row","current_schema","current_time","current_timestamp","current_path","current_role","current_transform_group_for_type","current_user","cursor","cycle","date","day","deallocate","dec","decimal","decfloat","declare","default","define","delete","dense_rank","deref","describe","deterministic","disconnect","distinct","double","drop","dynamic","each","element","else","empty","end","end_frame","end_partition","end-exec","equals","escape","every","except","exec","execute","exists","exp","external","extract","false","fetch","filter","first_value","float","floor","for","foreign","frame_row","free","from","full","function","fusion","get","global","grant","group","grouping","groups","having","hold","hour","identity","in","indicator","initial","inner","inout","insensitive","insert","int","integer","intersect","intersection","interval","into","is","join","json_array","json_arrayagg","json_exists","json_object","json_objectagg","json_query","json_table","json_table_primitive","json_value","lag","language","large","last_value","lateral","lead","leading","left","like","like_regex","listagg","ln","local","localtime","localtimestamp","log","log10","lower","match","match_number","match_recognize","matches","max","member","merge","method","min","minute","mod","modifies","module","month","multiset","national","natural","nchar","nclob","new","no","none","normalize","not","nth_value","ntile","null","nullif","numeric","octet_length","occurrences_regex","of","offset","old","omit","on","one","only","open","or","order","out","outer","over","overlaps","overlay","parameter","partition","pattern","per","percent","percent_rank","percentile_cont","percentile_disc","period","portion","position","position_regex","power","precedes","precision","prepare","primary","procedure","ptf","range","rank","reads","real","recursive","ref","references","referencing","regr_avgx","regr_avgy","regr_count","regr_intercept","regr_r2","regr_slope","regr_sxx","regr_sxy","regr_syy","release","result","return","returns","revoke","right","rollback","rollup","row","row_number","rows","running","savepoint","scope","scroll","search","second","seek","select","sensitive","session_user","set","show","similar","sin","sinh","skip","smallint","some","specific","specifictype","sql","sqlexception","sqlstate","sqlwarning","sqrt","start","static","stddev_pop","stddev_samp","submultiset","subset","substring","substring_regex","succeeds","sum","symmetric","system","system_time","system_user","table","tablesample","tan","tanh","then","time","timestamp","timezone_hour","timezone_minute","to","trailing","translate","translate_regex","translation","treat","trigger","trim","trim_array","true","truncate","uescape","union","unique","unknown","unnest","update","upper","user","using","value","values","value_of","var_pop","var_samp","varbinary","varchar","varying","versioning","when","whenever","where","width_bucket","window","with","within","without","year"],d=["abs","acos","array_agg","asin","atan","avg","cast","ceil","ceiling","coalesce","corr","cos","cosh","count","covar_pop","covar_samp","cume_dist","dense_rank","deref","element","exp","extract","first_value","floor","json_array","json_arrayagg","json_exists","json_object","json_objectagg","json_query","json_table","json_table_primitive","json_value","lag","last_value","lead","listagg","ln","log","log10","lower","max","min","mod","nth_value","ntile","nullif","percent_rank","percentile_cont","percentile_disc","position","position_regex","power","rank","regr_avgx","regr_avgy","regr_count","regr_intercept","regr_r2","regr_slope","regr_sxx","regr_sxy","regr_syy","row_number","sin","sinh","sqrt","stddev_pop","stddev_samp","substring","substring_regex","sum","tan","tanh","translate","translate_regex","treat","trim","trim_array","unnest","upper","value_of","var_pop","var_samp","width_bucket"],m=["current_catalog","current_date","current_default_transform_group","current_path","current_role","current_schema","current_transform_group_for_type","current_user","session_user","system_time","system_user","current_time","localtime","current_timestamp","localtimestamp"],g=["create table","insert into","primary key","foreign key","not null","alter table","add constraint","grouping sets","on overflow","character set","respect nulls","ignore nulls","nulls first","nulls last","depth first","breadth first"],p=d,y=[...c,...o].filter(A=>!d.includes(A)),h={scope:"variable",match:/@[a-z0-9][a-z0-9_]*/},T={scope:"operator",match:/[-+*/=%^~]|&&?|\|\|?|!=?|<(?:=>?|<|>)?|>[>=]?/,relevance:0},N={match:n.concat(/\b/,n.either(...p),/\s*\(/),relevance:0,keywords:{built_in:p}};function C(A){return n.concat(/\b/,n.either(...A.map(M=>M.replace(/\s+/,"\\s+"))),/\b/)}let R={scope:"keyword",match:C(g),relevance:0};function S(A,{exceptions:M,when:L}={}){let D=L;return M=M||[],A.map(U=>U.match(/\|\d+$/)||M.includes(U)?U:D(U)?`${U}|0`:U)}return{name:"SQL",case_insensitive:!0,illegal:/[{}]|<\//,keywords:{$pattern:/\b[\w\.]+/,keyword:S(y,{when:A=>A.length<3}),literal:u,type:i,built_in:m},contains:[{scope:"type",match:C(r)},R,N,h,a,s,e.C_NUMBER_MODE,e.C_BLOCK_COMMENT_MODE,t,T]}}It.exports=dr});var Kt=k((ss,Gt)=>{function Pt(e){return e?typeof e=="string"?e:e.source:null}function fe(e){return z("(?=",e,")")}function z(...e){return e.map(t=>Pt(t)).join("")}function ur(e){let n=e[e.length-1];return typeof n=="object"&&n.constructor===Object?(e.splice(e.length-1,1),n):{}}function X(...e){return"("+(ur(e).capture?"":"?:")+e.map(a=>Pt(a)).join("|")+")"}new RegExp(X(/\[(?:[^\\\]]|\\.)*\]/,/\(\?<(?![=!])[^>]+>/,/\(\?'[^']+'/,/\(\??/,/\\([1-9][0-9]*)/,/\\./));var Qe=e=>z(/\b/,e,/\w$/.test(e)?/\b/:/\B/),gr=["Protocol","Type"].map(Qe),Lt=["init","self"].map(Qe),br=["Any","Self"],Xe=["actor","any","associatedtype","async","await",/as\?/,/as!/,"as","borrowing","break","case","catch","class","consume","consuming","continue","convenience","copy","default","defer","deinit","didSet","distributed","do","dynamic","each","else","enum","extension","fallthrough",/fileprivate\(set\)/,"fileprivate","final","for","func","get","guard","if","import","indirect","infix",/init\?/,/init!/,"inout",/internal\(set\)/,"internal","in","is","isolated","nonisolated","lazy","let","macro","mutating","nonmutating",/open\(set\)/,"open","operator","optional","override","package","postfix","precedencegroup","prefix",/private\(set\)/,"private","protocol",/public\(set\)/,"public","repeat","required","rethrows","return","set","some","static","struct","subscript","super","switch","throws","throw",/try\?/,/try!/,"try","typealias",/unowned\(safe\)/,/unowned\(unsafe\)/,"unowned","var","weak","where","while","willSet"],Bt=["false","nil","true"],pr=["assignment","associativity","higherThan","left","lowerThan","none","right"],mr=["#colorLiteral","#column","#dsohandle","#else","#elseif","#endif","#error","#file","#fileID","#fileLiteral","#filePath","#function","#if","#imageLiteral","#keyPath","#line","#selector","#sourceLocation","#warning"],Ut=["abs","all","any","assert","assertionFailure","debugPrint","dump","fatalError","getVaList","isKnownUniquelyReferenced","max","min","numericCast","pointwiseMax","pointwiseMin","precondition","preconditionFailure","print","readLine","repeatElement","sequence","stride","swap","swift_unboxFromSwiftValueWithType","transcode","type","unsafeBitCast","unsafeDowncast","withExtendedLifetime","withUnsafeMutablePointer","withUnsafePointer","withVaList","withoutActuallyEscaping","zip"],Ft=X(/[/=\-+!*%<>&|^~?]/,/[\u00A1-\u00A7]/,/[\u00A9\u00AB]/,/[\u00AC\u00AE]/,/[\u00B0\u00B1]/,/[\u00B6\u00BB\u00BF\u00D7\u00F7]/,/[\u2016-\u2017]/,/[\u2020-\u2027]/,/[\u2030-\u203E]/,/[\u2041-\u2053]/,/[\u2055-\u205E]/,/[\u2190-\u23FF]/,/[\u2500-\u2775]/,/[\u2794-\u2BFF]/,/[\u2E00-\u2E7F]/,/[\u3001-\u3003]/,/[\u3008-\u3020]/,/[\u3030]/),zt=X(Ft,/[\u0300-\u036F]/,/[\u1DC0-\u1DFF]/,/[\u20D0-\u20FF]/,/[\uFE00-\uFE0F]/,/[\uFE20-\uFE2F]/),Ve=z(Ft,zt,"*"),$t=X(/[a-zA-Z_]/,/[\u00A8\u00AA\u00AD\u00AF\u00B2-\u00B5\u00B7-\u00BA]/,/[\u00BC-\u00BE\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u00FF]/,/[\u0100-\u02FF\u0370-\u167F\u1681-\u180D\u180F-\u1DBF]/,/[\u1E00-\u1FFF]/,/[\u200B-\u200D\u202A-\u202E\u203F-\u2040\u2054\u2060-\u206F]/,/[\u2070-\u20CF\u2100-\u218F\u2460-\u24FF\u2776-\u2793]/,/[\u2C00-\u2DFF\u2E80-\u2FFF]/,/[\u3004-\u3007\u3021-\u302F\u3031-\u303F\u3040-\uD7FF]/,/[\uF900-\uFD3D\uFD40-\uFDCF\uFDF0-\uFE1F\uFE30-\uFE44]/,/[\uFE47-\uFEFE\uFF00-\uFFFD]/),Ie=X($t,/\d/,/[\u0300-\u036F\u1DC0-\u1DFF\u20D0-\u20FF\uFE20-\uFE2F]/),te=z($t,Ie,"*"),Ce=z(/[A-Z]/,Ie,"*"),_r=["attached","autoclosure",z(/convention\(/,X("swift","block","c"),/\)/),"discardableResult","dynamicCallable","dynamicMemberLookup","escaping","freestanding","frozen","GKInspectable","IBAction","IBDesignable","IBInspectable","IBOutlet","IBSegueAction","inlinable","main","nonobjc","NSApplicationMain","NSCopying","NSManaged",z(/objc\(/,te,/\)/),"objc","objcMembers","propertyWrapper","requires_stored_property_inits","resultBuilder","Sendable","testable","UIApplicationMain","unchecked","unknown","usableFromInline","warn_unqualified_access"],Er=["iOS","iOSApplicationExtension","macOS","macOSApplicationExtension","macCatalyst","macCatalystApplicationExtension","watchOS","watchOSApplicationExtension","tvOS","tvOSApplicationExtension","swift"];function fr(e){let n={match:/\s+/,relevance:0},t=e.COMMENT("/\\*","\\*/",{contains:["self"]}),a=[e.C_LINE_COMMENT_MODE,t],s={match:[/\./,X(...gr,...Lt)],className:{2:"keyword"}},u={match:z(/\./,X(...Xe)),relevance:0},r=Xe.filter(F=>typeof F=="string").concat(["_|0"]),i=Xe.filter(F=>typeof F!="string").concat(br).map(Qe),o={variants:[{className:"keyword",match:X(...i,...Lt)}]},c={$pattern:X(/\b\w+/,/#\w+/),keyword:r.concat(mr),literal:Bt},d=[s,u,o],m={match:z(/\./,X(...Ut)),relevance:0},g={className:"built_in",match:z(/\b/,X(...Ut),/(?=\()/)},p=[m,g],y={match:/->/,relevance:0},h={className:"operator",relevance:0,variants:[{match:Ve},{match:`\\.(\\.|${zt})+`}]},T=[y,h],N="([0-9]_*)+",C="([0-9a-fA-F]_*)+",R={className:"number",relevance:0,variants:[{match:`\\b(${N})(\\.(${N}))?([eE][+-]?(${N}))?\\b`},{match:`\\b0x(${C})(\\.(${C}))?([pP][+-]?(${N}))?\\b`},{match:/\b0o([0-7]_*)+\b/},{match:/\b0b([01]_*)+\b/}]},S=(F="")=>({className:"subst",variants:[{match:z(/\\/,F,/[0\\tnr"']/)},{match:z(/\\/,F,/u\{[0-9a-fA-F]{1,8}\}/)}]}),A=(F="")=>({className:"subst",match:z(/\\/,F,/[\t ]*(?:[\r\n]|\r\n)/)}),M=(F="")=>({className:"subst",label:"interpol",begin:z(/\\/,F,/\(/),end:/\)/}),L=(F="")=>({begin:z(F,/"""/),end:z(/"""/,F),contains:[S(F),A(F),M(F)]}),D=(F="")=>({begin:z(F,/"/),end:z(/"/,F),contains:[S(F),M(F)]}),U={className:"string",variants:[L(),L("#"),L("##"),L("###"),D(),D("#"),D("##"),D("###")]},O=[e.BACKSLASH_ESCAPE,{begin:/\[/,end:/\]/,relevance:0,contains:[e.BACKSLASH_ESCAPE]}],H={begin:/\/[^\s](?=[^/\n]*\/)/,end:/\//,contains:O},J=F=>{let ie=z(F,/\//),v=z(/\//,F);return{begin:ie,end:v,contains:[...O,{scope:"comment",begin:`#(?!.*${v})`,end:/$/}]}},ne={scope:"regexp",variants:[J("###"),J("##"),J("#"),H]},q={match:z(/`/,te,/`/)},Z={className:"variable",match:/\$\d+/},l={className:"variable",match:`\\$${Ie}+`},_=[q,Z,l],E={match:/(@|#(un)?)available/,scope:"keyword",starts:{contains:[{begin:/\(/,end:/\)/,keywords:Er,contains:[...T,R,U]}]}},w={scope:"keyword",match:z(/@/,X(..._r),fe(X(/\(/,/\s+/)))},B={scope:"meta",match:z(/@/,te)},$=[E,w,B],K={match:fe(/\b[A-Z]/),relevance:0,contains:[{className:"type",match:z(/(AV|CA|CF|CG|CI|CL|CM|CN|CT|MK|MP|MTK|MTL|NS|SCN|SK|UI|WK|XC)/,Ie,"+")},{className:"type",match:Ce,relevance:0},{match:/[?!]+/,relevance:0},{match:/\.\.\./,relevance:0},{match:z(/\s+&\s+/,fe(Ce)),relevance:0}]},j={begin:/</,end:/>/,keywords:c,contains:[...a,...d,...$,y,K]};K.contains.push(j);let V={match:z(te,/\s*:/),keywords:"_|0",relevance:0},Q={begin:/\(/,end:/\)/,relevance:0,keywords:c,contains:["self",V,...a,ne,...d,...p,...T,R,U,..._,...$,K]},le={begin:/</,end:/>/,keywords:"repeat each",contains:[...a,K]},he={begin:X(fe(z(te,/\s*:/)),fe(z(te,/\s+/,te,/\s*:/))),end:/:/,relevance:0,contains:[{className:"keyword",match:/\b_\b/},{className:"params",match:te}]},me={begin:/\(/,end:/\)/,keywords:c,contains:[he,...a,...d,...T,R,U,...$,K,Q],endsParent:!0,illegal:/["']/},Be={match:[/(func|macro)/,/\s+/,X(q.match,te,Ve)],className:{1:"keyword",3:"title.function"},contains:[le,me,n],illegal:[/\[/,/%/]},Ue={match:[/\b(?:subscript|init[?!]?)/,/\s*(?=[<(])/],className:{1:"keyword"},contains:[le,me,n],illegal:/\[|%/},Pe={match:[/operator/,/\s+/,Ve],className:{1:"keyword",3:"title"}},Fe={begin:[/precedencegroup/,/\s+/,Ce],className:{1:"keyword",3:"title"},contains:[K],keywords:[...pr,...Bt],end:/}/},de={match:[/class\b/,/\s+/,/func\b/,/\s+/,/\b[A-Za-z_][A-Za-z0-9_]*\b/],scope:{1:"keyword",3:"keyword",5:"title.function"}},Ne={match:[/class\b/,/\s+/,/var\b/],scope:{1:"keyword",3:"keyword"}},ee={begin:[/(struct|protocol|class|extension|enum|actor)/,/\s+/,te,/\s*/],beginScope:{1:"keyword",3:"title.class"},keywords:c,contains:[le,...d,{begin:/:/,end:/\{/,keywords:c,contains:[{scope:"title.class.inherited",match:Ce},...d],relevance:0}]};for(let F of U.variants){let ie=F.contains.find(ye=>ye.label==="interpol");ie.keywords=c;let v=[...d,...p,...T,R,U,..._];ie.contains=[...v,{begin:/\(/,end:/\)/,contains:["self",...v]}]}return{name:"Swift",keywords:c,contains:[...a,Be,Ue,de,Ne,ee,Pe,Fe,{beginKeywords:"import",end:/$/,contains:[...a],relevance:0},ne,...d,...p,...T,R,U,..._,...$,K,Q]}}Gt.exports=fr});var qt=k((os,Ht)=>{function hr(e){let n="true false yes no null",t="[\\w#;/?:@&=+$,.~*'()[\\]]+",a={className:"attr",variants:[{begin:/[\w*@][\w*@ :()\./-]*:(?=[ \t]|$)/},{begin:/"[\w*@][\w*@ :()\./-]*":(?=[ \t]|$)/},{begin:/'[\w*@][\w*@ :()\./-]*':(?=[ \t]|$)/}]},s={className:"template-variable",variants:[{begin:/\{\{/,end:/\}\}/},{begin:/%\{/,end:/\}/}]},u={className:"string",relevance:0,begin:/'/,end:/'/,contains:[{match:/''/,scope:"char.escape",relevance:0}]},r={className:"string",relevance:0,variants:[{begin:/"/,end:/"/},{begin:/\S+/}],contains:[e.BACKSLASH_ESCAPE,s]},i=e.inherit(r,{variants:[{begin:/'/,end:/'/,contains:[{begin:/''/,relevance:0}]},{begin:/"/,end:/"/},{begin:/[^\s,{}[\]]+/}]}),g={className:"number",begin:"\\b"+"[0-9]{4}(-[0-9][0-9]){0,2}"+"([Tt \\t][0-9][0-9]?(:[0-9][0-9]){2})?"+"(\\.[0-9]*)?"+"([ \\t])*(Z|[-+][0-9][0-9]?(:[0-9][0-9])?)?"+"\\b"},p={end:",",endsWithParent:!0,excludeEnd:!0,keywords:n,relevance:0},y={begin:/\{/,end:/\}/,contains:[p],illegal:"\\n",relevance:0},h={begin:"\\[",end:"\\]",contains:[p],illegal:"\\n",relevance:0},T=[a,{className:"meta",begin:"^---\\s*$",relevance:10},{className:"string",begin:"[\\|>]([1-9]?[+-])?[ ]*\\n( +)[^ ][^\\n]*\\n(\\2[^\\n]+\\n?)*"},{begin:"<%[%=-]?",end:"[%-]?%>",subLanguage:"ruby",excludeBegin:!0,excludeEnd:!0,relevance:0},{className:"type",begin:"!\\w+!"+t},{className:"type",begin:"!<"+t+">"},{className:"type",begin:"!"+t},{className:"type",begin:"!!"+t},{className:"meta",begin:"&"+e.UNDERSCORE_IDENT_RE+"$"},{className:"meta",begin:"\\*"+e.UNDERSCORE_IDENT_RE+"$"},{className:"bullet",begin:"-(?=[ ]|$)",relevance:0},e.HASH_COMMENT_MODE,{beginKeywords:n,keywords:{literal:n}},g,{className:"number",begin:e.C_NUMBER_RE+"\\b",relevance:0},y,h,u,r],N=[...T];return N.pop(),N.push(i),p.contains=N,{name:"YAML",case_insensitive:!0,aliases:["yml"],contains:T}}Ht.exports=hr});var ea=k((cs,jt)=>{var De="[A-Za-z$_][0-9A-Za-z$_]*",Zt=["as","in","of","if","for","while","finally","var","new","function","do","return","void","else","break","catch","instanceof","with","throw","case","default","try","switch","continue","typeof","delete","let","yield","const","class","debugger","async","await","static","import","from","export","extends","using"],Wt=["true","false","null","undefined","NaN","Infinity"],Yt=["Object","Function","Boolean","Symbol","Math","Date","Number","BigInt","String","RegExp","Array","Float32Array","Float64Array","Int8Array","Uint8Array","Uint8ClampedArray","Int16Array","Int32Array","Uint16Array","Uint32Array","BigInt64Array","BigUint64Array","Set","Map","WeakSet","WeakMap","ArrayBuffer","SharedArrayBuffer","Atomics","DataView","JSON","Promise","Generator","GeneratorFunction","AsyncFunction","Reflect","Proxy","Intl","WebAssembly"],Xt=["Error","EvalError","InternalError","RangeError","ReferenceError","SyntaxError","TypeError","URIError"],Vt=["setInterval","setTimeout","clearInterval","clearTimeout","require","exports","eval","isFinite","isNaN","parseFloat","parseInt","decodeURI","decodeURIComponent","encodeURI","encodeURIComponent","escape","unescape"],Qt=["arguments","this","super","console","window","document","localStorage","sessionStorage","module","self","global"],Jt=[].concat(Vt,Yt,Xt);function Nr(e){let n=e.regex,t=(E,{after:w})=>{let B="</"+E[0].slice(1);return E.input.indexOf(B,w)!==-1},a=De,s={begin:"<>",end:"</>"},u=/<[A-Za-z0-9\\._:-]+\s*\/>/,r={begin:/<[A-Za-z0-9\\._:-]+/,end:/\/[A-Za-z0-9\\._:-]+>|\/>/,isTrulyOpeningTag:(E,w)=>{let B=E[0].length+E.index,$=E.input[B];if($==="<"||$===","){w.ignoreMatch();return}$===">"&&(t(E,{after:B})||w.ignoreMatch());let K,j=E.input.substring(B);if(K=j.match(/^\s*=/)){w.ignoreMatch();return}if((K=j.match(/^\s+extends\s+/))&&K.index===0){w.ignoreMatch();return}}},i={$pattern:De,keyword:Zt,literal:Wt,built_in:Jt,"variable.language":Qt},o="[0-9](_?[0-9])*",c=`\\.(${o})`,d="0|[1-9](_?[0-9])*|0[0-7]*[89][0-9]*",m={className:"number",variants:[{begin:`(\\b(${d})((${c})|\\.)?|(${c}))[eE][+-]?(${o})\\b`},{begin:`\\b(${d})\\b((${c})\\b|\\.)?|(${c})\\b`},{begin:"\\b(0|[1-9](_?[0-9])*)n\\b"},{begin:"\\b0[xX][0-9a-fA-F](_?[0-9a-fA-F])*n?\\b"},{begin:"\\b0[bB][0-1](_?[0-1])*n?\\b"},{begin:"\\b0[oO][0-7](_?[0-7])*n?\\b"},{begin:"\\b0[0-7]+n?\\b"}],relevance:0},g={className:"subst",begin:"\\$\\{",end:"\\}",keywords:i,contains:[]},p={begin:".?html`",end:"",starts:{end:"`",returnEnd:!1,contains:[e.BACKSLASH_ESCAPE,g],subLanguage:"xml"}},y={begin:".?css`",end:"",starts:{end:"`",returnEnd:!1,contains:[e.BACKSLASH_ESCAPE,g],subLanguage:"css"}},h={begin:".?gql`",end:"",starts:{end:"`",returnEnd:!1,contains:[e.BACKSLASH_ESCAPE,g],subLanguage:"graphql"}},T={className:"string",begin:"`",end:"`",contains:[e.BACKSLASH_ESCAPE,g]},C={className:"comment",variants:[e.COMMENT(/\/\*\*(?!\/)/,"\\*/",{relevance:0,contains:[{begin:"(?=@[A-Za-z]+)",relevance:0,contains:[{className:"doctag",begin:"@[A-Za-z]+"},{className:"type",begin:"\\{",end:"\\}",excludeEnd:!0,excludeBegin:!0,relevance:0},{className:"variable",begin:a+"(?=\\s*(-)|$)",endsParent:!0,relevance:0},{begin:/(?=[^\n])\s/,relevance:0}]}]}),e.C_BLOCK_COMMENT_MODE,e.C_LINE_COMMENT_MODE]},R=[e.APOS_STRING_MODE,e.QUOTE_STRING_MODE,p,y,h,T,{match:/\$\d+/},m];g.contains=R.concat({begin:/\{/,end:/\}/,keywords:i,contains:["self"].concat(R)});let S=[].concat(C,g.contains),A=S.concat([{begin:/(\s*)\(/,end:/\)/,keywords:i,contains:["self"].concat(S)}]),M={className:"params",begin:/(\s*)\(/,end:/\)/,excludeBegin:!0,excludeEnd:!0,keywords:i,contains:A},L={variants:[{match:[/class/,/\s+/,a,/\s+/,/extends/,/\s+/,n.concat(a,"(",n.concat(/\./,a),")*")],scope:{1:"keyword",3:"title.class",5:"keyword",7:"title.class.inherited"}},{match:[/class/,/\s+/,a],scope:{1:"keyword",3:"title.class"}}]},D={relevance:0,match:n.either(/\bJSON/,/\b[A-Z][a-z]+([A-Z][a-z]*|\d)*/,/\b[A-Z]{2,}([A-Z][a-z]+|\d)+([A-Z][a-z]*)*/,/\b[A-Z]{2,}[a-z]+([A-Z][a-z]+|\d)*([A-Z][a-z]*)*/),className:"title.class",keywords:{_:[...Yt,...Xt]}},U={label:"use_strict",className:"meta",relevance:10,begin:/^\s*['"]use (strict|asm)['"]/},O={variants:[{match:[/function/,/\s+/,a,/(?=\s*\()/]},{match:[/function/,/\s*(?=\()/]}],className:{1:"keyword",3:"title.function"},label:"func.def",contains:[M],illegal:/%/},H={relevance:0,match:/\b[A-Z][A-Z_0-9]+\b/,className:"variable.constant"};function J(E){return n.concat("(?!",E.join("|"),")")}let ne={match:n.concat(/\b/,J([...Vt,"super","import","await"].map(E=>`${E}\\s*\\(`)),a,n.lookahead(/\s*\(/)),className:"title.function",relevance:0},q={begin:n.concat(/\./,n.lookahead(n.concat(a,/(?![0-9A-Za-z$_(])/))),end:a,excludeBegin:!0,keywords:"prototype",className:"property",relevance:0},Z={match:[/get|set/,/\s+/,a,/(?=\()/],className:{1:"keyword",3:"title.function"},contains:[{begin:/\(\)/},M]},l="(\\([^()]*(\\([^()]*(\\([^()]*\\)[^()]*)*\\)[^()]*)*\\)|"+e.UNDERSCORE_IDENT_RE+")\\s*=>",_={match:[/const|var|let/,/\s+/,a,/\s*/,/=\s*/,/(async\s*)?/,n.lookahead(l)],keywords:"async",className:{1:"keyword",3:"title.function"},contains:[M]};return{name:"JavaScript",aliases:["js","jsx","mjs","cjs"],keywords:i,exports:{PARAMS_CONTAINS:A,CLASS_REFERENCE:D},illegal:/#(?![$_A-Za-z])/,contains:[e.SHEBANG({label:"shebang",binary:"node",relevance:5}),U,e.APOS_STRING_MODE,e.QUOTE_STRING_MODE,p,y,h,T,C,{match:/\$\d+/},m,D,{scope:"attr",match:a+n.lookahead(":"),relevance:0},_,{begin:"("+e.RE_STARTERS_RE+"|\\b(case|return|throw)\\b)\\s*",keywords:"return throw case",relevance:0,contains:[C,e.REGEXP_MODE,{className:"function",begin:l,returnBegin:!0,end:"\\s*=>",contains:[{className:"params",variants:[{begin:e.UNDERSCORE_IDENT_RE,relevance:0},{className:null,begin:/\(\s*\)/,skip:!0},{begin:/(\s*)\(/,end:/\)/,excludeBegin:!0,excludeEnd:!0,keywords:i,contains:A}]}]},{begin:/,/,relevance:0},{match:/\s+/,relevance:0},{variants:[{begin:s.begin,end:s.end},{match:u},{begin:r.begin,"on:begin":r.isTrulyOpeningTag,end:r.end}],subLanguage:"xml",contains:[{begin:r.begin,end:r.end,skip:!0,contains:["self"]}]}]},O,{beginKeywords:"while if switch catch for"},{begin:"\\b(?!function)"+e.UNDERSCORE_IDENT_RE+"\\([^()]*(\\([^()]*(\\([^()]*\\)[^()]*)*\\)[^()]*)*\\)\\s*\\{",returnBegin:!0,label:"func.def",contains:[M,e.inherit(e.TITLE_MODE,{begin:a,className:"title.function"})]},{match:/\.\.\./,relevance:0},q,{match:"\\$"+a,relevance:0},{match:[/\bconstructor(?=\s*\()/],className:{1:"title.function"},contains:[M]},ne,H,L,Z,{match:/\$[(.]/}]}}function yr(e){let n=e.regex,t=Nr(e),a=De,s=["any","void","number","boolean","string","object","never","symbol","bigint","unknown"],u={begin:[/namespace/,/\s+/,e.IDENT_RE],beginScope:{1:"keyword",3:"title.class"}},r={beginKeywords:"interface",end:/\{/,excludeEnd:!0,keywords:{keyword:"interface extends",built_in:s},contains:[t.exports.CLASS_REFERENCE]},i={className:"meta",relevance:10,begin:/^\s*['"]use strict['"]/},o=["type","interface","public","private","protected","implements","declare","abstract","readonly","enum","override","satisfies"],c={$pattern:De,keyword:Zt.concat(o),literal:Wt,built_in:Jt.concat(s),"variable.language":Qt},d={className:"meta",begin:"@"+a},m=(h,T,N)=>{let C=h.contains.findIndex(R=>R.label===T);if(C===-1)throw new Error("can not find mode to replace");h.contains.splice(C,1,N)};Object.assign(t.keywords,c),t.exports.PARAMS_CONTAINS.push(d);let g=t.contains.find(h=>h.scope==="attr"),p=Object.assign({},g,{match:n.concat(a,n.lookahead(/\s*\?:/))});t.exports.PARAMS_CONTAINS.push([t.exports.CLASS_REFERENCE,g,p]),t.contains=t.contains.concat([d,u,r,p]),m(t,"shebang",e.SHEBANG()),m(t,"use_strict",i);let y=t.contains.find(h=>h.label==="func.def");return y.relevance=0,Object.assign(t,{name:"TypeScript",aliases:["ts","tsx","mts","cts"]}),t}jt.exports=yr});var ta=k((ls,na)=>{function Tr(e){let n=e.regex,t={className:"string",begin:/"(""|[^/n])"C\b/},a={className:"string",begin:/"/,end:/"/,illegal:/\n/,contains:[{begin:/""/}]},s=/\d{1,2}\/\d{1,2}\/\d{4}/,u=/\d{4}-\d{1,2}-\d{1,2}/,r=/(\d|1[012])(:\d+){0,2} *(AM|PM)/,i=/\d{1,2}(:\d{1,2}){1,2}/,o={className:"literal",variants:[{begin:n.concat(/# */,n.either(u,s),/ *#/)},{begin:n.concat(/# */,i,/ *#/)},{begin:n.concat(/# */,r,/ *#/)},{begin:n.concat(/# */,n.either(u,s),/ +/,n.either(r,i),/ *#/)}]},c={className:"number",relevance:0,variants:[{begin:/\b\d[\d_]*((\.[\d_]+(E[+-]?[\d_]+)?)|(E[+-]?[\d_]+))[RFD@!#]?/},{begin:/\b\d[\d_]*((U?[SIL])|[%&])?/},{begin:/&H[\dA-F_]+((U?[SIL])|[%&])?/},{begin:/&O[0-7_]+((U?[SIL])|[%&])?/},{begin:/&B[01_]+((U?[SIL])|[%&])?/}]},d={className:"label",begin:/^\w+:/},m=e.COMMENT(/'''/,/$/,{contains:[{className:"doctag",begin:/<\/?/,end:/>/}]}),g=e.COMMENT(null,/$/,{variants:[{begin:/'/},{begin:/([\t ]|^)REM(?=\s)/}]});return{name:"Visual Basic .NET",aliases:["vb"],case_insensitive:!0,classNameAliases:{label:"symbol"},keywords:{keyword:"addhandler alias aggregate ansi as async assembly auto binary by byref byval call case catch class compare const continue custom declare default delegate dim distinct do each equals else elseif end enum erase error event exit explicit finally for friend from function get global goto group handles if implements imports in inherits interface into iterator join key let lib loop me mid module mustinherit mustoverride mybase myclass namespace narrowing new next notinheritable notoverridable of off on operator option optional order overloads overridable overrides paramarray partial preserve private property protected public raiseevent readonly redim removehandler resume return select set shadows shared skip static step stop structure strict sub synclock take text then throw to try unicode until using when where while widening with withevents writeonly yield",built_in:"addressof and andalso await directcast gettype getxmlnamespace is isfalse isnot istrue like mod nameof new not or orelse trycast typeof xor cbool cbyte cchar cdate cdbl cdec cint clng cobj csbyte cshort csng cstr cuint culng cushort",type:"boolean byte char date decimal double integer long object sbyte short single string uinteger ulong ushort",literal:"true false nothing"},illegal:"//|\\{|\\}|endif|gosub|variant|wend|^\\$ ",contains:[t,a,o,c,d,m,g,{className:"meta",begin:/[\t ]*#(const|disable|else|elseif|enable|end|externalsource|if|region)\b/,end:/$/,keywords:{keyword:"const disable else elseif enable end externalsource if region then"},contains:[g]}]}}na.exports=Tr});var ia=k((ds,aa)=>{function vr(e){e.regex;let n=e.COMMENT(/\(;/,/;\)/);n.contains.push("self");let t=e.COMMENT(/;;/,/$/),a=["anyfunc","block","br","br_if","br_table","call","call_indirect","data","drop","elem","else","end","export","func","global.get","global.set","local.get","local.set","local.tee","get_global","get_local","global","if","import","local","loop","memory","memory.grow","memory.size","module","mut","nop","offset","param","result","return","select","set_global","set_local","start","table","tee_local","then","type","unreachable"],s={begin:[/(?:func|call|call_indirect)/,/\s+/,/\$[^\s)]+/],className:{1:"keyword",3:"title.function"}},u={className:"variable",begin:/\$[\w_]+/},r={match:/(\((?!;)|\))+/,className:"punctuation",relevance:0},i={className:"number",relevance:0,match:/[+-]?\b(?:\d(?:_?\d)*(?:\.\d(?:_?\d)*)?(?:[eE][+-]?\d(?:_?\d)*)?|0x[\da-fA-F](?:_?[\da-fA-F])*(?:\.[\da-fA-F](?:_?[\da-fA-D])*)?(?:[pP][+-]?\d(?:_?\d)*)?)\b|\binf\b|\bnan(?::0x[\da-fA-F](?:_?[\da-fA-D])*)?\b/},o={match:/(i32|i64|f32|f64)(?!\.)/,className:"type"},c={className:"keyword",match:/\b(f32|f64|i32|i64)(?:\.(?:abs|add|and|ceil|clz|const|convert_[su]\/i(?:32|64)|copysign|ctz|demote\/f64|div(?:_[su])?|eqz?|extend_[su]\/i32|floor|ge(?:_[su])?|gt(?:_[su])?|le(?:_[su])?|load(?:(?:8|16|32)_[su])?|lt(?:_[su])?|max|min|mul|nearest|neg?|or|popcnt|promote\/f32|reinterpret\/[fi](?:32|64)|rem_[su]|rot[lr]|shl|shr_[su]|store(?:8|16|32)?|sqrt|sub|trunc(?:_[su]\/f(?:32|64))?|wrap\/i64|xor))\b/};return{name:"WebAssembly",keywords:{$pattern:/[\w.]+/,keyword:a},contains:[t,n,{match:[/(?:offset|align)/,/\s*/,/=/],className:{1:"keyword",3:"operator"}},u,r,s,e.QUOTE_STRING_MODE,o,c,i]}}aa.exports=vr});var sa=k((us,ra)=>{var x=fn();x.registerLanguage("xml",Nn());x.registerLanguage("bash",Tn());x.registerLanguage("c",Sn());x.registerLanguage("cpp",On());x.registerLanguage("csharp",Rn());x.registerLanguage("css",kn());x.registerLanguage("markdown",Cn());x.registerLanguage("diff",Dn());x.registerLanguage("ruby",Bn());x.registerLanguage("go",Pn());x.registerLanguage("graphql",zn());x.registerLanguage("ini",Gn());x.registerLanguage("java",Zn());x.registerLanguage("javascript",Jn());x.registerLanguage("json",et());x.registerLanguage("kotlin",tt());x.registerLanguage("less",st());x.registerLanguage("lua",ct());x.registerLanguage("makefile",dt());x.registerLanguage("perl",gt());x.registerLanguage("objectivec",pt());x.registerLanguage("php",_t());x.registerLanguage("php-template",ft());x.registerLanguage("plaintext",Nt());x.registerLanguage("python",Tt());x.registerLanguage("python-repl",St());x.registerLanguage("r",Ot());x.registerLanguage("rust",Rt());x.registerLanguage("scss",kt());x.registerLanguage("shell",Ct());x.registerLanguage("sql",Dt());x.registerLanguage("swift",Kt());x.registerLanguage("yaml",qt());x.registerLanguage("typescript",ea());x.registerLanguage("vbnet",ta());x.registerLanguage("wasm",ia());x.HighlightJS=x;x.default=x;ra.exports=x});var ca=k((gs,oa)=>{function Sr(e){let n=["exports","register","file","shl","array","record","property","for","mod","while","set","ally","label","uses","raise","not","stored","class","safecall","var","interface","or","private","static","exit","index","inherited","to","else","stdcall","override","shr","asm","far","resourcestring","finalization","packed","virtual","out","and","protected","library","do","xorwrite","goto","near","function","end","div","overload","object","unit","begin","string","on","inline","repeat","until","destructor","write","message","program","with","read","initialization","except","default","nil","if","case","cdecl","in","downto","threadvar","of","try","pascal","const","external","constructor","type","public","then","implementation","finally","published","procedure","absolute","reintroduce","operator","as","is","abstract","alias","assembler","bitpacked","break","continue","cppdecl","cvar","enumerator","experimental","platform","deprecated","unimplemented","dynamic","export","far16","forward","generic","helper","implements","interrupt","iochecks","local","name","nodefault","noreturn","nostackframe","oldfpccall","otherwise","saveregisters","softfloat","specialize","strict","unaligned","varargs"],t=[e.C_LINE_COMMENT_MODE,e.COMMENT(/\{/,/\}/,{relevance:0}),e.COMMENT(/\(\*/,/\*\)/,{relevance:10})],a={className:"meta",variants:[{begin:/\{\$/,end:/\}/},{begin:/\(\*\$/,end:/\*\)/}]},s={className:"string",begin:/'/,end:/'/,contains:[{begin:/''/}]},u={className:"number",relevance:0,variants:[{match:/\b\d[\d_]*(\.\d[\d_]*)?/},{match:/\$[\dA-Fa-f_]+/},{match:/\$/,relevance:0},{match:/&[0-7][0-7_]*/},{match:/%[01_]+/},{match:/%/,relevance:0}]},r={className:"string",variants:[{match:/#\d[\d_]*/},{match:/#\$[\dA-Fa-f][\dA-Fa-f_]*/},{match:/#&[0-7][0-7_]*/},{match:/#%[01][01_]*/}]},i={begin:e.IDENT_RE+"\\s*=\\s*class\\s*\\(",returnBegin:!0,contains:[e.TITLE_MODE]},o={className:"function",beginKeywords:"function constructor destructor procedure",end:/[:;]/,keywords:"function constructor|10 destructor|10 procedure|10",contains:[e.TITLE_MODE,{className:"params",begin:/\(/,end:/\)/,keywords:n,contains:[s,r,a].concat(t)},a].concat(t)};return{name:"Delphi",aliases:["dpr","dfm","pas","pascal"],case_insensitive:!0,keywords:n,illegal:/"|\$[G-Zg-z]|\/\*|<\/|\|/,contains:[s,r,u,i,o,a].concat(t)}}oa.exports=Sr});var da=k((bs,la)=>{function Ar(e){let t=e.regex.either(...["(?:NeedsTeXFormat|RequirePackage|GetIdInfo)","Provides(?:Expl)?(?:Package|Class|File)","(?:DeclareOption|ProcessOptions)","(?:documentclass|usepackage|input|include)","makeat(?:letter|other)","ExplSyntax(?:On|Off)","(?:new|renew|provide)?command","(?:re)newenvironment","(?:New|Renew|Provide|Declare)(?:Expandable)?DocumentCommand","(?:New|Renew|Provide|Declare)DocumentEnvironment","(?:(?:e|g|x)?def|let)","(?:begin|end)","(?:part|chapter|(?:sub){0,2}section|(?:sub)?paragraph)","caption","(?:label|(?:eq|page|name)?ref|(?:paren|foot|super)?cite)","(?:alpha|beta|[Gg]amma|[Dd]elta|(?:var)?epsilon|zeta|eta|[Tt]heta|vartheta)","(?:iota|(?:var)?kappa|[Ll]ambda|mu|nu|[Xx]i|[Pp]i|varpi|(?:var)rho)","(?:[Ss]igma|varsigma|tau|[Uu]psilon|[Pp]hi|varphi|chi|[Pp]si|[Oo]mega)","(?:frac|sum|prod|lim|infty|times|sqrt|leq|geq|left|right|middle|[bB]igg?)","(?:[lr]angle|q?quad|[lcvdi]?dots|d?dot|hat|tilde|bar)"].map(O=>O+"(?![a-zA-Z@:_])")),a=new RegExp(["(?:__)?[a-zA-Z]{2,}_[a-zA-Z](?:_?[a-zA-Z])+:[a-zA-Z]*","[lgc]__?[a-zA-Z](?:_?[a-zA-Z])*_[a-zA-Z]{2,}","[qs]__?[a-zA-Z](?:_?[a-zA-Z])+","use(?:_i)?:[a-zA-Z]*","(?:else|fi|or):","(?:if|cs|exp):w","(?:hbox|vbox):n","::[a-zA-Z]_unbraced","::[a-zA-Z:]"].map(O=>O+"(?![a-zA-Z:_])").join("|")),s=[{begin:/[a-zA-Z@]+/},{begin:/[^a-zA-Z@]?/}],u=[{begin:/\^{6}[0-9a-f]{6}/},{begin:/\^{5}[0-9a-f]{5}/},{begin:/\^{4}[0-9a-f]{4}/},{begin:/\^{3}[0-9a-f]{3}/},{begin:/\^{2}[0-9a-f]{2}/},{begin:/\^{2}[\u0000-\u007f]/}],r={className:"keyword",begin:/\\/,relevance:0,contains:[{endsParent:!0,begin:t},{endsParent:!0,begin:a},{endsParent:!0,variants:u},{endsParent:!0,relevance:0,variants:s}]},i={className:"params",relevance:0,begin:/#+\d?/},o={variants:u},c={className:"built_in",relevance:0,begin:/[$&^_]/},d={className:"meta",begin:/% ?!(T[eE]X|tex|BIB|bib)/,end:"$",relevance:10},m=e.COMMENT("%","$",{relevance:0}),g=[r,i,o,c,d,m],p={begin:/\{/,end:/\}/,relevance:0,contains:["self",...g]},y=e.inherit(p,{relevance:0,endsParent:!0,contains:[p,...g]}),h={begin:/\[/,end:/\]/,endsParent:!0,relevance:0,contains:[p,...g]},T={begin:/\s+/,relevance:0},N=[y],C=[h],R=function(O,H){return{contains:[T],starts:{relevance:0,contains:O,starts:H}}},S=function(O,H){return{begin:"\\\\"+O+"(?![a-zA-Z@:_])",keywords:{$pattern:/\\[a-zA-Z]+/,keyword:"\\"+O},relevance:0,contains:[T],starts:H}},A=function(O,H){return e.inherit({begin:"\\\\begin(?=[ 	]*(\\r?\\n[ 	]*)?\\{"+O+"\\})",keywords:{$pattern:/\\[a-zA-Z]+/,keyword:"\\begin"},relevance:0},R(N,H))},M=(O="string")=>e.END_SAME_AS_BEGIN({className:O,begin:/(.|\r?\n)/,end:/(.|\r?\n)/,excludeBegin:!0,excludeEnd:!0,endsParent:!0}),L=function(O){return{className:"string",end:"(?=\\\\end\\{"+O+"\\})"}},D=(O="string")=>({relevance:0,begin:/\{/,starts:{endsParent:!0,contains:[{className:O,end:/(?=\})/,endsParent:!0,contains:[{begin:/\{/,end:/\}/,relevance:0,contains:["self"]}]}]}}),U=[...["verb","lstinline"].map(O=>S(O,{contains:[M()]})),S("mint",R(N,{contains:[M()]})),S("mintinline",R(N,{contains:[D(),M()]})),S("url",{contains:[D("link"),D("link")]}),S("hyperref",{contains:[D("link")]}),S("href",R(C,{contains:[D("link")]})),...[].concat(...["","\\*"].map(O=>[A("verbatim"+O,L("verbatim"+O)),A("filecontents"+O,R(N,L("filecontents"+O))),...["","B","L"].map(H=>A(H+"Verbatim"+O,R(C,L(H+"Verbatim"+O))))])),A("minted",R(C,R(N,L("minted"))))];return{name:"LaTeX",aliases:["tex"],contains:[...U,...g]}}la.exports=Ar});var ga=k((ps,ua)=>{function Or(e){let n="('|\\.')+",t={relevance:0,contains:[{begin:n}]};return{name:"Matlab",keywords:{keyword:"arguments break case catch classdef continue else elseif end enumeration events for function global if methods otherwise parfor persistent properties return spmd switch try while",built_in:"sin sind sinh asin asind asinh cos cosd cosh acos acosd acosh tan tand tanh atan atand atan2 atanh sec secd sech asec asecd asech csc cscd csch acsc acscd acsch cot cotd coth acot acotd acoth hypot exp expm1 log log1p log10 log2 pow2 realpow reallog realsqrt sqrt nthroot nextpow2 abs angle complex conj imag real unwrap isreal cplxpair fix floor ceil round mod rem sign airy besselj bessely besselh besseli besselk beta betainc betaln ellipj ellipke erf erfc erfcx erfinv expint gamma gammainc gammaln psi legendre cross dot factor isprime primes gcd lcm rat rats perms nchoosek factorial cart2sph cart2pol pol2cart sph2cart hsv2rgb rgb2hsv zeros ones eye repmat rand randn linspace logspace freqspace meshgrid accumarray size length ndims numel disp isempty isequal isequalwithequalnans cat reshape diag blkdiag tril triu fliplr flipud flipdim rot90 find sub2ind ind2sub bsxfun ndgrid permute ipermute shiftdim circshift squeeze isscalar isvector ans eps realmax realmin pi i|0 inf nan isnan isinf isfinite j|0 why compan gallery hadamard hankel hilb invhilb magic pascal rosser toeplitz vander wilkinson max min nanmax nanmin mean nanmean type table readtable writetable sortrows sort figure plot plot3 scatter scatter3 cellfun legend intersect ismember procrustes hold num2cell "},illegal:'(//|"|#|/\\*|\\s+/\\w+)',contains:[{className:"function",beginKeywords:"function",end:"$",contains:[e.UNDERSCORE_TITLE_MODE,{className:"params",variants:[{begin:"\\(",end:"\\)"},{begin:"\\[",end:"\\]"}]}]},{className:"built_in",begin:/true|false/,relevance:0,starts:t},{begin:"[a-zA-Z][a-zA-Z_0-9]*"+n,relevance:0},{className:"number",begin:e.C_NUMBER_RE,relevance:0,starts:t},{className:"string",begin:"'",end:"'",contains:[{begin:"''"}]},{begin:/\]|\}|\)/,relevance:0,starts:t},{className:"string",begin:'"',end:'"',contains:[{begin:'""'}],starts:t},e.COMMENT("^\\s*%\\{\\s*$","^\\s*%\\}\\s*$"),e.COMMENT("%","$")]}}ua.exports=Or});var Le=sa();Le.registerLanguage("delphi",ca());Le.registerLanguage("latex",da());Le.registerLanguage("matlab",ga());window.hljs=Le;})();;
!(function(e, t) {
  "object" == typeof exports && "object" == typeof module ? module.exports = t() : "function" == typeof define && define.amd ? define([], t) : "object" == typeof exports ? exports.katex = t() : e.katex = t();
})("undefined" != typeof self ? self : this, function() {
  return (function() {
    "use strict";
    var e = { d: function(t2, r2) {
      for (var n2 in r2) e.o(r2, n2) && !e.o(t2, n2) && Object.defineProperty(t2, n2, { enumerable: true, get: r2[n2] });
    }, o: function(e2, t2) {
      return Object.prototype.hasOwnProperty.call(e2, t2);
    } }, t = {};
    e.d(t, { default: function() {
      return ko;
    } });
    class r extends Error {
      constructor(e2, t2) {
        let n2, o2, s2 = "KaTeX parse error: " + e2;
        const i2 = t2 && t2.loc;
        if (i2 && i2.start <= i2.end) {
          const e3 = i2.lexer.input;
          n2 = i2.start, o2 = i2.end, n2 === e3.length ? s2 += " at end of input: " : s2 += " at position " + (n2 + 1) + ": ";
          const t3 = e3.slice(n2, o2).replace(/[^]/g, "$&\u0332");
          let r2, l2;
          r2 = n2 > 15 ? "\u2026" + e3.slice(n2 - 15, n2) : e3.slice(0, n2), l2 = o2 + 15 < e3.length ? e3.slice(o2, o2 + 15) + "\u2026" : e3.slice(o2), s2 += r2 + t3 + l2;
        }
        super(s2), this.name = "ParseError", this.position = void 0, this.length = void 0, this.rawMessage = void 0, Object.setPrototypeOf(this, r.prototype), this.position = n2, null != n2 && null != o2 && (this.length = o2 - n2), this.rawMessage = e2;
      }
    }
    var n = r;
    const o = /([A-Z])/g, s = (e2) => e2.replace(o, "-$1").toLowerCase(), i = { "&": "&amp;", ">": "&gt;", "<": "&lt;", '"': "&quot;", "'": "&#x27;" }, l = /[&><"']/g, a = (e2) => String(e2).replace(l, (e3) => i[e3]), c = (e2) => "ordgroup" === e2.type || "color" === e2.type ? 1 === e2.body.length ? c(e2.body[0]) : e2 : "font" === e2.type ? c(e2.body) : e2, h = /* @__PURE__ */ new Set(["mathord", "textord", "atom"]), m = (e2) => h.has(c(e2).type), u = { displayMode: { type: "boolean", description: "Render math in display mode, which puts the math in display style (so \\int and \\sum are large, for example), and centers the math on the page on its own line.", cli: "-d, --display-mode" }, output: { type: { enum: ["htmlAndMathml", "html", "mathml"] }, description: "Determines the markup language of the output.", cli: "-F, --format <type>" }, leqno: { type: "boolean", description: "Render display math in leqno style (left-justified tags)." }, fleqn: { type: "boolean", description: "Render display math flush left." }, throwOnError: { type: "boolean", default: true, cli: "-t, --no-throw-on-error", cliDescription: "Render errors (in the color given by --error-color) instead of throwing a ParseError exception when encountering an error." }, errorColor: { type: "string", default: "#cc0000", cli: "-c, --error-color <color>", cliDescription: "A color string given in the format 'rgb' or 'rrggbb' (no #). This option determines the color of errors rendered by the -t option.", cliProcessor: (e2) => "#" + e2 }, macros: { type: "object", cli: "-m, --macro <def>", cliDescription: "Define custom macro of the form '\\foo:expansion' (use multiple -m arguments for multiple macros).", cliDefault: [], cliProcessor: (e2, t2) => (t2.push(e2), t2) }, minRuleThickness: { type: "number", description: "Specifies a minimum thickness, in ems, for fraction lines, `\\sqrt` top lines, `{array}` vertical lines, `\\hline`, `\\hdashline`, `\\underline`, `\\overline`, and the borders of `\\fbox`, `\\boxed`, and `\\fcolorbox`.", processor: (e2) => Math.max(0, e2), cli: "--min-rule-thickness <size>", cliProcessor: parseFloat }, colorIsTextColor: { type: "boolean", description: "Makes \\color behave like LaTeX's 2-argument \\textcolor, instead of LaTeX's one-argument \\color mode change.", cli: "-b, --color-is-text-color" }, strict: { type: [{ enum: ["warn", "ignore", "error"] }, "boolean", "function"], description: "Turn on strict / LaTeX faithfulness mode, which throws an error if the input uses features that are not supported by LaTeX.", cli: "-S, --strict", cliDefault: false }, trust: { type: ["boolean", "function"], description: "Trust the input, enabling all HTML features such as \\url.", cli: "-T, --trust" }, maxSize: { type: "number", default: 1 / 0, description: "If non-zero, all user-specified sizes, e.g. in \\rule{500em}{500em}, will be capped to maxSize ems. Otherwise, elements and spaces can be arbitrarily large", processor: (e2) => Math.max(0, e2), cli: "-s, --max-size <n>", cliProcessor: parseInt }, maxExpand: { type: "number", default: 1e3, description: "Limit the number of macro expansions to the specified number, to prevent e.g. infinite macro loops. If set to Infinity, the macro expander will try to fully expand as in LaTeX.", processor: (e2) => Math.max(0, e2), cli: "-e, --max-expand <n>", cliProcessor: (e2) => "Infinity" === e2 ? 1 / 0 : parseInt(e2) }, globalGroup: { type: "boolean", cli: false } };
    function p(e2) {
      if (void 0 !== e2.default) return e2.default;
      return (function(e3) {
        if ("string" != typeof e3) return e3.enum[0];
        switch (e3) {
          case "boolean":
            return false;
          case "string":
            return "";
          case "number":
            return 0;
          case "object":
            return {};
          default:
            throw new Error("Unexpected schema type; settings must declare an explicit default.");
        }
      })(Array.isArray(e2.type) ? e2.type[0] : e2.type);
    }
    function d(e2, t2, r2, n2) {
      const o2 = r2[t2];
      e2[t2] = void 0 !== o2 ? n2.processor ? n2.processor(o2) : o2 : p(n2);
    }
    class g {
      constructor(e2) {
        void 0 === e2 && (e2 = {}), this.displayMode = void 0, this.output = void 0, this.leqno = void 0, this.fleqn = void 0, this.throwOnError = void 0, this.errorColor = void 0, this.macros = void 0, this.minRuleThickness = void 0, this.colorIsTextColor = void 0, this.strict = void 0, this.trust = void 0, this.maxSize = void 0, this.maxExpand = void 0, this.globalGroup = void 0, e2 = e2 || {};
        for (const t2 of Object.keys(u)) {
          const r2 = u[t2];
          r2 && d(this, t2, e2, r2);
        }
      }
      reportNonstrict(e2, t2, r2) {
        let o2 = this.strict;
        if ("function" == typeof o2 && (o2 = o2(e2, t2, r2)), o2 && "ignore" !== o2) {
          if (true === o2 || "error" === o2) throw new n("LaTeX-incompatible input and strict mode is set to 'error': " + t2 + " [" + e2 + "]", r2);
          "warn" === o2 ? "undefined" != typeof console && console.warn("LaTeX-incompatible input and strict mode is set to 'warn': " + t2 + " [" + e2 + "]") : "undefined" != typeof console && console.warn("LaTeX-incompatible input and strict mode is set to unrecognized '" + o2 + "': " + t2 + " [" + e2 + "]");
        }
      }
      useStrictBehavior(e2, t2, r2) {
        let n2 = this.strict;
        if ("function" == typeof n2) try {
          n2 = n2(e2, t2, r2);
        } catch (e3) {
          n2 = "error";
        }
        return !(!n2 || "ignore" === n2) && (true === n2 || "error" === n2 || ("warn" === n2 ? ("undefined" != typeof console && console.warn("LaTeX-incompatible input and strict mode is set to 'warn': " + t2 + " [" + e2 + "]"), false) : ("undefined" != typeof console && console.warn("LaTeX-incompatible input and strict mode is set to unrecognized '" + n2 + "': " + t2 + " [" + e2 + "]"), false)));
      }
      isTrusted(e2) {
        if ("url" in e2 && e2.url && !e2.protocol) {
          const t3 = ((e3) => {
            const t4 = /^[\x00-\x20]*([^\\/#?]*?)(:|&#0*58|&#x0*3a|&colon)/i.exec(e3);
            return t4 ? ":" !== t4[2] ? null : /^[a-zA-Z][a-zA-Z0-9+\-.]*$/.test(t4[1]) ? t4[1].toLowerCase() : null : "_relative";
          })(e2.url);
          if (null == t3) return false;
          e2.protocol = t3;
        }
        const t2 = "function" == typeof this.trust ? this.trust(e2) : this.trust;
        return Boolean(t2);
      }
    }
    class f {
      constructor(e2, t2, r2) {
        this.id = void 0, this.size = void 0, this.cramped = void 0, this.id = e2, this.size = t2, this.cramped = r2;
      }
      sup() {
        return b[y[this.id]];
      }
      sub() {
        return b[x[this.id]];
      }
      fracNum() {
        return b[w[this.id]];
      }
      fracDen() {
        return b[v[this.id]];
      }
      cramp() {
        return b[k[this.id]];
      }
      text() {
        return b[z[this.id]];
      }
      isTight() {
        return this.size >= 2;
      }
    }
    const b = [new f(0, 0, false), new f(1, 0, true), new f(2, 1, false), new f(3, 1, true), new f(4, 2, false), new f(5, 2, true), new f(6, 3, false), new f(7, 3, true)], y = [4, 5, 4, 5, 6, 7, 6, 7], x = [5, 5, 5, 5, 7, 7, 7, 7], w = [2, 3, 4, 5, 6, 7, 6, 7], v = [3, 3, 5, 5, 7, 7, 7, 7], k = [1, 1, 3, 3, 5, 5, 7, 7], z = [0, 1, 2, 3, 2, 3, 2, 3];
    var S = { DISPLAY: b[0], TEXT: b[2], SCRIPT: b[4], SCRIPTSCRIPT: b[6] };
    const M = [{ name: "latin", blocks: [[256, 591], [768, 879]] }, { name: "cyrillic", blocks: [[1024, 1279]] }, { name: "armenian", blocks: [[1328, 1423]] }, { name: "brahmic", blocks: [[2304, 4255]] }, { name: "georgian", blocks: [[4256, 4351]] }, { name: "cjk", blocks: [[12288, 12543], [19968, 40879], [65280, 65376]] }, { name: "hangul", blocks: [[44032, 55215]] }];
    const A = [];
    function T(e2) {
      for (let t2 = 0; t2 < A.length; t2 += 2) if (e2 >= A[t2] && e2 <= A[t2 + 1]) return true;
      return false;
    }
    M.forEach((e2) => e2.blocks.forEach((e3) => A.push(...e3)));
    const B = (e2) => e2 + " " + e2, C = 80, q = { doubleleftarrow: "M262 157\nl10-10c34-36 62.7-77 86-123 3.3-8 5-13.3 5-16 0-5.3-6.7-8-20-8-7.3\n 0-12.2.5-14.5 1.5-2.3 1-4.8 4.5-7.5 10.5-49.3 97.3-121.7 169.3-217 216-28\n 14-57.3 25-88 33-6.7 2-11 3.8-13 5.5-2 1.7-3 4.2-3 7.5s1 5.8 3 7.5\nc2 1.7 6.3 3.5 13 5.5 68 17.3 128.2 47.8 180.5 91.5 52.3 43.7 93.8 96.2 124.5\n 157.5 9.3 8 15.3 12.3 18 13h6c12-.7 18-4 18-10 0-2-1.7-7-5-15-23.3-46-52-87\n-86-123l-10-10h399738v-40H218c328 0 0 0 0 0l-10-8c-26.7-20-65.7-43-117-69 2.7\n-2 6-3.7 10-5 36.7-16 72.3-37.3 107-64l10-8h399782v-40z\nm8 0v40h399730v-40zm0 194v40h399730v-40z", doublerightarrow: "M399738 392l\n-10 10c-34 36-62.7 77-86 123-3.3 8-5 13.3-5 16 0 5.3 6.7 8 20 8 7.3 0 12.2-.5\n 14.5-1.5 2.3-1 4.8-4.5 7.5-10.5 49.3-97.3 121.7-169.3 217-216 28-14 57.3-25 88\n-33 6.7-2 11-3.8 13-5.5 2-1.7 3-4.2 3-7.5s-1-5.8-3-7.5c-2-1.7-6.3-3.5-13-5.5-68\n-17.3-128.2-47.8-180.5-91.5-52.3-43.7-93.8-96.2-124.5-157.5-9.3-8-15.3-12.3-18\n-13h-6c-12 .7-18 4-18 10 0 2 1.7 7 5 15 23.3 46 52 87 86 123l10 10H0v40h399782\nc-328 0 0 0 0 0l10 8c26.7 20 65.7 43 117 69-2.7 2-6 3.7-10 5-36.7 16-72.3 37.3\n-107 64l-10 8H0v40zM0 157v40h399730v-40zm0 194v40h399730v-40z", leftarrow: "M400000 241H110l3-3c68.7-52.7 113.7-120\n 135-202 4-14.7 6-23 6-25 0-7.3-7-11-21-11-8 0-13.2.8-15.5 2.5-2.3 1.7-4.2 5.8\n-5.5 12.5-1.3 4.7-2.7 10.3-4 17-12 48.7-34.8 92-68.5 130S65.3 228.3 18 247\nc-10 4-16 7.7-18 11 0 8.7 6 14.3 18 17 47.3 18.7 87.8 47 121.5 85S196 441.3 208\n 490c.7 2 1.3 5 2 9s1.2 6.7 1.5 8c.3 1.3 1 3.3 2 6s2.2 4.5 3.5 5.5c1.3 1 3.3\n 1.8 6 2.5s6 1 10 1c14 0 21-3.7 21-11 0-2-2-10.3-6-25-20-79.3-65-146.7-135-202\n l-3-3h399890zM100 241v40h399900v-40z", leftbrace: "M6 548l-6-6v-35l6-11c56-104 135.3-181.3 238-232 57.3-28.7 117\n-45 179-50h399577v120H403c-43.3 7-81 15-113 26-100.7 33-179.7 91-237 174-2.7\n 5-6 9-10 13-.7 1-7.3 1-20 1H6z", leftbraceunder: "M0 6l6-6h17c12.688 0 19.313.3 20 1 4 4 7.313 8.3 10 13\n 35.313 51.3 80.813 93.8 136.5 127.5 55.688 33.7 117.188 55.8 184.5 66.5.688\n 0 2 .3 4 1 18.688 2.7 76 4.3 172 5h399450v120H429l-6-1c-124.688-8-235-61.7\n-331-161C60.687 138.7 32.312 99.3 7 54L0 41V6z", leftgroup: "M400000 80\nH435C64 80 168.3 229.4 21 260c-5.9 1.2-18 0-18 0-2 0-3-1-3-3v-38C76 61 257 0\n 435 0h399565z", leftgroupunder: "M400000 262\nH435C64 262 168.3 112.6 21 82c-5.9-1.2-18 0-18 0-2 0-3 1-3 3v38c76 158 257 219\n 435 219h399565z", leftharpoon: "M0 267c.7 5.3 3 10 7 14h399993v-40H93c3.3\n-3.3 10.2-9.5 20.5-18.5s17.8-15.8 22.5-20.5c50.7-52 88-110.3 112-175 4-11.3 5\n-18.3 3-21-1.3-4-7.3-6-18-6-8 0-13 .7-15 2s-4.7 6.7-8 16c-42 98.7-107.3 174.7\n-196 228-6.7 4.7-10.7 8-12 10-1.3 2-2 5.7-2 11zm100-26v40h399900v-40z", leftharpoonplus: "M0 267c.7 5.3 3 10 7 14h399993v-40H93c3.3-3.3 10.2-9.5\n 20.5-18.5s17.8-15.8 22.5-20.5c50.7-52 88-110.3 112-175 4-11.3 5-18.3 3-21-1.3\n-4-7.3-6-18-6-8 0-13 .7-15 2s-4.7 6.7-8 16c-42 98.7-107.3 174.7-196 228-6.7 4.7\n-10.7 8-12 10-1.3 2-2 5.7-2 11zm100-26v40h399900v-40zM0 435v40h400000v-40z\nm0 0v40h400000v-40z", leftharpoondown: "M7 241c-4 4-6.333 8.667-7 14 0 5.333.667 9 2 11s5.333\n 5.333 12 10c90.667 54 156 130 196 228 3.333 10.667 6.333 16.333 9 17 2 .667 5\n 1 9 1h5c10.667 0 16.667-2 18-6 2-2.667 1-9.667-3-21-32-87.333-82.667-157.667\n-152-211l-3-3h399907v-40zM93 281 H400000 v-40L7 241z", leftharpoondownplus: "M7 435c-4 4-6.3 8.7-7 14 0 5.3.7 9 2 11s5.3 5.3 12\n 10c90.7 54 156 130 196 228 3.3 10.7 6.3 16.3 9 17 2 .7 5 1 9 1h5c10.7 0 16.7\n-2 18-6 2-2.7 1-9.7-3-21-32-87.3-82.7-157.7-152-211l-3-3h399907v-40H7zm93 0\nv40h399900v-40zM0 241v40h399900v-40zm0 0v40h399900v-40z", lefthook: "M400000 281 H103s-33-11.2-61-33.5S0 197.3 0 164s14.2-61.2 42.5\n-83.5C70.8 58.2 104 47 142 47 c16.7 0 25 6.7 25 20 0 12-8.7 18.7-26 20-40 3.3\n-68.7 15.7-86 37-10 12-15 25.3-15 40 0 22.7 9.8 40.7 29.5 54 19.7 13.3 43.5 21\n 71.5 23h399859zM103 281v-40h399897v40z", leftlinesegment: B("M40 281 V428 H0 V94 H40 V241 H400000 v40z"), leftbracketunder: B("M0 0 h120 V290 H399995 v120 H0z"), leftbracketover: B("M0 440 h120 V150 H399995 v-120 H0z"), leftmapsto: B("M40 281 V448H0V74H40V241H400000v40z"), leftToFrom: "M0 147h400000v40H0zm0 214c68 40 115.7 95.7 143 167h22c15.3 0 23\n-.3 23-1 0-1.3-5.3-13.7-16-37-18-35.3-41.3-69-70-101l-7-8h399905v-40H95l7-8\nc28.7-32 52-65.7 70-101 10.7-23.3 16-35.7 16-37 0-.7-7.7-1-23-1h-22C115.7 265.3\n 68 321 0 361zm0-174v-40h399900v40zm100 154v40h399900v-40z", longequal: B("M0 50 h400000 v40H0z m0 194h40000v40H0z"), midbrace: "M200428 334\nc-100.7-8.3-195.3-44-280-108-55.3-42-101.7-93-139-153l-9-14c-2.7 4-5.7 8.7-9 14\n-53.3 86.7-123.7 153-211 199-66.7 36-137.3 56.3-212 62H0V214h199568c178.3-11.7\n 311.7-78.3 403-201 6-8 9.7-12 11-12 .7-.7 6.7-1 18-1s17.3.3 18 1c1.3 0 5 4 11\n 12 44.7 59.3 101.3 106.3 170 141s145.3 54.3 229 60h199572v120z", midbraceunder: "M199572 214\nc100.7 8.3 195.3 44 280 108 55.3 42 101.7 93 139 153l9 14c2.7-4 5.7-8.7 9-14\n 53.3-86.7 123.7-153 211-199 66.7-36 137.3-56.3 212-62h199568v120H200432c-178.3\n 11.7-311.7 78.3-403 201-6 8-9.7 12-11 12-.7.7-6.7 1-18 1s-17.3-.3-18-1c-1.3 0\n-5-4-11-12-44.7-59.3-101.3-106.3-170-141s-145.3-54.3-229-60H0V214z", oiintSize1: "M512.6 71.6c272.6 0 320.3 106.8 320.3 178.2 0 70.8-47.7 177.6\n-320.3 177.6S193.1 320.6 193.1 249.8c0-71.4 46.9-178.2 319.5-178.2z\nm368.1 178.2c0-86.4-60.9-215.4-368.1-215.4-306.4 0-367.3 129-367.3 215.4 0 85.8\n60.9 214.8 367.3 214.8 307.2 0 368.1-129 368.1-214.8z", oiintSize2: "M757.8 100.1c384.7 0 451.1 137.6 451.1 230 0 91.3-66.4 228.8\n-451.1 228.8-386.3 0-452.7-137.5-452.7-228.8 0-92.4 66.4-230 452.7-230z\nm502.4 230c0-111.2-82.4-277.2-502.4-277.2s-504 166-504 277.2\nc0 110 84 276 504 276s502.4-166 502.4-276z", oiiintSize1: "M681.4 71.6c408.9 0 480.5 106.8 480.5 178.2 0 70.8-71.6 177.6\n-480.5 177.6S202.1 320.6 202.1 249.8c0-71.4 70.5-178.2 479.3-178.2z\nm525.8 178.2c0-86.4-86.8-215.4-525.7-215.4-437.9 0-524.7 129-524.7 215.4 0\n85.8 86.8 214.8 524.7 214.8 438.9 0 525.7-129 525.7-214.8z", oiiintSize2: "M1021.2 53c603.6 0 707.8 165.8 707.8 277.2 0 110-104.2 275.8\n-707.8 275.8-606 0-710.2-165.8-710.2-275.8C311 218.8 415.2 53 1021.2 53z\nm770.4 277.1c0-131.2-126.4-327.6-770.5-327.6S248.4 198.9 248.4 330.1\nc0 130 128.8 326.4 772.7 326.4s770.5-196.4 770.5-326.4z", rightarrow: "M0 241v40h399891c-47.3 35.3-84 78-110 128\n-16.7 32-27.7 63.7-33 95 0 1.3-.2 2.7-.5 4-.3 1.3-.5 2.3-.5 3 0 7.3 6.7 11 20\n 11 8 0 13.2-.8 15.5-2.5 2.3-1.7 4.2-5.5 5.5-11.5 2-13.3 5.7-27 11-41 14.7-44.7\n 39-84.5 73-119.5s73.7-60.2 119-75.5c6-2 9-5.7 9-11s-3-9-9-11c-45.3-15.3-85\n-40.5-119-75.5s-58.3-74.8-73-119.5c-4.7-14-8.3-27.3-11-40-1.3-6.7-3.2-10.8-5.5\n-12.5-2.3-1.7-7.5-2.5-15.5-2.5-14 0-21 3.7-21 11 0 2 2 10.3 6 25 20.7 83.3 67\n 151.7 139 205zm0 0v40h399900v-40z", rightbrace: "M400000 542l\n-6 6h-17c-12.7 0-19.3-.3-20-1-4-4-7.3-8.3-10-13-35.3-51.3-80.8-93.8-136.5-127.5\ns-117.2-55.8-184.5-66.5c-.7 0-2-.3-4-1-18.7-2.7-76-4.3-172-5H0V214h399571l6 1\nc124.7 8 235 61.7 331 161 31.3 33.3 59.7 72.7 85 118l7 13v35z", rightbraceunder: "M399994 0l6 6v35l-6 11c-56 104-135.3 181.3-238 232-57.3\n 28.7-117 45-179 50H-300V214h399897c43.3-7 81-15 113-26 100.7-33 179.7-91 237\n-174 2.7-5 6-9 10-13 .7-1 7.3-1 20-1h17z", rightgroup: "M0 80h399565c371 0 266.7 149.4 414 180 5.9 1.2 18 0 18 0 2 0\n 3-1 3-3v-38c-76-158-257-219-435-219H0z", rightgroupunder: "M0 262h399565c371 0 266.7-149.4 414-180 5.9-1.2 18 0 18\n 0 2 0 3 1 3 3v38c-76 158-257 219-435 219H0z", rightharpoon: "M0 241v40h399993c4.7-4.7 7-9.3 7-14 0-9.3\n-3.7-15.3-11-18-92.7-56.7-159-133.7-199-231-3.3-9.3-6-14.7-8-16-2-1.3-7-2-15-2\n-10.7 0-16.7 2-18 6-2 2.7-1 9.7 3 21 15.3 42 36.7 81.8 64 119.5 27.3 37.7 58\n 69.2 92 94.5zm0 0v40h399900v-40z", rightharpoonplus: "M0 241v40h399993c4.7-4.7 7-9.3 7-14 0-9.3-3.7-15.3-11\n-18-92.7-56.7-159-133.7-199-231-3.3-9.3-6-14.7-8-16-2-1.3-7-2-15-2-10.7 0-16.7\n 2-18 6-2 2.7-1 9.7 3 21 15.3 42 36.7 81.8 64 119.5 27.3 37.7 58 69.2 92 94.5z\nm0 0v40h399900v-40z m100 194v40h399900v-40zm0 0v40h399900v-40z", rightharpoondown: "M399747 511c0 7.3 6.7 11 20 11 8 0 13-.8 15-2.5s4.7-6.8\n 8-15.5c40-94 99.3-166.3 178-217 13.3-8 20.3-12.3 21-13 5.3-3.3 8.5-5.8 9.5\n-7.5 1-1.7 1.5-5.2 1.5-10.5s-2.3-10.3-7-15H0v40h399908c-34 25.3-64.7 57-92 95\n-27.3 38-48.7 77.7-64 119-3.3 8.7-5 14-5 16zM0 241v40h399900v-40z", rightharpoondownplus: "M399747 705c0 7.3 6.7 11 20 11 8 0 13-.8\n 15-2.5s4.7-6.8 8-15.5c40-94 99.3-166.3 178-217 13.3-8 20.3-12.3 21-13 5.3-3.3\n 8.5-5.8 9.5-7.5 1-1.7 1.5-5.2 1.5-10.5s-2.3-10.3-7-15H0v40h399908c-34 25.3\n-64.7 57-92 95-27.3 38-48.7 77.7-64 119-3.3 8.7-5 14-5 16zM0 435v40h399900v-40z\nm0-194v40h400000v-40zm0 0v40h400000v-40z", righthook: "M399859 241c-764 0 0 0 0 0 40-3.3 68.7-15.7 86-37 10-12 15-25.3\n 15-40 0-22.7-9.8-40.7-29.5-54-19.7-13.3-43.5-21-71.5-23-17.3-1.3-26-8-26-20 0\n-13.3 8.7-20 26-20 38 0 71 11.2 99 33.5 0 0 7 5.6 21 16.7 14 11.2 21 33.5 21\n 66.8s-14 61.2-42 83.5c-28 22.3-61 33.5-99 33.5L0 241z M0 281v-40h399859v40z", rightlinesegment: B("M399960 241 V94 h40 V428 h-40 V281 H0 v-40z"), rightbracketunder: B("M399995 0 h-120 V290 H0 v120 H400000z"), rightbracketover: B("M399995 440 h-120 V150 H0 v-120 H399995z"), rightToFrom: "M400000 167c-70.7-42-118-97.7-142-167h-23c-15.3 0-23 .3-23\n 1 0 1.3 5.3 13.7 16 37 18 35.3 41.3 69 70 101l7 8H0v40h399905l-7 8c-28.7 32\n-52 65.7-70 101-10.7 23.3-16 35.7-16 37 0 .7 7.7 1 23 1h23c24-69.3 71.3-125 142\n-167z M100 147v40h399900v-40zM0 341v40h399900v-40z", twoheadleftarrow: "M0 167c68 40\n 115.7 95.7 143 167h22c15.3 0 23-.3 23-1 0-1.3-5.3-13.7-16-37-18-35.3-41.3-69\n-70-101l-7-8h125l9 7c50.7 39.3 85 86 103 140h46c0-4.7-6.3-18.7-19-42-18-35.3\n-40-67.3-66-96l-9-9h399716v-40H284l9-9c26-28.7 48-60.7 66-96 12.7-23.333 19\n-37.333 19-42h-46c-18 54-52.3 100.7-103 140l-9 7H95l7-8c28.7-32 52-65.7 70-101\n 10.7-23.333 16-35.7 16-37 0-.7-7.7-1-23-1h-22C115.7 71.3 68 127 0 167z", twoheadrightarrow: "M400000 167\nc-68-40-115.7-95.7-143-167h-22c-15.3 0-23 .3-23 1 0 1.3 5.3 13.7 16 37 18 35.3\n 41.3 69 70 101l7 8h-125l-9-7c-50.7-39.3-85-86-103-140h-46c0 4.7 6.3 18.7 19 42\n 18 35.3 40 67.3 66 96l9 9H0v40h399716l-9 9c-26 28.7-48 60.7-66 96-12.7 23.333\n-19 37.333-19 42h46c18-54 52.3-100.7 103-140l9-7h125l-7 8c-28.7 32-52 65.7-70\n 101-10.7 23.333-16 35.7-16 37 0 .7 7.7 1 23 1h22c27.3-71.3 75-127 143-167z", tilde1: "M200 55.538c-77 0-168 73.953-177 73.953-3 0-7\n-2.175-9-5.437L2 97c-1-2-2-4-2-6 0-4 2-7 5-9l20-12C116 12 171 0 207 0c86 0\n 114 68 191 68 78 0 168-68 177-68 4 0 7 2 9 5l12 19c1 2.175 2 4.35 2 6.525 0\n 4.35-2 7.613-5 9.788l-19 13.05c-92 63.077-116.937 75.308-183 76.128\n-68.267.847-113-73.952-191-73.952z", tilde2: "M344 55.266c-142 0-300.638 81.316-311.5 86.418\n-8.01 3.762-22.5 10.91-23.5 5.562L1 120c-1-2-1-3-1-4 0-5 3-9 8-10l18.4-9C160.9\n 31.9 283 0 358 0c148 0 188 122 331 122s314-97 326-97c4 0 8 2 10 7l7 21.114\nc1 2.14 1 3.21 1 4.28 0 5.347-3 9.626-7 10.696l-22.3 12.622C852.6 158.372 751\n 181.476 676 181.476c-149 0-189-126.21-332-126.21z", tilde3: "M786 59C457 59 32 175.242 13 175.242c-6 0-10-3.457\n-11-10.37L.15 138c-1-7 3-12 10-13l19.2-6.4C378.4 40.7 634.3 0 804.3 0c337 0\n 411.8 157 746.8 157 328 0 754-112 773-112 5 0 10 3 11 9l1 14.075c1 8.066-.697\n 16.595-6.697 17.492l-21.052 7.31c-367.9 98.146-609.15 122.696-778.15 122.696\n -338 0-409-156.573-744-156.573z", tilde4: "M786 58C457 58 32 177.487 13 177.487c-6 0-10-3.345\n-11-10.035L.15 143c-1-7 3-12 10-13l22-6.7C381.2 35 637.15 0 807.15 0c337 0 409\n 177 744 177 328 0 754-127 773-127 5 0 10 3 11 9l1 14.794c1 7.805-3 13.38-9\n 14.495l-20.7 5.574c-366.85 99.79-607.3 139.372-776.3 139.372-338 0-409\n -175.236-744-175.236z", vec: "M377 20c0-5.333 1.833-10 5.5-14S391 0 397 0c4.667 0 8.667 1.667 12 5\n3.333 2.667 6.667 9 10 19 6.667 24.667 20.333 43.667 41 57 7.333 4.667 11\n10.667 11 18 0 6-1 10-3 12s-6.667 5-14 9c-28.667 14.667-53.667 35.667-75 63\n-1.333 1.333-3.167 3.5-5.5 6.5s-4 4.833-5 5.5c-1 .667-2.5 1.333-4.5 2s-4.333 1\n-7 1c-4.667 0-9.167-1.833-13.5-5.5S337 184 337 178c0-12.667 15.667-32.333 47-59\nH213l-171-1c-8.667-6-13-12.333-13-19 0-4.667 4.333-11.333 13-20h359\nc-16-25.333-24-45-24-59z", widehat1: "M529 0h5l519 115c5 1 9 5 9 10 0 1-1 2-1 3l-4 22\nc-1 5-5 9-11 9h-2L532 67 19 159h-2c-5 0-9-4-11-9l-5-22c-1-6 2-12 8-13z", widehat2: "M1181 0h2l1171 176c6 0 10 5 10 11l-2 23c-1 6-5 10\n-11 10h-1L1182 67 15 220h-1c-6 0-10-4-11-10l-2-23c-1-6 4-11 10-11z", widehat3: "M1181 0h2l1171 236c6 0 10 5 10 11l-2 23c-1 6-5 10\n-11 10h-1L1182 67 15 280h-1c-6 0-10-4-11-10l-2-23c-1-6 4-11 10-11z", widehat4: "M1181 0h2l1171 296c6 0 10 5 10 11l-2 23c-1 6-5 10\n-11 10h-1L1182 67 15 340h-1c-6 0-10-4-11-10l-2-23c-1-6 4-11 10-11z", widecheck1: "M529,159h5l519,-115c5,-1,9,-5,9,-10c0,-1,-1,-2,-1,-3l-4,-22c-1,\n-5,-5,-9,-11,-9h-2l-512,92l-513,-92h-2c-5,0,-9,4,-11,9l-5,22c-1,6,2,12,8,13z", widecheck2: "M1181,220h2l1171,-176c6,0,10,-5,10,-11l-2,-23c-1,-6,-5,-10,\n-11,-10h-1l-1168,153l-1167,-153h-1c-6,0,-10,4,-11,10l-2,23c-1,6,4,11,10,11z", widecheck3: "M1181,280h2l1171,-236c6,0,10,-5,10,-11l-2,-23c-1,-6,-5,-10,\n-11,-10h-1l-1168,213l-1167,-213h-1c-6,0,-10,4,-11,10l-2,23c-1,6,4,11,10,11z", widecheck4: "M1181,340h2l1171,-296c6,0,10,-5,10,-11l-2,-23c-1,-6,-5,-10,\n-11,-10h-1l-1168,273l-1167,-273h-1c-6,0,-10,4,-11,10l-2,23c-1,6,4,11,10,11z", baraboveleftarrow: "M400000 620h-399890l3 -3c68.7 -52.7 113.7 -120 135 -202\nc4 -14.7 6 -23 6 -25c0 -7.3 -7 -11 -21 -11c-8 0 -13.2 0.8 -15.5 2.5\nc-2.3 1.7 -4.2 5.8 -5.5 12.5c-1.3 4.7 -2.7 10.3 -4 17c-12 48.7 -34.8 92 -68.5 130\ns-74.2 66.3 -121.5 85c-10 4 -16 7.7 -18 11c0 8.7 6 14.3 18 17c47.3 18.7 87.8 47\n121.5 85s56.5 81.3 68.5 130c0.7 2 1.3 5 2 9s1.2 6.7 1.5 8c0.3 1.3 1 3.3 2 6\ns2.2 4.5 3.5 5.5c1.3 1 3.3 1.8 6 2.5s6 1 10 1c14 0 21 -3.7 21 -11\nc0 -2 -2 -10.3 -6 -25c-20 -79.3 -65 -146.7 -135 -202l-3 -3h399890z\nM100 620v40h399900v-40z M0 241v40h399900v-40zM0 241v40h399900v-40z", rightarrowabovebar: "M0 241v40h399891c-47.3 35.3-84 78-110 128-16.7 32\n-27.7 63.7-33 95 0 1.3-.2 2.7-.5 4-.3 1.3-.5 2.3-.5 3 0 7.3 6.7 11 20 11 8 0\n13.2-.8 15.5-2.5 2.3-1.7 4.2-5.5 5.5-11.5 2-13.3 5.7-27 11-41 14.7-44.7 39\n-84.5 73-119.5s73.7-60.2 119-75.5c6-2 9-5.7 9-11s-3-9-9-11c-45.3-15.3-85-40.5\n-119-75.5s-58.3-74.8-73-119.5c-4.7-14-8.3-27.3-11-40-1.3-6.7-3.2-10.8-5.5\n-12.5-2.3-1.7-7.5-2.5-15.5-2.5-14 0-21 3.7-21 11 0 2 2 10.3 6 25 20.7 83.3 67\n151.7 139 205zm96 379h399894v40H0zm0 0h399904v40H0z", baraboveshortleftharpoon: "M507,435c-4,4,-6.3,8.7,-7,14c0,5.3,0.7,9,2,11\nc1.3,2,5.3,5.3,12,10c90.7,54,156,130,196,228c3.3,10.7,6.3,16.3,9,17\nc2,0.7,5,1,9,1c0,0,5,0,5,0c10.7,0,16.7,-2,18,-6c2,-2.7,1,-9.7,-3,-21\nc-32,-87.3,-82.7,-157.7,-152,-211c0,0,-3,-3,-3,-3l399351,0l0,-40\nc-398570,0,-399437,0,-399437,0z M593 435 v40 H399500 v-40z\nM0 281 v-40 H399908 v40z M0 281 v-40 H399908 v40z", rightharpoonaboveshortbar: "M0,241 l0,40c399126,0,399993,0,399993,0\nc4.7,-4.7,7,-9.3,7,-14c0,-9.3,-3.7,-15.3,-11,-18c-92.7,-56.7,-159,-133.7,-199,\n-231c-3.3,-9.3,-6,-14.7,-8,-16c-2,-1.3,-7,-2,-15,-2c-10.7,0,-16.7,2,-18,6\nc-2,2.7,-1,9.7,3,21c15.3,42,36.7,81.8,64,119.5c27.3,37.7,58,69.2,92,94.5z\nM0 241 v40 H399908 v-40z M0 475 v-40 H399500 v40z M0 475 v-40 H399500 v40z", shortbaraboveleftharpoon: "M7,435c-4,4,-6.3,8.7,-7,14c0,5.3,0.7,9,2,11\nc1.3,2,5.3,5.3,12,10c90.7,54,156,130,196,228c3.3,10.7,6.3,16.3,9,17c2,0.7,5,1,9,\n1c0,0,5,0,5,0c10.7,0,16.7,-2,18,-6c2,-2.7,1,-9.7,-3,-21c-32,-87.3,-82.7,-157.7,\n-152,-211c0,0,-3,-3,-3,-3l399907,0l0,-40c-399126,0,-399993,0,-399993,0z\nM93 435 v40 H400000 v-40z M500 241 v40 H400000 v-40z M500 241 v40 H400000 v-40z", shortrightharpoonabovebar: "M53,241l0,40c398570,0,399437,0,399437,0\nc4.7,-4.7,7,-9.3,7,-14c0,-9.3,-3.7,-15.3,-11,-18c-92.7,-56.7,-159,-133.7,-199,\n-231c-3.3,-9.3,-6,-14.7,-8,-16c-2,-1.3,-7,-2,-15,-2c-10.7,0,-16.7,2,-18,6\nc-2,2.7,-1,9.7,3,21c15.3,42,36.7,81.8,64,119.5c27.3,37.7,58,69.2,92,94.5z\nM500 241 v40 H399408 v-40z M500 435 v40 H400000 v-40z" };
    class I {
      constructor(e2) {
        this.children = void 0, this.classes = void 0, this.height = void 0, this.depth = void 0, this.maxFontSize = void 0, this.style = void 0, this.children = e2, this.classes = [], this.height = 0, this.depth = 0, this.maxFontSize = 0, this.style = {};
      }
      hasClass(e2) {
        return this.classes.includes(e2);
      }
      toNode() {
        const e2 = document.createDocumentFragment();
        for (let t2 = 0; t2 < this.children.length; t2++) e2.appendChild(this.children[t2].toNode());
        return e2;
      }
      toMarkup() {
        let e2 = "";
        for (let t2 = 0; t2 < this.children.length; t2++) e2 += this.children[t2].toMarkup();
        return e2;
      }
      toText() {
        return this.children.map((e2) => {
          if ("toText" in e2) return e2.toText();
          throw new Error("Expected MathDomNode with toText, got " + e2.constructor.name);
        }).join("");
      }
    }
    const R = { pt: 1, mm: 7227 / 2540, cm: 7227 / 254, in: 72.27, bp: 1.00375, pc: 12, dd: 1238 / 1157, cc: 14856 / 1157, nd: 685 / 642, nc: 1370 / 107, sp: 1 / 65536, px: 1.00375 }, E = { ex: true, em: true, mu: true }, H = function(e2) {
      return "string" != typeof e2 && (e2 = e2.unit), e2 in R || e2 in E || "ex" === e2;
    }, N = function(e2, t2) {
      let r2;
      if (e2.unit in R) r2 = R[e2.unit] / t2.fontMetrics().ptPerEm / t2.sizeMultiplier;
      else if ("mu" === e2.unit) r2 = t2.fontMetrics().cssEmPerMu;
      else {
        let o2;
        if (o2 = t2.style.isTight() ? t2.havingStyle(t2.style.text()) : t2, "ex" === e2.unit) r2 = o2.fontMetrics().xHeight;
        else {
          if ("em" !== e2.unit) throw new n("Invalid unit: '" + e2.unit + "'");
          r2 = o2.fontMetrics().quad;
        }
        o2 !== t2 && (r2 *= o2.sizeMultiplier / t2.sizeMultiplier);
      }
      return Math.min(e2.number * r2, t2.maxSize);
    }, O = function(e2) {
      return +e2.toFixed(4) + "em";
    }, D = function(e2) {
      return e2.filter((e3) => e3).join(" ");
    }, L = function(e2) {
      let t2 = "";
      for (const r2 of Object.keys(e2)) {
        const n2 = e2[r2];
        void 0 !== n2 && (t2 += s(r2) + ":" + n2 + ";");
      }
      return t2;
    }, P = function(e2, t2, r2) {
      if (this.classes = e2 || [], this.attributes = {}, this.height = 0, this.depth = 0, this.maxFontSize = 0, this.style = r2 || {}, t2) {
        t2.style.isTight() && this.classes.push("mtight");
        const e3 = t2.getColor();
        e3 && (this.style.color = e3);
      }
    }, F = function(e2) {
      const t2 = document.createElement(e2);
      t2.className = D(this.classes), Object.assign(t2.style, this.style);
      for (const e3 of Object.keys(this.attributes)) t2.setAttribute(e3, this.attributes[e3]);
      for (let e3 = 0; e3 < this.children.length; e3++) t2.appendChild(this.children[e3].toNode());
      return t2;
    }, V = /[\s"'>/=\x00-\x1f]/, G = function(e2) {
      let t2 = "<" + e2;
      this.classes.length && (t2 += ' class="' + a(D(this.classes)) + '"');
      const r2 = L(this.style);
      r2 && (t2 += ' style="' + a(r2) + '"');
      for (const e3 of Object.keys(this.attributes)) {
        if (V.test(e3)) throw new n("Invalid attribute name '" + e3 + "'");
        t2 += " " + e3 + '="' + a(this.attributes[e3]) + '"';
      }
      t2 += ">";
      for (let e3 = 0; e3 < this.children.length; e3++) t2 += this.children[e3].toMarkup();
      return t2 += "</" + e2 + ">", t2;
    };
    class U {
      constructor(e2, t2, r2, n2) {
        this.children = void 0, this.attributes = void 0, this.classes = void 0, this.height = void 0, this.depth = void 0, this.width = void 0, this.maxFontSize = void 0, this.style = void 0, this.italic = void 0, P.call(this, e2, r2, n2), this.children = t2 || [];
      }
      setAttribute(e2, t2) {
        this.attributes[e2] = t2;
      }
      hasClass(e2) {
        return this.classes.includes(e2);
      }
      toNode() {
        return F.call(this, "span");
      }
      toMarkup() {
        return G.call(this, "span");
      }
    }
    class X {
      constructor(e2, t2, r2, n2) {
        this.children = void 0, this.attributes = void 0, this.classes = void 0, this.height = void 0, this.depth = void 0, this.maxFontSize = void 0, this.style = void 0, P.call(this, t2, n2), this.children = r2 || [], this.setAttribute("href", e2);
      }
      setAttribute(e2, t2) {
        this.attributes[e2] = t2;
      }
      hasClass(e2) {
        return this.classes.includes(e2);
      }
      toNode() {
        return F.call(this, "a");
      }
      toMarkup() {
        return G.call(this, "a");
      }
    }
    class Y {
      constructor(e2, t2, r2) {
        this.src = void 0, this.alt = void 0, this.classes = void 0, this.height = void 0, this.depth = void 0, this.maxFontSize = void 0, this.style = void 0, this.alt = t2, this.src = e2, this.classes = ["mord"], this.height = 0, this.depth = 0, this.maxFontSize = 0, this.style = r2;
      }
      hasClass(e2) {
        return this.classes.includes(e2);
      }
      toNode() {
        const e2 = document.createElement("img");
        return e2.src = this.src, e2.alt = this.alt, e2.className = "mord", Object.assign(e2.style, this.style), e2;
      }
      toMarkup() {
        let e2 = '<img src="' + a(this.src) + '" alt="' + a(this.alt) + '"';
        const t2 = L(this.style);
        return t2 && (e2 += ' style="' + a(t2) + '"'), e2 += "'/>", e2;
      }
    }
    const j = { "\xEE": "\u0131\u0302", "\xEF": "\u0131\u0308", "\xED": "\u0131\u0301", "\xEC": "\u0131\u0300" };
    class W {
      constructor(e2, t2, r2, n2, o2, s2, i2, l2) {
        this.text = void 0, this.height = void 0, this.depth = void 0, this.italic = void 0, this.skew = void 0, this.width = void 0, this.maxFontSize = void 0, this.classes = void 0, this.style = void 0, this.text = e2, this.height = t2 || 0, this.depth = r2 || 0, this.italic = n2 || 0, this.skew = o2 || 0, this.width = s2 || 0, this.classes = i2 || [], this.style = l2 || {}, this.maxFontSize = 0;
        const a2 = (function(e3) {
          for (let t3 = 0; t3 < M.length; t3++) {
            const r3 = M[t3];
            for (let t4 = 0; t4 < r3.blocks.length; t4++) {
              const n3 = r3.blocks[t4];
              if (e3 >= n3[0] && e3 <= n3[1]) return r3.name;
            }
          }
          return null;
        })(this.text.charCodeAt(0));
        a2 && this.classes.push(a2 + "_fallback"), /[\xee\xef\xed\xec]/.test(this.text) && (this.text = j[this.text]);
      }
      hasClass(e2) {
        return this.classes.includes(e2);
      }
      toNode() {
        const e2 = document.createTextNode(this.text);
        let t2 = null;
        return this.italic > 0 && (t2 = document.createElement("span"), t2.style.marginRight = O(this.italic)), this.classes.length > 0 && (t2 = t2 || document.createElement("span"), t2.className = D(this.classes)), Object.keys(this.style).length > 0 && (t2 = t2 || document.createElement("span"), Object.assign(t2.style, this.style)), t2 ? (t2.appendChild(e2), t2) : e2;
      }
      toMarkup() {
        let e2 = false, t2 = "<span";
        this.classes.length && (e2 = true, t2 += ' class="', t2 += a(D(this.classes)), t2 += '"');
        let r2 = "";
        this.italic > 0 && (r2 += "margin-right:" + O(this.italic) + ";"), r2 += L(this.style), r2 && (e2 = true, t2 += ' style="' + a(r2) + '"');
        const n2 = a(this.text);
        return e2 ? (t2 += ">", t2 += n2, t2 += "</span>", t2) : n2;
      }
    }
    class _ {
      constructor(e2, t2) {
        this.children = void 0, this.attributes = void 0, this.children = e2 || [], this.attributes = t2 || {};
      }
      toNode() {
        const e2 = document.createElementNS("http://www.w3.org/2000/svg", "svg");
        for (const t2 of Object.keys(this.attributes)) e2.setAttribute(t2, this.attributes[t2]);
        for (let t2 = 0; t2 < this.children.length; t2++) e2.appendChild(this.children[t2].toNode());
        return e2;
      }
      toMarkup() {
        let e2 = '<svg xmlns="http://www.w3.org/2000/svg"';
        for (const t2 of Object.keys(this.attributes)) e2 += " " + t2 + '="' + a(this.attributes[t2]) + '"';
        e2 += ">";
        for (let t2 = 0; t2 < this.children.length; t2++) e2 += this.children[t2].toMarkup();
        return e2 += "</svg>", e2;
      }
    }
    class $ {
      constructor(e2, t2) {
        this.pathName = void 0, this.alternate = void 0, this.pathName = e2, this.alternate = t2;
      }
      toNode() {
        const e2 = document.createElementNS("http://www.w3.org/2000/svg", "path");
        return this.alternate ? e2.setAttribute("d", this.alternate) : e2.setAttribute("d", q[this.pathName]), e2;
      }
      toMarkup() {
        return this.alternate ? '<path d="' + a(this.alternate) + '"/>' : '<path d="' + a(q[this.pathName]) + '"/>';
      }
    }
    class Z {
      constructor(e2) {
        this.attributes = void 0, this.attributes = e2 || {};
      }
      toNode() {
        const e2 = document.createElementNS("http://www.w3.org/2000/svg", "line");
        for (const t2 of Object.keys(this.attributes)) e2.setAttribute(t2, this.attributes[t2]);
        return e2;
      }
      toMarkup() {
        let e2 = "<line";
        for (const t2 of Object.keys(this.attributes)) e2 += " " + t2 + '="' + a(this.attributes[t2]) + '"';
        return e2 += "/>", e2;
      }
    }
    var K = { "AMS-Regular": { 32: [0, 0, 0, 0, 0.25], 65: [0, 0.68889, 0, 0, 0.72222], 66: [0, 0.68889, 0, 0, 0.66667], 67: [0, 0.68889, 0, 0, 0.72222], 68: [0, 0.68889, 0, 0, 0.72222], 69: [0, 0.68889, 0, 0, 0.66667], 70: [0, 0.68889, 0, 0, 0.61111], 71: [0, 0.68889, 0, 0, 0.77778], 72: [0, 0.68889, 0, 0, 0.77778], 73: [0, 0.68889, 0, 0, 0.38889], 74: [0.16667, 0.68889, 0, 0, 0.5], 75: [0, 0.68889, 0, 0, 0.77778], 76: [0, 0.68889, 0, 0, 0.66667], 77: [0, 0.68889, 0, 0, 0.94445], 78: [0, 0.68889, 0, 0, 0.72222], 79: [0.16667, 0.68889, 0, 0, 0.77778], 80: [0, 0.68889, 0, 0, 0.61111], 81: [0.16667, 0.68889, 0, 0, 0.77778], 82: [0, 0.68889, 0, 0, 0.72222], 83: [0, 0.68889, 0, 0, 0.55556], 84: [0, 0.68889, 0, 0, 0.66667], 85: [0, 0.68889, 0, 0, 0.72222], 86: [0, 0.68889, 0, 0, 0.72222], 87: [0, 0.68889, 0, 0, 1], 88: [0, 0.68889, 0, 0, 0.72222], 89: [0, 0.68889, 0, 0, 0.72222], 90: [0, 0.68889, 0, 0, 0.66667], 107: [0, 0.68889, 0, 0, 0.55556], 160: [0, 0, 0, 0, 0.25], 165: [0, 0.675, 0.025, 0, 0.75], 174: [0.15559, 0.69224, 0, 0, 0.94666], 240: [0, 0.68889, 0, 0, 0.55556], 295: [0, 0.68889, 0, 0, 0.54028], 710: [0, 0.825, 0, 0, 2.33334], 732: [0, 0.9, 0, 0, 2.33334], 770: [0, 0.825, 0, 0, 2.33334], 771: [0, 0.9, 0, 0, 2.33334], 989: [0.08167, 0.58167, 0, 0, 0.77778], 1008: [0, 0.43056, 0.04028, 0, 0.66667], 8245: [0, 0.54986, 0, 0, 0.275], 8463: [0, 0.68889, 0, 0, 0.54028], 8487: [0, 0.68889, 0, 0, 0.72222], 8498: [0, 0.68889, 0, 0, 0.55556], 8502: [0, 0.68889, 0, 0, 0.66667], 8503: [0, 0.68889, 0, 0, 0.44445], 8504: [0, 0.68889, 0, 0, 0.66667], 8513: [0, 0.68889, 0, 0, 0.63889], 8592: [-0.03598, 0.46402, 0, 0, 0.5], 8594: [-0.03598, 0.46402, 0, 0, 0.5], 8602: [-0.13313, 0.36687, 0, 0, 1], 8603: [-0.13313, 0.36687, 0, 0, 1], 8606: [0.01354, 0.52239, 0, 0, 1], 8608: [0.01354, 0.52239, 0, 0, 1], 8610: [0.01354, 0.52239, 0, 0, 1.11111], 8611: [0.01354, 0.52239, 0, 0, 1.11111], 8619: [0, 0.54986, 0, 0, 1], 8620: [0, 0.54986, 0, 0, 1], 8621: [-0.13313, 0.37788, 0, 0, 1.38889], 8622: [-0.13313, 0.36687, 0, 0, 1], 8624: [0, 0.69224, 0, 0, 0.5], 8625: [0, 0.69224, 0, 0, 0.5], 8630: [0, 0.43056, 0, 0, 1], 8631: [0, 0.43056, 0, 0, 1], 8634: [0.08198, 0.58198, 0, 0, 0.77778], 8635: [0.08198, 0.58198, 0, 0, 0.77778], 8638: [0.19444, 0.69224, 0, 0, 0.41667], 8639: [0.19444, 0.69224, 0, 0, 0.41667], 8642: [0.19444, 0.69224, 0, 0, 0.41667], 8643: [0.19444, 0.69224, 0, 0, 0.41667], 8644: [0.1808, 0.675, 0, 0, 1], 8646: [0.1808, 0.675, 0, 0, 1], 8647: [0.1808, 0.675, 0, 0, 1], 8648: [0.19444, 0.69224, 0, 0, 0.83334], 8649: [0.1808, 0.675, 0, 0, 1], 8650: [0.19444, 0.69224, 0, 0, 0.83334], 8651: [0.01354, 0.52239, 0, 0, 1], 8652: [0.01354, 0.52239, 0, 0, 1], 8653: [-0.13313, 0.36687, 0, 0, 1], 8654: [-0.13313, 0.36687, 0, 0, 1], 8655: [-0.13313, 0.36687, 0, 0, 1], 8666: [0.13667, 0.63667, 0, 0, 1], 8667: [0.13667, 0.63667, 0, 0, 1], 8669: [-0.13313, 0.37788, 0, 0, 1], 8672: [-0.064, 0.437, 0, 0, 1.334], 8674: [-0.064, 0.437, 0, 0, 1.334], 8705: [0, 0.825, 0, 0, 0.5], 8708: [0, 0.68889, 0, 0, 0.55556], 8709: [0.08167, 0.58167, 0, 0, 0.77778], 8717: [0, 0.43056, 0, 0, 0.42917], 8722: [-0.03598, 0.46402, 0, 0, 0.5], 8724: [0.08198, 0.69224, 0, 0, 0.77778], 8726: [0.08167, 0.58167, 0, 0, 0.77778], 8733: [0, 0.69224, 0, 0, 0.77778], 8736: [0, 0.69224, 0, 0, 0.72222], 8737: [0, 0.69224, 0, 0, 0.72222], 8738: [0.03517, 0.52239, 0, 0, 0.72222], 8739: [0.08167, 0.58167, 0, 0, 0.22222], 8740: [0.25142, 0.74111, 0, 0, 0.27778], 8741: [0.08167, 0.58167, 0, 0, 0.38889], 8742: [0.25142, 0.74111, 0, 0, 0.5], 8756: [0, 0.69224, 0, 0, 0.66667], 8757: [0, 0.69224, 0, 0, 0.66667], 8764: [-0.13313, 0.36687, 0, 0, 0.77778], 8765: [-0.13313, 0.37788, 0, 0, 0.77778], 8769: [-0.13313, 0.36687, 0, 0, 0.77778], 8770: [-0.03625, 0.46375, 0, 0, 0.77778], 8774: [0.30274, 0.79383, 0, 0, 0.77778], 8776: [-0.01688, 0.48312, 0, 0, 0.77778], 8778: [0.08167, 0.58167, 0, 0, 0.77778], 8782: [0.06062, 0.54986, 0, 0, 0.77778], 8783: [0.06062, 0.54986, 0, 0, 0.77778], 8785: [0.08198, 0.58198, 0, 0, 0.77778], 8786: [0.08198, 0.58198, 0, 0, 0.77778], 8787: [0.08198, 0.58198, 0, 0, 0.77778], 8790: [0, 0.69224, 0, 0, 0.77778], 8791: [0.22958, 0.72958, 0, 0, 0.77778], 8796: [0.08198, 0.91667, 0, 0, 0.77778], 8806: [0.25583, 0.75583, 0, 0, 0.77778], 8807: [0.25583, 0.75583, 0, 0, 0.77778], 8808: [0.25142, 0.75726, 0, 0, 0.77778], 8809: [0.25142, 0.75726, 0, 0, 0.77778], 8812: [0.25583, 0.75583, 0, 0, 0.5], 8814: [0.20576, 0.70576, 0, 0, 0.77778], 8815: [0.20576, 0.70576, 0, 0, 0.77778], 8816: [0.30274, 0.79383, 0, 0, 0.77778], 8817: [0.30274, 0.79383, 0, 0, 0.77778], 8818: [0.22958, 0.72958, 0, 0, 0.77778], 8819: [0.22958, 0.72958, 0, 0, 0.77778], 8822: [0.1808, 0.675, 0, 0, 0.77778], 8823: [0.1808, 0.675, 0, 0, 0.77778], 8828: [0.13667, 0.63667, 0, 0, 0.77778], 8829: [0.13667, 0.63667, 0, 0, 0.77778], 8830: [0.22958, 0.72958, 0, 0, 0.77778], 8831: [0.22958, 0.72958, 0, 0, 0.77778], 8832: [0.20576, 0.70576, 0, 0, 0.77778], 8833: [0.20576, 0.70576, 0, 0, 0.77778], 8840: [0.30274, 0.79383, 0, 0, 0.77778], 8841: [0.30274, 0.79383, 0, 0, 0.77778], 8842: [0.13597, 0.63597, 0, 0, 0.77778], 8843: [0.13597, 0.63597, 0, 0, 0.77778], 8847: [0.03517, 0.54986, 0, 0, 0.77778], 8848: [0.03517, 0.54986, 0, 0, 0.77778], 8858: [0.08198, 0.58198, 0, 0, 0.77778], 8859: [0.08198, 0.58198, 0, 0, 0.77778], 8861: [0.08198, 0.58198, 0, 0, 0.77778], 8862: [0, 0.675, 0, 0, 0.77778], 8863: [0, 0.675, 0, 0, 0.77778], 8864: [0, 0.675, 0, 0, 0.77778], 8865: [0, 0.675, 0, 0, 0.77778], 8872: [0, 0.69224, 0, 0, 0.61111], 8873: [0, 0.69224, 0, 0, 0.72222], 8874: [0, 0.69224, 0, 0, 0.88889], 8876: [0, 0.68889, 0, 0, 0.61111], 8877: [0, 0.68889, 0, 0, 0.61111], 8878: [0, 0.68889, 0, 0, 0.72222], 8879: [0, 0.68889, 0, 0, 0.72222], 8882: [0.03517, 0.54986, 0, 0, 0.77778], 8883: [0.03517, 0.54986, 0, 0, 0.77778], 8884: [0.13667, 0.63667, 0, 0, 0.77778], 8885: [0.13667, 0.63667, 0, 0, 0.77778], 8888: [0, 0.54986, 0, 0, 1.11111], 8890: [0.19444, 0.43056, 0, 0, 0.55556], 8891: [0.19444, 0.69224, 0, 0, 0.61111], 8892: [0.19444, 0.69224, 0, 0, 0.61111], 8901: [0, 0.54986, 0, 0, 0.27778], 8903: [0.08167, 0.58167, 0, 0, 0.77778], 8905: [0.08167, 0.58167, 0, 0, 0.77778], 8906: [0.08167, 0.58167, 0, 0, 0.77778], 8907: [0, 0.69224, 0, 0, 0.77778], 8908: [0, 0.69224, 0, 0, 0.77778], 8909: [-0.03598, 0.46402, 0, 0, 0.77778], 8910: [0, 0.54986, 0, 0, 0.76042], 8911: [0, 0.54986, 0, 0, 0.76042], 8912: [0.03517, 0.54986, 0, 0, 0.77778], 8913: [0.03517, 0.54986, 0, 0, 0.77778], 8914: [0, 0.54986, 0, 0, 0.66667], 8915: [0, 0.54986, 0, 0, 0.66667], 8916: [0, 0.69224, 0, 0, 0.66667], 8918: [0.0391, 0.5391, 0, 0, 0.77778], 8919: [0.0391, 0.5391, 0, 0, 0.77778], 8920: [0.03517, 0.54986, 0, 0, 1.33334], 8921: [0.03517, 0.54986, 0, 0, 1.33334], 8922: [0.38569, 0.88569, 0, 0, 0.77778], 8923: [0.38569, 0.88569, 0, 0, 0.77778], 8926: [0.13667, 0.63667, 0, 0, 0.77778], 8927: [0.13667, 0.63667, 0, 0, 0.77778], 8928: [0.30274, 0.79383, 0, 0, 0.77778], 8929: [0.30274, 0.79383, 0, 0, 0.77778], 8934: [0.23222, 0.74111, 0, 0, 0.77778], 8935: [0.23222, 0.74111, 0, 0, 0.77778], 8936: [0.23222, 0.74111, 0, 0, 0.77778], 8937: [0.23222, 0.74111, 0, 0, 0.77778], 8938: [0.20576, 0.70576, 0, 0, 0.77778], 8939: [0.20576, 0.70576, 0, 0, 0.77778], 8940: [0.30274, 0.79383, 0, 0, 0.77778], 8941: [0.30274, 0.79383, 0, 0, 0.77778], 8994: [0.19444, 0.69224, 0, 0, 0.77778], 8995: [0.19444, 0.69224, 0, 0, 0.77778], 9416: [0.15559, 0.69224, 0, 0, 0.90222], 9484: [0, 0.69224, 0, 0, 0.5], 9488: [0, 0.69224, 0, 0, 0.5], 9492: [0, 0.37788, 0, 0, 0.5], 9496: [0, 0.37788, 0, 0, 0.5], 9585: [0.19444, 0.68889, 0, 0, 0.88889], 9586: [0.19444, 0.74111, 0, 0, 0.88889], 9632: [0, 0.675, 0, 0, 0.77778], 9633: [0, 0.675, 0, 0, 0.77778], 9650: [0, 0.54986, 0, 0, 0.72222], 9651: [0, 0.54986, 0, 0, 0.72222], 9654: [0.03517, 0.54986, 0, 0, 0.77778], 9660: [0, 0.54986, 0, 0, 0.72222], 9661: [0, 0.54986, 0, 0, 0.72222], 9664: [0.03517, 0.54986, 0, 0, 0.77778], 9674: [0.11111, 0.69224, 0, 0, 0.66667], 9733: [0.19444, 0.69224, 0, 0, 0.94445], 10003: [0, 0.69224, 0, 0, 0.83334], 10016: [0, 0.69224, 0, 0, 0.83334], 10731: [0.11111, 0.69224, 0, 0, 0.66667], 10846: [0.19444, 0.75583, 0, 0, 0.61111], 10877: [0.13667, 0.63667, 0, 0, 0.77778], 10878: [0.13667, 0.63667, 0, 0, 0.77778], 10885: [0.25583, 0.75583, 0, 0, 0.77778], 10886: [0.25583, 0.75583, 0, 0, 0.77778], 10887: [0.13597, 0.63597, 0, 0, 0.77778], 10888: [0.13597, 0.63597, 0, 0, 0.77778], 10889: [0.26167, 0.75726, 0, 0, 0.77778], 10890: [0.26167, 0.75726, 0, 0, 0.77778], 10891: [0.48256, 0.98256, 0, 0, 0.77778], 10892: [0.48256, 0.98256, 0, 0, 0.77778], 10901: [0.13667, 0.63667, 0, 0, 0.77778], 10902: [0.13667, 0.63667, 0, 0, 0.77778], 10933: [0.25142, 0.75726, 0, 0, 0.77778], 10934: [0.25142, 0.75726, 0, 0, 0.77778], 10935: [0.26167, 0.75726, 0, 0, 0.77778], 10936: [0.26167, 0.75726, 0, 0, 0.77778], 10937: [0.26167, 0.75726, 0, 0, 0.77778], 10938: [0.26167, 0.75726, 0, 0, 0.77778], 10949: [0.25583, 0.75583, 0, 0, 0.77778], 10950: [0.25583, 0.75583, 0, 0, 0.77778], 10955: [0.28481, 0.79383, 0, 0, 0.77778], 10956: [0.28481, 0.79383, 0, 0, 0.77778], 57350: [0.08167, 0.58167, 0, 0, 0.22222], 57351: [0.08167, 0.58167, 0, 0, 0.38889], 57352: [0.08167, 0.58167, 0, 0, 0.77778], 57353: [0, 0.43056, 0.04028, 0, 0.66667], 57356: [0.25142, 0.75726, 0, 0, 0.77778], 57357: [0.25142, 0.75726, 0, 0, 0.77778], 57358: [0.41951, 0.91951, 0, 0, 0.77778], 57359: [0.30274, 0.79383, 0, 0, 0.77778], 57360: [0.30274, 0.79383, 0, 0, 0.77778], 57361: [0.41951, 0.91951, 0, 0, 0.77778], 57366: [0.25142, 0.75726, 0, 0, 0.77778], 57367: [0.25142, 0.75726, 0, 0, 0.77778], 57368: [0.25142, 0.75726, 0, 0, 0.77778], 57369: [0.25142, 0.75726, 0, 0, 0.77778], 57370: [0.13597, 0.63597, 0, 0, 0.77778], 57371: [0.13597, 0.63597, 0, 0, 0.77778] }, "Caligraphic-Regular": { 32: [0, 0, 0, 0, 0.25], 65: [0, 0.68333, 0, 0.19445, 0.79847], 66: [0, 0.68333, 0.03041, 0.13889, 0.65681], 67: [0, 0.68333, 0.05834, 0.13889, 0.52653], 68: [0, 0.68333, 0.02778, 0.08334, 0.77139], 69: [0, 0.68333, 0.08944, 0.11111, 0.52778], 70: [0, 0.68333, 0.09931, 0.11111, 0.71875], 71: [0.09722, 0.68333, 0.0593, 0.11111, 0.59487], 72: [0, 0.68333, 965e-5, 0.11111, 0.84452], 73: [0, 0.68333, 0.07382, 0, 0.54452], 74: [0.09722, 0.68333, 0.18472, 0.16667, 0.67778], 75: [0, 0.68333, 0.01445, 0.05556, 0.76195], 76: [0, 0.68333, 0, 0.13889, 0.68972], 77: [0, 0.68333, 0, 0.13889, 1.2009], 78: [0, 0.68333, 0.14736, 0.08334, 0.82049], 79: [0, 0.68333, 0.02778, 0.11111, 0.79611], 80: [0, 0.68333, 0.08222, 0.08334, 0.69556], 81: [0.09722, 0.68333, 0, 0.11111, 0.81667], 82: [0, 0.68333, 0, 0.08334, 0.8475], 83: [0, 0.68333, 0.075, 0.13889, 0.60556], 84: [0, 0.68333, 0.25417, 0, 0.54464], 85: [0, 0.68333, 0.09931, 0.08334, 0.62583], 86: [0, 0.68333, 0.08222, 0, 0.61278], 87: [0, 0.68333, 0.08222, 0.08334, 0.98778], 88: [0, 0.68333, 0.14643, 0.13889, 0.7133], 89: [0.09722, 0.68333, 0.08222, 0.08334, 0.66834], 90: [0, 0.68333, 0.07944, 0.13889, 0.72473], 160: [0, 0, 0, 0, 0.25] }, "Fraktur-Regular": { 32: [0, 0, 0, 0, 0.25], 33: [0, 0.69141, 0, 0, 0.29574], 34: [0, 0.69141, 0, 0, 0.21471], 38: [0, 0.69141, 0, 0, 0.73786], 39: [0, 0.69141, 0, 0, 0.21201], 40: [0.24982, 0.74947, 0, 0, 0.38865], 41: [0.24982, 0.74947, 0, 0, 0.38865], 42: [0, 0.62119, 0, 0, 0.27764], 43: [0.08319, 0.58283, 0, 0, 0.75623], 44: [0, 0.10803, 0, 0, 0.27764], 45: [0.08319, 0.58283, 0, 0, 0.75623], 46: [0, 0.10803, 0, 0, 0.27764], 47: [0.24982, 0.74947, 0, 0, 0.50181], 48: [0, 0.47534, 0, 0, 0.50181], 49: [0, 0.47534, 0, 0, 0.50181], 50: [0, 0.47534, 0, 0, 0.50181], 51: [0.18906, 0.47534, 0, 0, 0.50181], 52: [0.18906, 0.47534, 0, 0, 0.50181], 53: [0.18906, 0.47534, 0, 0, 0.50181], 54: [0, 0.69141, 0, 0, 0.50181], 55: [0.18906, 0.47534, 0, 0, 0.50181], 56: [0, 0.69141, 0, 0, 0.50181], 57: [0.18906, 0.47534, 0, 0, 0.50181], 58: [0, 0.47534, 0, 0, 0.21606], 59: [0.12604, 0.47534, 0, 0, 0.21606], 61: [-0.13099, 0.36866, 0, 0, 0.75623], 63: [0, 0.69141, 0, 0, 0.36245], 65: [0, 0.69141, 0, 0, 0.7176], 66: [0, 0.69141, 0, 0, 0.88397], 67: [0, 0.69141, 0, 0, 0.61254], 68: [0, 0.69141, 0, 0, 0.83158], 69: [0, 0.69141, 0, 0, 0.66278], 70: [0.12604, 0.69141, 0, 0, 0.61119], 71: [0, 0.69141, 0, 0, 0.78539], 72: [0.06302, 0.69141, 0, 0, 0.7203], 73: [0, 0.69141, 0, 0, 0.55448], 74: [0.12604, 0.69141, 0, 0, 0.55231], 75: [0, 0.69141, 0, 0, 0.66845], 76: [0, 0.69141, 0, 0, 0.66602], 77: [0, 0.69141, 0, 0, 1.04953], 78: [0, 0.69141, 0, 0, 0.83212], 79: [0, 0.69141, 0, 0, 0.82699], 80: [0.18906, 0.69141, 0, 0, 0.82753], 81: [0.03781, 0.69141, 0, 0, 0.82699], 82: [0, 0.69141, 0, 0, 0.82807], 83: [0, 0.69141, 0, 0, 0.82861], 84: [0, 0.69141, 0, 0, 0.66899], 85: [0, 0.69141, 0, 0, 0.64576], 86: [0, 0.69141, 0, 0, 0.83131], 87: [0, 0.69141, 0, 0, 1.04602], 88: [0, 0.69141, 0, 0, 0.71922], 89: [0.18906, 0.69141, 0, 0, 0.83293], 90: [0.12604, 0.69141, 0, 0, 0.60201], 91: [0.24982, 0.74947, 0, 0, 0.27764], 93: [0.24982, 0.74947, 0, 0, 0.27764], 94: [0, 0.69141, 0, 0, 0.49965], 97: [0, 0.47534, 0, 0, 0.50046], 98: [0, 0.69141, 0, 0, 0.51315], 99: [0, 0.47534, 0, 0, 0.38946], 100: [0, 0.62119, 0, 0, 0.49857], 101: [0, 0.47534, 0, 0, 0.40053], 102: [0.18906, 0.69141, 0, 0, 0.32626], 103: [0.18906, 0.47534, 0, 0, 0.5037], 104: [0.18906, 0.69141, 0, 0, 0.52126], 105: [0, 0.69141, 0, 0, 0.27899], 106: [0, 0.69141, 0, 0, 0.28088], 107: [0, 0.69141, 0, 0, 0.38946], 108: [0, 0.69141, 0, 0, 0.27953], 109: [0, 0.47534, 0, 0, 0.76676], 110: [0, 0.47534, 0, 0, 0.52666], 111: [0, 0.47534, 0, 0, 0.48885], 112: [0.18906, 0.52396, 0, 0, 0.50046], 113: [0.18906, 0.47534, 0, 0, 0.48912], 114: [0, 0.47534, 0, 0, 0.38919], 115: [0, 0.47534, 0, 0, 0.44266], 116: [0, 0.62119, 0, 0, 0.33301], 117: [0, 0.47534, 0, 0, 0.5172], 118: [0, 0.52396, 0, 0, 0.5118], 119: [0, 0.52396, 0, 0, 0.77351], 120: [0.18906, 0.47534, 0, 0, 0.38865], 121: [0.18906, 0.47534, 0, 0, 0.49884], 122: [0.18906, 0.47534, 0, 0, 0.39054], 160: [0, 0, 0, 0, 0.25], 8216: [0, 0.69141, 0, 0, 0.21471], 8217: [0, 0.69141, 0, 0, 0.21471], 58112: [0, 0.62119, 0, 0, 0.49749], 58113: [0, 0.62119, 0, 0, 0.4983], 58114: [0.18906, 0.69141, 0, 0, 0.33328], 58115: [0.18906, 0.69141, 0, 0, 0.32923], 58116: [0.18906, 0.47534, 0, 0, 0.50343], 58117: [0, 0.69141, 0, 0, 0.33301], 58118: [0, 0.62119, 0, 0, 0.33409], 58119: [0, 0.47534, 0, 0, 0.50073] }, "Main-Bold": { 32: [0, 0, 0, 0, 0.25], 33: [0, 0.69444, 0, 0, 0.35], 34: [0, 0.69444, 0, 0, 0.60278], 35: [0.19444, 0.69444, 0, 0, 0.95833], 36: [0.05556, 0.75, 0, 0, 0.575], 37: [0.05556, 0.75, 0, 0, 0.95833], 38: [0, 0.69444, 0, 0, 0.89444], 39: [0, 0.69444, 0, 0, 0.31944], 40: [0.25, 0.75, 0, 0, 0.44722], 41: [0.25, 0.75, 0, 0, 0.44722], 42: [0, 0.75, 0, 0, 0.575], 43: [0.13333, 0.63333, 0, 0, 0.89444], 44: [0.19444, 0.15556, 0, 0, 0.31944], 45: [0, 0.44444, 0, 0, 0.38333], 46: [0, 0.15556, 0, 0, 0.31944], 47: [0.25, 0.75, 0, 0, 0.575], 48: [0, 0.64444, 0, 0, 0.575], 49: [0, 0.64444, 0, 0, 0.575], 50: [0, 0.64444, 0, 0, 0.575], 51: [0, 0.64444, 0, 0, 0.575], 52: [0, 0.64444, 0, 0, 0.575], 53: [0, 0.64444, 0, 0, 0.575], 54: [0, 0.64444, 0, 0, 0.575], 55: [0, 0.64444, 0, 0, 0.575], 56: [0, 0.64444, 0, 0, 0.575], 57: [0, 0.64444, 0, 0, 0.575], 58: [0, 0.44444, 0, 0, 0.31944], 59: [0.19444, 0.44444, 0, 0, 0.31944], 60: [0.08556, 0.58556, 0, 0, 0.89444], 61: [-0.10889, 0.39111, 0, 0, 0.89444], 62: [0.08556, 0.58556, 0, 0, 0.89444], 63: [0, 0.69444, 0, 0, 0.54305], 64: [0, 0.69444, 0, 0, 0.89444], 65: [0, 0.68611, 0, 0, 0.86944], 66: [0, 0.68611, 0, 0, 0.81805], 67: [0, 0.68611, 0, 0, 0.83055], 68: [0, 0.68611, 0, 0, 0.88194], 69: [0, 0.68611, 0, 0, 0.75555], 70: [0, 0.68611, 0, 0, 0.72361], 71: [0, 0.68611, 0, 0, 0.90416], 72: [0, 0.68611, 0, 0, 0.9], 73: [0, 0.68611, 0, 0, 0.43611], 74: [0, 0.68611, 0, 0, 0.59444], 75: [0, 0.68611, 0, 0, 0.90138], 76: [0, 0.68611, 0, 0, 0.69166], 77: [0, 0.68611, 0, 0, 1.09166], 78: [0, 0.68611, 0, 0, 0.9], 79: [0, 0.68611, 0, 0, 0.86388], 80: [0, 0.68611, 0, 0, 0.78611], 81: [0.19444, 0.68611, 0, 0, 0.86388], 82: [0, 0.68611, 0, 0, 0.8625], 83: [0, 0.68611, 0, 0, 0.63889], 84: [0, 0.68611, 0, 0, 0.8], 85: [0, 0.68611, 0, 0, 0.88472], 86: [0, 0.68611, 0.01597, 0, 0.86944], 87: [0, 0.68611, 0.01597, 0, 1.18888], 88: [0, 0.68611, 0, 0, 0.86944], 89: [0, 0.68611, 0.02875, 0, 0.86944], 90: [0, 0.68611, 0, 0, 0.70277], 91: [0.25, 0.75, 0, 0, 0.31944], 92: [0.25, 0.75, 0, 0, 0.575], 93: [0.25, 0.75, 0, 0, 0.31944], 94: [0, 0.69444, 0, 0, 0.575], 95: [0.31, 0.13444, 0.03194, 0, 0.575], 97: [0, 0.44444, 0, 0, 0.55902], 98: [0, 0.69444, 0, 0, 0.63889], 99: [0, 0.44444, 0, 0, 0.51111], 100: [0, 0.69444, 0, 0, 0.63889], 101: [0, 0.44444, 0, 0, 0.52708], 102: [0, 0.69444, 0.10903, 0, 0.35139], 103: [0.19444, 0.44444, 0.01597, 0, 0.575], 104: [0, 0.69444, 0, 0, 0.63889], 105: [0, 0.69444, 0, 0, 0.31944], 106: [0.19444, 0.69444, 0, 0, 0.35139], 107: [0, 0.69444, 0, 0, 0.60694], 108: [0, 0.69444, 0, 0, 0.31944], 109: [0, 0.44444, 0, 0, 0.95833], 110: [0, 0.44444, 0, 0, 0.63889], 111: [0, 0.44444, 0, 0, 0.575], 112: [0.19444, 0.44444, 0, 0, 0.63889], 113: [0.19444, 0.44444, 0, 0, 0.60694], 114: [0, 0.44444, 0, 0, 0.47361], 115: [0, 0.44444, 0, 0, 0.45361], 116: [0, 0.63492, 0, 0, 0.44722], 117: [0, 0.44444, 0, 0, 0.63889], 118: [0, 0.44444, 0.01597, 0, 0.60694], 119: [0, 0.44444, 0.01597, 0, 0.83055], 120: [0, 0.44444, 0, 0, 0.60694], 121: [0.19444, 0.44444, 0.01597, 0, 0.60694], 122: [0, 0.44444, 0, 0, 0.51111], 123: [0.25, 0.75, 0, 0, 0.575], 124: [0.25, 0.75, 0, 0, 0.31944], 125: [0.25, 0.75, 0, 0, 0.575], 126: [0.35, 0.34444, 0, 0, 0.575], 160: [0, 0, 0, 0, 0.25], 163: [0, 0.69444, 0, 0, 0.86853], 168: [0, 0.69444, 0, 0, 0.575], 172: [0, 0.44444, 0, 0, 0.76666], 176: [0, 0.69444, 0, 0, 0.86944], 177: [0.13333, 0.63333, 0, 0, 0.89444], 184: [0.17014, 0, 0, 0, 0.51111], 198: [0, 0.68611, 0, 0, 1.04166], 215: [0.13333, 0.63333, 0, 0, 0.89444], 216: [0.04861, 0.73472, 0, 0, 0.89444], 223: [0, 0.69444, 0, 0, 0.59722], 230: [0, 0.44444, 0, 0, 0.83055], 247: [0.13333, 0.63333, 0, 0, 0.89444], 248: [0.09722, 0.54167, 0, 0, 0.575], 305: [0, 0.44444, 0, 0, 0.31944], 338: [0, 0.68611, 0, 0, 1.16944], 339: [0, 0.44444, 0, 0, 0.89444], 567: [0.19444, 0.44444, 0, 0, 0.35139], 710: [0, 0.69444, 0, 0, 0.575], 711: [0, 0.63194, 0, 0, 0.575], 713: [0, 0.59611, 0, 0, 0.575], 714: [0, 0.69444, 0, 0, 0.575], 715: [0, 0.69444, 0, 0, 0.575], 728: [0, 0.69444, 0, 0, 0.575], 729: [0, 0.69444, 0, 0, 0.31944], 730: [0, 0.69444, 0, 0, 0.86944], 732: [0, 0.69444, 0, 0, 0.575], 733: [0, 0.69444, 0, 0, 0.575], 915: [0, 0.68611, 0, 0, 0.69166], 916: [0, 0.68611, 0, 0, 0.95833], 920: [0, 0.68611, 0, 0, 0.89444], 923: [0, 0.68611, 0, 0, 0.80555], 926: [0, 0.68611, 0, 0, 0.76666], 928: [0, 0.68611, 0, 0, 0.9], 931: [0, 0.68611, 0, 0, 0.83055], 933: [0, 0.68611, 0, 0, 0.89444], 934: [0, 0.68611, 0, 0, 0.83055], 936: [0, 0.68611, 0, 0, 0.89444], 937: [0, 0.68611, 0, 0, 0.83055], 8211: [0, 0.44444, 0.03194, 0, 0.575], 8212: [0, 0.44444, 0.03194, 0, 1.14999], 8216: [0, 0.69444, 0, 0, 0.31944], 8217: [0, 0.69444, 0, 0, 0.31944], 8220: [0, 0.69444, 0, 0, 0.60278], 8221: [0, 0.69444, 0, 0, 0.60278], 8224: [0.19444, 0.69444, 0, 0, 0.51111], 8225: [0.19444, 0.69444, 0, 0, 0.51111], 8242: [0, 0.55556, 0, 0, 0.34444], 8407: [0, 0.72444, 0.15486, 0, 0.575], 8463: [0, 0.69444, 0, 0, 0.66759], 8465: [0, 0.69444, 0, 0, 0.83055], 8467: [0, 0.69444, 0, 0, 0.47361], 8472: [0.19444, 0.44444, 0, 0, 0.74027], 8476: [0, 0.69444, 0, 0, 0.83055], 8501: [0, 0.69444, 0, 0, 0.70277], 8592: [-0.10889, 0.39111, 0, 0, 1.14999], 8593: [0.19444, 0.69444, 0, 0, 0.575], 8594: [-0.10889, 0.39111, 0, 0, 1.14999], 8595: [0.19444, 0.69444, 0, 0, 0.575], 8596: [-0.10889, 0.39111, 0, 0, 1.14999], 8597: [0.25, 0.75, 0, 0, 0.575], 8598: [0.19444, 0.69444, 0, 0, 1.14999], 8599: [0.19444, 0.69444, 0, 0, 1.14999], 8600: [0.19444, 0.69444, 0, 0, 1.14999], 8601: [0.19444, 0.69444, 0, 0, 1.14999], 8636: [-0.10889, 0.39111, 0, 0, 1.14999], 8637: [-0.10889, 0.39111, 0, 0, 1.14999], 8640: [-0.10889, 0.39111, 0, 0, 1.14999], 8641: [-0.10889, 0.39111, 0, 0, 1.14999], 8656: [-0.10889, 0.39111, 0, 0, 1.14999], 8657: [0.19444, 0.69444, 0, 0, 0.70277], 8658: [-0.10889, 0.39111, 0, 0, 1.14999], 8659: [0.19444, 0.69444, 0, 0, 0.70277], 8660: [-0.10889, 0.39111, 0, 0, 1.14999], 8661: [0.25, 0.75, 0, 0, 0.70277], 8704: [0, 0.69444, 0, 0, 0.63889], 8706: [0, 0.69444, 0.06389, 0, 0.62847], 8707: [0, 0.69444, 0, 0, 0.63889], 8709: [0.05556, 0.75, 0, 0, 0.575], 8711: [0, 0.68611, 0, 0, 0.95833], 8712: [0.08556, 0.58556, 0, 0, 0.76666], 8715: [0.08556, 0.58556, 0, 0, 0.76666], 8722: [0.13333, 0.63333, 0, 0, 0.89444], 8723: [0.13333, 0.63333, 0, 0, 0.89444], 8725: [0.25, 0.75, 0, 0, 0.575], 8726: [0.25, 0.75, 0, 0, 0.575], 8727: [-0.02778, 0.47222, 0, 0, 0.575], 8728: [-0.02639, 0.47361, 0, 0, 0.575], 8729: [-0.02639, 0.47361, 0, 0, 0.575], 8730: [0.18, 0.82, 0, 0, 0.95833], 8733: [0, 0.44444, 0, 0, 0.89444], 8734: [0, 0.44444, 0, 0, 1.14999], 8736: [0, 0.69224, 0, 0, 0.72222], 8739: [0.25, 0.75, 0, 0, 0.31944], 8741: [0.25, 0.75, 0, 0, 0.575], 8743: [0, 0.55556, 0, 0, 0.76666], 8744: [0, 0.55556, 0, 0, 0.76666], 8745: [0, 0.55556, 0, 0, 0.76666], 8746: [0, 0.55556, 0, 0, 0.76666], 8747: [0.19444, 0.69444, 0.12778, 0, 0.56875], 8764: [-0.10889, 0.39111, 0, 0, 0.89444], 8768: [0.19444, 0.69444, 0, 0, 0.31944], 8771: [222e-5, 0.50222, 0, 0, 0.89444], 8773: [0.027, 0.638, 0, 0, 0.894], 8776: [0.02444, 0.52444, 0, 0, 0.89444], 8781: [222e-5, 0.50222, 0, 0, 0.89444], 8801: [222e-5, 0.50222, 0, 0, 0.89444], 8804: [0.19667, 0.69667, 0, 0, 0.89444], 8805: [0.19667, 0.69667, 0, 0, 0.89444], 8810: [0.08556, 0.58556, 0, 0, 1.14999], 8811: [0.08556, 0.58556, 0, 0, 1.14999], 8826: [0.08556, 0.58556, 0, 0, 0.89444], 8827: [0.08556, 0.58556, 0, 0, 0.89444], 8834: [0.08556, 0.58556, 0, 0, 0.89444], 8835: [0.08556, 0.58556, 0, 0, 0.89444], 8838: [0.19667, 0.69667, 0, 0, 0.89444], 8839: [0.19667, 0.69667, 0, 0, 0.89444], 8846: [0, 0.55556, 0, 0, 0.76666], 8849: [0.19667, 0.69667, 0, 0, 0.89444], 8850: [0.19667, 0.69667, 0, 0, 0.89444], 8851: [0, 0.55556, 0, 0, 0.76666], 8852: [0, 0.55556, 0, 0, 0.76666], 8853: [0.13333, 0.63333, 0, 0, 0.89444], 8854: [0.13333, 0.63333, 0, 0, 0.89444], 8855: [0.13333, 0.63333, 0, 0, 0.89444], 8856: [0.13333, 0.63333, 0, 0, 0.89444], 8857: [0.13333, 0.63333, 0, 0, 0.89444], 8866: [0, 0.69444, 0, 0, 0.70277], 8867: [0, 0.69444, 0, 0, 0.70277], 8868: [0, 0.69444, 0, 0, 0.89444], 8869: [0, 0.69444, 0, 0, 0.89444], 8900: [-0.02639, 0.47361, 0, 0, 0.575], 8901: [-0.02639, 0.47361, 0, 0, 0.31944], 8902: [-0.02778, 0.47222, 0, 0, 0.575], 8968: [0.25, 0.75, 0, 0, 0.51111], 8969: [0.25, 0.75, 0, 0, 0.51111], 8970: [0.25, 0.75, 0, 0, 0.51111], 8971: [0.25, 0.75, 0, 0, 0.51111], 8994: [-0.13889, 0.36111, 0, 0, 1.14999], 8995: [-0.13889, 0.36111, 0, 0, 1.14999], 9651: [0.19444, 0.69444, 0, 0, 1.02222], 9657: [-0.02778, 0.47222, 0, 0, 0.575], 9661: [0.19444, 0.69444, 0, 0, 1.02222], 9667: [-0.02778, 0.47222, 0, 0, 0.575], 9711: [0.19444, 0.69444, 0, 0, 1.14999], 9824: [0.12963, 0.69444, 0, 0, 0.89444], 9825: [0.12963, 0.69444, 0, 0, 0.89444], 9826: [0.12963, 0.69444, 0, 0, 0.89444], 9827: [0.12963, 0.69444, 0, 0, 0.89444], 9837: [0, 0.75, 0, 0, 0.44722], 9838: [0.19444, 0.69444, 0, 0, 0.44722], 9839: [0.19444, 0.69444, 0, 0, 0.44722], 10216: [0.25, 0.75, 0, 0, 0.44722], 10217: [0.25, 0.75, 0, 0, 0.44722], 10815: [0, 0.68611, 0, 0, 0.9], 10927: [0.19667, 0.69667, 0, 0, 0.89444], 10928: [0.19667, 0.69667, 0, 0, 0.89444], 57376: [0.19444, 0.69444, 0, 0, 0] }, "Main-BoldItalic": { 32: [0, 0, 0, 0, 0.25], 33: [0, 0.69444, 0.11417, 0, 0.38611], 34: [0, 0.69444, 0.07939, 0, 0.62055], 35: [0.19444, 0.69444, 0.06833, 0, 0.94444], 37: [0.05556, 0.75, 0.12861, 0, 0.94444], 38: [0, 0.69444, 0.08528, 0, 0.88555], 39: [0, 0.69444, 0.12945, 0, 0.35555], 40: [0.25, 0.75, 0.15806, 0, 0.47333], 41: [0.25, 0.75, 0.03306, 0, 0.47333], 42: [0, 0.75, 0.14333, 0, 0.59111], 43: [0.10333, 0.60333, 0.03306, 0, 0.88555], 44: [0.19444, 0.14722, 0, 0, 0.35555], 45: [0, 0.44444, 0.02611, 0, 0.41444], 46: [0, 0.14722, 0, 0, 0.35555], 47: [0.25, 0.75, 0.15806, 0, 0.59111], 48: [0, 0.64444, 0.13167, 0, 0.59111], 49: [0, 0.64444, 0.13167, 0, 0.59111], 50: [0, 0.64444, 0.13167, 0, 0.59111], 51: [0, 0.64444, 0.13167, 0, 0.59111], 52: [0.19444, 0.64444, 0.13167, 0, 0.59111], 53: [0, 0.64444, 0.13167, 0, 0.59111], 54: [0, 0.64444, 0.13167, 0, 0.59111], 55: [0.19444, 0.64444, 0.13167, 0, 0.59111], 56: [0, 0.64444, 0.13167, 0, 0.59111], 57: [0, 0.64444, 0.13167, 0, 0.59111], 58: [0, 0.44444, 0.06695, 0, 0.35555], 59: [0.19444, 0.44444, 0.06695, 0, 0.35555], 61: [-0.10889, 0.39111, 0.06833, 0, 0.88555], 63: [0, 0.69444, 0.11472, 0, 0.59111], 64: [0, 0.69444, 0.09208, 0, 0.88555], 65: [0, 0.68611, 0, 0, 0.86555], 66: [0, 0.68611, 0.0992, 0, 0.81666], 67: [0, 0.68611, 0.14208, 0, 0.82666], 68: [0, 0.68611, 0.09062, 0, 0.87555], 69: [0, 0.68611, 0.11431, 0, 0.75666], 70: [0, 0.68611, 0.12903, 0, 0.72722], 71: [0, 0.68611, 0.07347, 0, 0.89527], 72: [0, 0.68611, 0.17208, 0, 0.8961], 73: [0, 0.68611, 0.15681, 0, 0.47166], 74: [0, 0.68611, 0.145, 0, 0.61055], 75: [0, 0.68611, 0.14208, 0, 0.89499], 76: [0, 0.68611, 0, 0, 0.69777], 77: [0, 0.68611, 0.17208, 0, 1.07277], 78: [0, 0.68611, 0.17208, 0, 0.8961], 79: [0, 0.68611, 0.09062, 0, 0.85499], 80: [0, 0.68611, 0.0992, 0, 0.78721], 81: [0.19444, 0.68611, 0.09062, 0, 0.85499], 82: [0, 0.68611, 0.02559, 0, 0.85944], 83: [0, 0.68611, 0.11264, 0, 0.64999], 84: [0, 0.68611, 0.12903, 0, 0.7961], 85: [0, 0.68611, 0.17208, 0, 0.88083], 86: [0, 0.68611, 0.18625, 0, 0.86555], 87: [0, 0.68611, 0.18625, 0, 1.15999], 88: [0, 0.68611, 0.15681, 0, 0.86555], 89: [0, 0.68611, 0.19803, 0, 0.86555], 90: [0, 0.68611, 0.14208, 0, 0.70888], 91: [0.25, 0.75, 0.1875, 0, 0.35611], 93: [0.25, 0.75, 0.09972, 0, 0.35611], 94: [0, 0.69444, 0.06709, 0, 0.59111], 95: [0.31, 0.13444, 0.09811, 0, 0.59111], 97: [0, 0.44444, 0.09426, 0, 0.59111], 98: [0, 0.69444, 0.07861, 0, 0.53222], 99: [0, 0.44444, 0.05222, 0, 0.53222], 100: [0, 0.69444, 0.10861, 0, 0.59111], 101: [0, 0.44444, 0.085, 0, 0.53222], 102: [0.19444, 0.69444, 0.21778, 0, 0.4], 103: [0.19444, 0.44444, 0.105, 0, 0.53222], 104: [0, 0.69444, 0.09426, 0, 0.59111], 105: [0, 0.69326, 0.11387, 0, 0.35555], 106: [0.19444, 0.69326, 0.1672, 0, 0.35555], 107: [0, 0.69444, 0.11111, 0, 0.53222], 108: [0, 0.69444, 0.10861, 0, 0.29666], 109: [0, 0.44444, 0.09426, 0, 0.94444], 110: [0, 0.44444, 0.09426, 0, 0.64999], 111: [0, 0.44444, 0.07861, 0, 0.59111], 112: [0.19444, 0.44444, 0.07861, 0, 0.59111], 113: [0.19444, 0.44444, 0.105, 0, 0.53222], 114: [0, 0.44444, 0.11111, 0, 0.50167], 115: [0, 0.44444, 0.08167, 0, 0.48694], 116: [0, 0.63492, 0.09639, 0, 0.385], 117: [0, 0.44444, 0.09426, 0, 0.62055], 118: [0, 0.44444, 0.11111, 0, 0.53222], 119: [0, 0.44444, 0.11111, 0, 0.76777], 120: [0, 0.44444, 0.12583, 0, 0.56055], 121: [0.19444, 0.44444, 0.105, 0, 0.56166], 122: [0, 0.44444, 0.13889, 0, 0.49055], 126: [0.35, 0.34444, 0.11472, 0, 0.59111], 160: [0, 0, 0, 0, 0.25], 168: [0, 0.69444, 0.11473, 0, 0.59111], 176: [0, 0.69444, 0, 0, 0.94888], 184: [0.17014, 0, 0, 0, 0.53222], 198: [0, 0.68611, 0.11431, 0, 1.02277], 216: [0.04861, 0.73472, 0.09062, 0, 0.88555], 223: [0.19444, 0.69444, 0.09736, 0, 0.665], 230: [0, 0.44444, 0.085, 0, 0.82666], 248: [0.09722, 0.54167, 0.09458, 0, 0.59111], 305: [0, 0.44444, 0.09426, 0, 0.35555], 338: [0, 0.68611, 0.11431, 0, 1.14054], 339: [0, 0.44444, 0.085, 0, 0.82666], 567: [0.19444, 0.44444, 0.04611, 0, 0.385], 710: [0, 0.69444, 0.06709, 0, 0.59111], 711: [0, 0.63194, 0.08271, 0, 0.59111], 713: [0, 0.59444, 0.10444, 0, 0.59111], 714: [0, 0.69444, 0.08528, 0, 0.59111], 715: [0, 0.69444, 0, 0, 0.59111], 728: [0, 0.69444, 0.10333, 0, 0.59111], 729: [0, 0.69444, 0.12945, 0, 0.35555], 730: [0, 0.69444, 0, 0, 0.94888], 732: [0, 0.69444, 0.11472, 0, 0.59111], 733: [0, 0.69444, 0.11472, 0, 0.59111], 915: [0, 0.68611, 0.12903, 0, 0.69777], 916: [0, 0.68611, 0, 0, 0.94444], 920: [0, 0.68611, 0.09062, 0, 0.88555], 923: [0, 0.68611, 0, 0, 0.80666], 926: [0, 0.68611, 0.15092, 0, 0.76777], 928: [0, 0.68611, 0.17208, 0, 0.8961], 931: [0, 0.68611, 0.11431, 0, 0.82666], 933: [0, 0.68611, 0.10778, 0, 0.88555], 934: [0, 0.68611, 0.05632, 0, 0.82666], 936: [0, 0.68611, 0.10778, 0, 0.88555], 937: [0, 0.68611, 0.0992, 0, 0.82666], 8211: [0, 0.44444, 0.09811, 0, 0.59111], 8212: [0, 0.44444, 0.09811, 0, 1.18221], 8216: [0, 0.69444, 0.12945, 0, 0.35555], 8217: [0, 0.69444, 0.12945, 0, 0.35555], 8220: [0, 0.69444, 0.16772, 0, 0.62055], 8221: [0, 0.69444, 0.07939, 0, 0.62055] }, "Main-Italic": { 32: [0, 0, 0, 0, 0.25], 33: [0, 0.69444, 0.12417, 0, 0.30667], 34: [0, 0.69444, 0.06961, 0, 0.51444], 35: [0.19444, 0.69444, 0.06616, 0, 0.81777], 37: [0.05556, 0.75, 0.13639, 0, 0.81777], 38: [0, 0.69444, 0.09694, 0, 0.76666], 39: [0, 0.69444, 0.12417, 0, 0.30667], 40: [0.25, 0.75, 0.16194, 0, 0.40889], 41: [0.25, 0.75, 0.03694, 0, 0.40889], 42: [0, 0.75, 0.14917, 0, 0.51111], 43: [0.05667, 0.56167, 0.03694, 0, 0.76666], 44: [0.19444, 0.10556, 0, 0, 0.30667], 45: [0, 0.43056, 0.02826, 0, 0.35778], 46: [0, 0.10556, 0, 0, 0.30667], 47: [0.25, 0.75, 0.16194, 0, 0.51111], 48: [0, 0.64444, 0.13556, 0, 0.51111], 49: [0, 0.64444, 0.13556, 0, 0.51111], 50: [0, 0.64444, 0.13556, 0, 0.51111], 51: [0, 0.64444, 0.13556, 0, 0.51111], 52: [0.19444, 0.64444, 0.13556, 0, 0.51111], 53: [0, 0.64444, 0.13556, 0, 0.51111], 54: [0, 0.64444, 0.13556, 0, 0.51111], 55: [0.19444, 0.64444, 0.13556, 0, 0.51111], 56: [0, 0.64444, 0.13556, 0, 0.51111], 57: [0, 0.64444, 0.13556, 0, 0.51111], 58: [0, 0.43056, 0.0582, 0, 0.30667], 59: [0.19444, 0.43056, 0.0582, 0, 0.30667], 61: [-0.13313, 0.36687, 0.06616, 0, 0.76666], 63: [0, 0.69444, 0.1225, 0, 0.51111], 64: [0, 0.69444, 0.09597, 0, 0.76666], 65: [0, 0.68333, 0, 0, 0.74333], 66: [0, 0.68333, 0.10257, 0, 0.70389], 67: [0, 0.68333, 0.14528, 0, 0.71555], 68: [0, 0.68333, 0.09403, 0, 0.755], 69: [0, 0.68333, 0.12028, 0, 0.67833], 70: [0, 0.68333, 0.13305, 0, 0.65277], 71: [0, 0.68333, 0.08722, 0, 0.77361], 72: [0, 0.68333, 0.16389, 0, 0.74333], 73: [0, 0.68333, 0.15806, 0, 0.38555], 74: [0, 0.68333, 0.14028, 0, 0.525], 75: [0, 0.68333, 0.14528, 0, 0.76888], 76: [0, 0.68333, 0, 0, 0.62722], 77: [0, 0.68333, 0.16389, 0, 0.89666], 78: [0, 0.68333, 0.16389, 0, 0.74333], 79: [0, 0.68333, 0.09403, 0, 0.76666], 80: [0, 0.68333, 0.10257, 0, 0.67833], 81: [0.19444, 0.68333, 0.09403, 0, 0.76666], 82: [0, 0.68333, 0.03868, 0, 0.72944], 83: [0, 0.68333, 0.11972, 0, 0.56222], 84: [0, 0.68333, 0.13305, 0, 0.71555], 85: [0, 0.68333, 0.16389, 0, 0.74333], 86: [0, 0.68333, 0.18361, 0, 0.74333], 87: [0, 0.68333, 0.18361, 0, 0.99888], 88: [0, 0.68333, 0.15806, 0, 0.74333], 89: [0, 0.68333, 0.19383, 0, 0.74333], 90: [0, 0.68333, 0.14528, 0, 0.61333], 91: [0.25, 0.75, 0.1875, 0, 0.30667], 93: [0.25, 0.75, 0.10528, 0, 0.30667], 94: [0, 0.69444, 0.06646, 0, 0.51111], 95: [0.31, 0.12056, 0.09208, 0, 0.51111], 97: [0, 0.43056, 0.07671, 0, 0.51111], 98: [0, 0.69444, 0.06312, 0, 0.46], 99: [0, 0.43056, 0.05653, 0, 0.46], 100: [0, 0.69444, 0.10333, 0, 0.51111], 101: [0, 0.43056, 0.07514, 0, 0.46], 102: [0.19444, 0.69444, 0.21194, 0, 0.30667], 103: [0.19444, 0.43056, 0.08847, 0, 0.46], 104: [0, 0.69444, 0.07671, 0, 0.51111], 105: [0, 0.65536, 0.1019, 0, 0.30667], 106: [0.19444, 0.65536, 0.14467, 0, 0.30667], 107: [0, 0.69444, 0.10764, 0, 0.46], 108: [0, 0.69444, 0.10333, 0, 0.25555], 109: [0, 0.43056, 0.07671, 0, 0.81777], 110: [0, 0.43056, 0.07671, 0, 0.56222], 111: [0, 0.43056, 0.06312, 0, 0.51111], 112: [0.19444, 0.43056, 0.06312, 0, 0.51111], 113: [0.19444, 0.43056, 0.08847, 0, 0.46], 114: [0, 0.43056, 0.10764, 0, 0.42166], 115: [0, 0.43056, 0.08208, 0, 0.40889], 116: [0, 0.61508, 0.09486, 0, 0.33222], 117: [0, 0.43056, 0.07671, 0, 0.53666], 118: [0, 0.43056, 0.10764, 0, 0.46], 119: [0, 0.43056, 0.10764, 0, 0.66444], 120: [0, 0.43056, 0.12042, 0, 0.46389], 121: [0.19444, 0.43056, 0.08847, 0, 0.48555], 122: [0, 0.43056, 0.12292, 0, 0.40889], 126: [0.35, 0.31786, 0.11585, 0, 0.51111], 160: [0, 0, 0, 0, 0.25], 168: [0, 0.66786, 0.10474, 0, 0.51111], 176: [0, 0.69444, 0, 0, 0.83129], 184: [0.17014, 0, 0, 0, 0.46], 198: [0, 0.68333, 0.12028, 0, 0.88277], 216: [0.04861, 0.73194, 0.09403, 0, 0.76666], 223: [0.19444, 0.69444, 0.10514, 0, 0.53666], 230: [0, 0.43056, 0.07514, 0, 0.71555], 248: [0.09722, 0.52778, 0.09194, 0, 0.51111], 338: [0, 0.68333, 0.12028, 0, 0.98499], 339: [0, 0.43056, 0.07514, 0, 0.71555], 710: [0, 0.69444, 0.06646, 0, 0.51111], 711: [0, 0.62847, 0.08295, 0, 0.51111], 713: [0, 0.56167, 0.10333, 0, 0.51111], 714: [0, 0.69444, 0.09694, 0, 0.51111], 715: [0, 0.69444, 0, 0, 0.51111], 728: [0, 0.69444, 0.10806, 0, 0.51111], 729: [0, 0.66786, 0.11752, 0, 0.30667], 730: [0, 0.69444, 0, 0, 0.83129], 732: [0, 0.66786, 0.11585, 0, 0.51111], 733: [0, 0.69444, 0.1225, 0, 0.51111], 915: [0, 0.68333, 0.13305, 0, 0.62722], 916: [0, 0.68333, 0, 0, 0.81777], 920: [0, 0.68333, 0.09403, 0, 0.76666], 923: [0, 0.68333, 0, 0, 0.69222], 926: [0, 0.68333, 0.15294, 0, 0.66444], 928: [0, 0.68333, 0.16389, 0, 0.74333], 931: [0, 0.68333, 0.12028, 0, 0.71555], 933: [0, 0.68333, 0.11111, 0, 0.76666], 934: [0, 0.68333, 0.05986, 0, 0.71555], 936: [0, 0.68333, 0.11111, 0, 0.76666], 937: [0, 0.68333, 0.10257, 0, 0.71555], 8211: [0, 0.43056, 0.09208, 0, 0.51111], 8212: [0, 0.43056, 0.09208, 0, 1.02222], 8216: [0, 0.69444, 0.12417, 0, 0.30667], 8217: [0, 0.69444, 0.12417, 0, 0.30667], 8220: [0, 0.69444, 0.1685, 0, 0.51444], 8221: [0, 0.69444, 0.06961, 0, 0.51444], 8463: [0, 0.68889, 0, 0, 0.54028] }, "Main-Regular": { 32: [0, 0, 0, 0, 0.25], 33: [0, 0.69444, 0, 0, 0.27778], 34: [0, 0.69444, 0, 0, 0.5], 35: [0.19444, 0.69444, 0, 0, 0.83334], 36: [0.05556, 0.75, 0, 0, 0.5], 37: [0.05556, 0.75, 0, 0, 0.83334], 38: [0, 0.69444, 0, 0, 0.77778], 39: [0, 0.69444, 0, 0, 0.27778], 40: [0.25, 0.75, 0, 0, 0.38889], 41: [0.25, 0.75, 0, 0, 0.38889], 42: [0, 0.75, 0, 0, 0.5], 43: [0.08333, 0.58333, 0, 0, 0.77778], 44: [0.19444, 0.10556, 0, 0, 0.27778], 45: [0, 0.43056, 0, 0, 0.33333], 46: [0, 0.10556, 0, 0, 0.27778], 47: [0.25, 0.75, 0, 0, 0.5], 48: [0, 0.64444, 0, 0, 0.5], 49: [0, 0.64444, 0, 0, 0.5], 50: [0, 0.64444, 0, 0, 0.5], 51: [0, 0.64444, 0, 0, 0.5], 52: [0, 0.64444, 0, 0, 0.5], 53: [0, 0.64444, 0, 0, 0.5], 54: [0, 0.64444, 0, 0, 0.5], 55: [0, 0.64444, 0, 0, 0.5], 56: [0, 0.64444, 0, 0, 0.5], 57: [0, 0.64444, 0, 0, 0.5], 58: [0, 0.43056, 0, 0, 0.27778], 59: [0.19444, 0.43056, 0, 0, 0.27778], 60: [0.0391, 0.5391, 0, 0, 0.77778], 61: [-0.13313, 0.36687, 0, 0, 0.77778], 62: [0.0391, 0.5391, 0, 0, 0.77778], 63: [0, 0.69444, 0, 0, 0.47222], 64: [0, 0.69444, 0, 0, 0.77778], 65: [0, 0.68333, 0, 0, 0.75], 66: [0, 0.68333, 0, 0, 0.70834], 67: [0, 0.68333, 0, 0, 0.72222], 68: [0, 0.68333, 0, 0, 0.76389], 69: [0, 0.68333, 0, 0, 0.68056], 70: [0, 0.68333, 0, 0, 0.65278], 71: [0, 0.68333, 0, 0, 0.78472], 72: [0, 0.68333, 0, 0, 0.75], 73: [0, 0.68333, 0, 0, 0.36111], 74: [0, 0.68333, 0, 0, 0.51389], 75: [0, 0.68333, 0, 0, 0.77778], 76: [0, 0.68333, 0, 0, 0.625], 77: [0, 0.68333, 0, 0, 0.91667], 78: [0, 0.68333, 0, 0, 0.75], 79: [0, 0.68333, 0, 0, 0.77778], 80: [0, 0.68333, 0, 0, 0.68056], 81: [0.19444, 0.68333, 0, 0, 0.77778], 82: [0, 0.68333, 0, 0, 0.73611], 83: [0, 0.68333, 0, 0, 0.55556], 84: [0, 0.68333, 0, 0, 0.72222], 85: [0, 0.68333, 0, 0, 0.75], 86: [0, 0.68333, 0.01389, 0, 0.75], 87: [0, 0.68333, 0.01389, 0, 1.02778], 88: [0, 0.68333, 0, 0, 0.75], 89: [0, 0.68333, 0.025, 0, 0.75], 90: [0, 0.68333, 0, 0, 0.61111], 91: [0.25, 0.75, 0, 0, 0.27778], 92: [0.25, 0.75, 0, 0, 0.5], 93: [0.25, 0.75, 0, 0, 0.27778], 94: [0, 0.69444, 0, 0, 0.5], 95: [0.31, 0.12056, 0.02778, 0, 0.5], 97: [0, 0.43056, 0, 0, 0.5], 98: [0, 0.69444, 0, 0, 0.55556], 99: [0, 0.43056, 0, 0, 0.44445], 100: [0, 0.69444, 0, 0, 0.55556], 101: [0, 0.43056, 0, 0, 0.44445], 102: [0, 0.69444, 0.07778, 0, 0.30556], 103: [0.19444, 0.43056, 0.01389, 0, 0.5], 104: [0, 0.69444, 0, 0, 0.55556], 105: [0, 0.66786, 0, 0, 0.27778], 106: [0.19444, 0.66786, 0, 0, 0.30556], 107: [0, 0.69444, 0, 0, 0.52778], 108: [0, 0.69444, 0, 0, 0.27778], 109: [0, 0.43056, 0, 0, 0.83334], 110: [0, 0.43056, 0, 0, 0.55556], 111: [0, 0.43056, 0, 0, 0.5], 112: [0.19444, 0.43056, 0, 0, 0.55556], 113: [0.19444, 0.43056, 0, 0, 0.52778], 114: [0, 0.43056, 0, 0, 0.39167], 115: [0, 0.43056, 0, 0, 0.39445], 116: [0, 0.61508, 0, 0, 0.38889], 117: [0, 0.43056, 0, 0, 0.55556], 118: [0, 0.43056, 0.01389, 0, 0.52778], 119: [0, 0.43056, 0.01389, 0, 0.72222], 120: [0, 0.43056, 0, 0, 0.52778], 121: [0.19444, 0.43056, 0.01389, 0, 0.52778], 122: [0, 0.43056, 0, 0, 0.44445], 123: [0.25, 0.75, 0, 0, 0.5], 124: [0.25, 0.75, 0, 0, 0.27778], 125: [0.25, 0.75, 0, 0, 0.5], 126: [0.35, 0.31786, 0, 0, 0.5], 160: [0, 0, 0, 0, 0.25], 163: [0, 0.69444, 0, 0, 0.76909], 167: [0.19444, 0.69444, 0, 0, 0.44445], 168: [0, 0.66786, 0, 0, 0.5], 172: [0, 0.43056, 0, 0, 0.66667], 176: [0, 0.69444, 0, 0, 0.75], 177: [0.08333, 0.58333, 0, 0, 0.77778], 182: [0.19444, 0.69444, 0, 0, 0.61111], 184: [0.17014, 0, 0, 0, 0.44445], 198: [0, 0.68333, 0, 0, 0.90278], 215: [0.08333, 0.58333, 0, 0, 0.77778], 216: [0.04861, 0.73194, 0, 0, 0.77778], 223: [0, 0.69444, 0, 0, 0.5], 230: [0, 0.43056, 0, 0, 0.72222], 247: [0.08333, 0.58333, 0, 0, 0.77778], 248: [0.09722, 0.52778, 0, 0, 0.5], 305: [0, 0.43056, 0, 0, 0.27778], 338: [0, 0.68333, 0, 0, 1.01389], 339: [0, 0.43056, 0, 0, 0.77778], 567: [0.19444, 0.43056, 0, 0, 0.30556], 710: [0, 0.69444, 0, 0, 0.5], 711: [0, 0.62847, 0, 0, 0.5], 713: [0, 0.56778, 0, 0, 0.5], 714: [0, 0.69444, 0, 0, 0.5], 715: [0, 0.69444, 0, 0, 0.5], 728: [0, 0.69444, 0, 0, 0.5], 729: [0, 0.66786, 0, 0, 0.27778], 730: [0, 0.69444, 0, 0, 0.75], 732: [0, 0.66786, 0, 0, 0.5], 733: [0, 0.69444, 0, 0, 0.5], 915: [0, 0.68333, 0, 0, 0.625], 916: [0, 0.68333, 0, 0, 0.83334], 920: [0, 0.68333, 0, 0, 0.77778], 923: [0, 0.68333, 0, 0, 0.69445], 926: [0, 0.68333, 0, 0, 0.66667], 928: [0, 0.68333, 0, 0, 0.75], 931: [0, 0.68333, 0, 0, 0.72222], 933: [0, 0.68333, 0, 0, 0.77778], 934: [0, 0.68333, 0, 0, 0.72222], 936: [0, 0.68333, 0, 0, 0.77778], 937: [0, 0.68333, 0, 0, 0.72222], 8211: [0, 0.43056, 0.02778, 0, 0.5], 8212: [0, 0.43056, 0.02778, 0, 1], 8216: [0, 0.69444, 0, 0, 0.27778], 8217: [0, 0.69444, 0, 0, 0.27778], 8220: [0, 0.69444, 0, 0, 0.5], 8221: [0, 0.69444, 0, 0, 0.5], 8224: [0.19444, 0.69444, 0, 0, 0.44445], 8225: [0.19444, 0.69444, 0, 0, 0.44445], 8230: [0, 0.123, 0, 0, 1.172], 8242: [0, 0.55556, 0, 0, 0.275], 8407: [0, 0.71444, 0.15382, 0, 0.5], 8463: [0, 0.68889, 0, 0, 0.54028], 8465: [0, 0.69444, 0, 0, 0.72222], 8467: [0, 0.69444, 0, 0.11111, 0.41667], 8472: [0.19444, 0.43056, 0, 0.11111, 0.63646], 8476: [0, 0.69444, 0, 0, 0.72222], 8501: [0, 0.69444, 0, 0, 0.61111], 8592: [-0.13313, 0.36687, 0, 0, 1], 8593: [0.19444, 0.69444, 0, 0, 0.5], 8594: [-0.13313, 0.36687, 0, 0, 1], 8595: [0.19444, 0.69444, 0, 0, 0.5], 8596: [-0.13313, 0.36687, 0, 0, 1], 8597: [0.25, 0.75, 0, 0, 0.5], 8598: [0.19444, 0.69444, 0, 0, 1], 8599: [0.19444, 0.69444, 0, 0, 1], 8600: [0.19444, 0.69444, 0, 0, 1], 8601: [0.19444, 0.69444, 0, 0, 1], 8614: [0.011, 0.511, 0, 0, 1], 8617: [0.011, 0.511, 0, 0, 1.126], 8618: [0.011, 0.511, 0, 0, 1.126], 8636: [-0.13313, 0.36687, 0, 0, 1], 8637: [-0.13313, 0.36687, 0, 0, 1], 8640: [-0.13313, 0.36687, 0, 0, 1], 8641: [-0.13313, 0.36687, 0, 0, 1], 8652: [0.011, 0.671, 0, 0, 1], 8656: [-0.13313, 0.36687, 0, 0, 1], 8657: [0.19444, 0.69444, 0, 0, 0.61111], 8658: [-0.13313, 0.36687, 0, 0, 1], 8659: [0.19444, 0.69444, 0, 0, 0.61111], 8660: [-0.13313, 0.36687, 0, 0, 1], 8661: [0.25, 0.75, 0, 0, 0.61111], 8704: [0, 0.69444, 0, 0, 0.55556], 8706: [0, 0.69444, 0.05556, 0.08334, 0.5309], 8707: [0, 0.69444, 0, 0, 0.55556], 8709: [0.05556, 0.75, 0, 0, 0.5], 8711: [0, 0.68333, 0, 0, 0.83334], 8712: [0.0391, 0.5391, 0, 0, 0.66667], 8715: [0.0391, 0.5391, 0, 0, 0.66667], 8722: [0.08333, 0.58333, 0, 0, 0.77778], 8723: [0.08333, 0.58333, 0, 0, 0.77778], 8725: [0.25, 0.75, 0, 0, 0.5], 8726: [0.25, 0.75, 0, 0, 0.5], 8727: [-0.03472, 0.46528, 0, 0, 0.5], 8728: [-0.05555, 0.44445, 0, 0, 0.5], 8729: [-0.05555, 0.44445, 0, 0, 0.5], 8730: [0.2, 0.8, 0, 0, 0.83334], 8733: [0, 0.43056, 0, 0, 0.77778], 8734: [0, 0.43056, 0, 0, 1], 8736: [0, 0.69224, 0, 0, 0.72222], 8739: [0.25, 0.75, 0, 0, 0.27778], 8741: [0.25, 0.75, 0, 0, 0.5], 8743: [0, 0.55556, 0, 0, 0.66667], 8744: [0, 0.55556, 0, 0, 0.66667], 8745: [0, 0.55556, 0, 0, 0.66667], 8746: [0, 0.55556, 0, 0, 0.66667], 8747: [0.19444, 0.69444, 0.11111, 0, 0.41667], 8764: [-0.13313, 0.36687, 0, 0, 0.77778], 8768: [0.19444, 0.69444, 0, 0, 0.27778], 8771: [-0.03625, 0.46375, 0, 0, 0.77778], 8773: [-0.022, 0.589, 0, 0, 0.778], 8776: [-0.01688, 0.48312, 0, 0, 0.77778], 8781: [-0.03625, 0.46375, 0, 0, 0.77778], 8784: [-0.133, 0.673, 0, 0, 0.778], 8801: [-0.03625, 0.46375, 0, 0, 0.77778], 8804: [0.13597, 0.63597, 0, 0, 0.77778], 8805: [0.13597, 0.63597, 0, 0, 0.77778], 8810: [0.0391, 0.5391, 0, 0, 1], 8811: [0.0391, 0.5391, 0, 0, 1], 8826: [0.0391, 0.5391, 0, 0, 0.77778], 8827: [0.0391, 0.5391, 0, 0, 0.77778], 8834: [0.0391, 0.5391, 0, 0, 0.77778], 8835: [0.0391, 0.5391, 0, 0, 0.77778], 8838: [0.13597, 0.63597, 0, 0, 0.77778], 8839: [0.13597, 0.63597, 0, 0, 0.77778], 8846: [0, 0.55556, 0, 0, 0.66667], 8849: [0.13597, 0.63597, 0, 0, 0.77778], 8850: [0.13597, 0.63597, 0, 0, 0.77778], 8851: [0, 0.55556, 0, 0, 0.66667], 8852: [0, 0.55556, 0, 0, 0.66667], 8853: [0.08333, 0.58333, 0, 0, 0.77778], 8854: [0.08333, 0.58333, 0, 0, 0.77778], 8855: [0.08333, 0.58333, 0, 0, 0.77778], 8856: [0.08333, 0.58333, 0, 0, 0.77778], 8857: [0.08333, 0.58333, 0, 0, 0.77778], 8866: [0, 0.69444, 0, 0, 0.61111], 8867: [0, 0.69444, 0, 0, 0.61111], 8868: [0, 0.69444, 0, 0, 0.77778], 8869: [0, 0.69444, 0, 0, 0.77778], 8872: [0.249, 0.75, 0, 0, 0.867], 8900: [-0.05555, 0.44445, 0, 0, 0.5], 8901: [-0.05555, 0.44445, 0, 0, 0.27778], 8902: [-0.03472, 0.46528, 0, 0, 0.5], 8904: [5e-3, 0.505, 0, 0, 0.9], 8942: [0.03, 0.903, 0, 0, 0.278], 8943: [-0.19, 0.313, 0, 0, 1.172], 8945: [-0.1, 0.823, 0, 0, 1.282], 8968: [0.25, 0.75, 0, 0, 0.44445], 8969: [0.25, 0.75, 0, 0, 0.44445], 8970: [0.25, 0.75, 0, 0, 0.44445], 8971: [0.25, 0.75, 0, 0, 0.44445], 8994: [-0.14236, 0.35764, 0, 0, 1], 8995: [-0.14236, 0.35764, 0, 0, 1], 9136: [0.244, 0.744, 0, 0, 0.412], 9137: [0.244, 0.745, 0, 0, 0.412], 9651: [0.19444, 0.69444, 0, 0, 0.88889], 9657: [-0.03472, 0.46528, 0, 0, 0.5], 9661: [0.19444, 0.69444, 0, 0, 0.88889], 9667: [-0.03472, 0.46528, 0, 0, 0.5], 9711: [0.19444, 0.69444, 0, 0, 1], 9824: [0.12963, 0.69444, 0, 0, 0.77778], 9825: [0.12963, 0.69444, 0, 0, 0.77778], 9826: [0.12963, 0.69444, 0, 0, 0.77778], 9827: [0.12963, 0.69444, 0, 0, 0.77778], 9837: [0, 0.75, 0, 0, 0.38889], 9838: [0.19444, 0.69444, 0, 0, 0.38889], 9839: [0.19444, 0.69444, 0, 0, 0.38889], 10216: [0.25, 0.75, 0, 0, 0.38889], 10217: [0.25, 0.75, 0, 0, 0.38889], 10222: [0.244, 0.744, 0, 0, 0.412], 10223: [0.244, 0.745, 0, 0, 0.412], 10229: [0.011, 0.511, 0, 0, 1.609], 10230: [0.011, 0.511, 0, 0, 1.638], 10231: [0.011, 0.511, 0, 0, 1.859], 10232: [0.024, 0.525, 0, 0, 1.609], 10233: [0.024, 0.525, 0, 0, 1.638], 10234: [0.024, 0.525, 0, 0, 1.858], 10236: [0.011, 0.511, 0, 0, 1.638], 10815: [0, 0.68333, 0, 0, 0.75], 10927: [0.13597, 0.63597, 0, 0, 0.77778], 10928: [0.13597, 0.63597, 0, 0, 0.77778], 57376: [0.19444, 0.69444, 0, 0, 0] }, "Math-BoldItalic": { 32: [0, 0, 0, 0, 0.25], 48: [0, 0.44444, 0, 0, 0.575], 49: [0, 0.44444, 0, 0, 0.575], 50: [0, 0.44444, 0, 0, 0.575], 51: [0.19444, 0.44444, 0, 0, 0.575], 52: [0.19444, 0.44444, 0, 0, 0.575], 53: [0.19444, 0.44444, 0, 0, 0.575], 54: [0, 0.64444, 0, 0, 0.575], 55: [0.19444, 0.44444, 0, 0, 0.575], 56: [0, 0.64444, 0, 0, 0.575], 57: [0.19444, 0.44444, 0, 0, 0.575], 65: [0, 0.68611, 0, 0, 0.86944], 66: [0, 0.68611, 0.04835, 0, 0.8664], 67: [0, 0.68611, 0.06979, 0, 0.81694], 68: [0, 0.68611, 0.03194, 0, 0.93812], 69: [0, 0.68611, 0.05451, 0, 0.81007], 70: [0, 0.68611, 0.15972, 0, 0.68889], 71: [0, 0.68611, 0, 0, 0.88673], 72: [0, 0.68611, 0.08229, 0, 0.98229], 73: [0, 0.68611, 0.07778, 0, 0.51111], 74: [0, 0.68611, 0.10069, 0, 0.63125], 75: [0, 0.68611, 0.06979, 0, 0.97118], 76: [0, 0.68611, 0, 0, 0.75555], 77: [0, 0.68611, 0.11424, 0, 1.14201], 78: [0, 0.68611, 0.11424, 0, 0.95034], 79: [0, 0.68611, 0.03194, 0, 0.83666], 80: [0, 0.68611, 0.15972, 0, 0.72309], 81: [0.19444, 0.68611, 0, 0, 0.86861], 82: [0, 0.68611, 421e-5, 0, 0.87235], 83: [0, 0.68611, 0.05382, 0, 0.69271], 84: [0, 0.68611, 0.15972, 0, 0.63663], 85: [0, 0.68611, 0.11424, 0, 0.80027], 86: [0, 0.68611, 0.25555, 0, 0.67778], 87: [0, 0.68611, 0.15972, 0, 1.09305], 88: [0, 0.68611, 0.07778, 0, 0.94722], 89: [0, 0.68611, 0.25555, 0, 0.67458], 90: [0, 0.68611, 0.06979, 0, 0.77257], 97: [0, 0.44444, 0, 0, 0.63287], 98: [0, 0.69444, 0, 0, 0.52083], 99: [0, 0.44444, 0, 0, 0.51342], 100: [0, 0.69444, 0, 0, 0.60972], 101: [0, 0.44444, 0, 0, 0.55361], 102: [0.19444, 0.69444, 0.11042, 0, 0.56806], 103: [0.19444, 0.44444, 0.03704, 0, 0.5449], 104: [0, 0.69444, 0, 0, 0.66759], 105: [0, 0.69326, 0, 0, 0.4048], 106: [0.19444, 0.69326, 0.0622, 0, 0.47083], 107: [0, 0.69444, 0.01852, 0, 0.6037], 108: [0, 0.69444, 88e-4, 0, 0.34815], 109: [0, 0.44444, 0, 0, 1.0324], 110: [0, 0.44444, 0, 0, 0.71296], 111: [0, 0.44444, 0, 0, 0.58472], 112: [0.19444, 0.44444, 0, 0, 0.60092], 113: [0.19444, 0.44444, 0.03704, 0, 0.54213], 114: [0, 0.44444, 0.03194, 0, 0.5287], 115: [0, 0.44444, 0, 0, 0.53125], 116: [0, 0.63492, 0, 0, 0.41528], 117: [0, 0.44444, 0, 0, 0.68102], 118: [0, 0.44444, 0.03704, 0, 0.56666], 119: [0, 0.44444, 0.02778, 0, 0.83148], 120: [0, 0.44444, 0, 0, 0.65903], 121: [0.19444, 0.44444, 0.03704, 0, 0.59028], 122: [0, 0.44444, 0.04213, 0, 0.55509], 160: [0, 0, 0, 0, 0.25], 915: [0, 0.68611, 0.15972, 0, 0.65694], 916: [0, 0.68611, 0, 0, 0.95833], 920: [0, 0.68611, 0.03194, 0, 0.86722], 923: [0, 0.68611, 0, 0, 0.80555], 926: [0, 0.68611, 0.07458, 0, 0.84125], 928: [0, 0.68611, 0.08229, 0, 0.98229], 931: [0, 0.68611, 0.05451, 0, 0.88507], 933: [0, 0.68611, 0.15972, 0, 0.67083], 934: [0, 0.68611, 0, 0, 0.76666], 936: [0, 0.68611, 0.11653, 0, 0.71402], 937: [0, 0.68611, 0.04835, 0, 0.8789], 945: [0, 0.44444, 0, 0, 0.76064], 946: [0.19444, 0.69444, 0.03403, 0, 0.65972], 947: [0.19444, 0.44444, 0.06389, 0, 0.59003], 948: [0, 0.69444, 0.03819, 0, 0.52222], 949: [0, 0.44444, 0, 0, 0.52882], 950: [0.19444, 0.69444, 0.06215, 0, 0.50833], 951: [0.19444, 0.44444, 0.03704, 0, 0.6], 952: [0, 0.69444, 0.03194, 0, 0.5618], 953: [0, 0.44444, 0, 0, 0.41204], 954: [0, 0.44444, 0, 0, 0.66759], 955: [0, 0.69444, 0, 0, 0.67083], 956: [0.19444, 0.44444, 0, 0, 0.70787], 957: [0, 0.44444, 0.06898, 0, 0.57685], 958: [0.19444, 0.69444, 0.03021, 0, 0.50833], 959: [0, 0.44444, 0, 0, 0.58472], 960: [0, 0.44444, 0.03704, 0, 0.68241], 961: [0.19444, 0.44444, 0, 0, 0.6118], 962: [0.09722, 0.44444, 0.07917, 0, 0.42361], 963: [0, 0.44444, 0.03704, 0, 0.68588], 964: [0, 0.44444, 0.13472, 0, 0.52083], 965: [0, 0.44444, 0.03704, 0, 0.63055], 966: [0.19444, 0.44444, 0, 0, 0.74722], 967: [0.19444, 0.44444, 0, 0, 0.71805], 968: [0.19444, 0.69444, 0.03704, 0, 0.75833], 969: [0, 0.44444, 0.03704, 0, 0.71782], 977: [0, 0.69444, 0, 0, 0.69155], 981: [0.19444, 0.69444, 0, 0, 0.7125], 982: [0, 0.44444, 0.03194, 0, 0.975], 1009: [0.19444, 0.44444, 0, 0, 0.6118], 1013: [0, 0.44444, 0, 0, 0.48333], 57649: [0, 0.44444, 0, 0, 0.39352], 57911: [0.19444, 0.44444, 0, 0, 0.43889] }, "Math-Italic": { 32: [0, 0, 0, 0, 0.25], 48: [0, 0.43056, 0, 0, 0.5], 49: [0, 0.43056, 0, 0, 0.5], 50: [0, 0.43056, 0, 0, 0.5], 51: [0.19444, 0.43056, 0, 0, 0.5], 52: [0.19444, 0.43056, 0, 0, 0.5], 53: [0.19444, 0.43056, 0, 0, 0.5], 54: [0, 0.64444, 0, 0, 0.5], 55: [0.19444, 0.43056, 0, 0, 0.5], 56: [0, 0.64444, 0, 0, 0.5], 57: [0.19444, 0.43056, 0, 0, 0.5], 65: [0, 0.68333, 0, 0.13889, 0.75], 66: [0, 0.68333, 0.05017, 0.08334, 0.75851], 67: [0, 0.68333, 0.07153, 0.08334, 0.71472], 68: [0, 0.68333, 0.02778, 0.05556, 0.82792], 69: [0, 0.68333, 0.05764, 0.08334, 0.7382], 70: [0, 0.68333, 0.13889, 0.08334, 0.64306], 71: [0, 0.68333, 0, 0.08334, 0.78625], 72: [0, 0.68333, 0.08125, 0.05556, 0.83125], 73: [0, 0.68333, 0.07847, 0.11111, 0.43958], 74: [0, 0.68333, 0.09618, 0.16667, 0.55451], 75: [0, 0.68333, 0.07153, 0.05556, 0.84931], 76: [0, 0.68333, 0, 0.02778, 0.68056], 77: [0, 0.68333, 0.10903, 0.08334, 0.97014], 78: [0, 0.68333, 0.10903, 0.08334, 0.80347], 79: [0, 0.68333, 0.02778, 0.08334, 0.76278], 80: [0, 0.68333, 0.13889, 0.08334, 0.64201], 81: [0.19444, 0.68333, 0, 0.08334, 0.79056], 82: [0, 0.68333, 773e-5, 0.08334, 0.75929], 83: [0, 0.68333, 0.05764, 0.08334, 0.6132], 84: [0, 0.68333, 0.13889, 0.08334, 0.58438], 85: [0, 0.68333, 0.10903, 0.02778, 0.68278], 86: [0, 0.68333, 0.22222, 0, 0.58333], 87: [0, 0.68333, 0.13889, 0, 0.94445], 88: [0, 0.68333, 0.07847, 0.08334, 0.82847], 89: [0, 0.68333, 0.22222, 0, 0.58056], 90: [0, 0.68333, 0.07153, 0.08334, 0.68264], 97: [0, 0.43056, 0, 0, 0.52859], 98: [0, 0.69444, 0, 0, 0.42917], 99: [0, 0.43056, 0, 0.05556, 0.43276], 100: [0, 0.69444, 0, 0.16667, 0.52049], 101: [0, 0.43056, 0, 0.05556, 0.46563], 102: [0.19444, 0.69444, 0.10764, 0.16667, 0.48959], 103: [0.19444, 0.43056, 0.03588, 0.02778, 0.47697], 104: [0, 0.69444, 0, 0, 0.57616], 105: [0, 0.65952, 0, 0, 0.34451], 106: [0.19444, 0.65952, 0.05724, 0, 0.41181], 107: [0, 0.69444, 0.03148, 0, 0.5206], 108: [0, 0.69444, 0.01968, 0.08334, 0.29838], 109: [0, 0.43056, 0, 0, 0.87801], 110: [0, 0.43056, 0, 0, 0.60023], 111: [0, 0.43056, 0, 0.05556, 0.48472], 112: [0.19444, 0.43056, 0, 0.08334, 0.50313], 113: [0.19444, 0.43056, 0.03588, 0.08334, 0.44641], 114: [0, 0.43056, 0.02778, 0.05556, 0.45116], 115: [0, 0.43056, 0, 0.05556, 0.46875], 116: [0, 0.61508, 0, 0.08334, 0.36111], 117: [0, 0.43056, 0, 0.02778, 0.57246], 118: [0, 0.43056, 0.03588, 0.02778, 0.48472], 119: [0, 0.43056, 0.02691, 0.08334, 0.71592], 120: [0, 0.43056, 0, 0.02778, 0.57153], 121: [0.19444, 0.43056, 0.03588, 0.05556, 0.49028], 122: [0, 0.43056, 0.04398, 0.05556, 0.46505], 160: [0, 0, 0, 0, 0.25], 915: [0, 0.68333, 0.13889, 0.08334, 0.61528], 916: [0, 0.68333, 0, 0.16667, 0.83334], 920: [0, 0.68333, 0.02778, 0.08334, 0.76278], 923: [0, 0.68333, 0, 0.16667, 0.69445], 926: [0, 0.68333, 0.07569, 0.08334, 0.74236], 928: [0, 0.68333, 0.08125, 0.05556, 0.83125], 931: [0, 0.68333, 0.05764, 0.08334, 0.77986], 933: [0, 0.68333, 0.13889, 0.05556, 0.58333], 934: [0, 0.68333, 0, 0.08334, 0.66667], 936: [0, 0.68333, 0.11, 0.05556, 0.61222], 937: [0, 0.68333, 0.05017, 0.08334, 0.7724], 945: [0, 0.43056, 37e-4, 0.02778, 0.6397], 946: [0.19444, 0.69444, 0.05278, 0.08334, 0.56563], 947: [0.19444, 0.43056, 0.05556, 0, 0.51773], 948: [0, 0.69444, 0.03785, 0.05556, 0.44444], 949: [0, 0.43056, 0, 0.08334, 0.46632], 950: [0.19444, 0.69444, 0.07378, 0.08334, 0.4375], 951: [0.19444, 0.43056, 0.03588, 0.05556, 0.49653], 952: [0, 0.69444, 0.02778, 0.08334, 0.46944], 953: [0, 0.43056, 0, 0.05556, 0.35394], 954: [0, 0.43056, 0, 0, 0.57616], 955: [0, 0.69444, 0, 0, 0.58334], 956: [0.19444, 0.43056, 0, 0.02778, 0.60255], 957: [0, 0.43056, 0.06366, 0.02778, 0.49398], 958: [0.19444, 0.69444, 0.04601, 0.11111, 0.4375], 959: [0, 0.43056, 0, 0.05556, 0.48472], 960: [0, 0.43056, 0.03588, 0, 0.57003], 961: [0.19444, 0.43056, 0, 0.08334, 0.51702], 962: [0.09722, 0.43056, 0.07986, 0.08334, 0.36285], 963: [0, 0.43056, 0.03588, 0, 0.57141], 964: [0, 0.43056, 0.1132, 0.02778, 0.43715], 965: [0, 0.43056, 0.03588, 0.02778, 0.54028], 966: [0.19444, 0.43056, 0, 0.08334, 0.65417], 967: [0.19444, 0.43056, 0, 0.05556, 0.62569], 968: [0.19444, 0.69444, 0.03588, 0.11111, 0.65139], 969: [0, 0.43056, 0.03588, 0, 0.62245], 977: [0, 0.69444, 0, 0.08334, 0.59144], 981: [0.19444, 0.69444, 0, 0.08334, 0.59583], 982: [0, 0.43056, 0.02778, 0, 0.82813], 1009: [0.19444, 0.43056, 0, 0.08334, 0.51702], 1013: [0, 0.43056, 0, 0.05556, 0.4059], 57649: [0, 0.43056, 0, 0.02778, 0.32246], 57911: [0.19444, 0.43056, 0, 0.08334, 0.38403] }, "SansSerif-Bold": { 32: [0, 0, 0, 0, 0.25], 33: [0, 0.69444, 0, 0, 0.36667], 34: [0, 0.69444, 0, 0, 0.55834], 35: [0.19444, 0.69444, 0, 0, 0.91667], 36: [0.05556, 0.75, 0, 0, 0.55], 37: [0.05556, 0.75, 0, 0, 1.02912], 38: [0, 0.69444, 0, 0, 0.83056], 39: [0, 0.69444, 0, 0, 0.30556], 40: [0.25, 0.75, 0, 0, 0.42778], 41: [0.25, 0.75, 0, 0, 0.42778], 42: [0, 0.75, 0, 0, 0.55], 43: [0.11667, 0.61667, 0, 0, 0.85556], 44: [0.10556, 0.13056, 0, 0, 0.30556], 45: [0, 0.45833, 0, 0, 0.36667], 46: [0, 0.13056, 0, 0, 0.30556], 47: [0.25, 0.75, 0, 0, 0.55], 48: [0, 0.69444, 0, 0, 0.55], 49: [0, 0.69444, 0, 0, 0.55], 50: [0, 0.69444, 0, 0, 0.55], 51: [0, 0.69444, 0, 0, 0.55], 52: [0, 0.69444, 0, 0, 0.55], 53: [0, 0.69444, 0, 0, 0.55], 54: [0, 0.69444, 0, 0, 0.55], 55: [0, 0.69444, 0, 0, 0.55], 56: [0, 0.69444, 0, 0, 0.55], 57: [0, 0.69444, 0, 0, 0.55], 58: [0, 0.45833, 0, 0, 0.30556], 59: [0.10556, 0.45833, 0, 0, 0.30556], 61: [-0.09375, 0.40625, 0, 0, 0.85556], 63: [0, 0.69444, 0, 0, 0.51945], 64: [0, 0.69444, 0, 0, 0.73334], 65: [0, 0.69444, 0, 0, 0.73334], 66: [0, 0.69444, 0, 0, 0.73334], 67: [0, 0.69444, 0, 0, 0.70278], 68: [0, 0.69444, 0, 0, 0.79445], 69: [0, 0.69444, 0, 0, 0.64167], 70: [0, 0.69444, 0, 0, 0.61111], 71: [0, 0.69444, 0, 0, 0.73334], 72: [0, 0.69444, 0, 0, 0.79445], 73: [0, 0.69444, 0, 0, 0.33056], 74: [0, 0.69444, 0, 0, 0.51945], 75: [0, 0.69444, 0, 0, 0.76389], 76: [0, 0.69444, 0, 0, 0.58056], 77: [0, 0.69444, 0, 0, 0.97778], 78: [0, 0.69444, 0, 0, 0.79445], 79: [0, 0.69444, 0, 0, 0.79445], 80: [0, 0.69444, 0, 0, 0.70278], 81: [0.10556, 0.69444, 0, 0, 0.79445], 82: [0, 0.69444, 0, 0, 0.70278], 83: [0, 0.69444, 0, 0, 0.61111], 84: [0, 0.69444, 0, 0, 0.73334], 85: [0, 0.69444, 0, 0, 0.76389], 86: [0, 0.69444, 0.01528, 0, 0.73334], 87: [0, 0.69444, 0.01528, 0, 1.03889], 88: [0, 0.69444, 0, 0, 0.73334], 89: [0, 0.69444, 0.0275, 0, 0.73334], 90: [0, 0.69444, 0, 0, 0.67223], 91: [0.25, 0.75, 0, 0, 0.34306], 93: [0.25, 0.75, 0, 0, 0.34306], 94: [0, 0.69444, 0, 0, 0.55], 95: [0.35, 0.10833, 0.03056, 0, 0.55], 97: [0, 0.45833, 0, 0, 0.525], 98: [0, 0.69444, 0, 0, 0.56111], 99: [0, 0.45833, 0, 0, 0.48889], 100: [0, 0.69444, 0, 0, 0.56111], 101: [0, 0.45833, 0, 0, 0.51111], 102: [0, 0.69444, 0.07639, 0, 0.33611], 103: [0.19444, 0.45833, 0.01528, 0, 0.55], 104: [0, 0.69444, 0, 0, 0.56111], 105: [0, 0.69444, 0, 0, 0.25556], 106: [0.19444, 0.69444, 0, 0, 0.28611], 107: [0, 0.69444, 0, 0, 0.53056], 108: [0, 0.69444, 0, 0, 0.25556], 109: [0, 0.45833, 0, 0, 0.86667], 110: [0, 0.45833, 0, 0, 0.56111], 111: [0, 0.45833, 0, 0, 0.55], 112: [0.19444, 0.45833, 0, 0, 0.56111], 113: [0.19444, 0.45833, 0, 0, 0.56111], 114: [0, 0.45833, 0.01528, 0, 0.37222], 115: [0, 0.45833, 0, 0, 0.42167], 116: [0, 0.58929, 0, 0, 0.40417], 117: [0, 0.45833, 0, 0, 0.56111], 118: [0, 0.45833, 0.01528, 0, 0.5], 119: [0, 0.45833, 0.01528, 0, 0.74445], 120: [0, 0.45833, 0, 0, 0.5], 121: [0.19444, 0.45833, 0.01528, 0, 0.5], 122: [0, 0.45833, 0, 0, 0.47639], 126: [0.35, 0.34444, 0, 0, 0.55], 160: [0, 0, 0, 0, 0.25], 168: [0, 0.69444, 0, 0, 0.55], 176: [0, 0.69444, 0, 0, 0.73334], 180: [0, 0.69444, 0, 0, 0.55], 184: [0.17014, 0, 0, 0, 0.48889], 305: [0, 0.45833, 0, 0, 0.25556], 567: [0.19444, 0.45833, 0, 0, 0.28611], 710: [0, 0.69444, 0, 0, 0.55], 711: [0, 0.63542, 0, 0, 0.55], 713: [0, 0.63778, 0, 0, 0.55], 728: [0, 0.69444, 0, 0, 0.55], 729: [0, 0.69444, 0, 0, 0.30556], 730: [0, 0.69444, 0, 0, 0.73334], 732: [0, 0.69444, 0, 0, 0.55], 733: [0, 0.69444, 0, 0, 0.55], 915: [0, 0.69444, 0, 0, 0.58056], 916: [0, 0.69444, 0, 0, 0.91667], 920: [0, 0.69444, 0, 0, 0.85556], 923: [0, 0.69444, 0, 0, 0.67223], 926: [0, 0.69444, 0, 0, 0.73334], 928: [0, 0.69444, 0, 0, 0.79445], 931: [0, 0.69444, 0, 0, 0.79445], 933: [0, 0.69444, 0, 0, 0.85556], 934: [0, 0.69444, 0, 0, 0.79445], 936: [0, 0.69444, 0, 0, 0.85556], 937: [0, 0.69444, 0, 0, 0.79445], 8211: [0, 0.45833, 0.03056, 0, 0.55], 8212: [0, 0.45833, 0.03056, 0, 1.10001], 8216: [0, 0.69444, 0, 0, 0.30556], 8217: [0, 0.69444, 0, 0, 0.30556], 8220: [0, 0.69444, 0, 0, 0.55834], 8221: [0, 0.69444, 0, 0, 0.55834] }, "SansSerif-Italic": { 32: [0, 0, 0, 0, 0.25], 33: [0, 0.69444, 0.05733, 0, 0.31945], 34: [0, 0.69444, 316e-5, 0, 0.5], 35: [0.19444, 0.69444, 0.05087, 0, 0.83334], 36: [0.05556, 0.75, 0.11156, 0, 0.5], 37: [0.05556, 0.75, 0.03126, 0, 0.83334], 38: [0, 0.69444, 0.03058, 0, 0.75834], 39: [0, 0.69444, 0.07816, 0, 0.27778], 40: [0.25, 0.75, 0.13164, 0, 0.38889], 41: [0.25, 0.75, 0.02536, 0, 0.38889], 42: [0, 0.75, 0.11775, 0, 0.5], 43: [0.08333, 0.58333, 0.02536, 0, 0.77778], 44: [0.125, 0.08333, 0, 0, 0.27778], 45: [0, 0.44444, 0.01946, 0, 0.33333], 46: [0, 0.08333, 0, 0, 0.27778], 47: [0.25, 0.75, 0.13164, 0, 0.5], 48: [0, 0.65556, 0.11156, 0, 0.5], 49: [0, 0.65556, 0.11156, 0, 0.5], 50: [0, 0.65556, 0.11156, 0, 0.5], 51: [0, 0.65556, 0.11156, 0, 0.5], 52: [0, 0.65556, 0.11156, 0, 0.5], 53: [0, 0.65556, 0.11156, 0, 0.5], 54: [0, 0.65556, 0.11156, 0, 0.5], 55: [0, 0.65556, 0.11156, 0, 0.5], 56: [0, 0.65556, 0.11156, 0, 0.5], 57: [0, 0.65556, 0.11156, 0, 0.5], 58: [0, 0.44444, 0.02502, 0, 0.27778], 59: [0.125, 0.44444, 0.02502, 0, 0.27778], 61: [-0.13, 0.37, 0.05087, 0, 0.77778], 63: [0, 0.69444, 0.11809, 0, 0.47222], 64: [0, 0.69444, 0.07555, 0, 0.66667], 65: [0, 0.69444, 0, 0, 0.66667], 66: [0, 0.69444, 0.08293, 0, 0.66667], 67: [0, 0.69444, 0.11983, 0, 0.63889], 68: [0, 0.69444, 0.07555, 0, 0.72223], 69: [0, 0.69444, 0.11983, 0, 0.59722], 70: [0, 0.69444, 0.13372, 0, 0.56945], 71: [0, 0.69444, 0.11983, 0, 0.66667], 72: [0, 0.69444, 0.08094, 0, 0.70834], 73: [0, 0.69444, 0.13372, 0, 0.27778], 74: [0, 0.69444, 0.08094, 0, 0.47222], 75: [0, 0.69444, 0.11983, 0, 0.69445], 76: [0, 0.69444, 0, 0, 0.54167], 77: [0, 0.69444, 0.08094, 0, 0.875], 78: [0, 0.69444, 0.08094, 0, 0.70834], 79: [0, 0.69444, 0.07555, 0, 0.73611], 80: [0, 0.69444, 0.08293, 0, 0.63889], 81: [0.125, 0.69444, 0.07555, 0, 0.73611], 82: [0, 0.69444, 0.08293, 0, 0.64584], 83: [0, 0.69444, 0.09205, 0, 0.55556], 84: [0, 0.69444, 0.13372, 0, 0.68056], 85: [0, 0.69444, 0.08094, 0, 0.6875], 86: [0, 0.69444, 0.1615, 0, 0.66667], 87: [0, 0.69444, 0.1615, 0, 0.94445], 88: [0, 0.69444, 0.13372, 0, 0.66667], 89: [0, 0.69444, 0.17261, 0, 0.66667], 90: [0, 0.69444, 0.11983, 0, 0.61111], 91: [0.25, 0.75, 0.15942, 0, 0.28889], 93: [0.25, 0.75, 0.08719, 0, 0.28889], 94: [0, 0.69444, 0.0799, 0, 0.5], 95: [0.35, 0.09444, 0.08616, 0, 0.5], 97: [0, 0.44444, 981e-5, 0, 0.48056], 98: [0, 0.69444, 0.03057, 0, 0.51667], 99: [0, 0.44444, 0.08336, 0, 0.44445], 100: [0, 0.69444, 0.09483, 0, 0.51667], 101: [0, 0.44444, 0.06778, 0, 0.44445], 102: [0, 0.69444, 0.21705, 0, 0.30556], 103: [0.19444, 0.44444, 0.10836, 0, 0.5], 104: [0, 0.69444, 0.01778, 0, 0.51667], 105: [0, 0.67937, 0.09718, 0, 0.23889], 106: [0.19444, 0.67937, 0.09162, 0, 0.26667], 107: [0, 0.69444, 0.08336, 0, 0.48889], 108: [0, 0.69444, 0.09483, 0, 0.23889], 109: [0, 0.44444, 0.01778, 0, 0.79445], 110: [0, 0.44444, 0.01778, 0, 0.51667], 111: [0, 0.44444, 0.06613, 0, 0.5], 112: [0.19444, 0.44444, 0.0389, 0, 0.51667], 113: [0.19444, 0.44444, 0.04169, 0, 0.51667], 114: [0, 0.44444, 0.10836, 0, 0.34167], 115: [0, 0.44444, 0.0778, 0, 0.38333], 116: [0, 0.57143, 0.07225, 0, 0.36111], 117: [0, 0.44444, 0.04169, 0, 0.51667], 118: [0, 0.44444, 0.10836, 0, 0.46111], 119: [0, 0.44444, 0.10836, 0, 0.68334], 120: [0, 0.44444, 0.09169, 0, 0.46111], 121: [0.19444, 0.44444, 0.10836, 0, 0.46111], 122: [0, 0.44444, 0.08752, 0, 0.43472], 126: [0.35, 0.32659, 0.08826, 0, 0.5], 160: [0, 0, 0, 0, 0.25], 168: [0, 0.67937, 0.06385, 0, 0.5], 176: [0, 0.69444, 0, 0, 0.73752], 184: [0.17014, 0, 0, 0, 0.44445], 305: [0, 0.44444, 0.04169, 0, 0.23889], 567: [0.19444, 0.44444, 0.04169, 0, 0.26667], 710: [0, 0.69444, 0.0799, 0, 0.5], 711: [0, 0.63194, 0.08432, 0, 0.5], 713: [0, 0.60889, 0.08776, 0, 0.5], 714: [0, 0.69444, 0.09205, 0, 0.5], 715: [0, 0.69444, 0, 0, 0.5], 728: [0, 0.69444, 0.09483, 0, 0.5], 729: [0, 0.67937, 0.07774, 0, 0.27778], 730: [0, 0.69444, 0, 0, 0.73752], 732: [0, 0.67659, 0.08826, 0, 0.5], 733: [0, 0.69444, 0.09205, 0, 0.5], 915: [0, 0.69444, 0.13372, 0, 0.54167], 916: [0, 0.69444, 0, 0, 0.83334], 920: [0, 0.69444, 0.07555, 0, 0.77778], 923: [0, 0.69444, 0, 0, 0.61111], 926: [0, 0.69444, 0.12816, 0, 0.66667], 928: [0, 0.69444, 0.08094, 0, 0.70834], 931: [0, 0.69444, 0.11983, 0, 0.72222], 933: [0, 0.69444, 0.09031, 0, 0.77778], 934: [0, 0.69444, 0.04603, 0, 0.72222], 936: [0, 0.69444, 0.09031, 0, 0.77778], 937: [0, 0.69444, 0.08293, 0, 0.72222], 8211: [0, 0.44444, 0.08616, 0, 0.5], 8212: [0, 0.44444, 0.08616, 0, 1], 8216: [0, 0.69444, 0.07816, 0, 0.27778], 8217: [0, 0.69444, 0.07816, 0, 0.27778], 8220: [0, 0.69444, 0.14205, 0, 0.5], 8221: [0, 0.69444, 316e-5, 0, 0.5] }, "SansSerif-Regular": { 32: [0, 0, 0, 0, 0.25], 33: [0, 0.69444, 0, 0, 0.31945], 34: [0, 0.69444, 0, 0, 0.5], 35: [0.19444, 0.69444, 0, 0, 0.83334], 36: [0.05556, 0.75, 0, 0, 0.5], 37: [0.05556, 0.75, 0, 0, 0.83334], 38: [0, 0.69444, 0, 0, 0.75834], 39: [0, 0.69444, 0, 0, 0.27778], 40: [0.25, 0.75, 0, 0, 0.38889], 41: [0.25, 0.75, 0, 0, 0.38889], 42: [0, 0.75, 0, 0, 0.5], 43: [0.08333, 0.58333, 0, 0, 0.77778], 44: [0.125, 0.08333, 0, 0, 0.27778], 45: [0, 0.44444, 0, 0, 0.33333], 46: [0, 0.08333, 0, 0, 0.27778], 47: [0.25, 0.75, 0, 0, 0.5], 48: [0, 0.65556, 0, 0, 0.5], 49: [0, 0.65556, 0, 0, 0.5], 50: [0, 0.65556, 0, 0, 0.5], 51: [0, 0.65556, 0, 0, 0.5], 52: [0, 0.65556, 0, 0, 0.5], 53: [0, 0.65556, 0, 0, 0.5], 54: [0, 0.65556, 0, 0, 0.5], 55: [0, 0.65556, 0, 0, 0.5], 56: [0, 0.65556, 0, 0, 0.5], 57: [0, 0.65556, 0, 0, 0.5], 58: [0, 0.44444, 0, 0, 0.27778], 59: [0.125, 0.44444, 0, 0, 0.27778], 61: [-0.13, 0.37, 0, 0, 0.77778], 63: [0, 0.69444, 0, 0, 0.47222], 64: [0, 0.69444, 0, 0, 0.66667], 65: [0, 0.69444, 0, 0, 0.66667], 66: [0, 0.69444, 0, 0, 0.66667], 67: [0, 0.69444, 0, 0, 0.63889], 68: [0, 0.69444, 0, 0, 0.72223], 69: [0, 0.69444, 0, 0, 0.59722], 70: [0, 0.69444, 0, 0, 0.56945], 71: [0, 0.69444, 0, 0, 0.66667], 72: [0, 0.69444, 0, 0, 0.70834], 73: [0, 0.69444, 0, 0, 0.27778], 74: [0, 0.69444, 0, 0, 0.47222], 75: [0, 0.69444, 0, 0, 0.69445], 76: [0, 0.69444, 0, 0, 0.54167], 77: [0, 0.69444, 0, 0, 0.875], 78: [0, 0.69444, 0, 0, 0.70834], 79: [0, 0.69444, 0, 0, 0.73611], 80: [0, 0.69444, 0, 0, 0.63889], 81: [0.125, 0.69444, 0, 0, 0.73611], 82: [0, 0.69444, 0, 0, 0.64584], 83: [0, 0.69444, 0, 0, 0.55556], 84: [0, 0.69444, 0, 0, 0.68056], 85: [0, 0.69444, 0, 0, 0.6875], 86: [0, 0.69444, 0.01389, 0, 0.66667], 87: [0, 0.69444, 0.01389, 0, 0.94445], 88: [0, 0.69444, 0, 0, 0.66667], 89: [0, 0.69444, 0.025, 0, 0.66667], 90: [0, 0.69444, 0, 0, 0.61111], 91: [0.25, 0.75, 0, 0, 0.28889], 93: [0.25, 0.75, 0, 0, 0.28889], 94: [0, 0.69444, 0, 0, 0.5], 95: [0.35, 0.09444, 0.02778, 0, 0.5], 97: [0, 0.44444, 0, 0, 0.48056], 98: [0, 0.69444, 0, 0, 0.51667], 99: [0, 0.44444, 0, 0, 0.44445], 100: [0, 0.69444, 0, 0, 0.51667], 101: [0, 0.44444, 0, 0, 0.44445], 102: [0, 0.69444, 0.06944, 0, 0.30556], 103: [0.19444, 0.44444, 0.01389, 0, 0.5], 104: [0, 0.69444, 0, 0, 0.51667], 105: [0, 0.67937, 0, 0, 0.23889], 106: [0.19444, 0.67937, 0, 0, 0.26667], 107: [0, 0.69444, 0, 0, 0.48889], 108: [0, 0.69444, 0, 0, 0.23889], 109: [0, 0.44444, 0, 0, 0.79445], 110: [0, 0.44444, 0, 0, 0.51667], 111: [0, 0.44444, 0, 0, 0.5], 112: [0.19444, 0.44444, 0, 0, 0.51667], 113: [0.19444, 0.44444, 0, 0, 0.51667], 114: [0, 0.44444, 0.01389, 0, 0.34167], 115: [0, 0.44444, 0, 0, 0.38333], 116: [0, 0.57143, 0, 0, 0.36111], 117: [0, 0.44444, 0, 0, 0.51667], 118: [0, 0.44444, 0.01389, 0, 0.46111], 119: [0, 0.44444, 0.01389, 0, 0.68334], 120: [0, 0.44444, 0, 0, 0.46111], 121: [0.19444, 0.44444, 0.01389, 0, 0.46111], 122: [0, 0.44444, 0, 0, 0.43472], 126: [0.35, 0.32659, 0, 0, 0.5], 160: [0, 0, 0, 0, 0.25], 168: [0, 0.67937, 0, 0, 0.5], 176: [0, 0.69444, 0, 0, 0.66667], 184: [0.17014, 0, 0, 0, 0.44445], 305: [0, 0.44444, 0, 0, 0.23889], 567: [0.19444, 0.44444, 0, 0, 0.26667], 710: [0, 0.69444, 0, 0, 0.5], 711: [0, 0.63194, 0, 0, 0.5], 713: [0, 0.60889, 0, 0, 0.5], 714: [0, 0.69444, 0, 0, 0.5], 715: [0, 0.69444, 0, 0, 0.5], 728: [0, 0.69444, 0, 0, 0.5], 729: [0, 0.67937, 0, 0, 0.27778], 730: [0, 0.69444, 0, 0, 0.66667], 732: [0, 0.67659, 0, 0, 0.5], 733: [0, 0.69444, 0, 0, 0.5], 915: [0, 0.69444, 0, 0, 0.54167], 916: [0, 0.69444, 0, 0, 0.83334], 920: [0, 0.69444, 0, 0, 0.77778], 923: [0, 0.69444, 0, 0, 0.61111], 926: [0, 0.69444, 0, 0, 0.66667], 928: [0, 0.69444, 0, 0, 0.70834], 931: [0, 0.69444, 0, 0, 0.72222], 933: [0, 0.69444, 0, 0, 0.77778], 934: [0, 0.69444, 0, 0, 0.72222], 936: [0, 0.69444, 0, 0, 0.77778], 937: [0, 0.69444, 0, 0, 0.72222], 8211: [0, 0.44444, 0.02778, 0, 0.5], 8212: [0, 0.44444, 0.02778, 0, 1], 8216: [0, 0.69444, 0, 0, 0.27778], 8217: [0, 0.69444, 0, 0, 0.27778], 8220: [0, 0.69444, 0, 0, 0.5], 8221: [0, 0.69444, 0, 0, 0.5] }, "Script-Regular": { 32: [0, 0, 0, 0, 0.25], 65: [0, 0.7, 0.22925, 0, 0.80253], 66: [0, 0.7, 0.04087, 0, 0.90757], 67: [0, 0.7, 0.1689, 0, 0.66619], 68: [0, 0.7, 0.09371, 0, 0.77443], 69: [0, 0.7, 0.18583, 0, 0.56162], 70: [0, 0.7, 0.13634, 0, 0.89544], 71: [0, 0.7, 0.17322, 0, 0.60961], 72: [0, 0.7, 0.29694, 0, 0.96919], 73: [0, 0.7, 0.19189, 0, 0.80907], 74: [0.27778, 0.7, 0.19189, 0, 1.05159], 75: [0, 0.7, 0.31259, 0, 0.91364], 76: [0, 0.7, 0.19189, 0, 0.87373], 77: [0, 0.7, 0.15981, 0, 1.08031], 78: [0, 0.7, 0.3525, 0, 0.9015], 79: [0, 0.7, 0.08078, 0, 0.73787], 80: [0, 0.7, 0.08078, 0, 1.01262], 81: [0, 0.7, 0.03305, 0, 0.88282], 82: [0, 0.7, 0.06259, 0, 0.85], 83: [0, 0.7, 0.19189, 0, 0.86767], 84: [0, 0.7, 0.29087, 0, 0.74697], 85: [0, 0.7, 0.25815, 0, 0.79996], 86: [0, 0.7, 0.27523, 0, 0.62204], 87: [0, 0.7, 0.27523, 0, 0.80532], 88: [0, 0.7, 0.26006, 0, 0.94445], 89: [0, 0.7, 0.2939, 0, 0.70961], 90: [0, 0.7, 0.24037, 0, 0.8212], 160: [0, 0, 0, 0, 0.25] }, "Size1-Regular": { 32: [0, 0, 0, 0, 0.25], 40: [0.35001, 0.85, 0, 0, 0.45834], 41: [0.35001, 0.85, 0, 0, 0.45834], 47: [0.35001, 0.85, 0, 0, 0.57778], 91: [0.35001, 0.85, 0, 0, 0.41667], 92: [0.35001, 0.85, 0, 0, 0.57778], 93: [0.35001, 0.85, 0, 0, 0.41667], 123: [0.35001, 0.85, 0, 0, 0.58334], 125: [0.35001, 0.85, 0, 0, 0.58334], 160: [0, 0, 0, 0, 0.25], 710: [0, 0.72222, 0, 0, 0.55556], 732: [0, 0.72222, 0, 0, 0.55556], 770: [0, 0.72222, 0, 0, 0.55556], 771: [0, 0.72222, 0, 0, 0.55556], 8214: [-99e-5, 0.601, 0, 0, 0.77778], 8593: [1e-5, 0.6, 0, 0, 0.66667], 8595: [1e-5, 0.6, 0, 0, 0.66667], 8657: [1e-5, 0.6, 0, 0, 0.77778], 8659: [1e-5, 0.6, 0, 0, 0.77778], 8719: [0.25001, 0.75, 0, 0, 0.94445], 8720: [0.25001, 0.75, 0, 0, 0.94445], 8721: [0.25001, 0.75, 0, 0, 1.05556], 8730: [0.35001, 0.85, 0, 0, 1], 8739: [-599e-5, 0.606, 0, 0, 0.33333], 8741: [-599e-5, 0.606, 0, 0, 0.55556], 8747: [0.30612, 0.805, 0.19445, 0, 0.47222], 8748: [0.306, 0.805, 0.19445, 0, 0.47222], 8749: [0.306, 0.805, 0.19445, 0, 0.47222], 8750: [0.30612, 0.805, 0.19445, 0, 0.47222], 8896: [0.25001, 0.75, 0, 0, 0.83334], 8897: [0.25001, 0.75, 0, 0, 0.83334], 8898: [0.25001, 0.75, 0, 0, 0.83334], 8899: [0.25001, 0.75, 0, 0, 0.83334], 8968: [0.35001, 0.85, 0, 0, 0.47222], 8969: [0.35001, 0.85, 0, 0, 0.47222], 8970: [0.35001, 0.85, 0, 0, 0.47222], 8971: [0.35001, 0.85, 0, 0, 0.47222], 9168: [-99e-5, 0.601, 0, 0, 0.66667], 10216: [0.35001, 0.85, 0, 0, 0.47222], 10217: [0.35001, 0.85, 0, 0, 0.47222], 10752: [0.25001, 0.75, 0, 0, 1.11111], 10753: [0.25001, 0.75, 0, 0, 1.11111], 10754: [0.25001, 0.75, 0, 0, 1.11111], 10756: [0.25001, 0.75, 0, 0, 0.83334], 10758: [0.25001, 0.75, 0, 0, 0.83334] }, "Size2-Regular": { 32: [0, 0, 0, 0, 0.25], 40: [0.65002, 1.15, 0, 0, 0.59722], 41: [0.65002, 1.15, 0, 0, 0.59722], 47: [0.65002, 1.15, 0, 0, 0.81111], 91: [0.65002, 1.15, 0, 0, 0.47222], 92: [0.65002, 1.15, 0, 0, 0.81111], 93: [0.65002, 1.15, 0, 0, 0.47222], 123: [0.65002, 1.15, 0, 0, 0.66667], 125: [0.65002, 1.15, 0, 0, 0.66667], 160: [0, 0, 0, 0, 0.25], 710: [0, 0.75, 0, 0, 1], 732: [0, 0.75, 0, 0, 1], 770: [0, 0.75, 0, 0, 1], 771: [0, 0.75, 0, 0, 1], 8719: [0.55001, 1.05, 0, 0, 1.27778], 8720: [0.55001, 1.05, 0, 0, 1.27778], 8721: [0.55001, 1.05, 0, 0, 1.44445], 8730: [0.65002, 1.15, 0, 0, 1], 8747: [0.86225, 1.36, 0.44445, 0, 0.55556], 8748: [0.862, 1.36, 0.44445, 0, 0.55556], 8749: [0.862, 1.36, 0.44445, 0, 0.55556], 8750: [0.86225, 1.36, 0.44445, 0, 0.55556], 8896: [0.55001, 1.05, 0, 0, 1.11111], 8897: [0.55001, 1.05, 0, 0, 1.11111], 8898: [0.55001, 1.05, 0, 0, 1.11111], 8899: [0.55001, 1.05, 0, 0, 1.11111], 8968: [0.65002, 1.15, 0, 0, 0.52778], 8969: [0.65002, 1.15, 0, 0, 0.52778], 8970: [0.65002, 1.15, 0, 0, 0.52778], 8971: [0.65002, 1.15, 0, 0, 0.52778], 10216: [0.65002, 1.15, 0, 0, 0.61111], 10217: [0.65002, 1.15, 0, 0, 0.61111], 10752: [0.55001, 1.05, 0, 0, 1.51112], 10753: [0.55001, 1.05, 0, 0, 1.51112], 10754: [0.55001, 1.05, 0, 0, 1.51112], 10756: [0.55001, 1.05, 0, 0, 1.11111], 10758: [0.55001, 1.05, 0, 0, 1.11111] }, "Size3-Regular": { 32: [0, 0, 0, 0, 0.25], 40: [0.95003, 1.45, 0, 0, 0.73611], 41: [0.95003, 1.45, 0, 0, 0.73611], 47: [0.95003, 1.45, 0, 0, 1.04445], 91: [0.95003, 1.45, 0, 0, 0.52778], 92: [0.95003, 1.45, 0, 0, 1.04445], 93: [0.95003, 1.45, 0, 0, 0.52778], 123: [0.95003, 1.45, 0, 0, 0.75], 125: [0.95003, 1.45, 0, 0, 0.75], 160: [0, 0, 0, 0, 0.25], 710: [0, 0.75, 0, 0, 1.44445], 732: [0, 0.75, 0, 0, 1.44445], 770: [0, 0.75, 0, 0, 1.44445], 771: [0, 0.75, 0, 0, 1.44445], 8730: [0.95003, 1.45, 0, 0, 1], 8968: [0.95003, 1.45, 0, 0, 0.58334], 8969: [0.95003, 1.45, 0, 0, 0.58334], 8970: [0.95003, 1.45, 0, 0, 0.58334], 8971: [0.95003, 1.45, 0, 0, 0.58334], 10216: [0.95003, 1.45, 0, 0, 0.75], 10217: [0.95003, 1.45, 0, 0, 0.75] }, "Size4-Regular": { 32: [0, 0, 0, 0, 0.25], 40: [1.25003, 1.75, 0, 0, 0.79167], 41: [1.25003, 1.75, 0, 0, 0.79167], 47: [1.25003, 1.75, 0, 0, 1.27778], 91: [1.25003, 1.75, 0, 0, 0.58334], 92: [1.25003, 1.75, 0, 0, 1.27778], 93: [1.25003, 1.75, 0, 0, 0.58334], 123: [1.25003, 1.75, 0, 0, 0.80556], 125: [1.25003, 1.75, 0, 0, 0.80556], 160: [0, 0, 0, 0, 0.25], 710: [0, 0.825, 0, 0, 1.8889], 732: [0, 0.825, 0, 0, 1.8889], 770: [0, 0.825, 0, 0, 1.8889], 771: [0, 0.825, 0, 0, 1.8889], 8730: [1.25003, 1.75, 0, 0, 1], 8968: [1.25003, 1.75, 0, 0, 0.63889], 8969: [1.25003, 1.75, 0, 0, 0.63889], 8970: [1.25003, 1.75, 0, 0, 0.63889], 8971: [1.25003, 1.75, 0, 0, 0.63889], 9115: [0.64502, 1.155, 0, 0, 0.875], 9116: [1e-5, 0.6, 0, 0, 0.875], 9117: [0.64502, 1.155, 0, 0, 0.875], 9118: [0.64502, 1.155, 0, 0, 0.875], 9119: [1e-5, 0.6, 0, 0, 0.875], 9120: [0.64502, 1.155, 0, 0, 0.875], 9121: [0.64502, 1.155, 0, 0, 0.66667], 9122: [-99e-5, 0.601, 0, 0, 0.66667], 9123: [0.64502, 1.155, 0, 0, 0.66667], 9124: [0.64502, 1.155, 0, 0, 0.66667], 9125: [-99e-5, 0.601, 0, 0, 0.66667], 9126: [0.64502, 1.155, 0, 0, 0.66667], 9127: [1e-5, 0.9, 0, 0, 0.88889], 9128: [0.65002, 1.15, 0, 0, 0.88889], 9129: [0.90001, 0, 0, 0, 0.88889], 9130: [0, 0.3, 0, 0, 0.88889], 9131: [1e-5, 0.9, 0, 0, 0.88889], 9132: [0.65002, 1.15, 0, 0, 0.88889], 9133: [0.90001, 0, 0, 0, 0.88889], 9143: [0.88502, 0.915, 0, 0, 1.05556], 10216: [1.25003, 1.75, 0, 0, 0.80556], 10217: [1.25003, 1.75, 0, 0, 0.80556], 57344: [-499e-5, 0.605, 0, 0, 1.05556], 57345: [-499e-5, 0.605, 0, 0, 1.05556], 57680: [0, 0.12, 0, 0, 0.45], 57681: [0, 0.12, 0, 0, 0.45], 57682: [0, 0.12, 0, 0, 0.45], 57683: [0, 0.12, 0, 0, 0.45] }, "Typewriter-Regular": { 32: [0, 0, 0, 0, 0.525], 33: [0, 0.61111, 0, 0, 0.525], 34: [0, 0.61111, 0, 0, 0.525], 35: [0, 0.61111, 0, 0, 0.525], 36: [0.08333, 0.69444, 0, 0, 0.525], 37: [0.08333, 0.69444, 0, 0, 0.525], 38: [0, 0.61111, 0, 0, 0.525], 39: [0, 0.61111, 0, 0, 0.525], 40: [0.08333, 0.69444, 0, 0, 0.525], 41: [0.08333, 0.69444, 0, 0, 0.525], 42: [0, 0.52083, 0, 0, 0.525], 43: [-0.08056, 0.53055, 0, 0, 0.525], 44: [0.13889, 0.125, 0, 0, 0.525], 45: [-0.08056, 0.53055, 0, 0, 0.525], 46: [0, 0.125, 0, 0, 0.525], 47: [0.08333, 0.69444, 0, 0, 0.525], 48: [0, 0.61111, 0, 0, 0.525], 49: [0, 0.61111, 0, 0, 0.525], 50: [0, 0.61111, 0, 0, 0.525], 51: [0, 0.61111, 0, 0, 0.525], 52: [0, 0.61111, 0, 0, 0.525], 53: [0, 0.61111, 0, 0, 0.525], 54: [0, 0.61111, 0, 0, 0.525], 55: [0, 0.61111, 0, 0, 0.525], 56: [0, 0.61111, 0, 0, 0.525], 57: [0, 0.61111, 0, 0, 0.525], 58: [0, 0.43056, 0, 0, 0.525], 59: [0.13889, 0.43056, 0, 0, 0.525], 60: [-0.05556, 0.55556, 0, 0, 0.525], 61: [-0.19549, 0.41562, 0, 0, 0.525], 62: [-0.05556, 0.55556, 0, 0, 0.525], 63: [0, 0.61111, 0, 0, 0.525], 64: [0, 0.61111, 0, 0, 0.525], 65: [0, 0.61111, 0, 0, 0.525], 66: [0, 0.61111, 0, 0, 0.525], 67: [0, 0.61111, 0, 0, 0.525], 68: [0, 0.61111, 0, 0, 0.525], 69: [0, 0.61111, 0, 0, 0.525], 70: [0, 0.61111, 0, 0, 0.525], 71: [0, 0.61111, 0, 0, 0.525], 72: [0, 0.61111, 0, 0, 0.525], 73: [0, 0.61111, 0, 0, 0.525], 74: [0, 0.61111, 0, 0, 0.525], 75: [0, 0.61111, 0, 0, 0.525], 76: [0, 0.61111, 0, 0, 0.525], 77: [0, 0.61111, 0, 0, 0.525], 78: [0, 0.61111, 0, 0, 0.525], 79: [0, 0.61111, 0, 0, 0.525], 80: [0, 0.61111, 0, 0, 0.525], 81: [0.13889, 0.61111, 0, 0, 0.525], 82: [0, 0.61111, 0, 0, 0.525], 83: [0, 0.61111, 0, 0, 0.525], 84: [0, 0.61111, 0, 0, 0.525], 85: [0, 0.61111, 0, 0, 0.525], 86: [0, 0.61111, 0, 0, 0.525], 87: [0, 0.61111, 0, 0, 0.525], 88: [0, 0.61111, 0, 0, 0.525], 89: [0, 0.61111, 0, 0, 0.525], 90: [0, 0.61111, 0, 0, 0.525], 91: [0.08333, 0.69444, 0, 0, 0.525], 92: [0.08333, 0.69444, 0, 0, 0.525], 93: [0.08333, 0.69444, 0, 0, 0.525], 94: [0, 0.61111, 0, 0, 0.525], 95: [0.09514, 0, 0, 0, 0.525], 96: [0, 0.61111, 0, 0, 0.525], 97: [0, 0.43056, 0, 0, 0.525], 98: [0, 0.61111, 0, 0, 0.525], 99: [0, 0.43056, 0, 0, 0.525], 100: [0, 0.61111, 0, 0, 0.525], 101: [0, 0.43056, 0, 0, 0.525], 102: [0, 0.61111, 0, 0, 0.525], 103: [0.22222, 0.43056, 0, 0, 0.525], 104: [0, 0.61111, 0, 0, 0.525], 105: [0, 0.61111, 0, 0, 0.525], 106: [0.22222, 0.61111, 0, 0, 0.525], 107: [0, 0.61111, 0, 0, 0.525], 108: [0, 0.61111, 0, 0, 0.525], 109: [0, 0.43056, 0, 0, 0.525], 110: [0, 0.43056, 0, 0, 0.525], 111: [0, 0.43056, 0, 0, 0.525], 112: [0.22222, 0.43056, 0, 0, 0.525], 113: [0.22222, 0.43056, 0, 0, 0.525], 114: [0, 0.43056, 0, 0, 0.525], 115: [0, 0.43056, 0, 0, 0.525], 116: [0, 0.55358, 0, 0, 0.525], 117: [0, 0.43056, 0, 0, 0.525], 118: [0, 0.43056, 0, 0, 0.525], 119: [0, 0.43056, 0, 0, 0.525], 120: [0, 0.43056, 0, 0, 0.525], 121: [0.22222, 0.43056, 0, 0, 0.525], 122: [0, 0.43056, 0, 0, 0.525], 123: [0.08333, 0.69444, 0, 0, 0.525], 124: [0.08333, 0.69444, 0, 0, 0.525], 125: [0.08333, 0.69444, 0, 0, 0.525], 126: [0, 0.61111, 0, 0, 0.525], 127: [0, 0.61111, 0, 0, 0.525], 160: [0, 0, 0, 0, 0.525], 176: [0, 0.61111, 0, 0, 0.525], 184: [0.19445, 0, 0, 0, 0.525], 305: [0, 0.43056, 0, 0, 0.525], 567: [0.22222, 0.43056, 0, 0, 0.525], 711: [0, 0.56597, 0, 0, 0.525], 713: [0, 0.56555, 0, 0, 0.525], 714: [0, 0.61111, 0, 0, 0.525], 715: [0, 0.61111, 0, 0, 0.525], 728: [0, 0.61111, 0, 0, 0.525], 730: [0, 0.61111, 0, 0, 0.525], 770: [0, 0.61111, 0, 0, 0.525], 771: [0, 0.61111, 0, 0, 0.525], 776: [0, 0.61111, 0, 0, 0.525], 915: [0, 0.61111, 0, 0, 0.525], 916: [0, 0.61111, 0, 0, 0.525], 920: [0, 0.61111, 0, 0, 0.525], 923: [0, 0.61111, 0, 0, 0.525], 926: [0, 0.61111, 0, 0, 0.525], 928: [0, 0.61111, 0, 0, 0.525], 931: [0, 0.61111, 0, 0, 0.525], 933: [0, 0.61111, 0, 0, 0.525], 934: [0, 0.61111, 0, 0, 0.525], 936: [0, 0.61111, 0, 0, 0.525], 937: [0, 0.61111, 0, 0, 0.525], 8216: [0, 0.61111, 0, 0, 0.525], 8217: [0, 0.61111, 0, 0, 0.525], 8242: [0, 0.61111, 0, 0, 0.525], 9251: [0.11111, 0.21944, 0, 0, 0.525] } };
    const J = { slant: [0.25, 0.25, 0.25], space: [0, 0, 0], stretch: [0, 0, 0], shrink: [0, 0, 0], xHeight: [0.431, 0.431, 0.431], quad: [1, 1.171, 1.472], extraSpace: [0, 0, 0], num1: [0.677, 0.732, 0.925], num2: [0.394, 0.384, 0.387], num3: [0.444, 0.471, 0.504], denom1: [0.686, 0.752, 1.025], denom2: [0.345, 0.344, 0.532], sup1: [0.413, 0.503, 0.504], sup2: [0.363, 0.431, 0.404], sup3: [0.289, 0.286, 0.294], sub1: [0.15, 0.143, 0.2], sub2: [0.247, 0.286, 0.4], supDrop: [0.386, 0.353, 0.494], subDrop: [0.05, 0.071, 0.1], delim1: [2.39, 1.7, 1.98], delim2: [1.01, 1.157, 1.42], axisHeight: [0.25, 0.25, 0.25], defaultRuleThickness: [0.04, 0.049, 0.049], bigOpSpacing1: [0.111, 0.111, 0.111], bigOpSpacing2: [0.166, 0.166, 0.166], bigOpSpacing3: [0.2, 0.2, 0.2], bigOpSpacing4: [0.6, 0.611, 0.611], bigOpSpacing5: [0.1, 0.143, 0.143], sqrtRuleThickness: [0.04, 0.04, 0.04], ptPerEm: [10, 10, 10], doubleRuleSep: [0.2, 0.2, 0.2], arrayRuleWidth: [0.04, 0.04, 0.04], fboxsep: [0.3, 0.3, 0.3], fboxrule: [0.04, 0.04, 0.04] }, Q = { "\xC5": "A", "\xD0": "D", "\xDE": "o", "\xE5": "a", "\xF0": "d", "\xFE": "o", "\u0410": "A", "\u0411": "B", "\u0412": "B", "\u0413": "F", "\u0414": "A", "\u0415": "E", "\u0416": "K", "\u0417": "3", "\u0418": "N", "\u0419": "N", "\u041A": "K", "\u041B": "N", "\u041C": "M", "\u041D": "H", "\u041E": "O", "\u041F": "N", "\u0420": "P", "\u0421": "C", "\u0422": "T", "\u0423": "y", "\u0424": "O", "\u0425": "X", "\u0426": "U", "\u0427": "h", "\u0428": "W", "\u0429": "W", "\u042A": "B", "\u042B": "X", "\u042C": "B", "\u042D": "3", "\u042E": "X", "\u042F": "R", "\u0430": "a", "\u0431": "b", "\u0432": "a", "\u0433": "r", "\u0434": "y", "\u0435": "e", "\u0436": "m", "\u0437": "e", "\u0438": "n", "\u0439": "n", "\u043A": "n", "\u043B": "n", "\u043C": "m", "\u043D": "n", "\u043E": "o", "\u043F": "n", "\u0440": "p", "\u0441": "c", "\u0442": "o", "\u0443": "y", "\u0444": "b", "\u0445": "x", "\u0446": "n", "\u0447": "n", "\u0448": "w", "\u0449": "w", "\u044A": "a", "\u044B": "m", "\u044C": "a", "\u044D": "e", "\u044E": "m", "\u044F": "r" };
    function ee(e2, t2, r2) {
      if (!K[t2]) throw new Error("Font metrics not found for font: " + t2 + ".");
      let n2 = e2.charCodeAt(0), o2 = K[t2][n2];
      if (!o2 && e2[0] in Q && (n2 = Q[e2[0]].charCodeAt(0), o2 = K[t2][n2]), o2 || "text" !== r2 || T(n2) && (o2 = K[t2][77]), o2) return { depth: o2[0], height: o2[1], italic: o2[2], skew: o2[3], width: o2[4] };
    }
    const te = {};
    const re = { math: {}, text: {} };
    var ne = re;
    function oe(e2, t2, r2, n2, o2, s2) {
      re[e2][o2] = { font: t2, group: r2, replace: n2 }, s2 && n2 && (re[e2][n2] = re[e2][o2]);
    }
    const se = "math", ie = "text", le = "main", ae = "ams", ce = "accent-token", he = "bin", me = "close", ue = "inner", pe = "mathord", de = "op-token", ge = "open", fe = "punct", be = "rel", ye = "spacing", xe = "textord";
    oe(se, le, be, "\u2261", "\\equiv", true), oe(se, le, be, "\u227A", "\\prec", true), oe(se, le, be, "\u227B", "\\succ", true), oe(se, le, be, "\u223C", "\\sim", true), oe(se, le, be, "\u22A5", "\\perp"), oe(se, le, be, "\u2AAF", "\\preceq", true), oe(se, le, be, "\u2AB0", "\\succeq", true), oe(se, le, be, "\u2243", "\\simeq", true), oe(se, le, be, "\u2223", "\\mid", true), oe(se, le, be, "\u226A", "\\ll", true), oe(se, le, be, "\u226B", "\\gg", true), oe(se, le, be, "\u224D", "\\asymp", true), oe(se, le, be, "\u2225", "\\parallel"), oe(se, le, be, "\u22C8", "\\bowtie", true), oe(se, le, be, "\u2323", "\\smile", true), oe(se, le, be, "\u2291", "\\sqsubseteq", true), oe(se, le, be, "\u2292", "\\sqsupseteq", true), oe(se, le, be, "\u2250", "\\doteq", true), oe(se, le, be, "\u2322", "\\frown", true), oe(se, le, be, "\u220B", "\\ni", true), oe(se, le, be, "\u221D", "\\propto", true), oe(se, le, be, "\u22A2", "\\vdash", true), oe(se, le, be, "\u22A3", "\\dashv", true), oe(se, le, be, "\u220B", "\\owns"), oe(se, le, fe, ".", "\\ldotp"), oe(se, le, fe, "\u22C5", "\\cdotp"), oe(se, le, fe, "\u22C5", "\xB7"), oe(ie, le, xe, "\u22C5", "\xB7"), oe(se, le, xe, "#", "\\#"), oe(ie, le, xe, "#", "\\#"), oe(se, le, xe, "&", "\\&"), oe(ie, le, xe, "&", "\\&"), oe(se, le, xe, "\u2135", "\\aleph", true), oe(se, le, xe, "\u2200", "\\forall", true), oe(se, le, xe, "\u210F", "\\hbar", true), oe(se, le, xe, "\u2203", "\\exists", true), oe(se, le, xe, "\u2207", "\\nabla", true), oe(se, le, xe, "\u266D", "\\flat", true), oe(se, le, xe, "\u2113", "\\ell", true), oe(se, le, xe, "\u266E", "\\natural", true), oe(se, le, xe, "\u2663", "\\clubsuit", true), oe(se, le, xe, "\u2118", "\\wp", true), oe(se, le, xe, "\u266F", "\\sharp", true), oe(se, le, xe, "\u2662", "\\diamondsuit", true), oe(se, le, xe, "\u211C", "\\Re", true), oe(se, le, xe, "\u2661", "\\heartsuit", true), oe(se, le, xe, "\u2111", "\\Im", true), oe(se, le, xe, "\u2660", "\\spadesuit", true), oe(se, le, xe, "\xA7", "\\S", true), oe(ie, le, xe, "\xA7", "\\S"), oe(se, le, xe, "\xB6", "\\P", true), oe(ie, le, xe, "\xB6", "\\P"), oe(se, le, xe, "\u2020", "\\dag"), oe(ie, le, xe, "\u2020", "\\dag"), oe(ie, le, xe, "\u2020", "\\textdagger"), oe(se, le, xe, "\u2021", "\\ddag"), oe(ie, le, xe, "\u2021", "\\ddag"), oe(ie, le, xe, "\u2021", "\\textdaggerdbl"), oe(se, le, me, "\u23B1", "\\rmoustache", true), oe(se, le, ge, "\u23B0", "\\lmoustache", true), oe(se, le, me, "\u27EF", "\\rgroup", true), oe(se, le, ge, "\u27EE", "\\lgroup", true), oe(se, le, he, "\u2213", "\\mp", true), oe(se, le, he, "\u2296", "\\ominus", true), oe(se, le, he, "\u228E", "\\uplus", true), oe(se, le, he, "\u2293", "\\sqcap", true), oe(se, le, he, "\u2217", "\\ast"), oe(se, le, he, "\u2294", "\\sqcup", true), oe(se, le, he, "\u25EF", "\\bigcirc", true), oe(se, le, he, "\u2219", "\\bullet", true), oe(se, le, he, "\u2021", "\\ddagger"), oe(se, le, he, "\u2240", "\\wr", true), oe(se, le, he, "\u2A3F", "\\amalg"), oe(se, le, he, "&", "\\And"), oe(se, le, be, "\u27F5", "\\longleftarrow", true), oe(se, le, be, "\u21D0", "\\Leftarrow", true), oe(se, le, be, "\u27F8", "\\Longleftarrow", true), oe(se, le, be, "\u27F6", "\\longrightarrow", true), oe(se, le, be, "\u21D2", "\\Rightarrow", true), oe(se, le, be, "\u27F9", "\\Longrightarrow", true), oe(se, le, be, "\u2194", "\\leftrightarrow", true), oe(se, le, be, "\u27F7", "\\longleftrightarrow", true), oe(se, le, be, "\u21D4", "\\Leftrightarrow", true), oe(se, le, be, "\u27FA", "\\Longleftrightarrow", true), oe(se, le, be, "\u21A6", "\\mapsto", true), oe(se, le, be, "\u27FC", "\\longmapsto", true), oe(se, le, be, "\u2197", "\\nearrow", true), oe(se, le, be, "\u21A9", "\\hookleftarrow", true), oe(se, le, be, "\u21AA", "\\hookrightarrow", true), oe(se, le, be, "\u2198", "\\searrow", true), oe(se, le, be, "\u21BC", "\\leftharpoonup", true), oe(se, le, be, "\u21C0", "\\rightharpoonup", true), oe(se, le, be, "\u2199", "\\swarrow", true), oe(se, le, be, "\u21BD", "\\leftharpoondown", true), oe(se, le, be, "\u21C1", "\\rightharpoondown", true), oe(se, le, be, "\u2196", "\\nwarrow", true), oe(se, le, be, "\u21CC", "\\rightleftharpoons", true), oe(se, ae, be, "\u226E", "\\nless", true), oe(se, ae, be, "\uE010", "\\@nleqslant"), oe(se, ae, be, "\uE011", "\\@nleqq"), oe(se, ae, be, "\u2A87", "\\lneq", true), oe(se, ae, be, "\u2268", "\\lneqq", true), oe(se, ae, be, "\uE00C", "\\@lvertneqq"), oe(se, ae, be, "\u22E6", "\\lnsim", true), oe(se, ae, be, "\u2A89", "\\lnapprox", true), oe(se, ae, be, "\u2280", "\\nprec", true), oe(se, ae, be, "\u22E0", "\\npreceq", true), oe(se, ae, be, "\u22E8", "\\precnsim", true), oe(se, ae, be, "\u2AB9", "\\precnapprox", true), oe(se, ae, be, "\u2241", "\\nsim", true), oe(se, ae, be, "\uE006", "\\@nshortmid"), oe(se, ae, be, "\u2224", "\\nmid", true), oe(se, ae, be, "\u22AC", "\\nvdash", true), oe(se, ae, be, "\u22AD", "\\nvDash", true), oe(se, ae, be, "\u22EA", "\\ntriangleleft"), oe(se, ae, be, "\u22EC", "\\ntrianglelefteq", true), oe(se, ae, be, "\u228A", "\\subsetneq", true), oe(se, ae, be, "\uE01A", "\\@varsubsetneq"), oe(se, ae, be, "\u2ACB", "\\subsetneqq", true), oe(se, ae, be, "\uE017", "\\@varsubsetneqq"), oe(se, ae, be, "\u226F", "\\ngtr", true), oe(se, ae, be, "\uE00F", "\\@ngeqslant"), oe(se, ae, be, "\uE00E", "\\@ngeqq"), oe(se, ae, be, "\u2A88", "\\gneq", true), oe(se, ae, be, "\u2269", "\\gneqq", true), oe(se, ae, be, "\uE00D", "\\@gvertneqq"), oe(se, ae, be, "\u22E7", "\\gnsim", true), oe(se, ae, be, "\u2A8A", "\\gnapprox", true), oe(se, ae, be, "\u2281", "\\nsucc", true), oe(se, ae, be, "\u22E1", "\\nsucceq", true), oe(se, ae, be, "\u22E9", "\\succnsim", true), oe(se, ae, be, "\u2ABA", "\\succnapprox", true), oe(se, ae, be, "\u2246", "\\ncong", true), oe(se, ae, be, "\uE007", "\\@nshortparallel"), oe(se, ae, be, "\u2226", "\\nparallel", true), oe(se, ae, be, "\u22AF", "\\nVDash", true), oe(se, ae, be, "\u22EB", "\\ntriangleright"), oe(se, ae, be, "\u22ED", "\\ntrianglerighteq", true), oe(se, ae, be, "\uE018", "\\@nsupseteqq"), oe(se, ae, be, "\u228B", "\\supsetneq", true), oe(se, ae, be, "\uE01B", "\\@varsupsetneq"), oe(se, ae, be, "\u2ACC", "\\supsetneqq", true), oe(se, ae, be, "\uE019", "\\@varsupsetneqq"), oe(se, ae, be, "\u22AE", "\\nVdash", true), oe(se, ae, be, "\u2AB5", "\\precneqq", true), oe(se, ae, be, "\u2AB6", "\\succneqq", true), oe(se, ae, be, "\uE016", "\\@nsubseteqq"), oe(se, ae, he, "\u22B4", "\\unlhd"), oe(se, ae, he, "\u22B5", "\\unrhd"), oe(se, ae, be, "\u219A", "\\nleftarrow", true), oe(se, ae, be, "\u219B", "\\nrightarrow", true), oe(se, ae, be, "\u21CD", "\\nLeftarrow", true), oe(se, ae, be, "\u21CF", "\\nRightarrow", true), oe(se, ae, be, "\u21AE", "\\nleftrightarrow", true), oe(se, ae, be, "\u21CE", "\\nLeftrightarrow", true), oe(se, ae, be, "\u25B3", "\\vartriangle"), oe(se, ae, xe, "\u210F", "\\hslash"), oe(se, ae, xe, "\u25BD", "\\triangledown"), oe(se, ae, xe, "\u25CA", "\\lozenge"), oe(se, ae, xe, "\u24C8", "\\circledS"), oe(se, ae, xe, "\xAE", "\\circledR"), oe(ie, ae, xe, "\xAE", "\\circledR"), oe(se, ae, xe, "\u2221", "\\measuredangle", true), oe(se, ae, xe, "\u2204", "\\nexists"), oe(se, ae, xe, "\u2127", "\\mho"), oe(se, ae, xe, "\u2132", "\\Finv", true), oe(se, ae, xe, "\u2141", "\\Game", true), oe(se, ae, xe, "\u2035", "\\backprime"), oe(se, ae, xe, "\u25B2", "\\blacktriangle"), oe(se, ae, xe, "\u25BC", "\\blacktriangledown"), oe(se, ae, xe, "\u25A0", "\\blacksquare"), oe(se, ae, xe, "\u29EB", "\\blacklozenge"), oe(se, ae, xe, "\u2605", "\\bigstar"), oe(se, ae, xe, "\u2222", "\\sphericalangle", true), oe(se, ae, xe, "\u2201", "\\complement", true), oe(se, ae, xe, "\xF0", "\\eth", true), oe(ie, le, xe, "\xF0", "\xF0"), oe(se, ae, xe, "\u2571", "\\diagup"), oe(se, ae, xe, "\u2572", "\\diagdown"), oe(se, ae, xe, "\u25A1", "\\square"), oe(se, ae, xe, "\u25A1", "\\Box"), oe(se, ae, xe, "\u25CA", "\\Diamond"), oe(se, ae, xe, "\xA5", "\\yen", true), oe(ie, ae, xe, "\xA5", "\\yen", true), oe(se, ae, xe, "\u2713", "\\checkmark", true), oe(ie, ae, xe, "\u2713", "\\checkmark"), oe(se, ae, xe, "\u2136", "\\beth", true), oe(se, ae, xe, "\u2138", "\\daleth", true), oe(se, ae, xe, "\u2137", "\\gimel", true), oe(se, ae, xe, "\u03DD", "\\digamma", true), oe(se, ae, xe, "\u03F0", "\\varkappa"), oe(se, ae, ge, "\u250C", "\\@ulcorner", true), oe(se, ae, me, "\u2510", "\\@urcorner", true), oe(se, ae, ge, "\u2514", "\\@llcorner", true), oe(se, ae, me, "\u2518", "\\@lrcorner", true), oe(se, ae, be, "\u2266", "\\leqq", true), oe(se, ae, be, "\u2A7D", "\\leqslant", true), oe(se, ae, be, "\u2A95", "\\eqslantless", true), oe(se, ae, be, "\u2272", "\\lesssim", true), oe(se, ae, be, "\u2A85", "\\lessapprox", true), oe(se, ae, be, "\u224A", "\\approxeq", true), oe(se, ae, he, "\u22D6", "\\lessdot"), oe(se, ae, be, "\u22D8", "\\lll", true), oe(se, ae, be, "\u2276", "\\lessgtr", true), oe(se, ae, be, "\u22DA", "\\lesseqgtr", true), oe(se, ae, be, "\u2A8B", "\\lesseqqgtr", true), oe(se, ae, be, "\u2251", "\\doteqdot"), oe(se, ae, be, "\u2253", "\\risingdotseq", true), oe(se, ae, be, "\u2252", "\\fallingdotseq", true), oe(se, ae, be, "\u223D", "\\backsim", true), oe(se, ae, be, "\u22CD", "\\backsimeq", true), oe(se, ae, be, "\u2AC5", "\\subseteqq", true), oe(se, ae, be, "\u22D0", "\\Subset", true), oe(se, ae, be, "\u228F", "\\sqsubset", true), oe(se, ae, be, "\u227C", "\\preccurlyeq", true), oe(se, ae, be, "\u22DE", "\\curlyeqprec", true), oe(se, ae, be, "\u227E", "\\precsim", true), oe(se, ae, be, "\u2AB7", "\\precapprox", true), oe(se, ae, be, "\u22B2", "\\vartriangleleft"), oe(se, ae, be, "\u22B4", "\\trianglelefteq"), oe(se, ae, be, "\u22A8", "\\vDash", true), oe(se, ae, be, "\u22AA", "\\Vvdash", true), oe(se, ae, be, "\u2323", "\\smallsmile"), oe(se, ae, be, "\u2322", "\\smallfrown"), oe(se, ae, be, "\u224F", "\\bumpeq", true), oe(se, ae, be, "\u224E", "\\Bumpeq", true), oe(se, ae, be, "\u2267", "\\geqq", true), oe(se, ae, be, "\u2A7E", "\\geqslant", true), oe(se, ae, be, "\u2A96", "\\eqslantgtr", true), oe(se, ae, be, "\u2273", "\\gtrsim", true), oe(se, ae, be, "\u2A86", "\\gtrapprox", true), oe(se, ae, he, "\u22D7", "\\gtrdot"), oe(se, ae, be, "\u22D9", "\\ggg", true), oe(se, ae, be, "\u2277", "\\gtrless", true), oe(se, ae, be, "\u22DB", "\\gtreqless", true), oe(se, ae, be, "\u2A8C", "\\gtreqqless", true), oe(se, ae, be, "\u2256", "\\eqcirc", true), oe(se, ae, be, "\u2257", "\\circeq", true), oe(se, ae, be, "\u225C", "\\triangleq", true), oe(se, ae, be, "\u223C", "\\thicksim"), oe(se, ae, be, "\u2248", "\\thickapprox"), oe(se, ae, be, "\u2AC6", "\\supseteqq", true), oe(se, ae, be, "\u22D1", "\\Supset", true), oe(se, ae, be, "\u2290", "\\sqsupset", true), oe(se, ae, be, "\u227D", "\\succcurlyeq", true), oe(se, ae, be, "\u22DF", "\\curlyeqsucc", true), oe(se, ae, be, "\u227F", "\\succsim", true), oe(se, ae, be, "\u2AB8", "\\succapprox", true), oe(se, ae, be, "\u22B3", "\\vartriangleright"), oe(se, ae, be, "\u22B5", "\\trianglerighteq"), oe(se, ae, be, "\u22A9", "\\Vdash", true), oe(se, ae, be, "\u2223", "\\shortmid"), oe(se, ae, be, "\u2225", "\\shortparallel"), oe(se, ae, be, "\u226C", "\\between", true), oe(se, ae, be, "\u22D4", "\\pitchfork", true), oe(se, ae, be, "\u221D", "\\varpropto"), oe(se, ae, be, "\u25C0", "\\blacktriangleleft"), oe(se, ae, be, "\u2234", "\\therefore", true), oe(se, ae, be, "\u220D", "\\backepsilon"), oe(se, ae, be, "\u25B6", "\\blacktriangleright"), oe(se, ae, be, "\u2235", "\\because", true), oe(se, ae, be, "\u22D8", "\\llless"), oe(se, ae, be, "\u22D9", "\\gggtr"), oe(se, ae, he, "\u22B2", "\\lhd"), oe(se, ae, he, "\u22B3", "\\rhd"), oe(se, ae, be, "\u2242", "\\eqsim", true), oe(se, le, be, "\u22C8", "\\Join"), oe(se, ae, be, "\u2251", "\\Doteq", true), oe(se, ae, he, "\u2214", "\\dotplus", true), oe(se, ae, he, "\u2216", "\\smallsetminus"), oe(se, ae, he, "\u22D2", "\\Cap", true), oe(se, ae, he, "\u22D3", "\\Cup", true), oe(se, ae, he, "\u2A5E", "\\doublebarwedge", true), oe(se, ae, he, "\u229F", "\\boxminus", true), oe(se, ae, he, "\u229E", "\\boxplus", true), oe(se, ae, he, "\u22C7", "\\divideontimes", true), oe(se, ae, he, "\u22C9", "\\ltimes", true), oe(se, ae, he, "\u22CA", "\\rtimes", true), oe(se, ae, he, "\u22CB", "\\leftthreetimes", true), oe(se, ae, he, "\u22CC", "\\rightthreetimes", true), oe(se, ae, he, "\u22CF", "\\curlywedge", true), oe(se, ae, he, "\u22CE", "\\curlyvee", true), oe(se, ae, he, "\u229D", "\\circleddash", true), oe(se, ae, he, "\u229B", "\\circledast", true), oe(se, ae, he, "\u22C5", "\\centerdot"), oe(se, ae, he, "\u22BA", "\\intercal", true), oe(se, ae, he, "\u22D2", "\\doublecap"), oe(se, ae, he, "\u22D3", "\\doublecup"), oe(se, ae, he, "\u22A0", "\\boxtimes", true), oe(se, ae, be, "\u21E2", "\\dashrightarrow", true), oe(se, ae, be, "\u21E0", "\\dashleftarrow", true), oe(se, ae, be, "\u21C7", "\\leftleftarrows", true), oe(se, ae, be, "\u21C6", "\\leftrightarrows", true), oe(se, ae, be, "\u21DA", "\\Lleftarrow", true), oe(se, ae, be, "\u219E", "\\twoheadleftarrow", true), oe(se, ae, be, "\u21A2", "\\leftarrowtail", true), oe(se, ae, be, "\u21AB", "\\looparrowleft", true), oe(se, ae, be, "\u21CB", "\\leftrightharpoons", true), oe(se, ae, be, "\u21B6", "\\curvearrowleft", true), oe(se, ae, be, "\u21BA", "\\circlearrowleft", true), oe(se, ae, be, "\u21B0", "\\Lsh", true), oe(se, ae, be, "\u21C8", "\\upuparrows", true), oe(se, ae, be, "\u21BF", "\\upharpoonleft", true), oe(se, ae, be, "\u21C3", "\\downharpoonleft", true), oe(se, le, be, "\u22B6", "\\origof", true), oe(se, le, be, "\u22B7", "\\imageof", true), oe(se, ae, be, "\u22B8", "\\multimap", true), oe(se, ae, be, "\u21AD", "\\leftrightsquigarrow", true), oe(se, ae, be, "\u21C9", "\\rightrightarrows", true), oe(se, ae, be, "\u21C4", "\\rightleftarrows", true), oe(se, ae, be, "\u21A0", "\\twoheadrightarrow", true), oe(se, ae, be, "\u21A3", "\\rightarrowtail", true), oe(se, ae, be, "\u21AC", "\\looparrowright", true), oe(se, ae, be, "\u21B7", "\\curvearrowright", true), oe(se, ae, be, "\u21BB", "\\circlearrowright", true), oe(se, ae, be, "\u21B1", "\\Rsh", true), oe(se, ae, be, "\u21CA", "\\downdownarrows", true), oe(se, ae, be, "\u21BE", "\\upharpoonright", true), oe(se, ae, be, "\u21C2", "\\downharpoonright", true), oe(se, ae, be, "\u21DD", "\\rightsquigarrow", true), oe(se, ae, be, "\u21DD", "\\leadsto"), oe(se, ae, be, "\u21DB", "\\Rrightarrow", true), oe(se, ae, be, "\u21BE", "\\restriction"), oe(se, le, xe, "\u2018", "`"), oe(se, le, xe, "$", "\\$"), oe(ie, le, xe, "$", "\\$"), oe(ie, le, xe, "$", "\\textdollar"), oe(se, le, xe, "%", "\\%"), oe(ie, le, xe, "%", "\\%"), oe(se, le, xe, "_", "\\_"), oe(ie, le, xe, "_", "\\_"), oe(ie, le, xe, "_", "\\textunderscore"), oe(se, le, xe, "\u2220", "\\angle", true), oe(se, le, xe, "\u221E", "\\infty", true), oe(se, le, xe, "\u2032", "\\prime"), oe(se, le, xe, "\u25B3", "\\triangle"), oe(se, le, xe, "\u0393", "\\Gamma", true), oe(se, le, xe, "\u0394", "\\Delta", true), oe(se, le, xe, "\u0398", "\\Theta", true), oe(se, le, xe, "\u039B", "\\Lambda", true), oe(se, le, xe, "\u039E", "\\Xi", true), oe(se, le, xe, "\u03A0", "\\Pi", true), oe(se, le, xe, "\u03A3", "\\Sigma", true), oe(se, le, xe, "\u03A5", "\\Upsilon", true), oe(se, le, xe, "\u03A6", "\\Phi", true), oe(se, le, xe, "\u03A8", "\\Psi", true), oe(se, le, xe, "\u03A9", "\\Omega", true), oe(se, le, xe, "A", "\u0391"), oe(se, le, xe, "B", "\u0392"), oe(se, le, xe, "E", "\u0395"), oe(se, le, xe, "Z", "\u0396"), oe(se, le, xe, "H", "\u0397"), oe(se, le, xe, "I", "\u0399"), oe(se, le, xe, "K", "\u039A"), oe(se, le, xe, "M", "\u039C"), oe(se, le, xe, "N", "\u039D"), oe(se, le, xe, "O", "\u039F"), oe(se, le, xe, "P", "\u03A1"), oe(se, le, xe, "T", "\u03A4"), oe(se, le, xe, "X", "\u03A7"), oe(se, le, xe, "\xAC", "\\neg", true), oe(se, le, xe, "\xAC", "\\lnot"), oe(se, le, xe, "\u22A4", "\\top"), oe(se, le, xe, "\u22A5", "\\bot"), oe(se, le, xe, "\u2205", "\\emptyset"), oe(se, ae, xe, "\u2205", "\\varnothing"), oe(se, le, pe, "\u03B1", "\\alpha", true), oe(se, le, pe, "\u03B2", "\\beta", true), oe(se, le, pe, "\u03B3", "\\gamma", true), oe(se, le, pe, "\u03B4", "\\delta", true), oe(se, le, pe, "\u03F5", "\\epsilon", true), oe(se, le, pe, "\u03B6", "\\zeta", true), oe(se, le, pe, "\u03B7", "\\eta", true), oe(se, le, pe, "\u03B8", "\\theta", true), oe(se, le, pe, "\u03B9", "\\iota", true), oe(se, le, pe, "\u03BA", "\\kappa", true), oe(se, le, pe, "\u03BB", "\\lambda", true), oe(se, le, pe, "\u03BC", "\\mu", true), oe(se, le, pe, "\u03BD", "\\nu", true), oe(se, le, pe, "\u03BE", "\\xi", true), oe(se, le, pe, "\u03BF", "\\omicron", true), oe(se, le, pe, "\u03C0", "\\pi", true), oe(se, le, pe, "\u03C1", "\\rho", true), oe(se, le, pe, "\u03C3", "\\sigma", true), oe(se, le, pe, "\u03C4", "\\tau", true), oe(se, le, pe, "\u03C5", "\\upsilon", true), oe(se, le, pe, "\u03D5", "\\phi", true), oe(se, le, pe, "\u03C7", "\\chi", true), oe(se, le, pe, "\u03C8", "\\psi", true), oe(se, le, pe, "\u03C9", "\\omega", true), oe(se, le, pe, "\u03B5", "\\varepsilon", true), oe(se, le, pe, "\u03D1", "\\vartheta", true), oe(se, le, pe, "\u03D6", "\\varpi", true), oe(se, le, pe, "\u03F1", "\\varrho", true), oe(se, le, pe, "\u03C2", "\\varsigma", true), oe(se, le, pe, "\u03C6", "\\varphi", true), oe(se, le, he, "\u2217", "*", true), oe(se, le, he, "+", "+"), oe(se, le, he, "\u2212", "-", true), oe(se, le, he, "\u22C5", "\\cdot", true), oe(se, le, he, "\u2218", "\\circ", true), oe(se, le, he, "\xF7", "\\div", true), oe(se, le, he, "\xB1", "\\pm", true), oe(se, le, he, "\xD7", "\\times", true), oe(se, le, he, "\u2229", "\\cap", true), oe(se, le, he, "\u222A", "\\cup", true), oe(se, le, he, "\u2216", "\\setminus", true), oe(se, le, he, "\u2227", "\\land"), oe(se, le, he, "\u2228", "\\lor"), oe(se, le, he, "\u2227", "\\wedge", true), oe(se, le, he, "\u2228", "\\vee", true), oe(se, le, xe, "\u221A", "\\surd"), oe(se, le, ge, "\u27E8", "\\langle", true), oe(se, le, ge, "\u2223", "\\lvert"), oe(se, le, ge, "\u2225", "\\lVert"), oe(se, le, me, "?", "?"), oe(se, le, me, "!", "!"), oe(se, le, me, "\u27E9", "\\rangle", true), oe(se, le, me, "\u2223", "\\rvert"), oe(se, le, me, "\u2225", "\\rVert"), oe(se, le, be, "=", "="), oe(se, le, be, ":", ":"), oe(se, le, be, "\u2248", "\\approx", true), oe(se, le, be, "\u2245", "\\cong", true), oe(se, le, be, "\u2265", "\\ge"), oe(se, le, be, "\u2265", "\\geq", true), oe(se, le, be, "\u2190", "\\gets"), oe(se, le, be, ">", "\\gt", true), oe(se, le, be, "\u2208", "\\in", true), oe(se, le, be, "\uE020", "\\@not"), oe(se, le, be, "\u2282", "\\subset", true), oe(se, le, be, "\u2283", "\\supset", true), oe(se, le, be, "\u2286", "\\subseteq", true), oe(se, le, be, "\u2287", "\\supseteq", true), oe(se, ae, be, "\u2288", "\\nsubseteq", true), oe(se, ae, be, "\u2289", "\\nsupseteq", true), oe(se, le, be, "\u22A8", "\\models"), oe(se, le, be, "\u2190", "\\leftarrow", true), oe(se, le, be, "\u2264", "\\le"), oe(se, le, be, "\u2264", "\\leq", true), oe(se, le, be, "<", "\\lt", true), oe(se, le, be, "\u2192", "\\rightarrow", true), oe(se, le, be, "\u2192", "\\to"), oe(se, ae, be, "\u2271", "\\ngeq", true), oe(se, ae, be, "\u2270", "\\nleq", true), oe(se, le, ye, "\xA0", "\\ "), oe(se, le, ye, "\xA0", "\\space"), oe(se, le, ye, "\xA0", "\\nobreakspace"), oe(ie, le, ye, "\xA0", "\\ "), oe(ie, le, ye, "\xA0", " "), oe(ie, le, ye, "\xA0", "\\space"), oe(ie, le, ye, "\xA0", "\\nobreakspace"), oe(se, le, ye, "", "\\nobreak"), oe(se, le, ye, "", "\\allowbreak"), oe(se, le, fe, ",", ","), oe(se, le, fe, ";", ";"), oe(se, ae, he, "\u22BC", "\\barwedge", true), oe(se, ae, he, "\u22BB", "\\veebar", true), oe(se, le, he, "\u2299", "\\odot", true), oe(se, le, he, "\u2295", "\\oplus", true), oe(se, le, he, "\u2297", "\\otimes", true), oe(se, le, xe, "\u2202", "\\partial", true), oe(se, le, he, "\u2298", "\\oslash", true), oe(se, ae, he, "\u229A", "\\circledcirc", true), oe(se, ae, he, "\u22A1", "\\boxdot", true), oe(se, le, he, "\u25B3", "\\bigtriangleup"), oe(se, le, he, "\u25BD", "\\bigtriangledown"), oe(se, le, he, "\u2020", "\\dagger"), oe(se, le, he, "\u22C4", "\\diamond"), oe(se, le, he, "\u22C6", "\\star"), oe(se, le, he, "\u25C3", "\\triangleleft"), oe(se, le, he, "\u25B9", "\\triangleright"), oe(se, le, ge, "{", "\\{"), oe(ie, le, xe, "{", "\\{"), oe(ie, le, xe, "{", "\\textbraceleft"), oe(se, le, me, "}", "\\}"), oe(ie, le, xe, "}", "\\}"), oe(ie, le, xe, "}", "\\textbraceright"), oe(se, le, ge, "{", "\\lbrace"), oe(se, le, me, "}", "\\rbrace"), oe(se, le, ge, "[", "\\lbrack", true), oe(ie, le, xe, "[", "\\lbrack", true), oe(se, le, me, "]", "\\rbrack", true), oe(ie, le, xe, "]", "\\rbrack", true), oe(se, le, ge, "(", "\\lparen", true), oe(se, le, me, ")", "\\rparen", true), oe(ie, le, xe, "<", "\\textless", true), oe(ie, le, xe, ">", "\\textgreater", true), oe(se, le, ge, "\u230A", "\\lfloor", true), oe(se, le, me, "\u230B", "\\rfloor", true), oe(se, le, ge, "\u2308", "\\lceil", true), oe(se, le, me, "\u2309", "\\rceil", true), oe(se, le, xe, "\\", "\\backslash"), oe(se, le, xe, "\u2223", "|"), oe(se, le, xe, "\u2223", "\\vert"), oe(ie, le, xe, "|", "\\textbar", true), oe(se, le, xe, "\u2225", "\\|"), oe(se, le, xe, "\u2225", "\\Vert"), oe(ie, le, xe, "\u2225", "\\textbardbl"), oe(ie, le, xe, "~", "\\textasciitilde"), oe(ie, le, xe, "\\", "\\textbackslash"), oe(ie, le, xe, "^", "\\textasciicircum"), oe(se, le, be, "\u2191", "\\uparrow", true), oe(se, le, be, "\u21D1", "\\Uparrow", true), oe(se, le, be, "\u2193", "\\downarrow", true), oe(se, le, be, "\u21D3", "\\Downarrow", true), oe(se, le, be, "\u2195", "\\updownarrow", true), oe(se, le, be, "\u21D5", "\\Updownarrow", true), oe(se, le, de, "\u2210", "\\coprod"), oe(se, le, de, "\u22C1", "\\bigvee"), oe(se, le, de, "\u22C0", "\\bigwedge"), oe(se, le, de, "\u2A04", "\\biguplus"), oe(se, le, de, "\u22C2", "\\bigcap"), oe(se, le, de, "\u22C3", "\\bigcup"), oe(se, le, de, "\u222B", "\\int"), oe(se, le, de, "\u222B", "\\intop"), oe(se, le, de, "\u222C", "\\iint"), oe(se, le, de, "\u222D", "\\iiint"), oe(se, le, de, "\u220F", "\\prod"), oe(se, le, de, "\u2211", "\\sum"), oe(se, le, de, "\u2A02", "\\bigotimes"), oe(se, le, de, "\u2A01", "\\bigoplus"), oe(se, le, de, "\u2A00", "\\bigodot"), oe(se, le, de, "\u222E", "\\oint"), oe(se, le, de, "\u222F", "\\oiint"), oe(se, le, de, "\u2230", "\\oiiint"), oe(se, le, de, "\u2A06", "\\bigsqcup"), oe(se, le, de, "\u222B", "\\smallint"), oe(ie, le, ue, "\u2026", "\\textellipsis"), oe(se, le, ue, "\u2026", "\\mathellipsis"), oe(ie, le, ue, "\u2026", "\\ldots", true), oe(se, le, ue, "\u2026", "\\ldots", true), oe(se, le, ue, "\u22EF", "\\@cdots", true), oe(se, le, ue, "\u22F1", "\\ddots", true), oe(se, le, xe, "\u22EE", "\\varvdots"), oe(ie, le, xe, "\u22EE", "\\varvdots"), oe(se, le, ce, "\u02CA", "\\acute"), oe(se, le, ce, "\u02CB", "\\grave"), oe(se, le, ce, "\xA8", "\\ddot"), oe(se, le, ce, "~", "\\tilde"), oe(se, le, ce, "\u02C9", "\\bar"), oe(se, le, ce, "\u02D8", "\\breve"), oe(se, le, ce, "\u02C7", "\\check"), oe(se, le, ce, "^", "\\hat"), oe(se, le, ce, "\u20D7", "\\vec"), oe(se, le, ce, "\u02D9", "\\dot"), oe(se, le, ce, "\u02DA", "\\mathring"), oe(se, le, pe, "\uE131", "\\@imath"), oe(se, le, pe, "\uE237", "\\@jmath"), oe(se, le, xe, "\u0131", "\u0131"), oe(se, le, xe, "\u0237", "\u0237"), oe(ie, le, xe, "\u0131", "\\i", true), oe(ie, le, xe, "\u0237", "\\j", true), oe(ie, le, xe, "\xDF", "\\ss", true), oe(ie, le, xe, "\xE6", "\\ae", true), oe(ie, le, xe, "\u0153", "\\oe", true), oe(ie, le, xe, "\xF8", "\\o", true), oe(ie, le, xe, "\xC6", "\\AE", true), oe(ie, le, xe, "\u0152", "\\OE", true), oe(ie, le, xe, "\xD8", "\\O", true), oe(ie, le, ce, "\u02CA", "\\'"), oe(ie, le, ce, "\u02CB", "\\`"), oe(ie, le, ce, "\u02C6", "\\^"), oe(ie, le, ce, "\u02DC", "\\~"), oe(ie, le, ce, "\u02C9", "\\="), oe(ie, le, ce, "\u02D8", "\\u"), oe(ie, le, ce, "\u02D9", "\\."), oe(ie, le, ce, "\xB8", "\\c"), oe(ie, le, ce, "\u02DA", "\\r"), oe(ie, le, ce, "\u02C7", "\\v"), oe(ie, le, ce, "\xA8", '\\"'), oe(ie, le, ce, "\u02DD", "\\H"), oe(ie, le, ce, "\u25EF", "\\textcircled");
    const we = { "--": true, "---": true, "``": true, "''": true };
    oe(ie, le, xe, "\u2013", "--", true), oe(ie, le, xe, "\u2013", "\\textendash"), oe(ie, le, xe, "\u2014", "---", true), oe(ie, le, xe, "\u2014", "\\textemdash"), oe(ie, le, xe, "\u2018", "`", true), oe(ie, le, xe, "\u2018", "\\textquoteleft"), oe(ie, le, xe, "\u2019", "'", true), oe(ie, le, xe, "\u2019", "\\textquoteright"), oe(ie, le, xe, "\u201C", "``", true), oe(ie, le, xe, "\u201C", "\\textquotedblleft"), oe(ie, le, xe, "\u201D", "''", true), oe(ie, le, xe, "\u201D", "\\textquotedblright"), oe(se, le, xe, "\xB0", "\\degree", true), oe(ie, le, xe, "\xB0", "\\degree"), oe(ie, le, xe, "\xB0", "\\textdegree", true), oe(se, le, xe, "\xA3", "\\pounds"), oe(se, le, xe, "\xA3", "\\mathsterling", true), oe(ie, le, xe, "\xA3", "\\pounds"), oe(ie, le, xe, "\xA3", "\\textsterling", true), oe(se, ae, xe, "\u2720", "\\maltese"), oe(ie, ae, xe, "\u2720", "\\maltese");
    const ve = '0123456789/@."';
    for (let e2 = 0; e2 < 14; e2++) {
      const t2 = ve.charAt(e2);
      oe(se, le, xe, t2, t2);
    }
    const ke = '0123456789!@*()-=+";:?/.,';
    for (let e2 = 0; e2 < 25; e2++) {
      const t2 = ke.charAt(e2);
      oe(ie, le, xe, t2, t2);
    }
    const ze = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    for (let e2 = 0; e2 < 52; e2++) {
      const t2 = ze.charAt(e2);
      oe(se, le, pe, t2, t2), oe(ie, le, xe, t2, t2);
    }
    let Se;
    oe(se, ae, xe, "C", "\u2102"), oe(ie, ae, xe, "C", "\u2102"), oe(se, ae, xe, "H", "\u210D"), oe(ie, ae, xe, "H", "\u210D"), oe(se, ae, xe, "N", "\u2115"), oe(ie, ae, xe, "N", "\u2115"), oe(se, ae, xe, "P", "\u2119"), oe(ie, ae, xe, "P", "\u2119"), oe(se, ae, xe, "Q", "\u211A"), oe(ie, ae, xe, "Q", "\u211A"), oe(se, ae, xe, "R", "\u211D"), oe(ie, ae, xe, "R", "\u211D"), oe(se, ae, xe, "Z", "\u2124"), oe(ie, ae, xe, "Z", "\u2124"), oe(se, le, pe, "h", "\u210E"), oe(ie, le, pe, "h", "\u210E");
    for (let e2 = 0; e2 < 52; e2++) {
      const t2 = ze.charAt(e2);
      Se = String.fromCharCode(55349, 56320 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se), Se = String.fromCharCode(55349, 56372 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se), Se = String.fromCharCode(55349, 56424 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se), Se = String.fromCharCode(55349, 56580 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se), Se = String.fromCharCode(55349, 56684 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se), Se = String.fromCharCode(55349, 56736 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se), Se = String.fromCharCode(55349, 56788 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se), Se = String.fromCharCode(55349, 56840 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se), Se = String.fromCharCode(55349, 56944 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se), e2 < 26 && (Se = String.fromCharCode(55349, 56632 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se), Se = String.fromCharCode(55349, 56476 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se));
    }
    Se = String.fromCharCode(55349, 56668), oe(se, le, pe, "k", Se), oe(ie, le, xe, "k", Se);
    for (let e2 = 0; e2 < 10; e2++) {
      const t2 = e2.toString();
      Se = String.fromCharCode(55349, 57294 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se), Se = String.fromCharCode(55349, 57314 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se), Se = String.fromCharCode(55349, 57324 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se), Se = String.fromCharCode(55349, 57334 + e2), oe(se, le, pe, t2, Se), oe(ie, le, xe, t2, Se);
    }
    const Me = "\xD0\xDE\xFE";
    for (let e2 = 0; e2 < 3; e2++) {
      const t2 = Me.charAt(e2);
      oe(se, le, pe, t2, t2), oe(ie, le, xe, t2, t2);
    }
    const Ae = { mathClass: "mathbf", textClass: "textbf", font: "Main-Bold" }, Te = { mathClass: "mathnormal", textClass: "textit", font: "Math-Italic" }, Be = { mathClass: "boldsymbol", textClass: "boldsymbol", font: "Main-BoldItalic" }, Ce = { mathClass: "", textClass: "", font: "" }, qe = { mathClass: "mathfrak", textClass: "textfrak", font: "Fraktur-Regular" }, Ie = { mathClass: "mathbb", textClass: "textbb", font: "AMS-Regular" }, Re = { mathClass: "mathboldfrak", textClass: "textboldfrak", font: "Fraktur-Regular" }, Ee = { mathClass: "mathsf", textClass: "textsf", font: "SansSerif-Regular" }, He = { mathClass: "mathboldsf", textClass: "textboldsf", font: "SansSerif-Bold" }, Ne = { mathClass: "mathitsf", textClass: "textitsf", font: "SansSerif-Italic" }, Oe = { mathClass: "mathtt", textClass: "texttt", font: "Typewriter-Regular" }, De = [Ae, Ae, Te, Te, Be, Be, { mathClass: "mathscr", textClass: "textscr", font: "Script-Regular" }, Ce, Ce, Ce, qe, qe, Ie, Ie, Re, Re, Ee, Ee, He, He, Ne, Ne, Ce, Ce, Oe, Oe], Le = [Ae, Ce, Ee, He, Oe], Pe = function(e2, t2, r2) {
      if (ne[r2][e2]) {
        const t3 = ne[r2][e2].replace;
        t3 && (e2 = t3);
      }
      return { value: e2, metrics: ee(e2, t2, r2) };
    }, Fe = function(e2, t2, r2, n2, o2) {
      const s2 = Pe(e2, t2, r2), i2 = s2.metrics;
      let l2;
      if (e2 = s2.value, i2) {
        let t3 = i2.italic;
        ("text" === r2 || n2 && "mathit" === n2.font) && (t3 = 0), l2 = new W(e2, i2.height, i2.depth, t3, i2.skew, i2.width, o2);
      } else "undefined" != typeof console && console.warn("No character metrics for '" + e2 + "' in style '" + t2 + "' and mode '" + r2 + "'"), l2 = new W(e2, 0, 0, 0, 0, 0, o2);
      if (n2) {
        l2.maxFontSize = n2.sizeMultiplier, n2.style.isTight() && l2.classes.push("mtight");
        const e3 = n2.getColor();
        e3 && (l2.style.color = e3);
      }
      return l2;
    }, Ve = function(e2, t2, r2, n2) {
      return void 0 === n2 && (n2 = []), "boldsymbol" === r2.font && Pe(e2, "Main-Bold", t2).metrics ? Fe(e2, "Main-Bold", t2, r2, n2.concat(["mathbf"])) : "\\" === e2 || "main" === ne[t2][e2].font ? Fe(e2, "Main-Regular", t2, r2, n2) : Fe(e2, "AMS-Regular", t2, r2, n2.concat(["amsrm"]));
    }, Ge = function(e2, t2, r2) {
      const o2 = e2.mode, s2 = e2.text, i2 = ["mord"], { font: l2, fontFamily: a2, fontWeight: c2, fontShape: h2 } = t2, m2 = "math" === o2 || "text" === o2 && !!l2, u2 = m2 ? l2 : a2;
      let p2 = "", d2 = "";
      if (55349 === s2.charCodeAt(0)) {
        const e3 = ((e4) => {
          const t3 = 1024 * (e4.charCodeAt(0) - 55296) + (e4.charCodeAt(1) - 56320) + 65536;
          if (119808 <= t3 && t3 < 120484) {
            const e5 = Math.floor((t3 - 119808) / 26);
            return De[e5];
          }
          if (120782 <= t3 && t3 <= 120831) {
            const e5 = Math.floor((t3 - 120782) / 10);
            return Le[e5];
          }
          if (120485 === t3 || 120486 === t3) return De[0];
          if (120486 < t3 && t3 < 120782) return Ce;
          throw new n("Unsupported character: " + e4);
        })(s2);
        p2 = e3.font, d2 = e3[o2 + "Class"];
      }
      if (p2) return Fe(s2, p2, o2, t2, i2.concat(d2));
      if (u2) {
        let e3, n2;
        if ("boldsymbol" === u2) {
          const t3 = (function(e4, t4, r3) {
            return "textord" !== r3 && Pe(e4, "Math-BoldItalic", t4).metrics ? { fontName: "Math-BoldItalic", fontClass: "boldsymbol" } : { fontName: "Main-Bold", fontClass: "mathbf" };
          })(s2, o2, r2);
          e3 = t3.fontName, n2 = [t3.fontClass];
        } else m2 ? (e3 = et[l2].fontName, n2 = [l2]) : (e3 = Qe(a2, c2, h2), n2 = [a2, c2, h2]);
        if (Pe(s2, e3, o2).metrics) return Fe(s2, e3, o2, t2, i2.concat(n2));
        if (we.hasOwnProperty(s2) && "Typewriter" === e3.slice(0, 10)) {
          const r3 = [];
          for (let l3 = 0; l3 < s2.length; l3++) r3.push(Fe(s2[l3], e3, o2, t2, i2.concat(n2)));
          return $e(r3);
        }
      }
      if ("mathord" === r2) return Fe(s2, "Math-Italic", o2, t2, i2.concat(["mathnormal"]));
      if ("textord" === r2) {
        const e3 = ne[o2][s2] && ne[o2][s2].font;
        if ("ams" === e3) {
          const e4 = Qe("amsrm", c2, h2);
          return Fe(s2, e4, o2, t2, i2.concat("amsrm", c2, h2));
        }
        if ("main" !== e3 && e3) {
          const r3 = Qe(e3, c2, h2);
          return Fe(s2, r3, o2, t2, i2.concat(r3, c2, h2));
        }
        {
          const e4 = Qe("textrm", c2, h2);
          return Fe(s2, e4, o2, t2, i2.concat(c2, h2));
        }
      }
      throw new Error("unexpected type: " + r2 + " in makeOrd");
    }, Ue = (e2, t2) => {
      if (D(e2.classes) !== D(t2.classes) || e2.skew !== t2.skew || e2.maxFontSize !== t2.maxFontSize || 0 !== e2.italic && e2.hasClass("mathnormal")) return false;
      if (1 === e2.classes.length) {
        const t3 = e2.classes[0];
        if ("mbin" === t3 || "mord" === t3) return false;
      }
      for (const r2 of Object.keys(e2.style)) if (e2.style[r2] !== t2.style[r2]) return false;
      for (const r2 of Object.keys(t2.style)) if (e2.style[r2] !== t2.style[r2]) return false;
      return true;
    }, Xe = (e2) => {
      for (let t2 = 0; t2 < e2.length - 1; t2++) {
        const r2 = e2[t2], n2 = e2[t2 + 1];
        r2 instanceof W && n2 instanceof W && Ue(r2, n2) && (r2.text += n2.text, r2.height = Math.max(r2.height, n2.height), r2.depth = Math.max(r2.depth, n2.depth), r2.italic = n2.italic, e2.splice(t2 + 1, 1), t2--);
      }
      return e2;
    }, Ye = function(e2) {
      let t2 = 0, r2 = 0, n2 = 0;
      for (let o2 = 0; o2 < e2.children.length; o2++) {
        const s2 = e2.children[o2];
        s2.height > t2 && (t2 = s2.height), s2.depth > r2 && (r2 = s2.depth), s2.maxFontSize > n2 && (n2 = s2.maxFontSize);
      }
      e2.height = t2, e2.depth = r2, e2.maxFontSize = n2;
    }, je = function(e2, t2, r2, n2) {
      const o2 = new U(e2, t2, r2, n2);
      return Ye(o2), o2;
    }, We = (e2, t2, r2, n2) => new U(e2, t2, r2, n2), _e = function(e2, t2, r2) {
      const n2 = je([e2], [], t2);
      return n2.height = Math.max(r2 || t2.fontMetrics().defaultRuleThickness, t2.minRuleThickness), n2.style.borderBottomWidth = O(n2.height), n2.maxFontSize = 1, n2;
    }, $e = function(e2) {
      const t2 = new I(e2);
      return Ye(t2), t2;
    }, Ze = function(e2, t2) {
      return e2 instanceof I ? je([], [e2], t2) : e2;
    }, Ke = function(e2, t2) {
      const { children: r2, depth: n2 } = (function(e3) {
        if ("individualShift" === e3.positionType) {
          const t4 = e3.children, r3 = [t4[0]], n3 = -t4[0].shift - t4[0].elem.depth;
          let o3 = n3;
          for (let e4 = 1; e4 < t4.length; e4++) {
            const n4 = -t4[e4].shift - o3 - t4[e4].elem.depth, s3 = n4 - (t4[e4 - 1].elem.height + t4[e4 - 1].elem.depth);
            o3 += n4, r3.push({ type: "kern", size: s3 }), r3.push(t4[e4]);
          }
          return { children: r3, depth: n3 };
        }
        let t3;
        if ("top" === e3.positionType) {
          let r3 = e3.positionData;
          for (let t4 = 0; t4 < e3.children.length; t4++) {
            const n3 = e3.children[t4];
            r3 -= "kern" === n3.type ? n3.size : n3.elem.height + n3.elem.depth;
          }
          t3 = r3;
        } else if ("bottom" === e3.positionType) t3 = -e3.positionData;
        else {
          const r3 = e3.children[0];
          if ("elem" !== r3.type) throw new Error('First child must have type "elem".');
          if ("shift" === e3.positionType) t3 = -r3.elem.depth - e3.positionData;
          else {
            if ("firstBaseline" !== e3.positionType) throw new Error("Invalid positionType " + e3.positionType + ".");
            t3 = -r3.elem.depth;
          }
        }
        return { children: e3.children, depth: t3 };
      })(e2);
      let o2 = 0;
      for (let e3 = 0; e3 < r2.length; e3++) {
        const t3 = r2[e3];
        if ("elem" === t3.type) {
          const e4 = t3.elem;
          o2 = Math.max(o2, e4.maxFontSize, e4.height);
        }
      }
      o2 += 2;
      const s2 = je(["pstrut"], []);
      s2.style.height = O(o2);
      const i2 = [];
      let l2 = n2, a2 = n2, c2 = n2;
      for (let e3 = 0; e3 < r2.length; e3++) {
        const t3 = r2[e3];
        if ("kern" === t3.type) c2 += t3.size;
        else {
          const e4 = t3.elem, r3 = t3.wrapperClasses || [], n3 = t3.wrapperStyle || {}, l3 = je(r3, [s2, e4], void 0, n3);
          l3.style.top = O(-o2 - c2 - e4.depth), t3.marginLeft && (l3.style.marginLeft = t3.marginLeft), t3.marginRight && (l3.style.marginRight = t3.marginRight), i2.push(l3), c2 += e4.height + e4.depth;
        }
        l2 = Math.min(l2, c2), a2 = Math.max(a2, c2);
      }
      const h2 = je(["vlist"], i2);
      let m2;
      if (h2.style.height = O(a2), l2 < 0) {
        const e3 = je([], []), t3 = je(["vlist"], [e3]);
        t3.style.height = O(-l2);
        const r3 = je(["vlist-s"], [new W("\u200B")]);
        m2 = [je(["vlist-r"], [h2, r3]), je(["vlist-r"], [t3])];
      } else m2 = [je(["vlist-r"], [h2])];
      const u2 = je(["vlist-t"], m2);
      return 2 === m2.length && u2.classes.push("vlist-t2"), u2.height = a2, u2.depth = -l2, u2;
    }, Je = (e2, t2) => {
      const r2 = je(["mspace"], [], t2), n2 = N(e2, t2);
      return r2.style.marginRight = O(n2), r2;
    }, Qe = (e2, t2, r2) => {
      let n2, o2;
      switch (e2) {
        case "amsrm":
          n2 = "AMS";
          break;
        case "textrm":
          n2 = "Main";
          break;
        case "textsf":
          n2 = "SansSerif";
          break;
        case "texttt":
          n2 = "Typewriter";
          break;
        default:
          n2 = e2;
      }
      return o2 = "textbf" === t2 && "textit" === r2 ? "BoldItalic" : "textbf" === t2 ? "Bold" : "textit" === r2 ? "Italic" : "Regular", n2 + "-" + o2;
    }, et = { mathbf: { variant: "bold", fontName: "Main-Bold" }, mathrm: { variant: "normal", fontName: "Main-Regular" }, textit: { variant: "italic", fontName: "Main-Italic" }, mathit: { variant: "italic", fontName: "Main-Italic" }, mathnormal: { variant: "italic", fontName: "Math-Italic" }, mathsfit: { variant: "sans-serif-italic", fontName: "SansSerif-Italic" }, mathbb: { variant: "double-struck", fontName: "AMS-Regular" }, mathcal: { variant: "script", fontName: "Caligraphic-Regular" }, mathfrak: { variant: "fraktur", fontName: "Fraktur-Regular" }, mathscr: { variant: "script", fontName: "Script-Regular" }, mathsf: { variant: "sans-serif", fontName: "SansSerif-Regular" }, mathtt: { variant: "monospace", fontName: "Typewriter-Regular" } }, tt = { vec: ["vec", 0.471, 0.714], oiintSize1: ["oiintSize1", 0.957, 0.499], oiintSize2: ["oiintSize2", 1.472, 0.659], oiiintSize1: ["oiiintSize1", 1.304, 0.499], oiiintSize2: ["oiiintSize2", 1.98, 0.659] }, rt = function(e2, t2) {
      const [r2, n2, o2] = tt[e2], s2 = new $(r2), i2 = new _([s2], { width: O(n2), height: O(o2), style: "width:" + O(n2), viewBox: "0 0 " + 1e3 * n2 + " " + 1e3 * o2, preserveAspectRatio: "xMinYMin" }), l2 = We(["overlay"], [i2], t2);
      return l2.height = o2, l2.style.height = O(o2), l2.style.width = O(n2), l2;
    }, nt = { number: 3, unit: "mu" }, ot = { number: 4, unit: "mu" }, st = { number: 5, unit: "mu" }, it = { mord: { mop: nt, mbin: ot, mrel: st, minner: nt }, mop: { mord: nt, mop: nt, mrel: st, minner: nt }, mbin: { mord: ot, mop: ot, mopen: ot, minner: ot }, mrel: { mord: st, mop: st, mopen: st, minner: st }, mopen: {}, mclose: { mop: nt, mbin: ot, mrel: st, minner: nt }, mpunct: { mord: nt, mop: nt, mrel: st, mopen: nt, mclose: nt, mpunct: nt, minner: nt }, minner: { mord: nt, mop: nt, mbin: ot, mrel: st, mopen: nt, mpunct: nt, minner: nt } }, lt = { mord: { mop: nt }, mop: { mord: nt, mop: nt }, mbin: {}, mrel: {}, mopen: {}, mclose: { mop: nt }, mpunct: {}, minner: { mop: nt } }, at = {}, ct = {}, ht = {};
    function mt(e2) {
      let { type: t2, names: r2, props: n2, handler: o2, htmlBuilder: s2, mathmlBuilder: i2 } = e2;
      const l2 = { type: t2, numArgs: n2.numArgs, argTypes: n2.argTypes, allowedInArgument: !!n2.allowedInArgument, allowedInText: !!n2.allowedInText, allowedInMath: void 0 === n2.allowedInMath || n2.allowedInMath, numOptionalArgs: n2.numOptionalArgs || 0, infix: !!n2.infix, primitive: !!n2.primitive, handler: o2 };
      for (let e3 = 0; e3 < r2.length; ++e3) at[r2[e3]] = l2;
      t2 && (s2 && (ct[t2] = s2), i2 && (ht[t2] = i2));
    }
    function ut(e2) {
      let { type: t2, htmlBuilder: r2, mathmlBuilder: n2 } = e2;
      mt({ type: t2, names: [], props: { numArgs: 0 }, handler() {
        throw new Error("Should never be called.");
      }, htmlBuilder: r2, mathmlBuilder: n2 });
    }
    const pt = function(e2) {
      return "ordgroup" === e2.type && 1 === e2.body.length ? e2.body[0] : e2;
    }, dt = function(e2) {
      return "ordgroup" === e2.type ? e2.body : [e2];
    }, gt = /* @__PURE__ */ new Set(["leftmost", "mbin", "mopen", "mrel", "mop", "mpunct"]), ft = /* @__PURE__ */ new Set(["rightmost", "mrel", "mclose", "mpunct"]), bt = { display: S.DISPLAY, text: S.TEXT, script: S.SCRIPT, scriptscript: S.SCRIPTSCRIPT }, yt = { mord: "mord", mop: "mop", mbin: "mbin", mrel: "mrel", mopen: "mopen", mclose: "mclose", mpunct: "mpunct", minner: "minner" }, xt = function(e2, t2, r2, n2) {
      void 0 === n2 && (n2 = [null, null]);
      const o2 = [];
      for (let r3 = 0; r3 < e2.length; r3++) {
        const n3 = Mt(e2[r3], t2);
        if (n3 instanceof I) {
          const e3 = n3.children;
          o2.push(...e3);
        } else o2.push(n3);
      }
      if (Xe(o2), !r2) return o2;
      let s2 = t2;
      if (1 === e2.length) {
        const r3 = e2[0];
        "sizing" === r3.type ? s2 = t2.havingSize(r3.size) : "styling" === r3.type && (s2 = t2.havingStyle(bt[r3.style]));
      }
      const i2 = je([n2[0] || "leftmost"], [], t2), l2 = je([n2[1] || "rightmost"], [], t2), a2 = "root" === r2;
      return wt(o2, (e3, t3) => {
        const r3 = t3.classes[0], n3 = e3.classes[0];
        "mbin" === r3 && ft.has(n3) ? t3.classes[0] = "mord" : "mbin" === n3 && gt.has(r3) && (e3.classes[0] = "mord");
      }, { node: i2 }, l2, a2), wt(o2, (e3, t3) => {
        var r3, n3;
        const o3 = zt(t3), i3 = zt(e3), l3 = o3 && i3 ? e3.hasClass("mtight") ? null == (r3 = lt[o3]) ? void 0 : r3[i3] : null == (n3 = it[o3]) ? void 0 : n3[i3] : null;
        if (l3) return Je(l3, s2);
      }, { node: i2 }, l2, a2), o2;
    }, wt = function(e2, t2, r2, n2, o2) {
      n2 && e2.push(n2);
      let s2 = 0;
      for (; s2 < e2.length; s2++) {
        const n3 = e2[s2], i2 = vt(n3);
        if (i2) {
          wt(i2.children, t2, r2, null, o2);
          continue;
        }
        const l2 = !n3.hasClass("mspace");
        if (l2) {
          const o3 = t2(n3, r2.node);
          o3 && (r2.insertAfter ? r2.insertAfter(o3) : (e2.unshift(o3), s2++));
        }
        l2 ? r2.node = n3 : o2 && n3.hasClass("newline") && (r2.node = je(["leftmost"])), r2.insertAfter = /* @__PURE__ */ ((t3) => (r3) => {
          e2.splice(t3 + 1, 0, r3), s2++;
        })(s2);
      }
      n2 && e2.pop();
    }, vt = function(e2) {
      return e2 instanceof I || e2 instanceof X || e2 instanceof U && e2.hasClass("enclosing") ? e2 : null;
    }, kt = function(e2, t2) {
      const r2 = vt(e2);
      if (r2) {
        const e3 = r2.children;
        if (e3.length) {
          if ("right" === t2) return kt(e3[e3.length - 1], "right");
          if ("left" === t2) return kt(e3[0], "left");
        }
      }
      return e2;
    }, zt = function(e2, t2) {
      if (!e2) return null;
      t2 && (e2 = kt(e2, t2));
      const r2 = e2.classes[0];
      return yt[r2] || null;
    }, St = function(e2, t2) {
      const r2 = ["nulldelimiter"].concat(e2.baseSizingClasses());
      return je(t2.concat(r2));
    }, Mt = function(e2, t2, r2) {
      if (!e2) return je();
      if (ct[e2.type]) {
        let n2 = ct[e2.type](e2, t2);
        if (r2 && t2.size !== r2.size) {
          n2 = je(t2.sizingClasses(r2), [n2], t2);
          const e3 = t2.sizeMultiplier / r2.sizeMultiplier;
          n2.height *= e3, n2.depth *= e3;
        }
        return n2;
      }
      throw new n("Got group of unknown type: '" + e2.type + "'");
    };
    function At(e2, t2) {
      const r2 = je(["base"], e2, t2), n2 = je(["strut"]);
      return n2.style.height = O(r2.height + r2.depth), r2.depth && (n2.style.verticalAlign = O(-r2.depth)), r2.children.unshift(n2), r2;
    }
    function Tt(e2, t2) {
      let r2 = null;
      1 === e2.length && "tag" === e2[0].type && (r2 = e2[0].tag, e2 = e2[0].body);
      const n2 = xt(e2, t2, "root");
      let o2;
      2 === n2.length && n2[1].hasClass("tag") && (o2 = n2.pop());
      const s2 = [];
      let i2, l2 = [];
      for (let e3 = 0; e3 < n2.length; e3++) if (l2.push(n2[e3]), n2[e3].hasClass("mbin") || n2[e3].hasClass("mrel") || n2[e3].hasClass("allowbreak")) {
        let r3 = false;
        for (; e3 < n2.length - 1 && n2[e3 + 1].hasClass("mspace") && !n2[e3 + 1].hasClass("newline"); ) e3++, l2.push(n2[e3]), n2[e3].hasClass("nobreak") && (r3 = true);
        r3 || (s2.push(At(l2, t2)), l2 = []);
      } else n2[e3].hasClass("newline") && (l2.pop(), l2.length > 0 && (s2.push(At(l2, t2)), l2 = []), s2.push(n2[e3]));
      l2.length > 0 && s2.push(At(l2, t2)), r2 ? (i2 = At(xt(r2, t2, true), t2), i2.classes = ["tag"], s2.push(i2)) : o2 && s2.push(o2);
      const a2 = je(["katex-html"], s2);
      if (a2.setAttribute("aria-hidden", "true"), i2) {
        const e3 = i2.children[0];
        e3.style.height = O(a2.height + a2.depth), a2.depth && (e3.style.verticalAlign = O(-a2.depth));
      }
      return a2;
    }
    function Bt(e2) {
      return new I(e2);
    }
    class Ct {
      constructor(e2, t2, r2) {
        this.type = void 0, this.attributes = void 0, this.children = void 0, this.classes = void 0, this.type = e2, this.attributes = {}, this.children = t2 || [], this.classes = r2 || [];
      }
      setAttribute(e2, t2) {
        this.attributes[e2] = t2;
      }
      getAttribute(e2) {
        return this.attributes[e2];
      }
      toNode() {
        const e2 = document.createElementNS("http://www.w3.org/1998/Math/MathML", this.type);
        for (const t2 in this.attributes) Object.prototype.hasOwnProperty.call(this.attributes, t2) && e2.setAttribute(t2, this.attributes[t2]);
        this.classes.length > 0 && (e2.className = D(this.classes));
        for (let t2 = 0; t2 < this.children.length; t2++) if (this.children[t2] instanceof qt && this.children[t2 + 1] instanceof qt) {
          let r2 = this.children[t2].toText() + this.children[++t2].toText();
          for (; this.children[t2 + 1] instanceof qt; ) r2 += this.children[++t2].toText();
          e2.appendChild(new qt(r2).toNode());
        } else e2.appendChild(this.children[t2].toNode());
        return e2;
      }
      toMarkup() {
        let e2 = "<" + this.type;
        for (const t2 in this.attributes) Object.prototype.hasOwnProperty.call(this.attributes, t2) && (e2 += " " + t2 + '="', e2 += a(this.attributes[t2]), e2 += '"');
        this.classes.length > 0 && (e2 += ' class ="' + a(D(this.classes)) + '"'), e2 += ">";
        for (let t2 = 0; t2 < this.children.length; t2++) e2 += this.children[t2].toMarkup();
        return e2 += "</" + this.type + ">", e2;
      }
      toText() {
        return this.children.map((e2) => e2.toText()).join("");
      }
    }
    class qt {
      constructor(e2) {
        this.text = void 0, this.text = e2;
      }
      toNode() {
        return document.createTextNode(this.text);
      }
      toMarkup() {
        return a(this.toText());
      }
      toText() {
        return this.text;
      }
    }
    class It {
      constructor(e2) {
        this.width = void 0, this.character = void 0, this.width = e2, this.character = e2 >= 0.05555 && e2 <= 0.05556 ? "\u200A" : e2 >= 0.1666 && e2 <= 0.1667 ? "\u2009" : e2 >= 0.2222 && e2 <= 0.2223 ? "\u2005" : e2 >= 0.2777 && e2 <= 0.2778 ? "\u2005\u200A" : e2 >= -0.05556 && e2 <= -0.05555 ? "\u200A\u2063" : e2 >= -0.1667 && e2 <= -0.1666 ? "\u2009\u2063" : e2 >= -0.2223 && e2 <= -0.2222 ? "\u205F\u2063" : e2 >= -0.2778 && e2 <= -0.2777 ? "\u2005\u2063" : null;
      }
      toNode() {
        if (this.character) return document.createTextNode(this.character);
        {
          const e2 = document.createElementNS("http://www.w3.org/1998/Math/MathML", "mspace");
          return e2.setAttribute("width", O(this.width)), e2;
        }
      }
      toMarkup() {
        return this.character ? "<mtext>" + this.character + "</mtext>" : '<mspace width="' + O(this.width) + '"/>';
      }
      toText() {
        return this.character ? this.character : " ";
      }
    }
    const Rt = /* @__PURE__ */ new Set(["\\imath", "\\jmath"]), Et = /* @__PURE__ */ new Set(["mrow", "mtable"]), Ht = function(e2, t2, r2) {
      return !ne[t2][e2] || !ne[t2][e2].replace || 55349 === e2.charCodeAt(0) || we.hasOwnProperty(e2) && r2 && (r2.fontFamily && "tt" === r2.fontFamily.slice(4, 6) || r2.font && "tt" === r2.font.slice(4, 6)) || (e2 = ne[t2][e2].replace), new qt(e2);
    }, Nt = function(e2) {
      return 1 === e2.length ? e2[0] : new Ct("mrow", e2);
    }, Ot = { mathit: "italic", boldsymbol: (e2) => "textord" === e2.type ? "bold" : "bold-italic", mathbf: "bold", mathbb: "double-struck", mathsfit: "sans-serif-italic", mathfrak: "fraktur", mathscr: "script", mathcal: "script", mathsf: "sans-serif", mathtt: "monospace" }, Dt = (e2, t2) => {
      if ("text" === e2.mode) {
        if ("texttt" === t2.fontFamily) return "monospace";
        if ("textsf" === t2.fontFamily) return "textit" === t2.fontShape && "textbf" === t2.fontWeight ? "sans-serif-bold-italic" : "textit" === t2.fontShape ? "sans-serif-italic" : "textbf" === t2.fontWeight ? "bold-sans-serif" : "sans-serif";
        if ("textit" === t2.fontShape && "textbf" === t2.fontWeight) return "bold-italic";
        if ("textit" === t2.fontShape) return "italic";
        if ("textbf" === t2.fontWeight) return "bold";
      }
      const r2 = t2.font;
      if (!r2 || "mathnormal" === r2) return null;
      const n2 = e2.mode, o2 = Ot[r2];
      if (o2) return "function" == typeof o2 ? o2(e2) : o2;
      let s2 = e2.text;
      if (Rt.has(s2)) return null;
      if (ne[n2][s2]) {
        const e3 = ne[n2][s2].replace;
        e3 && (s2 = e3);
      }
      return ee(s2, et[r2].fontName, n2) ? et[r2].variant : null;
    };
    function Lt(e2) {
      if (!e2) return false;
      if ("mi" === e2.type && 1 === e2.children.length) {
        const t2 = e2.children[0];
        return t2 instanceof qt && "." === t2.text;
      }
      if ("mo" === e2.type && 1 === e2.children.length && "true" === e2.getAttribute("separator") && "0em" === e2.getAttribute("lspace") && "0em" === e2.getAttribute("rspace")) {
        const t2 = e2.children[0];
        return t2 instanceof qt && "," === t2.text;
      }
      return false;
    }
    const Pt = function(e2, t2, r2) {
      if (1 === e2.length) {
        const n3 = Vt(e2[0], t2);
        return r2 && n3 instanceof Ct && "mo" === n3.type && (n3.setAttribute("lspace", "0em"), n3.setAttribute("rspace", "0em")), [n3];
      }
      const n2 = [];
      let o2;
      for (let r3 = 0; r3 < e2.length; r3++) {
        const s2 = Vt(e2[r3], t2);
        if (s2 instanceof Ct && o2 instanceof Ct) {
          if ("mtext" === s2.type && "mtext" === o2.type && s2.getAttribute("mathvariant") === o2.getAttribute("mathvariant")) {
            o2.children.push(...s2.children);
            continue;
          }
          if ("mn" === s2.type && "mn" === o2.type) {
            o2.children.push(...s2.children);
            continue;
          }
          if (Lt(s2) && "mn" === o2.type) {
            o2.children.push(...s2.children);
            continue;
          }
          if ("mn" === s2.type && Lt(o2)) s2.children = [...o2.children, ...s2.children], n2.pop();
          else if (("msup" === s2.type || "msub" === s2.type) && s2.children.length >= 1 && ("mn" === o2.type || Lt(o2))) {
            const e3 = s2.children[0];
            e3 instanceof Ct && "mn" === e3.type && (e3.children = [...o2.children, ...e3.children], n2.pop());
          } else if ("mi" === o2.type && 1 === o2.children.length) {
            const e3 = o2.children[0];
            if (e3 instanceof qt && "\u0338" === e3.text && ("mo" === s2.type || "mi" === s2.type || "mn" === s2.type)) {
              const e4 = s2.children[0];
              e4 instanceof qt && e4.text.length > 0 && (e4.text = e4.text.slice(0, 1) + "\u0338" + e4.text.slice(1), n2.pop());
            }
          }
        }
        n2.push(s2), o2 = s2;
      }
      return n2;
    }, Ft = function(e2, t2, r2) {
      return Nt(Pt(e2, t2, r2));
    }, Vt = function(e2, t2) {
      if (!e2) return new Ct("mrow");
      if (ht[e2.type]) return ht[e2.type](e2, t2);
      throw new n("Got group of unknown type: '" + e2.type + "'");
    };
    function Gt(e2, t2, r2, n2, o2) {
      const s2 = Pt(e2, r2);
      let i2;
      i2 = 1 === s2.length && s2[0] instanceof Ct && Et.has(s2[0].type) ? s2[0] : new Ct("mrow", s2);
      const l2 = new Ct("annotation", [new qt(t2)]);
      l2.setAttribute("encoding", "application/x-tex");
      const a2 = new Ct("semantics", [i2, l2]), c2 = new Ct("math", [a2]);
      c2.setAttribute("xmlns", "http://www.w3.org/1998/Math/MathML"), n2 && c2.setAttribute("display", "block");
      return je([o2 ? "katex" : "katex-mathml"], [c2]);
    }
    const Ut = [[1, 1, 1], [2, 1, 1], [3, 1, 1], [4, 2, 1], [5, 2, 1], [6, 3, 1], [7, 4, 2], [8, 6, 3], [9, 7, 6], [10, 8, 7], [11, 10, 9]], Xt = [0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.2, 1.44, 1.728, 2.074, 2.488], Yt = function(e2, t2) {
      return t2.size < 2 ? e2 : Ut[e2 - 1][t2.size - 1];
    };
    class jt {
      constructor(e2) {
        this.style = void 0, this.color = void 0, this.size = void 0, this.textSize = void 0, this.phantom = void 0, this.font = void 0, this.fontFamily = void 0, this.fontWeight = void 0, this.fontShape = void 0, this.sizeMultiplier = void 0, this.maxSize = void 0, this.minRuleThickness = void 0, this._fontMetrics = void 0, this.style = e2.style, this.color = e2.color, this.size = e2.size || jt.BASESIZE, this.textSize = e2.textSize || this.size, this.phantom = !!e2.phantom, this.font = e2.font || "", this.fontFamily = e2.fontFamily || "", this.fontWeight = e2.fontWeight || "", this.fontShape = e2.fontShape || "", this.sizeMultiplier = Xt[this.size - 1], this.maxSize = e2.maxSize, this.minRuleThickness = e2.minRuleThickness, this._fontMetrics = void 0;
      }
      extend(e2) {
        const t2 = { style: this.style, size: this.size, textSize: this.textSize, color: this.color, phantom: this.phantom, font: this.font, fontFamily: this.fontFamily, fontWeight: this.fontWeight, fontShape: this.fontShape, maxSize: this.maxSize, minRuleThickness: this.minRuleThickness };
        return Object.assign(t2, e2), new jt(t2);
      }
      havingStyle(e2) {
        return this.style === e2 ? this : this.extend({ style: e2, size: Yt(this.textSize, e2) });
      }
      havingCrampedStyle() {
        return this.havingStyle(this.style.cramp());
      }
      havingSize(e2) {
        return this.size === e2 && this.textSize === e2 ? this : this.extend({ style: this.style.text(), size: e2, textSize: e2, sizeMultiplier: Xt[e2 - 1] });
      }
      havingBaseStyle(e2) {
        e2 = e2 || this.style.text();
        const t2 = Yt(jt.BASESIZE, e2);
        return this.size === t2 && this.textSize === jt.BASESIZE && this.style === e2 ? this : this.extend({ style: e2, size: t2 });
      }
      havingBaseSizing() {
        let e2;
        switch (this.style.id) {
          case 4:
          case 5:
            e2 = 3;
            break;
          case 6:
          case 7:
            e2 = 1;
            break;
          default:
            e2 = 6;
        }
        return this.extend({ style: this.style.text(), size: e2 });
      }
      withColor(e2) {
        return this.extend({ color: e2 });
      }
      withPhantom() {
        return this.extend({ phantom: true });
      }
      withFont(e2) {
        return this.extend({ font: e2 });
      }
      withTextFontFamily(e2) {
        return this.extend({ fontFamily: e2, font: "" });
      }
      withTextFontWeight(e2) {
        return this.extend({ fontWeight: e2, font: "" });
      }
      withTextFontShape(e2) {
        return this.extend({ fontShape: e2, font: "" });
      }
      sizingClasses(e2) {
        return e2.size !== this.size ? ["sizing", "reset-size" + e2.size, "size" + this.size] : [];
      }
      baseSizingClasses() {
        return this.size !== jt.BASESIZE ? ["sizing", "reset-size" + this.size, "size" + jt.BASESIZE] : [];
      }
      fontMetrics() {
        return this._fontMetrics || (this._fontMetrics = (function(e2) {
          let t2;
          if (t2 = e2 >= 5 ? 0 : e2 >= 3 ? 1 : 2, !te[t2]) {
            const e3 = te[t2] = { cssEmPerMu: J.quad[t2] / 18 };
            for (const r2 in J) J.hasOwnProperty(r2) && (e3[r2] = J[r2][t2]);
          }
          return te[t2];
        })(this.size)), this._fontMetrics;
      }
      getColor() {
        return this.phantom ? "transparent" : this.color;
      }
    }
    jt.BASESIZE = 6;
    var Wt = jt;
    const _t = function(e2) {
      return new Wt({ style: e2.displayMode ? S.DISPLAY : S.TEXT, maxSize: e2.maxSize, minRuleThickness: e2.minRuleThickness });
    }, $t = function(e2, t2) {
      if (t2.displayMode) {
        const r2 = ["katex-display"];
        t2.leqno && r2.push("leqno"), t2.fleqn && r2.push("fleqn"), e2 = je(r2, [e2]);
      }
      return e2;
    }, Zt = function(e2, t2, r2) {
      const n2 = _t(r2);
      let o2;
      if ("mathml" === r2.output) return Gt(e2, t2, n2, r2.displayMode, true);
      if ("html" === r2.output) {
        const t3 = Tt(e2, n2);
        o2 = je(["katex"], [t3]);
      } else {
        const s2 = Gt(e2, t2, n2, r2.displayMode, false), i2 = Tt(e2, n2);
        o2 = je(["katex"], [s2, i2]);
      }
      return $t(o2, r2);
    };
    const Kt = { widehat: "^", widecheck: "\u02C7", widetilde: "~", utilde: "~", overleftarrow: "\u2190", underleftarrow: "\u2190", xleftarrow: "\u2190", overrightarrow: "\u2192", underrightarrow: "\u2192", xrightarrow: "\u2192", underbrace: "\u23DF", overbrace: "\u23DE", underbracket: "\u23B5", overbracket: "\u23B4", overgroup: "\u23E0", undergroup: "\u23E1", overleftrightarrow: "\u2194", underleftrightarrow: "\u2194", xleftrightarrow: "\u2194", Overrightarrow: "\u21D2", xRightarrow: "\u21D2", overleftharpoon: "\u21BC", xleftharpoonup: "\u21BC", overrightharpoon: "\u21C0", xrightharpoonup: "\u21C0", xLeftarrow: "\u21D0", xLeftrightarrow: "\u21D4", xhookleftarrow: "\u21A9", xhookrightarrow: "\u21AA", xmapsto: "\u21A6", xrightharpoondown: "\u21C1", xleftharpoondown: "\u21BD", xrightleftharpoons: "\u21CC", xleftrightharpoons: "\u21CB", xtwoheadleftarrow: "\u219E", xtwoheadrightarrow: "\u21A0", xlongequal: "=", xtofrom: "\u21C4", xrightleftarrows: "\u21C4", xrightequilibrium: "\u21CC", xleftequilibrium: "\u21CB", "\\cdrightarrow": "\u2192", "\\cdleftarrow": "\u2190", "\\cdlongequal": "=" }, Jt = function(e2) {
      const t2 = new Ct("mo", [new qt(Kt[e2.replace(/^\\/, "")])]);
      return t2.setAttribute("stretchy", "true"), t2;
    }, Qt = { overrightarrow: [["rightarrow"], 0.888, 522, "xMaxYMin"], overleftarrow: [["leftarrow"], 0.888, 522, "xMinYMin"], underrightarrow: [["rightarrow"], 0.888, 522, "xMaxYMin"], underleftarrow: [["leftarrow"], 0.888, 522, "xMinYMin"], xrightarrow: [["rightarrow"], 1.469, 522, "xMaxYMin"], "\\cdrightarrow": [["rightarrow"], 3, 522, "xMaxYMin"], xleftarrow: [["leftarrow"], 1.469, 522, "xMinYMin"], "\\cdleftarrow": [["leftarrow"], 3, 522, "xMinYMin"], Overrightarrow: [["doublerightarrow"], 0.888, 560, "xMaxYMin"], xRightarrow: [["doublerightarrow"], 1.526, 560, "xMaxYMin"], xLeftarrow: [["doubleleftarrow"], 1.526, 560, "xMinYMin"], overleftharpoon: [["leftharpoon"], 0.888, 522, "xMinYMin"], xleftharpoonup: [["leftharpoon"], 0.888, 522, "xMinYMin"], xleftharpoondown: [["leftharpoondown"], 0.888, 522, "xMinYMin"], overrightharpoon: [["rightharpoon"], 0.888, 522, "xMaxYMin"], xrightharpoonup: [["rightharpoon"], 0.888, 522, "xMaxYMin"], xrightharpoondown: [["rightharpoondown"], 0.888, 522, "xMaxYMin"], xlongequal: [["longequal"], 0.888, 334, "xMinYMin"], "\\cdlongequal": [["longequal"], 3, 334, "xMinYMin"], xtwoheadleftarrow: [["twoheadleftarrow"], 0.888, 334, "xMinYMin"], xtwoheadrightarrow: [["twoheadrightarrow"], 0.888, 334, "xMaxYMin"], overleftrightarrow: [["leftarrow", "rightarrow"], 0.888, 522], overbrace: [["leftbrace", "midbrace", "rightbrace"], 1.6, 548], underbrace: [["leftbraceunder", "midbraceunder", "rightbraceunder"], 1.6, 548], underleftrightarrow: [["leftarrow", "rightarrow"], 0.888, 522], xleftrightarrow: [["leftarrow", "rightarrow"], 1.75, 522], xLeftrightarrow: [["doubleleftarrow", "doublerightarrow"], 1.75, 560], xrightleftharpoons: [["leftharpoondownplus", "rightharpoonplus"], 1.75, 716], xleftrightharpoons: [["leftharpoonplus", "rightharpoondownplus"], 1.75, 716], xhookleftarrow: [["leftarrow", "righthook"], 1.08, 522], xhookrightarrow: [["lefthook", "rightarrow"], 1.08, 522], overlinesegment: [["leftlinesegment", "rightlinesegment"], 0.888, 522], underlinesegment: [["leftlinesegment", "rightlinesegment"], 0.888, 522], overbracket: [["leftbracketover", "rightbracketover"], 1.6, 440], underbracket: [["leftbracketunder", "rightbracketunder"], 1.6, 410], overgroup: [["leftgroup", "rightgroup"], 0.888, 342], undergroup: [["leftgroupunder", "rightgroupunder"], 0.888, 342], xmapsto: [["leftmapsto", "rightarrow"], 1.5, 522], xtofrom: [["leftToFrom", "rightToFrom"], 1.75, 528], xrightleftarrows: [["baraboveleftarrow", "rightarrowabovebar"], 1.75, 901], xrightequilibrium: [["baraboveshortleftharpoon", "rightharpoonaboveshortbar"], 1.75, 716], xleftequilibrium: [["shortbaraboveleftharpoon", "shortrightharpoonabovebar"], 1.75, 716] }, er = /* @__PURE__ */ new Set(["widehat", "widecheck", "widetilde", "utilde"]), tr = function(e2, t2) {
      const { span: r2, minWidth: n2, height: o2 } = (function() {
        let r3 = 4e5;
        const n3 = e2.label.slice(1);
        if (er.has(n3) && "base" in e2) {
          const o3 = "ordgroup" === e2.base.type ? e2.base.body.length : 1;
          let s2, i2, l2;
          if (o3 > 5) "widehat" === n3 || "widecheck" === n3 ? (s2 = 420, r3 = 2364, l2 = 0.42, i2 = n3 + "4") : (s2 = 312, r3 = 2340, l2 = 0.34, i2 = "tilde4");
          else {
            const e3 = [1, 1, 2, 2, 3, 3][o3];
            "widehat" === n3 || "widecheck" === n3 ? (r3 = [0, 1062, 2364, 2364, 2364][e3], s2 = [0, 239, 300, 360, 420][e3], l2 = [0, 0.24, 0.3, 0.3, 0.36, 0.42][e3], i2 = n3 + e3) : (r3 = [0, 600, 1033, 2339, 2340][e3], s2 = [0, 260, 286, 306, 312][e3], l2 = [0, 0.26, 0.286, 0.3, 0.306, 0.34][e3], i2 = "tilde" + e3);
          }
          const a2 = new $(i2), c2 = new _([a2], { width: "100%", height: O(l2), viewBox: "0 0 " + r3 + " " + s2, preserveAspectRatio: "none" });
          return { span: We([], [c2], t2), minWidth: 0, height: l2 };
        }
        {
          const e3 = [], o3 = Qt[n3];
          if (!o3) throw new Error('No SVG data for "' + n3 + '".');
          const [s2, i2, l2] = o3, a2 = l2 / 1e3, c2 = s2.length;
          let h2, m2;
          if (1 === c2) {
            if (4 !== o3.length) throw new Error('Expected 4-tuple for single-path SVG data "' + n3 + '".');
            h2 = ["hide-tail"], m2 = [o3[3]];
          } else if (2 === c2) h2 = ["halfarrow-left", "halfarrow-right"], m2 = ["xMinYMin", "xMaxYMin"];
          else {
            if (3 !== c2) throw new Error("Correct katexImagesData or update code here to support\n                    " + c2 + " children.");
            h2 = ["brace-left", "brace-center", "brace-right"], m2 = ["xMinYMin", "xMidYMin", "xMaxYMin"];
          }
          for (let n4 = 0; n4 < c2; n4++) {
            const o4 = new $(s2[n4]), u2 = new _([o4], { width: "400em", height: O(a2), viewBox: "0 0 " + r3 + " " + l2, preserveAspectRatio: m2[n4] + " slice" }), p2 = We([h2[n4]], [u2], t2);
            if (1 === c2) return { span: p2, minWidth: i2, height: a2 };
            p2.style.height = O(a2), e3.push(p2);
          }
          return { span: je(["stretchy"], e3, t2), minWidth: i2, height: a2 };
        }
      })();
      return r2.height = o2, r2.style.height = O(o2), n2 > 0 && (r2.style.minWidth = O(n2)), r2;
    }, rr = { bin: 1, close: 1, inner: 1, open: 1, punct: 1, rel: 1 }, nr = { "accent-token": 1, mathord: 1, "op-token": 1, spacing: 1, textord: 1 };
    function or(e2, t2) {
      if (!e2 || e2.type !== t2) throw new Error("Expected node of type " + t2 + ", but got " + (e2 ? "node of type " + e2.type : String(e2)));
      return e2;
    }
    function sr(e2) {
      const t2 = ir(e2);
      if (!t2) throw new Error("Expected node of symbol group type, but got " + (e2 ? "node of type " + e2.type : String(e2)));
      return t2;
    }
    function ir(e2) {
      return e2 && ("atom" === e2.type || nr.hasOwnProperty(e2.type)) ? e2 : null;
    }
    const lr = (e2) => {
      return e2 instanceof W ? e2 : ((t2 = e2) instanceof U || t2 instanceof X || t2 instanceof I) && 1 === e2.children.length ? lr(e2.children[0]) : void 0;
      var t2;
    }, ar = (e2, t2) => {
      let r2, n2, o2;
      e2 && "supsub" === e2.type ? (n2 = or(e2.base, "accent"), r2 = n2.base, e2.base = r2, o2 = (function(e3) {
        if (e3 instanceof U) return e3;
        throw new Error("Expected span<HtmlDomNode> but got " + String(e3) + ".");
      })(Mt(e2, t2)), e2.base = n2) : (n2 = or(e2, "accent"), r2 = n2.base);
      const s2 = Mt(r2, t2.havingCrampedStyle());
      let i2 = 0;
      var l2, a2;
      n2.isShifty && m(r2) && (i2 = null != (l2 = null == (a2 = lr(s2)) ? void 0 : a2.skew) ? l2 : 0);
      const c2 = "\\c" === n2.label;
      let h2, u2 = c2 ? s2.height + s2.depth : Math.min(s2.height, t2.fontMetrics().xHeight);
      if (n2.isStretchy) h2 = tr(n2, t2), h2 = Ke({ positionType: "firstBaseline", children: [{ type: "elem", elem: s2 }, { type: "elem", elem: h2, wrapperClasses: ["svg-align"], wrapperStyle: i2 > 0 ? { width: "calc(100% - " + O(2 * i2) + ")", marginLeft: O(2 * i2) } : void 0 }] });
      else {
        let e3, r3;
        "\\vec" === n2.label ? (e3 = rt("vec", t2), r3 = tt.vec[1]) : (e3 = Ge({ type: "textord", mode: n2.mode, text: n2.label }, t2, "textord"), e3 = (function(e4) {
          if (e4 instanceof W) return e4;
          throw new Error("Expected symbolNode but got " + String(e4) + ".");
        })(e3), e3.italic = 0, r3 = e3.width, c2 && (u2 += e3.depth)), h2 = je(["accent-body"], [e3]);
        const o3 = "\\textcircled" === n2.label;
        o3 && (h2.classes.push("accent-full"), u2 = s2.height);
        let l3 = i2;
        o3 || (l3 -= r3 / 2), h2.style.left = O(l3), "\\textcircled" === n2.label && (h2.style.top = ".2em"), h2 = Ke({ positionType: "firstBaseline", children: [{ type: "elem", elem: s2 }, { type: "kern", size: -u2 }, { type: "elem", elem: h2 }] });
      }
      const p2 = je(["mord", "accent"], [h2], t2);
      return o2 ? (o2.children[0] = p2, o2.height = Math.max(p2.height, o2.height), o2.classes[0] = "mord", o2) : p2;
    }, cr = (e2, t2) => {
      const r2 = e2.isStretchy ? Jt(e2.label) : new Ct("mo", [Ht(e2.label, e2.mode)]), n2 = new Ct("mover", [Vt(e2.base, t2), r2]);
      return n2.setAttribute("accent", "true"), n2;
    }, hr = new RegExp(["\\acute", "\\grave", "\\ddot", "\\tilde", "\\bar", "\\breve", "\\check", "\\hat", "\\vec", "\\dot", "\\mathring"].map((e2) => "\\" + e2).join("|"));
    mt({ type: "accent", names: ["\\acute", "\\grave", "\\ddot", "\\tilde", "\\bar", "\\breve", "\\check", "\\hat", "\\vec", "\\dot", "\\mathring", "\\widecheck", "\\widehat", "\\widetilde", "\\overrightarrow", "\\overleftarrow", "\\Overrightarrow", "\\overleftrightarrow", "\\overgroup", "\\overlinesegment", "\\overleftharpoon", "\\overrightharpoon"], props: { numArgs: 1 }, handler: (e2, t2) => {
      const r2 = pt(t2[0]), n2 = !hr.test(e2.funcName), o2 = !n2 || "\\widehat" === e2.funcName || "\\widetilde" === e2.funcName || "\\widecheck" === e2.funcName;
      return { type: "accent", mode: e2.parser.mode, label: e2.funcName, isStretchy: n2, isShifty: o2, base: r2 };
    }, htmlBuilder: ar, mathmlBuilder: cr }), mt({ type: "accent", names: ["\\'", "\\`", "\\^", "\\~", "\\=", "\\u", "\\.", '\\"', "\\c", "\\r", "\\H", "\\v", "\\textcircled"], props: { numArgs: 1, allowedInText: true, allowedInMath: true, argTypes: ["primitive"] }, handler: (e2, t2) => {
      const r2 = t2[0];
      let n2 = e2.parser.mode;
      return "math" === n2 && (e2.parser.settings.reportNonstrict("mathVsTextAccents", "LaTeX's accent " + e2.funcName + " works only in text mode"), n2 = "text"), { type: "accent", mode: n2, label: e2.funcName, isStretchy: false, isShifty: true, base: r2 };
    }, htmlBuilder: ar, mathmlBuilder: cr }), mt({ type: "accentUnder", names: ["\\underleftarrow", "\\underrightarrow", "\\underleftrightarrow", "\\undergroup", "\\underlinesegment", "\\utilde"], props: { numArgs: 1 }, handler: (e2, t2) => {
      let { parser: r2, funcName: n2 } = e2;
      const o2 = t2[0];
      return { type: "accentUnder", mode: r2.mode, label: n2, base: o2 };
    }, htmlBuilder: (e2, t2) => {
      const r2 = Mt(e2.base, t2), n2 = tr(e2, t2), o2 = "\\utilde" === e2.label ? 0.12 : 0, s2 = Ke({ positionType: "top", positionData: r2.height, children: [{ type: "elem", elem: n2, wrapperClasses: ["svg-align"] }, { type: "kern", size: o2 }, { type: "elem", elem: r2 }] });
      return je(["mord", "accentunder"], [s2], t2);
    }, mathmlBuilder: (e2, t2) => {
      const r2 = Jt(e2.label), n2 = new Ct("munder", [Vt(e2.base, t2), r2]);
      return n2.setAttribute("accentunder", "true"), n2;
    } });
    const mr = (e2) => {
      const t2 = new Ct("mpadded", e2 ? [e2] : []);
      return t2.setAttribute("width", "+0.6em"), t2.setAttribute("lspace", "0.3em"), t2;
    };
    function ur(e2, t2) {
      const r2 = xt(e2.body, t2, true);
      return je([e2.mclass], r2, t2);
    }
    function pr(e2, t2) {
      let r2;
      const n2 = Pt(e2.body, t2);
      return "minner" === e2.mclass ? r2 = new Ct("mpadded", n2) : "mord" === e2.mclass ? e2.isCharacterBox ? (r2 = n2[0], r2.type = "mi") : r2 = new Ct("mi", n2) : (e2.isCharacterBox ? (r2 = n2[0], r2.type = "mo") : r2 = new Ct("mo", n2), "mbin" === e2.mclass ? (r2.attributes.lspace = "0.22em", r2.attributes.rspace = "0.22em") : "mpunct" === e2.mclass ? (r2.attributes.lspace = "0em", r2.attributes.rspace = "0.17em") : "mopen" === e2.mclass || "mclose" === e2.mclass ? (r2.attributes.lspace = "0em", r2.attributes.rspace = "0em") : "minner" === e2.mclass && (r2.attributes.lspace = "0.0556em", r2.attributes.width = "+0.1111em")), r2;
    }
    mt({ type: "xArrow", names: ["\\xleftarrow", "\\xrightarrow", "\\xLeftarrow", "\\xRightarrow", "\\xleftrightarrow", "\\xLeftrightarrow", "\\xhookleftarrow", "\\xhookrightarrow", "\\xmapsto", "\\xrightharpoondown", "\\xrightharpoonup", "\\xleftharpoondown", "\\xleftharpoonup", "\\xrightleftharpoons", "\\xleftrightharpoons", "\\xlongequal", "\\xtwoheadrightarrow", "\\xtwoheadleftarrow", "\\xtofrom", "\\xrightleftarrows", "\\xrightequilibrium", "\\xleftequilibrium", "\\\\cdrightarrow", "\\\\cdleftarrow", "\\\\cdlongequal"], props: { numArgs: 1, numOptionalArgs: 1 }, handler(e2, t2, r2) {
      let { parser: n2, funcName: o2 } = e2;
      return { type: "xArrow", mode: n2.mode, label: o2, body: t2[0], below: r2[0] };
    }, htmlBuilder(e2, t2) {
      const r2 = t2.style;
      let n2 = t2.havingStyle(r2.sup());
      const o2 = Ze(Mt(e2.body, n2, t2), t2), s2 = "\\x" === e2.label.slice(0, 2) ? "x" : "cd";
      let i2;
      o2.classes.push(s2 + "-arrow-pad"), e2.below && (n2 = t2.havingStyle(r2.sub()), i2 = Ze(Mt(e2.below, n2, t2), t2), i2.classes.push(s2 + "-arrow-pad"));
      const l2 = tr(e2, t2), a2 = -t2.fontMetrics().axisHeight + 0.5 * l2.height;
      let c2, h2 = -t2.fontMetrics().axisHeight - 0.5 * l2.height - 0.111;
      if ((o2.depth > 0.25 || "\\xleftequilibrium" === e2.label) && (h2 -= o2.depth), i2) {
        const e3 = -t2.fontMetrics().axisHeight + i2.height + 0.5 * l2.height + 0.111;
        c2 = Ke({ positionType: "individualShift", children: [{ type: "elem", elem: o2, shift: h2 }, { type: "elem", elem: l2, shift: a2, wrapperClasses: ["svg-align"] }, { type: "elem", elem: i2, shift: e3 }] });
      } else c2 = Ke({ positionType: "individualShift", children: [{ type: "elem", elem: o2, shift: h2 }, { type: "elem", elem: l2, shift: a2, wrapperClasses: ["svg-align"] }] });
      return je(["mrel", "x-arrow"], [c2], t2);
    }, mathmlBuilder(e2, t2) {
      const r2 = Jt(e2.label);
      let n2;
      if (r2.setAttribute("minsize", "x" === e2.label.charAt(0) ? "1.75em" : "3.0em"), e2.body) {
        const o2 = mr(Vt(e2.body, t2));
        if (e2.below) {
          const s2 = mr(Vt(e2.below, t2));
          n2 = new Ct("munderover", [r2, s2, o2]);
        } else n2 = new Ct("mover", [r2, o2]);
      } else if (e2.below) {
        const o2 = mr(Vt(e2.below, t2));
        n2 = new Ct("munder", [r2, o2]);
      } else n2 = mr(), n2 = new Ct("mover", [r2, n2]);
      return n2;
    } }), mt({ type: "mclass", names: ["\\mathord", "\\mathbin", "\\mathrel", "\\mathopen", "\\mathclose", "\\mathpunct", "\\mathinner"], props: { numArgs: 1, primitive: true }, handler(e2, t2) {
      let { parser: r2, funcName: n2 } = e2;
      const o2 = t2[0];
      return { type: "mclass", mode: r2.mode, mclass: "m" + n2.slice(5), body: dt(o2), isCharacterBox: m(o2) };
    }, htmlBuilder: ur, mathmlBuilder: pr });
    const dr = (e2) => {
      const t2 = "ordgroup" === e2.type && e2.body.length ? e2.body[0] : e2;
      return "atom" !== t2.type || "bin" !== t2.family && "rel" !== t2.family ? "mord" : "m" + t2.family;
    };
    mt({ type: "mclass", names: ["\\@binrel"], props: { numArgs: 2 }, handler(e2, t2) {
      let { parser: r2 } = e2;
      return { type: "mclass", mode: r2.mode, mclass: dr(t2[0]), body: dt(t2[1]), isCharacterBox: m(t2[1]) };
    } }), mt({ type: "mclass", names: ["\\stackrel", "\\overset", "\\underset"], props: { numArgs: 2 }, handler(e2, t2) {
      let { parser: r2, funcName: n2 } = e2;
      const o2 = t2[1], s2 = t2[0];
      let i2;
      i2 = "\\stackrel" !== n2 ? dr(o2) : "mrel";
      const l2 = { type: "op", mode: o2.mode, limits: true, alwaysHandleSupSub: true, parentIsSupSub: false, symbol: false, suppressBaseShift: "\\stackrel" !== n2, body: dt(o2) }, a2 = { type: "supsub", mode: s2.mode, base: l2, sup: "\\underset" === n2 ? null : s2, sub: "\\underset" === n2 ? s2 : null };
      return { type: "mclass", mode: r2.mode, mclass: i2, body: [a2], isCharacterBox: m(a2) };
    }, htmlBuilder: ur, mathmlBuilder: pr }), mt({ type: "pmb", names: ["\\pmb"], props: { numArgs: 1, allowedInText: true }, handler(e2, t2) {
      let { parser: r2 } = e2;
      return { type: "pmb", mode: r2.mode, mclass: dr(t2[0]), body: dt(t2[0]) };
    }, htmlBuilder(e2, t2) {
      const r2 = xt(e2.body, t2, true), n2 = je([e2.mclass], r2, t2);
      return n2.style.textShadow = "0.02em 0.01em 0.04px", n2;
    }, mathmlBuilder(e2, t2) {
      const r2 = Pt(e2.body, t2), n2 = new Ct("mstyle", r2);
      return n2.setAttribute("style", "text-shadow: 0.02em 0.01em 0.04px"), n2;
    } });
    const gr = { ">": "\\\\cdrightarrow", "<": "\\\\cdleftarrow", "=": "\\\\cdlongequal", A: "\\uparrow", V: "\\downarrow", "|": "\\Vert", ".": "no arrow" }, fr = () => ({ type: "styling", body: [], mode: "math", style: "display", resetFont: true }), br = (e2) => "textord" === e2.type && "@" === e2.text, yr = (e2, t2) => ("mathord" === e2.type || "atom" === e2.type) && e2.text === t2;
    function xr(e2, t2, r2) {
      const n2 = gr[e2];
      switch (n2) {
        case "\\\\cdrightarrow":
        case "\\\\cdleftarrow":
          return r2.callFunction(n2, [t2[0]], [t2[1]]);
        case "\\uparrow":
        case "\\downarrow": {
          const e3 = { type: "atom", text: n2, mode: "math", family: "rel" }, o2 = { type: "ordgroup", mode: "math", body: [r2.callFunction("\\\\cdleft", [t2[0]], []), r2.callFunction("\\Big", [e3], []), r2.callFunction("\\\\cdright", [t2[1]], [])] };
          return r2.callFunction("\\\\cdparent", [o2], []);
        }
        case "\\\\cdlongequal":
          return r2.callFunction("\\\\cdlongequal", [], []);
        case "\\Vert": {
          const e3 = { type: "textord", text: "\\Vert", mode: "math" };
          return r2.callFunction("\\Big", [e3], []);
        }
        default:
          return { type: "textord", text: " ", mode: "math" };
      }
    }
    mt({ type: "cdlabel", names: ["\\\\cdleft", "\\\\cdright"], props: { numArgs: 1 }, handler(e2, t2) {
      let { parser: r2, funcName: n2 } = e2;
      return { type: "cdlabel", mode: r2.mode, side: n2.slice(4), label: t2[0] };
    }, htmlBuilder(e2, t2) {
      const r2 = t2.havingStyle(t2.style.sup()), n2 = Ze(Mt(e2.label, r2, t2), t2);
      return n2.classes.push("cd-label-" + e2.side), n2.style.bottom = O(0.8 - n2.depth), n2.height = 0, n2.depth = 0, n2;
    }, mathmlBuilder(e2, t2) {
      let r2 = new Ct("mrow", [Vt(e2.label, t2)]);
      return r2 = new Ct("mpadded", [r2]), r2.setAttribute("width", "0"), "left" === e2.side && r2.setAttribute("lspace", "-1width"), r2.setAttribute("voffset", "0.7em"), r2 = new Ct("mstyle", [r2]), r2.setAttribute("displaystyle", "false"), r2.setAttribute("scriptlevel", "1"), r2;
    } }), mt({ type: "cdlabelparent", names: ["\\\\cdparent"], props: { numArgs: 1 }, handler(e2, t2) {
      let { parser: r2 } = e2;
      return { type: "cdlabelparent", mode: r2.mode, fragment: t2[0] };
    }, htmlBuilder(e2, t2) {
      const r2 = Ze(Mt(e2.fragment, t2), t2);
      return r2.classes.push("cd-vert-arrow"), r2;
    }, mathmlBuilder(e2, t2) {
      return new Ct("mrow", [Vt(e2.fragment, t2)]);
    } }), mt({ type: "textord", names: ["\\@char"], props: { numArgs: 1, allowedInText: true }, handler(e2, t2) {
      let { parser: r2 } = e2;
      const o2 = or(t2[0], "ordgroup").body;
      let s2 = "";
      for (let e3 = 0; e3 < o2.length; e3++) {
        s2 += or(o2[e3], "textord").text;
      }
      let i2, l2 = parseInt(s2);
      if (isNaN(l2)) throw new n("\\@char has non-numeric argument " + s2);
      if (l2 < 0 || l2 >= 1114111) throw new n("\\@char with invalid code point " + s2);
      return l2 <= 65535 ? i2 = String.fromCharCode(l2) : (l2 -= 65536, i2 = String.fromCharCode(55296 + (l2 >> 10), 56320 + (1023 & l2))), { type: "textord", mode: r2.mode, text: i2 };
    } });
    const wr = (e2, t2) => {
      const r2 = xt(e2.body, t2.withColor(e2.color), false);
      return $e(r2);
    }, vr = (e2, t2) => {
      const r2 = Pt(e2.body, t2.withColor(e2.color)), n2 = new Ct("mstyle", r2);
      return n2.setAttribute("mathcolor", e2.color), n2;
    };
    mt({ type: "color", names: ["\\textcolor"], props: { numArgs: 2, allowedInText: true, argTypes: ["color", "original"] }, handler(e2, t2) {
      let { parser: r2 } = e2;
      const n2 = or(t2[0], "color-token").color, o2 = t2[1];
      return { type: "color", mode: r2.mode, color: n2, body: dt(o2) };
    }, htmlBuilder: wr, mathmlBuilder: vr }), mt({ type: "color", names: ["\\color"], props: { numArgs: 1, allowedInText: true, argTypes: ["color"] }, handler(e2, t2) {
      let { parser: r2, breakOnTokenText: n2 } = e2;
      const o2 = or(t2[0], "color-token").color;
      r2.gullet.macros.set("\\current@color", o2);
      const s2 = r2.parseExpression(true, n2);
      return { type: "color", mode: r2.mode, color: o2, body: s2 };
    }, htmlBuilder: wr, mathmlBuilder: vr }), mt({ type: "cr", names: ["\\\\"], props: { numArgs: 0, numOptionalArgs: 0, allowedInText: true }, handler(e2, t2, r2) {
      let { parser: n2 } = e2;
      const o2 = "[" === n2.gullet.future().text ? n2.parseSizeGroup(true) : null, s2 = !n2.settings.displayMode || !n2.settings.useStrictBehavior("newLineInDisplayMode", "In LaTeX, \\\\ or \\newline does nothing in display mode");
      return { type: "cr", mode: n2.mode, newLine: s2, size: o2 && or(o2, "size").value };
    }, htmlBuilder(e2, t2) {
      const r2 = je(["mspace"], [], t2);
      return e2.newLine && (r2.classes.push("newline"), e2.size && (r2.style.marginTop = O(N(e2.size, t2)))), r2;
    }, mathmlBuilder(e2, t2) {
      const r2 = new Ct("mspace");
      return e2.newLine && (r2.setAttribute("linebreak", "newline"), e2.size && r2.setAttribute("height", O(N(e2.size, t2)))), r2;
    } });
    const kr = { "\\global": "\\global", "\\long": "\\\\globallong", "\\\\globallong": "\\\\globallong", "\\def": "\\gdef", "\\gdef": "\\gdef", "\\edef": "\\xdef", "\\xdef": "\\xdef", "\\let": "\\\\globallet", "\\futurelet": "\\\\globalfuture" }, zr = (e2) => {
      const t2 = e2.text;
      if (/^(?:[\\{}$&#^_]|EOF)$/.test(t2)) throw new n("Expected a control sequence", e2);
      return t2;
    }, Sr = (e2, t2, r2, n2) => {
      let o2 = e2.gullet.macros.get(r2.text);
      null == o2 && (r2.noexpand = true, o2 = { tokens: [r2], numArgs: 0, unexpandable: !e2.gullet.isExpandable(r2.text) }), e2.gullet.macros.set(t2, o2, n2);
    };
    mt({ type: "internal", names: ["\\global", "\\long", "\\\\globallong"], props: { numArgs: 0, allowedInText: true }, handler(e2) {
      let { parser: t2, funcName: r2 } = e2;
      t2.consumeSpaces();
      const o2 = t2.fetch();
      if (kr[o2.text]) return "\\global" !== r2 && "\\\\globallong" !== r2 || (o2.text = kr[o2.text]), or(t2.parseFunction(), "internal");
      throw new n("Invalid token after macro prefix", o2);
    } }), mt({ type: "internal", names: ["\\def", "\\gdef", "\\edef", "\\xdef"], props: { numArgs: 0, allowedInText: true, primitive: true }, handler(e2) {
      let { parser: t2, funcName: r2 } = e2, o2 = t2.gullet.popToken();
      const s2 = o2.text;
      if (/^(?:[\\{}$&#^_]|EOF)$/.test(s2)) throw new n("Expected a control sequence", o2);
      let i2, l2 = 0;
      const a2 = [[]];
      for (; "{" !== t2.gullet.future().text; ) if (o2 = t2.gullet.popToken(), "#" === o2.text) {
        if ("{" === t2.gullet.future().text) {
          i2 = t2.gullet.future(), a2[l2].push("{");
          break;
        }
        if (o2 = t2.gullet.popToken(), !/^[1-9]$/.test(o2.text)) throw new n('Invalid argument number "' + o2.text + '"');
        if (parseInt(o2.text) !== l2 + 1) throw new n('Argument number "' + o2.text + '" out of order');
        l2++, a2.push([]);
      } else {
        if ("EOF" === o2.text) throw new n("Expected a macro definition");
        a2[l2].push(o2.text);
      }
      let { tokens: c2 } = t2.gullet.consumeArg();
      return i2 && c2.unshift(i2), "\\edef" !== r2 && "\\xdef" !== r2 || (c2 = t2.gullet.expandTokens(c2), c2.reverse()), t2.gullet.macros.set(s2, { tokens: c2, numArgs: l2, delimiters: a2 }, r2 === kr[r2]), { type: "internal", mode: t2.mode };
    } }), mt({ type: "internal", names: ["\\let", "\\\\globallet"], props: { numArgs: 0, allowedInText: true, primitive: true }, handler(e2) {
      let { parser: t2, funcName: r2 } = e2;
      const n2 = zr(t2.gullet.popToken());
      t2.gullet.consumeSpaces();
      const o2 = ((e3) => {
        let t3 = e3.gullet.popToken();
        return "=" === t3.text && (t3 = e3.gullet.popToken(), " " === t3.text && (t3 = e3.gullet.popToken())), t3;
      })(t2);
      return Sr(t2, n2, o2, "\\\\globallet" === r2), { type: "internal", mode: t2.mode };
    } }), mt({ type: "internal", names: ["\\futurelet", "\\\\globalfuture"], props: { numArgs: 0, allowedInText: true, primitive: true }, handler(e2) {
      let { parser: t2, funcName: r2 } = e2;
      const n2 = zr(t2.gullet.popToken()), o2 = t2.gullet.popToken(), s2 = t2.gullet.popToken();
      return Sr(t2, n2, s2, "\\\\globalfuture" === r2), t2.gullet.pushToken(s2), t2.gullet.pushToken(o2), { type: "internal", mode: t2.mode };
    } });
    const Mr = function(e2, t2, r2) {
      const n2 = ee(ne.math[e2] && ne.math[e2].replace || e2, t2, r2);
      if (!n2) throw new Error("Unsupported symbol " + e2 + " and font size " + t2 + ".");
      return n2;
    }, Ar = function(e2, t2, r2, n2) {
      const o2 = r2.havingBaseStyle(t2), s2 = je(n2.concat(o2.sizingClasses(r2)), [e2], r2), i2 = o2.sizeMultiplier / r2.sizeMultiplier;
      return s2.height *= i2, s2.depth *= i2, s2.maxFontSize = o2.sizeMultiplier, s2;
    }, Tr = function(e2, t2, r2) {
      const n2 = t2.havingBaseStyle(r2), o2 = (1 - t2.sizeMultiplier / n2.sizeMultiplier) * t2.fontMetrics().axisHeight;
      e2.classes.push("delimcenter"), e2.style.top = O(o2), e2.height -= o2, e2.depth += o2;
    }, Br = function(e2, t2, r2, n2, o2, s2) {
      const i2 = (function(e3, t3, r3, n3) {
        return Fe(e3, "Size" + t3 + "-Regular", r3, n3);
      })(e2, t2, o2, n2), l2 = Ar(je(["delimsizing", "size" + t2], [i2], n2), S.TEXT, n2, s2);
      return r2 && Tr(l2, n2, S.TEXT), l2;
    }, Cr = function(e2, t2, r2) {
      let n2;
      n2 = "Size1-Regular" === t2 ? "delim-size1" : "delim-size4";
      return { type: "elem", elem: je(["delimsizinginner", n2], [je([], [Fe(e2, t2, r2)])]) };
    }, qr = function(e2, t2, r2) {
      const n2 = K["Size4-Regular"][e2.charCodeAt(0)] ? K["Size4-Regular"][e2.charCodeAt(0)][4] : K["Size1-Regular"][e2.charCodeAt(0)][4], o2 = new $("inner", (function(e3, t3) {
        switch (e3) {
          case "\u239C":
            return B("M291 0 H417 V" + t3 + " H291z");
          case "\u2223":
            return B("M145 0 H188 V" + t3 + " H145z");
          case "\u2225":
            return B("M145 0 H188 V" + t3 + " H145z") + B("M367 0 H410 V" + t3 + " H367z");
          case "\u239F":
            return B("M457 0 H583 V" + t3 + " H457z");
          case "\u23A2":
            return B("M319 0 H403 V" + t3 + " H319z");
          case "\u23A5":
            return B("M263 0 H347 V" + t3 + " H263z");
          case "\u23AA":
            return B("M384 0 H504 V" + t3 + " H384z");
          case "\u23D0":
            return B("M312 0 H355 V" + t3 + " H312z");
          case "\u2016":
            return B("M257 0 H300 V" + t3 + " H257z") + B("M478 0 H521 V" + t3 + " H478z");
          default:
            return "";
        }
      })(e2, Math.round(1e3 * t2))), s2 = new _([o2], { width: O(n2), height: O(t2), style: "width:" + O(n2), viewBox: "0 0 " + 1e3 * n2 + " " + Math.round(1e3 * t2), preserveAspectRatio: "xMinYMin" }), i2 = We([], [s2], r2);
      return i2.height = t2, i2.style.height = O(t2), i2.style.width = O(n2), { type: "elem", elem: i2 };
    }, Ir = { type: "kern", size: -8e-3 }, Rr = /* @__PURE__ */ new Set(["|", "\\lvert", "\\rvert", "\\vert"]), Er = /* @__PURE__ */ new Set(["\\|", "\\lVert", "\\rVert", "\\Vert"]), Hr = function(e2, t2, r2, n2, o2, s2) {
      let i2, l2, a2, c2, h2 = "", m2 = 0;
      i2 = a2 = c2 = e2, l2 = null;
      let u2 = "Size1-Regular";
      "\\uparrow" === e2 ? a2 = c2 = "\u23D0" : "\\Uparrow" === e2 ? a2 = c2 = "\u2016" : "\\downarrow" === e2 ? i2 = a2 = "\u23D0" : "\\Downarrow" === e2 ? i2 = a2 = "\u2016" : "\\updownarrow" === e2 ? (i2 = "\\uparrow", a2 = "\u23D0", c2 = "\\downarrow") : "\\Updownarrow" === e2 ? (i2 = "\\Uparrow", a2 = "\u2016", c2 = "\\Downarrow") : Rr.has(e2) ? (a2 = "\u2223", h2 = "vert", m2 = 333) : Er.has(e2) ? (a2 = "\u2225", h2 = "doublevert", m2 = 556) : "[" === e2 || "\\lbrack" === e2 ? (i2 = "\u23A1", a2 = "\u23A2", c2 = "\u23A3", u2 = "Size4-Regular", h2 = "lbrack", m2 = 667) : "]" === e2 || "\\rbrack" === e2 ? (i2 = "\u23A4", a2 = "\u23A5", c2 = "\u23A6", u2 = "Size4-Regular", h2 = "rbrack", m2 = 667) : "\\lfloor" === e2 || "\u230A" === e2 ? (a2 = i2 = "\u23A2", c2 = "\u23A3", u2 = "Size4-Regular", h2 = "lfloor", m2 = 667) : "\\lceil" === e2 || "\u2308" === e2 ? (i2 = "\u23A1", a2 = c2 = "\u23A2", u2 = "Size4-Regular", h2 = "lceil", m2 = 667) : "\\rfloor" === e2 || "\u230B" === e2 ? (a2 = i2 = "\u23A5", c2 = "\u23A6", u2 = "Size4-Regular", h2 = "rfloor", m2 = 667) : "\\rceil" === e2 || "\u2309" === e2 ? (i2 = "\u23A4", a2 = c2 = "\u23A5", u2 = "Size4-Regular", h2 = "rceil", m2 = 667) : "(" === e2 || "\\lparen" === e2 ? (i2 = "\u239B", a2 = "\u239C", c2 = "\u239D", u2 = "Size4-Regular", h2 = "lparen", m2 = 875) : ")" === e2 || "\\rparen" === e2 ? (i2 = "\u239E", a2 = "\u239F", c2 = "\u23A0", u2 = "Size4-Regular", h2 = "rparen", m2 = 875) : "\\{" === e2 || "\\lbrace" === e2 ? (i2 = "\u23A7", l2 = "\u23A8", c2 = "\u23A9", a2 = "\u23AA", u2 = "Size4-Regular") : "\\}" === e2 || "\\rbrace" === e2 ? (i2 = "\u23AB", l2 = "\u23AC", c2 = "\u23AD", a2 = "\u23AA", u2 = "Size4-Regular") : "\\lgroup" === e2 || "\u27EE" === e2 ? (i2 = "\u23A7", c2 = "\u23A9", a2 = "\u23AA", u2 = "Size4-Regular") : "\\rgroup" === e2 || "\u27EF" === e2 ? (i2 = "\u23AB", c2 = "\u23AD", a2 = "\u23AA", u2 = "Size4-Regular") : "\\lmoustache" === e2 || "\u23B0" === e2 ? (i2 = "\u23A7", c2 = "\u23AD", a2 = "\u23AA", u2 = "Size4-Regular") : "\\rmoustache" !== e2 && "\u23B1" !== e2 || (i2 = "\u23AB", c2 = "\u23A9", a2 = "\u23AA", u2 = "Size4-Regular");
      const p2 = Mr(i2, u2, o2), d2 = p2.height + p2.depth, g2 = Mr(a2, u2, o2), f2 = g2.height + g2.depth, b2 = Mr(c2, u2, o2), y2 = b2.height + b2.depth;
      let x2 = 0, w2 = 1;
      if (null !== l2) {
        const e3 = Mr(l2, u2, o2);
        x2 = e3.height + e3.depth, w2 = 2;
      }
      const v2 = d2 + y2 + x2, k2 = v2 + Math.max(0, Math.ceil((t2 - v2) / (w2 * f2))) * w2 * f2;
      let z2 = n2.fontMetrics().axisHeight;
      r2 && (z2 *= n2.sizeMultiplier);
      const M2 = k2 / 2 - z2, A2 = [];
      if (h2.length > 0) {
        const e3 = k2 - d2 - y2, t3 = Math.round(1e3 * k2), r3 = (function(e4, t4) {
          switch (e4) {
            case "lbrack":
              return "M403 1759 V84 H666 V0 H319 V1759 v" + t4 + " v1759 v84 h347 v-84\nH403z M403 1759 V0 H319 V1759 v" + t4 + " v1759 v84 h84z";
            case "rbrack":
              return "M347 1759 V0 H0 V84 H263 V1759 v" + t4 + " v1759 H0 v84 H347z\nM347 1759 V0 H263 V1759 v" + t4 + " v1759 h84z";
            case "vert":
              return "M145 15 v585 v" + t4 + " v585 c2.667,10,9.667,15,21,15\nc10,0,16.667,-5,20,-15 v-585 v" + -t4 + " v-585 c-2.667,-10,-9.667,-15,-21,-15\nc-10,0,-16.667,5,-20,15z M188 15 H145 v585 v" + t4 + " v585 h43z";
            case "doublevert":
              return "M145 15 v585 v" + t4 + " v585 c2.667,10,9.667,15,21,15\nc10,0,16.667,-5,20,-15 v-585 v" + -t4 + " v-585 c-2.667,-10,-9.667,-15,-21,-15\nc-10,0,-16.667,5,-20,15z M188 15 H145 v585 v" + t4 + " v585 h43z\nM367 15 v585 v" + t4 + " v585 c2.667,10,9.667,15,21,15\nc10,0,16.667,-5,20,-15 v-585 v" + -t4 + " v-585 c-2.667,-10,-9.667,-15,-21,-15\nc-10,0,-16.667,5,-20,15z M410 15 H367 v585 v" + t4 + " v585 h43z";
            case "lfloor":
              return "M319 602 V0 H403 V602 v" + t4 + " v1715 h263 v84 H319z\nMM319 602 V0 H403 V602 v" + t4 + " v1715 H319z";
            case "rfloor":
              return "M319 602 V0 H403 V602 v" + t4 + " v1799 H0 v-84 H319z\nMM319 602 V0 H403 V602 v" + t4 + " v1715 H319z";
            case "lceil":
              return "M403 1759 V84 H666 V0 H319 V1759 v" + t4 + " v602 h84z\nM403 1759 V0 H319 V1759 v" + t4 + " v602 h84z";
            case "rceil":
              return "M347 1759 V0 H0 V84 H263 V1759 v" + t4 + " v602 h84z\nM347 1759 V0 h-84 V1759 v" + t4 + " v602 h84z";
            case "lparen":
              return "M863,9c0,-2,-2,-5,-6,-9c0,0,-17,0,-17,0c-12.7,0,-19.3,0.3,-20,1\nc-5.3,5.3,-10.3,11,-15,17c-242.7,294.7,-395.3,682,-458,1162c-21.3,163.3,-33.3,349,\n-36,557 l0," + (t4 + 84) + "c0.2,6,0,26,0,60c2,159.3,10,310.7,24,454c53.3,528,210,\n949.7,470,1265c4.7,6,9.7,11.7,15,17c0.7,0.7,7,1,19,1c0,0,18,0,18,0c4,-4,6,-7,6,-9\nc0,-2.7,-3.3,-8.7,-10,-18c-135.3,-192.7,-235.5,-414.3,-300.5,-665c-65,-250.7,-102.5,\n-544.7,-112.5,-882c-2,-104,-3,-167,-3,-189\nl0,-" + (t4 + 92) + "c0,-162.7,5.7,-314,17,-454c20.7,-272,63.7,-513,129,-723c65.3,\n-210,155.3,-396.3,270,-559c6.7,-9.3,10,-15.3,10,-18z";
            case "rparen":
              return "M76,0c-16.7,0,-25,3,-25,9c0,2,2,6.3,6,13c21.3,28.7,42.3,60.3,\n63,95c96.7,156.7,172.8,332.5,228.5,527.5c55.7,195,92.8,416.5,111.5,664.5\nc11.3,139.3,17,290.7,17,454c0,28,1.7,43,3.3,45l0," + (t4 + 9) + "\nc-3,4,-3.3,16.7,-3.3,38c0,162,-5.7,313.7,-17,455c-18.7,248,-55.8,469.3,-111.5,664\nc-55.7,194.7,-131.8,370.3,-228.5,527c-20.7,34.7,-41.7,66.3,-63,95c-2,3.3,-4,7,-6,11\nc0,7.3,5.7,11,17,11c0,0,11,0,11,0c9.3,0,14.3,-0.3,15,-1c5.3,-5.3,10.3,-11,15,-17\nc242.7,-294.7,395.3,-681.7,458,-1161c21.3,-164.7,33.3,-350.7,36,-558\nl0,-" + (t4 + 144) + "c-2,-159.3,-10,-310.7,-24,-454c-53.3,-528,-210,-949.7,\n-470,-1265c-4.7,-6,-9.7,-11.7,-15,-17c-0.7,-0.7,-6.7,-1,-18,-1z";
            default:
              throw new Error("Unknown stretchy delimiter.");
          }
        })(h2, Math.round(1e3 * e3)), o3 = new $(h2, r3), s3 = O(m2 / 1e3), i3 = O(t3 / 1e3), l3 = new _([o3], { width: s3, height: i3, viewBox: "0 0 " + m2 + " " + t3 }), a3 = We([], [l3], n2);
        a3.height = t3 / 1e3, a3.style.width = s3, a3.style.height = i3, A2.push({ type: "elem", elem: a3 });
      } else {
        if (A2.push(Cr(c2, u2, o2)), A2.push(Ir), null === l2) {
          const e3 = k2 - d2 - y2 + 0.016;
          A2.push(qr(a2, e3, n2));
        } else {
          const e3 = (k2 - d2 - y2 - x2) / 2 + 0.016;
          A2.push(qr(a2, e3, n2)), A2.push(Ir), A2.push(Cr(l2, u2, o2)), A2.push(Ir), A2.push(qr(a2, e3, n2));
        }
        A2.push(Ir), A2.push(Cr(i2, u2, o2));
      }
      const T2 = n2.havingBaseStyle(S.TEXT), B2 = Ke({ positionType: "bottom", positionData: M2, children: A2 });
      return Ar(je(["delimsizing", "mult"], [B2], T2), S.TEXT, n2, s2);
    }, Nr = 0.08, Or = function(e2, t2, r2, n2, o2) {
      const s2 = (function(e3, t3, r3) {
        t3 *= 1e3;
        let n3 = "";
        switch (e3) {
          case "sqrtMain":
            n3 = (function(e4, t4) {
              return "M95," + (622 + e4 + t4) + "\nc-2.7,0,-7.17,-2.7,-13.5,-8c-5.8,-5.3,-9.5,-10,-9.5,-14\nc0,-2,0.3,-3.3,1,-4c1.3,-2.7,23.83,-20.7,67.5,-54\nc44.2,-33.3,65.8,-50.3,66.5,-51c1.3,-1.3,3,-2,5,-2c4.7,0,8.7,3.3,12,10\ns173,378,173,378c0.7,0,35.3,-71,104,-213c68.7,-142,137.5,-285,206.5,-429\nc69,-144,104.5,-217.7,106.5,-221\nl" + e4 / 2.075 + " -" + e4 + "\nc5.3,-9.3,12,-14,20,-14\nH400000v" + (40 + e4) + "H845.2724\ns-225.272,467,-225.272,467s-235,486,-235,486c-2.7,4.7,-9,7,-19,7\nc-6,0,-10,-1,-12,-3s-194,-422,-194,-422s-65,47,-65,47z\nM" + (834 + e4) + " " + t4 + "h400000v" + (40 + e4) + "h-400000z";
            })(t3, C);
            break;
          case "sqrtSize1":
            n3 = (function(e4, t4) {
              return "M263," + (601 + e4 + t4) + "c0.7,0,18,39.7,52,119\nc34,79.3,68.167,158.7,102.5,238c34.3,79.3,51.8,119.3,52.5,120\nc340,-704.7,510.7,-1060.3,512,-1067\nl" + e4 / 2.084 + " -" + e4 + "\nc4.7,-7.3,11,-11,19,-11\nH40000v" + (40 + e4) + "H1012.3\ns-271.3,567,-271.3,567c-38.7,80.7,-84,175,-136,283c-52,108,-89.167,185.3,-111.5,232\nc-22.3,46.7,-33.8,70.3,-34.5,71c-4.7,4.7,-12.3,7,-23,7s-12,-1,-12,-1\ns-109,-253,-109,-253c-72.7,-168,-109.3,-252,-110,-252c-10.7,8,-22,16.7,-34,26\nc-22,17.3,-33.3,26,-34,26s-26,-26,-26,-26s76,-59,76,-59s76,-60,76,-60z\nM" + (1001 + e4) + " " + t4 + "h400000v" + (40 + e4) + "h-400000z";
            })(t3, C);
            break;
          case "sqrtSize2":
            n3 = (function(e4, t4) {
              return "M983 " + (10 + e4 + t4) + "\nl" + e4 / 3.13 + " -" + e4 + "\nc4,-6.7,10,-10,18,-10 H400000v" + (40 + e4) + "\nH1013.1s-83.4,268,-264.1,840c-180.7,572,-277,876.3,-289,913c-4.7,4.7,-12.7,7,-24,7\ns-12,0,-12,0c-1.3,-3.3,-3.7,-11.7,-7,-25c-35.3,-125.3,-106.7,-373.3,-214,-744\nc-10,12,-21,25,-33,39s-32,39,-32,39c-6,-5.3,-15,-14,-27,-26s25,-30,25,-30\nc26.7,-32.7,52,-63,76,-91s52,-60,52,-60s208,722,208,722\nc56,-175.3,126.3,-397.3,211,-666c84.7,-268.7,153.8,-488.2,207.5,-658.5\nc53.7,-170.3,84.5,-266.8,92.5,-289.5z\nM" + (1001 + e4) + " " + t4 + "h400000v" + (40 + e4) + "h-400000z";
            })(t3, C);
            break;
          case "sqrtSize3":
            n3 = (function(e4, t4) {
              return "M424," + (2398 + e4 + t4) + "\nc-1.3,-0.7,-38.5,-172,-111.5,-514c-73,-342,-109.8,-513.3,-110.5,-514\nc0,-2,-10.7,14.3,-32,49c-4.7,7.3,-9.8,15.7,-15.5,25c-5.7,9.3,-9.8,16,-12.5,20\ns-5,7,-5,7c-4,-3.3,-8.3,-7.7,-13,-13s-13,-13,-13,-13s76,-122,76,-122s77,-121,77,-121\ns209,968,209,968c0,-2,84.7,-361.7,254,-1079c169.3,-717.3,254.7,-1077.7,256,-1081\nl" + e4 / 4.223 + " -" + e4 + "c4,-6.7,10,-10,18,-10 H400000\nv" + (40 + e4) + "H1014.6\ns-87.3,378.7,-272.6,1166c-185.3,787.3,-279.3,1182.3,-282,1185\nc-2,6,-10,9,-24,9\nc-8,0,-12,-0.7,-12,-2z M" + (1001 + e4) + " " + t4 + "\nh400000v" + (40 + e4) + "h-400000z";
            })(t3, C);
            break;
          case "sqrtSize4":
            n3 = (function(e4, t4) {
              return "M473," + (2713 + e4 + t4) + "\nc339.3,-1799.3,509.3,-2700,510,-2702 l" + e4 / 5.298 + " -" + e4 + "\nc3.3,-7.3,9.3,-11,18,-11 H400000v" + (40 + e4) + "H1017.7\ns-90.5,478,-276.2,1466c-185.7,988,-279.5,1483,-281.5,1485c-2,6,-10,9,-24,9\nc-8,0,-12,-0.7,-12,-2c0,-1.3,-5.3,-32,-16,-92c-50.7,-293.3,-119.7,-693.3,-207,-1200\nc0,-1.3,-5.3,8.7,-16,30c-10.7,21.3,-21.3,42.7,-32,64s-16,33,-16,33s-26,-26,-26,-26\ns76,-153,76,-153s77,-151,77,-151c0.7,0.7,35.7,202,105,604c67.3,400.7,102,602.7,104,\n606zM" + (1001 + e4) + " " + t4 + "h400000v" + (40 + e4) + "H1017.7z";
            })(t3, C);
            break;
          case "sqrtTall":
            n3 = (function(e4, t4, r4) {
              return "M702 " + (e4 + t4) + "H400000" + (40 + e4) + "\nH742v" + (r4 - 54 - t4 - e4) + "l-4 4-4 4c-.667.7 -2 1.5-4 2.5s-4.167 1.833-6.5 2.5-5.5 1-9.5 1\nh-12l-28-84c-16.667-52-96.667 -294.333-240-727l-212 -643 -85 170\nc-4-3.333-8.333-7.667-13 -13l-13-13l77-155 77-156c66 199.333 139 419.667\n219 661 l218 661zM702 " + t4 + "H400000v" + (40 + e4) + "H742z";
            })(t3, C, r3);
        }
        return n3;
      })(e2, n2, r2), i2 = new $(e2, s2), l2 = new _([i2], { width: "400em", height: O(t2), viewBox: "0 0 400000 " + r2, preserveAspectRatio: "xMinYMin slice" });
      return We(["hide-tail"], [l2], o2);
    }, Dr = /* @__PURE__ */ new Set(["(", "\\lparen", ")", "\\rparen", "[", "\\lbrack", "]", "\\rbrack", "\\{", "\\lbrace", "\\}", "\\rbrace", "\\lfloor", "\\rfloor", "\u230A", "\u230B", "\\lceil", "\\rceil", "\u2308", "\u2309", "\\surd"]), Lr = /* @__PURE__ */ new Set(["\\uparrow", "\\downarrow", "\\updownarrow", "\\Uparrow", "\\Downarrow", "\\Updownarrow", "|", "\\|", "\\vert", "\\Vert", "\\lvert", "\\rvert", "\\lVert", "\\rVert", "\\lgroup", "\\rgroup", "\u27EE", "\u27EF", "\\lmoustache", "\\rmoustache", "\u23B0", "\u23B1"]), Pr = /* @__PURE__ */ new Set(["<", ">", "\\langle", "\\rangle", "/", "\\backslash", "\\lt", "\\gt"]), Fr = [0, 1.2, 1.8, 2.4, 3], Vr = function(e2, t2, r2, o2, s2) {
      if ("<" === e2 || "\\lt" === e2 || "\u27E8" === e2 ? e2 = "\\langle" : ">" !== e2 && "\\gt" !== e2 && "\u27E9" !== e2 || (e2 = "\\rangle"), Dr.has(e2) || Pr.has(e2)) return Br(e2, t2, false, r2, o2, s2);
      if (Lr.has(e2)) return Hr(e2, Fr[t2], false, r2, o2, s2);
      throw new n("Illegal delimiter: '" + e2 + "'");
    }, Gr = [{ type: "small", style: S.SCRIPTSCRIPT }, { type: "small", style: S.SCRIPT }, { type: "small", style: S.TEXT }, { type: "large", size: 1 }, { type: "large", size: 2 }, { type: "large", size: 3 }, { type: "large", size: 4 }], Ur = [{ type: "small", style: S.SCRIPTSCRIPT }, { type: "small", style: S.SCRIPT }, { type: "small", style: S.TEXT }, { type: "stack" }], Xr = [{ type: "small", style: S.SCRIPTSCRIPT }, { type: "small", style: S.SCRIPT }, { type: "small", style: S.TEXT }, { type: "large", size: 1 }, { type: "large", size: 2 }, { type: "large", size: 3 }, { type: "large", size: 4 }, { type: "stack" }], Yr = function(e2) {
      if ("small" === e2.type) return "Main-Regular";
      if ("large" === e2.type) return "Size" + e2.size + "-Regular";
      if ("stack" === e2.type) return "Size4-Regular";
      {
        const t2 = e2.type;
        throw new Error("Add support for delim type '" + t2 + "' here.");
      }
    }, jr = function(e2, t2, r2, n2) {
      for (let o2 = Math.min(2, 3 - n2.style.size); o2 < r2.length; o2++) {
        const s2 = r2[o2];
        if ("stack" === s2.type) break;
        const i2 = Mr(e2, Yr(s2), "math");
        let l2 = i2.height + i2.depth;
        if ("small" === s2.type) {
          l2 *= n2.havingBaseStyle(s2.style).sizeMultiplier;
        }
        if (l2 > t2) return s2;
      }
      return r2[r2.length - 1];
    }, Wr = function(e2, t2, r2, n2, o2, s2) {
      let i2;
      "<" === e2 || "\\lt" === e2 || "\u27E8" === e2 ? e2 = "\\langle" : ">" !== e2 && "\\gt" !== e2 && "\u27E9" !== e2 || (e2 = "\\rangle"), i2 = Pr.has(e2) ? Gr : Dr.has(e2) ? Xr : Ur;
      const l2 = jr(e2, t2, i2, n2);
      return "small" === l2.type ? (function(e3, t3, r3, n3, o3, s3) {
        const i3 = Fe(e3, "Main-Regular", o3, n3), l3 = Ar(i3, t3, n3, s3);
        return r3 && Tr(l3, n3, t3), l3;
      })(e2, l2.style, r2, n2, o2, s2) : "large" === l2.type ? Br(e2, l2.size, r2, n2, o2, s2) : Hr(e2, t2, r2, n2, o2, s2);
    }, _r = function(e2, t2, r2, n2, o2, s2) {
      const i2 = n2.fontMetrics().axisHeight * n2.sizeMultiplier, l2 = 5 / n2.fontMetrics().ptPerEm, a2 = Math.max(t2 - i2, r2 + i2), c2 = Math.max(a2 / 500 * 901, 2 * a2 - l2);
      return Wr(e2, c2, true, n2, o2, s2);
    }, $r = { "\\bigl": { mclass: "mopen", size: 1 }, "\\Bigl": { mclass: "mopen", size: 2 }, "\\biggl": { mclass: "mopen", size: 3 }, "\\Biggl": { mclass: "mopen", size: 4 }, "\\bigr": { mclass: "mclose", size: 1 }, "\\Bigr": { mclass: "mclose", size: 2 }, "\\biggr": { mclass: "mclose", size: 3 }, "\\Biggr": { mclass: "mclose", size: 4 }, "\\bigm": { mclass: "mrel", size: 1 }, "\\Bigm": { mclass: "mrel", size: 2 }, "\\biggm": { mclass: "mrel", size: 3 }, "\\Biggm": { mclass: "mrel", size: 4 }, "\\big": { mclass: "mord", size: 1 }, "\\Big": { mclass: "mord", size: 2 }, "\\bigg": { mclass: "mord", size: 3 }, "\\Bigg": { mclass: "mord", size: 4 } }, Zr = /* @__PURE__ */ new Set(["(", "\\lparen", ")", "\\rparen", "[", "\\lbrack", "]", "\\rbrack", "\\{", "\\lbrace", "\\}", "\\rbrace", "\\lfloor", "\\rfloor", "\u230A", "\u230B", "\\lceil", "\\rceil", "\u2308", "\u2309", "<", ">", "\\langle", "\u27E8", "\\rangle", "\u27E9", "\\lt", "\\gt", "\\lvert", "\\rvert", "\\lVert", "\\rVert", "\\lgroup", "\\rgroup", "\u27EE", "\u27EF", "\\lmoustache", "\\rmoustache", "\u23B0", "\u23B1", "/", "\\backslash", "|", "\\vert", "\\|", "\\Vert", "\\uparrow", "\\Uparrow", "\\downarrow", "\\Downarrow", "\\updownarrow", "\\Updownarrow", "."]);
    function Kr(e2) {
      return "isMiddle" in e2;
    }
    function Jr(e2, t2) {
      const r2 = ir(e2);
      if (r2 && Zr.has(r2.text)) return r2;
      throw new n(r2 ? "Invalid delimiter '" + r2.text + "' after '" + t2.funcName + "'" : "Invalid delimiter type '" + e2.type + "'", e2);
    }
    function Qr(e2) {
      if (!e2.body) throw new Error("Bug: The leftright ParseNode wasn't fully parsed.");
    }
    mt({ type: "delimsizing", names: ["\\bigl", "\\Bigl", "\\biggl", "\\Biggl", "\\bigr", "\\Bigr", "\\biggr", "\\Biggr", "\\bigm", "\\Bigm", "\\biggm", "\\Biggm", "\\big", "\\Big", "\\bigg", "\\Bigg"], props: { numArgs: 1, argTypes: ["primitive"] }, handler: (e2, t2) => {
      const r2 = Jr(t2[0], e2);
      return { type: "delimsizing", mode: e2.parser.mode, size: $r[e2.funcName].size, mclass: $r[e2.funcName].mclass, delim: r2.text };
    }, htmlBuilder: (e2, t2) => "." === e2.delim ? je([e2.mclass]) : Vr(e2.delim, e2.size, t2, e2.mode, [e2.mclass]), mathmlBuilder: (e2) => {
      const t2 = [];
      "." !== e2.delim && t2.push(Ht(e2.delim, e2.mode));
      const r2 = new Ct("mo", t2);
      "mopen" === e2.mclass || "mclose" === e2.mclass ? r2.setAttribute("fence", "true") : r2.setAttribute("fence", "false"), r2.setAttribute("stretchy", "true");
      const n2 = O(Fr[e2.size]);
      return r2.setAttribute("minsize", n2), r2.setAttribute("maxsize", n2), r2;
    } }), mt({ type: "leftright-right", names: ["\\right"], props: { numArgs: 1, primitive: true }, handler: (e2, t2) => {
      const r2 = e2.parser.gullet.macros.get("\\current@color");
      if (r2 && "string" != typeof r2) throw new n("\\current@color set to non-string in \\right");
      return { type: "leftright-right", mode: e2.parser.mode, delim: Jr(t2[0], e2).text, color: r2 };
    } }), mt({ type: "leftright", names: ["\\left"], props: { numArgs: 1, primitive: true }, handler: (e2, t2) => {
      const r2 = Jr(t2[0], e2), n2 = e2.parser;
      ++n2.leftrightDepth;
      const o2 = n2.parseExpression(false);
      --n2.leftrightDepth, n2.expect("\\right", false);
      const s2 = or(n2.parseFunction(), "leftright-right");
      return { type: "leftright", mode: n2.mode, body: o2, left: r2.text, right: s2.delim, rightColor: s2.color };
    }, htmlBuilder: (e2, t2) => {
      Qr(e2);
      const r2 = xt(e2.body, t2, true, ["mopen", "mclose"]);
      let n2, o2, s2 = 0, i2 = 0, l2 = false;
      for (let e3 = 0; e3 < r2.length; e3++) {
        Kr(r2[e3]) ? l2 = true : (s2 = Math.max(r2[e3].height, s2), i2 = Math.max(r2[e3].depth, i2));
      }
      if (s2 *= t2.sizeMultiplier, i2 *= t2.sizeMultiplier, n2 = "." === e2.left ? St(t2, ["mopen"]) : _r(e2.left, s2, i2, t2, e2.mode, ["mopen"]), r2.unshift(n2), l2) for (let t3 = 1; t3 < r2.length; t3++) {
        const n3 = r2[t3];
        if (Kr(n3)) {
          const o3 = n3.isMiddle;
          r2[t3] = _r(o3.delim, s2, i2, o3.options, e2.mode, []);
        }
      }
      if ("." === e2.right) o2 = St(t2, ["mclose"]);
      else {
        const r3 = e2.rightColor ? t2.withColor(e2.rightColor) : t2;
        o2 = _r(e2.right, s2, i2, r3, e2.mode, ["mclose"]);
      }
      return r2.push(o2), je(["minner"], r2, t2);
    }, mathmlBuilder: (e2, t2) => {
      Qr(e2);
      const r2 = Pt(e2.body, t2);
      if ("." !== e2.left) {
        const t3 = new Ct("mo", [Ht(e2.left, e2.mode)]);
        t3.setAttribute("fence", "true"), r2.unshift(t3);
      }
      if ("." !== e2.right) {
        const t3 = new Ct("mo", [Ht(e2.right, e2.mode)]);
        t3.setAttribute("fence", "true"), e2.rightColor && t3.setAttribute("mathcolor", e2.rightColor), r2.push(t3);
      }
      return Nt(r2);
    } }), mt({ type: "middle", names: ["\\middle"], props: { numArgs: 1, primitive: true }, handler: (e2, t2) => {
      const r2 = Jr(t2[0], e2);
      if (!e2.parser.leftrightDepth) throw new n("\\middle without preceding \\left", r2);
      return { type: "middle", mode: e2.parser.mode, delim: r2.text };
    }, htmlBuilder: (e2, t2) => {
      let r2;
      return "." === e2.delim ? r2 = St(t2, []) : (r2 = Vr(e2.delim, 1, t2, e2.mode, []), r2.isMiddle = { delim: e2.delim, options: t2 }), r2;
    }, mathmlBuilder: (e2, t2) => {
      const r2 = "\\vert" === e2.delim || "|" === e2.delim ? Ht("|", "text") : Ht(e2.delim, e2.mode), n2 = new Ct("mo", [r2]);
      return n2.setAttribute("fence", "true"), n2.setAttribute("lspace", "0.05em"), n2.setAttribute("rspace", "0.05em"), n2;
    } });
    const en = (e2, t2) => {
      const r2 = Ze(Mt(e2.body, t2), t2), n2 = e2.label.slice(1);
      let o2, s2, i2 = t2.sizeMultiplier;
      const l2 = m(e2.body);
      if ("sout" === n2) o2 = je(["stretchy", "sout"]), o2.height = t2.fontMetrics().defaultRuleThickness / i2, s2 = -0.5 * t2.fontMetrics().xHeight;
      else if ("phase" === n2) {
        const e3 = N({ number: 0.6, unit: "pt" }, t2), n3 = N({ number: 0.35, unit: "ex" }, t2);
        i2 /= t2.havingBaseSizing().sizeMultiplier;
        const l3 = r2.height + r2.depth + e3 + n3;
        r2.style.paddingLeft = O(l3 / 2 + e3);
        const c3 = Math.floor(1e3 * l3 * i2), h2 = "M400000 " + (a2 = c3) + " H0 L" + a2 / 2 + " 0 l65 45 L145 " + (a2 - 80) + " H400000z", m2 = new _([new $("phase", h2)], { width: "400em", height: O(c3 / 1e3), viewBox: "0 0 400000 " + c3, preserveAspectRatio: "xMinYMin slice" });
        o2 = We(["hide-tail"], [m2], t2), o2.style.height = O(l3), s2 = r2.depth + e3 + n3;
      } else {
        let i3, a3;
        /cancel/.test(n2) ? l2 || r2.classes.push("cancel-pad") : "angl" === n2 ? r2.classes.push("anglpad") : r2.classes.push("boxpad");
        let c3 = 0;
        /box/.test(n2) ? (c3 = Math.max(t2.fontMetrics().fboxrule, t2.minRuleThickness), i3 = t2.fontMetrics().fboxsep + ("colorbox" === n2 ? 0 : c3), a3 = i3) : "angl" === n2 ? (c3 = Math.max(t2.fontMetrics().defaultRuleThickness, t2.minRuleThickness), i3 = 4 * c3, a3 = Math.max(0, 0.25 - r2.depth)) : (i3 = l2 ? 0.2 : 0, a3 = i3), o2 = (function(e3, t3, r3, n3, o3) {
          let s3;
          const i4 = e3.height + e3.depth + r3 + n3;
          if (/fbox|color|angl/.test(t3)) {
            if (s3 = je(["stretchy", t3], [], o3), "fbox" === t3) {
              const e4 = o3.color && o3.getColor();
              e4 && (s3.style.borderColor = e4);
            }
          } else {
            const e4 = [];
            /^[bx]cancel$/.test(t3) && e4.push(new Z({ x1: "0", y1: "0", x2: "100%", y2: "100%", "stroke-width": "0.046em" })), /^x?cancel$/.test(t3) && e4.push(new Z({ x1: "0", y1: "100%", x2: "100%", y2: "0", "stroke-width": "0.046em" }));
            const r4 = new _(e4, { width: "100%", height: O(i4) });
            s3 = We([], [r4], o3);
          }
          return s3.height = i4, s3.style.height = O(i4), s3;
        })(r2, n2, i3, a3, t2), /fbox|boxed|fcolorbox/.test(n2) ? (o2.style.borderStyle = "solid", o2.style.borderWidth = O(c3)) : "angl" === n2 && 0.049 !== c3 && (o2.style.borderTopWidth = O(c3), o2.style.borderRightWidth = O(c3)), s2 = r2.depth + a3, e2.backgroundColor && (o2.style.backgroundColor = e2.backgroundColor, e2.borderColor && (o2.style.borderColor = e2.borderColor));
      }
      var a2;
      let c2;
      if (e2.backgroundColor) c2 = Ke({ positionType: "individualShift", children: [{ type: "elem", elem: o2, shift: s2 }, { type: "elem", elem: r2, shift: 0 }] });
      else {
        const e3 = /cancel|phase/.test(n2) ? ["svg-align"] : [];
        c2 = Ke({ positionType: "individualShift", children: [{ type: "elem", elem: r2, shift: 0 }, { type: "elem", elem: o2, shift: s2, wrapperClasses: e3 }] });
      }
      return /cancel/.test(n2) && (c2.height = r2.height, c2.depth = r2.depth), /cancel/.test(n2) && !l2 ? je(["mord", "cancel-lap"], [c2], t2) : je(["mord"], [c2], t2);
    }, tn = (e2, t2) => {
      let r2;
      const n2 = new Ct(e2.label.includes("colorbox") ? "mpadded" : "menclose", [Vt(e2.body, t2)]);
      switch (e2.label) {
        case "\\cancel":
          n2.setAttribute("notation", "updiagonalstrike");
          break;
        case "\\bcancel":
          n2.setAttribute("notation", "downdiagonalstrike");
          break;
        case "\\phase":
          n2.setAttribute("notation", "phasorangle");
          break;
        case "\\sout":
          n2.setAttribute("notation", "horizontalstrike");
          break;
        case "\\fbox":
          n2.setAttribute("notation", "box");
          break;
        case "\\angl":
          n2.setAttribute("notation", "actuarial");
          break;
        case "\\fcolorbox":
        case "\\colorbox":
          if (r2 = t2.fontMetrics().fboxsep * t2.fontMetrics().ptPerEm, n2.setAttribute("width", "+" + 2 * r2 + "pt"), n2.setAttribute("height", "+" + 2 * r2 + "pt"), n2.setAttribute("lspace", r2 + "pt"), n2.setAttribute("voffset", r2 + "pt"), "\\fcolorbox" === e2.label) {
            const r3 = Math.max(t2.fontMetrics().fboxrule, t2.minRuleThickness);
            n2.setAttribute("style", "border: " + O(r3) + " solid " + e2.borderColor);
          }
          break;
        case "\\xcancel":
          n2.setAttribute("notation", "updiagonalstrike downdiagonalstrike");
      }
      return e2.backgroundColor && n2.setAttribute("mathbackground", e2.backgroundColor), n2;
    };
    mt({ type: "enclose", names: ["\\colorbox"], props: { numArgs: 2, allowedInText: true, argTypes: ["color", "hbox"] }, handler(e2, t2, r2) {
      let { parser: n2, funcName: o2 } = e2;
      const s2 = or(t2[0], "color-token").color, i2 = t2[1];
      return { type: "enclose", mode: n2.mode, label: o2, backgroundColor: s2, body: i2 };
    }, htmlBuilder: en, mathmlBuilder: tn }), mt({ type: "enclose", names: ["\\fcolorbox"], props: { numArgs: 3, allowedInText: true, argTypes: ["color", "color", "hbox"] }, handler(e2, t2, r2) {
      let { parser: n2, funcName: o2 } = e2;
      const s2 = or(t2[0], "color-token").color, i2 = or(t2[1], "color-token").color, l2 = t2[2];
      return { type: "enclose", mode: n2.mode, label: o2, backgroundColor: i2, borderColor: s2, body: l2 };
    }, htmlBuilder: en, mathmlBuilder: tn }), mt({ type: "enclose", names: ["\\fbox"], props: { numArgs: 1, argTypes: ["hbox"], allowedInText: true }, handler(e2, t2) {
      let { parser: r2 } = e2;
      return { type: "enclose", mode: r2.mode, label: "\\fbox", body: t2[0] };
    } }), mt({ type: "enclose", names: ["\\cancel", "\\bcancel", "\\xcancel", "\\phase"], props: { numArgs: 1 }, handler(e2, t2) {
      let { parser: r2, funcName: n2 } = e2;
      const o2 = t2[0];
      return { type: "enclose", mode: r2.mode, label: n2, body: o2 };
    }, htmlBuilder: en, mathmlBuilder: tn }), mt({ type: "enclose", names: ["\\sout"], props: { numArgs: 1, allowedInText: true }, handler(e2, t2) {
      let { parser: r2, funcName: n2 } = e2;
      "math" === r2.mode && r2.settings.reportNonstrict("mathVsSout", "LaTeX's \\sout works only in text mode");
      const o2 = t2[0];
      return { type: "enclose", mode: r2.mode, label: n2, body: o2 };
    }, htmlBuilder: en, mathmlBuilder: tn }), mt({ type: "enclose", names: ["\\angl"], props: { numArgs: 1, argTypes: ["hbox"], allowedInText: false }, handler(e2, t2) {
      let { parser: r2 } = e2;
      return { type: "enclose", mode: r2.mode, label: "\\angl", body: t2[0] };
    } });
    const rn = {};
    function nn(e2) {
      let { type: t2, names: r2, props: n2, handler: o2, htmlBuilder: s2, mathmlBuilder: i2 } = e2;
      const l2 = { type: t2, numArgs: n2.numArgs || 0, allowedInText: false, numOptionalArgs: 0, handler: o2 };
      for (let e3 = 0; e3 < r2.length; ++e3) rn[r2[e3]] = l2;
      s2 && (ct[t2] = s2), i2 && (ht[t2] = i2);
    }
    const on = {};
    function sn(e2, t2) {
      on[e2] = t2;
    }
    class ln {
      constructor(e2, t2, r2) {
        this.lexer = void 0, this.start = void 0, this.end = void 0, this.lexer = e2, this.start = t2, this.end = r2;
      }
      static range(e2, t2) {
        return t2 ? e2 && e2.loc && t2.loc && e2.loc.lexer === t2.loc.lexer ? new ln(e2.loc.lexer, e2.loc.start, t2.loc.end) : null : e2 && e2.loc;
      }
    }
    class an {
      constructor(e2, t2) {
        this.text = void 0, this.loc = void 0, this.noexpand = void 0, this.treatAsRelax = void 0, this.text = e2, this.loc = t2;
      }
      range(e2, t2) {
        return new an(t2, ln.range(this, e2));
      }
    }
    function cn(e2) {
      const t2 = [];
      e2.consumeSpaces();
      let r2 = e2.fetch().text;
      for ("\\relax" === r2 && (e2.consume(), e2.consumeSpaces(), r2 = e2.fetch().text); "\\hline" === r2 || "\\hdashline" === r2; ) e2.consume(), t2.push("\\hdashline" === r2), e2.consumeSpaces(), r2 = e2.fetch().text;
      return t2;
    }
    const hn = (e2) => {
      if (!e2.parser.settings.displayMode) throw new n("{" + e2.envName + "} can be used only in display mode.");
    }, mn = /* @__PURE__ */ new Set(["gather", "gather*"]);
    function un(e2) {
      if (!e2.includes("ed")) return !e2.includes("*");
    }
    function pn(e2, t2, r2) {
      let { hskipBeforeAndAfter: o2, addJot: s2, cols: i2, arraystretch: l2, colSeparationType: a2, autoTag: c2, singleRow: h2, emptySingleRow: m2, maxNumCols: u2, leqno: p2 } = t2;
      if (e2.gullet.beginGroup(), h2 || e2.gullet.macros.set("\\cr", "\\\\\\relax"), !l2) {
        const t3 = e2.gullet.expandMacroAsText("\\arraystretch");
        if (null == t3) l2 = 1;
        else if (l2 = parseFloat(t3), !l2 || l2 < 0) throw new n("Invalid \\arraystretch: " + t3);
      }
      e2.gullet.beginGroup();
      let d2 = [];
      const g2 = [d2], f2 = [], b2 = [], y2 = null != c2 ? [] : void 0;
      function x2() {
        c2 && e2.gullet.macros.set("\\@eqnsw", "1", true);
      }
      function w2() {
        y2 && (e2.gullet.macros.get("\\df@tag") ? (y2.push(e2.subparse([new an("\\df@tag")])), e2.gullet.macros.set("\\df@tag", void 0, true)) : y2.push(Boolean(c2) && "1" === e2.gullet.macros.get("\\@eqnsw")));
      }
      for (x2(), b2.push(cn(e2)); ; ) {
        const t3 = e2.parseExpression(false, h2 ? "\\end" : "\\\\");
        e2.gullet.endGroup(), e2.gullet.beginGroup();
        let o3 = { type: "ordgroup", mode: e2.mode, body: t3 };
        r2 && (o3 = { type: "styling", mode: e2.mode, style: r2, resetFont: true, body: [o3] }), d2.push(o3);
        const s3 = e2.fetch().text;
        if ("&" === s3) {
          if (u2 && d2.length === u2) {
            if (h2 || a2) throw new n("Too many tab characters: &", e2.nextToken);
            e2.settings.reportNonstrict("textEnv", "Too few columns specified in the {array} column argument.");
          }
          e2.consume();
        } else {
          if ("\\end" === s3) {
            w2(), 1 === d2.length && "styling" === o3.type && 1 === o3.body.length && "ordgroup" === o3.body[0].type && 0 === o3.body[0].body.length && (g2.length > 1 || !m2) && g2.pop(), b2.length < g2.length + 1 && b2.push([]);
            break;
          }
          if ("\\\\" !== s3) throw new n("Expected & or \\\\ or \\cr or \\end", e2.nextToken);
          {
            let t4;
            e2.consume(), " " !== e2.gullet.future().text && (t4 = e2.parseSizeGroup(true)), f2.push(t4 ? t4.value : null), w2(), b2.push(cn(e2)), d2 = [], g2.push(d2), x2();
          }
        }
      }
      return e2.gullet.endGroup(), e2.gullet.endGroup(), { type: "array", mode: e2.mode, addJot: s2, arraystretch: l2, body: g2, cols: i2, rowGaps: f2, hskipBeforeAndAfter: o2, hLinesBeforeRow: b2, colSeparationType: a2, tags: y2, leqno: p2 };
    }
    function dn(e2) {
      return "d" === e2.slice(0, 1) ? "display" : "text";
    }
    const gn = function(e2, t2) {
      let r2, o2;
      const s2 = e2.body.length, i2 = e2.hLinesBeforeRow;
      let l2 = 0;
      const a2 = new Array(s2), c2 = [], h2 = Math.max(t2.fontMetrics().arrayRuleWidth, t2.minRuleThickness), m2 = 1 / t2.fontMetrics().ptPerEm;
      let u2 = 5 * m2;
      if (e2.colSeparationType && "small" === e2.colSeparationType) {
        u2 = t2.havingStyle(S.SCRIPT).sizeMultiplier / t2.sizeMultiplier * 0.2778;
      }
      const p2 = "CD" === e2.colSeparationType ? N({ number: 3, unit: "ex" }, t2) : 12 * m2, d2 = 3 * m2, g2 = e2.arraystretch * p2, f2 = 0.7 * g2, b2 = 0.3 * g2;
      let y2 = 0;
      function x2(e3) {
        for (let t3 = 0; t3 < e3.length; ++t3) t3 > 0 && (y2 += 0.25), c2.push({ pos: y2, isDashed: e3[t3] });
      }
      for (x2(i2[0]), r2 = 0; r2 < e2.body.length; ++r2) {
        const n2 = e2.body[r2];
        let s3 = f2, c3 = b2;
        l2 < n2.length && (l2 = n2.length);
        const h3 = { cells: new Array(n2.length), height: 0, depth: 0, pos: 0 };
        for (o2 = 0; o2 < n2.length; ++o2) {
          const e3 = Mt(n2[o2], t2);
          c3 < e3.depth && (c3 = e3.depth), s3 < e3.height && (s3 = e3.height), h3.cells[o2] = e3;
        }
        const m3 = e2.rowGaps[r2];
        let u3 = 0;
        m3 && (u3 = N(m3, t2), u3 > 0 && (u3 += b2, c3 < u3 && (c3 = u3), u3 = 0)), e2.addJot && r2 < e2.body.length - 1 && (c3 += d2), h3.height = s3, h3.depth = c3, y2 += s3, h3.pos = y2, y2 += c3 + u3, a2[r2] = h3, x2(i2[r2 + 1]);
      }
      const w2 = y2 / 2 + t2.fontMetrics().axisHeight, v2 = e2.cols || [], k2 = [];
      let z2, M2;
      const A2 = [];
      if (e2.tags && e2.tags.some((e3) => e3)) for (r2 = 0; r2 < s2; ++r2) {
        const n2 = a2[r2], o3 = n2.pos - w2, s3 = e2.tags[r2];
        let i3;
        i3 = true === s3 ? je(["eqn-num"], [], t2) : je([], false === s3 ? [] : xt(s3, t2, true), t2), i3.depth = n2.depth, i3.height = n2.height, A2.push({ type: "elem", elem: i3, shift: o3 });
      }
      for (o2 = 0, M2 = 0; o2 < l2 || M2 < v2.length; ++o2, ++M2) {
        var T2;
        let i3, c3 = v2[M2], m3 = true;
        for (; "separator" === (null == (B2 = c3) ? void 0 : B2.type); ) {
          var B2;
          if (m3 || (z2 = je(["arraycolsep"], []), z2.style.width = O(t2.fontMetrics().doubleRuleSep), k2.push(z2)), "|" !== c3.separator && ":" !== c3.separator) throw new n("Invalid separator type: " + c3.separator);
          {
            const e3 = "|" === c3.separator ? "solid" : "dashed", r3 = je(["vertical-separator"], [], t2);
            r3.style.height = O(y2), r3.style.borderRightWidth = O(h2), r3.style.borderRightStyle = e3, r3.style.margin = "0 " + O(-h2 / 2);
            const n2 = y2 - w2;
            n2 && (r3.style.verticalAlign = O(-n2)), k2.push(r3);
          }
          M2++, c3 = v2[M2], m3 = false;
        }
        if (o2 >= l2) continue;
        var C2, q2;
        if (o2 > 0 || e2.hskipBeforeAndAfter) i3 = null != (C2 = null == (q2 = c3) ? void 0 : q2.pregap) ? C2 : u2, 0 !== i3 && (z2 = je(["arraycolsep"], []), z2.style.width = O(i3), k2.push(z2));
        const p3 = [];
        for (r2 = 0; r2 < s2; ++r2) {
          const e3 = a2[r2], t3 = e3.cells[o2];
          if (!t3) continue;
          const n2 = e3.pos - w2;
          t3.depth = e3.depth, t3.height = e3.height, p3.push({ type: "elem", elem: t3, shift: n2 });
        }
        const d3 = Ke({ positionType: "individualShift", children: p3 }), g3 = je(["col-align-" + ((null == (T2 = c3) ? void 0 : T2.align) || "c")], [d3]);
        var I2, R2;
        if (k2.push(g3), o2 < l2 - 1 || e2.hskipBeforeAndAfter) i3 = null != (I2 = null == (R2 = c3) ? void 0 : R2.postgap) ? I2 : u2, 0 !== i3 && (z2 = je(["arraycolsep"], []), z2.style.width = O(i3), k2.push(z2));
      }
      let E2 = je(["mtable"], k2);
      if (c2.length > 0) {
        const e3 = _e("hline", t2, h2), r3 = _e("hdashline", t2, h2), n2 = [{ type: "elem", elem: E2, shift: 0 }];
        for (; c2.length > 0; ) {
          const t3 = c2.pop(), o3 = t3.pos - w2;
          t3.isDashed ? n2.push({ type: "elem", elem: r3, shift: o3 }) : n2.push({ type: "elem", elem: e3, shift: o3 });
        }
        E2 = Ke({ positionType: "individualShift", children: n2 });
      }
      if (0 === A2.length) return je(["mord"], [E2], t2);
      {
        const e3 = Ke({ positionType: "individualShift", children: A2 }), r3 = je(["tag"], [e3], t2);
        return $e([E2, r3]);
      }
    }, fn = { c: "center ", l: "left ", r: "right " }, bn = function(e2, t2) {
      const r2 = [], n2 = new Ct("mtd", [], ["mtr-glue"]), o2 = new Ct("mtd", [], ["mml-eqn-num"]);
      for (let s3 = 0; s3 < e2.body.length; s3++) {
        const i3 = e2.body[s3], l3 = [];
        for (let e3 = 0; e3 < i3.length; e3++) l3.push(new Ct("mtd", [Vt(i3[e3], t2)]));
        e2.tags && e2.tags[s3] && (l3.unshift(n2), l3.push(n2), e2.leqno ? l3.unshift(o2) : l3.push(o2)), r2.push(new Ct("mtr", l3));
      }
      let s2 = new Ct("mtable", r2);
      const i2 = 0.5 === e2.arraystretch ? 0.1 : 0.16 + e2.arraystretch - 1 + (e2.addJot ? 0.09 : 0);
      s2.setAttribute("rowspacing", O(i2));
      let l2 = "", a2 = "";
      if (e2.cols && e2.cols.length > 0) {
        const t3 = e2.cols;
        let r3 = "", n3 = false, o3 = 0, i3 = t3.length;
        "separator" === t3[0].type && (l2 += "top ", o3 = 1), "separator" === t3[t3.length - 1].type && (l2 += "bottom ", i3 -= 1);
        for (let e3 = o3; e3 < i3; e3++) {
          const o4 = t3[e3];
          "align" === o4.type ? (a2 += fn[o4.align], n3 && (r3 += "none "), n3 = true) : "separator" === o4.type && n3 && (r3 += "|" === o4.separator ? "solid " : "dashed ", n3 = false);
        }
        s2.setAttribute("columnalign", a2.trim()), /[sd]/.test(r3) && s2.setAttribute("columnlines", r3.trim());
      }
      if ("align" === e2.colSeparationType) {
        const t3 = e2.cols || [];
        let r3 = "";
        for (let e3 = 1; e3 < t3.length; e3++) r3 += e3 % 2 ? "0em " : "1em ";
        s2.setAttribute("columnspacing", r3.trim());
      } else "alignat" === e2.colSeparationType || "gather" === e2.colSeparationType ? s2.setAttribute("columnspacing", "0em") : "small" === e2.colSeparationType ? s2.setAttribute("columnspacing", "0.2778em") : "CD" === e2.colSeparationType ? s2.setAttribute("columnspacing", "0.5em") : s2.setAttribute("columnspacing", "1em");
      let c2 = "";
      const h2 = e2.hLinesBeforeRow;
      l2 += h2[0].length > 0 ? "left " : "", l2 += h2[h2.length - 1].length > 0 ? "right " : "";
      for (let e3 = 1; e3 < h2.length - 1; e3++) c2 += 0 === h2[e3].length ? "none " : h2[e3][0] ? "dashed " : "solid ";
      return /[sd]/.test(c2) && s2.setAttribute("rowlines", c2.trim()), "" !== l2 && (s2 = new Ct("menclose", [s2]), s2.setAttribute("notation", l2.trim())), e2.arraystretch && e2.arraystretch < 1 && (s2 = new Ct("mstyle", [s2]), s2.setAttribute("scriptlevel", "1")), s2;
    }, yn = function(e2, t2) {
      e2.envName.includes("ed") || hn(e2);
      const r2 = [], o2 = e2.envName.includes("at") ? "alignat" : "align", s2 = "split" === e2.envName, i2 = pn(e2.parser, { cols: r2, addJot: true, autoTag: s2 ? void 0 : un(e2.envName), emptySingleRow: true, colSeparationType: o2, maxNumCols: s2 ? 2 : void 0, leqno: e2.parser.settings.leqno }, "display");
      let l2 = 0, a2 = 0;
      const c2 = { type: "ordgroup", mode: e2.mode, body: [] };
      if (t2[0] && "ordgroup" === t2[0].type) {
        let e3 = "";
        for (let r3 = 0; r3 < t2[0].body.length; r3++) {
          e3 += or(t2[0].body[r3], "textord").text;
        }
        l2 = Number(e3), a2 = 2 * l2;
      }
      const h2 = !a2;
      i2.body.forEach(function(e3) {
        for (let t3 = 1; t3 < e3.length; t3 += 2) {
          const r3 = or(e3[t3], "styling");
          or(r3.body[0], "ordgroup").body.unshift(c2);
        }
        if (h2) a2 < e3.length && (a2 = e3.length);
        else {
          const t3 = e3.length / 2;
          if (l2 < t3) throw new n("Too many math in a row: expected " + l2 + ", but got " + t3, e3[0]);
        }
      });
      for (let e3 = 0; e3 < a2; ++e3) {
        let t3 = "r", n2 = 0;
        e3 % 2 == 1 ? t3 = "l" : e3 > 0 && h2 && (n2 = 1), r2[e3] = { type: "align", align: t3, pregap: n2, postgap: 0 };
      }
      return i2.colSeparationType = h2 ? "align" : "alignat", i2;
    };
    nn({ type: "array", names: ["array", "darray"], props: { numArgs: 1 }, handler(e2, t2) {
      const r2 = (ir(t2[0]) ? [t2[0]] : or(t2[0], "ordgroup").body).map(function(e3) {
        const t3 = sr(e3).text;
        if ("lcr".includes(t3)) return { type: "align", align: t3 };
        if ("|" === t3) return { type: "separator", separator: "|" };
        if (":" === t3) return { type: "separator", separator: ":" };
        throw new n("Unknown column alignment: " + t3, e3);
      }), o2 = { cols: r2, hskipBeforeAndAfter: true, maxNumCols: r2.length };
      return pn(e2.parser, o2, dn(e2.envName));
    }, htmlBuilder: gn, mathmlBuilder: bn }), nn({ type: "array", names: ["matrix", "pmatrix", "bmatrix", "Bmatrix", "vmatrix", "Vmatrix", "matrix*", "pmatrix*", "bmatrix*", "Bmatrix*", "vmatrix*", "Vmatrix*"], props: { numArgs: 0 }, handler(e2) {
      const t2 = { matrix: null, pmatrix: ["(", ")"], bmatrix: ["[", "]"], Bmatrix: ["\\{", "\\}"], vmatrix: ["|", "|"], Vmatrix: ["\\Vert", "\\Vert"] }[e2.envName.replace("*", "")];
      let r2 = "c";
      const o2 = { hskipBeforeAndAfter: false, cols: [{ type: "align", align: r2 }] };
      if ("*" === e2.envName.charAt(e2.envName.length - 1)) {
        const t3 = e2.parser;
        if (t3.consumeSpaces(), "[" === t3.fetch().text) {
          if (t3.consume(), t3.consumeSpaces(), r2 = t3.fetch().text, !"lcr".includes(r2)) throw new n("Expected l or c or r", t3.nextToken);
          t3.consume(), t3.consumeSpaces(), t3.expect("]"), t3.consume(), o2.cols = [{ type: "align", align: r2 }];
        }
      }
      const s2 = pn(e2.parser, o2, dn(e2.envName)), i2 = Math.max(0, ...s2.body.map((e3) => e3.length));
      return s2.cols = new Array(i2).fill({ type: "align", align: r2 }), t2 ? { type: "leftright", mode: e2.mode, body: [s2], left: t2[0], right: t2[1], rightColor: void 0 } : s2;
    }, htmlBuilder: gn, mathmlBuilder: bn }), nn({ type: "array", names: ["smallmatrix"], props: { numArgs: 0 }, handler(e2) {
      const t2 = pn(e2.parser, { arraystretch: 0.5 }, "script");
      return t2.colSeparationType = "small", t2;
    }, htmlBuilder: gn, mathmlBuilder: bn }), nn({ type: "array", names: ["subarray"], props: { numArgs: 1 }, handler(e2, t2) {
      const r2 = (ir(t2[0]) ? [t2[0]] : or(t2[0], "ordgroup").body).map(function(e3) {
        const t3 = sr(e3).text;
        if ("lc".includes(t3)) return { type: "align", align: t3 };
        throw new n("Unknown column alignment: " + t3, e3);
      });
      if (r2.length > 1) throw new n("{subarray} can contain only one column");
      const o2 = { cols: r2, hskipBeforeAndAfter: false, arraystretch: 0.5 }, s2 = pn(e2.parser, o2, "script");
      if (s2.body.length > 0 && s2.body[0].length > 1) throw new n("{subarray} can contain only one column");
      return s2;
    }, htmlBuilder: gn, mathmlBuilder: bn }), nn({ type: "array", names: ["cases", "dcases", "rcases", "drcases"], props: { numArgs: 0 }, handler(e2) {
      const t2 = pn(e2.parser, { arraystretch: 1.2, cols: [{ type: "align", align: "l", pregap: 0, postgap: 1 }, { type: "align", align: "l", pregap: 0, postgap: 0 }] }, dn(e2.envName));
      return { type: "leftright", mode: e2.mode, body: [t2], left: e2.envName.includes("r") ? "." : "\\{", right: e2.envName.includes("r") ? "\\}" : ".", rightColor: void 0 };
    }, htmlBuilder: gn, mathmlBuilder: bn }), nn({ type: "array", names: ["align", "align*", "aligned", "split"], props: { numArgs: 0 }, handler: yn, htmlBuilder: gn, mathmlBuilder: bn }), nn({ type: "array", names: ["gathered", "gather", "gather*"], props: { numArgs: 0 }, handler(e2) {
      mn.has(e2.envName) && hn(e2);
      const t2 = { cols: [{ type: "align", align: "c" }], addJot: true, colSeparationType: "gather", autoTag: un(e2.envName), emptySingleRow: true, leqno: e2.parser.settings.leqno };
      return pn(e2.parser, t2, "display");
    }, htmlBuilder: gn, mathmlBuilder: bn }), nn({ type: "array", names: ["alignat", "alignat*", "alignedat"], props: { numArgs: 1 }, handler: yn, htmlBuilder: gn, mathmlBuilder: bn }), nn({ type: "array", names: ["equation", "equation*"], props: { numArgs: 0 }, handler(e2) {
      hn(e2);
      const t2 = { autoTag: un(e2.envName), emptySingleRow: true, singleRow: true, maxNumCols: 1, leqno: e2.parser.settings.leqno };
      return pn(e2.parser, t2, "display");
    }, htmlBuilder: gn, mathmlBuilder: bn }), nn({ type: "array", names: ["CD"], props: { numArgs: 0 }, handler(e2) {
      return hn(e2), (function(e3) {
        const t2 = [];
        for (e3.gullet.beginGroup(), e3.gullet.macros.set("\\cr", "\\\\\\relax"), e3.gullet.beginGroup(); ; ) {
          t2.push(e3.parseExpression(false, "\\\\")), e3.gullet.endGroup(), e3.gullet.beginGroup();
          const r3 = e3.fetch().text;
          if ("&" !== r3 && "\\\\" !== r3) {
            if ("\\end" === r3) {
              0 === t2[t2.length - 1].length && t2.pop();
              break;
            }
            throw new n("Expected \\\\ or \\cr or \\end", e3.nextToken);
          }
          e3.consume();
        }
        let r2 = [];
        const o2 = [r2];
        for (let s2 = 0; s2 < t2.length; s2++) {
          const i2 = t2[s2];
          let l2 = fr();
          for (let t3 = 0; t3 < i2.length; t3++) if (br(i2[t3])) {
            r2.push(l2), t3 += 1;
            const o3 = sr(i2[t3]).text, s3 = new Array(2);
            if (s3[0] = { type: "ordgroup", mode: "math", body: [] }, s3[1] = { type: "ordgroup", mode: "math", body: [] }, "=|.".includes(o3)) ;
            else {
              if (!"<>AV".includes(o3)) throw new n('Expected one of "<>AV=|." after @', i2[t3]);
              for (let e4 = 0; e4 < 2; e4++) {
                let r3 = true;
                for (let l3 = t3 + 1; l3 < i2.length; l3++) {
                  if (yr(i2[l3], o3)) {
                    r3 = false, t3 = l3;
                    break;
                  }
                  if (br(i2[l3])) throw new n("Missing a " + o3 + " character to complete a CD arrow.", i2[l3]);
                  s3[e4].body.push(i2[l3]);
                }
                if (r3) throw new n("Missing a " + o3 + " character to complete a CD arrow.", i2[t3]);
              }
            }
            const a2 = { type: "styling", body: [xr(o3, s3, e3)], mode: "math", style: "display", resetFont: true };
            r2.push(a2), l2 = fr();
          } else l2.body.push(i2[t3]);
          s2 % 2 == 0 ? r2.push(l2) : r2.shift(), r2 = [], o2.push(r2);
        }
        return e3.gullet.endGroup(), e3.gullet.endGroup(), { type: "array", mode: "math", body: o2, arraystretch: 1, addJot: true, rowGaps: [null], cols: new Array(o2[0].length).fill({ type: "align", align: "c", pregap: 0.25, postgap: 0.25 }), colSeparationType: "CD", hLinesBeforeRow: new Array(o2.length + 1).fill([]) };
      })(e2.parser);
    }, htmlBuilder: gn, mathmlBuilder: bn }), sn("\\nonumber", "\\gdef\\@eqnsw{0}"), sn("\\notag", "\\nonumber"), mt({ type: "text", names: ["\\hline", "\\hdashline"], props: { numArgs: 0, allowedInText: true, allowedInMath: true }, handler(e2, t2) {
      throw new n(e2.funcName + " valid only within array environment");
    } });
    var xn = rn;
    mt({ type: "environment", names: ["\\begin", "\\end"], props: { numArgs: 1, argTypes: ["text"] }, handler(e2, t2) {
      let { parser: r2, funcName: o2 } = e2;
      const s2 = t2[0];
      if ("ordgroup" !== s2.type) throw new n("Invalid environment name", s2);
      let i2 = "";
      for (let e3 = 0; e3 < s2.body.length; ++e3) i2 += or(s2.body[e3], "textord").text;
      if ("\\begin" === o2) {
        if (!xn.hasOwnProperty(i2)) throw new n("No such environment: " + i2, s2);
        const e3 = xn[i2], { args: t3, optArgs: o3 } = r2.parseArguments("\\begin{" + i2 + "}", e3), l2 = { mode: r2.mode, envName: i2, parser: r2 }, a2 = e3.handler(l2, t3, o3);
        r2.expect("\\end", false);
        const c2 = r2.nextToken, h2 = or(r2.parseFunction(), "environment");
        if (h2.name !== i2) throw new n("Mismatch: \\begin{" + i2 + "} matched by \\end{" + h2.name + "}", c2);
        return a2;
      }
      return { type: "environment", mode: r2.mode, name: i2, nameGroup: s2 };
    } });
    const wn = (e2, t2) => {
      const r2 = e2.font, n2 = t2.withFont(r2);
      return Mt(e2.body, n2);
    }, vn = (e2, t2) => {
      const r2 = e2.font, n2 = t2.withFont(r2);
      return Vt(e2.body, n2);
    }, kn = { "\\Bbb": "\\mathbb", "\\bold": "\\mathbf", "\\frak": "\\mathfrak" };
    mt({ type: "font", names: ["\\mathrm", "\\mathit", "\\mathbf", "\\mathnormal", "\\mathsfit", "\\mathbb", "\\mathcal", "\\mathfrak", "\\mathscr", "\\mathsf", "\\mathtt", "\\Bbb", "\\bold", "\\frak"], props: { numArgs: 1, allowedInArgument: true }, handler: (e2, t2) => {
      let { parser: r2, funcName: n2 } = e2;
      const o2 = pt(t2[0]);
      let s2 = n2;
      return s2 in kn && (s2 = kn[s2]), { type: "font", mode: r2.mode, font: s2.slice(1), body: o2 };
    }, htmlBuilder: wn, mathmlBuilder: vn }), mt({ type: "mclass", names: ["\\boldsymbol", "\\bm"], props: { numArgs: 1 }, handler: (e2, t2) => {
      let { parser: r2 } = e2;
      const n2 = t2[0];
      return { type: "mclass", mode: r2.mode, mclass: dr(n2), body: [{ type: "font", mode: r2.mode, font: "boldsymbol", body: n2 }], isCharacterBox: m(n2) };
    } }), mt({ type: "font", names: ["\\rm", "\\sf", "\\tt", "\\bf", "\\it", "\\cal"], props: { numArgs: 0, allowedInText: true }, handler: (e2, t2) => {
      let { parser: r2, funcName: n2, breakOnTokenText: o2 } = e2;
      const { mode: s2 } = r2, i2 = r2.parseExpression(true, o2);
      return { type: "font", mode: s2, font: "math" + n2.slice(1), body: { type: "ordgroup", mode: r2.mode, body: i2 } };
    }, htmlBuilder: wn, mathmlBuilder: vn });
    const zn = (e2, t2) => {
      if (!t2) return e2;
      return { type: "styling", mode: e2.mode, style: t2, body: [e2] };
    };
    mt({ type: "genfrac", names: ["\\cfrac", "\\dfrac", "\\frac", "\\tfrac", "\\dbinom", "\\binom", "\\tbinom", "\\\\atopfrac", "\\\\bracefrac", "\\\\brackfrac"], props: { numArgs: 2, allowedInArgument: true }, handler: (e2, t2) => {
      let { parser: r2, funcName: n2 } = e2;
      const o2 = t2[0], s2 = t2[1];
      let i2, l2 = null, a2 = null;
      switch (n2) {
        case "\\cfrac":
        case "\\dfrac":
        case "\\frac":
        case "\\tfrac":
          i2 = true;
          break;
        case "\\\\atopfrac":
          i2 = false;
          break;
        case "\\dbinom":
        case "\\binom":
        case "\\tbinom":
          i2 = false, l2 = "(", a2 = ")";
          break;
        case "\\\\bracefrac":
          i2 = false, l2 = "\\{", a2 = "\\}";
          break;
        case "\\\\brackfrac":
          i2 = false, l2 = "[", a2 = "]";
          break;
        default:
          throw new Error("Unrecognized genfrac command");
      }
      const c2 = "\\cfrac" === n2;
      let h2 = null;
      return c2 || n2.startsWith("\\d") ? h2 = "display" : n2.startsWith("\\t") && (h2 = "text"), zn({ type: "genfrac", mode: r2.mode, numer: o2, denom: s2, continued: c2, hasBarLine: i2, leftDelim: l2, rightDelim: a2, barSize: null }, h2);
    }, htmlBuilder: (e2, t2) => {
      const r2 = t2.style, n2 = r2.fracNum(), o2 = r2.fracDen();
      let s2;
      s2 = t2.havingStyle(n2);
      const i2 = Mt(e2.numer, s2, t2);
      if (e2.continued) {
        const e3 = 8.5 / t2.fontMetrics().ptPerEm, r3 = 3.5 / t2.fontMetrics().ptPerEm;
        i2.height = i2.height < e3 ? e3 : i2.height, i2.depth = i2.depth < r3 ? r3 : i2.depth;
      }
      s2 = t2.havingStyle(o2);
      const l2 = Mt(e2.denom, s2, t2);
      let a2, c2, h2, m2, u2, p2, d2, g2, f2, b2;
      if (e2.hasBarLine ? (e2.barSize ? (c2 = N(e2.barSize, t2), a2 = _e("frac-line", t2, c2)) : a2 = _e("frac-line", t2), c2 = a2.height, h2 = a2.height) : (a2 = null, c2 = 0, h2 = t2.fontMetrics().defaultRuleThickness), r2.size === S.DISPLAY.size ? (m2 = t2.fontMetrics().num1, u2 = c2 > 0 ? 3 * h2 : 7 * h2, p2 = t2.fontMetrics().denom1) : (c2 > 0 ? (m2 = t2.fontMetrics().num2, u2 = h2) : (m2 = t2.fontMetrics().num3, u2 = 3 * h2), p2 = t2.fontMetrics().denom2), a2) {
        const e3 = t2.fontMetrics().axisHeight;
        m2 - i2.depth - (e3 + 0.5 * c2) < u2 && (m2 += u2 - (m2 - i2.depth - (e3 + 0.5 * c2))), e3 - 0.5 * c2 - (l2.height - p2) < u2 && (p2 += u2 - (e3 - 0.5 * c2 - (l2.height - p2)));
        d2 = Ke({ positionType: "individualShift", children: [{ type: "elem", elem: l2, shift: p2 }, { type: "elem", elem: a2, shift: -(e3 - 0.5 * c2) }, { type: "elem", elem: i2, shift: -m2 }] });
      } else {
        const e3 = m2 - i2.depth - (l2.height - p2);
        e3 < u2 && (m2 += 0.5 * (u2 - e3), p2 += 0.5 * (u2 - e3)), d2 = Ke({ positionType: "individualShift", children: [{ type: "elem", elem: l2, shift: p2 }, { type: "elem", elem: i2, shift: -m2 }] });
      }
      return s2 = t2.havingStyle(r2), d2.height *= s2.sizeMultiplier / t2.sizeMultiplier, d2.depth *= s2.sizeMultiplier / t2.sizeMultiplier, g2 = r2.size === S.DISPLAY.size ? t2.fontMetrics().delim1 : r2.size === S.SCRIPTSCRIPT.size ? t2.havingStyle(S.SCRIPT).fontMetrics().delim2 : t2.fontMetrics().delim2, f2 = null == e2.leftDelim ? St(t2, ["mopen"]) : Wr(e2.leftDelim, g2, true, t2.havingStyle(r2), e2.mode, ["mopen"]), b2 = e2.continued ? je([]) : null == e2.rightDelim ? St(t2, ["mclose"]) : Wr(e2.rightDelim, g2, true, t2.havingStyle(r2), e2.mode, ["mclose"]), je(["mord"].concat(s2.sizingClasses(t2)), [f2, je(["mfrac"], [d2]), b2], t2);
    }, mathmlBuilder: (e2, t2) => {
      const r2 = new Ct("mfrac", [Vt(e2.numer, t2), Vt(e2.denom, t2)]);
      if (e2.hasBarLine) {
        if (e2.barSize) {
          const n2 = N(e2.barSize, t2);
          r2.setAttribute("linethickness", O(n2));
        }
      } else r2.setAttribute("linethickness", "0px");
      if (null != e2.leftDelim || null != e2.rightDelim) {
        const t3 = [];
        if (null != e2.leftDelim) {
          const r3 = new Ct("mo", [new qt(e2.leftDelim.replace("\\", ""))]);
          r3.setAttribute("fence", "true"), t3.push(r3);
        }
        if (t3.push(r2), null != e2.rightDelim) {
          const r3 = new Ct("mo", [new qt(e2.rightDelim.replace("\\", ""))]);
          r3.setAttribute("fence", "true"), t3.push(r3);
        }
        return Nt(t3);
      }
      return r2;
    } }), mt({ type: "infix", names: ["\\over", "\\choose", "\\atop", "\\brace", "\\brack"], props: { numArgs: 0, infix: true }, handler(e2) {
      let t2, { parser: r2, funcName: n2, token: o2 } = e2;
      switch (n2) {
        case "\\over":
          t2 = "\\frac";
          break;
        case "\\choose":
          t2 = "\\binom";
          break;
        case "\\atop":
          t2 = "\\\\atopfrac";
          break;
        case "\\brace":
          t2 = "\\\\bracefrac";
          break;
        case "\\brack":
          t2 = "\\\\brackfrac";
          break;
        default:
          throw new Error("Unrecognized infix genfrac command");
      }
      return { type: "infix", mode: r2.mode, replaceWith: t2, token: o2 };
    } });
    const Sn = ["display", "text", "script", "scriptscript"], Mn = function(e2) {
      let t2 = null;
      return e2.length > 0 && (t2 = e2, t2 = "." === t2 ? null : t2), t2;
    };
    mt({ type: "genfrac", names: ["\\genfrac"], props: { numArgs: 6, allowedInArgument: true, argTypes: ["math", "math", "size", "text", "math", "math"] }, handler(e2, t2) {
      let { parser: r2 } = e2;
      const n2 = t2[4], o2 = t2[5], s2 = pt(t2[0]), i2 = "atom" === s2.type && "open" === s2.family ? Mn(s2.text) : null, l2 = pt(t2[1]), a2 = "atom" === l2.type && "close" === l2.family ? Mn(l2.text) : null, c2 = or(t2[2], "size");
      let h2, m2 = null;
      c2.isBlank ? h2 = true : (m2 = c2.value, h2 = m2.number > 0);
      let u2 = null, p2 = t2[3];
      if ("ordgroup" === p2.type) {
        if (p2.body.length > 0) {
          const e3 = or(p2.body[0], "textord");
          u2 = Sn[Number(e3.text)];
        }
      } else p2 = or(p2, "textord"), u2 = Sn[Number(p2.text)];
      return zn({ type: "genfrac", mode: r2.mode, numer: n2, denom: o2, continued: false, hasBarLine: h2, barSize: m2, leftDelim: i2, rightDelim: a2 }, u2);
    } }), mt({ type: "infix", names: ["\\above"], props: { numArgs: 1, argTypes: ["size"], infix: true }, handler(e2, t2) {
      let { parser: r2, funcName: n2, token: o2 } = e2;
      return { type: "infix", mode: r2.mode, replaceWith: "\\\\abovefrac", size: or(t2[0], "size").value, token: o2 };
    } }), mt({ type: "genfrac", names: ["\\\\abovefrac"], props: { numArgs: 3, argTypes: ["math", "size", "math"] }, handler: (e2, t2) => {
      let { parser: r2, funcName: n2 } = e2;
      const o2 = t2[0], s2 = or(t2[1], "infix").size;
      if (!s2) throw new Error("\\\\abovefrac expected size, but got " + String(s2));
      const i2 = t2[2], l2 = s2.number > 0;
      return { type: "genfrac", mode: r2.mode, numer: o2, denom: i2, continued: false, hasBarLine: l2, barSize: s2, leftDelim: null, rightDelim: null };
    } });
    const An = (e2, t2) => {
      const r2 = t2.style;
      let n2, o2;
      "supsub" === e2.type ? (n2 = e2.sup ? Mt(e2.sup, t2.havingStyle(r2.sup()), t2) : Mt(e2.sub, t2.havingStyle(r2.sub()), t2), o2 = or(e2.base, "horizBrace")) : o2 = or(e2, "horizBrace");
      const s2 = Mt(o2.base, t2.havingBaseStyle(S.DISPLAY)), i2 = tr(o2, t2);
      let l2;
      if (l2 = o2.isOver ? Ke({ positionType: "firstBaseline", children: [{ type: "elem", elem: s2 }, { type: "kern", size: 0.1 }, { type: "elem", elem: i2, wrapperClasses: ["svg-align"] }] }) : Ke({ positionType: "bottom", positionData: s2.depth + 0.1 + i2.height, children: [{ type: "elem", elem: i2, wrapperClasses: ["svg-align"] }, { type: "kern", size: 0.1 }, { type: "elem", elem: s2 }] }), n2) {
        const e3 = je(["minner", o2.isOver ? "mover" : "munder"], [l2], t2);
        l2 = o2.isOver ? Ke({ positionType: "firstBaseline", children: [{ type: "elem", elem: e3 }, { type: "kern", size: 0.2 }, { type: "elem", elem: n2 }] }) : Ke({ positionType: "bottom", positionData: e3.depth + 0.2 + n2.height + n2.depth, children: [{ type: "elem", elem: n2 }, { type: "kern", size: 0.2 }, { type: "elem", elem: e3 }] });
      }
      return je(["minner", o2.isOver ? "mover" : "munder"], [l2], t2);
    };
    mt({ type: "horizBrace", names: ["\\overbrace", "\\underbrace", "\\overbracket", "\\underbracket"], props: { numArgs: 1 }, handler(e2, t2) {
      let { parser: r2, funcName: n2 } = e2;
      return { type: "horizBrace", mode: r2.mode, label: n2, isOver: n2.includes("\\over"), base: t2[0] };
    }, htmlBuilder: An, mathmlBuilder: (e2, t2) => {
      const r2 = Jt(e2.label);
      return new Ct(e2.isOver ? "mover" : "munder", [Vt(e2.base, t2), r2]);
    } }), mt({ type: "href", names: ["\\href"], props: { numArgs: 2, argTypes: ["url", "original"], allowedInText: true }, handler: (e2, t2) => {
      let { parser: r2 } = e2;
      const n2 = t2[1], o2 = or(t2[0], "url").url;
      return r2.settings.isTrusted({ command: "\\href", url: o2 }) ? { type: "href", mode: r2.mode, href: o2, body: dt(n2) } : r2.formatUnsupportedCmd("\\href");
    }, htmlBuilder: (e2, t2) => {
      const r2 = xt(e2.body, t2, false);
      return (function(e3, t3, r3, n2) {
        const o2 = new X(e3, t3, r3, n2);
        return Ye(o2), o2;
      })(e2.href, [], r2, t2);
    }, mathmlBuilder: (e2, t2) => {
      let r2 = Ft(e2.body, t2);
      return r2 instanceof Ct || (r2 = new Ct("mrow", [r2])), r2.setAttribute("href", e2.href), r2;
    } }), mt({ type: "href", names: ["\\url"], props: { numArgs: 1, argTypes: ["url"], allowedInText: true }, handler: (e2, t2) => {
      let { parser: r2 } = e2;
      const n2 = or(t2[0], "url").url;
      if (!r2.settings.isTrusted({ command: "\\url", url: n2 })) return r2.formatUnsupportedCmd("\\url");
      const o2 = [];
      for (let e3 = 0; e3 < n2.length; e3++) {
        let t3 = n2[e3];
        "~" === t3 && (t3 = "\\textasciitilde"), o2.push({ type: "textord", mode: "text", text: t3 });
      }
      const s2 = { type: "text", mode: r2.mode, font: "\\texttt", body: o2 };
      return { type: "href", mode: r2.mode, href: n2, body: dt(s2) };
    } }), mt({ type: "hbox", names: ["\\hbox"], props: { numArgs: 1, argTypes: ["text"], allowedInText: true, primitive: true }, handler(e2, t2) {
      let { parser: r2 } = e2;
      return { type: "hbox", mode: r2.mode, body: dt(t2[0]) };
    }, htmlBuilder(e2, t2) {
      const r2 = xt(e2.body, t2.withFont(""), false);
      return $e(r2);
    }, mathmlBuilder(e2, t2) {
      return new Ct("mrow", Pt(e2.body, t2.withFont("")));
    } }), mt({ type: "html", names: ["\\htmlClass", "\\htmlId", "\\htmlStyle", "\\htmlData"], props: { numArgs: 2, argTypes: ["raw", "original"], allowedInText: true }, handler: (e2, t2) => {
      let { parser: r2, funcName: o2, token: s2 } = e2;
      const i2 = or(t2[0], "raw").string, l2 = t2[1];
      let a2;
      r2.settings.strict && r2.settings.reportNonstrict("htmlExtension", "HTML extension is disabled on strict mode");
      const c2 = {};
      switch (o2) {
        case "\\htmlClass":
          c2.class = i2, a2 = { command: "\\htmlClass", class: i2 };
          break;
        case "\\htmlId":
          c2.id = i2, a2 = { command: "\\htmlId", id: i2 };
          break;
        case "\\htmlStyle":
          c2.style = i2, a2 = { command: "\\htmlStyle", style: i2 };
          break;
        case "\\htmlData": {
          const e3 = i2.split(",");
          for (let t3 = 0; t3 < e3.length; t3++) {
            const r3 = e3[t3], o3 = r3.indexOf("=");
            if (o3 < 0) throw new n("\\htmlData key/value '" + r3 + "' missing equals sign");
            const s3 = r3.slice(0, o3), i3 = r3.slice(o3 + 1);
            c2["data-" + s3.trim()] = i3;
          }
          a2 = { command: "\\htmlData", attributes: c2 };
          break;
        }
        default:
          throw new Error("Unrecognized html command");
      }
      return r2.settings.isTrusted(a2) ? { type: "html", mode: r2.mode, attributes: c2, body: dt(l2) } : r2.formatUnsupportedCmd(o2);
    }, htmlBuilder: (e2, t2) => {
      const r2 = xt(e2.body, t2, false), n2 = ["enclosing"];
      e2.attributes.class && n2.push(...e2.attributes.class.trim().split(/\s+/));
      const o2 = je(n2, r2, t2);
      for (const t3 in e2.attributes) "class" !== t3 && e2.attributes.hasOwnProperty(t3) && o2.setAttribute(t3, e2.attributes[t3]);
      return o2;
    }, mathmlBuilder: (e2, t2) => Ft(e2.body, t2) }), mt({ type: "htmlmathml", names: ["\\html@mathml"], props: { numArgs: 2, allowedInArgument: true, allowedInText: true }, handler: (e2, t2) => {
      let { parser: r2 } = e2;
      return { type: "htmlmathml", mode: r2.mode, html: dt(t2[0]), mathml: dt(t2[1]) };
    }, htmlBuilder: (e2, t2) => {
      const r2 = xt(e2.html, t2, false);
      return $e(r2);
    }, mathmlBuilder: (e2, t2) => Ft(e2.mathml, t2) });
    const Tn = function(e2) {
      if (/^[-+]? *(\d+(\.\d*)?|\.\d+)$/.test(e2)) return { number: +e2, unit: "bp" };
      {
        const t2 = /([-+]?) *(\d+(?:\.\d*)?|\.\d+) *([a-z]{2})/.exec(e2);
        if (!t2) throw new n("Invalid size: '" + e2 + "' in \\includegraphics");
        const r2 = { number: +(t2[1] + t2[2]), unit: t2[3] };
        if (!H(r2)) throw new n("Invalid unit: '" + r2.unit + "' in \\includegraphics.");
        return r2;
      }
    };
    mt({ type: "includegraphics", names: ["\\includegraphics"], props: { numArgs: 1, numOptionalArgs: 1, argTypes: ["raw", "url"], allowedInText: false }, handler: (e2, t2, r2) => {
      let { parser: o2 } = e2, s2 = { number: 0, unit: "em" }, i2 = { number: 0.9, unit: "em" }, l2 = { number: 0, unit: "em" }, a2 = "";
      if (r2[0]) {
        const e3 = or(r2[0], "raw").string.split(",");
        for (let t3 = 0; t3 < e3.length; t3++) {
          const r3 = e3[t3].split("=");
          if (2 === r3.length) {
            const e4 = r3[1].trim();
            switch (r3[0].trim()) {
              case "alt":
                a2 = e4;
                break;
              case "width":
                s2 = Tn(e4);
                break;
              case "height":
                i2 = Tn(e4);
                break;
              case "totalheight":
                l2 = Tn(e4);
                break;
              default:
                throw new n("Invalid key: '" + r3[0] + "' in \\includegraphics.");
            }
          }
        }
      }
      const c2 = or(t2[0], "url").url;
      return "" === a2 && (a2 = c2, a2 = a2.replace(/^.*[\\/]/, ""), a2 = a2.substring(0, a2.lastIndexOf("."))), o2.settings.isTrusted({ command: "\\includegraphics", url: c2 }) ? { type: "includegraphics", mode: o2.mode, alt: a2, width: s2, height: i2, totalheight: l2, src: c2 } : o2.formatUnsupportedCmd("\\includegraphics");
    }, htmlBuilder: (e2, t2) => {
      const r2 = N(e2.height, t2);
      let n2 = 0;
      e2.totalheight.number > 0 && (n2 = N(e2.totalheight, t2) - r2);
      let o2 = 0;
      e2.width.number > 0 && (o2 = N(e2.width, t2));
      const s2 = { height: O(r2 + n2) };
      o2 > 0 && (s2.width = O(o2)), n2 > 0 && (s2.verticalAlign = O(-n2));
      const i2 = new Y(e2.src, e2.alt, s2);
      return i2.height = r2, i2.depth = n2, i2;
    }, mathmlBuilder: (e2, t2) => {
      const r2 = new Ct("mglyph", []);
      r2.setAttribute("alt", e2.alt);
      const n2 = N(e2.height, t2);
      let o2 = 0;
      if (e2.totalheight.number > 0 && (o2 = N(e2.totalheight, t2) - n2, r2.setAttribute("valign", O(-o2))), r2.setAttribute("height", O(n2 + o2)), e2.width.number > 0) {
        const n3 = N(e2.width, t2);
        r2.setAttribute("width", O(n3));
      }
      return r2.setAttribute("src", e2.src), r2;
    } }), mt({ type: "kern", names: ["\\kern", "\\mkern", "\\hskip", "\\mskip"], props: { numArgs: 1, argTypes: ["size"], primitive: true, allowedInText: true }, handler(e2, t2) {
      let { parser: r2, funcName: n2 } = e2;
      const o2 = or(t2[0], "size");
      if (r2.settings.strict) {
        const e3 = "m" === n2[1], t3 = "mu" === o2.value.unit;
        e3 ? (t3 || r2.settings.reportNonstrict("mathVsTextUnits", "LaTeX's " + n2 + " supports only mu units, not " + o2.value.unit + " units"), "math" !== r2.mode && r2.settings.reportNonstrict("mathVsTextUnits", "LaTeX's " + n2 + " works only in math mode")) : t3 && r2.settings.reportNonstrict("mathVsTextUnits", "LaTeX's " + n2 + " doesn't support mu units");
      }
      return { type: "kern", mode: r2.mode, dimension: o2.value };
    }, htmlBuilder(e2, t2) {
      return Je(e2.dimension, t2);
    }, mathmlBuilder(e2, t2) {
      const r2 = N(e2.dimension, t2);
      return new It(r2);
    } }), mt({ type: "lap", names: ["\\mathllap", "\\mathrlap", "\\mathclap"], props: { numArgs: 1, allowedInText: true }, handler: (e2, t2) => {
      let { parser: r2, funcName: n2 } = e2;
      const o2 = t2[0];
      return { type: "lap", mode: r2.mode, alignment: n2.slice(5), body: o2 };
    }, htmlBuilder: (e2, t2) => {
      let r2;
      "clap" === e2.alignment ? (r2 = je([], [Mt(e2.body, t2)]), r2 = je(["inner"], [r2], t2)) : r2 = je(["inner"], [Mt(e2.body, t2)]);
      const n2 = je(["fix"], []);
      let o2 = je([e2.alignment], [r2, n2], t2);
      const s2 = je(["strut"]);
      return s2.style.height = O(o2.height + o2.depth), o2.depth && (s2.style.verticalAlign = O(-o2.depth)), o2.children.unshift(s2), o2 = je(["thinbox"], [o2], t2), je(["mord", "vbox"], [o2], t2);
    }, mathmlBuilder: (e2, t2) => {
      const r2 = new Ct("mpadded", [Vt(e2.body, t2)]);
      if ("rlap" !== e2.alignment) {
        const t3 = "llap" === e2.alignment ? "-1" : "-0.5";
        r2.setAttribute("lspace", t3 + "width");
      }
      return r2.setAttribute("width", "0px"), r2;
    } }), mt({ type: "styling", names: ["\\(", "$"], props: { numArgs: 0, allowedInText: true, allowedInMath: false }, handler(e2, t2) {
      let { funcName: r2, parser: n2 } = e2;
      const o2 = n2.mode;
      n2.switchMode("math");
      const s2 = "\\(" === r2 ? "\\)" : "$", i2 = n2.parseExpression(false, s2);
      return n2.expect(s2), n2.switchMode(o2), { type: "styling", mode: n2.mode, style: "text", resetFont: true, body: i2 };
    } }), mt({ type: "text", names: ["\\)", "\\]"], props: { numArgs: 0, allowedInText: true, allowedInMath: false }, handler(e2, t2) {
      throw new n("Mismatched " + e2.funcName);
    } });
    const Bn = (e2, t2) => {
      switch (t2.style.size) {
        case S.DISPLAY.size:
          return e2.display;
        case S.TEXT.size:
          return e2.text;
        case S.SCRIPT.size:
          return e2.script;
        case S.SCRIPTSCRIPT.size:
          return e2.scriptscript;
        default:
          return e2.text;
      }
    };
    mt({ type: "mathchoice", names: ["\\mathchoice"], props: { numArgs: 4, primitive: true }, handler: (e2, t2) => {
      let { parser: r2 } = e2;
      return { type: "mathchoice", mode: r2.mode, display: dt(t2[0]), text: dt(t2[1]), script: dt(t2[2]), scriptscript: dt(t2[3]) };
    }, htmlBuilder: (e2, t2) => {
      const r2 = Bn(e2, t2), n2 = xt(r2, t2, false);
      return $e(n2);
    }, mathmlBuilder: (e2, t2) => {
      const r2 = Bn(e2, t2);
      return Ft(r2, t2);
    } });
    const Cn = (e2, t2, r2, n2, o2, s2, i2) => {
      e2 = je([], [e2]);
      const l2 = r2 && m(r2);
      let a2, c2, h2;
      if (t2) {
        const e3 = Mt(t2, n2.havingStyle(o2.sup()), n2);
        c2 = { elem: e3, kern: Math.max(n2.fontMetrics().bigOpSpacing1, n2.fontMetrics().bigOpSpacing3 - e3.depth) };
      }
      if (r2) {
        const e3 = Mt(r2, n2.havingStyle(o2.sub()), n2);
        a2 = { elem: e3, kern: Math.max(n2.fontMetrics().bigOpSpacing2, n2.fontMetrics().bigOpSpacing4 - e3.height) };
      }
      if (c2 && a2) {
        const t3 = n2.fontMetrics().bigOpSpacing5 + a2.elem.height + a2.elem.depth + a2.kern + e2.depth + i2;
        h2 = Ke({ positionType: "bottom", positionData: t3, children: [{ type: "kern", size: n2.fontMetrics().bigOpSpacing5 }, { type: "elem", elem: a2.elem, marginLeft: O(-s2) }, { type: "kern", size: a2.kern }, { type: "elem", elem: e2 }, { type: "kern", size: c2.kern }, { type: "elem", elem: c2.elem, marginLeft: O(s2) }, { type: "kern", size: n2.fontMetrics().bigOpSpacing5 }] });
      } else if (a2) {
        const t3 = e2.height - i2;
        h2 = Ke({ positionType: "top", positionData: t3, children: [{ type: "kern", size: n2.fontMetrics().bigOpSpacing5 }, { type: "elem", elem: a2.elem, marginLeft: O(-s2) }, { type: "kern", size: a2.kern }, { type: "elem", elem: e2 }] });
      } else {
        if (!c2) return e2;
        {
          const t3 = e2.depth + i2;
          h2 = Ke({ positionType: "bottom", positionData: t3, children: [{ type: "elem", elem: e2 }, { type: "kern", size: c2.kern }, { type: "elem", elem: c2.elem, marginLeft: O(s2) }, { type: "kern", size: n2.fontMetrics().bigOpSpacing5 }] });
        }
      }
      const u2 = [h2];
      if (a2 && 0 !== s2 && !l2) {
        const e3 = je(["mspace"], [], n2);
        e3.style.marginRight = O(s2), u2.unshift(e3);
      }
      return je(["mop", "op-limits"], u2, n2);
    }, qn = /* @__PURE__ */ new Set(["\\smallint"]), In = (e2, t2) => {
      let r2, n2, o2, s2 = false;
      "supsub" === e2.type ? (r2 = e2.sup, n2 = e2.sub, o2 = or(e2.base, "op"), s2 = true) : o2 = or(e2, "op");
      const i2 = t2.style;
      let l2, a2, c2 = false;
      if (i2.size === S.DISPLAY.size && o2.symbol && !qn.has(o2.name) && (c2 = true), o2.symbol) {
        const e3 = c2 ? "Size2-Regular" : "Size1-Regular";
        let r3 = "";
        if ("\\oiint" !== o2.name && "\\oiiint" !== o2.name || (r3 = o2.name.slice(1), o2.name = "oiint" === r3 ? "\\iint" : "\\iiint"), l2 = Fe(o2.name, e3, "math", t2, ["mop", "op-symbol", c2 ? "large-op" : "small-op"]), a2 = l2.italic, r3.length > 0) {
          const e4 = rt(r3 + "Size" + (c2 ? "2" : "1"), t2);
          l2 = Ke({ positionType: "individualShift", children: [{ type: "elem", elem: l2, shift: 0 }, { type: "elem", elem: e4, shift: c2 ? 0.08 : 0 }] }), o2.name = "\\" + r3, l2.classes.unshift("mop"), l2.italic = a2;
        }
      } else if (o2.body) {
        const e3 = xt(o2.body, t2, true);
        1 === e3.length && e3[0] instanceof W ? (l2 = e3[0], l2.classes[0] = "mop") : l2 = je(["mop"], e3, t2);
      } else {
        const e3 = [];
        for (let r3 = 1; r3 < o2.name.length; r3++) e3.push(Ve(o2.name[r3], o2.mode, t2));
        l2 = je(["mop"], e3, t2);
      }
      let h2 = 0, m2 = 0;
      var u2;
      (l2 instanceof W || "\\oiint" === o2.name || "\\oiiint" === o2.name) && !o2.suppressBaseShift && (h2 = (l2.height - l2.depth) / 2 - t2.fontMetrics().axisHeight, m2 = null != (u2 = l2.italic) ? u2 : 0);
      return s2 ? Cn(l2, r2, n2, t2, i2, m2, h2) : (h2 && (l2.style.position = "relative", l2.style.top = O(h2)), l2);
    }, Rn = (e2, t2) => {
      let r2;
      if (e2.symbol) r2 = new Ct("mo", [Ht(e2.name, e2.mode)]), qn.has(e2.name) && r2.setAttribute("largeop", "false");
      else if (e2.body) r2 = new Ct("mo", Pt(e2.body, t2));
      else {
        r2 = new Ct("mi", [new qt(e2.name.slice(1))]);
        const t3 = new Ct("mo", [Ht("\u2061", "text")]);
        r2 = e2.parentIsSupSub ? new Ct("mrow", [r2, t3]) : Bt([r2, t3]);
      }
      return r2;
    }, En = { "\u220F": "\\prod", "\u2210": "\\coprod", "\u2211": "\\sum", "\u22C0": "\\bigwedge", "\u22C1": "\\bigvee", "\u22C2": "\\bigcap", "\u22C3": "\\bigcup", "\u2A00": "\\bigodot", "\u2A01": "\\bigoplus", "\u2A02": "\\bigotimes", "\u2A04": "\\biguplus", "\u2A06": "\\bigsqcup" };
    mt({ type: "op", names: ["\\coprod", "\\bigvee", "\\bigwedge", "\\biguplus", "\\bigcap", "\\bigcup", "\\intop", "\\prod", "\\sum", "\\bigotimes", "\\bigoplus", "\\bigodot", "\\bigsqcup", "\\smallint", "\u220F", "\u2210", "\u2211", "\u22C0", "\u22C1", "\u22C2", "\u22C3", "\u2A00", "\u2A01", "\u2A02", "\u2A04", "\u2A06"], props: { numArgs: 0 }, handler: (e2, t2) => {
      let { parser: r2, funcName: n2 } = e2, o2 = n2;
      return 1 === o2.length && (o2 = En[o2]), { type: "op", mode: r2.mode, limits: true, parentIsSupSub: false, symbol: true, name: o2 };
    }, htmlBuilder: In, mathmlBuilder: Rn }), mt({ type: "op", names: ["\\mathop"], props: { numArgs: 1, primitive: true }, handler: (e2, t2) => {
      let { parser: r2 } = e2;
      const n2 = t2[0];
      return { type: "op", mode: r2.mode, limits: false, parentIsSupSub: false, symbol: false, body: dt(n2) };
    }, htmlBuilder: In, mathmlBuilder: Rn });
    const Hn = { "\u222B": "\\int", "\u222C": "\\iint", "\u222D": "\\iiint", "\u222E": "\\oint", "\u222F": "\\oiint", "\u2230": "\\oiiint" };
    mt({ type: "op", names: ["\\arcsin", "\\arccos", "\\arctan", "\\arctg", "\\arcctg", "\\arg", "\\ch", "\\cos", "\\cosec", "\\cosh", "\\cot", "\\cotg", "\\coth", "\\csc", "\\ctg", "\\cth", "\\deg", "\\dim", "\\exp", "\\hom", "\\ker", "\\lg", "\\ln", "\\log", "\\sec", "\\sin", "\\sinh", "\\sh", "\\tan", "\\tanh", "\\tg", "\\th"], props: { numArgs: 0 }, handler(e2) {
      let { parser: t2, funcName: r2 } = e2;
      return { type: "op", mode: t2.mode, limits: false, parentIsSupSub: false, symbol: false, name: r2 };
    }, htmlBuilder: In, mathmlBuilder: Rn }), mt({ type: "op", names: ["\\det", "\\gcd", "\\inf", "\\lim", "\\max", "\\min", "\\Pr", "\\sup"], props: { numArgs: 0 }, handler(e2) {
      let { parser: t2, funcName: r2 } = e2;
      return { type: "op", mode: t2.mode, limits: true, parentIsSupSub: false, symbol: false, name: r2 };
    }, htmlBuilder: In, mathmlBuilder: Rn }), mt({ type: "op", names: ["\\int", "\\iint", "\\iiint", "\\oint", "\\oiint", "\\oiiint", "\u222B", "\u222C", "\u222D", "\u222E", "\u222F", "\u2230"], props: { numArgs: 0, allowedInArgument: true }, handler(e2) {
      let { parser: t2, funcName: r2 } = e2, n2 = r2;
      return 1 === n2.length && (n2 = Hn[n2]), { type: "op", mode: t2.mode, limits: false, parentIsSupSub: false, symbol: true, name: n2 };
    }, htmlBuilder: In, mathmlBuilder: Rn });
    const Nn = (e2, t2) => {
      let r2, n2, o2, s2, i2 = false;
      if ("supsub" === e2.type ? (r2 = e2.sup, n2 = e2.sub, o2 = or(e2.base, "operatorname"), i2 = true) : o2 = or(e2, "operatorname"), o2.body.length > 0) {
        const e3 = o2.body.map((e4) => {
          const t3 = "text" in e4 ? e4.text : void 0;
          return "string" == typeof t3 ? { type: "textord", mode: e4.mode, text: t3 } : e4;
        }), r3 = xt(e3, t2.withFont("mathrm"), true);
        for (let e4 = 0; e4 < r3.length; e4++) {
          const t3 = r3[e4];
          t3 instanceof W && (t3.text = t3.text.replace(/\u2212/, "-").replace(/\u2217/, "*"));
        }
        s2 = je(["mop"], r3, t2);
      } else s2 = je(["mop"], [], t2);
      return i2 ? Cn(s2, r2, n2, t2, t2.style, 0, 0) : s2;
    };
    function On(e2, t2, r2) {
      const n2 = xt(e2, t2, false), o2 = t2.sizeMultiplier / r2.sizeMultiplier;
      for (let e3 = 0; e3 < n2.length; e3++) {
        const s2 = n2[e3].classes.indexOf("sizing");
        s2 < 0 ? Array.prototype.push.apply(n2[e3].classes, t2.sizingClasses(r2)) : n2[e3].classes[s2 + 1] === "reset-size" + t2.size && (n2[e3].classes[s2 + 1] = "reset-size" + r2.size), n2[e3].height *= o2, n2[e3].depth *= o2;
      }
      return $e(n2);
    }
    mt({ type: "operatorname", names: ["\\operatorname@", "\\operatornamewithlimits"], props: { numArgs: 1 }, handler: (e2, t2) => {
      let { parser: r2, funcName: n2 } = e2;
      const o2 = t2[0];
      return { type: "operatorname", mode: r2.mode, body: dt(o2), alwaysHandleSupSub: "\\operatornamewithlimits" === n2, limits: false, parentIsSupSub: false };
    }, htmlBuilder: Nn, mathmlBuilder: (e2, t2) => {
      let r2 = Pt(e2.body, t2.withFont("mathrm")), n2 = true;
      for (let e3 = 0; e3 < r2.length; e3++) {
        const t3 = r2[e3];
        if (t3 instanceof It) ;
        else if (t3 instanceof Ct) switch (t3.type) {
          case "mi":
          case "mn":
          case "mspace":
          case "mtext":
            break;
          case "mo": {
            const e4 = t3.children[0];
            1 === t3.children.length && e4 instanceof qt ? e4.text = e4.text.replace(/\u2212/, "-").replace(/\u2217/, "*") : n2 = false;
            break;
          }
          default:
            n2 = false;
        }
        else n2 = false;
      }
      if (n2) {
        const e3 = r2.map((e4) => e4.toText()).join("");
        r2 = [new qt(e3)];
      }
      const o2 = new Ct("mi", r2);
      o2.setAttribute("mathvariant", "normal");
      const s2 = new Ct("mo", [Ht("\u2061", "text")]);
      return e2.parentIsSupSub ? new Ct("mrow", [o2, s2]) : Bt([o2, s2]);
    } }), sn("\\operatorname", "\\@ifstar\\operatornamewithlimits\\operatorname@"), ut({ type: "ordgroup", htmlBuilder(e2, t2) {
      return e2.semisimple ? $e(xt(e2.body, t2, false)) : je(["mord"], xt(e2.body, t2, true), t2);
    }, mathmlBuilder(e2, t2) {
      return Ft(e2.body, t2, true);
    } }), mt({ type: "overline", names: ["\\overline"], props: { numArgs: 1 }, handler(e2, t2) {
      let { parser: r2 } = e2;
      const n2 = t2[0];
      return { type: "overline", mode: r2.mode, body: n2 };
    }, htmlBuilder(e2, t2) {
      const r2 = Mt(e2.body, t2.havingCrampedStyle()), n2 = _e("overline-line", t2), o2 = t2.fontMetrics().defaultRuleThickness, s2 = Ke({ positionType: "firstBaseline", children: [{ type: "elem", elem: r2 }, { type: "kern", size: 3 * o2 }, { type: "elem", elem: n2 }, { type: "kern", size: o2 }] });
      return je(["mord", "overline"], [s2], t2);
    }, mathmlBuilder(e2, t2) {
      const r2 = new Ct("mo", [new qt("\u203E")]);
      r2.setAttribute("stretchy", "true");
      const n2 = new Ct("mover", [Vt(e2.body, t2), r2]);
      return n2.setAttribute("accent", "true"), n2;
    } }), mt({ type: "phantom", names: ["\\phantom"], props: { numArgs: 1, allowedInText: true }, handler: (e2, t2) => {
      let { parser: r2 } = e2;
      const n2 = t2[0];
      return { type: "phantom", mode: r2.mode, body: dt(n2) };
    }, htmlBuilder: (e2, t2) => {
      const r2 = xt(e2.body, t2.withPhantom(), false);
      return $e(r2);
    }, mathmlBuilder: (e2, t2) => {
      const r2 = Pt(e2.body, t2);
      return new Ct("mphantom", r2);
    } }), sn("\\hphantom", "\\smash{\\phantom{#1}}"), mt({ type: "vphantom", names: ["\\vphantom"], props: { numArgs: 1, allowedInText: true }, handler: (e2, t2) => {
      let { parser: r2 } = e2;
      const n2 = t2[0];
      return { type: "vphantom", mode: r2.mode, body: n2 };
    }, htmlBuilder: (e2, t2) => {
      const r2 = je(["inner"], [Mt(e2.body, t2.withPhantom())]), n2 = je(["fix"], []);
      return je(["mord", "rlap"], [r2, n2], t2);
    }, mathmlBuilder: (e2, t2) => {
      const r2 = Pt(dt(e2.body), t2), n2 = new Ct("mphantom", r2), o2 = new Ct("mpadded", [n2]);
      return o2.setAttribute("width", "0px"), o2;
    } }), mt({ type: "raisebox", names: ["\\raisebox"], props: { numArgs: 2, argTypes: ["size", "hbox"], allowedInText: true }, handler(e2, t2) {
      let { parser: r2 } = e2;
      const n2 = or(t2[0], "size").value, o2 = t2[1];
      return { type: "raisebox", mode: r2.mode, dy: n2, body: o2 };
    }, htmlBuilder(e2, t2) {
      const r2 = Mt(e2.body, t2), n2 = N(e2.dy, t2);
      return Ke({ positionType: "shift", positionData: -n2, children: [{ type: "elem", elem: r2 }] });
    }, mathmlBuilder(e2, t2) {
      const r2 = new Ct("mpadded", [Vt(e2.body, t2)]), n2 = e2.dy.number + e2.dy.unit;
      return r2.setAttribute("voffset", n2), r2;
    } }), mt({ type: "internal", names: ["\\relax"], props: { numArgs: 0, allowedInText: true, allowedInArgument: true }, handler(e2) {
      let { parser: t2 } = e2;
      return { type: "internal", mode: t2.mode };
    } }), mt({ type: "rule", names: ["\\rule"], props: { numArgs: 2, numOptionalArgs: 1, allowedInText: true, allowedInMath: true, argTypes: ["size", "size", "size"] }, handler(e2, t2, r2) {
      let { parser: n2 } = e2;
      const o2 = r2[0], s2 = or(t2[0], "size"), i2 = or(t2[1], "size");
      return { type: "rule", mode: n2.mode, shift: o2 && or(o2, "size").value, width: s2.value, height: i2.value };
    }, htmlBuilder(e2, t2) {
      const r2 = je(["mord", "rule"], [], t2), n2 = N(e2.width, t2), o2 = N(e2.height, t2), s2 = e2.shift ? N(e2.shift, t2) : 0;
      return r2.style.borderRightWidth = O(n2), r2.style.borderTopWidth = O(o2), r2.style.bottom = O(s2), r2.width = n2, r2.height = o2 + s2, r2.depth = -s2, r2.maxFontSize = 1.125 * o2 * t2.sizeMultiplier, r2;
    }, mathmlBuilder(e2, t2) {
      const r2 = N(e2.width, t2), n2 = N(e2.height, t2), o2 = e2.shift ? N(e2.shift, t2) : 0, s2 = t2.color && t2.getColor() || "black", i2 = new Ct("mspace");
      i2.setAttribute("mathbackground", s2), i2.setAttribute("width", O(r2)), i2.setAttribute("height", O(n2));
      const l2 = new Ct("mpadded", [i2]);
      return o2 >= 0 ? l2.setAttribute("height", O(o2)) : (l2.setAttribute("height", O(o2)), l2.setAttribute("depth", O(-o2))), l2.setAttribute("voffset", O(o2)), l2;
    } });
    const Dn = ["\\tiny", "\\sixptsize", "\\scriptsize", "\\footnotesize", "\\small", "\\normalsize", "\\large", "\\Large", "\\LARGE", "\\huge", "\\Huge"];
    mt({ type: "sizing", names: Dn, props: { numArgs: 0, allowedInText: true }, handler: (e2, t2) => {
      let { breakOnTokenText: r2, funcName: n2, parser: o2 } = e2;
      const s2 = o2.parseExpression(false, r2);
      return { type: "sizing", mode: o2.mode, size: Dn.indexOf(n2) + 1, body: s2 };
    }, htmlBuilder: (e2, t2) => {
      const r2 = t2.havingSize(e2.size);
      return On(e2.body, r2, t2);
    }, mathmlBuilder: (e2, t2) => {
      const r2 = t2.havingSize(e2.size), n2 = Pt(e2.body, r2), o2 = new Ct("mstyle", n2);
      return o2.setAttribute("mathsize", O(r2.sizeMultiplier)), o2;
    } }), mt({ type: "smash", names: ["\\smash"], props: { numArgs: 1, numOptionalArgs: 1, allowedInText: true }, handler: (e2, t2, r2) => {
      let { parser: n2 } = e2, o2 = false, s2 = false;
      const i2 = r2[0] && or(r2[0], "ordgroup");
      if (i2) {
        let e3;
        for (let t3 = 0; t3 < i2.body.length; ++t3) {
          if (e3 = sr(i2.body[t3]).text, "t" === e3) o2 = true;
          else {
            if ("b" !== e3) {
              o2 = false, s2 = false;
              break;
            }
            s2 = true;
          }
        }
      } else o2 = true, s2 = true;
      const l2 = t2[0];
      return { type: "smash", mode: n2.mode, body: l2, smashHeight: o2, smashDepth: s2 };
    }, htmlBuilder: (e2, t2) => {
      const r2 = je([], [Mt(e2.body, t2)]);
      if (!e2.smashHeight && !e2.smashDepth) return r2;
      if (e2.smashHeight && (r2.height = 0), e2.smashDepth && (r2.depth = 0), e2.smashHeight && e2.smashDepth) return je(["mord", "smash"], [r2], t2);
      if (r2.children) for (let t3 = 0; t3 < r2.children.length; t3++) e2.smashHeight && (r2.children[t3].height = 0), e2.smashDepth && (r2.children[t3].depth = 0);
      const n2 = Ke({ positionType: "firstBaseline", children: [{ type: "elem", elem: r2 }] });
      return je(["mord"], [n2], t2);
    }, mathmlBuilder: (e2, t2) => {
      const r2 = new Ct("mpadded", [Vt(e2.body, t2)]);
      return e2.smashHeight && r2.setAttribute("height", "0px"), e2.smashDepth && r2.setAttribute("depth", "0px"), r2;
    } }), mt({ type: "sqrt", names: ["\\sqrt"], props: { numArgs: 1, numOptionalArgs: 1 }, handler(e2, t2, r2) {
      let { parser: n2 } = e2;
      const o2 = r2[0], s2 = t2[0];
      return { type: "sqrt", mode: n2.mode, body: s2, index: o2 };
    }, htmlBuilder(e2, t2) {
      let r2 = Mt(e2.body, t2.havingCrampedStyle());
      0 === r2.height && (r2.height = t2.fontMetrics().xHeight), r2 = Ze(r2, t2);
      const n2 = t2.fontMetrics().defaultRuleThickness;
      let o2 = n2;
      t2.style.id < S.TEXT.id && (o2 = t2.fontMetrics().xHeight);
      let s2 = n2 + o2 / 4;
      const i2 = r2.height + r2.depth + s2 + n2, { span: l2, ruleWidth: a2, advanceWidth: c2 } = (function(e3, t3) {
        const r3 = t3.havingBaseSizing(), n3 = jr("\\surd", e3 * r3.sizeMultiplier, Xr, r3);
        let o3 = r3.sizeMultiplier;
        const s3 = Math.max(0, t3.minRuleThickness - t3.fontMetrics().sqrtRuleThickness);
        let i3, l3, a3, c3, h3;
        return "small" === n3.type ? (c3 = 1e3 + 1e3 * s3 + 80, e3 < 1 ? o3 = 1 : e3 < 1.4 && (o3 = 0.7), l3 = (1 + s3 + Nr) / o3, a3 = (1 + s3) / o3, i3 = Or("sqrtMain", l3, c3, s3, t3), i3.style.minWidth = "0.853em", h3 = 0.833 / o3) : "large" === n3.type ? (c3 = 1080 * Fr[n3.size], a3 = (Fr[n3.size] + s3) / o3, l3 = (Fr[n3.size] + s3 + Nr) / o3, i3 = Or("sqrtSize" + n3.size, l3, c3, s3, t3), i3.style.minWidth = "1.02em", h3 = 1 / o3) : (l3 = e3 + s3 + Nr, a3 = e3 + s3, c3 = Math.floor(1e3 * e3 + s3) + 80, i3 = Or("sqrtTall", l3, c3, s3, t3), i3.style.minWidth = "0.742em", h3 = 1.056), i3.height = a3, i3.style.height = O(l3), { span: i3, advanceWidth: h3, ruleWidth: (t3.fontMetrics().sqrtRuleThickness + s3) * o3 };
      })(i2, t2), h2 = l2.height - a2;
      h2 > r2.height + r2.depth + s2 && (s2 = (s2 + h2 - r2.height - r2.depth) / 2);
      const m2 = l2.height - r2.height - s2 - a2;
      r2.style.paddingLeft = O(c2);
      const u2 = Ke({ positionType: "firstBaseline", children: [{ type: "elem", elem: r2, wrapperClasses: ["svg-align"] }, { type: "kern", size: -(r2.height + m2) }, { type: "elem", elem: l2 }, { type: "kern", size: a2 }] });
      if (e2.index) {
        const r3 = t2.havingStyle(S.SCRIPTSCRIPT), n3 = Mt(e2.index, r3, t2), o3 = 0.6 * (u2.height - u2.depth), s3 = Ke({ positionType: "shift", positionData: -o3, children: [{ type: "elem", elem: n3 }] }), i3 = je(["root"], [s3]);
        return je(["mord", "sqrt"], [i3, u2], t2);
      }
      return je(["mord", "sqrt"], [u2], t2);
    }, mathmlBuilder(e2, t2) {
      const { body: r2, index: n2 } = e2;
      return n2 ? new Ct("mroot", [Vt(r2, t2), Vt(n2, t2)]) : new Ct("msqrt", [Vt(r2, t2)]);
    } });
    const Ln = { display: S.DISPLAY, text: S.TEXT, script: S.SCRIPT, scriptscript: S.SCRIPTSCRIPT };
    mt({ type: "styling", names: ["\\displaystyle", "\\textstyle", "\\scriptstyle", "\\scriptscriptstyle"], props: { numArgs: 0, allowedInText: true, primitive: true }, handler(e2, t2) {
      let { breakOnTokenText: r2, funcName: n2, parser: o2 } = e2;
      const s2 = o2.parseExpression(true, r2), i2 = n2.slice(1, n2.length - 5);
      if (!(i2 in Ln)) throw new Error("Unknown style: " + i2);
      return { type: "styling", mode: o2.mode, style: i2, body: s2 };
    }, htmlBuilder(e2, t2) {
      const r2 = Ln[e2.style];
      let n2 = t2.havingStyle(r2);
      return e2.resetFont && (n2 = n2.withFont("")), On(e2.body, n2, t2);
    }, mathmlBuilder(e2, t2) {
      const r2 = Ln[e2.style];
      let n2 = t2.havingStyle(r2);
      e2.resetFont && (n2 = n2.withFont(""));
      const o2 = Pt(e2.body, n2), s2 = new Ct("mstyle", o2), i2 = { display: ["0", "true"], text: ["0", "false"], script: ["1", "false"], scriptscript: ["2", "false"] }[e2.style];
      return s2.setAttribute("scriptlevel", i2[0]), s2.setAttribute("displaystyle", i2[1]), s2;
    } });
    ut({ type: "supsub", htmlBuilder(e2, t2) {
      const r2 = (function(e3, t3) {
        const r3 = e3.base;
        if (r3) return "op" === r3.type ? r3.limits && (t3.style.size === S.DISPLAY.size || r3.alwaysHandleSupSub) ? In : null : "operatorname" === r3.type ? r3.alwaysHandleSupSub && (t3.style.size === S.DISPLAY.size || r3.limits) ? Nn : null : "accent" === r3.type ? m(r3.base) ? ar : null : "horizBrace" === r3.type && !e3.sub === r3.isOver ? An : null;
        return null;
      })(e2, t2);
      if (r2) return r2(e2, t2);
      const { base: n2, sup: o2, sub: s2 } = e2, i2 = Mt(n2, t2);
      let l2, a2;
      const c2 = t2.fontMetrics();
      let h2 = 0, u2 = 0;
      const p2 = n2 && m(n2);
      if (o2) {
        const e3 = t2.havingStyle(t2.style.sup());
        l2 = Mt(o2, e3, t2), p2 || (h2 = i2.height - e3.fontMetrics().supDrop * e3.sizeMultiplier / t2.sizeMultiplier);
      }
      if (s2) {
        const e3 = t2.havingStyle(t2.style.sub());
        a2 = Mt(s2, e3, t2), p2 || (u2 = i2.depth + e3.fontMetrics().subDrop * e3.sizeMultiplier / t2.sizeMultiplier);
      }
      let d2;
      d2 = t2.style === S.DISPLAY ? c2.sup1 : t2.style.cramped ? c2.sup3 : c2.sup2;
      const g2 = t2.sizeMultiplier, f2 = O(0.5 / c2.ptPerEm / g2);
      let b2, y2 = null;
      if (a2) {
        const t3 = e2.base && "op" === e2.base.type && e2.base.name && ("\\oiint" === e2.base.name || "\\oiiint" === e2.base.name);
        var x2;
        if (i2 instanceof W || t3) y2 = O(-(null != (x2 = i2.italic) ? x2 : 0));
      }
      if (l2 && a2) {
        h2 = Math.max(h2, d2, l2.depth + 0.25 * c2.xHeight), u2 = Math.max(u2, c2.sub2);
        const e3 = 4 * c2.defaultRuleThickness;
        if (h2 - l2.depth - (a2.height - u2) < e3) {
          u2 = e3 - (h2 - l2.depth) + a2.height;
          const t3 = 0.8 * c2.xHeight - (h2 - l2.depth);
          t3 > 0 && (h2 += t3, u2 -= t3);
        }
        b2 = Ke({ positionType: "individualShift", children: [{ type: "elem", elem: a2, shift: u2, marginRight: f2, marginLeft: y2 }, { type: "elem", elem: l2, shift: -h2, marginRight: f2 }] });
      } else if (a2) {
        u2 = Math.max(u2, c2.sub1, a2.height - 0.8 * c2.xHeight);
        b2 = Ke({ positionType: "shift", positionData: u2, children: [{ type: "elem", elem: a2, marginLeft: y2, marginRight: f2 }] });
      } else {
        if (!l2) throw new Error("supsub must have either sup or sub.");
        h2 = Math.max(h2, d2, l2.depth + 0.25 * c2.xHeight), b2 = Ke({ positionType: "shift", positionData: -h2, children: [{ type: "elem", elem: l2, marginRight: f2 }] });
      }
      const w2 = zt(i2, "right") || "mord";
      return je([w2], [i2, je(["msupsub"], [b2])], t2);
    }, mathmlBuilder(e2, t2) {
      let r2, n2, o2 = false;
      e2.base && "horizBrace" === e2.base.type && (n2 = !!e2.sup, n2 === e2.base.isOver && (o2 = true, r2 = e2.base.isOver)), !e2.base || "op" !== e2.base.type && "operatorname" !== e2.base.type || (e2.base.parentIsSupSub = true);
      const s2 = [Vt(e2.base, t2)];
      let i2;
      if (e2.sub && s2.push(Vt(e2.sub, t2)), e2.sup && s2.push(Vt(e2.sup, t2)), o2) i2 = r2 ? "mover" : "munder";
      else if (e2.sub) if (e2.sup) {
        const r3 = e2.base;
        i2 = r3 && "op" === r3.type && r3.limits && t2.style === S.DISPLAY || r3 && "operatorname" === r3.type && r3.alwaysHandleSupSub && (t2.style === S.DISPLAY || r3.limits) ? "munderover" : "msubsup";
      } else {
        const r3 = e2.base;
        i2 = r3 && "op" === r3.type && r3.limits && (t2.style === S.DISPLAY || r3.alwaysHandleSupSub) || r3 && "operatorname" === r3.type && r3.alwaysHandleSupSub && (r3.limits || t2.style === S.DISPLAY) ? "munder" : "msub";
      }
      else {
        const r3 = e2.base;
        i2 = r3 && "op" === r3.type && r3.limits && (t2.style === S.DISPLAY || r3.alwaysHandleSupSub) || r3 && "operatorname" === r3.type && r3.alwaysHandleSupSub && (r3.limits || t2.style === S.DISPLAY) ? "mover" : "msup";
      }
      return new Ct(i2, s2);
    } }), ut({ type: "atom", htmlBuilder(e2, t2) {
      return Ve(e2.text, e2.mode, t2, ["m" + e2.family]);
    }, mathmlBuilder(e2, t2) {
      const r2 = new Ct("mo", [Ht(e2.text, e2.mode)]);
      if ("bin" === e2.family) {
        const n2 = Dt(e2, t2);
        "bold-italic" === n2 && r2.setAttribute("mathvariant", n2);
      } else "punct" === e2.family ? r2.setAttribute("separator", "true") : "open" !== e2.family && "close" !== e2.family || r2.setAttribute("stretchy", "false");
      return r2;
    } });
    const Pn = { mi: "italic", mn: "normal", mtext: "normal" };
    ut({ type: "mathord", htmlBuilder(e2, t2) {
      return Ge(e2, t2, "mathord");
    }, mathmlBuilder(e2, t2) {
      const r2 = new Ct("mi", [Ht(e2.text, e2.mode, t2)]), n2 = Dt(e2, t2) || "italic";
      return n2 !== Pn[r2.type] && r2.setAttribute("mathvariant", n2), r2;
    } }), ut({ type: "textord", htmlBuilder(e2, t2) {
      return Ge(e2, t2, "textord");
    }, mathmlBuilder(e2, t2) {
      const r2 = Ht(e2.text, e2.mode, t2), n2 = Dt(e2, t2) || "normal";
      let o2;
      return o2 = "text" === e2.mode ? new Ct("mtext", [r2]) : /[0-9]/.test(e2.text) ? new Ct("mn", [r2]) : "\\prime" === e2.text ? new Ct("mo", [r2]) : new Ct("mi", [r2]), n2 !== Pn[o2.type] && o2.setAttribute("mathvariant", n2), o2;
    } });
    const Fn = { "\\nobreak": "nobreak", "\\allowbreak": "allowbreak" }, Vn = { " ": {}, "\\ ": {}, "~": { className: "nobreak" }, "\\space": {}, "\\nobreakspace": { className: "nobreak" } };
    ut({ type: "spacing", htmlBuilder(e2, t2) {
      if (Vn.hasOwnProperty(e2.text)) {
        const r2 = Vn[e2.text].className || "";
        if ("text" === e2.mode) {
          const n2 = Ge(e2, t2, "textord");
          return n2.classes.push(r2), n2;
        }
        return je(["mspace", r2], [Ve(e2.text, e2.mode, t2)], t2);
      }
      if (Fn.hasOwnProperty(e2.text)) return je(["mspace", Fn[e2.text]], [], t2);
      throw new n('Unknown type of space "' + e2.text + '"');
    }, mathmlBuilder(e2, t2) {
      let r2;
      if (!Vn.hasOwnProperty(e2.text)) {
        if (Fn.hasOwnProperty(e2.text)) return new Ct("mspace");
        throw new n('Unknown type of space "' + e2.text + '"');
      }
      return r2 = new Ct("mtext", [new qt("\xA0")]), r2;
    } });
    const Gn = () => {
      const e2 = new Ct("mtd", []);
      return e2.setAttribute("width", "50%"), e2;
    };
    ut({ type: "tag", mathmlBuilder(e2, t2) {
      const r2 = new Ct("mtable", [new Ct("mtr", [Gn(), new Ct("mtd", [Ft(e2.body, t2)]), Gn(), new Ct("mtd", [Ft(e2.tag, t2)])])]);
      return r2.setAttribute("width", "100%"), r2;
    } });
    const Un = { "\\text": void 0, "\\textrm": "textrm", "\\textsf": "textsf", "\\texttt": "texttt", "\\textnormal": "textrm" }, Xn = { "\\textbf": "textbf", "\\textmd": "textmd" }, Yn = { "\\textit": "textit", "\\textup": "textup" }, jn = (e2, t2) => {
      const r2 = e2.font;
      return r2 ? Un[r2] ? t2.withTextFontFamily(Un[r2]) : Xn[r2] ? t2.withTextFontWeight(Xn[r2]) : "\\emph" === r2 ? "textit" === t2.fontShape ? t2.withTextFontShape("textup") : t2.withTextFontShape("textit") : t2.withTextFontShape(Yn[r2]) : t2;
    };
    mt({ type: "text", names: ["\\text", "\\textrm", "\\textsf", "\\texttt", "\\textnormal", "\\textbf", "\\textmd", "\\textit", "\\textup", "\\emph"], props: { numArgs: 1, argTypes: ["text"], allowedInArgument: true, allowedInText: true }, handler(e2, t2) {
      let { parser: r2, funcName: n2 } = e2;
      const o2 = t2[0];
      return { type: "text", mode: r2.mode, body: dt(o2), font: n2 };
    }, htmlBuilder(e2, t2) {
      const r2 = jn(e2, t2), n2 = xt(e2.body, r2, true);
      return je(["mord", "text"], n2, r2);
    }, mathmlBuilder(e2, t2) {
      const r2 = jn(e2, t2);
      return Ft(e2.body, r2);
    } }), mt({ type: "underline", names: ["\\underline"], props: { numArgs: 1, allowedInText: true }, handler(e2, t2) {
      let { parser: r2 } = e2;
      return { type: "underline", mode: r2.mode, body: t2[0] };
    }, htmlBuilder(e2, t2) {
      const r2 = Mt(e2.body, t2), n2 = _e("underline-line", t2), o2 = t2.fontMetrics().defaultRuleThickness, s2 = Ke({ positionType: "top", positionData: r2.height, children: [{ type: "kern", size: o2 }, { type: "elem", elem: n2 }, { type: "kern", size: 3 * o2 }, { type: "elem", elem: r2 }] });
      return je(["mord", "underline"], [s2], t2);
    }, mathmlBuilder(e2, t2) {
      const r2 = new Ct("mo", [new qt("\u203E")]);
      r2.setAttribute("stretchy", "true");
      const n2 = new Ct("munder", [Vt(e2.body, t2), r2]);
      return n2.setAttribute("accentunder", "true"), n2;
    } }), mt({ type: "vcenter", names: ["\\vcenter"], props: { numArgs: 1, argTypes: ["original"], allowedInText: false }, handler(e2, t2) {
      let { parser: r2 } = e2;
      return { type: "vcenter", mode: r2.mode, body: t2[0] };
    }, htmlBuilder(e2, t2) {
      const r2 = Mt(e2.body, t2), n2 = t2.fontMetrics().axisHeight, o2 = 0.5 * (r2.height - n2 - (r2.depth + n2));
      return Ke({ positionType: "shift", positionData: o2, children: [{ type: "elem", elem: r2 }] });
    }, mathmlBuilder(e2, t2) {
      const r2 = new Ct("mpadded", [Vt(e2.body, t2)], ["vcenter"]);
      return new Ct("mrow", [r2]);
    } }), mt({ type: "verb", names: ["\\verb"], props: { numArgs: 0, allowedInText: true }, handler(e2, t2, r2) {
      throw new n("\\verb ended by end of line instead of matching delimiter");
    }, htmlBuilder(e2, t2) {
      const r2 = Wn(e2), n2 = [], o2 = t2.havingStyle(t2.style.text());
      for (let t3 = 0; t3 < r2.length; t3++) {
        let s2 = r2[t3];
        "~" === s2 && (s2 = "\\textasciitilde"), n2.push(Fe(s2, "Typewriter-Regular", e2.mode, o2, ["mord", "texttt"]));
      }
      return je(["mord", "text"].concat(o2.sizingClasses(t2)), Xe(n2), o2);
    }, mathmlBuilder(e2, t2) {
      const r2 = new qt(Wn(e2)), n2 = new Ct("mtext", [r2]);
      return n2.setAttribute("mathvariant", "monospace"), n2;
    } });
    const Wn = (e2) => e2.body.replace(/ /g, e2.star ? "\u2423" : "\xA0");
    var _n = at;
    const $n = "[ \r\n	]", Zn = "(\\\\[a-zA-Z@]+)" + $n + "*", Kn = "[\u0300-\u036F]", Jn = new RegExp(Kn + "+$"), Qn = "(" + $n + "+)|\\\\(\n|[ \r	]+\n?)[ \r	]*|([!-\\[\\]-\u2027\u202A-\uD7FF\uF900-\uFFFF]" + Kn + "*|[\uD800-\uDBFF][\uDC00-\uDFFF]" + Kn + "*|\\\\verb\\*([^]).*?\\4|\\\\verb([^*a-zA-Z]).*?\\5|" + Zn + "|\\\\[^\uD800-\uDFFF])";
    class eo {
      constructor(e2, t2) {
        this.input = void 0, this.settings = void 0, this.tokenRegex = void 0, this.catcodes = void 0, this.input = e2, this.settings = t2, this.tokenRegex = new RegExp(Qn, "g"), this.catcodes = { "%": 14, "~": 13 };
      }
      setCatcode(e2, t2) {
        this.catcodes[e2] = t2;
      }
      lex() {
        const e2 = this.input, t2 = this.tokenRegex.lastIndex;
        if (t2 === e2.length) return new an("EOF", new ln(this, t2, t2));
        const r2 = this.tokenRegex.exec(e2);
        if (null === r2 || r2.index !== t2) throw new n("Unexpected character: '" + e2[t2] + "'", new an(e2[t2], new ln(this, t2, t2 + 1)));
        const o2 = r2[6] || r2[3] || (r2[2] ? "\\ " : " ");
        if (14 === this.catcodes[o2]) {
          const t3 = e2.indexOf("\n", this.tokenRegex.lastIndex);
          return -1 === t3 ? (this.tokenRegex.lastIndex = e2.length, this.settings.reportNonstrict("commentAtEnd", "% comment has no terminating newline; LaTeX would fail because of commenting the end of math mode (e.g. $)")) : this.tokenRegex.lastIndex = t3 + 1, this.lex();
        }
        return new an(o2, new ln(this, t2, this.tokenRegex.lastIndex));
      }
    }
    class to {
      constructor(e2, t2) {
        void 0 === e2 && (e2 = {}), void 0 === t2 && (t2 = {}), this.current = void 0, this.builtins = void 0, this.undefStack = void 0, this.current = t2, this.builtins = e2, this.undefStack = [];
      }
      beginGroup() {
        this.undefStack.push({});
      }
      endGroup() {
        if (0 === this.undefStack.length) throw new n("Unbalanced namespace destruction: attempt to pop global namespace; please report this as a bug");
        const e2 = this.undefStack.pop();
        for (const t2 in e2) e2.hasOwnProperty(t2) && (null == e2[t2] ? delete this.current[t2] : this.current[t2] = e2[t2]);
      }
      endGroups() {
        for (; this.undefStack.length > 0; ) this.endGroup();
      }
      has(e2) {
        return this.current.hasOwnProperty(e2) || this.builtins.hasOwnProperty(e2);
      }
      get(e2) {
        return this.current.hasOwnProperty(e2) ? this.current[e2] : this.builtins[e2];
      }
      set(e2, t2, r2) {
        if (void 0 === r2 && (r2 = false), r2) {
          for (let t3 = 0; t3 < this.undefStack.length; t3++) delete this.undefStack[t3][e2];
          this.undefStack.length > 0 && (this.undefStack[this.undefStack.length - 1][e2] = t2);
        } else {
          const t3 = this.undefStack[this.undefStack.length - 1];
          t3 && !t3.hasOwnProperty(e2) && (t3[e2] = this.current[e2]);
        }
        null == t2 ? delete this.current[e2] : this.current[e2] = t2;
      }
    }
    var ro = on;
    sn("\\noexpand", function(e2) {
      const t2 = e2.popToken();
      return e2.isExpandable(t2.text) && (t2.noexpand = true, t2.treatAsRelax = true), { tokens: [t2], numArgs: 0 };
    }), sn("\\expandafter", function(e2) {
      const t2 = e2.popToken();
      return e2.expandOnce(true), { tokens: [t2], numArgs: 0 };
    }), sn("\\@firstoftwo", function(e2) {
      return { tokens: e2.consumeArgs(2)[0], numArgs: 0 };
    }), sn("\\@secondoftwo", function(e2) {
      return { tokens: e2.consumeArgs(2)[1], numArgs: 0 };
    }), sn("\\@ifnextchar", function(e2) {
      const t2 = e2.consumeArgs(3);
      e2.consumeSpaces();
      const r2 = e2.future();
      return 1 === t2[0].length && t2[0][0].text === r2.text ? { tokens: t2[1], numArgs: 0 } : { tokens: t2[2], numArgs: 0 };
    }), sn("\\@ifstar", "\\@ifnextchar *{\\@firstoftwo{#1}}"), sn("\\TextOrMath", function(e2) {
      const t2 = e2.consumeArgs(2);
      return "text" === e2.mode ? { tokens: t2[0], numArgs: 0 } : { tokens: t2[1], numArgs: 0 };
    });
    const no = { 0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9, a: 10, A: 10, b: 11, B: 11, c: 12, C: 12, d: 13, D: 13, e: 14, E: 14, f: 15, F: 15 };
    sn("\\char", function(e2) {
      let t2, r2 = e2.popToken(), o2 = 0;
      if ("'" === r2.text) t2 = 8, r2 = e2.popToken();
      else if ('"' === r2.text) t2 = 16, r2 = e2.popToken();
      else if ("`" === r2.text) if (r2 = e2.popToken(), "\\" === r2.text[0]) o2 = r2.text.charCodeAt(1);
      else {
        if ("EOF" === r2.text) throw new n("\\char` missing argument");
        o2 = r2.text.charCodeAt(0);
      }
      else t2 = 10;
      if (t2) {
        if (o2 = no[r2.text], null == o2 || o2 >= t2) throw new n("Invalid base-" + t2 + " digit " + r2.text);
        let s2;
        for (; null != (s2 = no[e2.future().text]) && s2 < t2; ) o2 *= t2, o2 += s2, e2.popToken();
      }
      return "\\@char{" + o2 + "}";
    });
    const oo = (e2, t2, r2, o2) => {
      let s2 = e2.consumeArg().tokens;
      if (1 !== s2.length) throw new n("\\newcommand's first argument must be a macro name");
      const i2 = s2[0].text, l2 = e2.isDefined(i2);
      if (l2 && !t2) throw new n("\\newcommand{" + i2 + "} attempting to redefine " + i2 + "; use \\renewcommand");
      if (!l2 && !r2) throw new n("\\renewcommand{" + i2 + "} when command " + i2 + " does not yet exist; use \\newcommand");
      let a2 = 0;
      if (s2 = e2.consumeArg().tokens, 1 === s2.length && "[" === s2[0].text) {
        let t3 = "", r3 = e2.expandNextToken();
        for (; "]" !== r3.text && "EOF" !== r3.text; ) t3 += r3.text, r3 = e2.expandNextToken();
        if (!t3.match(/^\s*[0-9]+\s*$/)) throw new n("Invalid number of arguments: " + t3);
        a2 = parseInt(t3), s2 = e2.consumeArg().tokens;
      }
      return l2 && o2 || e2.macros.set(i2, { tokens: s2, numArgs: a2 }), "";
    };
    sn("\\newcommand", (e2) => oo(e2, false, true, false)), sn("\\renewcommand", (e2) => oo(e2, true, false, false)), sn("\\providecommand", (e2) => oo(e2, true, true, true)), sn("\\message", (e2) => {
      const t2 = e2.consumeArgs(1)[0];
      return console.log(t2.reverse().map((e3) => e3.text).join("")), "";
    }), sn("\\errmessage", (e2) => {
      const t2 = e2.consumeArgs(1)[0];
      return console.error(t2.reverse().map((e3) => e3.text).join("")), "";
    }), sn("\\show", (e2) => {
      const t2 = e2.popToken(), r2 = t2.text;
      return console.log(t2, e2.macros.get(r2), _n[r2], ne.math[r2], ne.text[r2]), "";
    }), sn("\\bgroup", "{"), sn("\\egroup", "}"), sn("~", "\\nobreakspace"), sn("\\lq", "`"), sn("\\rq", "'"), sn("\\aa", "\\r a"), sn("\\AA", "\\r A"), sn("\\textcopyright", "\\html@mathml{\\textcircled{c}}{\\char`\xA9}"), sn("\\copyright", "\\TextOrMath{\\textcopyright}{\\text{\\textcopyright}}"), sn("\\textregistered", "\\html@mathml{\\textcircled{\\scriptsize R}}{\\char`\xAE}"), sn("\u212C", "\\mathscr{B}"), sn("\u2130", "\\mathscr{E}"), sn("\u2131", "\\mathscr{F}"), sn("\u210B", "\\mathscr{H}"), sn("\u2110", "\\mathscr{I}"), sn("\u2112", "\\mathscr{L}"), sn("\u2133", "\\mathscr{M}"), sn("\u211B", "\\mathscr{R}"), sn("\u212D", "\\mathfrak{C}"), sn("\u210C", "\\mathfrak{H}"), sn("\u2128", "\\mathfrak{Z}"), sn("\\Bbbk", "\\Bbb{k}"), sn("\\llap", "\\mathllap{\\textrm{#1}}"), sn("\\rlap", "\\mathrlap{\\textrm{#1}}"), sn("\\clap", "\\mathclap{\\textrm{#1}}"), sn("\\mathstrut", "\\vphantom{(}"), sn("\\underbar", "\\underline{\\text{#1}}"), sn("\\not", '\\html@mathml{\\mathrel{\\mathrlap\\@not}\\nobreak}{\\char"338}'), sn("\\neq", "\\html@mathml{\\mathrel{\\not=}}{\\mathrel{\\char`\u2260}}"), sn("\\ne", "\\neq"), sn("\u2260", "\\neq"), sn("\\notin", "\\html@mathml{\\mathrel{{\\in}\\mathllap{/\\mskip1mu}}}{\\mathrel{\\char`\u2209}}"), sn("\u2209", "\\notin"), sn("\u2258", "\\html@mathml{\\mathrel{=\\kern{-1em}\\raisebox{0.4em}{$\\scriptsize\\frown$}}}{\\mathrel{\\char`\u2258}}"), sn("\u2259", "\\html@mathml{\\stackrel{\\tiny\\wedge}{=}}{\\mathrel{\\char`\u2258}}"), sn("\u225A", "\\html@mathml{\\stackrel{\\tiny\\vee}{=}}{\\mathrel{\\char`\u225A}}"), sn("\u225B", "\\html@mathml{\\stackrel{\\scriptsize\\star}{=}}{\\mathrel{\\char`\u225B}}"), sn("\u225D", "\\html@mathml{\\stackrel{\\tiny\\mathrm{def}}{=}}{\\mathrel{\\char`\u225D}}"), sn("\u225E", "\\html@mathml{\\stackrel{\\tiny\\mathrm{m}}{=}}{\\mathrel{\\char`\u225E}}"), sn("\u225F", "\\html@mathml{\\stackrel{\\tiny?}{=}}{\\mathrel{\\char`\u225F}}"), sn("\u27C2", "\\perp"), sn("\u203C", "\\mathclose{!\\mkern-0.8mu!}"), sn("\u220C", "\\notni"), sn("\u231C", "\\ulcorner"), sn("\u231D", "\\urcorner"), sn("\u231E", "\\llcorner"), sn("\u231F", "\\lrcorner"), sn("\xA9", "\\copyright"), sn("\xAE", "\\textregistered"), sn("\\ulcorner", '\\html@mathml{\\@ulcorner}{\\mathop{\\char"231c}}'), sn("\\urcorner", '\\html@mathml{\\@urcorner}{\\mathop{\\char"231d}}'), sn("\\llcorner", '\\html@mathml{\\@llcorner}{\\mathop{\\char"231e}}'), sn("\\lrcorner", '\\html@mathml{\\@lrcorner}{\\mathop{\\char"231f}}'), sn("\\vdots", "{\\varvdots\\rule{0pt}{15pt}}"), sn("\u22EE", "\\vdots"), sn("\\varGamma", "\\mathit{\\Gamma}"), sn("\\varDelta", "\\mathit{\\Delta}"), sn("\\varTheta", "\\mathit{\\Theta}"), sn("\\varLambda", "\\mathit{\\Lambda}"), sn("\\varXi", "\\mathit{\\Xi}"), sn("\\varPi", "\\mathit{\\Pi}"), sn("\\varSigma", "\\mathit{\\Sigma}"), sn("\\varUpsilon", "\\mathit{\\Upsilon}"), sn("\\varPhi", "\\mathit{\\Phi}"), sn("\\varPsi", "\\mathit{\\Psi}"), sn("\\varOmega", "\\mathit{\\Omega}"), sn("\\substack", "\\begin{subarray}{c}#1\\end{subarray}"), sn("\\colon", "\\nobreak\\mskip2mu\\mathpunct{}\\mathchoice{\\mkern-3mu}{\\mkern-3mu}{}{}{:}\\mskip6mu\\relax"), sn("\\boxed", "\\fbox{$\\displaystyle{#1}$}"), sn("\\iff", "\\DOTSB\\;\\Longleftrightarrow\\;"), sn("\\implies", "\\DOTSB\\;\\Longrightarrow\\;"), sn("\\impliedby", "\\DOTSB\\;\\Longleftarrow\\;"), sn("\\dddot", "{\\overset{\\raisebox{-0.1ex}{\\normalsize ...}}{#1}}"), sn("\\ddddot", "{\\overset{\\raisebox{-0.1ex}{\\normalsize ....}}{#1}}");
    const so = { ",": "\\dotsc", "\\not": "\\dotsb", "+": "\\dotsb", "=": "\\dotsb", "<": "\\dotsb", ">": "\\dotsb", "-": "\\dotsb", "*": "\\dotsb", ":": "\\dotsb", "\\DOTSB": "\\dotsb", "\\coprod": "\\dotsb", "\\bigvee": "\\dotsb", "\\bigwedge": "\\dotsb", "\\biguplus": "\\dotsb", "\\bigcap": "\\dotsb", "\\bigcup": "\\dotsb", "\\prod": "\\dotsb", "\\sum": "\\dotsb", "\\bigotimes": "\\dotsb", "\\bigoplus": "\\dotsb", "\\bigodot": "\\dotsb", "\\bigsqcup": "\\dotsb", "\\And": "\\dotsb", "\\longrightarrow": "\\dotsb", "\\Longrightarrow": "\\dotsb", "\\longleftarrow": "\\dotsb", "\\Longleftarrow": "\\dotsb", "\\longleftrightarrow": "\\dotsb", "\\Longleftrightarrow": "\\dotsb", "\\mapsto": "\\dotsb", "\\longmapsto": "\\dotsb", "\\hookrightarrow": "\\dotsb", "\\doteq": "\\dotsb", "\\mathbin": "\\dotsb", "\\mathrel": "\\dotsb", "\\relbar": "\\dotsb", "\\Relbar": "\\dotsb", "\\xrightarrow": "\\dotsb", "\\xleftarrow": "\\dotsb", "\\DOTSI": "\\dotsi", "\\int": "\\dotsi", "\\oint": "\\dotsi", "\\iint": "\\dotsi", "\\iiint": "\\dotsi", "\\iiiint": "\\dotsi", "\\idotsint": "\\dotsi", "\\DOTSX": "\\dotsx" }, io = /* @__PURE__ */ new Set(["bin", "rel"]);
    sn("\\dots", function(e2) {
      let t2 = "\\dotso";
      const r2 = e2.expandAfterFuture().text;
      return r2 in so ? t2 = so[r2] : ("\\not" === r2.slice(0, 4) || r2 in ne.math && io.has(ne.math[r2].group)) && (t2 = "\\dotsb"), t2;
    });
    const lo = { ")": true, "]": true, "\\rbrack": true, "\\}": true, "\\rbrace": true, "\\rangle": true, "\\rceil": true, "\\rfloor": true, "\\rgroup": true, "\\rmoustache": true, "\\right": true, "\\bigr": true, "\\biggr": true, "\\Bigr": true, "\\Biggr": true, $: true, ";": true, ".": true, ",": true };
    sn("\\dotso", function(e2) {
      return e2.future().text in lo ? "\\ldots\\," : "\\ldots";
    }), sn("\\dotsc", function(e2) {
      const t2 = e2.future().text;
      return t2 in lo && "," !== t2 ? "\\ldots\\," : "\\ldots";
    }), sn("\\cdots", function(e2) {
      return e2.future().text in lo ? "\\@cdots\\," : "\\@cdots";
    }), sn("\\dotsb", "\\cdots"), sn("\\dotsm", "\\cdots"), sn("\\dotsi", "\\!\\cdots"), sn("\\dotsx", "\\ldots\\,"), sn("\\DOTSI", "\\relax"), sn("\\DOTSB", "\\relax"), sn("\\DOTSX", "\\relax"), sn("\\tmspace", "\\TextOrMath{\\kern#1#3}{\\mskip#1#2}\\relax"), sn("\\,", "\\tmspace+{3mu}{.1667em}"), sn("\\thinspace", "\\,"), sn("\\>", "\\mskip{4mu}"), sn("\\:", "\\tmspace+{4mu}{.2222em}"), sn("\\medspace", "\\:"), sn("\\;", "\\tmspace+{5mu}{.2777em}"), sn("\\thickspace", "\\;"), sn("\\!", "\\tmspace-{3mu}{.1667em}"), sn("\\negthinspace", "\\!"), sn("\\negmedspace", "\\tmspace-{4mu}{.2222em}"), sn("\\negthickspace", "\\tmspace-{5mu}{.277em}"), sn("\\enspace", "\\kern.5em "), sn("\\enskip", "\\hskip.5em\\relax"), sn("\\quad", "\\hskip1em\\relax"), sn("\\qquad", "\\hskip2em\\relax"), sn("\\tag", "\\@ifstar\\tag@literal\\tag@paren"), sn("\\tag@paren", "\\tag@literal{({#1})}"), sn("\\tag@literal", (e2) => {
      if (e2.macros.get("\\df@tag")) throw new n("Multiple \\tag");
      return "\\gdef\\df@tag{\\text{#1}}";
    }), sn("\\bmod", "\\mathchoice{\\mskip1mu}{\\mskip1mu}{\\mskip5mu}{\\mskip5mu}\\mathbin{\\rm mod}\\mathchoice{\\mskip1mu}{\\mskip1mu}{\\mskip5mu}{\\mskip5mu}"), sn("\\pod", "\\allowbreak\\mathchoice{\\mkern18mu}{\\mkern8mu}{\\mkern8mu}{\\mkern8mu}(#1)"), sn("\\pmod", "\\pod{{\\rm mod}\\mkern6mu#1}"), sn("\\mod", "\\allowbreak\\mathchoice{\\mkern18mu}{\\mkern12mu}{\\mkern12mu}{\\mkern12mu}{\\rm mod}\\,\\,#1"), sn("\\newline", "\\\\\\relax"), sn("\\TeX", "\\textrm{\\html@mathml{T\\kern-.1667em\\raisebox{-.5ex}{E}\\kern-.125emX}{TeX}}");
    const ao = O(K["Main-Regular"]["T".charCodeAt(0)][1] - 0.7 * K["Main-Regular"]["A".charCodeAt(0)][1]);
    sn("\\LaTeX", "\\textrm{\\html@mathml{L\\kern-.36em\\raisebox{" + ao + "}{\\scriptstyle A}\\kern-.15em\\TeX}{LaTeX}}"), sn("\\KaTeX", "\\textrm{\\html@mathml{K\\kern-.17em\\raisebox{" + ao + "}{\\scriptstyle A}\\kern-.15em\\TeX}{KaTeX}}"), sn("\\hspace", "\\@ifstar\\@hspacer\\@hspace"), sn("\\@hspace", "\\hskip #1\\relax"), sn("\\@hspacer", "\\rule{0pt}{0pt}\\hskip #1\\relax"), sn("\\ordinarycolon", ":"), sn("\\vcentcolon", "\\mathrel{\\mathop\\ordinarycolon}"), sn("\\dblcolon", '\\html@mathml{\\mathrel{\\vcentcolon\\mathrel{\\mkern-.9mu}\\vcentcolon}}{\\mathop{\\char"2237}}'), sn("\\coloneqq", '\\html@mathml{\\mathrel{\\vcentcolon\\mathrel{\\mkern-1.2mu}=}}{\\mathop{\\char"2254}}'), sn("\\Coloneqq", '\\html@mathml{\\mathrel{\\dblcolon\\mathrel{\\mkern-1.2mu}=}}{\\mathop{\\char"2237\\char"3d}}'), sn("\\coloneq", '\\html@mathml{\\mathrel{\\vcentcolon\\mathrel{\\mkern-1.2mu}\\mathrel{-}}}{\\mathop{\\char"3a\\char"2212}}'), sn("\\Coloneq", '\\html@mathml{\\mathrel{\\dblcolon\\mathrel{\\mkern-1.2mu}\\mathrel{-}}}{\\mathop{\\char"2237\\char"2212}}'), sn("\\eqqcolon", '\\html@mathml{\\mathrel{=\\mathrel{\\mkern-1.2mu}\\vcentcolon}}{\\mathop{\\char"2255}}'), sn("\\Eqqcolon", '\\html@mathml{\\mathrel{=\\mathrel{\\mkern-1.2mu}\\dblcolon}}{\\mathop{\\char"3d\\char"2237}}'), sn("\\eqcolon", '\\html@mathml{\\mathrel{\\mathrel{-}\\mathrel{\\mkern-1.2mu}\\vcentcolon}}{\\mathop{\\char"2239}}'), sn("\\Eqcolon", '\\html@mathml{\\mathrel{\\mathrel{-}\\mathrel{\\mkern-1.2mu}\\dblcolon}}{\\mathop{\\char"2212\\char"2237}}'), sn("\\colonapprox", '\\html@mathml{\\mathrel{\\vcentcolon\\mathrel{\\mkern-1.2mu}\\approx}}{\\mathop{\\char"3a\\char"2248}}'), sn("\\Colonapprox", '\\html@mathml{\\mathrel{\\dblcolon\\mathrel{\\mkern-1.2mu}\\approx}}{\\mathop{\\char"2237\\char"2248}}'), sn("\\colonsim", '\\html@mathml{\\mathrel{\\vcentcolon\\mathrel{\\mkern-1.2mu}\\sim}}{\\mathop{\\char"3a\\char"223c}}'), sn("\\Colonsim", '\\html@mathml{\\mathrel{\\dblcolon\\mathrel{\\mkern-1.2mu}\\sim}}{\\mathop{\\char"2237\\char"223c}}'), sn("\u2237", "\\dblcolon"), sn("\u2239", "\\eqcolon"), sn("\u2254", "\\coloneqq"), sn("\u2255", "\\eqqcolon"), sn("\u2A74", "\\Coloneqq"), sn("\\ratio", "\\vcentcolon"), sn("\\coloncolon", "\\dblcolon"), sn("\\colonequals", "\\coloneqq"), sn("\\coloncolonequals", "\\Coloneqq"), sn("\\equalscolon", "\\eqqcolon"), sn("\\equalscoloncolon", "\\Eqqcolon"), sn("\\colonminus", "\\coloneq"), sn("\\coloncolonminus", "\\Coloneq"), sn("\\minuscolon", "\\eqcolon"), sn("\\minuscoloncolon", "\\Eqcolon"), sn("\\coloncolonapprox", "\\Colonapprox"), sn("\\coloncolonsim", "\\Colonsim"), sn("\\simcolon", "\\mathrel{\\sim\\mathrel{\\mkern-1.2mu}\\vcentcolon}"), sn("\\simcoloncolon", "\\mathrel{\\sim\\mathrel{\\mkern-1.2mu}\\dblcolon}"), sn("\\approxcolon", "\\mathrel{\\approx\\mathrel{\\mkern-1.2mu}\\vcentcolon}"), sn("\\approxcoloncolon", "\\mathrel{\\approx\\mathrel{\\mkern-1.2mu}\\dblcolon}"), sn("\\notni", "\\html@mathml{\\not\\ni}{\\mathrel{\\char`\u220C}}"), sn("\\limsup", "\\DOTSB\\operatorname*{lim\\,sup}"), sn("\\liminf", "\\DOTSB\\operatorname*{lim\\,inf}"), sn("\\injlim", "\\DOTSB\\operatorname*{inj\\,lim}"), sn("\\projlim", "\\DOTSB\\operatorname*{proj\\,lim}"), sn("\\varlimsup", "\\DOTSB\\operatorname*{\\overline{lim}}"), sn("\\varliminf", "\\DOTSB\\operatorname*{\\underline{lim}}"), sn("\\varinjlim", "\\DOTSB\\operatorname*{\\underrightarrow{lim}}"), sn("\\varprojlim", "\\DOTSB\\operatorname*{\\underleftarrow{lim}}"), sn("\\gvertneqq", "\\html@mathml{\\@gvertneqq}{\u2269}"), sn("\\lvertneqq", "\\html@mathml{\\@lvertneqq}{\u2268}"), sn("\\ngeqq", "\\html@mathml{\\@ngeqq}{\u2271}"), sn("\\ngeqslant", "\\html@mathml{\\@ngeqslant}{\u2271}"), sn("\\nleqq", "\\html@mathml{\\@nleqq}{\u2270}"), sn("\\nleqslant", "\\html@mathml{\\@nleqslant}{\u2270}"), sn("\\nshortmid", "\\html@mathml{\\@nshortmid}{\u2224}"), sn("\\nshortparallel", "\\html@mathml{\\@nshortparallel}{\u2226}"), sn("\\nsubseteqq", "\\html@mathml{\\@nsubseteqq}{\u2288}"), sn("\\nsupseteqq", "\\html@mathml{\\@nsupseteqq}{\u2289}"), sn("\\varsubsetneq", "\\html@mathml{\\@varsubsetneq}{\u228A}"), sn("\\varsubsetneqq", "\\html@mathml{\\@varsubsetneqq}{\u2ACB}"), sn("\\varsupsetneq", "\\html@mathml{\\@varsupsetneq}{\u228B}"), sn("\\varsupsetneqq", "\\html@mathml{\\@varsupsetneqq}{\u2ACC}"), sn("\\imath", "\\html@mathml{\\@imath}{\u0131}"), sn("\\jmath", "\\html@mathml{\\@jmath}{\u0237}"), sn("\\llbracket", "\\html@mathml{\\mathopen{[\\mkern-3.2mu[}}{\\mathopen{\\char`\u27E6}}"), sn("\\rrbracket", "\\html@mathml{\\mathclose{]\\mkern-3.2mu]}}{\\mathclose{\\char`\u27E7}}"), sn("\u27E6", "\\llbracket"), sn("\u27E7", "\\rrbracket"), sn("\\lBrace", "\\html@mathml{\\mathopen{\\{\\mkern-3.2mu[}}{\\mathopen{\\char`\u2983}}"), sn("\\rBrace", "\\html@mathml{\\mathclose{]\\mkern-3.2mu\\}}}{\\mathclose{\\char`\u2984}}"), sn("\u2983", "\\lBrace"), sn("\u2984", "\\rBrace"), sn("\\minuso", "\\mathbin{\\html@mathml{{\\mathrlap{\\mathchoice{\\kern{0.145em}}{\\kern{0.145em}}{\\kern{0.1015em}}{\\kern{0.0725em}}\\circ}{-}}}{\\char`\u29B5}}"), sn("\u29B5", "\\minuso"), sn("\\darr", "\\downarrow"), sn("\\dArr", "\\Downarrow"), sn("\\Darr", "\\Downarrow"), sn("\\lang", "\\langle"), sn("\\rang", "\\rangle"), sn("\\uarr", "\\uparrow"), sn("\\uArr", "\\Uparrow"), sn("\\Uarr", "\\Uparrow"), sn("\\N", "\\mathbb{N}"), sn("\\R", "\\mathbb{R}"), sn("\\Z", "\\mathbb{Z}"), sn("\\alef", "\\aleph"), sn("\\alefsym", "\\aleph"), sn("\\Alpha", "\\mathrm{A}"), sn("\\Beta", "\\mathrm{B}"), sn("\\bull", "\\bullet"), sn("\\Chi", "\\mathrm{X}"), sn("\\clubs", "\\clubsuit"), sn("\\cnums", "\\mathbb{C}"), sn("\\Complex", "\\mathbb{C}"), sn("\\Dagger", "\\ddagger"), sn("\\diamonds", "\\diamondsuit"), sn("\\empty", "\\emptyset"), sn("\\Epsilon", "\\mathrm{E}"), sn("\\Eta", "\\mathrm{H}"), sn("\\exist", "\\exists"), sn("\\harr", "\\leftrightarrow"), sn("\\hArr", "\\Leftrightarrow"), sn("\\Harr", "\\Leftrightarrow"), sn("\\hearts", "\\heartsuit"), sn("\\image", "\\Im"), sn("\\infin", "\\infty"), sn("\\Iota", "\\mathrm{I}"), sn("\\isin", "\\in"), sn("\\Kappa", "\\mathrm{K}"), sn("\\larr", "\\leftarrow"), sn("\\lArr", "\\Leftarrow"), sn("\\Larr", "\\Leftarrow"), sn("\\lrarr", "\\leftrightarrow"), sn("\\lrArr", "\\Leftrightarrow"), sn("\\Lrarr", "\\Leftrightarrow"), sn("\\Mu", "\\mathrm{M}"), sn("\\natnums", "\\mathbb{N}"), sn("\\Nu", "\\mathrm{N}"), sn("\\Omicron", "\\mathrm{O}"), sn("\\plusmn", "\\pm"), sn("\\rarr", "\\rightarrow"), sn("\\rArr", "\\Rightarrow"), sn("\\Rarr", "\\Rightarrow"), sn("\\real", "\\Re"), sn("\\reals", "\\mathbb{R}"), sn("\\Reals", "\\mathbb{R}"), sn("\\Rho", "\\mathrm{P}"), sn("\\sdot", "\\cdot"), sn("\\sect", "\\S"), sn("\\spades", "\\spadesuit"), sn("\\sub", "\\subset"), sn("\\sube", "\\subseteq"), sn("\\supe", "\\supseteq"), sn("\\Tau", "\\mathrm{T}"), sn("\\thetasym", "\\vartheta"), sn("\\weierp", "\\wp"), sn("\\Zeta", "\\mathrm{Z}"), sn("\\argmin", "\\DOTSB\\operatorname*{arg\\,min}"), sn("\\argmax", "\\DOTSB\\operatorname*{arg\\,max}"), sn("\\plim", "\\DOTSB\\mathop{\\operatorname{plim}}\\limits"), sn("\\bra", "\\mathinner{\\langle{#1}|}"), sn("\\ket", "\\mathinner{|{#1}\\rangle}"), sn("\\braket", "\\mathinner{\\langle{#1}\\rangle}"), sn("\\Bra", "\\left\\langle#1\\right|"), sn("\\Ket", "\\left|#1\\right\\rangle");
    const co = (e2) => (t2) => {
      const r2 = t2.consumeArg().tokens, n2 = t2.consumeArg().tokens, o2 = t2.consumeArg().tokens, s2 = t2.consumeArg().tokens, i2 = t2.macros.get("|"), l2 = t2.macros.get("\\|");
      t2.macros.beginGroup();
      const a2 = (t3) => (r3) => {
        e2 && (r3.macros.set("|", i2), o2.length && r3.macros.set("\\|", l2));
        let s3 = t3;
        if (!t3 && o2.length) {
          "|" === r3.future().text && (r3.popToken(), s3 = true);
        }
        return { tokens: s3 ? o2 : n2, numArgs: 0 };
      };
      t2.macros.set("|", a2(false)), o2.length && t2.macros.set("\\|", a2(true));
      const c2 = t2.consumeArg().tokens, h2 = t2.expandTokens([...s2, ...c2, ...r2]);
      return t2.macros.endGroup(), { tokens: h2.reverse(), numArgs: 0 };
    };
    sn("\\bra@ket", co(false)), sn("\\bra@set", co(true)), sn("\\Braket", "\\bra@ket{\\left\\langle}{\\,\\middle\\vert\\,}{\\,\\middle\\vert\\,}{\\right\\rangle}"), sn("\\Set", "\\bra@set{\\left\\{\\:}{\\;\\middle\\vert\\;}{\\;\\middle\\Vert\\;}{\\:\\right\\}}"), sn("\\set", "\\bra@set{\\{\\,}{\\mid}{}{\\,\\}}"), sn("\\angln", "{\\angl n}"), sn("\\blue", "\\textcolor{##6495ed}{#1}"), sn("\\orange", "\\textcolor{##ffa500}{#1}"), sn("\\pink", "\\textcolor{##ff00af}{#1}"), sn("\\red", "\\textcolor{##df0030}{#1}"), sn("\\green", "\\textcolor{##28ae7b}{#1}"), sn("\\gray", "\\textcolor{gray}{#1}"), sn("\\purple", "\\textcolor{##9d38bd}{#1}"), sn("\\blueA", "\\textcolor{##ccfaff}{#1}"), sn("\\blueB", "\\textcolor{##80f6ff}{#1}"), sn("\\blueC", "\\textcolor{##63d9ea}{#1}"), sn("\\blueD", "\\textcolor{##11accd}{#1}"), sn("\\blueE", "\\textcolor{##0c7f99}{#1}"), sn("\\tealA", "\\textcolor{##94fff5}{#1}"), sn("\\tealB", "\\textcolor{##26edd5}{#1}"), sn("\\tealC", "\\textcolor{##01d1c1}{#1}"), sn("\\tealD", "\\textcolor{##01a995}{#1}"), sn("\\tealE", "\\textcolor{##208170}{#1}"), sn("\\greenA", "\\textcolor{##b6ffb0}{#1}"), sn("\\greenB", "\\textcolor{##8af281}{#1}"), sn("\\greenC", "\\textcolor{##74cf70}{#1}"), sn("\\greenD", "\\textcolor{##1fab54}{#1}"), sn("\\greenE", "\\textcolor{##0d923f}{#1}"), sn("\\goldA", "\\textcolor{##ffd0a9}{#1}"), sn("\\goldB", "\\textcolor{##ffbb71}{#1}"), sn("\\goldC", "\\textcolor{##ff9c39}{#1}"), sn("\\goldD", "\\textcolor{##e07d10}{#1}"), sn("\\goldE", "\\textcolor{##a75a05}{#1}"), sn("\\redA", "\\textcolor{##fca9a9}{#1}"), sn("\\redB", "\\textcolor{##ff8482}{#1}"), sn("\\redC", "\\textcolor{##f9685d}{#1}"), sn("\\redD", "\\textcolor{##e84d39}{#1}"), sn("\\redE", "\\textcolor{##bc2612}{#1}"), sn("\\maroonA", "\\textcolor{##ffbde0}{#1}"), sn("\\maroonB", "\\textcolor{##ff92c6}{#1}"), sn("\\maroonC", "\\textcolor{##ed5fa6}{#1}"), sn("\\maroonD", "\\textcolor{##ca337c}{#1}"), sn("\\maroonE", "\\textcolor{##9e034e}{#1}"), sn("\\purpleA", "\\textcolor{##ddd7ff}{#1}"), sn("\\purpleB", "\\textcolor{##c6b9fc}{#1}"), sn("\\purpleC", "\\textcolor{##aa87ff}{#1}"), sn("\\purpleD", "\\textcolor{##7854ab}{#1}"), sn("\\purpleE", "\\textcolor{##543b78}{#1}"), sn("\\mintA", "\\textcolor{##f5f9e8}{#1}"), sn("\\mintB", "\\textcolor{##edf2df}{#1}"), sn("\\mintC", "\\textcolor{##e0e5cc}{#1}"), sn("\\grayA", "\\textcolor{##f6f7f7}{#1}"), sn("\\grayB", "\\textcolor{##f0f1f2}{#1}"), sn("\\grayC", "\\textcolor{##e3e5e6}{#1}"), sn("\\grayD", "\\textcolor{##d6d8da}{#1}"), sn("\\grayE", "\\textcolor{##babec2}{#1}"), sn("\\grayF", "\\textcolor{##888d93}{#1}"), sn("\\grayG", "\\textcolor{##626569}{#1}"), sn("\\grayH", "\\textcolor{##3b3e40}{#1}"), sn("\\grayI", "\\textcolor{##21242c}{#1}"), sn("\\kaBlue", "\\textcolor{##314453}{#1}"), sn("\\kaGreen", "\\textcolor{##71B307}{#1}");
    const ho = { "^": true, _: true, "\\limits": true, "\\nolimits": true };
    class mo {
      constructor(e2, t2, r2) {
        this.settings = void 0, this.expansionCount = void 0, this.lexer = void 0, this.macros = void 0, this.stack = void 0, this.mode = void 0, this.settings = t2, this.expansionCount = 0, this.feed(e2), this.macros = new to(ro, t2.macros), this.mode = r2, this.stack = [];
      }
      feed(e2) {
        this.lexer = new eo(e2, this.settings);
      }
      switchMode(e2) {
        this.mode = e2;
      }
      beginGroup() {
        this.macros.beginGroup();
      }
      endGroup() {
        this.macros.endGroup();
      }
      endGroups() {
        this.macros.endGroups();
      }
      future() {
        return 0 === this.stack.length && this.pushToken(this.lexer.lex()), this.stack[this.stack.length - 1];
      }
      popToken() {
        return this.future(), this.stack.pop();
      }
      pushToken(e2) {
        this.stack.push(e2);
      }
      pushTokens(e2) {
        this.stack.push(...e2);
      }
      scanArgument(e2) {
        let t2, r2, n2;
        if (e2) {
          if (this.consumeSpaces(), "[" !== this.future().text) return null;
          t2 = this.popToken(), { tokens: n2, end: r2 } = this.consumeArg(["]"]);
        } else ({ tokens: n2, start: t2, end: r2 } = this.consumeArg());
        return this.pushToken(new an("EOF", r2.loc)), this.pushTokens(n2), new an("", ln.range(t2, r2));
      }
      consumeSpaces() {
        for (; ; ) {
          if (" " !== this.future().text) break;
          this.stack.pop();
        }
      }
      consumeArg(e2) {
        const t2 = [], r2 = e2 && e2.length > 0;
        r2 || this.consumeSpaces();
        const o2 = this.future();
        let s2, i2 = 0, l2 = 0;
        do {
          if (s2 = this.popToken(), t2.push(s2), "{" === s2.text) ++i2;
          else if ("}" === s2.text) {
            if (--i2, -1 === i2) throw new n("Extra }", s2);
          } else if ("EOF" === s2.text) throw new n("Unexpected end of input in a macro argument, expected '" + (e2 && r2 ? e2[l2] : "}") + "'", s2);
          if (e2 && r2) if ((0 === i2 || 1 === i2 && "{" === e2[l2]) && s2.text === e2[l2]) {
            if (++l2, l2 === e2.length) {
              t2.splice(-l2, l2);
              break;
            }
          } else l2 = 0;
        } while (0 !== i2 || r2);
        return "{" === o2.text && "}" === t2[t2.length - 1].text && (t2.pop(), t2.shift()), t2.reverse(), { tokens: t2, start: o2, end: s2 };
      }
      consumeArgs(e2, t2) {
        if (t2) {
          if (t2.length !== e2 + 1) throw new n("The length of delimiters doesn't match the number of args!");
          const r3 = t2[0];
          for (let e3 = 0; e3 < r3.length; e3++) {
            const t3 = this.popToken();
            if (r3[e3] !== t3.text) throw new n("Use of the macro doesn't match its definition", t3);
          }
        }
        const r2 = [];
        for (let n2 = 0; n2 < e2; n2++) r2.push(this.consumeArg(t2 && t2[n2 + 1]).tokens);
        return r2;
      }
      countExpansion(e2) {
        if (this.expansionCount += e2, this.expansionCount > this.settings.maxExpand) throw new n("Too many expansions: infinite loop or need to increase maxExpand setting");
      }
      expandOnce(e2) {
        const t2 = this.popToken(), r2 = t2.text, o2 = t2.noexpand ? null : this._getExpansion(r2);
        if (null == o2 || e2 && o2.unexpandable) {
          if (e2 && null == o2 && "\\" === r2[0] && !this.isDefined(r2)) throw new n("Undefined control sequence: " + r2);
          return this.pushToken(t2), false;
        }
        this.countExpansion(1);
        let s2 = o2.tokens;
        const i2 = this.consumeArgs(o2.numArgs, o2.delimiters);
        if (o2.numArgs) {
          s2 = s2.slice();
          for (let e3 = s2.length - 1; e3 >= 0; --e3) {
            let t3 = s2[e3];
            if ("#" === t3.text) {
              if (0 === e3) throw new n("Incomplete placeholder at end of macro body", t3);
              if (t3 = s2[--e3], "#" === t3.text) s2.splice(e3 + 1, 1);
              else {
                if (!/^[1-9]$/.test(t3.text)) throw new n("Not a valid argument number", t3);
                s2.splice(e3, 2, ...i2[+t3.text - 1]);
              }
            }
          }
        }
        return this.pushTokens(s2), s2.length;
      }
      expandAfterFuture() {
        return this.expandOnce(), this.future();
      }
      expandNextToken() {
        for (; ; ) if (false === this.expandOnce()) {
          const e2 = this.stack.pop();
          return e2.treatAsRelax && (e2.text = "\\relax"), e2;
        }
      }
      expandMacro(e2) {
        return this.macros.has(e2) ? this.expandTokens([new an(e2)]) : void 0;
      }
      expandTokens(e2) {
        const t2 = [], r2 = this.stack.length;
        for (this.pushTokens(e2); this.stack.length > r2; ) if (false === this.expandOnce(true)) {
          const e3 = this.stack.pop();
          e3.treatAsRelax && (e3.noexpand = false, e3.treatAsRelax = false), t2.push(e3);
        }
        return this.countExpansion(t2.length), t2;
      }
      expandMacroAsText(e2) {
        const t2 = this.expandMacro(e2);
        return t2 ? t2.map((e3) => e3.text).join("") : t2;
      }
      _getExpansion(e2) {
        const t2 = this.macros.get(e2);
        if (null == t2) return t2;
        if (1 === e2.length) {
          const t3 = this.lexer.catcodes[e2];
          if (null != t3 && 13 !== t3) return;
        }
        const r2 = "function" == typeof t2 ? t2(this) : t2;
        if ("string" == typeof r2) {
          let e3 = 0;
          if (r2.includes("#")) {
            const t4 = r2.replace(/##/g, "");
            for (; t4.includes("#" + (e3 + 1)); ) ++e3;
          }
          const t3 = new eo(r2, this.settings), n2 = [];
          let o2 = t3.lex();
          for (; "EOF" !== o2.text; ) n2.push(o2), o2 = t3.lex();
          n2.reverse();
          return { tokens: n2, numArgs: e3 };
        }
        return r2;
      }
      isDefined(e2) {
        return this.macros.has(e2) || _n.hasOwnProperty(e2) || ne.math.hasOwnProperty(e2) || ne.text.hasOwnProperty(e2) || ho.hasOwnProperty(e2);
      }
      isExpandable(e2) {
        const t2 = this.macros.get(e2);
        return null != t2 ? "string" == typeof t2 || "function" == typeof t2 || !t2.unexpandable : _n.hasOwnProperty(e2) && !_n[e2].primitive;
      }
    }
    const uo = /^[\u208a\u208b\u208c\u208d\u208e\u2080\u2081\u2082\u2083\u2084\u2085\u2086\u2087\u2088\u2089\u2090\u2091\u2095\u1d62\u2c7c\u2096\u2097\u2098\u2099\u2092\u209a\u1d63\u209b\u209c\u1d64\u1d65\u2093\u1d66\u1d67\u1d68\u1d69\u1d6a]/, po = Object.freeze({ "\u208A": "+", "\u208B": "-", "\u208C": "=", "\u208D": "(", "\u208E": ")", "\u2080": "0", "\u2081": "1", "\u2082": "2", "\u2083": "3", "\u2084": "4", "\u2085": "5", "\u2086": "6", "\u2087": "7", "\u2088": "8", "\u2089": "9", "\u2090": "a", "\u2091": "e", "\u2095": "h", "\u1D62": "i", "\u2C7C": "j", "\u2096": "k", "\u2097": "l", "\u2098": "m", "\u2099": "n", "\u2092": "o", "\u209A": "p", "\u1D63": "r", "\u209B": "s", "\u209C": "t", "\u1D64": "u", "\u1D65": "v", "\u2093": "x", "\u1D66": "\u03B2", "\u1D67": "\u03B3", "\u1D68": "\u03C1", "\u1D69": "\u03D5", "\u1D6A": "\u03C7", "\u207A": "+", "\u207B": "-", "\u207C": "=", "\u207D": "(", "\u207E": ")", "\u2070": "0", "\xB9": "1", "\xB2": "2", "\xB3": "3", "\u2074": "4", "\u2075": "5", "\u2076": "6", "\u2077": "7", "\u2078": "8", "\u2079": "9", "\u1D2C": "A", "\u1D2E": "B", "\u1D30": "D", "\u1D31": "E", "\u1D33": "G", "\u1D34": "H", "\u1D35": "I", "\u1D36": "J", "\u1D37": "K", "\u1D38": "L", "\u1D39": "M", "\u1D3A": "N", "\u1D3C": "O", "\u1D3E": "P", "\u1D3F": "R", "\u1D40": "T", "\u1D41": "U", "\u2C7D": "V", "\u1D42": "W", "\u1D43": "a", "\u1D47": "b", "\u1D9C": "c", "\u1D48": "d", "\u1D49": "e", "\u1DA0": "f", "\u1D4D": "g", "\u02B0": "h", "\u2071": "i", "\u02B2": "j", "\u1D4F": "k", "\u02E1": "l", "\u1D50": "m", "\u207F": "n", "\u1D52": "o", "\u1D56": "p", "\u02B3": "r", "\u02E2": "s", "\u1D57": "t", "\u1D58": "u", "\u1D5B": "v", "\u02B7": "w", "\u02E3": "x", "\u02B8": "y", "\u1DBB": "z", "\u1D5D": "\u03B2", "\u1D5E": "\u03B3", "\u1D5F": "\u03B4", "\u1D60": "\u03D5", "\u1D61": "\u03C7", "\u1DBF": "\u03B8" }), go = { "\u0301": { text: "\\'", math: "\\acute" }, "\u0300": { text: "\\`", math: "\\grave" }, "\u0308": { text: '\\"', math: "\\ddot" }, "\u0303": { text: "\\~", math: "\\tilde" }, "\u0304": { text: "\\=", math: "\\bar" }, "\u0306": { text: "\\u", math: "\\breve" }, "\u030C": { text: "\\v", math: "\\check" }, "\u0302": { text: "\\^", math: "\\hat" }, "\u0307": { text: "\\.", math: "\\dot" }, "\u030A": { text: "\\r", math: "\\mathring" }, "\u030B": { text: "\\H" }, "\u0327": { text: "\\c" } }, fo = { "\xE1": "a\u0301", "\xE0": "a\u0300", "\xE4": "a\u0308", "\u01DF": "a\u0308\u0304", "\xE3": "a\u0303", "\u0101": "a\u0304", "\u0103": "a\u0306", "\u1EAF": "a\u0306\u0301", "\u1EB1": "a\u0306\u0300", "\u1EB5": "a\u0306\u0303", "\u01CE": "a\u030C", "\xE2": "a\u0302", "\u1EA5": "a\u0302\u0301", "\u1EA7": "a\u0302\u0300", "\u1EAB": "a\u0302\u0303", "\u0227": "a\u0307", "\u01E1": "a\u0307\u0304", "\xE5": "a\u030A", "\u01FB": "a\u030A\u0301", "\u1E03": "b\u0307", "\u0107": "c\u0301", "\u1E09": "c\u0327\u0301", "\u010D": "c\u030C", "\u0109": "c\u0302", "\u010B": "c\u0307", "\xE7": "c\u0327", "\u010F": "d\u030C", "\u1E0B": "d\u0307", "\u1E11": "d\u0327", "\xE9": "e\u0301", "\xE8": "e\u0300", "\xEB": "e\u0308", "\u1EBD": "e\u0303", "\u0113": "e\u0304", "\u1E17": "e\u0304\u0301", "\u1E15": "e\u0304\u0300", "\u0115": "e\u0306", "\u1E1D": "e\u0327\u0306", "\u011B": "e\u030C", "\xEA": "e\u0302", "\u1EBF": "e\u0302\u0301", "\u1EC1": "e\u0302\u0300", "\u1EC5": "e\u0302\u0303", "\u0117": "e\u0307", "\u0229": "e\u0327", "\u1E1F": "f\u0307", "\u01F5": "g\u0301", "\u1E21": "g\u0304", "\u011F": "g\u0306", "\u01E7": "g\u030C", "\u011D": "g\u0302", "\u0121": "g\u0307", "\u0123": "g\u0327", "\u1E27": "h\u0308", "\u021F": "h\u030C", "\u0125": "h\u0302", "\u1E23": "h\u0307", "\u1E29": "h\u0327", "\xED": "i\u0301", "\xEC": "i\u0300", "\xEF": "i\u0308", "\u1E2F": "i\u0308\u0301", "\u0129": "i\u0303", "\u012B": "i\u0304", "\u012D": "i\u0306", "\u01D0": "i\u030C", "\xEE": "i\u0302", "\u01F0": "j\u030C", "\u0135": "j\u0302", "\u1E31": "k\u0301", "\u01E9": "k\u030C", "\u0137": "k\u0327", "\u013A": "l\u0301", "\u013E": "l\u030C", "\u013C": "l\u0327", "\u1E3F": "m\u0301", "\u1E41": "m\u0307", "\u0144": "n\u0301", "\u01F9": "n\u0300", "\xF1": "n\u0303", "\u0148": "n\u030C", "\u1E45": "n\u0307", "\u0146": "n\u0327", "\xF3": "o\u0301", "\xF2": "o\u0300", "\xF6": "o\u0308", "\u022B": "o\u0308\u0304", "\xF5": "o\u0303", "\u1E4D": "o\u0303\u0301", "\u1E4F": "o\u0303\u0308", "\u022D": "o\u0303\u0304", "\u014D": "o\u0304", "\u1E53": "o\u0304\u0301", "\u1E51": "o\u0304\u0300", "\u014F": "o\u0306", "\u01D2": "o\u030C", "\xF4": "o\u0302", "\u1ED1": "o\u0302\u0301", "\u1ED3": "o\u0302\u0300", "\u1ED7": "o\u0302\u0303", "\u022F": "o\u0307", "\u0231": "o\u0307\u0304", "\u0151": "o\u030B", "\u1E55": "p\u0301", "\u1E57": "p\u0307", "\u0155": "r\u0301", "\u0159": "r\u030C", "\u1E59": "r\u0307", "\u0157": "r\u0327", "\u015B": "s\u0301", "\u1E65": "s\u0301\u0307", "\u0161": "s\u030C", "\u1E67": "s\u030C\u0307", "\u015D": "s\u0302", "\u1E61": "s\u0307", "\u015F": "s\u0327", "\u1E97": "t\u0308", "\u0165": "t\u030C", "\u1E6B": "t\u0307", "\u0163": "t\u0327", "\xFA": "u\u0301", "\xF9": "u\u0300", "\xFC": "u\u0308", "\u01D8": "u\u0308\u0301", "\u01DC": "u\u0308\u0300", "\u01D6": "u\u0308\u0304", "\u01DA": "u\u0308\u030C", "\u0169": "u\u0303", "\u1E79": "u\u0303\u0301", "\u016B": "u\u0304", "\u1E7B": "u\u0304\u0308", "\u016D": "u\u0306", "\u01D4": "u\u030C", "\xFB": "u\u0302", "\u016F": "u\u030A", "\u0171": "u\u030B", "\u1E7D": "v\u0303", "\u1E83": "w\u0301", "\u1E81": "w\u0300", "\u1E85": "w\u0308", "\u0175": "w\u0302", "\u1E87": "w\u0307", "\u1E98": "w\u030A", "\u1E8D": "x\u0308", "\u1E8B": "x\u0307", "\xFD": "y\u0301", "\u1EF3": "y\u0300", "\xFF": "y\u0308", "\u1EF9": "y\u0303", "\u0233": "y\u0304", "\u0177": "y\u0302", "\u1E8F": "y\u0307", "\u1E99": "y\u030A", "\u017A": "z\u0301", "\u017E": "z\u030C", "\u1E91": "z\u0302", "\u017C": "z\u0307", "\xC1": "A\u0301", "\xC0": "A\u0300", "\xC4": "A\u0308", "\u01DE": "A\u0308\u0304", "\xC3": "A\u0303", "\u0100": "A\u0304", "\u0102": "A\u0306", "\u1EAE": "A\u0306\u0301", "\u1EB0": "A\u0306\u0300", "\u1EB4": "A\u0306\u0303", "\u01CD": "A\u030C", "\xC2": "A\u0302", "\u1EA4": "A\u0302\u0301", "\u1EA6": "A\u0302\u0300", "\u1EAA": "A\u0302\u0303", "\u0226": "A\u0307", "\u01E0": "A\u0307\u0304", "\xC5": "A\u030A", "\u01FA": "A\u030A\u0301", "\u1E02": "B\u0307", "\u0106": "C\u0301", "\u1E08": "C\u0327\u0301", "\u010C": "C\u030C", "\u0108": "C\u0302", "\u010A": "C\u0307", "\xC7": "C\u0327", "\u010E": "D\u030C", "\u1E0A": "D\u0307", "\u1E10": "D\u0327", "\xC9": "E\u0301", "\xC8": "E\u0300", "\xCB": "E\u0308", "\u1EBC": "E\u0303", "\u0112": "E\u0304", "\u1E16": "E\u0304\u0301", "\u1E14": "E\u0304\u0300", "\u0114": "E\u0306", "\u1E1C": "E\u0327\u0306", "\u011A": "E\u030C", "\xCA": "E\u0302", "\u1EBE": "E\u0302\u0301", "\u1EC0": "E\u0302\u0300", "\u1EC4": "E\u0302\u0303", "\u0116": "E\u0307", "\u0228": "E\u0327", "\u1E1E": "F\u0307", "\u01F4": "G\u0301", "\u1E20": "G\u0304", "\u011E": "G\u0306", "\u01E6": "G\u030C", "\u011C": "G\u0302", "\u0120": "G\u0307", "\u0122": "G\u0327", "\u1E26": "H\u0308", "\u021E": "H\u030C", "\u0124": "H\u0302", "\u1E22": "H\u0307", "\u1E28": "H\u0327", "\xCD": "I\u0301", "\xCC": "I\u0300", "\xCF": "I\u0308", "\u1E2E": "I\u0308\u0301", "\u0128": "I\u0303", "\u012A": "I\u0304", "\u012C": "I\u0306", "\u01CF": "I\u030C", "\xCE": "I\u0302", "\u0130": "I\u0307", "\u0134": "J\u0302", "\u1E30": "K\u0301", "\u01E8": "K\u030C", "\u0136": "K\u0327", "\u0139": "L\u0301", "\u013D": "L\u030C", "\u013B": "L\u0327", "\u1E3E": "M\u0301", "\u1E40": "M\u0307", "\u0143": "N\u0301", "\u01F8": "N\u0300", "\xD1": "N\u0303", "\u0147": "N\u030C", "\u1E44": "N\u0307", "\u0145": "N\u0327", "\xD3": "O\u0301", "\xD2": "O\u0300", "\xD6": "O\u0308", "\u022A": "O\u0308\u0304", "\xD5": "O\u0303", "\u1E4C": "O\u0303\u0301", "\u1E4E": "O\u0303\u0308", "\u022C": "O\u0303\u0304", "\u014C": "O\u0304", "\u1E52": "O\u0304\u0301", "\u1E50": "O\u0304\u0300", "\u014E": "O\u0306", "\u01D1": "O\u030C", "\xD4": "O\u0302", "\u1ED0": "O\u0302\u0301", "\u1ED2": "O\u0302\u0300", "\u1ED6": "O\u0302\u0303", "\u022E": "O\u0307", "\u0230": "O\u0307\u0304", "\u0150": "O\u030B", "\u1E54": "P\u0301", "\u1E56": "P\u0307", "\u0154": "R\u0301", "\u0158": "R\u030C", "\u1E58": "R\u0307", "\u0156": "R\u0327", "\u015A": "S\u0301", "\u1E64": "S\u0301\u0307", "\u0160": "S\u030C", "\u1E66": "S\u030C\u0307", "\u015C": "S\u0302", "\u1E60": "S\u0307", "\u015E": "S\u0327", "\u0164": "T\u030C", "\u1E6A": "T\u0307", "\u0162": "T\u0327", "\xDA": "U\u0301", "\xD9": "U\u0300", "\xDC": "U\u0308", "\u01D7": "U\u0308\u0301", "\u01DB": "U\u0308\u0300", "\u01D5": "U\u0308\u0304", "\u01D9": "U\u0308\u030C", "\u0168": "U\u0303", "\u1E78": "U\u0303\u0301", "\u016A": "U\u0304", "\u1E7A": "U\u0304\u0308", "\u016C": "U\u0306", "\u01D3": "U\u030C", "\xDB": "U\u0302", "\u016E": "U\u030A", "\u0170": "U\u030B", "\u1E7C": "V\u0303", "\u1E82": "W\u0301", "\u1E80": "W\u0300", "\u1E84": "W\u0308", "\u0174": "W\u0302", "\u1E86": "W\u0307", "\u1E8C": "X\u0308", "\u1E8A": "X\u0307", "\xDD": "Y\u0301", "\u1EF2": "Y\u0300", "\u0178": "Y\u0308", "\u1EF8": "Y\u0303", "\u0232": "Y\u0304", "\u0176": "Y\u0302", "\u1E8E": "Y\u0307", "\u0179": "Z\u0301", "\u017D": "Z\u030C", "\u1E90": "Z\u0302", "\u017B": "Z\u0307", "\u03AC": "\u03B1\u0301", "\u1F70": "\u03B1\u0300", "\u1FB1": "\u03B1\u0304", "\u1FB0": "\u03B1\u0306", "\u03AD": "\u03B5\u0301", "\u1F72": "\u03B5\u0300", "\u03AE": "\u03B7\u0301", "\u1F74": "\u03B7\u0300", "\u03AF": "\u03B9\u0301", "\u1F76": "\u03B9\u0300", "\u03CA": "\u03B9\u0308", "\u0390": "\u03B9\u0308\u0301", "\u1FD2": "\u03B9\u0308\u0300", "\u1FD1": "\u03B9\u0304", "\u1FD0": "\u03B9\u0306", "\u03CC": "\u03BF\u0301", "\u1F78": "\u03BF\u0300", "\u03CD": "\u03C5\u0301", "\u1F7A": "\u03C5\u0300", "\u03CB": "\u03C5\u0308", "\u03B0": "\u03C5\u0308\u0301", "\u1FE2": "\u03C5\u0308\u0300", "\u1FE1": "\u03C5\u0304", "\u1FE0": "\u03C5\u0306", "\u03CE": "\u03C9\u0301", "\u1F7C": "\u03C9\u0300", "\u038E": "\u03A5\u0301", "\u1FEA": "\u03A5\u0300", "\u03AB": "\u03A5\u0308", "\u1FE9": "\u03A5\u0304", "\u1FE8": "\u03A5\u0306", "\u038F": "\u03A9\u0301", "\u1FFA": "\u03A9\u0300" };
    class bo {
      constructor(e2, t2) {
        this.mode = void 0, this.gullet = void 0, this.settings = void 0, this.leftrightDepth = void 0, this.nextToken = void 0, this.mode = "math", this.gullet = new mo(e2, t2, this.mode), this.settings = t2, this.leftrightDepth = 0, this.nextToken = null;
      }
      expect(e2, t2) {
        if (void 0 === t2 && (t2 = true), this.fetch().text !== e2) throw new n("Expected '" + e2 + "', got '" + this.fetch().text + "'", this.fetch());
        t2 && this.consume();
      }
      consume() {
        this.nextToken = null;
      }
      fetch() {
        return null == this.nextToken && (this.nextToken = this.gullet.expandNextToken()), this.nextToken;
      }
      switchMode(e2) {
        this.mode = e2, this.gullet.switchMode(e2);
      }
      parse() {
        this.settings.globalGroup || this.gullet.beginGroup(), this.settings.colorIsTextColor && this.gullet.macros.set("\\color", "\\textcolor");
        try {
          const e2 = this.parseExpression(false);
          return this.expect("EOF"), this.settings.globalGroup || this.gullet.endGroup(), e2;
        } finally {
          this.gullet.endGroups();
        }
      }
      subparse(e2) {
        const t2 = this.nextToken;
        this.consume(), this.gullet.pushToken(new an("}")), this.gullet.pushTokens(e2);
        const r2 = this.parseExpression(false);
        return this.expect("}"), this.nextToken = t2, r2;
      }
      parseExpression(e2, t2) {
        const r2 = [];
        for (; ; ) {
          "math" === this.mode && this.consumeSpaces();
          const n2 = this.fetch();
          if (bo.endOfExpression.has(n2.text)) break;
          if (t2 && n2.text === t2) break;
          if (e2 && _n[n2.text] && _n[n2.text].infix) break;
          const o2 = this.parseAtom(t2);
          if (!o2) break;
          "internal" !== o2.type && r2.push(o2);
        }
        return "text" === this.mode && this.formLigatures(r2), this.handleInfixNodes(r2);
      }
      handleInfixNodes(e2) {
        let t2, r2 = -1;
        for (let o2 = 0; o2 < e2.length; o2++) {
          const s2 = e2[o2];
          if ("infix" === s2.type) {
            if (-1 !== r2) throw new n("only one infix operator per group", s2.token);
            r2 = o2, t2 = s2.replaceWith;
          }
        }
        if (-1 !== r2 && t2) {
          let n2, o2;
          const s2 = e2.slice(0, r2), i2 = e2.slice(r2 + 1);
          let l2;
          return n2 = 1 === s2.length && "ordgroup" === s2[0].type ? s2[0] : { type: "ordgroup", mode: this.mode, body: s2 }, o2 = 1 === i2.length && "ordgroup" === i2[0].type ? i2[0] : { type: "ordgroup", mode: this.mode, body: i2 }, l2 = "\\\\abovefrac" === t2 ? this.callFunction(t2, [n2, e2[r2], o2], []) : this.callFunction(t2, [n2, o2], []), [l2];
        }
        return e2;
      }
      handleSupSubscript(e2) {
        const t2 = this.fetch(), r2 = t2.text;
        let o2;
        this.consume(), this.consumeSpaces();
        do {
          var s2;
          o2 = this.parseGroup(e2);
        } while ("internal" === (null == (s2 = o2) ? void 0 : s2.type));
        if (!o2) throw new n("Expected group after '" + r2 + "'", t2);
        return o2;
      }
      formatUnsupportedCmd(e2) {
        const t2 = [];
        for (let r3 = 0; r3 < e2.length; r3++) t2.push({ type: "textord", mode: "text", text: e2[r3] });
        const r2 = { type: "text", mode: this.mode, body: t2 };
        return { type: "color", mode: this.mode, color: this.settings.errorColor, body: [r2] };
      }
      parseAtom(e2) {
        const t2 = this.parseGroup("atom", e2);
        if ("internal" === (null == t2 ? void 0 : t2.type)) return t2;
        if ("text" === this.mode) return t2;
        let r2, o2;
        for (; ; ) {
          this.consumeSpaces();
          const e3 = this.fetch();
          if ("\\limits" === e3.text || "\\nolimits" === e3.text) {
            if (t2 && "op" === t2.type) {
              const r3 = "\\limits" === e3.text;
              t2.limits = r3, t2.alwaysHandleSupSub = true;
            } else {
              if (!t2 || "operatorname" !== t2.type) throw new n("Limit controls must follow a math operator", e3);
              t2.alwaysHandleSupSub && (t2.limits = "\\limits" === e3.text);
            }
            this.consume();
          } else if ("^" === e3.text) {
            if (r2) throw new n("Double superscript", e3);
            r2 = this.handleSupSubscript("superscript");
          } else if ("_" === e3.text) {
            if (o2) throw new n("Double subscript", e3);
            o2 = this.handleSupSubscript("subscript");
          } else if ("'" === e3.text) {
            if (r2) throw new n("Double superscript", e3);
            const t3 = { type: "textord", mode: this.mode, text: "\\prime" }, o3 = [t3];
            for (this.consume(); "'" === this.fetch().text; ) o3.push(t3), this.consume();
            "^" === this.fetch().text && o3.push(this.handleSupSubscript("superscript")), r2 = { type: "ordgroup", mode: this.mode, body: o3 };
          } else {
            if (!po[e3.text]) break;
            {
              const t3 = uo.test(e3.text), n2 = [];
              for (n2.push(new an(po[e3.text])), this.consume(); ; ) {
                const e4 = this.fetch().text;
                if (!po[e4]) break;
                if (uo.test(e4) !== t3) break;
                n2.unshift(new an(po[e4])), this.consume();
              }
              const s2 = this.subparse(n2);
              t3 ? o2 = { type: "ordgroup", mode: "math", body: s2 } : r2 = { type: "ordgroup", mode: "math", body: s2 };
            }
          }
        }
        return r2 || o2 ? { type: "supsub", mode: this.mode, base: t2, sup: r2, sub: o2 } : t2;
      }
      parseFunction(e2, t2) {
        const r2 = this.fetch(), o2 = r2.text, s2 = _n[o2];
        if (!s2) return null;
        if (this.consume(), t2 && "atom" !== t2 && !s2.allowedInArgument) throw new n("Got function '" + o2 + "' with no arguments" + (t2 ? " as " + t2 : ""), r2);
        if ("text" === this.mode && !s2.allowedInText) throw new n("Can't use function '" + o2 + "' in text mode", r2);
        if ("math" === this.mode && false === s2.allowedInMath) throw new n("Can't use function '" + o2 + "' in math mode", r2);
        const { args: i2, optArgs: l2 } = this.parseArguments(o2, s2);
        return this.callFunction(o2, i2, l2, r2, e2);
      }
      callFunction(e2, t2, r2, o2, s2) {
        const i2 = { funcName: e2, parser: this, token: o2, breakOnTokenText: s2 }, l2 = _n[e2];
        if (l2 && l2.handler) return l2.handler(i2, t2, r2);
        throw new n("No function handler for " + e2);
      }
      parseArguments(e2, t2) {
        const r2 = t2.numArgs + t2.numOptionalArgs;
        if (0 === r2) return { args: [], optArgs: [] };
        const o2 = [], s2 = [];
        for (let i2 = 0; i2 < r2; i2++) {
          let r3 = t2.argTypes && t2.argTypes[i2];
          const l2 = i2 < t2.numOptionalArgs;
          ("primitive" in t2 && t2.primitive && null == r3 || "sqrt" === t2.type && 1 === i2 && null == s2[0]) && (r3 = "primitive");
          const a2 = this.parseGroupOfType("argument to '" + e2 + "'", r3, l2);
          if (l2) s2.push(a2);
          else {
            if (null == a2) throw new n("Null argument, please report this as a bug");
            o2.push(a2);
          }
        }
        return { args: o2, optArgs: s2 };
      }
      parseGroupOfType(e2, t2, r2) {
        switch (t2) {
          case "color":
            return this.parseColorGroup(r2);
          case "size":
            return this.parseSizeGroup(r2);
          case "url":
            return this.parseUrlGroup(r2);
          case "math":
          case "text":
            return this.parseArgumentGroup(r2, t2);
          case "hbox": {
            const e3 = this.parseArgumentGroup(r2, "text");
            return null != e3 ? { type: "styling", mode: e3.mode, body: [e3], style: "text", resetFont: true } : null;
          }
          case "raw": {
            const e3 = this.parseStringGroup("raw", r2);
            return null != e3 ? { type: "raw", mode: "text", string: e3.text } : null;
          }
          case "primitive": {
            if (r2) throw new n("A primitive argument cannot be optional");
            const t3 = this.parseGroup(e2);
            if (null == t3) throw new n("Expected group as " + e2, this.fetch());
            return t3;
          }
          case "original":
          case null:
          case void 0:
            return this.parseArgumentGroup(r2);
          default:
            throw new n("Unknown group type as " + e2, this.fetch());
        }
      }
      consumeSpaces() {
        for (; " " === this.fetch().text; ) this.consume();
      }
      parseStringGroup(e2, t2) {
        const r2 = this.gullet.scanArgument(t2);
        if (null == r2) return null;
        let n2, o2 = "";
        for (; "EOF" !== (n2 = this.fetch()).text; ) o2 += n2.text, this.consume();
        return this.consume(), r2.text = o2, r2;
      }
      parseRegexGroup(e2, t2) {
        const r2 = this.fetch();
        let o2, s2 = r2, i2 = "";
        for (; "EOF" !== (o2 = this.fetch()).text && e2.test(i2 + o2.text); ) s2 = o2, i2 += s2.text, this.consume();
        if ("" === i2) throw new n("Invalid " + t2 + ": '" + r2.text + "'", r2);
        return r2.range(s2, i2);
      }
      parseColorGroup(e2) {
        const t2 = this.parseStringGroup("color", e2);
        if (null == t2) return null;
        const r2 = /^(#[a-f0-9]{3,4}|#[a-f0-9]{6}|#[a-f0-9]{8}|[a-f0-9]{6}|[a-z]+)$/i.exec(t2.text);
        if (!r2) throw new n("Invalid color: '" + t2.text + "'", t2);
        let o2 = r2[0];
        return /^[0-9a-f]{6}$/i.test(o2) && (o2 = "#" + o2), { type: "color-token", mode: this.mode, color: o2 };
      }
      parseSizeGroup(e2) {
        let t2, r2 = false;
        if (this.gullet.consumeSpaces(), t2 = e2 || "{" === this.gullet.future().text ? this.parseStringGroup("size", e2) : this.parseRegexGroup(/^[-+]? *(?:$|\d+|\d+\.\d*|\.\d*) *[a-z]{0,2} *$/, "size"), !t2) return null;
        e2 || 0 !== t2.text.length || (t2.text = "0pt", r2 = true);
        const o2 = /([-+]?) *(\d+(?:\.\d*)?|\.\d+) *([a-z]{2})/.exec(t2.text);
        if (!o2) throw new n("Invalid size: '" + t2.text + "'", t2);
        const s2 = { number: +(o2[1] + o2[2]), unit: o2[3] };
        if (!H(s2)) throw new n("Invalid unit: '" + s2.unit + "'", t2);
        return { type: "size", mode: this.mode, value: s2, isBlank: r2 };
      }
      parseUrlGroup(e2) {
        this.gullet.lexer.setCatcode("%", 13), this.gullet.lexer.setCatcode("~", 12);
        const t2 = this.parseStringGroup("url", e2);
        if (this.gullet.lexer.setCatcode("%", 14), this.gullet.lexer.setCatcode("~", 13), null == t2) return null;
        const r2 = t2.text.replace(/\\([#$%&~_^{}])/g, "$1");
        return { type: "url", mode: this.mode, url: r2 };
      }
      parseArgumentGroup(e2, t2) {
        const r2 = this.gullet.scanArgument(e2);
        if (null == r2) return null;
        const n2 = this.mode;
        t2 && this.switchMode(t2), this.gullet.beginGroup();
        const o2 = this.parseExpression(false, "EOF");
        this.expect("EOF"), this.gullet.endGroup();
        const s2 = { type: "ordgroup", mode: this.mode, loc: r2.loc, body: o2 };
        return t2 && this.switchMode(n2), s2;
      }
      parseGroup(e2, t2) {
        const r2 = this.fetch(), o2 = r2.text;
        let s2;
        if ("{" === o2 || "\\begingroup" === o2) {
          this.consume();
          const e3 = "{" === o2 ? "}" : "\\endgroup";
          this.gullet.beginGroup();
          const t3 = this.parseExpression(false, e3), n2 = this.fetch();
          this.expect(e3), this.gullet.endGroup(), s2 = { type: "ordgroup", mode: this.mode, loc: ln.range(r2, n2), body: t3, semisimple: "\\begingroup" === o2 || void 0 };
        } else if (s2 = this.parseFunction(t2, e2) || this.parseSymbol(), null == s2 && "\\" === o2[0] && !ho.hasOwnProperty(o2)) {
          if (this.settings.throwOnError) throw new n("Undefined control sequence: " + o2, r2);
          s2 = this.formatUnsupportedCmd(o2), this.consume();
        }
        return s2;
      }
      formLigatures(e2) {
        let t2 = e2.length - 1;
        for (let r2 = 0; r2 < t2; ++r2) {
          const n2 = e2[r2];
          if ("textord" !== n2.type) continue;
          const o2 = n2.text, s2 = e2[r2 + 1];
          if (s2 && "textord" === s2.type) {
            if ("-" === o2 && "-" === s2.text) {
              const o3 = e2[r2 + 2];
              r2 + 1 < t2 && o3 && "textord" === o3.type && "-" === o3.text ? (e2.splice(r2, 3, { type: "textord", mode: "text", loc: ln.range(n2, o3), text: "---" }), t2 -= 2) : (e2.splice(r2, 2, { type: "textord", mode: "text", loc: ln.range(n2, s2), text: "--" }), t2 -= 1);
            }
            "'" !== o2 && "`" !== o2 || s2.text !== o2 || (e2.splice(r2, 2, { type: "textord", mode: "text", loc: ln.range(n2, s2), text: o2 + o2 }), t2 -= 1);
          }
        }
      }
      parseSymbol() {
        const e2 = this.fetch();
        let t2 = e2.text;
        if (/^\\verb[^a-zA-Z]/.test(t2)) {
          this.consume();
          let e3 = t2.slice(5);
          const r3 = "*" === e3.charAt(0);
          if (r3 && (e3 = e3.slice(1)), e3.length < 2 || e3.charAt(0) !== e3.slice(-1)) throw new n("\\verb assertion failed --\n                    please report what input caused this bug");
          return e3 = e3.slice(1, -1), { type: "verb", mode: "text", body: e3, star: r3 };
        }
        fo.hasOwnProperty(t2[0]) && !ne[this.mode][t2[0]] && (this.settings.strict && "math" === this.mode && this.settings.reportNonstrict("unicodeTextInMathMode", 'Accented Unicode text character "' + t2[0] + '" used in math mode', e2), t2 = fo[t2[0]] + t2.slice(1));
        const r2 = Jn.exec(t2);
        let o2;
        if (r2 && (t2 = t2.substring(0, r2.index), "i" === t2 ? t2 = "\u0131" : "j" === t2 && (t2 = "\u0237")), ne[this.mode][t2]) {
          this.settings.strict && "math" === this.mode && Me.includes(t2) && this.settings.reportNonstrict("unicodeTextInMathMode", 'Latin-1/Unicode text character "' + t2[0] + '" used in math mode', e2);
          const r3 = ne[this.mode][t2].group, n2 = ln.range(e2);
          let s2;
          s2 = r3 in rr ? { type: "atom", mode: this.mode, family: r3, loc: n2, text: t2 } : { type: r3, mode: this.mode, loc: n2, text: t2 }, o2 = s2;
        } else {
          if (!(t2.charCodeAt(0) >= 128)) return null;
          this.settings.strict && (T(t2.charCodeAt(0)) ? "math" === this.mode && this.settings.reportNonstrict("unicodeTextInMathMode", 'Unicode text character "' + t2[0] + '" used in math mode', e2) : this.settings.reportNonstrict("unknownSymbol", 'Unrecognized Unicode character "' + t2[0] + '" (' + t2.charCodeAt(0) + ")", e2)), o2 = { type: "textord", mode: "text", loc: ln.range(e2), text: t2 };
        }
        if (this.consume(), r2) for (let t3 = 0; t3 < r2[0].length; t3++) {
          const s2 = r2[0][t3];
          if (!go[s2]) throw new n("Unknown accent ' " + s2 + "'", e2);
          const i2 = go[s2][this.mode] || go[s2].text;
          if (!i2) throw new n("Accent " + s2 + " unsupported in " + this.mode + " mode", e2);
          o2 = { type: "accent", mode: this.mode, loc: ln.range(e2), label: i2, isStretchy: false, isShifty: true, base: o2 };
        }
        return o2;
      }
    }
    bo.endOfExpression = /* @__PURE__ */ new Set(["}", "\\endgroup", "\\end", "\\right", "&"]);
    var yo = function(e2, t2) {
      if (!("string" == typeof e2 || e2 instanceof String)) throw new TypeError("KaTeX can only parse string typed expression");
      const r2 = new bo(e2, t2);
      delete r2.gullet.macros.current["\\df@tag"];
      let o2 = r2.parse();
      if (delete r2.gullet.macros.current["\\current@color"], delete r2.gullet.macros.current["\\color"], r2.gullet.macros.get("\\df@tag")) {
        if (!t2.displayMode) throw new n("\\tag works only in display equations");
        o2 = [{ type: "tag", mode: "text", body: o2, tag: r2.subparse([new an("\\df@tag")]) }];
      }
      return o2;
    };
    let xo = function(e2, t2, r2) {
      t2.textContent = "";
      const n2 = vo(e2, r2).toNode();
      t2.appendChild(n2);
    };
    "undefined" != typeof document && "CSS1Compat" !== document.compatMode && ("undefined" != typeof console && console.warn("Warning: KaTeX doesn't work in quirks mode. Make sure your website has a suitable doctype."), xo = function() {
      throw new n("KaTeX doesn't work in quirks mode.");
    });
    const wo = function(e2, t2, r2) {
      if (r2.throwOnError || !(e2 instanceof n)) throw e2;
      const o2 = je(["katex-error"], [new W(t2)]);
      return o2.setAttribute("title", e2.toString()), o2.setAttribute("style", "color:" + r2.errorColor), o2;
    }, vo = function(e2, t2) {
      const r2 = new g(t2);
      try {
        const t3 = yo(e2, r2);
        return Zt(t3, e2, r2);
      } catch (t3) {
        return wo(t3, e2, r2);
      }
    };
    var ko = { version: "0.16.47", render: xo, renderToString: function(e2, t2) {
      return vo(e2, t2).toMarkup();
    }, ParseError: n, SETTINGS_SCHEMA: u, __parse: function(e2, t2) {
      const r2 = new g(t2);
      return yo(e2, r2);
    }, __renderToDomTree: vo, __renderToHTMLTree: function(e2, t2) {
      const r2 = new g(t2);
      try {
        return (function(e3, t3, r3) {
          const n2 = Tt(e3, _t(r3)), o2 = je(["katex"], [n2]);
          return $t(o2, r3);
        })(yo(e2, r2), 0, r2);
      } catch (t3) {
        return wo(t3, e2, r2);
      }
    }, __setFontMetrics: function(e2, t2) {
      K[e2] = t2;
    }, __defineSymbol: oe, __defineFunction: mt, __defineMacro: sn, __domTree: { Span: U, Anchor: X, SymbolNode: W, SvgNode: _, PathNode: $, LineNode: Z } };
    return t = t.default;
  })();
});;
