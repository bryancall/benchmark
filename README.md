# Benchmarking ATS
Some configuration scripts and a Makefile to run h2load over ATS as a benchmark.

## Assumptions
ATS will need to be installed under `/opt/ats` and `h2load` will need be installed under `/opt/bin/h2load` with http3 support.  dstat and perf will also need to be installed to capture detaile.

## Benchmarking from localhost
Running all the benchmarks for http/1.1, http/1.1 TLS, http2, and http3

    make 

If you want to run selective benchmarks you can use a target to make

    make http
    make https
    make http2
    make http3


## Changing the configuration

To change the IP address for ATS

    CLIENT_IP=10.1.1.1 make update_client

To change the response size from the default 1KB

    SIZE=2048 make update_size

These commands will update the test URL files `urls.http.config` and `urls.https.config`

These benchmark scripts also use runroot feature in ATS and have all the ATS configuration files in this directory.  The configuration directory is under `etc/trafficserver`.

## Benchmarking from a remote host
After changing the IP address of the ATS proxy server above, benchmarks can be run where the `h2load` client is on another host in in the `/opt/bin` directory.
    SSH_COMMAND="ssh eris" make
