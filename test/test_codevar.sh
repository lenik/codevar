#!/bin/bash
# Test suite for codevar

set +e

CODEVAR="../codevar"
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

PASSED=0
FAILED=0

# Setup: ensure base91 is in PATH
export PATH="$(cd .. && pwd):$PATH"

test_basic() {
    local secret=$1
    local text=$2
    local test_name=$3
    
    echo -n "Testing $test_name: "
    
    local result=$($CODEVAR -s "$secret" "$text" 2>&1)
    
    if [ -n "$result" ] && [ ${#result} -gt 0 ]; then
        echo "PASS"
        ((PASSED++))
    else
        echo "FAIL (empty result)"
        ((FAILED++))
    fi
}

test_length() {
    local secret=$1
    local text=$2
    local length=$3
    local test_name=$4
    
    echo -n "Testing $test_name: "
    
    local result=$($CODEVAR -s "$secret" -l $length "$text" 2>&1)
    
    if [ ${#result} -eq $length ]; then
        echo "PASS"
        ((PASSED++))
    else
        echo "FAIL (expected length $length, got ${#result})"
        ((FAILED++))
    fi
}

test_year_protection() {
    local secret=$1
    local text=$2
    local test_name=$3
    
    echo -n "Testing $test_name: "
    
    local result1=$($CODEVAR -s "$secret" "$text" 2>&1)
    local result2=$($CODEVAR -s "$secret" -y "$text" 2>&1)
    
    if [ "$result1" != "$result2" ]; then
        echo "PASS"
        ((PASSED++))
    else
        echo "FAIL (year protection should produce different output)"
        ((FAILED++))
    fi
}

test_encoding() {
    local secret=$1
    local text=$2
    local encoding_flag=$3
    local encoding_name=$4
    local test_name=$5
    
    echo -n "Testing $test_name: "
    
    # Check if base91 program is available for non-base64 encodings
    if [ "$encoding_flag" != "-b" ] && [ "$encoding_flag" != "" ]; then
        if ! command -v base91 >/dev/null 2>&1 && [ ! -f "../base91" ]; then
            echo "SKIP (base91 not available)"
            return
        fi
    fi
    
    local result=$($CODEVAR -s "$secret" $encoding_flag "$text" 2>&1)
    
    if [ -n "$result" ] && [ ${#result} -gt 0 ]; then
        echo "PASS"
        ((PASSED++))
    else
        echo "FAIL (empty result for $encoding_name)"
        ((FAILED++))
    fi
}

test_config_file() {
    local test_name=$1
    
    echo -n "Testing $test_name: "
    
    # Create config file
    mkdir -p $TEST_DIR/.config/codevar
    cat > $TEST_DIR/.config/codevar/config.ini <<EOF
secret=configsecret
length=10
digest=sha256
encode=base64
EOF
    
    # Set HOME to test directory
    export HOME=$TEST_DIR
    
    local result=$($CODEVAR "test" 2>&1)
    
    if [ -n "$result" ] && [ ${#result} -eq 10 ]; then
        echo "PASS"
        ((PASSED++))
    else
        echo "FAIL (config file not loaded correctly)"
        ((FAILED++))
    fi
    
    unset HOME
}

test_consistency() {
    local secret=$1
    local text=$2
    local test_name=$3
    
    echo -n "Testing $test_name: "
    
    local result1=$($CODEVAR -s "$secret" "$text" 2>&1)
    local result2=$($CODEVAR -s "$secret" "$text" 2>&1)
    
    if [ "$result1" = "$result2" ]; then
        echo "PASS"
        ((PASSED++))
    else
        echo "FAIL (results should be consistent)"
        ((FAILED++))
    fi
}

# Check if codevar exists
if [ ! -f "$CODEVAR" ]; then
    echo "Error: $CODEVAR not found."
    exit 1
fi

echo "Running codevar tests..."
echo "======================"

# Basic functionality tests
test_basic "mysecret" "hello world" "basic encoding"
test_basic "test123" "simple" "simple encoding"
test_basic "" "no secret" "encoding without secret"

# Length tests
test_length "mysecret" "hello" 8 "default length"
test_length "mysecret" "hello" 12 "custom length 12"
test_length "mysecret" "hello" 16 "custom length 16"
test_length "mysecret" "hello" 4 "short length"

# Year protection tests
test_year_protection "mysecret" "hello" "year protection"

# Encoding tests
test_encoding "mysecret" "hello" "-b" "base64" "base64 encoding"
test_encoding "mysecret" "hello" "-8" "base85" "base85 encoding"
test_encoding "mysecret" "hello" "-9" "base91" "base91 encoding"
test_encoding "mysecret" "hello" "-B" "base122" "base122 encoding"

# Consistency tests
test_consistency "mysecret" "hello world" "output consistency"

# Config file test (if base91 is available)
if command -v base91 >/dev/null 2>&1 || [ -f "../base91" ]; then
    test_config_file "config file loading"
fi

echo "======================"
echo "Tests passed: $PASSED"
echo "Tests failed: $FAILED"

if [ $FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi

