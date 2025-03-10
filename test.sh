#!/bin/bash

# Load the API Token from .env file
API_TOKEN=$(grep "OLLAMA_BEARER_TOKEN" .env | cut -d '=' -f2)

# API Base URL
API_URL="http://localhost:5051"

# Colors and formatting
BOLD="\033[1m"
RESET="\033[0m"
BLUE="\033[34m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"

# Function to print test headers
print_test() {
    echo -e "\n${BOLD}┌──────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}│ ${BLUE}TEST: $1${RESET}${BOLD} │${RESET}"
    echo -e "${BOLD}└──────────────────────────────────────────┘${RESET}"
}

# Function to execute and print the command
run_test() {
    echo -e "${YELLOW}➜ COMMAND:${RESET}"
    echo -e "${GREEN}$1${RESET}\n"
    echo -e "${CYAN}▶ RESPONSE:${RESET}"
    
    # Capture and format JSON output
    OUTPUT=$(eval "$1")
    if echo "$OUTPUT" | jq -e . >/dev/null 2>&1; then
        echo "$OUTPUT" | jq '.'
    else
        echo "$OUTPUT"
    fi
    
    echo -e "${BOLD}──────────────────────────────────────────${RESET}"
}

# Print test suite header
echo -e "\n${BOLD}╔════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║        OLLAMA OPENAI API TEST SUITE         ║${RESET}"
echo -e "${BOLD}╚════════════════════════════════════════════╝${RESET}"

# 1️⃣ Check API Health
print_test "API Health Check"
run_test "curl -s -X GET \"$API_URL/\""

# 2️⃣ Test API Token Retrieval
print_test "API Token Validation"
if [ -z "$API_TOKEN" ]; then
    echo -e "${RED}✖ API Token not found in .env${RESET}"
    exit 1
else
    echo -e "${GREEN}✔ API Token successfully loaded${RESET}"
fi

# 3️⃣ Chat Completion with Valid Token
print_test "Chat Completion (Valid Token)"
run_test "curl -s -X POST \"$API_URL/v1/chat/completions\" \
     -H \"Content-Type: application/json\" \
     -H \"Authorization: Bearer $API_TOKEN\" \
     -d '{
           \"model\": \"mistral\",
           \"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}]
         }'"

# 4️⃣ Refresh Model Cache
print_test "Model Cache Update"
run_test "curl -s -X GET \"$API_URL/v1/models/update\" \
     -H \"Authorization: Bearer $API_TOKEN\""

# 5️⃣ Chat Completion with Invalid Token
print_test "Authentication Validation"
run_test "curl -s -X POST \"$API_URL/v1/chat/completions\" \
     -H \"Content-Type: application/json\" \
     -H \"Authorization: Bearer wrong-token\" \
     -d '{
           \"model\": \"mistral\",
           \"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}]
         }'"

# 6️⃣ Request a Non-Existent Model
print_test "Non-Existent Model Handling"
run_test "curl -s -X POST \"$API_URL/v1/chat/completions\" \
     -H \"Content-Type: application/json\" \
     -H \"Authorization: Bearer $API_TOKEN\" \
     -d '{
           \"model\": \"nonexistent-model\",
           \"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}]
         }'"

# Print test suite footer
echo -e "\n${BOLD}╔════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║             TEST SUITE COMPLETED            ║${RESET}"
echo -e "${BOLD}╚════════════════════════════════════════════╝${RESET}\n"