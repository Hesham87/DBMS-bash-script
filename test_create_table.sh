#!/bin/bash

# Path to the DBMS script
DBMS_SCRIPT="./DBMS.sh"

# Function to execute and test a command
run_test() {
    local command="$1"
    local description="$2"
    echo "Testing: $description"
    echo "Command: $command"
    temp_file=$(mktemp)
    echo "use hello;" > "$temp_file"
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

# Test cases

# Valid cases
run_test "create table employees {ID primary_key int{100}, name char{50}, birthdate date};" "Valid table creation with all data types"
run_test "create table test {ID primary_key int{1}, name char{999}};" "Valid table with minimum and maximum limits"
run_test "create table test2(ID int{100}) ;" "valid with white space between closing braclet and ;"

# Invalid cases
# 1. Data type range violations
run_test "create table invalid1 {ID primary_key int{0}, name char{50}};" "Invalid int below minimum range"
run_test "create table invalid2 {ID int{100000000}, name char{50}};" "Invalid int above maximum range"
run_test "create table invalid3 {ID int{100}, name char{1000}};" "Invalid char above maximum range"

# 2. Missing primary key
run_test "create table no_primary_key {ID int{100}, name char{50}};" "Table without a primary key"

# 3. Invalid data type
run_test "create table invalid_type1 {ID primary_key varchar{100}, name char{50}};" "Invalid data type (varchar not supported)"
run_test "create table invalid_type2 {ID primary_key int{100}, , name char{50}};" "Missing atribute extra commas."


# 4. Incorrect syntax
run_test "create table syntax_error1 ID int{100}, name char{50};" "Missing braces"
run_test "create table syntax_error2 {ID primary_key int{100} name char{50}};" "Missing comma between attributes"
run_test "create table syntax_error3 {ID primary_key int{100} char{50}};" "Dublicate data type"
run_test "create table syntax_error4 {ID primary_key int{100}, ID char{50}};" "Dublicate attribute name"
run_test "create table syntax_error5 {ID primary_key int{100}, name char{50};" "Missing closing brace"

# 5. Duplicate primary keys
run_test "create table duplicate_keys {ID primary_key int{100}, code primary_key char{10}};" "Table with duplicate primary keys"

# 6. No attributes
run_test "create table empty_table {};" "Table with no attributes"
run_test "create table empty_table2 { , ,};" "Table with no attributes and only commas"
run_test "create table empty_table3 {,};" "Table with no attributes and a single comma"

# 7. Unsupported characters
run_test "create table special_characters {ID primary_key int{100}, name char{50#}};" "Unsupported special characters in definition"

# 8. Repeated table name
run_test "create table employees {ID primary_key int{100}, name char{50}, birthdate date};" "Duplicate table name (employees)"

# 9. Invalid table name
run_test "create table 123invalid {ID primary_key int{100}, name char{50}};" "Invalid table name (starting with a number)"
run_test "create table INFORMATION_SCHEMA {ID primary_key int{100}, name char{50}};" "Invalid table name (table name is a reserved keyword)"
run_test "create table sys {ID primary_key int{100}, name char{50}};" "Invalid table name (table name is a reserved keyword)"
run_test "create table invalid-name {ID primary_key int{100}, name char{50}};" "Invalid table name (contains special characters)"

# 9. Invalid attribute name
run_test "create table invalid20 {123invalid primary_key int{100}, name char{50}};" "Invalid column name (starting with a number)"
run_test "create table invalid21 {ID primary_key int{100}, INFORMATION_SCHEMA char{50}};" "Invalid column name (column name is a reserved keyword)"
run_test "create table invalid22 {ID primary_key int{100}, sys char{50}};" "Invalid column name (column name is a reserved keyword)"
run_test "create table invalid23 {I@D primary_key int{100}, name char{50}};" "Invalid column name (contains special characters)"

# 10. Invalid characters after the last `}`
run_test "create table invalid_chars {ID primary_key int{100}} extra;" "Characters after closing brace"

# Print test summary
echo "All tests executed. Check the output above."
