#!/bin/bash

clear

echo -e "\e[1;36m"
echo "██████╗ ██╗   ██╗ ██████╗         ██████╗  ██████╗ ██╗   ██╗███╗   ██╗████████╗██╗   ██╗"
echo "██╔══██╗██║   ██║██╔════╝         ██╔══██╗██╔═══██╗██║   ██║████╗  ██║╚══██╔══╝╚██╗ ██╔╝"
echo "██████╔╝██║   ██║██║  ███╗        ██████╔╝██║   ██║██║   ██║██╔██╗ ██║   ██║    ╚████╔╝ "
echo "██╔══██╗██║   ██║██║   ██║        ██╔══██╗██║   ██║██║   ██║██║╚██╗██║   ██║     ╚██╔╝  "
echo "██████╔╝╚██████╔╝╚██████╔╝███████╗██████╔╝╚██████╔╝╚██████╔╝██║ ╚████║   ██║      ██║   "
echo "╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝   ╚═╝      ╚═╝   "
echo "      Find BugBounty Programs From hackerone - bugcrowd - yeswehack - intigriti"
echo "                Monitors and updates in-scope assets - ScopeWatcher   "
echo -e "\e[0m"

# Define URLs and corresponding database files
declare -A sources
sources=(
    ["hackerone"]="https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/refs/heads/main/data/hackerone_data.json"
    ["bugcrowd"]="https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/refs/heads/main/data/bugcrowd_data.json"
    ["yeswehack"]="https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/refs/heads/main/data/yeswehack_data.json"
    ["intigriti"]="https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/refs/heads/main/data/intigriti_data.json"
)

# Define parsing commands
declare -A jq_filters
jq_filters=(
    ["hackerone"]=".[] | .targets.in_scope[]? | select(.asset_type == \"WILDCARD\") | .asset_identifier"
    ["bugcrowd"]=".[] | .targets.in_scope[]? | select(.type == \"website\") | .target"
    ["yeswehack"]=".[] | .targets.in_scope[]? | select(.type == \"web-application\") | .target"
    ["intigriti"]=".[] | .targets.in_scope[]? | select(.type == \"wildcard\") | .endpoint"
)

# Process each source
for source in "${!sources[@]}"; do
    url="${sources[$source]}"
    file="${source}.txt"
    temp_file="${file}.tmp"

    # Fetch new data
    curl -s "$url" | jq -r "${jq_filters[$source]}" | sort -u > "$temp_file"

    # Remove unwanted characters (specific to bugcrowd)
    if [[ "$source" == "bugcrowd" ]]; then
        sed -i '/█/d' "$temp_file"
    fi

    # Compare with existing database
    if [[ -f "$file" ]]; then
        new_entries=$(comm -13 "$file" "$temp_file")
        if [[ -n "$new_entries" ]]; then
            echo -e "\e[1;32mNew entries added to $file:\e[0m"
            echo "$new_entries"
            echo "$new_entries" >> "$file"
            sort -u "$file" -o "$file"
        fi
    else
        mv "$temp_file" "$file"
        echo "Database file $file created."
    fi
    
    rm -f "$temp_file"
done
