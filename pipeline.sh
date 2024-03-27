#!/usr/bin/env bash

# Select the correct microphone input
MIC_CARD_NUMBER=$(aplay -l | grep ReSpeaker | sed -nE 's/card ([0-9]+):.+/\1/p')

# The GStreamer pipeline (excluding sink) to read video from the camera. Sources from the custom theta source, transcodes using Nvidia Deepstream
VIDEO_SOURCE="thetauvcsrc mode=4K ! h264parse ! nvv4l2decoder ! nvv4l2h264enc bitrate=10000000 iframeinterval=15 ! h264parse"
# The GStreamer pipeline (excluding sink) to read audio from the microphone. Currently just a simple alsasrc
AUDIO_SOURCE="alsasrc device=hw:$MIC_CARD_NUMBER"
# The GStreamer sink to stream over RTSP
STREAM_SINK="rtspclientsink location=rtsp://mediamtx:8554/theta protocols=tcp"
# The full GStreamer pipeline multiplexing audio and video and sinking to the stream (combining all of the above)
MUX_PIPELINE="$STREAM_SINK name=stream   $VIDEO_SOURCE ! stream.sink_0   $AUDIO_SOURCE ! audioconvert ! stream.sink_1"

gst-launch-1.0 $MUX_PIPELINE
