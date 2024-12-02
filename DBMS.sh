#!/bin/bash


# Function to create table the output inside the file is column_name:data_type:range:primary_key:not_null:unique
# It takes database path, table name, and the sql command as input.
# PLEASE NOTE THAT, it was the first time that I used awk function and I thought it could be used like this
# Then I found out that debugging it was a nightmare and I never thought it will grow this big. 
# CREATED BY: HESHAM BASSIOUNY
createTB(){
    if [[ -e "$3/$1.txt" ]]; then
        echo "table already exists!"
        exit 1
    fi
    # > "./tables/.$1.txt"
    # > "./tables/$1.txt"
    > tempfile.txt
    echo "$2" | tr ',' '\n' | awk -v table_name="$1" -v table_path="$3" '
    function check_column_name(column_name) {
        # Declare variables as local to avoid global scope issues

        # Rule 1: Column name length should be between 1 and 64 characters
        if (length(column_name) < 1 || length(column_name) > 64) {
            print "Invalid: column name length should be between 1 and 64 characters."
            return 1
        }

        # Rule 2: column name should match the pattern [a-zA-Z][a-zA-Z0-9_-]+
        if (column_name !~ /^[a-zA-Z][a-zA-Z0-9_-]*$/) {
            print "Invalid: column name can only contain letters, numbers, underscores, and hyphens. And must begin with letters."
            return 1
        }
        
        reserved_keywords = "INFORMATION_SCHEMA PERFORMANCE_SCHEMA MYSQL SYS SHOW EXPLAIN SELECT INSERT UPDATE DELETE WHERE FROM JOIN ORDER GROUP CREATE DROP ALTER TABLE DATABASE INDEX KEY TRUNCATE DISTINCT"
        
        if (tolower(reserved_keywords) ~ column_name) {
            print "Attribute name: ", column_name, "is a reserved keywords."
            return 1
        }

        return 0  # Valid table name
    }

    BEGIN {
        FS = " "  # Set field separator to white space
        primary_key=0
        attribute_number=0
        attribute_names[0]=""
        exit_check=0
    }
    {
        primary_key_curr=0
        not_null=0
        unique=0
        data_type=0
        for (i = 1; i <= NF; i++) {
            # Only column name (one word)
            if (NF == 1){
                    print "you must define a data type"
                    exit_check=1
                    exit 1
            }
            # remove trailing white space ( *$/) and begining white space ( *)
            gsub(/^ *| *$/, "", $i)  # Trim whitespace from each field

            # check for primary_key, not_null, and unique constraints.
            if (i > 1) {
                if ($i == "primary_key") {

                    if (primary_key == 0){
                        primary_key=1
                        primary_key_curr=1
                    }else{
                        print "only one attribute can be primary key."
                        exit_check=1
                        exit 1
                    }
                }
                else if ($i == "not_null") {
                    if (not_null == 0){
                        not_null=1
                    }else{
                        print "not null stated twice."
                        exit_check=1
                        exit 1
                    }
                }
                else if ($i == "unique") {
                    if (unique == 0){
                        unique=1
                    }else{
                        print "unique stated twice."
                        exit_check=1
                        exit 1
                    }
                }
                # Matches "Char(number)" where number is between 1 and 999
                else if (system("echo " $i " | grep -qE \"^char\{[1-9][0-9]{0,2}\}$\"") == 0) {     # ^Char\{: Starts with Char{.
                                                                                                    # [1-9][0-9]{0,2}: Matches a number from 1 to 999 (e.g., 1, 50, 999).
                                                                                                    # \}$: Ends with a closing }.
                    if (data_type == 0){
                        data_type=1
                    }else{
                        print "you can only assign one data type to an attribute"
                        exit_check=1
                        exit 1
                    }

                    # print data type into temp file char is a four character word.
                    printf "%s", substr($i, 1, 4) >> ("tempfile.txt")
                    printf ":" >> ("tempfile.txt")
                    # get get the rest of the string {number}
                    printf "%s", substr($i, 5) >> ("tempfile.txt")
                    printf ":" >> ("tempfile.txt") 
                }                                                                                   # -E, --extended-regexp     PATTERNS are extended regular expressions Provides more advanced syntax compared to basic regular expressions (BRE).
                # Matches "Int(number)" where number is between 1 and 99999999                                                 # You dont need to escape certain metacharacters (e.g., +, |, ()).
                else if (system("echo " $i " | grep -qE \"^int\{[1-9][0-9]{0,7}\}$\"") == 0) {      # -G, --basic-regexp        PATTERNS are basic regular expressions (Requires escaping for metacharacters like +, |, and () to be treated as special regex constructs.)
                    if (data_type == 0){
                        data_type=1
                    }else{
                        print "you can only assign one data type to an attribute"
                        exit_check=1
                        exit 1
                    }
                    # print data type into temp file int is a three letter word.
                    printf "%s", substr($i, 1, 3) >> ("tempfile.txt")
                    printf ":" >> ("tempfile.txt")
                    printf "%s", substr($i, 4) >> ("tempfile.txt")
                    printf ":" >> ("tempfile.txt")                                                    # -P, --perl-regexp         PATTERNS are Perl regular expressions (supports advanced constructs like lookaheads, lookbehinds, and non-capturing groups.)
                }                                                                                                               # Examples:
                else if ($i == "date") {                                                                                        # echo "apple123orange" | grep -P "(?<=apple)\d+"  # Matches digits after "apple" (lookbehind)
                                                                                                                                # echo "1234" | grep -P "\d+"                     # Matches one or more digits (PCRE '\d')
                    if (data_type == 0){
                        data_type=1
                        printf $i >> ("tempfile.txt")
                        printf ":{0}:" >> ("tempfile.txt")
                    }else{
                        print "you can only assign one data type to an attribute"
                        exit_check=1
                        exit 1
                    } 
                }                                                                                   # -e, --regexp=PATTERNS     use PATTERNS for matching  (when combining multiple patterns in a single grep command.) 
                else {                                                                                                          # Examples:
                    print "Invalid input: Supported types are not_null, unique, Primary_key, Int{1-99999999}, Char{1-999}, Date"                  # echo "apple orange banana" | grep -e "apple" -e "banana"  # Matches "apple" or "banana"
                    exit_check=1
                    exit 1                                                                                                      # echo "fruit" | grep -e "fruit"                           # Matches "fruit"
                }                                                                                   # -q, --quiet, --silent     suppress all normal output
                if (i == NF && data_type == 0){
                    print "you must define a data type"
                    exit_check=1
                    exit 1
                }            
            }      
            else{
                
                attribute_names[attribute_number]=$i
                attribute_number+=1
                
                printf $i >> ("tempfile.txt")
                printf ":" >> ("tempfile.txt")
            }
        }
        if(primary_key_curr == 1){
            printf "1:1:1\n" >> ("tempfile.txt")
        }else{
            printf "0:" >> ("tempfile.txt")

            if(not_null == 1){
                printf "1:" >> ("tempfile.txt")
            }else{
                printf "0:" >> ("tempfile.txt")
            }

            if(unique == 1){
                printf "1\n" >> ("tempfile.txt")
            }else{
                printf "0\n" >> ("tempfile.txt")
            }
        }
    }
    END {
        if (exit_check == 1){
            exit 1
        }

        if (attribute_number == 0){
            print "error: no attributes assigned."
            exit 1
        }
        # check if the user entered an empty field (, ,)
        if (attribute_number < NR){
            print "error: unexpected \",\" "
            exit 1
        }

        # Call the check_column_name function for each column name
        for (i = 0; i < length(attribute_names); i++) {
            exit_check=check_column_name(attribute_names[i])
            if (exit_check == 1){
                exit 1
            }
            for (j = i + 1; j < length(attribute_names); j++) {
                # Compare the strings case-insensitively by converting both to lowercase
                if (tolower(attribute_names[i]) == tolower(attribute_names[j])) {
                    print "Error: found two attributes with the same name."
                    exit 1
                }
            }
        }
        if (exit_check == 0){
            system("touch " (table_path "/" table_name ".txt"))
            system("cat " ("tempfile.txt") " >> " (table_path "/." table_name ".txt"))
        }else{
            exit 1
        }
        if (primary_key == 0){
            print "Warrining: no primary key assigned."
        }
    }
    '
    rm tempfile.txt
}

# Function to check if a database name is a valid table name database name.
# CREATED BY HESHAM BASSIOUNY
check_database_name() {
    local database_name="$1"
    
    # Rule 1: Database name length should be between 1 and 64 characters
    if [[ ${#database_name} -lt 1 || ${#database_name} -gt 64 ]]; then
        echo "Invalid: Database name length should be between 1 and 64 characters."
        exit 1
    fi

    # Rule 2: Table name should match the pattern [a-zA-Z][a-zA-Z0-9_-]+ (start with a letter, then letters, numbers, underscores, or hyphens)
    if ! [[ "$database_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then    # +: This is a quantifier in regular expressions that means "one or more" of the preceding elements.
                                                                    # $: This is the end of string anchor in regular expressions. It means the pattern must match all the way to the end of the string.
        echo "Invalid: Database name can only contain letters, numbers, underscores. And must begin with letters."
        exit 1
    fi    

    # Rule 3: Check if the table name is a reserved MySQL keyword (list of common keywords)
    local reserved_keywords=("INFORMATION_SCHEMA" "PERFORMANCE_SCHEMA" "MYSQL" "SYS" "SHOW" "EXPLAIN" "SELECT" "INSERT" "UPDATE" "DELETE" "WHERE" "FROM" "JOIN" "ORDER" "GROUP" "CREATE" "DROP" "ALTER" "TABLE" "DATABASE" "INDEX" "KEY" "TRUNCATE" "DISTINCT")
    
    for keyword in "${reserved_keywords[@]}"; do
        if [[ "$database_name" == "$keyword" || "$database_name" == "${keyword,,}" ]]; then
            echo "Invalid: Database name cannot be a reserved keyword ($keyword)."
            exit 1
        fi
    done

    return 0
}

# Function to check if a name is a valid table name.
# No difference between it and the check_database_name function but I created them at the begging because I thought there was a difference.
# CREATED BY HESHAM BASSIOUNY.
check_table_name() {
    local table_name="$1"
    
    # Rule 1: Table name length should be between 1 and 64 characters
    if [[ ${#table_name} -lt 1 || ${#table_name} -gt 64 ]]; then
        echo "Invalid: Table name length should be between 1 and 64 characters."
        exit 1
    fi

    # Rule 2: Table name should match the pattern [a-zA-Z][a-zA-Z0-9_-]+ (start with a letter, then letters, numbers, underscores, or hyphens)
    if ! [[ "$table_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then      # +: This is a quantifier in regular expressions that means "one or more" of the preceding elements.
                                                                    # $: This is the end of string anchor in regular expressions. It means the pattern must match all the way to the end of the string.
        echo "Invalid: Table name can only contain letters, numbers, and underscores. And must begin with letters."
        exit 1
    fi    

    # Rule 3: Check if the table name is a reserved MySQL keyword (list of common keywords)
    local reserved_keywords=("INFORMATION_SCHEMA" "PERFORMANCE_SCHEMA" "MYSQL" "SYS" "SHOW" "EXPLAIN" "SELECT" "INSERT" "UPDATE" "DELETE" "WHERE" "FROM" "JOIN" "ORDER" "GROUP" "CREATE" "DROP" "ALTER" "TABLE" "DATABASE" "INDEX" "KEY" "TRUNCATE" "DISTINCT")
    
    for keyword in "${reserved_keywords[@]}"; do
        if [[ "$table_name" == "$keyword" || "$table_name" == "${keyword,,}" ]]; then
            echo "Invalid: Table name cannot be a reserved keyword ($keyword)."
            exit 1
        fi
    done

    return 0
}

# Function to check if braces are balanced, properly nested.
# and if there are extra characters after the last brace or semicolon
# returns the string between the first brace and last brace
# CREATED BY HESHAM BASSIOUNY.
braces_check() {
  local input="$1"  # Input string passed to the function
  local brace_count=0
  local first_brace_pos=-1
  local last_brace_pos=-1
  local last_semicolon_pos=-1

  # Loop through each character in the string
  for (( i=0; i<${#input}; i++ )); do
    char="${input:i:1}"

    # Check for opening brace '{'
    if [[ "$char" == "{" ]]; then
      ((brace_count++))
      # set first brace position
      if [[ $brace_count -eq 1 && $first_brace_pos -eq -1 ]]; then
        first_brace_pos=$i
      fi
    # Check for closing brace '}'
    elif [[ "$char" == "}" ]]; then
      ((brace_count--))

      # If brace count is negative, there's an unmatched closing brace
      if ((brace_count < 0)); then
        echo "Error: Unmatched closing brace at position $i"
        exit 1  # exit error status
      fi
      last_brace_pos=$i  # Track the last closing brace position
    # Check for semicolon ';'
    elif [[ "$char" == ";" ]]; then
      last_semicolon_pos=$i  # Track the last semicolon position
    fi
  done

  # If brace count is not zero, there's an unmatched opening brace
  if ((brace_count != 0)); then
    echo "Error: Unmatched opening brace."
    exit 1  # exit error status
  fi

  # Check if there are characters after the last closing brace
  if (( last_brace_pos != -1 )); then
    # Extract the substring after the last closing brace and ensure it only contains whitespace or is empty
    # echo "${input:last_brace_pos+1}"
    if ! [[ "${input:last_brace_pos+1}" =~ ^[[:space:]]*";" ]]; then  # [[:space:]]* matches zero or more whitespace characters (spaces, tabs, etc.). $ ensures there is nothing but whitespace after the semicolon.
        echo "Error: There are characters other than whitespace after the last closing brace. Or there is no semicolon."
        exit 1 # exit error status
    fi
  fi

  # Check if there are characters after the last semicolon
  if (( last_semicolon_pos != -1 )) && [[ "${input:last_semicolon_pos+1}" != "" ]]; then
    echo "Error: There are characters after the last semicolon."
    exit 1 # exit error status
  fi
  # {input:first_brace_pos+1:$((last_brace_pos-1))}
  echo "${input:first_brace_pos+1:$((last_brace_pos-first_brace_pos-1))}" # This extracts the substring from the character after the first brace to the one before the last closing brace.
  return 0  # Return success status
}

# Function that checkes if there is a database selected or not.
# CREATED BY HESHAM BASSIOUNY.
check_db_selected(){
    if [[ "$1" == "" ]]; then
        echo "Error: no database selected."
        exit 1
    fi
}

# Function that handles the use database command.
# Takes the sql_command as an input.
# CREATED BY HESHAM BASSIOUNY.
select_db(){
    local sql_command="$1"
    third_word=$(echo "$sql_command" | awk '{print $3}') # get fourth word

    if [[ "$third_word" != ";" ]]; then
        echo "excpected ';' found: $third_word"
        exit 1
    fi

    database_name=$(echo "$sql_command" | awk '{print $2}') # get second word
    database_name=$(echo "$database_name" | tr 'A-Z' 'a-z')

    if ! [[ -d "$HOME/Databases/$database_name" ]]; then
        echo "Error: No such database: $database_name"
        exit 1
    else
        curr_db_path="$HOME/Databases/$database_name"
    fi
    cd "$curr_db_path"
}
# Function that deletes a database and all its tables.
# CREATED BY HESHAM BASSIOUNY.
drop_db(){
    fourth_word=$(echo "$sql_command" | awk '{print $4}') # get fourth word

    if [[ "$fourth_word" != ";" ]]; then
        echo "excpected ';' found: $fourth_word"
        exit 1
    fi

    database_name=$(echo "$sql_command" | awk '{print $3}') # get third word
    database_name=$(echo "$database_name" | tr 'A-Z' 'a-z')
    delete_db_path="$HOME/Databases/$database_name"

    if ! [[ -d "$delete_db_path" ]]; then
        echo "Error: No such database: $database_name"
        exit 1

    else
        rm -r "$delete_db_path"
    fi
}
# Function that delets a table.
# CREATED BY HESHAM BASSIOUNY.
drop_tb(){
    local curr_db_path="$1"
    local sql_command="$2"

    check_db_selected "$curr_db_path"

    fourth_word=$(echo "$sql_command" | awk '{print $4}') # get fourth word

    if [[ "$fourth_word" != ";" ]]; then
        echo "excpected ';' found: $fourth_word"
        exit 1
    fi

    table_name=$(echo "$sql_command" | awk '{print $3}') # get third word
    table_name=$(echo "$table_name" | tr 'A-Z' 'a-z')
    delete_tb_path="$curr_db_path"

    if ! [[ -e "$delete_tb_path/$table_name.txt" ]]; then
        echo "Error: No such table $table_name at path: $delete_tb_path"
        exit 1

    else
        delete_tb_path_header="$curr_db_path/.$table_name.txt"
        rm "$delete_tb_path_header"
        delete_tb_path_table="$curr_db_path/$table_name.txt"
        rm "$delete_tb_path_table"
    fi
}
# Function that Handles creating a databse.
# CREATED BY HESHAM BASSIOUNY.
create_db(){
    if ! [[ -d "$HOME/Databases" ]]; then
        echo "Creating Databases folder in $HOME"
        mkdir ~/Databases
    fi
    if ! [[ -d "$HOME/database_temp" ]]; then
        echo "Creating database_temp folder in $HOME"
        mkdir ~/database_temp
    fi
    local sql_command="$1"
    fourth_word=$(echo "$sql_command" | awk '{print $4}') # get fourth word

    if [[ "$fourth_word" != ";" ]]; then
        echo "excpected ';' found: $fourth_word"
        exit 1
    fi

    database_name=$(echo "$sql_command" | awk '{print $3}') # get third word
    check_database_name "$database_name"
    if [ -d "$HOME/Databases/$database_name" ]; then
        echo "Error: Directory already exists!"
        exit 1
    fi
    mkdir ~/Databases/$database_name
}
# Auxilary function that returns the first index of a word that is not between quotes (in a string)
# It returns -1 if not found and -2 if found more than once
# CREATED BY HESHAM BASSIONY
word_first_index(){
    string="$1"
    key="$2"
    output=""
    in_quotes=0
    # remove strings and dates from the sql_command
    while IFS= read -r -n1 char; do
        if [[ "$char" == '"' ]]; then
            if [[ $in_quotes -eq 0 ]]; then
                in_quotes=1
            else
                in_quotes=0
            fi
            output+="-"
        elif [[  $in_quotes -eq 0 ]]; then
            output+="$char"
        else
            if [[ "$char" == " " ]]; then
                output+=" "
            else
                output+="-"
            fi
        fi
    done <<< "$string"
    echo "$output" | awk -v word="$key" '
        {
            word_index = -1
            for (i = 1; i <= NF; i++){ 
                if ($i == word){
                    # check if first occurens.
                    if (word_index == -1){ 
                        word_index = i
                    }else{
                        # set index to -2 as a code that word has more than one index which is an error. 
                        word_index = -2
                    }
                }
            }
            print word_index
        }'
}
# AUXILARY function that returns the string between two indecies in a string.
# Takes as an input the first index, the second index, and the string.
# CREATED BY HESHAM BASSIOUNY.
get_words_from_to(){
    string="$3"
    echo "$string" | awk -v from="$1" -v to="$2" '
        {
            string_x=" "
            for (i=from+1; i<to; i++){ 
                string_x = string_x " " $i 
            }
            print string_x
        }'
}
# AUXILARY function that replaces the names of the columns with a string for example id will be col1 if it
# Is the first column in the meta data and so on. If a column name is written in a string it doesn't replace it.
# I would have used a more complex naming to aviod user accedintly writing (col1 for example) it in a string but
# scince this is a personal project I didn't bother to do it for convinece.
# CREATED BY HESHAM BASSIOUNY.
replace_column_name(){
    local sql_command="$1"
    file="$2"
    echo "$sql_command" | awk -v file="$file" '
    BEGIN {
        # Read the file and store the first word and its line number in the array
        counter = 0
        in_quotes = 0
        while ((getline line < file) > 0) {
            counter +=1 
            split(line, fields, ":");  # Split line and store the value in the array fields
            keywords[fields[1]] = "col" counter;  # Store the first word with its column code as value
        }
        close(file);
    }
    {
        # Loop through each word in the input string
        for (i = 1; i <= NF; i++) {
            # check if word is a quote.
            if ($i == "\""){
                if (in_quotes == 1){
                    in_quotes = 0
                }
                else{
                    in_quotes = 1
                }
            }
            else if ($i ~ /^\"/) {
                # check if a word begins with a quote and doesnt end in a quote.
                if ($i !~ /\"$/) {
                    if (in_quotes == 1){
                        in_quotes = 0
                    }
                    else{
                        in_quotes = 1
                    }
                } 
            }
            else if ($i ~ /\"$/) {
                # check if word ends in a quote.
                if (in_quotes == 1){
                    in_quotes = 0
                }
                else{
                    in_quotes = 1
                }
            }
            else if (in_quotes == 0){
                if ($i in keywords) {
                    $i = keywords[$i];  # Replace the word with its line number
                }
            }
        }
        print;  # Print the modified string
    }'
    
}

# A function that evaluates the where and set clauses of update, delete, and select commands.
# Takes as an input the where clause, main table, either an empty table (for select) or the string "update" or
# the string "delete" for when updating or deleting, the update clause, and the column number to be updated.
# The where and update clauses shoud be in the form "col1 + col2" and so on so there original names should be replaced
# by the alias "colX".
# I would have wrote better comments if I had time.
# CREATED BY HESHAM BASSIOUNY
evaluate_expression(){
    expression="$1"   # The expression, e.g., "col1 + col2 > 10" this is the where clause.
    file="$2"         # data table (that contains raws). I know I should use a better name. but I wrote it 3 am so sorry.
    table="$3"        # temporary table to store the values to be shown in select statement, or the command update or delete
    update_expr="$4"  # the set clause expression of the update statement
    col_num="$5"      # the number of the column to be updated in the update expression

    # echo "" | sed "s/\b$word\b/$replacement/g"
    temp_file="$HOME/database_temp/temp87.txt"
    > "$temp_file"
    update_file="$HOME/database_temp/temp870.txt"
    > "$update_file"
    # echo "*******************$update_expr"
    awk -v expr="$expression" -v up_expr="$update_expr" -v up_file="$update_file" -v file="$temp_file" '
    BEGIN {
        FS = ":"  # column delimeter
    }

    {
        # Creating a copy of the expression in awk serves to preserve the original expression for reference and reusability.
        eval_expr = expr
        eval_up = up_expr  

        # Replace column names with their respective values
        for (i = 1; i <= NF; i++) {
            if ($i != ""){
                gsub("col" i, $i, eval_expr)
                gsub("col" i, $i, eval_up)
            }
            else if(eval_expr ~ "col" i){
                gsub("col" i, "A_null_value", eval_expr)
            }
            else if(eval_up ~ "col" i){
                eval_up = ""
            }
            
        }
        # replace "=" with "==" because the first is an assignment operand
        gsub(" = ", " == ", eval_expr)
        gsub(" = ", " == ", eval_up)
        # print "_____________________"
        expr_string= eval_expr 
        print expr_string >> file
        print eval_up >> up_file

    }
    ' "$file"
    counter=1
    while IFS= read -r line; do
        # line=$(echo "$line" | sed 's/\("[^"]*"\)/\\\1/g')
        # line="${line//\"/\\\"}"
        # echo "3 {expression}: $line"
        check=$(evaluate_expression2 "$line")
        # echo "line: $line"
        # echo "check: $check"
        if [[  $check == "True" ]]; then
            if [[ $table == "delete" ]]; then
                sed -i "${counter}d" "$file"
            elif [[ $table == "update" ]]; then
                new_value=$(awk -v n=$counter 'NR==n' "$update_file")
                if [[ $new_value != "" ]]; then
                    new_value=$(python3 -c  "
try:
    result = eval('$new_value')
    print(result)
except Exception as e:
    print(f'Error: {e}')
                    ")
                fi
                # echo "2: $new_value"
                if [[ $new_value == Error:* ]]; then
                    echo "An exception occurred: $new_value"
                    exit 1
                fi
                update_row "$6" "$counter" "$col_num" "$new_value"
            else
                awk -v n=$counter 'NR==n' "$file" >> "$table"
            fi
        elif ! [[ $check == "False" ]]; then
            echo "Error: wrong where expression: $check for line: $line"
            rm "$temp_file"
            exit 1
        fi
        counter=$((counter+1))
    done < "$temp_file"
    rm "$temp_file"
}

# Changes the sql command to lower case (while avoiding strings) and creates spaces before and after special characters.
# Takes as an input the sql command.
# Should be modified in the future to include all special characters which could be done with a pattern.
# For now the modulo % and things other than the basic arithmatic operators must have spaces before and after
# them to work properly.
# CREATED BY HESHAM BASSIOUNY
command_to_lower_with_spaces(){
    local sql_command="$1"
    output=""
    in_quotes=0
    skip=0
    counter=0
    # Replace '+,-,/,*,=' with ' + ', and so on. // replaces all occurenceswhile IFS= read -r -n1 char; do
    while IFS= read -r -n1 char; do
        counter=$((counter + 1))
        if [[ $skip -eq 0 ]]; then  # if skip is set to 1 skip this character
            if [[ "$char" == '"' ]]; then
                if [[ $in_quotes -eq 0 ]]; then
                    in_quotes=1
                else
                    in_quotes=0
                fi
                output+="$char" 
            elif [[ (! "$char" =~ ^[a-zA-Z0-9_\ ]+$) && (! ${sql_command:counter:1} =~ ^[a-zA-Z0-9_\ ]+$) && $in_quotes -eq 0 ]]; then
                output+=" $char${sql_command:counter:1} "
                skip=2
            elif [[ (! "$char" =~ ^[a-zA-Z0-9_\ ]+$) && $in_quotes -eq 0 ]]; then 
                output+=" $char "     
            elif [[ $in_quotes -eq 0 ]]; then
                output+=$(echo "$char" | tr 'A-Z' 'a-z')  #convert to lower case
            else
                output+="$char"
            fi
        else
            skip=0
        fi
    done <<< "$sql_command"
    echo "$output"
}

# A function that handles the select command takes as an input the curr_db_path - which is a global variable but 
# due to time I haven't optimised the function- and the sql_command.
# CREATED BY HESHAM BASSIOUNY.
select_table(){
    local curr_db_path="$1"
    local sql_command="$2"

    check_db_selected "$curr_db_path"

    # keywords=("select" "where" "from" "group" "distinct" ";")

    # sql_command=$(echo "$sql_command" | tr 'A-Z' 'a-z')  # convert to lower case

    
    sql_command=$(command_to_lower_with_spaces "$sql_command")
    # echo "$output"

    check_select=$(word_first_index "$sql_command" "select")


    if [[ check_select -eq -2 ]]; then
        echo "Sorry subquires are not implemented in this DBMS. Please wait for further notice."
        exit 1
    fi


    check_group=$(word_first_index "$sql_command" "group")


    if ! [[ check_group -eq -1 ]]; then
        echo "Sorry group is not implemented in this DBMS. Please wait for further notice."
        exit 1
    fi


    from_index=$(word_first_index "$sql_command" "from")


    if [[ from_index -eq -2 ]]; then
        echo "syntax error more than one from keyword detected."
        exit 1
    fi


    where_index=$(word_first_index "$sql_command" "where")


    if [[ where_index -eq -2 ]]; then
        echo "syntax error more than one Where keyword detected."
        exit 1
    fi

    semicolon_index=$(word_first_index "$sql_command" ";")

    end_of_table=0

    table_name=""
    full_header=""
    if ! [[ from_index -eq -1 ]]; then
        if [[ where_index -eq -1 ]]; then
            end_of_table=$semicolon_index
        else
            end_of_table=$where_index
        fi

        table_name=$(get_words_from_to $from_index $end_of_table "$sql_command")
        table_name=$(echo "$table_name" | tr -d '[:space:]') #remove white spaces
        

        if ! [[ -e "$curr_db_path/$table_name.txt" ]]; then
            echo "couldn't find the table: $table_name at the path: $curr_db_path "
            echo "please note that only one table is allowed we don't current support join quires. please wait for further notice"
            exit 1  
        fi
        
        header_file="$curr_db_path/.$table_name.txt"
        num_fields=$(echo "$header_file" | awk -F":" '{print NF}')
        while IFS= read -r line; do
            for i in $(seq 1 $num_fields); do
                field_header=$(echo "$line" | cut -d":" -f"$i")
                full_header="$full_header$field_header:"
            done
        done < "$header_file"
    else
        if ! [[ where_index -eq -1 ]]; then
            echo "Error: No from keyword."
            exit 1
        else

            select_statment=$(get_words_from_to "1" "$semicolon_index" "$sql_command")
            num_fields=$(echo "$select_statment" | awk -F"," '{print NF}')
            select_table="$HOME/database_temp/select.txt"
            > "$select_table"

            for i in $(seq 1 $num_fields); do
                field=$(echo "$select_statment" | cut -d"," -f"$i")
                header=$header$field
                output=$(python3 -c  "
try:
    result = eval('$field')
    print(result)
except Exception as e:
    print(f'Error: {e}')
                    ")
                # Check if the output contains "Error:"
                if [[ $output == Error:* ]]; then
                    echo "An exception occurred: $output"
                    exit 1
                else
                    if [[ $i -eq $num_fields ]]; then
                        echo "$output"  >> "$select_table"
                    else
                        echo -n "$output:" >> "$select_table"
                    fi
                fi
            done
            print_table "$header" "$select_table" "$full_header"
            rm "$select_table"
        fi
    fi

    if ! [[ where_index -eq -1 ]]; then
        if [[ from_index -eq -1 ]]; then
            echo "Error: no from keyword found."
            exit 1
        fi
        expression=$(get_words_from_to "$where_index" "$semicolon_index" "$sql_command")

        expression=$(replace_column_name " $expression " "$curr_db_path/.$table_name.txt")
        table_file="$HOME/database_temp/table.txt"
        > "$table_file"

        evaluate_expression "$expression" "$curr_db_path/$table_name.txt" "$table_file"
        

        select_sql=" $sql_command "

        select_statment=$(get_words_from_to "1" "$from_index" "$select_sql")

        select_replaced=$(replace_column_name " $select_statment " "$curr_db_path/.$table_name.txt")

        visulize_table "$select_replaced" "$table_file" "$select_statment" "$full_header"
        rm "$table_file"
    
    else
        if ! [[ from_index -eq -1 ]]; then
            select_sql=" $sql_command "

            select_statment=$(get_words_from_to "1" "$from_index" "$select_sql")

            select_replaced=$(replace_column_name " $select_statment " "$curr_db_path/.$table_name.txt")

            visulize_table "$select_replaced" "$curr_db_path/$table_name.txt" "$select_statment" "$full_header"
        fi
      
    fi
    
}
# AUXILARY FUNCTION used by the evaluate_expression function could have had a better name but I didn't modify it
# due to time.
# Takes as an input the processed expression (column names replaced by their value) and outputs the result.
# CREATED BY HESHAM BASSIOUNY
evaluate_expression2() {
    local expression="$1"
    expression="${expression//\"/\\\"}" # replace " with \"
    # echo "4: $expression"
    # Python code to evaluate the expression
    result=$(python3 - <<EOF
from datetime import datetime

class AlwaysFalse:
    def __lt__(self, other):
        return False

    def __le__(self, other):
        return False

    def __eq__(self, other):
        return False

    def __gt__(self, other):
        return False

    def __ge__(self, other):
        return False
        
    def __add__(self, other):
        return False

    def __sub__(self, other):
        return False

    def __mul__(self, other):
        return False

    def __truediv__(self, other):
        return False

    def __floordiv__(self, other): # Defines the behavior of floor division // (e.g., x // y).
        return False

    def __mod__(self, other):
        return False

    def __pow__(self, other): # Defines the behavior of the exponentiation operator ** (e.g., x ** y).
        return False

    def __neg__(self):  # Defines the behavior of the unary negative operator - (e.g., -x).
        return False

    def __pos__(self): # Responsible for defining the behavior of the unary positive operator + (e.g., +x).
        return False

A_null_value = AlwaysFalse()
# Function to parse and compare dates
def replace_dates(expression):
    def parse_date(match):
        date_str = match.group(0).strip('\"')
        return f'datetime.strptime(\"{date_str}\", \"%Y-%m-%d\").date()'

    import re

    return re.sub(r'\"\d{4}-\d{1,2}-\d{1,2}\"', parse_date, expression)

# Replace dates and evaluate the expression
expression = "$expression"
try:
    expression = replace_dates(expression)
    result = eval(expression)
    print(result)
except Exception as e:
    print(f"Error: {e}")
EOF
)
    result="${result//\{/}" # remove {
    result="${result//\}/}" # remove }
    # Return the result
    echo "$result"
}
# The function that handles final processing of the select statement It was originaly meant to print the table but
# I realised later that it processed so much information about the select clause of the select command
# For example it handles the select salry*2 part of the select command.
# It takes as an input the select clause of the select command and the table containing the data to show.
# CREATED BY HESHAM BASSIOUNY. 
visulize_table(){
    local expression="$1"   # The expression, e.g., "col1 + col2 > 10"
    local main_table="$2"         # The file to process, e.g., "file.txt"
    if [[ $expression == *\"* || $expression == *\'* ]]; then
        echo "Error: We don't currently support non-standard column names. please wait for further notice"
        exit 1
    fi
    # echo "" | sed "s/\b$word\b/$replacement/g"
    temp_file="$HOME/database_temp/temp87.txt"
    > "$temp_file"
    # echo "$expression"
    awk -v expr="$expression" -v file="$temp_file" '
    BEGIN {
        FS = ":"  # column delimeter
    }

    {
        # Creating a copy of the expression in awk serves to preserve the original expression for reference and reusability.
        eval_expr = expr  

        # Replace column names with their respective values
        for (i = 1; i <= NF; i++) {
            # print "1: " i " : " $i ": " eval_expr
            if ($i != ""){
                gsub("col" i, $i, eval_expr)
                
            }
            else if(eval_expr ~ "col" i){
                gsub("col" i, "A_null_value", eval_expr)
            }
            # print "2: " i " : " $i ": " eval_expr
        }
        # replace "=" with "==" because the first is an assignment operand
        gsub(" = ", " == ", eval_expr)
        # print "_____________________"
        expr_string= eval_expr 
        print expr_string >> file

    }
    ' "$main_table"

    counter=1
    num_fields=$(echo "$expression" | awk -F"," '{print NF}')
    select_table="$HOME/database_temp/select.txt"
    > "$select_table"
    while IFS= read -r line; do
\
        for i in $(seq 1 $num_fields); do
            field=$(echo "$line" | cut -d"," -f"$i")
            trimmed_field=$(echo "$field" | tr -d ' ')
            if [[ $trimmed_field == "*" ]]; then
                if [[ $i -eq $num_fields ]]; then
                    awk -v line="$counter" 'NR == line' "$main_table" | tr '\\\"' ' ' >> "$select_table"
                else
                    awk -v line="$counter" 'NR == line { printf "%s", $0 }' $main_table | tr '\\\"' ' ' >> "$select_table" 
                fi

            else
                parse_expr=""
                if [[ ! $field =~ "A_null_value" ]]; then
                    parse_expr=$(evaluate_expression2 "$field")
                fi
                if [[ $parse_expr == Error:* ]]; then
                    echo "An exception occurred: $parse_expr"
                    rm "$temp_file"
                    rm "$select_table"
                    exit 1
                else
                    if [[ $i -eq $num_fields ]]; then
                        echo "$parse_expr"  >> "$select_table"
                    else
                        echo -n "$parse_expr:" >> "$select_table"
                    fi
                fi
            fi
        done
        counter=$((counter+1))
    done < "$temp_file"
    rm "$temp_file"
    print_table "$3" "$select_table" "$4"
    rm "$select_table"
}


# Function to print a row with proper formatting
# Prints row by row so the only input is the row.
# CREATED BY HESHAM BASSIOUNY.
print_row() {
    local row="$1"
    IFS=':' read -r -a columns <<< "$row"
    for ((i = 0; i < ${#columns[@]}; i++)); do
        if ((i == 0)); then
            printf "%-20s" "${columns[i]}"
        else
            printf ":%-20s" "${columns[i]}"
        fi
    done
    echo
}

# Function that handles printing the entire table.
# Takes as an input the header table (countained in the select statment), the date table, and all the headers (even those
# not included in the select statment for when the astrics is used).
# CREATED BY HESHAM BASSIOUNY.
print_table(){
    # Define colors for the header
    HEADER_COLOR='\033[1;34m'  # Blue
    Body_COLOR='\033[1;33m'    #yellow
    RESET='\033[0m'           # Reset to default

    header_table="$1"
    table="$2"

    # Define the table header and data
    header=""
    full_header="$3"
    num_fields=$(echo "$header_table" | awk -F"," '{print NF}')

    for i in $(seq 1 $num_fields); do
        field=$(echo "$header_table" | cut -d"," -f"$i")
        trimmed_field=$(echo "$field" | tr -d ' ')

        if [[ $trimmed_field == "*" ]]; then
            num_header_fields=$(echo "$full_header" | awk -F":" '{print NF}')
            for j in $(seq 1 $num_header_fields); do
                field=$(echo "$full_header" | cut -d":" -f"$j")

                if [[ $j -eq $num_header_fields && $i -eq $num_fields ]]; then
                    header="$header$field"
                else
                    header="$header$field:"
                fi
            done
        else
            if [[ $i -eq $num_fields ]]; then
                header="$header$field"
            else
                header="$header$field:"
            fi
        fi
    done


    # Print the header with color
    echo -e "${HEADER_COLOR}"
    print_row "$header"
    echo -e "${RESET}"
    echo -e "${Body_COLOR}"

    # Print a separator
    printf '%0.s-' {1..70}
    echo


    while IFS= read -r row; do
        print_row "$row"
    done < "$table"
    echo -e "${RESET}"
    # Print each row
    # for row in "${rows[@]}"; do
    #     print_row "$row"
    # done
}
# A function that handles the initial processing of the createTB function should be placed all the way up with it.
# takes as an input the curr_db_path which is a global variable so a bit redundant and the sql command.
# CREATED BY HESHAM BASSIOUNY.
create_table(){
    local curr_db_path="$1"
    local sql_command="$2"
    
    check_db_selected "$curr_db_path"

    if [[ "$sql_command" == *"{"* ]]; then
        # Replace the first '{' with ' {' / replaces first occurence
        sql_command="${sql_command/\{/' {'}"
    else
        echo "syntax error near: $type"
        exit 1
    fi

    table_name=$(echo "$sql_command" | awk '{print $3}') # get third word
    check_table_name "$table_name"
    fourth_word=$(echo "$sql_command" | awk '{print $4}') # get fourth word

    if [[ "$fourth_word" != "{"* ]]; then
        echo "excpected '{' found: $fourth_word"
        exit 1
    fi

    values=$(braces_check "$sql_command")  # $(....) excutes in a subshell so exit doesn't terminate the whole script
    
    # Check for the exit status of the function
    if [[ $? -ne 0 ]]; then
        echo "$values"
        exit 1
    fi
    
    values=$(echo "$values" | tr 'A-Z' 'a-z') 

    createTB "$table_name" "$values" "$curr_db_path"

}
# Function that handles the updating a certain row.
# takes as an input the column number to be modified, the row number, the value, and the table to be modified in.
# CREATED BY MOHAMED MAHER
update_row() {
    local table_name="$1"
    local row_number="$2"
    local column_index="$3"
    local new_value="$4"

    # Define paths for the table and metadata
    local base_dir="$curr_db_path"
    check_db_selected "$curr_db_path"
    local table_path="$base_dir/$table_name.txt"
    local meta_path="$base_dir/.${table_name}.txt"
    local metadata_line=$(sed -n "$((column_index + 1))p" "$meta_path")
    local size=$(echo "$metadata_line" | awk -F':' '{print $3}' | sed 's/[^0-9]//g')
    # Check if table and metadata exist
    if [[ ! -f "$table_path" || ! -f "$meta_path" ]]; then
        echo "Error: Table or metadata not found. Table path: $table_path, Metadata path: $meta_path"
        return 1
    fi

    # Step 1: Extract column names and datatypes from metadata
    local table_columns=($(awk -F':' '{print $1}' "$meta_path"))
    local table_datatypes=($(awk -F':' '{print $2}' "$meta_path"))
    local table_constraints=($(awk -F':' '{print $4, $5, $6}' "$meta_path"))  # Primary, Not Null, Unique
    
    # Step 2: Check if the row_number is valid (within bounds)
    local row_count=$(wc -l < "$table_path")
    if ((row_number <= 0 || row_number > row_count)); then
        echo "Error: Invalid row number. Table only has $row_count rows."
        return 1
    fi
    # Step 3: Get the specific row from the table (line corresponding to row_number)
    local row=$(sed -n "${row_number}p" "$table_path")
    IFS=':' read -ra row_values <<< "$row"  # Split the row based on ':'

    new_value=$(echo "$new_value" | xargs)
    if [[ -z "$new_value" ]]; then
        new_value=""
    fi
    # Step 4: Validate the new value based on datatype
    local datatype="${table_datatypes[$((column_index-1))]}"
    case $datatype in
        int)
            if [[ -n "$new_value" && ! "$new_value" =~ ^[0-9]+$ ]]; then
                echo "Error: '$new_value' is not a valid integer for column '${table_columns[$((column_index-1))]}'."
                return 1
            fi
            ;;
        char)
            # Ensure the value is wrapped in double quotes for 'char' column
            if [[ -n "$new_value" && ! "$new_value" =~ ^[a-zA-Z0-9_\ ]+$ ]]; then
                echo "Error: '$new_value' is not a valid string for column '${table_columns[$((column_index-1))]}'."
                return 1
            fi
            if [[ "${#new_value}" -gt "$size" ]]; then
                    echo "Error: Value '$new_value' for column '${table_columns[$((column_index-1))]}' exceeds size limit ($size)."
                    return 1
                fi
            # Make sure it's in double quotes for 'char' (e.g., "Sara")
            new_value="\""$new_value"\""
            ;;
        date)
            # Validate date format (YYYY-MM-DD)
                if [[ -n "$new_value" && ! "$new_value" =~ ^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$ ]]; then
                    echo "Error: Value '$new_value' for column '${table_columns[$((column_index-1))]}' must be in YYYY-MM-DD format."
                    return 1                 
                fi
                # Extract the month and day from the date value
                local year=$(echo "$new_value" | cut -d'-' -f1)
                local month=$(echo "$new_value" | cut -d'-' -f2)
                local day=$(echo "$new_value" | cut -d'-' -f3)
                # Validate the month and day ranges
                if [[ $year < 1000 ]]; then
                    echo "Error: Year '$year' for column '${table_columns[$((column_index-1))]}' must be more than a 1000"
                    return 1
                fi

                if [[ $month -lt 1 || $month -gt 12 ]]; then
                    echo "Error: Month '$month' for column '${table_columns[$((column_index-1))]}' must be between 1 and 12."
                    return 1
                fi

                if [[ $day -lt 1 || $day -gt 31 ]]; then
                    echo "Error: Day '$day' for column '${table_columns[$((column_index-1))]}' must be between 1 and 31."
                    return 1
                fi
                new_value="\""$new_value"\""
                ;;

        *)
            echo "Error: Unknown datatype '$datatype' for column '${table_columns[$((column_index-1))]}'."
            return 1
            ;;
    esac

    # Step 5: Check constraints (Primary Key and Unique)
    local primary_key="${table_constraints[$((column_index-1))]}"
    local not_null="${table_constraints[$((column_index))]}"
    local unique="${table_constraints[$((column_index+1))]}"


    # Unique constraint check (only if it's not a primary key)
    if [[  "$unique" -eq 1 ]]; then
        # Loop through each row in the table to check for duplicate values
        local col_i=$((column_index ))
        while IFS= read -r line; do
            field=$(echo "$line" | cut -d":" -f"$col_i")
            if [[ $datatype == "char" || $datatype == "date" ]]; then
                value_length=$((${#new_value}-1))
                value_temp=${new_value:0:value_length}
                if [[ $field == $new_value ]]; then
                echo "Error: unique constraint violated for column '${table_columns[$((column_index-1))]}'. Value '$new_value' already exists."
                exit 1
                fi
            else
                if [[ $field -eq $new_value ]]; then
                    echo "Error: unique constraint violated for column '${table_columns[$((column_index-1))]}'. Value '$new_value' already exists."
                    exit 1
                fi
            fi
        done < "$table_path"
    fi

    # Step 6: Check Not Null constraint
    if [[ "$not_null" -eq 1 && -z "$new_value" ]]; then
        echo "Error: Column '${table_columns[$((column_index-1))]}' cannot be NULL."
        return 1
    fi

    # Step 7: Update the row by replacing the column value
    row_values[$((column_index-1))]="$new_value"
    
    # Step 8: Rebuild the updated row and write it back to the table
    local updated_row=$(IFS=':'; echo "${row_values[*]}")

    # Use sed to replace the old row with the new updated row
    sed -i "${row_number}s/.*/$updated_row/" "$table_path"

    echo "Row $row_number updated successfully in '$table_name'."
}
# Function that handles inserting in a table.
# Takes as an input the current database path and sql command.
# CREATED BY MOHAMED MAHER
function insert_with_test() {
    local base_dir="$2"

    sql_command=$(command_to_lower_with_spaces "$1")
    into_word=$(echo "$sql_command" | awk '{print $2}') # get second word
    if ! [[ $into_word == "into" ]]; then
        echo "excpected into found: $into_word"
        exit 1
    fi
    table_name=$(echo "$sql_command" | awk '{print $3}')

    if ! [[ -f "$base_dir/$table_name.txt" ]]; then
        echo "table: $table_name doesn't exist in path $base_dir"
        exit 1
    fi
    value_index=$(word_first_index "$sql_command" "values")
    columns_string=""
    values_string=""
    if ! [[ $value_index -eq -1 ]]; then
        if [[ $value_index -eq -2 ]]; then
            echo "more than one values keyword entered."
            exit 1
        fi
        columns_string=$(get_words_from_to "3" "$value_index" "$sql_command")
        # echo "11: $columns_string"
        first_word=$(echo "$columns_string" | awk '{print $1}')

        if ! [[ $first_word == "{" ]];then
            echo "openning brace error."
            exit 1
        fi

        last_word=$(echo "$columns_string" | awk '{ print $NF}')

        # echo "13: $last_word"

        if ! [[ $last_word == "}" ]]; then
            echo "closing brace error."
            exit 1
        fi

        semicolon_index=$(word_first_index "$sql_command" ";")
        values_string=$(get_words_from_to "$value_index" "$semicolon_index"  "$sql_command")
        # echo "12: $values_string"
        first_word=$(echo "$values_string" | awk '{print $1}')

        if ! [[ $first_word == "{" ]];then
            echo "openning brace error."
            exit 1
        fi

        last_word=$(echo "$values_string" | awk '{print $NF}')

        if ! [[ $last_word == "}" ]]; then
            echo "closing brace error."
            exit 1
        fi
    else
        echo "no value keyword found."
        exit 1
    fi
    
    values=$(braces_check "$sql_command")  # $(....) excutes in a subshell so exit doesn't terminate the whole script
    
    # Check for the exit status of the function
    if [[ $? -ne 0 ]]; then
        echo "$values"
        exit 1
    fi
    local values=$(echo "$values_string" | awk '{for (i=2; i<NF; i++) printf $i " "; print ""}')
    # Define paths for table and metadata
    local table_path="$base_dir/$table_name.txt"
    local meta_path="$base_dir/.${table_name}.txt"

    # Check if table and metadata exist
    if [[ ! -f "$table_path" || ! -f "$meta_path" ]]; then
        echo "Error: Table or metadata not found in $base_dir. table path : $table_path, meta data : $meta_path"
        return
    fi
    local columns=$(echo "$columns_string" | awk '{for (i=2; i<NF; i++) printf $i " "; print ""}')
    local values=$(echo "$sql_command" | awk -F'[{]' '{print $3}' | sed 's/[};]//g' | xargs)

    # Count the number of columns and values
    local num_columns=$(echo "$columns" | awk -F',' '{print NF}')
    local num_values=$(echo "$values" | awk -F',' '{print NF}')
    # Validate number of columns and values
    if ((num_columns != num_values)); then
        echo "Error: Number of columns ($num_columns) does not match number of values ($num_values)."
        return 1
    fi
    IFS=',' read -ra column_array <<< "$columns"
    IFS=',' read -ra value_array <<< "$values"

    # Check if number of columns matches number of values
    if [[ "${#column_array[@]}" -ne "${#value_array[@]}" ]]; then
        echo "Error: Number of columns (${#column_array[@]}) does not match number of values (${#value_array[@]})."
        return 1
    fi

    # Create a record array matching all table columns, default to empty
    local table_columns=($(awk -F':' '{print $1}' "$meta_path"))
    local record=()
    for ((i = 0; i < ${#table_columns[@]}; i++)); do
        record[i]=""
    done
    # Validate each provided column and value
    for ((i = 0; i < ${#column_array[@]}; i++)); do
        local column="${column_array[$i]}"
        local value="${value_array[$i]}"
        column=$(echo "$column" | xargs)
        value=$(echo "$value" | xargs)
        # Find column metadata
        local column_index=-1
        for ((j = 0; j < ${#table_columns[@]}; j++)); do
            if [[ "${table_columns[$j]}" == "$column" ]]; then
                column_index=$j
                break
            fi
        done

        if [[ $column_index -eq -1 ]]; then
            echo "Error: Column '$column' does not exist in the table metadata."
            return 1
        fi

        # Extract metadata details
        local metadata_line=$(sed -n "$((column_index + 1))p" "$meta_path")
        local datatype=$(echo "$metadata_line" | awk -F':' '{print $2}')
        local size=$(echo "$metadata_line" | awk -F':' '{print $3}' | sed 's/[^0-9]//g')
        # local primary_key=$(echo "$metadata_line" | awk -F':' '{print $4}')
        local not_null=$(echo "$metadata_line" | awk -F':' '{print $5}')
        local unique=$(echo "$metadata_line" | awk -F':' '{print $6}')
        # Validate value against metadata
        case $datatype in
            int)
                if ! [[ "$value" =~ ^[0-9]+$ ]]; then
                    echo "Error: Value '$value' for column '$column' must be an integer."
                    return 1
                elif [[ $value -gt $size ]]; then
                    echo "Error: value '$value' exceeds the maximum value '$size'"
                    return 1
                fi
                ;;
            char)
                if [[ "${#value}" -gt "$size" ]]; then
                    echo "Error: Value '$value' for column '$column' exceeds size limit ($size)."
                    return 1
                fi
                value="\""$value"\""
                ;;
            date)
                if ! [[ "$value" =~ ^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$ ]]; then
                    echo "Error: Value '$value' for column '$column' must be in YYYY-MM-DD format."
                    return 1                 
                fi
                # Extract the month and day from the date value
                local year=$(echo "$value" | cut -d'-' -f1)
                local month=$(echo "$value" | cut -d'-' -f2)
                local day=$(echo "$value" | cut -d'-' -f3)
                # Validate the month and day ranges
                if [[ $year < 1000 ]]; then
                    echo "Error: Year '$year' for column '$column' must be more than a 1000"
                    return 1
                fi
    
                if [[ $month -lt 1 || $month -gt 12 ]]; then
                    echo "Error: Month '$month' for column '$column' must be between 1 and 12."
                    return 1
                fi

                if [[ $day -lt 1 || $day -gt 31 ]]; then
                    echo "Error: Day '$day' for column '$column' must be between 1 and 31."
                    return 1
                fi
                value="\""$value"\""
                ;;
            *)
                echo "Error: Unknown datatype '$datatype' for column '$column'."
                return 1
                ;;
        esac
        # Check constraints
        if [[ "$not_null" -eq 1 ]]; then
            # Not null: Value cannot be empty
            if [[ -z "$value" ]]; then
                echo "Error: Column '$column' cannot be null."
                return 1
            fi
        fi

        if [[ "$unique" -eq 1 ]]; then
            # Unique constraint: Value must not already exist
            col_i=$((column_index + 1))
            num_fields=$(echo "$table_path" | awk -F":" '{print NF}')

            while IFS= read -r line; do
                field=$(echo "$line" | cut -d":" -f"$col_i")
                if [[ $datatype == "char" || $datatype == "date" ]]; then
                    value_length=$((${#value}-1))
                    value_temp=${value:0:value_length}
                    if [[ $field == $value ]]; then
                    echo "Error: unique constraint violated for column '$column'. Value '$value' already exists."
                    exit 1
                    fi
                else
                    if [[ $field -eq $value ]]; then
                        echo "Error: unique constraint violated for column '$column'. Value '$value' already exists."
                        exit 1
                    fi
                fi
            done < "$table_path"
        fi

        # Set value in the record
        record[$column_index]="$value"
    done

    # Ensure all required columns (NOT NULL and PRIMARY KEY) are filled
    for ((i = 0; i < ${#table_columns[@]}; i++)); do
        local metadata_line=$(sed -n "$((i + 1))p" "$meta_path")
        local col_name=$(echo "$metadata_line" | awk -F':' '{print $1}')
        local not_null=$(echo "$metadata_line" | awk -F':' '{print $5}')
        local primary_key=$(echo "$metadata_line" | awk -F':' '{print $4}')

        if [[ "$not_null" -eq 1 || "$primary_key" -eq 1 ]]; then
            if [[ -z "${record[$i]}" ]]; then
                echo "Error: Column '$col_name' is required and cannot be null."
                return 1
            fi
        fi
    done

    # Append the record to the table
    echo "${record[*]}" | tr ' ' ':' >> "$table_path"
    echo "Record inserted successfully into '$table_name'."
 
}
# The delete command that deletes a certain row.
# Takes as an input the sql command, the current database path, and the table name.
# CREATED BY HESHAM BASSIOUNY
delete_from(){
    local sql_command="$1"
    local db_path="$2"
    local tb_name="$3"
    sql_command=$(command_to_lower_with_spaces "$sql_command")
    where_index=$(word_first_index "$sql_command" "where")

    if ! [[ where_index -eq -1 ]]; then
        if ! [[ where_index -eq -2 ]]; then
            semicolon_index=$(word_first_index "$sql_command" ";")
            where_statment=$(get_words_from_to "$where_index" "$semicolon_index" "$sql_command")
            where_statment=$(replace_column_name "$where_statment" "$db_path/.$tb_name.txt")
            evaluate_expression "$where_statment" "$db_path/$tb_name.txt" "delete"
        else
            echo "Error: multiple Where keyword detected."
            exit 1
        fi  
    else
        fourth_word=$(echo "$sql_command" | awk '{print $4}') # get fourth word
        if ! [[ fourth_word == ";" ]]; then
            echo "Error expected ; found: $fourth_word"
            exit 1;
        fi
        > "$db_path/$tb_name.txt"
    fi

}
# A functions that process data that will be passed to the update_row function.
# takes as an input the sql command only (finally).
# CREATED BY HESHAM BASSIOUNY.
update_tb(){
    local base_dir="$curr_db_path"
    check_db_selected "$base_dir"

    # Parse and clean SQL
    # Clean and parse the SQL command
    local sql_command="$1"

    # Clean and parse the SQL query to make it case-insensitive
    local sql_command_cleaned=$(command_to_lower_with_spaces "$sql_command")

    # Extract table name, columns, values, and WHERE condition
    local table_name=$(echo "$sql_command_cleaned" | awk '{print $2}') # get second word
    if [[ -f "$base_dir/$table_name" ]]; then
        echo "Error: table: $table_name doesn't exist at path: $base_dir"
        exit 1
    fi
    local set_word=$(echo "$sql_command_cleaned" | awk '{print $3}') # get second word

    if [[ set_word == "set" ]]; then
        echo "Error: expected set keyword found: $set_word"
        exit 1
    fi

    local where_index=$(word_first_index "$sql_command_cleaned" "where")
    local semicolon_index=$(word_first_index "$sql_command_cleaned" ";")
    local where_statment=""
    local set_clause=""
    if ! [[ $where_index -eq -1 ]]; then
        if ! [[ $where_index -eq -2 ]]; then
            if [[ $where_index -lt 3 ]]; then
                echo "Error: where is placed before set"
                exit 1
            fi
            set_clause=$(get_words_from_to "3" "$where_index" "$sql_command_cleaned")
            set_clause=$(replace_column_name "$set_clause" "$base_dir/.$table_name.txt")

            column_name=$(echo "$set_clause" | awk '{print $1}') # get first word
            if ! [[ ${column_name:0:3} == "col" ]]; then
                echo "excpected attribute name found: ${column_name:0:3}"
                exit 1
            fi
            column_number_length=$((${#column_name} - 3))
            column_number=${column_name:3:column_number_length}

            equal_op=$(echo "$set_clause" | awk '{print $2}')
            if ! [[ $equal_op == "=" ]]; then
                echo "excpected \"=\" found: $equal_op"
                exit 1
            fi

            expression=$(echo "$set_clause" | awk '{for (i=3; i<=NF; i++) printf $i " "; print ""}') # -f3- gets from the third word onwards.
            # echo "------------------$expression"

            where_statment=$(get_words_from_to "$where_index" "$semicolon_index" "$sql_command_cleaned")
            where_statment=$(replace_column_name "$where_statment" "$base_dir/.$table_name.txt")
            evaluate_expression "$where_statment" "$base_dir/$table_name.txt" "update" "$expression" "$column_number" "$table_name"
        else
            echo "Error: more than one where keyword detected."
            exit 1
        fi  
    else

        set_clause=$(get_words_from_to "3" "$semicolon_index" "$sql_command_cleaned")
        set_clause=$(replace_column_name "$set_clause" "$base_dir/.$table_name.txt")

        column_name=$(echo "$set_clause" | awk '{print $1}') # get first word
        if ! [[ ${column_name:0:3} == "col" ]]; then
            echo "excpected attribute name found: ${column_name:0:3}"
            exit 1
        fi
        column_number_length=$((${#column_name} - 3))
        column_number=${column_name:3:column_number_length}

        equal_op=$(echo "$set_clause" | awk '{print $2}')
        if ! [[ $equal_op == "=" ]]; then
            echo "excpected \"=\" found: $equal_op"
            exit 1
        fi

        expression=$(echo "$set_clause" | awk '{for (i=3; i<=NF; i++) printf $i " "; print ""}') # -f3- gets from the third word onwards.
        # echo "==============$expression----------$set_clause"

        evaluate_expression "1 == 1" "$base_dir/$table_name.txt" "update" "$expression" "$column_number" "$table_name"
    fi 
}


curr_db_path=""

# The main while loop.
# CREATED BY HESHAM BASSIOUNY.
while true; do 
    read -p "enter sql command: " sql_command
    sql_command=$(echo "$sql_command" | tr '()' '{}') #replace all '()' with '{}' due to errors with syntax in echo
    
    #check for semi-colon and separate it from other words
    if [[ "$sql_command" == *";" ]]; then
        # Replace the first ';' with ' ;' / replaces first occurence
        sql_command="${sql_command/\;/' ;'}"
    else
        echo "syntax error missing semicolon."
        exit 1
    fi

    # Check if there are characters after the semicolon that are not whitespace
    if [[ "${sql_command#*;}" =~ [^[:space:]] ]]; then  # ${sql_command#*;}: This removes everything before and including the first semicolon ;
        echo "Error: There are non-whitespace characters after the semicolon."
        exit 1
    fi

    command=$(echo "$sql_command" | awk '{print $1}') # get first word
    command=$(echo "$command" | tr 'A-Z' 'a-z')    #convert to lower case
    case "$command" in
        create)

            type=$(echo "$sql_command" | awk '{print $2}') # get second word
            type=$(echo "$type" | tr 'A-Z' 'a-z')    #convert to lower case

            if [[ "$type" == "table" ]]; then   #-eq is used for integer comparison only
                create_table "$curr_db_path" "$sql_command"

            elif [[ "$type" == "database" ]]; then
                create_db "$sql_command"
            else
                echo "unsupported type $type"
                exit 1
            fi
            
            ;;
        use)
            select_db "$sql_command"
            ;;
        select)
            select_table "$curr_db_path" "$sql_command"
            ;;
        drop)
            type=$(echo "$sql_command" | awk '{print $2}') # get second word
            type=$(echo "$type" | tr 'A-Z' 'a-z')    #convert to lower case

            if [[ "$type" == "table" ]]; then   #-eq is used for integer comparison only
                drop_tb "$curr_db_path" "$sql_command"

            elif [[ "$type" == "database" ]]; then   #-eq is used for integer comparison only
                drop_db "$sql_command"

            else
                echo "unsupported type $type"
                exit 1
            fi
            ;;
        insert)
            insert_with_test "$sql_command" "$curr_db_path"
            ;;
        delete)
            type=$(echo "$sql_command" | awk '{print $2}') # get second word
            type=$(echo "$type" | tr 'A-Z' 'a-z')    #convert to lower case

            if [[ "$type" == "from" ]]; then   #-eq is used for integer comparison only
                check_db_selected "$curr_db_path"
                table_name=$(echo "$sql_command" | awk '{print $3}') # get third word
                table_name=$(echo "$table_name" | tr 'A-Z' 'a-z')    #convert to lower case
                if ! [[ -e "$curr_db_path/$table_name.txt" ]]; then
                    echo "Error: No such table $table_name at path: $curr_db_path"
                    exit 1
                else
                    delete_from "$sql_command" "$curr_db_path" "$table_name"
                fi
            else
                echo "unsupported type $type"
            fi

            ;;
        update)
            update_tb "$sql_command"
            ;;
        show)

            third_word=$(echo "$sql_command" | awk '{print $3}') # get third word

            if [[ "$third_word" != ";" ]]; then
                echo "excpected ';' found: $fourth_word"
                exit 1
            fi

            keyword=$(echo "$sql_command" | awk '{print $2}') # get second word
            keyword=$(echo "$keyword" | tr 'A-Z' 'a-z')
            
            if [[ "$keyword" == "databases" ]]; then
                ls ~/Databases
            
            elif [[ "$keyword" == "tables" ]]; then
                if [[ "$curr_db_path" == "" ]]; then
                    echo "Error: no database selected."
                    exit 1
                fi
                ls "$curr_db_path"
            else
                echo "expected DATABASES or TABLES found: $keyword"
                exit 1
            fi
            ;;

        *)
            echo "unsupported command: $command"
            exit 1
    esac 
done
      
                
                
                    
                
                
                    
                    
                
            
            

