# Theta GStreamer

This repository contains a GStreamer pipeline that:
* Streams live audio from a USB Microphone
* Streams live video from a Ricoh Theta Z1 camera
* Transcodes the video to 10Mbps H.264 using Nvidia Deepstream (GPU-accelerated)
* Streams the combined audio and video over RTSP

This repository also contains:
* A Dockerfile for building the custom image needed to run the pipeline:
  * Building a recent version of GStreamer from source since Deepstream's version is too old and doesn't contain ALSA plugins
  * Building a custom `libuvc` to read from the camera
  * Building a custom GStreamer plugin to use the modified `libuvc`
* A `docker-compose.yaml` file which sets up the stream in a container and runs [MediaMTX](https://github.com/bluenviron/mediamtx) to allow multiple clients to receive the stream using RTSP **or** WebRTC.

## Building / Running

This is designed to run in an Nvidia Deepstream compatible Docker environment (such as an Nvidia Jetson computer).

You need to change `MTX_WEBRTCADDITIONALHOSTS` in `docker-compose.yml` to a hostname/IP that clients can use to access the stream from (e.g. `localhost`). This is due to how WebRTC sets up its UDP streams.

Running: `docker compose up -d --build`. The video should then become available at `http://localhost:8889/theta`.

## About

This project was written by [Harry Phillips](https://github.com/harryjph).

This project was used as part of the Avatour team's Human Centered Robotics project (Imperial College London, MEng EIE 4th year).
