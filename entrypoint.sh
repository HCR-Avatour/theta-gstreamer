#!/usr/bin/env bash

gst-launch-1.0 thetauvcsrc mode=2K ! h264parse ! rtspclientsink location=rtsp://mediamtx:8554/theta
