#!/bin/bash
#
# Copyright (c) 2016, PLUMgrid Inc, http://plumgrid.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Usage:
# Place this plugin in /usr/lib/rackspace-monitoring-agent/plugins
#
# Returns 1 metric:
#  - status_pg_trace_collector: UP/DWON

metrics=()

# Check: PG trace collector
check=$(ps aux | grep 'launch_trace_collector' | grep -c '^')
if [[ $? != 0 ]]; then
  echo "status error: '$check'"
  exit 1
fi
if [[ $check -eq 2 ]];then
  metrics+=("metric status_pg_trace_collector string UP")
else
  metrics+=("metric status_pg_trace_collector string DOWN")
fi

echo "$(printf '%s\n' "${metrics[@]}")"

exit 0
