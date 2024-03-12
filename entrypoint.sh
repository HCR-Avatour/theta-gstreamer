#!/usr/bin/env bash

MIC_CARD_NUMBER=$(aplay -l | grep ReSpeaker | sed -nE 's/card ([0-9]+):.+/\1/p')

VIDEO_SOURCE="thetauvcsrc mode=4K ! h264parse ! nvv4l2decoder ! nvv4l2h264enc bitrate=10000000 iframeinterval=15 ! h264parse"
AUDIO_SOURCE="alsasrc device=hw:$MIC_CARD_NUMBER"
STREAM_SINK="rtspclientsink location=rtsp://mediamtx:8554/theta"
MUX_PIPELINE="$VIDEO_SOURCE ! mux. $AUDIO_SOURCE ! mux. matroskamux name=mux ! $STREAM_SINK"

gst-launch-1.0 $MUX_PIPELINE
