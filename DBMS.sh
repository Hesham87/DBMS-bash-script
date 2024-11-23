#!/bin/bash

createTB(){
    if [[ -e "$3/$1.txt" ]]; then
        echo "table already exists!"
        exit 1
    fi
    # touch "./tables/.$1.txt"
    # touch "./tables/$1.txt"
    touch tempfile.txt
    echo "$2" | tr ',' '\n' | awk -v table_name="$1" -v table_path="$3" '
    BEGIN {
        FS = " "  # Set field separator to white space
        primary_key=0
        attribute_number=0
        attribute_names[0]=""
        exit_check=0
    }
    {
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
                    print $i >> ("tempfile.txt")

                    if (primary_key == 0){
                        primary_key=1
                    }else{
                        print "only one attribute can be primary key."
                        exit_check=1
                        exit 1
                    }
                }
                # Matches "Char(number)" where number is between 1 and 999
                else if (system("echo " $i " | grep -qE \"^char\{[1-9][0-9]{0,2}\}$\"") == 0) {     # ^Char\{: Starts with Char{.
                    print $i >> ("tempfile.txt")                                                    # [1-9][0-9]{0,2}: Matches a number from 1 to 999 (e.g., 1, 50, 999).
                                                                                                    # \}$: Ends with a closing }.
                    if (data_type == 0){
                        data_type=1
                    }else{
                        print "you can only assign one data type to an attribute"
                        exit_check=1
                        exit 1
                    } 
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
                    print $i >> ("tempfile.txt")                                                    # -P, --perl-regexp         PATTERNS are Perl regular expressions (supports advanced constructs like lookaheads, lookbehinds, and non-capturing groups.)
                }                                                                                                               # Examples:
                else if ($i == "date") {                                                                                        # echo "apple123orange" | grep -P "(?<=apple)\d+"  # Matches digits after "apple" (lookbehind)
                    print $i >> ("tempfile.txt")                                                                                # echo "1234" | grep -P "\d+"                     # Matches one or more digits (PCRE '\d')
                    if (data_type == 0){
                        data_type=1
                    }else{
                        print "you can only assign one data type to an attribute"
                        exit_check=1
                        exit 1
                    } 
                }                                                                                   # -e, --regexp=PATTERNS     use PATTERNS for matching  (when combining multiple patterns in a single grep command.) 
                else {                                                                                                          # Examples:
                    print "Invalid input: Supported types are Primary_key, Int{1-99999999}, Char{1-999}, Date"                  # echo "apple orange banana" | grep -e "apple" -e "banana"  # Matches "apple" or "banana"
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
                attribute_number+=1
                attribute_names[attribute_number]=$i
                print $i >> ("tempfile.txt")
            }
        }
        print ";;" >> ("tempfile.txt")
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

    if ! [[ -e "$delete_tb_path" ]]; then
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
      
                
                
                    
                
                
                    
                    
                
            
            

