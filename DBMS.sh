#!/bin/bash

createTB(){
    if [[ -e $1.txt ]]; then
        echo "table already exists!"
        exit 1
    fi
    touch ".$1.txt"
    touch "$1.txt"
    touch tempfile.txt
    echo "$2" | tr ',' '\n' | awk -v table_name="$1" '
    BEGIN {
        FS = " "  # Set field separator to white space
    }
    {
        for (i = 1; i <= NF; i++) {
            if (NF == 1){
                    print "you must define a data type"
                    exit 1
            }

            gsub(/^ *| *$/, "", $i)  # Trim whitespace from each field

            if (i > 1) {
                if ($i == "Primary_key") {
                    print $i >> ("tempfile.txt")
                    if(NF == 2){
                        print "you must define a data type for the primary key attribute"
                        exit 1
                    }
                }
                # Matches "Char(number)" where number is between 1 and 999
                else if (system("echo " $i " | grep -qE \"^Char\{[1-9][0-9]{0,2}\}$\"") == 0) {     # ^Char\{: Starts with Char{.
                    print $i >> ("tempfile.txt")                                                    # [1-9][0-9]{0,2}: Matches a number from 1 to 999 (e.g., 1, 50, 999).
                                                                                                    # \}$: Ends with a closing }.
                }                                                                                   # -E, --extended-regexp     PATTERNS are extended regular expressions Provides more advanced syntax compared to basic regular expressions (BRE).
                 # Matches "Int(number)" where number is between 1 and 99999999                                                 # You dont need to escape certain metacharacters (e.g., +, |, ()).
                else if (system("echo " $i " | grep -qE \"^Int\{[1-9][0-9]{0,7}\}$\"") == 0) {      # -G, --basic-regexp        PATTERNS are basic regular expressions (Requires escaping for metacharacters like +, |, and () to be treated as special regex constructs.)
                    print $i >> ("tempfile.txt")                                                    # -P, --perl-regexp         PATTERNS are Perl regular expressions (supports advanced constructs like lookaheads, lookbehinds, and non-capturing groups.)
                }                                                                                                               # Examples:
                else if ($i == "Date") {                                                                                        # echo "apple123orange" | grep -P "(?<=apple)\d+"  # Matches digits after "apple" (lookbehind)
                    print $i >> ("tempfile.txt")                                                                                # echo "1234" | grep -P "\d+"                     # Matches one or more digits (PCRE '\d')
                }                                                                                   # -e, --regexp=PATTERNS     use PATTERNS for matching  (when combining multiple patterns in a single grep command.) 
                else {                                                                                                          # Examples:
                    print "Invalid input: Supported types are Primary_key, Int{1-99999999}, Char{1-999}, Date"                  # echo "apple orange banana" | grep -e "apple" -e "banana"  # Matches "apple" or "banana"
                    exit 1                                                                                                      # echo "fruit" | grep -e "fruit"                           # Matches "fruit"
                }                                                                                   # -q, --quiet, --silent     suppress all normal output
            }      
             else{
                print $i >> ("tempfile.txt")
            }
        }
        print ";;" >> ("tempfile.txt")
    }
    END {
        system("cat " ("tempfile.txt") " >> " ("." table_name ".txt"))
    }
    '
    rm tempfile.txt
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
      
                
                
                    
                
                
                    
                    
                
            
            

