#!/bin/bash

Testing with server $1
iperf3 -t 30 -c $1 -p 5000 &
iperf3 -t 30 -c $1 -p 5001 &
iperf3 -t 30 -c $1 -p 5002 &
iperf3 -t 30 -c $1 -p 5003 &
iperf3 -t 30 -c $1 -p 5004 &
iperf3 -t 30 -c $1 -p 5005 &
iperf3 -t 30 -c $1 -p 5006 &
iperf3 -t 30 -c $1 -p 5007 &
iperf3 -t 30 -c $1 -p 5008 &
iperf3 -t 30 -c $1 -p 5009 &
