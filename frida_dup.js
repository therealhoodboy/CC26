'use strict';
try {
    var rt = Process.findModuleByName('libobjc.A.dylib');
    var objc_getClass = new NativeFunction(rt.findExportByName('objc_getClass'), 'pointer', ['pointer']);
    var objc_msgSend = new NativeFunction(rt.findExportByName('objc_msgSend'), 'pointer', ['pointer', 'pointer']);
    var objc_msgSend_int = new NativeFunction(rt.findExportByName('objc_msgSend'), 'uint64', ['pointer', 'pointer']);
    var objc_msgSend_idx = new NativeFunction(rt.findExportByName('objc_msgSend'), 'pointer', ['pointer', 'pointer', 'uint64']);
    var objc_msgSend_float = new NativeFunction(rt.findExportByName('objc_msgSend'), 'float', ['pointer', 'pointer']);
    var objc_msgSend_bool = new NativeFunction(rt.findExportByName('objc_msgSend'), 'uint8', ['pointer', 'pointer']);
    var sel_registerName = new NativeFunction(rt.findExportByName('sel_registerName'), 'pointer', ['pointer']);
    var class_getName = new NativeFunction(rt.findExportByName('class_getName'), 'pointer', ['pointer']);
    var object_getIvar = new NativeFunction(rt.findExportByName('object_getIvar'), 'pointer', ['pointer', 'pointer']);
    var class_getInstanceVariable = new NativeFunction(rt.findExportByName('class_getInstanceVariable'), 'pointer', ['pointer', 'pointer']);

    function sel(n) { return sel_registerName(Memory.allocUtf8String(n)); }
    function cn(o) { if(o.isNull()) return 'null'; return class_getName(objc_msgSend(o,sel('class'))).readUtf8String(); }
    function getIv(o,n) { var c=objc_msgSend(o,sel('class')); var iv=class_getInstanceVariable(c,Memory.allocUtf8String(n)); if(iv.isNull()) return ptr(0); return object_getIvar(o,iv); }
    function desc(o) { if(o.isNull()) return 'nil'; var d=objc_msgSend(o,sel('description')); return objc_msgSend(d,sel('UTF8String')).readUtf8String(); }
    function hid(o) { return objc_msgSend_bool(o,sel('isHidden')); }
    function alp(o) { return objc_msgSend_float(o,sel('alpha')); }
    function layerOp(o) { var layer=objc_msgSend(o,sel('layer')); return objc_msgSend_float(layer,sel('opacity')); }
    function clip(o) { return objc_msgSend_bool(o,sel('clipsToBounds')); }
    function getText(o) { try { var t=objc_msgSend(o,sel('text')); if(t.isNull()) return ''; return objc_msgSend(t,sel('UTF8String')).readUtf8String(); } catch(e) { return ''; } }

    var labelViews = [];
    var UIApp = objc_getClass(Memory.allocUtf8String('UIApplication'));
    var app = objc_msgSend(UIApp, sel('sharedApplication'));
    var windows = objc_msgSend(app, sel('windows'));
    var wc = objc_msgSend_int(windows, sel('count'));

    function walk(v, d) {
        if(d>30) return;
        var n = cn(v);
        if(n==='MRUNowPlayingLabelView') labelViews.push(v);
        var subs = objc_msgSend(v, sel('subviews'));
        var sc = objc_msgSend_int(subs, sel('count'));
        for(var i=0;i<sc;i++) walk(objc_msgSend_idx(subs,sel('objectAtIndex:'),i), d+1);
    }
    for(var i=0;i<wc;i++) walk(objc_msgSend_idx(windows,sel('objectAtIndex:'),i),0);

    send('Found ' + labelViews.length + ' MRUNowPlayingLabelView');

    for(var l=0; l<labelViews.length; l++) {
        var lv = labelViews[l];
        send('\n=== LabelView ' + l + ' ===');
        send('  hidden=' + hid(lv) + ' alpha=' + alp(lv) + ' layerOp=' + layerOp(lv) + ' clip=' + clip(lv));

        // Ivars
        var titleLabel = getIv(lv, '_titleLabel');
        var subtitleLabel = getIv(lv, '_subtitleLabel');
        var titleMarquee = getIv(lv, '_titleMarqueeView');
        var subtitleMarquee = getIv(lv, '_subtitleMarqueeView');

        send('  _titleLabel: ' + cn(titleLabel) + ' hidden=' + hid(titleLabel) + ' alpha=' + alp(titleLabel) + ' text="' + getText(titleLabel) + '"');
        if(!titleLabel.isNull()) send('    superview=' + cn(objc_msgSend(titleLabel, sel('superview'))) + ' addr=' + objc_msgSend(titleLabel, sel('superview')));

        send('  _subtitleLabel: ' + cn(subtitleLabel) + ' hidden=' + hid(subtitleLabel) + ' alpha=' + alp(subtitleLabel) + ' text="' + getText(subtitleLabel) + '"');
        if(!subtitleLabel.isNull()) send('    superview=' + cn(objc_msgSend(subtitleLabel, sel('superview'))) + ' addr=' + objc_msgSend(subtitleLabel, sel('superview')));

        send('  _titleMarqueeView: ' + cn(titleMarquee) + ' hidden=' + hid(titleMarquee) + ' alpha=' + alp(titleMarquee) + ' clip=' + clip(titleMarquee));
        if(!titleMarquee.isNull()) send('    superview=' + cn(objc_msgSend(titleMarquee, sel('superview'))) + ' addr=' + objc_msgSend(titleMarquee, sel('superview')));

        send('  _subtitleMarqueeView: ' + cn(subtitleMarquee) + ' hidden=' + hid(subtitleMarquee) + ' alpha=' + alp(subtitleMarquee) + ' clip=' + clip(subtitleMarquee));
        if(!subtitleMarquee.isNull()) send('    superview=' + cn(objc_msgSend(subtitleMarquee, sel('superview'))) + ' addr=' + objc_msgSend(subtitleMarquee, sel('superview')));

        // All direct subviews
        send('\n  Direct subviews:');
        var subs = objc_msgSend(lv, sel('subviews'));
        var sc = objc_msgSend_int(subs, sel('count'));
        for(var s=0;s<sc;s++) {
            var sub = objc_msgSend_idx(subs,sel('objectAtIndex:'),s);
            var scn = cn(sub);
            var extra = '';
            if(scn.indexOf('Label') >= 0 || scn.indexOf('Emoji') >= 0 || scn === 'UILabel') extra = ' text="' + getText(sub) + '"';
            send('  sub[' + s + '] ' + scn + ' ' + sub + ' hidden=' + hid(sub) + ' alpha=' + alp(sub) + ' clip=' + clip(sub) + extra);

            // Children of each subview (e.g. marquee children)
            var subsubs = objc_msgSend(sub, sel('subviews'));
            var ssc = objc_msgSend_int(subsubs, sel('count'));
            for(var ss=0;ss<ssc;ss++) {
                var ssub = objc_msgSend_idx(subsubs,sel('objectAtIndex:'),ss);
                var sscn = cn(ssub);
                var extra2 = '';
                if(sscn.indexOf('Label') >= 0 || sscn.indexOf('Emoji') >= 0 || sscn === 'UILabel') extra2 = ' text="' + getText(ssub) + '"';
                send('    child[' + ss + '] ' + sscn + ' ' + ssub + ' hidden=' + hid(ssub) + ' alpha=' + alp(ssub) + ' clip=' + clip(ssub) + extra2);
            }
        }
    }
} catch(e) { send('ERR: ' + e.message + ' ' + e.stack); }
