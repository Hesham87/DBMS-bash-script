#!/bin/bash

# Test script for the `create database` command in DBMS.sh
DBMS_SCRIPT="./DBMS.sh" # Path to the script being tested

# Array of test cases
test_cases=(
    # Valid cases
    "create database my_database;"                         # Valid simple name
    "create database MyDatabase;"                          # Mixed case name
    "create database db_123;"                              # Name with numbers and underscore
    "create database my-db;"                               # Name with a hyphen
    "create database valid123_ABC;"                        # Valid alphanumeric with underscores

    # Invalid cases
    "create database 123db;"                               # Starts with a number
    "create database ;"                                    # Missing database name
    "create database;"                                     # Missing semicolon
    "create database my!database;"                        # Invalid character (!)
    "create database my database;"                        # Contains a space
    "create database db_name&;"                           # Invalid character (&)
    "create database;"                                     # No database name
    "create database db-name-;"                           # Invalid trailing hyphen

    # Reserved keywords (invalid)
    "create database select;"                              # Reserved keyword
    "create database insert;"                              # Reserved keyword
    "create database update;"                              # Reserved keyword
    "create database delete;"                              # Reserved keyword
    "create database information_schema;"                 # System database

    # Edge cases
    "create database"                                      # No semicolon or name
    "create database db123;"                               # Valid but test again for consistency
    "create database mydatabase;;"                        # Double semicolon
    "create database db_name_1 extra;"                    # Extra words after the command
    "create database my_database_123 "                    # Missing semicolon, trailing space
)

# Function to test a single case
test_case() {
    local command="$1"
    echo "Testing: $command"
    temp_file=$(mktemp)
    echo "$command" >> "$temp_file"

    output=$(bash "$DBMS_SCRIPT" < "$temp_file")
    rm "$temp_file"  # Clean up
    
    last_line=$(echo -e "$output" | tail -n 1)

    if [[ "$last_line" =~ ^syntax\ error\ missing\ semicolon. ]]; then
        output=$(echo -e "$output" | head -n -1)
    else
        output="$output"
    fi

    echo "Output: $output"
    echo "-------------------------------------"
}

# Loop through all test cases
for case in "${test_cases[@]}"; do
    test_case "$case"
done
