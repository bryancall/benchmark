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
YSECURE_UNSAFE_LOCK_CALLBACKS=2
ATS_DIR=/opt/ats
NUM_REQ=20000000
NUM_REQ2=$$((20000000 * 2))
REMOTE_BENCHMARK=/home/bcall/dev/benchmark

test:
	$(MAKE) http
	$(MAKE) https
	$(MAKE) http2
	$(MAKE) http3

# Step 1 - setup the test
setup:
	$(ATS_DIR)/bin/trafficserver stop
	#sudo systemctl stop trafficserver9
	sudo rm -f $(ATS_DIR)/var/log/trafficserver/squid.blog*
	#sudo systemctl start trafficserver9
	$(ATS_DIR)/bin/trafficserver start
	rm -f *.log perf.data*
	sleep 2

# Step 2 - prime the cache
prime_http:
	curl -s -o /dev/null `cat urls.http.config | xargs` >/dev/null
	curl -s -o /dev/null `cat urls.http.config | xargs` >/dev/null

prime_https:
	curl -s -o /dev/null -k `cat urls.https.config | xargs` >/dev/null
	curl -s -o /dev/null -k `cat urls.https.config | xargs`>/dev/null

# Step 3 - start logging performance data
log_start:
	dstat -Nlo,total 10 >& dstat.log &
	sudo perf record -F 1000 -a sleep 1200 &
	sudo perf stat -p `pidof traffic_server` >& perf-stat.log &

# Step 4 - run the benchmark
bench_http:
	#/opt/bin/h2load --h1 -t 30 -n $(NUM_REQ2) -c 1000 `cat urls.http.config | xargs` | tail -9 > h2load.log
	/opt/bin/h2load --h1 --warm-up-time 5 -D 30 -t 30 -n $(NUM_REQ2) -c 900 `cat urls.http.config | xargs` | tail -9 > h2load.log

bench_https:
	/opt/bin/h2load --h1 -t 30 -n $(NUM_REQ) -c 900 `cat urls.https.config | xargs` | tail -9 > h2load.log

bench_http2:
	/opt/bin/h2load -t 30 -n $(NUM_REQ) -m 9 -c 100 `cat urls.https.config | xargs` | tail -9 > h2load.log

bench_http3:
	/opt/bin/h2load -t 30 -n $(NUM_REQ) -m 9 -c 100 --npn-list=h3 `cat urls.https.config | xargs` | tail -10 > h2load.log

# Step 5 - stop loggging performance data
log_stop:
	#killall dstat
	ps axuw | grep dsta[t] | awk '{print $$2}' | xargs kill
	sudo killall -s SIGINT perf
	sudo killall -s SIGINT perf || echo "it's ok"
	while [ `ps axuw | grep perf | grep -v grep | wc -l` != '0' ]; do echo "perf still running"; sleep 1; done
	sleep 1
	sudo perf report -sdso,symbol --stdio  -w10,20,50 | grep -v h2load | grep -v swapper | head -150 | tail -147 > perf-report.log

# Step 6 - make a report
report:
	echo '**http2load**' > report
	cat h2load.log >> report
	echo -e "\n**dstat**" >> report
	cat dstat.log >> report
	echo '**perf stat**' >> report
	cat perf-stat.log >> report
	echo '**perf report**' >> report
	cat perf-report.log >> report

# Define the tests and generate the report
http: setup prime_http log_start bench_http log_stop report
	mv report http_benchmark.report

https: setup prime_https log_start bench_https log_stop report
	mv report https_benchmark.report

http2: setup prime_https log_start bench_http2 log_stop report
	mv report http2_benchmark.report

http3: setup prime_https log_start bench_http3 log_stop report
	mv report http3_benchmark.report

update_url_files:
	sed -i "s/127.0.0.1/$(CLIENT_IP)/" urls.http.config
	sed -i "s/127.0.0.1/$(CLIENT_IP)/" urls.https.config

clean:
	rm -f *.log perf.data* *report
