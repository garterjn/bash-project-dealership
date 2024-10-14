#!/bin/bash

# Initialize variables
csv_file=""
type=""
field=""
parameter=""

# Help Function (-h)
function display_usage() {
  echo "Usage: $0 -c <csv_file> -t <type> -f <field> -p <parameter>" #arg 0 ($0) is the script
  echo "Options:"
  echo "  -c <csv_file>: Specify the input csv filename."
  echo "  -t <type>: Specify the type of action to perform. Supported types are 'verify', 'search', and 'sort'."
  echo "  -f <field>: Specify the search or sort field. Supported types are 'year', 'mileage', and 'price' for type 'sort' while including 'make', 'model', 'trim', 'style', 'color', and 'none' for type 'search'" 
  echo "  -p <parameter>: Specify the search parameter in that field when using 'search'. Supported inputs are alphanumeric"
  echo "  -h: Display this help information."
}

# Check if no arguments are provided
if [[ $# -eq 0 || "$1" == "-h" ]]; then #if there are 0 args OR argument 1 ($1) is -h
    display_usage
    exit 0
fi

# Process command-line options and arguments
while getopts ":c:t:f:p:h" opt; do
    case $opt in
        c) # option c
            csv_file=$OPTARG
            ;;
        t) # option t
            type=$OPTARG
            ;;
        f) # option f
            field=$OPTARG
            ;;
        p) # option p
            parameter=$OPTARG
            ;;
        h) # option h
            display_usage
            exit 0
            ;;
        \?) # any other option
            echo "Invalid option: -$OPTARG"
            display_usage
            exit 0
            ;;
        :) # no argument
            echo "Option -$OPTARG requires an argument."
            display_usage
            exit 1
            ;;
    esac
done

# Sort Function (-t 'sort' -f 'year', 'mileage', or 'price')
function sorter() {
    # Sort by year (newest to oldest)
    if [[ $field == "year" ]]; then
        echo "List sorted by year:"
        sort -t ',' -k 1,1nr $csv_file # 1,1 sorts by the first field (which is year) nr is because it is numeric and I want it in reverse order (newest cars first)
    # Sort by mileage (least to greatest)
    elif [[ $field == "mileage" ]]; then
        echo "List sorted by mileage:"
        sort -t ',' -k 7,7n $csv_file
    #Sort by price (least to greatest)
    elif [[ $field == "price" ]]; then
        echo "List sorted by price:"
        sort -t ',' -k 8,8n $csv_file
    fi
}

# Search Function (-t 'search' -f '[aField]' -p '[aValue]') {Year,Make,Model,Trim,Style,Color,Mileage,Price} {any value}
function searcher() {
    # Search by year 
    if [[ $field == "year" ]]; then
        echo "Cars manufactured in $parameter:"
        awk -F "," '$1 == '$parameter'' $csv_file
    # Search by make
    elif [[ $field == "make" ]]; then
        echo "Cars with make $parameter:"
        awk -F "," -v IGNORECASE=1 '$2 == "'$parameter'"' $csv_file
    # Search by model
    elif [[ $field == "model" ]]; then
        echo "Cars with model $parameter:"
        awk -F "," -v IGNORECASE=1 '$3 == "'$parameter'"' $csv_file
    # Search by trim
    elif [[ $field == "trim" ]]; then
        echo "Cars with trim $parameter:"
        awk -F "," -v IGNORECASE=1 '$4 == "'$parameter'"' $csv_file
    # Search by style
    elif [[ $field == "style" ]]; then
        echo "Cars with $parameter style:"
        awk -F "," -v IGNORECASE=1 '$5 == "'$parameter'"' $csv_file
    # Search by color
    elif [[ $field == "color" ]]; then
        echo "$parameter cars:"
        awk -F "," -v IGNORECASE=1 '$6 == "'$parameter'"' $csv_file
    # Search by mileage
    elif [[ $field == "mileage" ]]; then
        echo "Cars with less than $parameter miles:"
        awk -F "," '$7 <= '$parameter'' $csv_file
    # Search by price
    elif [[ $field == "price" ]]; then
        echo "Cars costing less than \$$parameter:"
        awk -F "," '$8 <= '$parameter'' $csv_file
    fi
}

function verifier() {
    if grep -q -v -E '^[0-9]{4},[A-Za-z\-]+,[A-Za-z0-9\-]+,[A-Za-z0-9\.\-_]+,[A-Za-z]{1,12},[A-Za-z]+,[0-9]{1,7},[0-9]{3,8}$' $csv_file; then # have to check that there is something or grep will error
        echo "Errors found:"
        #           year     make         model          trim             style          color     mileage     price
        grep -v -E '^[0-9]{4},[A-Za-z\-]+,[A-Za-z0-9\-]+,[A-Za-z0-9\.\-_]+,[A-Za-z]{1,12},[A-Za-z]+,[0-9]{1,7},[0-9]{3,8}$' $csv_file
    else
        echo "No errors found!"
    fi
    
}

# Check for required values
if [[ -z $csv_file || -z $type ]]; then #-z checks if values are empty
    echo "Error: Missing required options -c or -t."
    exit 1
fi

# Check for conditionally required values
if [[ $type == "search" ]]; then
    if [[ -z $field || -z $parameter ]]; then
        echo "Error: 'search' action type requires 'field' and 'parameter'"
        exit 1
    fi
elif [[ $type == "sort" ]]; then
    if [[ -z $field ]]; then
        echo "Error: 'sort' action type requires 'field'"
        exit 1
    fi
fi

# Check that -c is a valid file
if [[ ! -f $csv_file ]]; then
    echo "Error: Input file '$csv_file' does not exist"
    exit 1
fi

# Check that -t is a valid action type
if [[ $type != "sort" && $type != "search" && $type != "verify" ]]; then
    echo "Error: Unknown action type"
    exit 1
fi

# Check that -p is alphanumeric
if [[ $type == "search" && ! "$parameter" =~ ^[A-Za-z0-9]+$ ]]; then
    echo "Error: Parameter must be alphanumeric"
    exit 1
fi

# Check that -f is a valid field given the action type
# Check sort
if [[ $type == "sort" ]]; then
    if [[ $field != "year" && $field != "mileage" && $field != "price" ]]; then
        echo "Error: Unknown field used with 'sort' action type"
        exit 1
    else
        sorter # Run sorter if sort is chosen
    fi
# Check search {Year,Make,Model,Trim,Style,Color,Mileage,Price}
elif [[ $type == "search" ]]; then
    if [[ $field != "year" && $field != "make" && $field != "model" && $field != "trim" && $field != "style" && $field != "color" && $field != "mileage" && $field != "price" ]]; then
        echo "Error: Unknown field used with 'search' action type"
        exit 1
    elif [[ -z $parameter ]]; then
        echo "Error: Parameter required for 'search' action type"
        exit 1
    else
        searcher # Run searcher if search is chosen
    fi
elif [[ $type == "verify" ]]; then
    verifier # Run verifier if verify is chosen 
fi