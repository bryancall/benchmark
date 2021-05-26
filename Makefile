#
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

TS_RUNROOT:=$(shell pwd)
PATH:=$(PATH):/opt/h2load/bin
YSECURE_UNSAFE_LOCK_CALLBACKS=2
#ATS_DIR=/opt/ats
ATS_DIR=/opt/amd/trafficserver/9.0/

test:
	$(MAKE) http
	$(MAKE) https
	$(MAKE) http2

# Step 1 - setup the test
setup:
	#sudo $(ATS_DIR)/bin/trafficserver stop
	sudo systemctl stop trafficserver9
	sudo rm -f $(ATS_DIR)/var/log/trafficserver/squid.blog*
	sudo systemctl start trafficserver9
	#sudo $(ATS_DIR)/bin/trafficserver start
	rm -f *.log perf.data*

# Step 2 - prime the cache
prime_http:
	curl -s -o /dev/null `cat urls.http.config | xargs` >/dev/null
	curl -s -o /dev/null `cat urls.http.config | xargs` >/dev/null

prime_https:
	curl -s -o /dev/null -k `cat urls.https.config | xargs` >/dev/null
	curl -s -o /dev/null -k `cat urls.https.config | xargs`>/dev/null

# Step 3 - start logging performance data
log_start:
	ssh $(CLIENT_IP) dstat -Nlo,total 10 >& dstat.log &

# Step 4 - run the benchmark
bench_http:
	h2load --h1 -t 30 -n 2000000 -c 200 `cat urls.http.config | xargs` | tail -9 > h2load.log

bench_https:
	h2load --h1 -t 30 -n 2000000 -c 200 `cat urls.https.config | xargs` | tail -9 > h2load.log

bench_http2:
	h2load -t 30 -n 2000000 -c 200 `cat urls.https.config | xargs` | tail -9 > h2load.log

# Step 5 - stop loggging performance data
log_stop:
	ssh $(CLIENT_IP) killall dstat

# Step 6 - make a report
report:
	echo '**http2load**' > report
	cat h2load.log >> report
	echo -e "\n**dstat**" >> report
	cat dstat.log >> report

# Define the tests and generate the report
http: prime_http log_start bench_http log_stop report
	mv report http_benchmark.report

https: prime_https log_start bench_https log_stop report
	mv report https_benchmark.report

http2: prime_https log_start bench_http2 log_stop report
	mv report http2_benchmark.report

install:
	sudo cp -rp h2load /opt/
	sudo yum install -y libev c-ares

clean:
	rm -f *.log perf.data* *report
