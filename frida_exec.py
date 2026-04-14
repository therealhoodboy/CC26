#!/usr/bin/env python3
import frida, sys, time
mgr = frida.get_device_manager()
device = mgr.add_remote_device("192.168.0.32:27042")
procs = device.enumerate_processes()
sb = [p for p in procs if 'Spring' in p.name]
session = device.attach(sb[0].pid)
with open(sys.argv[1]) as f:
    code = f.read()
script = session.create_script(code)
def on_message(message, data):
    if message['type'] == 'send':
        print(message['payload'])
    else:
        print(message)
script.on('message', on_message)
script.load()
time.sleep(2)
session.detach()
