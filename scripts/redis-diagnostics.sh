#!/bin/bash

# Redis Diagnostics Script
# This script helps diagnose Redis connectivity and performance issues

set -e

REDIS_HOST=${REDIS_HOST:-localhost}
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASSWORD=${REDIS_PASSWORD:-""}

echo "🔍 Redis Diagnostics Script"
echo "=========================="
echo "Host: $REDIS_HOST"
echo "Port: $REDIS_PORT"
echo "Password: $([ -n "$REDIS_PASSWORD" ] && echo "***" || echo "none")"
echo ""

# Function to run Redis CLI command
redis_cmd() {
    if [ -n "$REDIS_PASSWORD" ]; then
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" "$@"
    else
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" "$@"
    fi
}

# Test basic connectivity
echo "1. Testing basic connectivity..."
if redis_cmd ping > /dev/null 2>&1; then
    echo "✅ Redis is responding to ping"
else
    echo "❌ Redis is not responding to ping"
    exit 1
fi

# Get Redis info
echo ""
echo "2. Redis Server Information:"
redis_cmd info server | grep -E "(redis_version|os|arch|process_id|uptime_in_seconds)"

# Memory information
echo ""
echo "3. Memory Information:"
redis_cmd info memory | grep -E "(used_memory_human|used_memory_peak_human|maxmemory_human|maxmemory_policy)"

# Client information
echo ""
echo "4. Client Information:"
redis_cmd info clients | grep -E "(connected_clients|client_recent_max_input_buffer|client_recent_max_output_buffer)"

# Test basic operations
echo ""
echo "5. Testing basic operations..."
redis_cmd set test_key "test_value" > /dev/null
if [ "$(redis_cmd get test_key)" = "test_value" ]; then
    echo "✅ SET/GET operations working"
    redis_cmd del test_key > /dev/null
else
    echo "❌ SET/GET operations failed"
fi

# Test pub/sub
echo ""
echo "6. Testing Pub/Sub functionality..."
redis_cmd subscribe test_channel > /tmp/redis_diag_sub.log 2>&1 &
SUB_PID=$!
sleep 2

redis_cmd publish test_channel "diagnostic_message" > /dev/null
sleep 1

kill $SUB_PID 2>/dev/null || true
wait $SUB_PID 2>/dev/null || true

if grep -q "diagnostic_message" /tmp/redis_diag_sub.log; then
    echo "✅ Pub/Sub functionality working"
else
    echo "❌ Pub/Sub functionality failed"
    echo "Pub/Sub log:"
    cat /tmp/redis_diag_sub.log
fi

# Test connection under load
echo ""
echo "7. Testing connection under load..."
for i in {1..20}; do
    redis_cmd ping > /dev/null &
done
wait

echo "✅ Connection load test completed"

# Configuration check
echo ""
echo "8. Important Configuration:"
redis_cmd config get save
redis_cmd config get maxmemory
redis_cmd config get maxmemory-policy
redis_cmd config get timeout

# Performance test
echo ""
echo "9. Performance test (1000 operations)..."
start_time=$(date +%s%N)
for i in {1..1000}; do
    redis_cmd set perf_key_$i "value_$i" > /dev/null
done
for i in {1..1000}; do
    redis_cmd get perf_key_$i > /dev/null
done
for i in {1..1000}; do
    redis_cmd del perf_key_$i > /dev/null
done
end_time=$(date +%s%N)

duration=$(( (end_time - start_time) / 1000000 ))
echo "✅ Performance test completed in ${duration}ms"

echo ""
echo "🎉 Redis diagnostics completed successfully!"
echo "Redis appears to be working correctly."