<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta http-equiv="Content-Type" content="application/xml+xhtml; charset=UTF-8"/>
        <title>OpenZiti by NetFoundry — Status</title>
        <style type="text/css">
            /* ── Base ─────────────────────────────────────────── */
            :root {
                --card-bg:      rgba(255,255,255,0.07);
                --card-border:  rgba(255,255,255,0.15);
                --card-active-bg:    rgba(0,200,83,0.12);
                --card-active-border:rgba(0,200,83,0.45);
                --radius:       5px;
                --gap:          6px;
            }
            body {
                font-family: monospace;
                height: 100%;
                width: 100%;
                padding: 0; margin: 0;
                white-space: nowrap;
                font-size: 1.6vmin;
            }
            hr { margin: 0; }
            pre { margin: 0; display: inline; }

            /* ── Background watermark ─────────────────────────── */
            #BODYIMG {
                background: url(images/logo.png) no-repeat center center fixed;
                min-height: 100%; min-width: 100px;
                width: 100%; height: auto;
                position: fixed; top: 0; left: 0; z-index: -1;
            }

            /* ── Layout helpers ───────────────────────────────── */
            .BODYOVERLAY  { height: 100%; width: 100%; position: fixed; overflow-y: auto; }
            .BODYWHITE    { background: white; text-shadow: 0px 0px 1px white; }
            .BODYBLACK    { background: #111;  text-shadow: 0px 0px 1px #111; }
            .NOTVISIBLE   { display: none; }
            .FULLWIDTH    { width: 100%; float: left; }
            .CENTERDATE   { text-align: center; float: right; }
            .CENTERINFO   { text-align: center; }

            /* ── Typography helpers ───────────────────────────── */
            .FG-BOLD      { font-weight: bold; }
            .FG-ITALIC    { font-style: italic; }
            .FG-LARGE     { font-size: 2.5vmin; }
            .FG-SHADOW    { text-shadow: 0px 0px 3px blue; }
            .FG-GREY      { color: grey; }
            .FG-LTGREY    { color: lightgrey; }
            .FG-WHITE     { color: white; }
            .FG-BLACK     { color: black; }
            .FG-YELLOW    { color: yellow; }
            .FG-RED       { color: red; }
            .FG-GREEN     { color: green; }
            .FG-BLUE      { color: blue; }
            .FG-PURPLE    { color: purple; }

            /* ── Background helpers ───────────────────────────── */
            [class*="BG-"] { border-radius: 3px; }
            .BG-GREY   { background-color: grey; }
            .BG-LTGREY { background-color: lightgrey; }
            .BG-WHITE  { background-color: white; }
            .BG-BLACK  { background-color: black; }
            .BG-YELLOW { background-color: yellow; }
            .BG-RED    { background-color: red; }
            .BG-GREEN  { background-color: green; }
            .BG-BLUE   { background-color: blue; }
            .BG-PURPLE { background-color: purple; }
            .BG-NONE   { background-color: unset; }

            /* ── Animation helpers ────────────────────────────── */
            .ANIMATED   { transition: all ease; }
            .T25MS      { transition-duration: 0.025s; }
            .T100MS     { transition-duration: 0.1s; }
            .T500MS     { transition-duration: 0.5s; }
            .T1S        { transition-duration: 1s; }
            .T2S        { transition-duration: 2s; }
            .T3S        { transition-duration: 3s; }
            .OPACITY-A  { opacity: 1; }
            .OPACITY-B  { opacity: 0.85; }
            .OPACITY-C  { opacity: 0.5; }
            .OPACITY-D  { opacity: 0.15; }
            .OPACITY-E  { opacity: 0; }

            /* ── Info header ──────────────────────────────────── */
            #ZETLOADSTATUS { cursor: pointer; }
            .info-pill {
                display: inline-block;
                padding: 1px 6px;
                border-radius: 3px;
                border: 1px solid rgba(128,128,128,0.3);
                margin: 1px 2px;
            }

            /* ── Summary cards row ────────────────────────────── */
            .summary-row {
                display: flex;
                flex-wrap: wrap;
                gap: var(--gap);
                padding: var(--gap) 4px;
                border-bottom: 1px solid rgba(128,128,128,0.25);
                margin-bottom: 2px;
                width: 100%;
                box-sizing: border-box;
                float: left;
            }
            .stat-card {
                flex: 1 1 140px;
                min-width: 120px;
                padding: 5px 8px;
                border-radius: var(--radius);
                border: 1px solid var(--card-border);
                background: var(--card-bg);
                box-sizing: border-box;
                overflow: hidden;   /* needed for child ellipsis to engage */
            }
            /* Highlighted card when connections are active */
            .stat-card-active {
                border-color: var(--card-active-border);
                background: var(--card-active-bg);
            }
            .stat-card-error-card {
                border-color: rgba(255,60,60,0.4);
                background: rgba(255,0,0,0.08);
            }
            .stat-card-label {
                font-size: 0.72em;
                opacity: 0.55;
                text-transform: uppercase;
                letter-spacing: 0.06em;
                margin-bottom: 2px;
            }
            .stat-card-value {
                font-size: 1.05em;
                font-weight: bold;
                white-space: nowrap;
                overflow: hidden;
                text-overflow: ellipsis;
            }
            .stat-card-sub {
                font-size: 0.78em;
                opacity: 0.65;
                margin-top: 1px;
                white-space: normal;
                word-break: break-all;
            }
            /* Status colours used by zetdisplay.sh */
            .stat-online  { color: #00c853; }
            .stat-warning { color: #ffca28; }
            .stat-error   { color: #ef5350; }
            .stat-idle    { color: grey; }
            /* Active caller list inside a card */
            .caller-list {
                border-top: 1px solid rgba(0,200,83,0.3);
                margin-top: 3px;
                padding-top: 2px;
                max-height: 6em;
                overflow: hidden;
            }
            .stat-caller {
                /* Match ER name style — muted via opacity, no forced colour */
                opacity: 0.62;
                font-size: 0.78em;
                white-space: nowrap;
                overflow: hidden;
                text-overflow: ellipsis;
                line-height: 1.4;
            }
            /* Identity name: smaller, ellipsis — CSS truncates, awk no longer hard-cuts */
            .stat-id-name {
                font-size: 0.80em;
                opacity: 0.80;
                white-space: nowrap;    /* required for text-overflow:ellipsis */
                overflow: hidden;
                text-overflow: ellipsis;
                display: inline-block;
                max-width: calc(100% - 16px);  /* leave room for the ● + nbsp */
                vertical-align: middle;
            }

            /* ── Table-based detail view ──────────────────────── */
            .zt-identity-block {
                float: left; width: 100%;
                margin-bottom: 8px;
            }
            .zt-identity-header {
                float: left; width: 100%; box-sizing: border-box;
                padding: 4px 8px;
                font-weight: bold;
                font-size: 0.92em;
                border-left: 3px solid rgba(0,200,83,0.6);
                background: rgba(0,200,83,0.08);
                margin-bottom: 4px;
            }
            .zt-identity-id { opacity: 0.45; font-size: 0.82em; font-weight: normal; }
            .zt-section {
                float: left; width: 100%; box-sizing: border-box;
                margin-bottom: 6px;
            }
            .zt-section-title {
                font-size: 0.82em; font-weight: bold;
                text-transform: uppercase; letter-spacing: 0.08em;
                color: rgba(0,200,83,0.85);
                padding: 4px 4px 2px 7px;
                border-left: 3px solid rgba(0,200,83,0.5);
                border-bottom: 1px solid rgba(0,200,83,0.12);
                margin-bottom: 2px;
            }
            .zt-table {
                width: 100%; border-collapse: collapse;
                font-size: 0.88em; table-layout: auto;
            }
            .zt-table th {
                text-align: left; font-weight: normal;
                font-size: 0.76em; opacity: 0.45;
                text-transform: uppercase; letter-spacing: 0.04em;
                padding: 2px 6px 2px 4px;
                border-bottom: 1px solid rgba(128,128,128,0.15);
                white-space: nowrap;
            }
            .zt-table td {
                padding: 3px 6px 3px 4px;
                border-bottom: 1px solid rgba(128,128,128,0.06);
                vertical-align: middle;
                overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
            }
            .zt-table tr:last-child td { border-bottom: none; }
            .zt-th-sm { width: 1%; white-space: nowrap; }
            .zt-mono  { font-family: monospace; }
            .zt-muted { opacity: 0.55; }
            .zt-num   { text-align: right; font-variant-numeric: tabular-nums; }
            /* Latency colours */
            .lat-good { color: #4caf50; font-weight: bold; }
            .lat-warn { color: #ffc107; font-weight: bold; }
            .lat-bad  { color: #ef5350; font-weight: bold; }
            /* Badges */
            .badge {
                display: inline-block; padding: 1px 5px;
                border-radius: 3px; font-size: 0.74em;
                font-weight: bold; letter-spacing: 0.04em;
                white-space: nowrap;
            }
            .badge-online     { background:#1b5e20; color:#ccff90; }
            .badge-offline    { background:#b71c1c; color:#ffcdd2; }
            .badge-up         { background:#1b5e20; color:#ccff90; }
            .badge-down       { background:#b71c1c; color:#ffcdd2; }
            .badge-connecting { background:#e65100; color:#ffe0b2; }
            .badge-connected  { background:#1b5e20; color:#ccff90; }
            .badge-dial       { background:rgba(33,150,243,0.18); color:#90caf9; border:1px solid rgba(33,150,243,0.3); }
            .badge-bind       { background:rgba(156,39,176,0.18); color:#ce93d8; border:1px solid rgba(156,39,176,0.3); }
            .badge-dialbind   { background:rgba(0,150,136,0.18);  color:#80cbc4; border:1px solid rgba(0,150,136,0.3); }

            /* ── Channel list rows in Edge Routers card ───────── */
            .stat-chan {
                display: flex;
                align-items: baseline;
                gap: 4px;
                padding: 1px 0;
                white-space: nowrap;
                overflow: hidden;
                line-height: 1.5;
            }
            /* Router name: smaller, muted, ellipsis when constrained */
            .stat-chan-name {
                font-size: 0.76em;
                opacity: 0.62;
                overflow: hidden;
                text-overflow: ellipsis;
                min-width: 0;        /* flex child must have min-width:0 to ellipsize */
                flex: 1 1 auto;
            }

            /* ── Active Connections grouped rows ─────────────── */
            .zt-conn-group td {
                font-weight: bold;
                padding-top: 6px;
                padding-bottom: 2px;
                border-top: 1px solid rgba(128,128,128,0.12);
                border-bottom: none;
            }
            .zt-conn-group:first-child td { border-top: none; padding-top: 3px; }
            .zt-conn-detail td:first-child { padding-left: 16px; }
            .zt-conn-detail td { border-bottom: 1px solid rgba(128,128,128,0.04); }

            /* ── Throughput chart strip ───────────────────────── */
            #ZT-CHART-AREA {
                display: none;          /* hidden until first ZET data arrives */
                width: 100%;
                float: left;
                padding: 3px 4px 2px 4px;
                box-sizing: border-box;
                border-bottom: 1px solid rgba(128,128,128,0.2);
                position: relative;
            }
            #zt-canvas {
                display: block;
                width: 100%;
                height: 100px;
                border-radius: 3px;
                background: rgba(0,0,0,0.35);
            }
            #ZT-CHART-LABELS {
                position: absolute;
                top: 7px; right: 10px;
                font-size: 0.9em;
                font-weight: bold;
                pointer-events: none;
                text-shadow: 0 0 4px rgba(0,0,0,0.9);
            }
            #ZT-CHART-TITLE {
                position: absolute;
                top: 7px; left: 10px;
                font-size: 0.72em;
                color: rgba(180,180,180,0.9);
                text-transform: uppercase;
                letter-spacing: 0.05em;
                pointer-events: none;
            }
        </style>
    </head>
    <body>
        <script>
            // ── Animation & fetch helpers ──────────────────────────
            function fadeIn(el, ms, cb) {
                if (!el) { if (cb) cb(); return; }
                if (el.style.display === 'block') { if (cb) cb(); return; }
                var dur = ms || 300;
                el.style.display = 'block';
                el.classList.remove('NOTVISIBLE');
                el.style.opacity = '0';
                el.style.transition = '';
                requestAnimationFrame(function() {
                    requestAnimationFrame(function() {
                        el.style.transition = 'opacity ' + dur + 'ms ease';
                        el.style.opacity = '1';
                        if (cb) setTimeout(cb, dur);
                    });
                });
            }

            function fadeOut(el, ms, cb) {
                if (!el) { if (cb) cb(); return; }
                var dur = ms || 300;
                el.style.transition = 'opacity ' + dur + 'ms ease';
                el.style.opacity = '0';
                setTimeout(function() {
                    el.style.display = 'none';
                    el.style.transition = '';
                    el.style.opacity = '';
                    if (cb) cb();
                }, dur);
            }

            function fadeOutAll(els, ms, cb) {
                var live = els.filter(Boolean);
                if (!live.length) { if (cb) cb(); return; }
                var done = 0;
                live.forEach(function(el) {
                    fadeOut(el, ms, function() { if (++done >= live.length && cb) cb(); });
                });
            }

            function slideDown(el, ms) {
                if (!el) return;
                var dur = ms || 300;
                el.classList.remove('NOTVISIBLE');
                el.style.overflow = 'hidden';
                el.style.height = '0';
                el.style.display = 'block';
                var h = el.scrollHeight;
                requestAnimationFrame(function() {
                    requestAnimationFrame(function() {
                        el.style.transition = 'height ' + dur + 'ms ease';
                        el.style.height = h + 'px';
                        setTimeout(function() {
                            el.style.height = '';
                            el.style.overflow = '';
                            el.style.transition = '';
                        }, dur);
                    });
                });
            }

            function slideUp(el, ms) {
                if (!el) return;
                var dur = ms || 300;
                el.style.overflow = 'hidden';
                el.style.height = el.scrollHeight + 'px';
                requestAnimationFrame(function() {
                    requestAnimationFrame(function() {
                        el.style.transition = 'height ' + dur + 'ms ease';
                        el.style.height = '0';
                        setTimeout(function() {
                            el.style.display = 'none';
                            el.classList.add('NOTVISIBLE');
                            el.style.height = '';
                            el.style.overflow = '';
                            el.style.transition = '';
                        }, dur);
                    });
                });
            }

            function fetchHtml(url, params, cb) {
                var pstr = Object.keys(params).map(function(k) {
                    return encodeURIComponent(k) + '=' + encodeURIComponent(params[k]);
                }).join('&');
                fetch(pstr ? url + '?' + pstr : url)
                    .then(function(r) { return r.text(); })
                    .then(cb)
                    .catch(function() {});
            }

            // ── State ─────────────────────────────────────────────
            var flagPause, waitInt, currentHour, setColor_AllFGClasses, setColor_AllFGLength;

            // ── Throughput chart state ─────────────────────────────
            var ztTxHist = (new Array(40)).fill(0);
            var ztRxHist = (new Array(40)).fill(0);
            var ztLastSent = -1, ztLastRecv = -1, ztLastTime = -1;

            function ztFmt(bps) {
                if (bps >= 1048576) return (bps/1048576).toFixed(1) + ' MB/s';
                if (bps >= 1024)    return (bps/1024).toFixed(1)    + ' KB/s';
                return Math.round(bps) + ' B/s';
            }

            function ztDraw() {
                var c = document.getElementById('zt-canvas');
                if (!c) return;
                c.width = c.offsetWidth;
                var W = c.width, H = c.height;
                var ctx = c.getContext('2d');
                ctx.clearRect(0, 0, W, H);
                ctx.fillStyle = 'rgba(0,0,0,0.18)';
                ctx.fillRect(0, 0, W, H);

                var n = ztTxHist.length;         // 40 samples
                var intervalSec = 8;              // seconds between samples
                var totalSec = (n - 1) * intervalSec;  // 312s window
                var mx = 1;
                for (var i = 0; i < n; i++) { if (ztTxHist[i]>mx) mx=ztTxHist[i]; if (ztRxHist[i]>mx) mx=ztRxHist[i]; }
                var step = W / (n - 1);

                function yFor(v) { return H - 2 - (v / mx) * (H - 6); }

                // ── Grid ────────────────────────────────────────────────────
                ctx.lineWidth = 1;
                ctx.setLineDash([2, 4]);
                ctx.strokeStyle = 'rgba(255,255,255,0.08)';
                // Horizontal at 25%, 50%, 75% of max
                [0.25, 0.5, 0.75].forEach(function(f) {
                    var y = yFor(mx * f);
                    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke();
                });
                // Vertical at 1/3 and 2/3 of time window
                [1/3, 2/3].forEach(function(f) {
                    var x = Math.round(f * W);
                    ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, H); ctx.stroke();
                });
                ctx.setLineDash([]);

                // ── Data lines ───────────────────────────────────────────────
                function dataLine(arr, stroke, fill) {
                    ctx.beginPath();
                    for (var i = 0; i < arr.length; i++) {
                        var x = i * step, y = yFor(arr[i]);
                        if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                    }
                    ctx.strokeStyle = stroke; ctx.lineWidth = 1.5;
                    ctx.shadowBlur = 3; ctx.shadowColor = stroke;
                    ctx.stroke(); ctx.shadowBlur = 0;
                    ctx.lineTo(W, H); ctx.lineTo(0, H); ctx.closePath();
                    ctx.fillStyle = fill; ctx.fill();
                }
                dataLine(ztRxHist, '#4caf50', 'rgba(76,175,80,0.20)');
                dataLine(ztTxHist, '#29b6f6', 'rgba(41,182,246,0.20)');

                // ── Average lines ────────────────────────────────────────────
                var txSum = 0, rxSum = 0;
                for (var i = 0; i < n; i++) { txSum += ztTxHist[i]; rxSum += ztRxHist[i]; }
                var txAvg = txSum / n, rxAvg = rxSum / n;
                ctx.font = '9px monospace';
                function avgLine(val, color, tag) {
                    if (val < 1) return;
                    var y = Math.round(yFor(val));
                    ctx.save();
                    ctx.setLineDash([4, 3]);
                    ctx.lineWidth = 1;
                    ctx.strokeStyle = color;
                    ctx.globalAlpha = 0.5;
                    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke();
                    ctx.setLineDash([]);
                    ctx.globalAlpha = 0.75;
                    ctx.fillStyle = color;
                    ctx.textAlign = 'right';
                    var labelY = Math.max(11, Math.min(H - 11, y - 2));
                    ctx.fillText(tag + ' ' + ztFmt(val), W - 3, labelY);
                    ctx.restore();
                }
                avgLine(rxAvg, '#4caf50', 'rxØ');
                avgLine(txAvg, '#29b6f6', 'txØ');

                // ── Y-axis scale (left side) ──────────────────────────────────
                ctx.font = '9px monospace';
                ctx.fillStyle = 'rgba(200,200,200,0.45)';
                ctx.textAlign = 'left';
                ctx.fillText(ztFmt(mx),        3, 20);               // peak (below HTML title)
                ctx.fillText(ztFmt(mx * 0.5),  3, yFor(mx * 0.5) - 2); // 50% gridline

                // ── X-axis time labels (bottom) ───────────────────────────────
                ctx.fillStyle = 'rgba(200,200,200,0.35)';
                ctx.font = '9px monospace';
                ctx.textAlign = 'left';
                ctx.fillText('-' + totalSec + 's', 3, H - 2);
                ctx.textAlign = 'right';
                ctx.fillText('now', W - 3, H - 2);
                [1/3, 2/3].forEach(function(f) {
                    var sec = Math.round((1 - f) * totalSec);
                    ctx.textAlign = 'center';
                    ctx.fillText('-' + sec + 's', Math.round(f * W), H - 2);
                });
            }

            function ztUpdate() {
                var el = document.getElementById('ZET-THROUGHPUT');
                if (!el) return;
                var sent = parseInt(el.getAttribute('data-sent')) || 0;
                var recv = parseInt(el.getAttribute('data-recv')) || 0;
                var now  = Date.now();
                var txRate = 0, rxRate = 0;
                if (ztLastSent >= 0 && ztLastTime > 0 && sent >= ztLastSent) {
                    var dt = (now - ztLastTime) / 1000;
                    if (dt > 0) { txRate = (sent - ztLastSent) / dt; rxRate = (recv - ztLastRecv) / dt; }
                }
                ztLastSent = sent; ztLastRecv = recv; ztLastTime = now;
                ztTxHist.push(txRate); ztTxHist.shift();
                ztRxHist.push(rxRate); ztRxHist.shift();
                var txEl = document.getElementById('ZT-TX');
                var rxEl = document.getElementById('ZT-RX');
                if (txEl) txEl.textContent = 'TX ' + ztFmt(txRate);
                if (rxEl) rxEl.textContent = 'RX ' + ztFmt(rxRate);
                ztDraw();
            }

            // ── Day/night colour switch ────────────────────────────
            function UpdatePageColors() {
                currentHour = new Date().getHours();
                var bp  = document.getElementById('BODYPARENT');
                var ozi = document.getElementById('OPENZITITEXT');
                if (currentHour < 8 || currentHour > 20) {
                    if (bp) { bp.classList.remove('BODYWHITE'); bp.classList.add('BODYBLACK'); }
                    document.body.className = 'FG-WHITE';
                    setColor_AllFGClasses = ['FG-GREY','FG-WHITE'];
                } else {
                    if (bp) { bp.classList.remove('BODYBLACK'); bp.classList.add('BODYWHITE'); }
                    document.body.className = 'FG-BLACK';
                    setColor_AllFGClasses = ['FG-BLACK','FG-GREY','FG-RED','FG-GREEN','FG-BLUE','FG-PURPLE'];
                }
                setColor_AllFGLength = setColor_AllFGClasses.length;
                if (ozi) ozi.className = 'FG-SHADOW ' + setColor_AllFGClasses[Math.floor(Math.random() * setColor_AllFGLength)];
            }

            // ── Fetch and inject ZET status ────────────────────────
            function UpdateZETInfo() {
                waitInt = 0;
                var zetStatus = document.getElementById('ZETLOADSTATUS');
                flagPause = (zetStatus && zetStatus.classList.contains('NOTVISIBLE')) ? 'UNSET' : 'SET';
                fetchHtml('zetdisplay.php', {flagPause: flagPause}, function(data) {
                    if (flagPause === 'SET') {
                        var dateEl = document.getElementById('ZETDATE-BROWSER');
                        if (dateEl) {
                            var tmp = document.createElement('span');
                            tmp.innerHTML = data;
                            dateEl.parentNode.replaceChild(tmp.firstChild || tmp, dateEl);
                        }
                    } else {
                        var targets = [document.getElementById('ZETDETAIL')]
                            .concat(Array.from(document.querySelectorAll('.zt-identity-block')))
                            .filter(Boolean);
                        fadeOutAll(targets, 120, function() {
                            var zetLoad = document.getElementById('ZETLOAD');
                            zetLoad.innerHTML = data;
                            zetLoad.classList.remove('CENTERINFO');
                            document.querySelectorAll('.zt-identity-block').forEach(function(el) {
                                el.style.display = 'none';
                                fadeIn(el, 350);
                            });
                            var chartArea = document.getElementById('ZT-CHART-AREA');
                            if (chartArea && chartArea.style.display !== 'block') fadeIn(chartArea, 400);
                            document.getElementById('BODYPARENT').scrollTop = 0;
                            ztUpdate();
                        });
                    }
                });
            }

            document.addEventListener('DOMContentLoaded', function() {
                fadeIn(document.getElementById('BODYPARENT'));

                fetchHtml('infodisplay.php', {}, function(data) {
                    var infoLoad = document.getElementById('INFOLOAD');
                    infoLoad.classList.add('NOTVISIBLE');
                    infoLoad.innerHTML = data;
                    slideDown(infoLoad, 800);
                    UpdatePageColors();
                    setTimeout(function() {
                        var sysInfo = document.getElementById('SYSTEMINFO');
                        var oziText = document.getElementById('OPENZITITEXT');
                        var bodyImg = document.getElementById('BODYIMG');
                        if (sysInfo) slideUp(sysInfo);
                        if (oziText) slideUp(oziText);
                        if (bodyImg) { bodyImg.classList.remove('OPACITY-C'); bodyImg.classList.add('OPACITY-D'); }
                        document.body.addEventListener('click', function() {
                            var zetStatus = document.getElementById('ZETLOADSTATUS');
                            if (!zetStatus) return;
                            var isVisible = !zetStatus.classList.contains('NOTVISIBLE') && zetStatus.style.display !== 'none';
                            if (isVisible) {
                                fadeOut(zetStatus, 300, function() { zetStatus.classList.add('NOTVISIBLE'); });
                            } else {
                                fadeIn(zetStatus, 300, function() { zetStatus.classList.remove('NOTVISIBLE'); });
                            }
                        });
                    }, 7000);
                });

                setInterval(UpdatePageColors, 30000);
                setInterval(function() {
                    var zetStatus = document.getElementById('ZETLOADSTATUS');
                    var oziText   = document.getElementById('OPENZITITEXT');
                    var paused = zetStatus && !zetStatus.classList.contains('NOTVISIBLE') && zetStatus.style.display !== 'none';
                    if (paused) {
                        UpdatePageColors();
                        if (oziText && oziText.classList.contains('NOTVISIBLE')) slideDown(oziText);
                    } else {
                        if (oziText && !oziText.classList.contains('NOTVISIBLE')) slideUp(oziText);
                    }
                    UpdateZETInfo();
                }, 8000);
            });
        </script>

        <div id="BODYPARENT" class="BODYOVERLAY NOTVISIBLE">
            <span id="INFOLOAD" class="CENTERINFO FULLWIDTH"></span>
            <span id="ZETLOADSTATUS" class="CENTERINFO FULLWIDTH NOTVISIBLE FG-BOLD FG-LARGE FG-BLACK BG-YELLOW">
                REFRESH PAUSED — CLICK TO RESUME
            </span>
            <!-- Persistent throughput chart (not replaced on refresh) -->
            <div id="ZT-CHART-AREA">
                <canvas id="zt-canvas" height="88"></canvas>
                <div id="ZT-CHART-TITLE">Tunnel Throughput</div>
                <div id="ZT-CHART-LABELS">
                    <span id="ZT-TX" style="color:#81d4fa;font-weight:bold">TX —</span>
                    &#160;&#160;
                    <span id="ZT-RX" style="color:#a5d6a7;font-weight:bold">RX —</span>
                </div>
            </div>
            <span id="ZETLOAD" class="CENTERINFO FULLWIDTH">
                <span class="FULLWIDTH FG-BLACK BG-YELLOW">INITIALIZING, PLEASE WAIT…</span>
            </span>
            <span id="BODYIMG" class="ANIMATED T2S OPACITY-C"></span>
        </div>
    </body>
</html>
