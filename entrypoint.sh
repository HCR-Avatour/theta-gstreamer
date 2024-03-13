#!/usr/bin/env bash

MIC_CARD_NUMBER=$(aplay -l | grep ReSpeaker | sed -nE 's/card ([0-9]+):.+/\1/p')

VIDEO_SOURCE="thetauvcsrc mode=4K ! h264parse ! nvv4l2decoder ! nvv4l2h264enc bitrate=10000000 iframeinterval=15 ! h264parse"
AUDIO_SOURCE="alsasrc device=hw:$MIC_CARD_NUMBER"
STREAM_SINK="rtspclientsink location=rtsp://mediamtx:8554/theta protocols=tcp"
MUX_PIPELINE="$STREAM_SINK name=stream   $VIDEO_SOURCE ! stream.sink_0   $AUDIO_SOURCE ! audioconvert ! stream.sink_1"

gst-launch-1.0 $MUX_PIPELINE
