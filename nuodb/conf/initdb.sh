#!/bin/bash
/usr/bin/influx --execute "CREATE DATABASE nuodb WITH DURATION 365d REPLICATION 1 SHARD DURATION 1d NAME nuodbrp"
/usr/bin/influx --execute "CREATE DATABASE nuodb_internal WITH DURATION 365d REPLICATION 1 SHARD DURATION 1d NAME nuodbrp"
