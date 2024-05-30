#!/bin/bash
set -e

docker-compose down && rm -rf sqlserver-data/ && rm -rf pgdata/  

