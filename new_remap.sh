#!/bin/bash

grep -v txn_box.so /home/y/conf/trafficserver/remap.config > /tmp/new_remap.config
lines=$(wc -l /tmp/new_remap.config | awk '{print $1}')
echo "lines: $lines"

tail_lines=$(expr $lines - 10000)
echo "tail_lines: $tail_lines"

head -10000 /tmp/new_remap.config > /tmp/new_generator_remap.config

echo "map http://127.0.0.1/cache/ http://127.0.0.1/cache/ @plugin=generator.so" >> /tmp/new_generator_remap.config
echo "map https://127.0.0.1/cache/ http://127.0.0.1/cache/ @plugin=generator.so" >> /tmp/new_generator_remap.config

tail -$tail_lines /tmp/new_remap.config >> /tmp/new_generator_remap.config

rm /tmp/new_remap.config

sudo mv /home/y/conf/trafficserver/remap.config /home/y/conf/trafficserver/remap.config.orig
sudo mv /tmp/new_generator_remap.config /home/y/conf/trafficserver/remap.config
