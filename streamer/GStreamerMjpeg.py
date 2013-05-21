"""
Created on May 19, 2013

@author: sgoldsmith

Copyright (c) Steven P. Goldsmith

All rights reserved.
"""
import socket
import select
import threading
import wsgiref.simple_server
import SocketServer
import IPCameraApp

class GStreamerMjpeg(SocketServer.ThreadingMixIn, wsgiref.simple_server.WSGIServer):
    """GStreamer multipartmux MJPEG streamer.
    
    Based on https://gist.github.com/tzicatl/2409785
    
    Run this script and then launch the following GStreamer pipeline:
    
    Camera produces image/jpeg (this is the most efficient since no encoding takes place):
    
    gst-launch-1.0 v4l2src, timeout=5 ! image/jpeg, framerate=30/1, width=800, height=600 ! multipartmux boundary=cvp ! tcpclientsink port=9999
    
    Camera produces video/x-raw:

    gst-launch-1.0 v4l2src, timeout=5 ! video/x-raw, framerate=30/1, width=800, height=600 ! jpegenc ! multipartmux boundary=cvp ! tcpclientsink port=9999
    
    If you see 'libv4l2: error dequeuing buf: Success' errors add &>/dev/null to the end of the command string.

    """ 
    pass

def createServer(host, port, app, server_class=wsgiref.simple_server.WSGIServer, handler_class=wsgiref.simple_server.WSGIRequestHandler):
    return wsgiref.simple_server.make_server(host, port, app, server_class, handler_class) 

def inputLoop(app):
    sock = socket.socket()
    sock.bind(('', 9999))
    sock.listen(1)
    while True:
        print "Waiting for input stream from gstreamer..."
        sd, addr = sock.accept()
        print "Accepted input stream from", addr
        data = True
        while data:
            readable = select.select([sd], [], [], 0.1)[0]
            for s in readable:
                data = s.recv(1024)
                if not data:
                    break
                for q in app.queues:
                    q.put(data)
        print "Lost input stream from", addr

if __name__ == "__main__":
    # Launch an instance of wsgi server
    app = IPCameraApp.IPCameraApp()
    port = 1337
    print "Launching camera server on port", port
    httpd = createServer('', port, app)

    print "Launch input stream thread"
    t1 = threading.Thread(target=inputLoop, args=[app])
    t1.setDaemon(True)
    t1.start()

    try:
        print "Httpd serve forever"
        httpd.serve_forever()
    except KeyboardInterrupt:
        httpd.kill()
        print "Shutdown camera server"
