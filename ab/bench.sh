#!/bin/bash

#POST
ab -A appuser:sys -m POST -n 100 -c 10 http://webgateway/csp/myapp/test

#GET
ab -A appuser:sys -n 100 -c 10 http://webgateway/csp/myapp/test
