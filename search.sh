#!/bin/bash

show_help() {
    echo "Usage: search [-h]"
    echo "       search [-u]"
    echo "       search [-d] [-e] [-l] [-i [-o]] STRING [STRING…]"
    echo "       search [-d] [-e] [-l] [-i [-o]] STRING [PATH] [STRING…]"
    echo "       search [-d] [-e] [-l] [-i [-o]] [-p PATH] STRING [STRING…]"
    echo ""
    echo "          PATH: if a string is a directory, use it as the search path (default: \$PWD)"
    echo "        STRING: the string(s) to search in dirnames/filenames"
    echo ""
    echo "  -d,  --debug: show debug message"
    echo "  -e,  --error: show error message"
    echo "  -h,   --help: show this help"
    echo "  -i,  -inside: search inside file"
    echo "  -l, --locate: use locate instead of find command"
    echo "  -o,   --only: use it with -i, search only inside file"
    echo "  -p,   --path: force using the following string as the search path"
    echo "  -u, --update: update the locate DB"
}

update_locate_db() {
    sudo updatedb
}

search_files() {
    local search_path="$1"
    shift
    local terms=("$@")
    local find_cmd="find \"$search_path\""
    for term in "${terms[@]}"; do
        find_cmd+=" -iname \"*${term}*\""
    done
    eval "$find_cmd"
}

search_inside_files() {
    local search_path="$1"
    shift
    local terms=("$@")
    grep -ril -- "${terms[@]}" "$search_path"
}

debug_mode=false
error_mode=false
use_locate=false
search_inside=false
only_inside=false
search_path="$PWD"

while [[ "$1" == -* ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -u|--update)
            update_locate_db
            exit 0
            ;;
        -d|--debug)
            debug_mode=true
            set -x
            ;;
        -e|--error)
            error_mode=true
            ;;
        -l|--locate)
            use_locate=true
            ;;
        -i|--inside)
            search_inside=true
            ;;
        -o|--only)
            only_inside=true
            ;;
        -p|--path)
            shift
            search_path="$1"
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

if [[ "$#" -eq 0 ]]; then
    echo "Error: No search terms provided."
    show_help
    exit 1
fi

if $use_locate; then
    locate "$@"
elif $search_inside; then
    if $only_inside; then
        search_inside_files "$search_path" "$@"
    else
        search_files "$search_path" "$@" && search_inside_files "$search_path" "$@"
    fi
else
    search_files "$search_path" "$@"
fi

if $debug_mode; then
    set +x
fi