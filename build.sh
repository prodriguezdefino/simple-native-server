#!/bin/bash

#docker build --target native-image -t greeter:native-image .
docker build -t greeter:native-image .

docker tag greeter:native-image greeter:latest
