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

    var headerViews = [];
    var labelViews = [];
    var UIApp = objc_getClass(Memory.allocUtf8String('UIApplication'));
    var app = objc_msgSend(UIApp, sel('sharedApplication'));
    var windows = objc_msgSend(app, sel('windows'));
    var wc = objc_msgSend_int(windows, sel('count'));

    function walk(v, d) {
        if(d>30) return;
        var n = cn(v);
        if(n==='MRUNowPlayingHeaderView') headerViews.push(v);
        if(n==='MRUNowPlayingLabelView') labelViews.push(v);
        var subs = objc_msgSend(v, sel('subviews'));
        var sc = objc_msgSend_int(subs, sel('count'));
        for(var i=0;i<sc;i++) walk(objc_msgSend_idx(subs,sel('objectAtIndex:'),i), d+1);
    }
    for(var i=0;i<wc;i++) walk(objc_msgSend_idx(windows,sel('objectAtIndex:'),i),0);

    send('Headers: ' + headerViews.length + ' Labels: ' + labelViews.length);

    for(var h=0; h<headerViews.length; h++) {
        var hv = headerViews[h];
        send('\nHeader ' + h + ': ' + desc(hv));
        send('  hidden=' + hid(hv) + ' alpha=' + alp(hv) + ' layerOp=' + layerOp(hv) + ' clip=' + clip(hv));

        var lv = getIv(hv, '_labelView');
        if(!lv.isNull()) {
            send('  _labelView: ' + desc(lv));
            send('    hidden=' + hid(lv) + ' alpha=' + alp(lv) + ' layerOp=' + layerOp(lv) + ' clip=' + clip(lv));

            // Walk ancestors to find clipping/alpha issues
            var anc = objc_msgSend(lv, sel('superview'));
            var depth = 0;
            while(!anc.isNull() && depth < 8) {
                var acn = cn(anc);
                send('    ancestor[' + depth + '] ' + acn + ' hidden=' + hid(anc) + ' alpha=' + alp(anc) + ' clip=' + clip(anc) + ' layerOp=' + layerOp(anc));
                if(acn==='MRUNowPlayingView') break;
                anc = objc_msgSend(anc, sel('superview'));
                depth++;
            }
        }
    }

    for(var l=0; l<labelViews.length; l++) {
        var lv = labelViews[l];
        send('\nLabelView ' + l + ': ' + desc(lv));
        send('  hidden=' + hid(lv) + ' alpha=' + alp(lv) + ' layerOp=' + layerOp(lv));
        var ivars = ['_titleMarqueeView','_subtitleMarqueeView','_titleLabel','_subtitleLabel'];
        for(var i=0;i<ivars.length;i++) {
            var sv = getIv(lv, ivars[i]);
            if(!sv.isNull()) send('  ' + ivars[i] + ': hidden=' + hid(sv) + ' alpha=' + alp(sv) + ' layerOp=' + layerOp(sv) + ' ' + desc(sv));
        }
        var subs = objc_msgSend(lv, sel('subviews'));
        var sc = objc_msgSend_int(subs, sel('count'));
        for(var s=0;s<sc;s++) {
            var sub = objc_msgSend_idx(subs,sel('objectAtIndex:'),s);
            send('  sub[' + s + '] ' + cn(sub) + ' hidden=' + hid(sub) + ' alpha=' + alp(sub) + ' layerOp=' + layerOp(sub));
        }
    }
} catch(e) { send('ERR: ' + e.message + ' ' + e.stack); }
