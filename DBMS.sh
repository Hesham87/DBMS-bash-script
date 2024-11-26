#!/bin/bash

#function to create table the output inside the file is column_name:data_type:range:primary_key:not_null:unique
createTB(){
    if [[ -e "$3/$1.txt" ]]; then
        echo "table already exists!"
        exit 1
    fi
    # touch "./tables/.$1.txt"
    # touch "./tables/$1.txt"
    touch tempfile.txt
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
            if (NF == 1){
                    print "you must define a data type"
                    exit_check=1
                    exit 1
            }
            gsub(/^ *| *$/, "", $i)  # Trim whitespace from each field

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

                    # print data type into temp file
                    printf "%s", substr($i, 1, 4) >> ("tempfile.txt")
                    printf ":" >> ("tempfile.txt")
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
                    # print data type into temp file
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
                # Call the check_column_name function for each column name
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
        # print ";;" >> ("tempfile.txt")
    }
    END {
        if (exit_check == 1){
            exit 1
        }

        if (attribute_number == 0){
            print "error: no attributes assigned."
            exit 1
        }

        if (attribute_number < NR){
            print "error: unexpected \",\" "
            exit 1
        }


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

# Function to check if a database name is a valid table name database names can't contain hyphen ;-;
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

# Function to check if a name is a valid table name
check_table_name() {
    local table_name="$1"
    
    # Rule 1: Table name length should be between 1 and 64 characters
    if [[ ${#table_name} -lt 1 || ${#table_name} -gt 64 ]]; then
        echo "Invalid: Table name length should be between 1 and 64 characters."
        exit 1
    fi

    # Rule 2: Table name should match the pattern [a-zA-Z][a-zA-Z0-9_-]+ (start with a letter, then letters, numbers, underscores, or hyphens)
    if ! [[ "$table_name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then      # +: This is a quantifier in regular expressions that means "one or more" of the preceding elements.
                                                                    # $: This is the end of string anchor in regular expressions. It means the pattern must match all the way to the end of the string.
        echo "Invalid: Table name can only contain letters, numbers, underscores, and hyphens. And must begin with letters."
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

# Function to check if braces are balanced, properly nested, and if there are extra characters after the last brace or semicolon and returns the string between the first brace and last brace
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

check_db_selected(){
    if [[ "$1" == "" ]]; then
        echo "Error: no database selected."
        exit 1
    fi
}

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

create_db(){
    local sql_command="$1"
    fourth_word=$(echo "$sql_command" | awk '{print $4}') # get fourth word

    if [[ "$fourth_word" != ";" ]]; then
        echo "excpected ';' found: $fourth_word"
        exit 1
    fi

    database_name=$(echo "$sql_command" | awk '{print $3}') # get third word
    check_database_name "$database_name"
    mkdir ~/Databases/$database_name
}

word_first_index(){
    string="$1"
    key="$2"

    echo "$string" | awk -v word="$key" '
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

replace_column_name(){
    sql_command="$1"
    file="$2"
    awk -v sql="$sql_command" '
    BEGIN {
        FS = ":"  # column delimeter
        command = sql
    }

    {
        # Creating a copy of the sql in awk serves to preserve the original expression for reference and reusability.  
        curr_col = "col" NR " "  
        gsub(" "$1" ", curr_col, command) # \b to replace the column name with col(column number) ex col1, col2, col3...

        # Replace column names with their respective values
        # for (i = 1; i <= NF; i++) {
        #     gsub("col" i, $i, command)
        #     print command
        # }
    }

    END{
        print command
    }
    ' "$file"
    
}

evaluate_expression(){
    expression="$1"   # The expression, e.g., "col1 + col2 > 10"
    file="$2"         # The file to process, e.g., "file.csv"
    table="$3"

    # echo "" | sed "s/\b$word\b/$replacement/g"
    temp_file="$HOME/database_temp//temp87.txt"
    touch "$file"

    awk -v expr="$expression" -v file="$temp_file" '
    BEGIN {
        FS = ":"  # column delimeter
    }

    {
        # Creating a copy of the expression in awk serves to preserve the original expression for reference and reusability.
        eval_expr = expr  

        # Replace column names with their respective values
        for (i = 1; i <= NF; i++) {
            gsub("col" i, $i, eval_expr)
            # replace "=" with "==" because the first is an assignment operand
            gsub(" = ", " == ", eval_expr)
        }
        # print "_____________________"
        expr_string= eval_expr 
        print expr_string >> file

    }
    ' "$file"
    counter=0
    while IFS= read -r line; do
        if [[ $(echo "$[ $line ]") -eq 1 ]]; then
            awk -v n=$counter 'NR==n' "$file" >> "$table"
        fi
        counter=$((counter+1))
    done < "$temp_file"
    rm "$temp_file"
}

select_table(){
    local curr_db_path="$1"
    local sql_command="$2"

    check_db_selected "$curr_db_path"

    keywords=("select" "where" "from" "group" "distinct" ";")

    sql_command=$(echo "$sql_command" | tr 'A-Z' 'a-z')  # convert to lower case


    # Replace '+,-,/,*,=' with ' + ', and so on. // replaces all occurences
    sql_command="${sql_command//\+/' + '}"
    sql_command="${sql_command//\-/' - '}"
    sql_command="${sql_command//\=/' = '}"
    sql_command="${sql_command//\*/' * '}"
    sql_command="${sql_command//\//' / '}"
    sql_command="${sql_command/\{/' { '}"
    sql_command="${sql_command/\,/' , '}"


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

    if ! [[ from_index -eq -1 ]]; then

        if [[ where_index -eq -1 ]]; then
            end_of_table=$semicolon
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
    
    else

        if ! [[ where_index -eq -1 ]]; then
            echo "Error: No from keyword."
            exit 1
        else

            select_statment=$(get_words_from_to "1" "$semicolon_index" "$sql_command")
            num_fields=$(echo "$select_statment" | awk -F"," '{print NF}')
            select_table="$HOME/database_temp/select.txt"
            touch "$select_table"

            for i in $(seq 1 $num_fields); do
                field=$(echo "$select_statment" | cut -d"," -f"$i")
                if [[ $i -eq $num_fields ]]; then
                    python3 -c  "print(eval('$field'))" >> "$select_table"
                else
                    python3 -c  "print(eval('$field'), end=':')" >> "$select_table" 
                fi
            done
            cat "$select_table"
            rm "$select_table"
        fi
    fi

    if ! [[ where_index -eq -1 ]]; then
        if [[ from_index -eq -1 ]]; then
            echo "Error: no from keyword found."
            exit 1
        fi

        expression=$(get_words_from_to "$where_index" "$semicolon_index" "$sql_command")

        expression=$(replace_column_name "$expression" "$curr_db_path/.$table_name.txt")
        
        table_file="$HOME/database_temp/table.txt"
        touch "$table_file"


        evaluate_expression "$expression" "$curr_db_path/$table_name.txt" "$table_file"

        select_sql=" $sql_command "

        select_statment=$(get_words_from_to "1" "$from_index" "$select_sql")


        select_replaced=$(replace_column_name " $select_statment " "$curr_db_path/.$table_name.txt")


        visulize_table "$select_replaced" "$table_file" "$select_statment"
      
    fi
    
}

visulize_table(){
    expression="$1"   # The expression, e.g., "col1 + col2 > 10"
    file="$2"         # The file to process, e.g., "file.csv"

    # echo "" | sed "s/\b$word\b/$replacement/g"
    temp_file="$HOME/database_temp/temp87.txt"
    touch "$file"

    awk -v expr="$expression" -v file="$temp_file" '
    BEGIN {
        FS = ":"  # column delimeter
    }

    {
        # Creating a copy of the expression in awk serves to preserve the original expression for reference and reusability.
        eval_expr = expr  

        # Replace column names with their respective values
        for (i = 1; i <= NF; i++) {
            gsub("col" i, $i, eval_expr)
            # replace "=" with "==" because the first is an assignment operand
            gsub(" = ", " == ", eval_expr)
        }
        # print "_____________________"
        expr_string= eval_expr 
        print expr_string >> file

    }
    ' "$file"

    
    num_fields=$(echo "$expression" | awk -F"," '{print NF}')
    select_table="$HOME/database_temp/select.txt"
    touch "$select_table"
    while IFS= read -r line; do
        for i in $(seq 1 $num_fields); do
            field=$(echo "$line" | cut -d"," -f"$i")
            if [[ $i -eq $num_fields ]]; then
                python3 -c  "print(eval('$field'))" >> "$select_table"
            else
                python3 -c  "print(eval('$field'), end=':')" >> "$select_table" 
            fi
        done
    done < "$temp_file"
    rm "$temp_file"
    rm "$file"
    print_table "$3" "$select_table"
    rm "$select_table"
}


# Function to print a row with proper formatting
print_row() {
    local row="$1"
    IFS=':' read -r -a columns <<< "$row"
    for ((i = 0; i < ${#columns[@]}; i++)); do
        if ((i == 0)); then
            printf "%-15s" "${columns[i]}"
        else
            printf ":%-15s" "${columns[i]}"
        fi
    done
    echo
}


print_table(){
    # Define colors for the header
    HEADER_COLOR='\033[1;34m'  # Blue
    Body_COLOR='\033[1;33m'    #yellow
    RESET='\033[0m'           # Reset to default

    header_table="$1"
    table="$2"

    # Define the table header and data
    header=""

    num_fields=$(echo "$header_table" | awk -F"," '{print NF}')

    for i in $(seq 1 $num_fields); do
        field=$(echo "$header_table" | cut -d"," -f"$i")
        if [[ $i -eq $num_fields ]]; then
            header="$header$field"
        else
            header="$header$field:"
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
curr_db_path=""


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
      
                
                
                    
                
                
                    
                    
                
            
            

