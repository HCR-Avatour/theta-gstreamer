#!/usr/bin/env bash

echo "Yay!"
gst-inspect-1.0 thetauvc
gst-launch-1.0 thetauvcsrc mode=4K ! h264parse ! rtspclientsink location=rtsp://mediamtx:8554/theta
