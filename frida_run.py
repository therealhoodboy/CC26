#!/usr/bin/env python3
import frida
import sys
import time
import os

os.environ["FRIDA_SERVER"] = "192.168.0.32"
mgr = frida.get_device_manager()
device = mgr.add_remote_device("192.168.0.32:27042")
print("Device:", device.name, device.type)
procs = device.enumerate_processes()
sb = [p for p in procs if 'Spring' in p.name]
print("SpringBoard PID:", sb[0].pid)

session = device.attach(sb[0].pid)
script = session.create_script("""
'use strict';
try {
    var runtime = Process.findModuleByName('libobjc.A.dylib');
    
    var objc_getClass = new NativeFunction(runtime.findExportByName('objc_getClass'), 'pointer', ['pointer']);
    var class_copyIvarList = new NativeFunction(runtime.findExportByName('class_copyIvarList'), 'pointer', ['pointer', 'pointer']);
    var ivar_getName = new NativeFunction(runtime.findExportByName('ivar_getName'), 'pointer', ['pointer']);
    var class_getSuperclass = new NativeFunction(runtime.findExportByName('class_getSuperclass'), 'pointer', ['pointer']);
    var class_getName = new NativeFunction(runtime.findExportByName('class_getName'), 'pointer', ['pointer']);
    var objc_msgSend = new NativeFunction(runtime.findExportByName('objc_msgSend'), 'pointer', ['pointer', 'pointer']);
    var sel_registerName = new NativeFunction(runtime.findExportByName('sel_registerName'), 'pointer', ['pointer']);
    var class_copyMethodList = new NativeFunction(runtime.findExportByName('class_copyMethodList'), 'pointer', ['pointer', 'pointer']);
    var method_getName = new NativeFunction(runtime.findExportByName('method_getName'), 'pointer', ['pointer']);
    var sel_getName = new NativeFunction(runtime.findExportByName('sel_getName'), 'pointer', ['pointer']);
    
    function getIvars(clsName) {
        var namePtr = Memory.allocUtf8String(clsName);
        var cls = objc_getClass(namePtr);
        if (cls.isNull()) { send(clsName + ": class not found"); return []; }
        var countPtr = Memory.alloc(4);
        var ivars = class_copyIvarList(cls, countPtr);
        var count = countPtr.readU32();
        var names = [];
        for (var i = 0; i < count; i++) {
            var ivar = ivars.add(i * Process.pointerSize).readPointer();
            names.push(ivar_getName(ivar).readUtf8String());
        }
        send(clsName + " ivars (" + count + "): " + JSON.stringify(names));
        return names;
    }
    
    function getMethods(clsName) {
        var namePtr = Memory.allocUtf8String(clsName);
        var cls = objc_getClass(namePtr);
        if (cls.isNull()) { send(clsName + ": class not found"); return []; }
        var countPtr = Memory.alloc(4);
        var methods = class_copyMethodList(cls, countPtr);
        var count = countPtr.readU32();
        var names = [];
        for (var i = 0; i < count; i++) {
            var method = methods.add(i * Process.pointerSize).readPointer();
            var sel = method_getName(method);
            names.push(sel_getName(sel).readUtf8String());
        }
        return names;
    }
    
    function getSuperclass(clsName) {
        var namePtr = Memory.allocUtf8String(clsName);
        var cls = objc_getClass(namePtr);
        if (cls.isNull()) return "null";
        var superCls = class_getSuperclass(cls);
        if (superCls.isNull()) return "null";
        return class_getName(superCls).readUtf8String();
    }
    
    // Inspect media module classes
    send("=== MRUControlCenterView ===");
    getIvars('MRUControlCenterView');
    send("super: " + getSuperclass('MRUControlCenterView'));
    
    send("\\n=== MRUNowPlayingView ===");
    getIvars('MRUNowPlayingView');
    
    send("\\n=== MRUNowPlayingHeaderView ===");
    getIvars('MRUNowPlayingHeaderView');
    
    send("\\n=== MRUNowPlayingTransportControlsView ===");
    getIvars('MRUNowPlayingTransportControlsView');
    
    send("\\n=== MRUTransportButton ===");
    getIvars('MRUTransportButton');
    send("super: " + getSuperclass('MRUTransportButton'));
    
    // Check for routing/airplay related classes
    send("\\n=== MRUNowPlayingRoutingButton ===");
    getIvars('MRUNowPlayingRoutingButton');
    
    send("\\n=== MRURoutingView ===");
    getIvars('MRURoutingView');
    
    // Check methods that might relate to AirPlay/device buttons
    send("\\n=== MRUNowPlayingView layout methods ===");
    var npMethods = getMethods('MRUNowPlayingView');
    var layoutMethods = npMethods.filter(function(m) {
        return m.indexOf('layout') !== -1 || m.indexOf('Layout') !== -1 ||
               m.indexOf('route') !== -1 || m.indexOf('Route') !== -1 ||
               m.indexOf('airplay') !== -1 || m.indexOf('Airplay') !== -1 ||
               m.indexOf('AirPlay') !== -1 || m.indexOf('device') !== -1 ||
               m.indexOf('Device') !== -1 || m.indexOf('button') !== -1 ||
               m.indexOf('Button') !== -1;
    });
    send("relevant methods: " + JSON.stringify(layoutMethods));
    
    send("\\n=== MRUControlCenterView methods ===");
    var ccMethods = getMethods('MRUControlCenterView');
    var ccRelevant = ccMethods.filter(function(m) {
        return m.indexOf('route') !== -1 || m.indexOf('Route') !== -1 ||
               m.indexOf('airplay') !== -1 || m.indexOf('AirPlay') !== -1 ||
               m.indexOf('device') !== -1 || m.indexOf('Device') !== -1 ||
               m.indexOf('button') !== -1 || m.indexOf('Button') !== -1 ||
               m.indexOf('layout') !== -1 || m.indexOf('Layout') !== -1;
    });
    // Dump the live view hierarchy to verify the new layout
    var object_getIvar = new NativeFunction(runtime.findExportByName('object_getIvar'), 'pointer', ['pointer', 'pointer']);
    var class_getInstanceVariable = new NativeFunction(runtime.findExportByName('class_getInstanceVariable'), 'pointer', ['pointer', 'pointer']);
    
    var sel_subviews = sel_registerName(Memory.allocUtf8String('subviews'));
    var objc_msgSend_int = new NativeFunction(runtime.findExportByName('objc_msgSend'), 'uint64', ['pointer', 'pointer']);
    var objc_msgSend_idx = new NativeFunction(runtime.findExportByName('objc_msgSend'), 'pointer', ['pointer', 'pointer', 'uint64']);
    var sel_utf8 = sel_registerName(Memory.allocUtf8String('UTF8String'));
    
    var UIApp = objc_getClass(Memory.allocUtf8String('UIApplication'));
    var app = objc_msgSend(UIApp, sel_registerName(Memory.allocUtf8String('sharedApplication')));
    var windows = objc_msgSend(app, sel_registerName(Memory.allocUtf8String('windows')));
    var wCount = objc_msgSend_int(windows, sel_registerName(Memory.allocUtf8String('count')));
    
    function cn(obj) {
        if (obj.isNull()) return "null";
        var cls = objc_msgSend(obj, sel_registerName(Memory.allocUtf8String('class')));
        return class_getName(cls).readUtf8String();
    }
    
    function getIvarObj(obj, name) {
        var cls = objc_msgSend(obj, sel_registerName(Memory.allocUtf8String('class')));
        var ivar = class_getInstanceVariable(cls, Memory.allocUtf8String(name));
        if (ivar.isNull()) return ptr(0);
        return object_getIvar(obj, ivar);
    }
    
    function desc(obj) {
        if (obj.isNull()) return "nil";
        var d = objc_msgSend(obj, sel_registerName(Memory.allocUtf8String('description')));
        return objc_msgSend(d, sel_utf8).readUtf8String();
    }
    
    var headerViews = [];
    var npViews = [];
    var transportViews = [];
    function findViews(view, depth) {
        if (depth > 25) return;
        var name = cn(view);
        if (name === 'MRUNowPlayingHeaderView') headerViews.push(view);
        if (name === 'MRUNowPlayingView') npViews.push(view);
        if (name === 'MRUNowPlayingTransportControlsView') transportViews.push(view);
        var subs = objc_msgSend(view, sel_subviews);
        var c = objc_msgSend_int(subs, sel_registerName(Memory.allocUtf8String('count')));
        for (var i = 0; i < c; i++) {
            findViews(objc_msgSend_idx(subs, sel_registerName(Memory.allocUtf8String('objectAtIndex:')), i), depth + 1);
        }
    }
    for (var w = 0; w < wCount; w++) {
        findViews(objc_msgSend_idx(windows, sel_registerName(Memory.allocUtf8String('objectAtIndex:')), w), 0);
    }
    
    send("NowPlayingViews: " + npViews.length + ", HeaderViews: " + headerViews.length + ", TransportViews: " + transportViews.length);
    
    for (var i = 0; i < npViews.length; i++) {
        send("\\nNPView[" + i + "]: " + desc(npViews[i]));
        send("  _layout: " + getIvarObj(npViews[i], '_layout'));
    }
    
    for (var i = 0; i < headerViews.length; i++) {
        var hv = headerViews[i];
        send("\\nHeaderView[" + i + "]: " + desc(hv));
        
        var artwork = getIvarObj(hv, '_artworkView');
        var label = getIvarObj(hv, '_labelView');
        var routing = getIvarObj(hv, '_routingButton');
        var transport = getIvarObj(hv, '_transportButton');
        
        send("  artwork: " + desc(artwork));
        send("  label: " + desc(label));
        send("  routing: " + desc(routing));
        send("  transport: " + desc(transport));
    }
    
    for (var i = 0; i < transportViews.length; i++) {
        var tv = transportViews[i];
        send("\\nTransportView[" + i + "]: " + desc(tv));
        
        var left = getIvarObj(tv, '_leftButton');
        var middle = getIvarObj(tv, '_middleButton');
        var right = getIvarObj(tv, '_rightButton');
        
        send("  left: " + desc(left));
        send("  middle: " + desc(middle));
        send("  right: " + desc(right));
    }
    
} catch(e) {
    send("Error: " + e.message + " stack: " + e.stack);
}
""")

def on_message(message, data):
    if message['type'] == 'send':
        print(message['payload'])
    elif message['type'] == 'error':
        print("ERROR: " + message['description'])

script.on('message', on_message)
script.load()
time.sleep(2)
session.detach()
