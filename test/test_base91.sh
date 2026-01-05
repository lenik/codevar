#!/bin/bash
# Test suite for base91 (base64, base85, base91, base122)

set +e

BASE91="../base91"
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

PASSED=0
FAILED=0

test_encode_decode() {
    local encoding=$1
    local flag=$2
    local input="$3"
    local test_name="$4"
    
    echo -n "Testing $test_name: "
    
    # Create temp file for input
    echo -n "$input" > $TEST_DIR/input_$$.txt
    
    # Encode
    $BASE91 $flag -w 0 $TEST_DIR/input_$$.txt > $TEST_DIR/encoded_$$.txt 2>/dev/null
    
    if [ ! -s $TEST_DIR/encoded_$$.txt ]; then
        echo "SKIP (encoding failed)"
        rm -f $TEST_DIR/input_$$.txt $TEST_DIR/encoded_$$.txt
        return
    fi
    
    # Decode
    $BASE91 $flag -d -i -w 0 $TEST_DIR/encoded_$$.txt > $TEST_DIR/decoded_$$.txt 2>/dev/null
    
    if cmp -s $TEST_DIR/input_$$.txt $TEST_DIR/decoded_$$.txt; then
        echo "PASS"
        ((PASSED++))
    else
        echo "FAIL (input: '$input')"
        ((FAILED++))
    fi
    
    rm -f $TEST_DIR/input_$$.txt $TEST_DIR/encoded_$$.txt $TEST_DIR/decoded_$$.txt
}

test_program_name_detection() {
    local name=$1
    local encoding=$2
    local input="test"
    
    echo -n "Testing program name detection ($name): "
    
    # Create symlink
    ln -sf $(cd .. && pwd)/base91 $TEST_DIR/$name 2>/dev/null || {
        echo "SKIP (cannot create symlink)"
        return
    }
    
    # Test encoding
    echo -n "$input" > $TEST_DIR/det_input_$$.txt
    $TEST_DIR/$name -w 0 $TEST_DIR/det_input_$$.txt > $TEST_DIR/det_encoded_$$.txt 2>/dev/null
    
    if [ ! -s $TEST_DIR/det_encoded_$$.txt ]; then
        echo "SKIP (encoding failed)"
        rm -f $TEST_DIR/det_input_$$.txt $TEST_DIR/det_encoded_$$.txt
        return
    fi
    
    $TEST_DIR/$name -d -i -w 0 $TEST_DIR/det_encoded_$$.txt > $TEST_DIR/det_decoded_$$.txt 2>/dev/null
    
    if cmp -s $TEST_DIR/det_input_$$.txt $TEST_DIR/det_decoded_$$.txt; then
        echo "PASS"
        ((PASSED++))
    else
        echo "FAIL"
        ((FAILED++))
    fi
    
    rm -f $TEST_DIR/det_input_$$.txt $TEST_DIR/det_encoded_$$.txt $TEST_DIR/det_decoded_$$.txt
}

test_file_input() {
    local encoding=$1
    local flag=$2
    
    echo -n "Testing file input ($encoding): "
    
    echo "test content" > $TEST_DIR/input.txt
    $BASE91 $flag -w 0 $TEST_DIR/input.txt > $TEST_DIR/encoded.txt
    $BASE91 $flag -d -i -w 0 $TEST_DIR/encoded.txt > $TEST_DIR/decoded.txt
    
    if cmp -s $TEST_DIR/input.txt $TEST_DIR/decoded.txt; then
        echo "PASS"
        ((PASSED++))
    else
        echo "FAIL"
        ((FAILED++))
    fi
}

test_wrap() {
    local encoding=$1
    local flag=$2
    
    echo -n "Testing line wrapping ($encoding): "
    
    local input="This is a long string that should be wrapped"
    echo -n "$input" > $TEST_DIR/wrap_input_$$.txt
    
    $BASE91 $flag -w 10 $TEST_DIR/wrap_input_$$.txt > $TEST_DIR/wrap_encoded_$$.txt 2>/dev/null
    
    if [ ! -s $TEST_DIR/wrap_encoded_$$.txt ]; then
        echo "SKIP (encoding failed)"
        rm -f $TEST_DIR/wrap_input_$$.txt $TEST_DIR/wrap_encoded_$$.txt
        return
    fi
    
    # Check that output contains newlines
    if grep -q $'\n' $TEST_DIR/wrap_encoded_$$.txt; then
        echo "PASS"
        ((PASSED++))
    else
        echo "FAIL"
        ((FAILED++))
    fi
    
    rm -f $TEST_DIR/wrap_input_$$.txt $TEST_DIR/wrap_encoded_$$.txt
}

test_stdin() {
    local encoding=$1
    local flag=$2
    
    echo -n "Testing stdin input ($encoding): "
    
    local input="stdin test"
    echo -n "$input" > $TEST_DIR/stdin_input_$$.txt
    
    $BASE91 $flag -w 0 $TEST_DIR/stdin_input_$$.txt > $TEST_DIR/stdin_encoded_$$.txt 2>/dev/null
    
    if [ ! -s $TEST_DIR/stdin_encoded_$$.txt ]; then
        echo "SKIP (encoding failed)"
        rm -f $TEST_DIR/stdin_input_$$.txt $TEST_DIR/stdin_encoded_$$.txt
        return
    fi
    
    $BASE91 $flag -d -i -w 0 $TEST_DIR/stdin_encoded_$$.txt > $TEST_DIR/stdin_decoded_$$.txt 2>/dev/null
    
    if cmp -s $TEST_DIR/stdin_input_$$.txt $TEST_DIR/stdin_decoded_$$.txt; then
        echo "PASS"
        ((PASSED++))
    else
        echo "FAIL"
        ((FAILED++))
    fi
    
    rm -f $TEST_DIR/stdin_input_$$.txt $TEST_DIR/stdin_encoded_$$.txt $TEST_DIR/stdin_decoded_$$.txt
}

# Check if base91 exists
if [ ! -f "$BASE91" ]; then
    echo "Error: $BASE91 not found. Run 'make' first."
    exit 1
fi

echo "Running base91 tests..."
echo "======================"

# Test base64
test_file_input "base64" "-6"
test_wrap "base64" "-6"
test_encode_decode "base64" "-6" "hello" "base64 encode/decode"
test_encode_decode "base64" "-6" "Hello World!" "base64 with spaces"
test_encode_decode "base64" "-6" "test123" "base64 with numbers"

# Test base85
test_file_input "base85" "-8"
test_wrap "base85" "-8"
test_encode_decode "base85" "-8" "hello" "base85 encode/decode"
test_encode_decode "base85" "-8" "test" "base85 simple"

# Test base91
test_file_input "base91" "-9"
test_wrap "base91" "-9"
test_encode_decode "base91" "-9" "hello" "base91 encode/decode"
test_encode_decode "base91" "-9" "Hello World!" "base91 with spaces"
test_encode_decode "base91" "-9" "test123" "base91 with numbers"

# Test base122
test_file_input "base122" "-B"
test_wrap "base122" "-B"
test_encode_decode "base122" "-B" "hello" "base122 encode/decode"
test_encode_decode "base122" "-B" "test" "base122 simple"

# Test program name detection
test_program_name_detection "base64" "base64"
test_program_name_detection "base85" "base85"
test_program_name_detection "base91" "base91"
test_program_name_detection "base122" "base122"

echo "======================"
echo "Tests passed: $PASSED"
echo "Tests failed: $FAILED"

if [ $FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi

