#!/bin/bash

DBMS_SCRIPT="./DBMS.sh"
run_test() {
    local command="$1"
    local description="$2"
    echo "Testing: $description"
    echo "Command: $command"
    temp_file=$(mktemp)
    echo "use students;" > "$temp_file"
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
# run_test "INSERT INTO student (id, name, age) VALUES (1, 'Ahmed', '98/');" "Valid Insert (All Valid Data)"
# run_test "INSERT INTO student (id, name, age) VALUES (2, 'Ahmed', 20);"   "Insert with Invalid Data Type (Non-Integer for int column)"
# run_test "INSERT INTO student (id, name, age) VALUES (2, 'Sara', '2022');" "Insert with Invalid Date Format"
# run_test "INSERT INTO student (id, name, age) VALUES (3, 'ThisNameIsWayTooLongForTheColumn', 25);" "Insert with Value Exceeding Size Limit"
# run_test "INSERT INTO student (id, name, age) VALUES (4, NULL, 30);" "Insert with NULL Value in NOT NULL Column"

# run_test "INSERT INTO student (id, name, age) VALUES (5, 'John', 22);" "Insert with Primary Key Violation"

# run_test "INSERT INTO student (id, name, age) VALUES (6, 'John');" "Insert with Missing Value for Column"
# run_test "INSERT INTO student (id, name, age) VALUES (8, 'Tom', '-15');" "Insert with Valid Date (YYYY-MM-DD format)"
# run_test "INSERT INTO student (id, name, age) VALUES (7, 'David', 20);" "Insert with Unique Constraint Violation"
# run_test "INSERT INTO student (id, name, age) VALUES ( 8 , ' Sarah ' , 25 );" "Insert with Extra Spaces in Values"

# run_test "INSERT INTO student (id, name, age) VALUES (9, 'Mona', '110');"  "Insert with Valid Data (Date Handling and Formatting)"
# # Test Case 1: Valid Insert (All Valid Data)
# run_test "INSERT INTO student (id, name, age) VALUES (10, 'Ahmed', 20);" "Valid Insert (All Valid Data)"

# # Test Case 2: Invalid Data Type (Non-Integer for 'age' column)
# run_test "INSERT INTO student (id, name, age) VALUES (11, 'Ahmed', '5h');" "Invalid Data Type for 'age' column"

# # Test Case 3: Invalid Date Format (Invalid Date Format 'YYYY-MM-DD')

# # Test Case 6: Primary Key Violation (Inserting a Duplicate Primary Key)
# run_test "INSERT INTO student (id, name, age) VALUES (15, 'John', 22);" "Primary Key Constraint Violation for 'id' column"

# # Test Case 7: Missing Value for a Required Column
# run_test "INSERT INTO student (id, name, age) VALUES (16, 'John');" "Missing Value for Required Column 'age'"

# # Test Case 8: Insert Multiple Valid Records
# run_test "INSERT INTO student (id, name, age) VALUES (17, 'Alice', 22);" "Valid Insert of Record 1"
# run_test "INSERT INTO student (id, name, age) VALUES (18, 'Bob', 23);" "Valid Insert of Record 2"

# # Test Case 9: Valid Date Insert (`birth_date` with YYYY-MM-DD format)

# # Test Case 10: Unique Constraint Violation (Inserting Duplicate Value in `name`)
# run_test "INSERT INTO student (id, name, age) VALUES (20, 'David', 20);" "Unique Constraint Violation for 'name' column"
# # Test Case 11: Insert with Extra Spaces Around Values
# run_test "INSERT INTO student (id, name, age) VALUES ( 21 , ' Sarah ' , 25 );" "Handling Extra Spaces in Values"


# run_test "INSERT INTO student (id, name, age) VALUES (23, 'Ahmed', 25) ; extra; " "(Extra Characters After Semicolon):"
# run_test "INSERT INTO student (id, name, age) VALUES (24, 'Ahmed', 25)" " (No Semicolon):"

# run_test "insert into student (id, name, age) values (25, 'Ahmed', 25);" "(Case Insensitivity)"
# run_test "insert into student  (id, name, age) values (26, 'Ahmed', 25); " "wrong format "

# run_test "insert into student  (id asdf) values (26 asdf); " "added asdf "
# run_test "insert into student  (id ) values (27 ); " "remove asdf "
# run_test "insert into student  (id ) value ("26asdf"); " "added asdf "

run_test "INSERT INTO student (id, name, age) VALUES (1, 'John', 22);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (15, 'John', 22);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (1, 'Ahmed', 20);" "Primary Key Constraint Violation for 'id' column"
run_test "INSERT INTO student (id, name, age) VALUES (3, 'Sara', 25);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (10, 'Ali', 'twenty');" "Error: 'age' column must be an integer"
run_test "INSERT INTO student (id, name, age) VALUES (1, 'Ahmed', 20);" "Primary Key Constraint Violation for 'id' column"
run_test "INSERT INTO student (id, name) VALUES (5, 'Mona');" "Error: Missing value for 'age' column"
run_test "INSERT INTO student (id, name, age) VALUES (100, 'Mohamed', 30);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (25, 'Tariq', 22);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES ('5', 'Yasmin', 20);" "Error: 'id' must be an integer"
run_test "INSERT INTO student (id, name, age) VALUES (5, 'John Doe', 'thirty');" "Error: 'age' column must be an integer"
run_test "INSERT INTO student (id, name, age) VALUES (12, 'Samir', 30);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (1, 'Alice', 22);" "Primary Key Constraint Violation for 'id' column"
run_test "INSERT INTO student (id, name, age) VALUES (7, 'James', 23);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (5, 'Zara', 'twenty-five');" "Error: 'age' column must be an integer"
run_test "INSERT INTO student (id, name, age) VALUES (30, 'Peter', 25);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (1001, 'Khaled', 35);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (50, 'David', 28);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (7, 'Ali', 22);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (1, 'Mohamed', 'Twenty');" "Error: 'age' column must be an integer"
run_test "INSERT INTO student (id, name, age) VALUES (1, 'Ahmed', 'twenty-two');" "Error: 'age' column must be an integer"
run_test "INSERT INTO student (id, name, age) VALUES (10, 'Noor', 23);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (100, 'John', 25);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (5, 'Sam', 26);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (9, 'Marwa', 30);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (11, 'Rania', 27);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (11, 'Ali', 28);" "Primary Key Constraint Violation for 'id' column"
run_test "INSERT INTO student (id, name, age) VALUES (12, 'Ahmed', 25);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (13, 'Mohamed', 29);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (30, 'Maya', 32);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (14, 'Rana', 'age');" "Error: 'age' column must be an integer"
run_test "INSERT INTO student (id, name, age) VALUES (14, 'Sami', 28);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (20, 'Laila', 35);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES ('A', 'Tarek', 29);" "Error: 'id' must be an integer"
run_test "INSERT INTO student (id, name, age) VALUES (16, 'Alya', 30);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (18, 'Mina', 22);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (19, 'Osman', 'Twenty-one');" "Error: 'age' column must be an integer"
run_test "INSERT INTO student (id, name, age) VALUES (20, 'Iman', 33);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (22, 'Yasmin', 32);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (50, 'Omar', 'Thirty');" "Error: 'age' column must be an integer"
run_test "INSERT INTO student (id, name, age) VALUES (21, 'Nour', 27);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (35, 'Rana', 'Invalid Age');" "Error: 'age' column must be an integer"
run_test "INSERT INTO student (id, name, age) VALUES (50, 'Khaled', 40);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (40, 'Mariam', 30);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (41, 'Omar', 28);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (42, 'Zainab', 35);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (43, 'Amir', 30);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (44, 'Samiha', 32);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (45, 'Salma', 'thirty-three');" "Error: 'age' column must be an integer"
run_test "INSERT INTO student (id, name, age) VALUES (46, 'Ibrahim', 26);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (47, 'Maha', 28);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (48, 'Rashed', 30);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (55, 'Fahad', 'invalid age');" "Error: 'age' column must be an integer"
run_test "INSERT INTO student (id, name, age) VALUES (51, 'Said', 36);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (52, 'Sarah', 29);" "Valid Insert"
run_test "INSERT INTO student (id, name, age) VALUES (52, 'Sarah', 29)dsfs;" "dsfs Inserted  after"

run_test "INSERT INTO student (id, name, age VALUES (52, 'Sarah', 29);" "bracket test"
run_test "INSERT INTO student (id, name, age) VALUES (52, 'Sarah', 29;" "bracket test2"