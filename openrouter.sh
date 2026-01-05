#!/bin/bash

: ${RCSID:=$Id: openrouter 1.0.0 2026-01-06 - $}
: ${PROGRAM_TITLE:="OpenRouter API utility"}
: ${PROGRAM_SYNTAX:="[OPTIONS]"}

# OpenRouter config
OPENROUTER_API_KEY="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"
OPENROUTER_BASE_URL="https://openrouter.ai/api/v1"

# Config file
CONFIG_DIR="$HOME/.config/openrouter"
CONFIG_FILE="$CONFIG_DIR/config.ini"

# Load config if exists
if [ -f "$CONFIG_FILE" ]; then
    while IFS='=' read -r key value; do
        case "$key" in
            api_key) OPENROUTER_API_KEY="$value" ;;
        esac
    done < "$CONFIG_FILE"
fi

LOGLEVEL=0

. shlib-import cliboot
option -c --credit             "Show OpenRouter credit info"
option -u --usage              "Show OpenRouter usage info"
option -k --api-key =KEY       "OpenRouter API key"
option -q --quiet
option -v --verbose
option -h --help
option    --version

function setopt() {
    case "$1" in
        -c|--credit)
            SHOW_CREDIT=1;;
        -u|--usage)
            SHOW_USAGE=1;;
        -k|--api-key)
            OPENROUTER_API_KEY="$2";;
        -h|--help)
            help $1; exit;;
        -q|--quiet)
            LOGLEVEL=$((LOGLEVEL - 1));;
        -v|--verbose)
            LOGLEVEL=$((LOGLEVEL + 1));;
        --version)
            show_version; exit;;
        *)
            quit "invalid option: $1";;
    esac
}

function openrouter_api_call() {
    local endpoint="$1"
    local url="${OPENROUTER_BASE_URL}${endpoint}"

    if [ -z "$OPENROUTER_API_KEY" ]; then
        echo "Error: OpenRouter API key not set. Please use -k/--api-key option or add 'api_key=YOUR_KEY' to $CONFIG_FILE"
        return 1
    fi

    curl -s -H "Authorization: Bearer $OPENROUTER_API_KEY" \
         -H "Content-Type: application/json" \
         "$url"
}

function show_credit_info() {
    echo "Fetching OpenRouter credit information..."

    local response=$(openrouter_api_call "/auth/key")
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Parse the JSON response for credit info
    echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'data' in data and data['data']:
        key_data = data['data'][0] if isinstance(data['data'], list) else data['data']
        credits = key_data.get('credits', 0)
        limit = key_data.get('limit', 0)
        usage = key_data.get('usage', 0)
        print(f'Credits: {credits}')
        print(f'Limit: {limit}')
        print(f'Usage: {usage}')
    else:
        print('No credit data available')
except Exception as e:
    print(f'Error parsing credit response: {e}')
    print('Raw response:', sys.stdin.read())
" 2>/dev/null || echo "Error: Could not parse API response"
}

function show_usage_info() {
    echo "Fetching OpenRouter usage information..."

    local response=$(openrouter_api_call "/auth/key")
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Parse the JSON response for usage info
    echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'data' in data and data['data']:
        key_data = data['data'][0] if isinstance(data['data'], list) else data['data']
        total_credits = key_data.get('total_credits', 0)
        usage = key_data.get('usage', 0)
        remaining = total_credits - usage if total_credits > 0 else 0
        print(f'Total Credits: {total_credits}')
        print(f'Used: {usage}')
        print(f'Remaining: {remaining}')
    else:
        print('No usage data available')
except Exception as e:
    print(f'Error parsing usage response: {e}')
    print('Raw response:', sys.stdin.read())
" 2>/dev/null || echo "Error: Could not parse API response"
}

function main() {
    if [ "$SHOW_CREDIT" = 1 ]; then
        show_credit_info
        return $?
    fi

    if [ "$SHOW_USAGE" = 1 ]; then
        show_usage_info
        return $?
    fi

    echo "No action specified. Use -c/--credit or -u/--usage"
    echo "Usage: $0 [OPTIONS]"
    return 1
}

boot "$@"
