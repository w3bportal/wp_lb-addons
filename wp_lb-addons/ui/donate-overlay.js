(function () {
    const RESOURCE = 'lb-phone';
    let currentStreamer = null;
    let wpConfig = null;

    // Fetch config from Lua once on load
    fetch('https://' + RESOURCE + '/GetWpConfig', {
        method: 'POST',
        body: '{}',
    }).then(function (r) { return r.json(); }).then(function (cfg) {
        wpConfig = cfg;
        var L = (cfg && cfg.Locales) || {};
        btn.title = L.DonateTooltip || 'Donate';
        if (L.DonateChatMessage) {
            var escaped = L.DonateChatMessage.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace('%d', '(\\d+)');
            donationPattern = new RegExp(escaped);
        }
    }).catch(function () {});

    const btn = document.createElement('button');
    btn.id = 'instapic-donate-btn';
    btn.title = 'Donate';
    var btnIcon = document.createElement('i');
    btnIcon.className = 'fas fa-dollar-sign';
    btn.appendChild(btnIcon);
    btn.style.cssText = [
        'background:#0006',
        'color:rgba(255,255,255,.9)',
        'border:none',
        'border-radius:10px',
        'padding:.5rem .8rem',
        'font-size:14px',
        'cursor:pointer',
        'display:none',
        'font-family:inherit',
        'line-height:1',
    ].join(';');

    function tryInsert(retries) {
        var stats = document.querySelector('.instagram-live .live-header .stats');
        if (stats) {
            if (document.querySelector('.instagram-streams .instagram-stream')) return;
            if (btn.parentElement !== stats) {
                stats.insertBefore(btn, stats.firstChild);
            }
            btn.style.display = 'block';
            return;
        }
        if (retries > 0) {
            setTimeout(function () { tryInsert(retries - 1); }, 100);
        }
    }

    btn.addEventListener('click', async function () {
        if (!currentStreamer) return;
        var streamer = currentStreamer;

        var amounts = (wpConfig && wpConfig.DonateAmounts) || [
            { amount: 50,   color: 'green'  },
            { amount: 100,  color: 'green'  },
            { amount: 500,  color: 'green'  },
            { amount: 1000, color: 'yellow' },
        ];
        var L = (wpConfig && wpConfig.Locales) || {};
        var btnLabel = L.DonateBtnLabel || 'Donate $%d';

        var menuData = {
            buttons: amounts.map(function (d, i) {
                return { title: btnLabel.replace('%d', d.amount), color: d.color, callbackId: i };
            }),
        };

        var res = await fetch('https://' + RESOURCE + '/SetContextMenu', {
            method: 'POST',
            body: JSON.stringify(menuData),
        });
        var buttonId = await res.json();

        if (buttonId === undefined || buttonId === null || !amounts[buttonId]) return;
        var amount = amounts[buttonId].amount;

        fetch('https://lb-phone/InstaPicDonate', {
            method: 'POST',
            body: JSON.stringify({ streamer: streamer, amount: amount }),
        });
    });

    window.addEventListener('message', function (event) {
        var d = event.data;
        if (!d || !d.action) return;

        if (d.action === 'instagram:setLive') {
            if (d.data && d.data.host) {
                currentStreamer = d.data.host;
                tryInsert(10);
            }
        } else if (d.action === 'instagram:updateViewers') {
            if (d.data && d.data.username) {
                currentStreamer = d.data.username;
                tryInsert(10);
            }
        } else if (d.action === 'instagram:addMessage') {
            if (d.data && d.data.live && !currentStreamer) {
                currentStreamer = d.data.live;
                tryInsert(10);
            }
        } else if (
            d.action === 'instagram:liveEnded' ||
            d.action === 'instagram:stopLive'
        ) {
            currentStreamer = null;
            btn.style.display = 'none';
        }
    });

    // Inject styles for donation message highlighting
    var style = document.createElement('style');
    style.textContent = [
        '.comment.donation-message{',
            'background:linear-gradient(135deg,rgba(255,215,0,.22),rgba(255,165,0,.12));',
            'border-left:3px solid #FFD700;',
            'border-radius:8px;',
            'padding:3px 8px 3px 6px;',
            'animation:donation-flash .6s ease-out;',
        '}',
        '.comment.donation-message .comment-text{',
            'color:#FFD700;',
            'font-weight:600;',
        '}',
        '@keyframes donation-flash{',
            'from{background:rgba(255,215,0,.55);}',
            'to{background:linear-gradient(135deg,rgba(255,215,0,.22),rgba(255,165,0,.12));}',
        '}',
    ].join('');
    document.head.appendChild(style);

    var donationPattern = /donated \$(\d+)!/;
    var observer = new MutationObserver(function (mutations) {
        for (var i = 0; i < mutations.length; i++) {
            var mutation = mutations[i];

            var removed = mutation.removedNodes;
            for (var r = 0; r < removed.length; r++) {
                if (removed[r] === btn) {
                    if (currentStreamer && document.querySelector('.instagram-live')) {
                        if (!document.querySelector('.instagram-streams .instagram-stream')) {
                            var stats = document.querySelector('.instagram-live .live-header .stats');
                            if (stats) stats.insertBefore(btn, stats.firstChild);
                        }
                    } else {
                        currentStreamer = null;
                        btn.style.display = 'none';
                    }
                    break;
                }
            }

            var added = mutation.addedNodes;
            for (var j = 0; j < added.length; j++) {
                var node = added[j];
                if (node.nodeType !== 1) continue;
                var comments = node.classList && node.classList.contains('comment')
                    ? [node]
                    : node.querySelectorAll ? Array.from(node.querySelectorAll('.comment')) : [];
                for (var k = 0; k < comments.length; k++) {
                    var c = comments[k];
                    var textEl = c.querySelector('.comment-text');
                    if (!textEl) continue;
                    if (donationPattern.test(textEl.textContent)) {
                        c.classList.add('donation-message');
                    }
                }
            }
        }
    });
    observer.observe(document.body, { childList: true, subtree: true });

    (function () {
        var videoCache      = {};
        var videoCacheCount = 0;
        var VIDEO_CACHE_MAX = 200;
        var origFetch = window.fetch;

        function cacheVideo(id, username) {
            if (videoCache[id]) return;
            if (videoCacheCount >= VIDEO_CACHE_MAX) { videoCache = {}; videoCacheCount = 0; }
            videoCache[id] = username;
            videoCacheCount++;
        }

        window.fetch = async function (url, options) {
            var resp = await origFetch.apply(this, arguments);
            if (typeof url === 'string' && url.indexOf('lb-phone/TikTok') !== -1 && options && options.body) {
                try {
                    var body = JSON.parse(options.body);
                    resp.clone().json().then(function (data) {
                        var items = Array.isArray(data) ? data :
                                    (data && Array.isArray(data.videos) ? data.videos :
                                    (data && Array.isArray(data.data)   ? data.data   : []));
                        items.forEach(function (v) { if (v && v.id && v.username) cacheVideo(v.id, v.username); });
                        if (data && !Array.isArray(data) && data.id && data.username) cacheVideo(data.id, data.username);
                    }).catch(function () {});
                    if (body.action === 'setViewed' && body.id) {
                        origFetch('https://lb-phone/TrendyViewPayout', {
                            method: 'POST',
                            body: JSON.stringify({ videoId: body.id, creatorUsername: videoCache[body.id] || null })
                        }).catch(function () {});
                    }
                } catch (e) {}
            }
            return resp;
        };
    })();
})();
