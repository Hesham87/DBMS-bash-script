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


run_test "SELECT name FROM users;" "Single column selection"

run_test "SELECT name, age, registration_date FROM users;" " Multiple columns selection"

run_test "SELECT name FROM users WHERE age > 30;" " Selection with WHERE condition"

run_test "SELECT name FROM users WHERE age > 20 AND registration_date = \"2023-05-15\";" " WHERE with logical operators"

run_test "SELECT name, age + 5 FROM users WHERE age < 40;" " WHERE with arithmetic operations"

run_test "SELECT * FROM users;" " Selection with all columns"

run_test "name, age FROM users;" " Missing SELECT keyword"

run_test "SELECT name, age users;" " Missing FROM keyword"

run_test "SELECT name, age FROM;" " Missing table name"

run_test "SELECT FROM users;" " Missing columns"

run_test "SELECT name FROM users" " Missing semicolon (if mandatory)"

run_test "SELECT non_existent_column FROM users;" " Non-existent column"

run_test "SELECT name FROM non_existent_table;" " Non-existent table"

run_test "SELECT name FROM users WHERE age = \"text\";" " Invalid data type comparison"

run_test "SELECT name, age / 0 FROM users;" " Division by zero"

run_test "SELECT name FROM users WHERE registration_date = \"invalid-date\";" " Invalid date format"

run_test "SELECT name FROM users WHERE name = \"Alice\";" " String operations"
run_test "SELECT name FROM users WHERE name LIKE \"A%\";" " String operations"

run_test "SELECT name FROM users WHERE age > 25;" " Integer operations"
run_test "SELECT name FROM users WHERE age + 5 < 50;" " Integer operations"

run_test "SELECT name FROM users WHERE registration_date = \"2024-11-01\";" " Date operations"
run_test "SELECT name FROM users WHERE registration_date > \"2020-01-01\";" " Date operations"

run_test "SELECT * FROM empty_table;" " Empty table"

run_test "SELECT name FROM users WHERE age IS NULL;" " Column with NULL values"

run_test "SELECT name FROM users WHERE name = \"O\'Connor\";" " Special characters in string"

run_test "SELECT name FROM users WHERE (age > 20 AND age < 30) OR registration_date = \"2024-01-01\";" " Mixed conditions with logical operators"

run_test "SELECT name FROM large_table;" " Very large dataset (Performance Test)"

run_test "SELECT \"user name\" FROM users;" " Non-standard column names (if allowed)"

run_test "SELECT name FROM users WHERE age > 20 AND (registration_date = \"2023-01-01\" OR age < 50);" " Multiple logical operators"

run_test "SELECT name FROM users WHERE age + 10 = 40;" " Arithmetic in WHERE"

run_test "SELECT name FROM users WHERE registration_date < \"2023-12-31\" AND age >= 18;" " Multiple conditions across types"

run_test "SELECT name FROM users WHERE non_existent_column > 10;" " Invalid column in WHERE"

run_test "SELECT name FROM users WHERE age + \"invalid\";" " Invalid arithmetic operation"

run_test "SELECT name FROM users WHERE age AND registration_date;" " Invalid logical operation"

run_test "select name from users;" " Commands in lowercase"

run_test "SeLeCt name, age FrOm users;" " Mixed case"

run_test "SELECT Name FROM Users;" " Table and column case sensitivity"

run_test "SELECT very_long_column_name_with_many_characters FROM very_long_table_name;" " Very long table or column names"

run_test "SELECT * FROM huge_table;" " Thousands of rows"

run_test "SELECT * FROM users WHERE (age > 20 AND age < 50) OR (registration_date > \"2022-01-01\");" " Complex WHERE conditions"

run_test "select age + \"123\" from users where age>1;" "age>1"