#!/bin/bash
#
# Execute testrunner for each test file in the /run/tests/ directory
set -xeo pipefail
shopt -s nullglob

for test in /run/tests/*; do
  testrunner -logtostderr "--test_spec=${test}"
done
