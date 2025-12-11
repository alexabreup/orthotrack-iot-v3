#!/bin/bash

# Script to run WebSocket property-based tests
# Requires Go 1.21+ and Redis running on localhost:6379

echo "Running WebSocket Property-Based Tests..."
echo "=========================================="
echo ""

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "Error: Go is not installed or not in PATH"
    exit 1
fi

# Check if Redis is running
if ! nc -z localhost 6379 2>/dev/null; then
    echo "Warning: Redis does not appear to be running on localhost:6379"
    echo "Some tests may be skipped"
    echo ""
fi

# Run the property-based tests
echo "Running Property 1: Device status event propagation..."
go test -v -run TestProperty_DeviceStatusEventPropagation ./internal/services/

echo ""
echo "Running additional property tests..."
go test -v -run TestProperty_ ./internal/services/

echo ""
echo "=========================================="
echo "Tests complete!"
