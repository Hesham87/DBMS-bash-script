#!/bin/bash

createTB(){
    touch ".$1.txt"
    touch "$1.txt"
    
    echo "$2" | tr ',' '\n' | awk -v table_name="$1" '
    BEGIN {
        FS = " "  # Set field separator to white space
    }
    {
        for (i = 1; i <= NF; i++) {
            gsub(/^ *| *$/, "", $i)  # Trim whitespace from each field
            if (i > 1) {
                if ($i == "Primary_key") {
                    print $i >> ("." table_name ".txt")
                }
                # Matches "Char(number)" where number is between 1 and 999
                else if (system("echo " $i " | grep -qE \"^Char\{[1-9][0-9]{0,2}\}$\"") == 0) {            # ^Char\{: Starts with Char{.
                    print $i >> ("." table_name ".txt")                                                    # [1-9][0-9]{0,2}: Matches a number from 1 to 999 (e.g., 1, 50, 999).
                                                                                                           # \}$: Ends with a closing }.
                }
                # Matches "Int(number)" where number is between 1 and 99999999
                else if (system("echo " $i " | grep -qE \"^Int\{[1-9][0-9]{0,7}\}$\"") == 0) {
                    print $i >> ("." table_name ".txt")
                }
                else if ($i == "Date") {
                    print $i >> ("." table_name ".txt")
                }
                else {
                    print "Invalid input: Supported types are Primary_key, Int{1-99999999}, Char{1-999}, Date"
                    exit 1
                }
            }
            else{
                print $i >> ("." table_name ".txt")
            }
        }
        print ";;" >> ("." table_name ".txt")
    }
    END {
    }
    '
}

read -p "enter command: " command

case "$command" in
    create)
        read -p "Table or Database: " type
        if [[ "$type" -eq "Table" ]]; then
            read -p "enter Table Name: " name
            read -p "enter Table values(Primary_key, Int{1-99999999}, Char{1-999}, Date): " values
            createTB "$name" "$values"
        elif [[ "$type" -eq "Database" ]]; then
            read -p "enter Database Name: " name
            mkdir ~/DBMS/$name
        else
            echo "unsupported type $type"
            exit 1
        fi
        
        ;;
    *)
        echo "unsupported command $command"
        exit 1
    esac 


