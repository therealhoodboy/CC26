'use strict';
try {
var rt = Process.findModuleByName('libobjc.A.dylib');
var objc_getClass = new NativeFunction(rt.findExportByName('objc_getClass'), 'pointer', ['pointer']);
var objc_msgSend = new NativeFunction(rt.findExportByName('objc_msgSend'), 'pointer', ['pointer', 'pointer']);
var objc_msgSend_int = new NativeFunction(rt.findExportByName('objc_msgSend'), 'uint64', ['pointer', 'pointer']);
var objc_msgSend_idx = new NativeFunction(rt.findExportByName('objc_msgSend'), 'pointer', ['pointer', 'pointer', 'uint64']);
var objc_msgSend_f = new NativeFunction(rt.findExportByName('objc_msgSend'), 'float', ['pointer', 'pointer']);
var objc_msgSend_b = new NativeFunction(rt.findExportByName('objc_msgSend'), 'uint8', ['pointer', 'pointer']);
var sel_registerName = new NativeFunction(rt.findExportByName('sel_registerName'), 'pointer', ['pointer']);
var class_getName = new NativeFunction(rt.findExportByName('class_getName'), 'pointer', ['pointer']);
function sel(n){return sel_registerName(Memory.allocUtf8String(n));}
function cn(o){if(o.isNull())return'null';return class_getName(objc_msgSend(o,sel('class'))).readUtf8String();}

var targets = ['CCUIContentModuleContentContainerView','CCUIContinuousSliderView','MRUNowPlayingView','MRUNowPlayingControlsView','MTMaterialView','FCUIActivityControl'];
var app = objc_msgSend(objc_getClass(Memory.allocUtf8String('UIApplication')),sel('sharedApplication'));
var wins = objc_msgSend(app,sel('windows'));
var wc = objc_msgSend_int(wins,sel('count'));

function walk(v,depth){
  if(depth>20)return;
  var n=cn(v);
  var layer=objc_msgSend(v,sel('layer'));
  var cr=objc_msgSend_f(layer,sel('cornerRadius'));
  var bw=objc_msgSend_f(layer,sel('borderWidth'));
  var mask=objc_msgSend_b(v,sel('clipsToBounds'));
  // Report views with cornerRadius or borderWidth, or target classes
  var isTarget=false;
  for(var t=0;t<targets.length;t++){if(n===targets[t]){isTarget=true;break;}}
  if(cr>0||bw>0||isTarget){
    var d=objc_msgSend(v,sel('description'));
    var ds=objc_msgSend(d,sel('UTF8String')).readUtf8String();
    // Extract frame from description
    var fm=ds.match(/frame = \(([^)]+)\)/);
    var frame=fm?fm[1]:'?';
    send(n+' cr='+cr.toFixed(1)+' bw='+bw.toFixed(1)+' clip='+mask+' frame=('+frame+')');
  }
  var subs=objc_msgSend(v,sel('subviews'));
  var sc=objc_msgSend_int(subs,sel('count'));
  for(var i=0;i<sc;i++)walk(objc_msgSend_idx(subs,sel('objectAtIndex:'),i),depth+1);
}
for(var w=0;w<wc;w++){
  var win=objc_msgSend_idx(wins,sel('objectAtIndex:'),w);
  if(cn(win)==='SBControlCenterWindow'||cn(win)==='SBMainScreenActiveInterfaceOrientationWindow')
    walk(win,0);
}
send('DONE');
}catch(e){send('ERR:'+e.message);}
'use strict';
try {
    var rt = Process.findModuleByName('libobjc.A.dylib');
    var objc_getClass = new NativeFunction(rt.findExportByName('objc_getClass'), 'pointer', ['pointer']);
    var objc_msgSend = new NativeFunction(rt.findExportByName('objc_msgSend'), 'pointer', ['pointer', 'pointer']);
    var objc_msgSend_int = new NativeFunction(rt.findExportByName('objc_msgSend'), 'uint64', ['pointer', 'pointer']);
    var objc_msgSend_idx = new NativeFunction(rt.findExportByName('objc_msgSend'), 'pointer', ['pointer', 'pointer', 'uint64']);
    var objc_msgSend_float = new NativeFunction(rt.findExportByName('objc_msgSend'), 'float', ['pointer', 'pointer']);
    var objc_msgSend_bool = new NativeFunction(rt.findExportByName('objc_msgSend'), 'uint8', ['pointer', 'pointer']);
    var objc_msgSend_double = new NativeFunction(rt.findExportByName('objc_msgSend'), 'double', ['pointer', 'pointer']);
    var sel_registerName = new NativeFunction(rt.findExportByName('sel_registerName'), 'pointer', ['pointer']);
    var class_getName = new NativeFunction(rt.findExportByName('class_getName'), 'pointer', ['pointer']);

    function sel(n) { return sel_registerName(Memory.allocUtf8String(n)); }
    function cn(o) { if(o.isNull()) return 'null'; return class_getName(objc_msgSend(o,sel('class'))).readUtf8String(); }

    // CGRect via frame — arm64 returns in x0:x1 (two 64-bit regs packed as doubles)
    var objc_msgSend_frame = new NativeFunction(rt.findExportByName('objc_msgSend'), 'pointer', ['pointer', 'pointer']);

    function getFrameStr(v) {
        try {
            var d = objc_msgSend(v, sel('description'));
            var s = objc_msgSend(d, sel('UTF8String')).readUtf8String();
            // Extract frame from description string
            var m = s.match(/frame = \(([^)]+)\)/);
            if (m) return m[1];
            return '?';
        } catch(e) { return '?'; }
    }

    function getBoundsW(v) {
        try {
            var bv = objc_msgSend(v, sel('bounds'));
            // Can't easily read CGRect on arm64 from msgSend return, use description
            var d = objc_msgSend(v, sel('description'));
            var s = objc_msgSend(d, sel('UTF8String')).readUtf8String();
            var m = s.match(/frame = \(([^;]+); ([0-9.]+) x ([0-9.]+)\)/);
            if (m) return { w: parseFloat(m[2]), h: parseFloat(m[3]) };
            return null;
        } catch(e) { return null; }
    }

    function getLayerInfo(v) {
        var layer = objc_msgSend(v, sel('layer'));
        var cr = objc_msgSend_float(layer, sel('cornerRadius'));
        var bw = objc_msgSend_float(layer, sel('borderWidth'));
        var mtb = objc_msgSend_bool(layer, sel('masksToBounds'));
        var cc = objc_msgSend_bool(layer, sel('continuousCorners'));
        return 'r=' + cr.toFixed(1) + ' bw=' + bw.toFixed(1) + ' mtb=' + mtb + ' cc=' + cc;
    }

    var results = [];
    var UIApp = objc_getClass(Memory.allocUtf8String('UIApplication'));
    var app = objc_msgSend(UIApp, sel('sharedApplication'));
    var windows = objc_msgSend(app, sel('windows'));
    var wc = objc_msgSend_int(windows, sel('count'));

    // Find all views of interest
    var targets = {};
    function walk(v, d) {
        if(d > 40) return;
        var n = cn(v);
        if (!targets[n]) targets[n] = [];
        // Track interesting classes
        var interesting = [
            'CCUIContentModuleContentContainerView',
            'CCUIContinuousSliderView',
            'MRUNowPlayingView',
            'MRUNowPlayingControlsView',
            'MRUNowPlayingHeaderView',
            'MRUNowPlayingTransportControlsView',
            'MTMaterialView',
            'CCUIRoundButton',
            'FCUIActivityControl'
        ];
        for (var i = 0; i < interesting.length; i++) {
            if (n === interesting[i]) {
                targets[n].push(v);
                break;
            }
        }
        var subs = objc_msgSend(v, sel('subviews'));
        var sc = objc_msgSend_int(subs, sel('count'));
        for(var i=0;i<sc;i++) walk(objc_msgSend_idx(subs,sel('objectAtIndex:'),i), d+1);
    }
    for(var i=0;i<wc;i++) walk(objc_msgSend_idx(windows,sel('objectAtIndex:'),i),0);

    // Report findings
    var classes = Object.keys(targets).sort();
    for (var ci = 0; ci < classes.length; ci++) {
        var cls = classes[ci];
        var views = targets[cls];
        send('\n=== ' + cls + ' (' + views.length + ' instances) ===');
        for (var vi = 0; vi < views.length; vi++) {
            var v = views[vi];
            var size = getBoundsW(v);
            var sizeStr = size ? (size.w.toFixed(0) + 'x' + size.h.toFixed(0)) : '?';
            var clip = objc_msgSend_bool(v, sel('clipsToBounds'));
            send('  [' + vi + '] ' + sizeStr + ' clip=' + clip + ' ' + getLayerInfo(v));

            // For containers, show immediate children with radii
            if (cls === 'CCUIContentModuleContentContainerView' || cls === 'MRUNowPlayingView' || cls === 'MRUNowPlayingControlsView') {
                var subs = objc_msgSend(v, sel('subviews'));
                var sc = objc_msgSend_int(subs, sel('count'));
                for (var si = 0; si < sc; si++) {
                    var sub = objc_msgSend_idx(subs, sel('objectAtIndex:'), si);
                    var scn = cn(sub);
                    var ss = getBoundsW(sub);
                    var ssStr = ss ? (ss.w.toFixed(0) + 'x' + ss.h.toFixed(0)) : '?';
                    var sclip = objc_msgSend_bool(sub, sel('clipsToBounds'));
                    send('    child: ' + scn + ' ' + ssStr + ' clip=' + sclip + ' ' + getLayerInfo(sub));
                }
            }

            // For sliders, check if radius > min(w,h)/2 (elliptic!)
            if (cls === 'CCUIContinuousSliderView' && size) {
                var layer = objc_msgSend(v, sel('layer'));
                var cr = objc_msgSend_float(layer, sel('cornerRadius'));
                var maxR = Math.min(size.w, size.h) / 2.0;
                if (cr > maxR + 0.5) {
                    send('    ⚠️ ELLIPTIC! radius=' + cr.toFixed(1) + ' > min/2=' + maxR.toFixed(1));
                }
            }
        }
    }

    send('\n=== DONE ===');
} catch(e) { send('ERR: ' + e.message + ' ' + e.stack); }
