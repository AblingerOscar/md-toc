#!/bin/bash

output='['
current_heading_level=
current_heading_name=

currently_in_code_fence=false
starting_code_fence=""

function begins_with {
  local line=$1
  local line_beginning=$2

  case $line in
    "$line_beginning"*) true;;
    *) false;;
  esac;
}

function code_indentation {
  local line=$1
  begins_with "$line" "    "
  return "$?"
}

function trim_characters {
  local string=$1
  local characters=$2

  leading_removed="${string#"${string%%[!$characters]*}"}"
  trimmed="${leading_removed%"${leading_removed##*[!$characters]}"}"
  echo -n "$trimmed"
}

function trim {
  local string=$1
  echo -n "$(trim_characters "$string" "[:space:]")"
}

function check_for_code_fence_start {
    line=$1
    nr_of_consecutive_backticks=0
    nr_of_consecutive_tildes=0

    for (( i=0; i < ${#line}; i++  )); do
      if [ "${line:$i:1}" = '`' ]; then
        nr_of_consecutive_backticks=$((nr_of_consecutive_backticks+1))
      else
        if [[ $nr_of_consecutive_backticks -gt 2 ]]; then
          continue
        fi
        nr_of_consecutive_backticks=0
      fi

      if [ "${line:$i:1}" = '~' ]; then
        nr_of_consecutive_tildes=$((nr_of_consecutive_tildes+1))
      else
        if [[ $nr_of_consecutive_tildes -gt 2 ]]; then
          continue
        fi
        nr_of_consecutive_tildes=0
      fi
    done

    if [[ $nr_of_consecutive_backticks -gt 2 ]]; then
      currently_in_code_fence=true
      starting_code_fence=$(eval $(echo "printf '\`%0.s' {1..$nr_of_consecutive_backticks}"))

      # @setex-headings: interrupt paragraph: code fence
      current_heading_name=""
    fi
    if [[ $nr_of_consecutive_tildes -gt 2 ]]; then
      currently_in_code_fence=true
      starting_code_fence=$(eval $(echo "printf '~%0.s' {1..$nr_of_consecutive_tildes}"))

      # @setex-headings: interrupt paragraph: code fence
      current_heading_name=""
    fi
}

# checks the amount of # at the start of the string
#   and whether there is a space after them
# returns 1-6 for h1-h2 in atx style
# returns 0 if it's not a header
function atx_heading_level {
  local line=$1
  
  case $line in
    "###### "*) return 6;;
    "######\n") return 6;;
    "##### "*) return 5;;
    "#####\n") return 5;;
    "#### "*) return 4;;
    "####\n") return 4;;
    "### "*) return 3;;
    "###\n") return 3;;
    "## "*) return 2;;
    "##\n") return 2;;
    "# "*) return 1;;
    "#\n") return 1;;
    *) return 0;;
  esac;
}

function atx_heading_name {
  local line=$1
  local trimmed="$(trim_characters "$line" "\#[:space:]")"

  echo -n "$trimmed"
}

function check_atx_heading {
  local line="$1"
  atx_heading_level "$line"
  h_level="$?"
  if [ "$h_level" == 0 ]; then
    return 1 # false
  fi

  h_name="$(atx_heading_name "$line")"
  # Found heading of level $h_level with name "<$h_name>"

  current_heading_level=$h_level
  current_heading_name="$h_name"
}

# recognize list of = or -
function check_setex_heading {
  line="$1"

  if [ -n "$current_heading_name" ] && [ -n "$line" ]; then
    lvl1_pure_line="$(trim_characters "$line" "=")"
    if [ -z "$lvl1_pure_line" ]; then
      current_heading_level=1
      return 0
    fi
    
    lvl2_pure_line="$(trim_characters "$line" "-")"
    if [ -z "$lvl2_pure_line" ]; then
      current_heading_level=1
      return 0
    fi
  fi
  return 1
}

function check_setex_heading_reset {
  if [ -z "$current_heading_name" ]; then
    current_heading_name="$trimmed_line"
  else
    current_heading_name="$current_heading_name $trimmed_line"
  fi

  # a paragraph gets interrupted by:
  #     - block quote (see TODO about block quotes in general
  #     - html block (TODO)
  #     - a blank line
  if [ -z "$trimmed_line" ]; then
    current_heading_name=""
  fi

  #     - thematic break
  if [[ "$trimmed_line" =~ ^___+ ]]; then
    current_heading_name=""
  elif [[ "$trimmed_line" =~ ^---+ ]]; then
    current_heading_name=""
  elif [[ "$trimmed_line" =~ ^\*\*\*+ ]]; then
    current_heading_name=""

  #     - list item
  elif [[ "$trimmed_line" =~ ^[-+*]' ' ]]; then
    current_heading_name=""
  elif [[ "$trimmed_line" =~ ^[0-9]{1,9}')' ]]; then
    current_heading_name=""
  elif [[ "$trimmed_line" =~ ^[0-9]{1,9}'.' ]]; then
    current_heading_name=""
  fi
}


function escape {
  local line=$1
  
  echo -e "$line" | sed 's/"/\\"/g'
}

function generate_output_for_current_heading {
  local level="$current_heading_level"
  local name="$(escape "$(trim "$current_heading_name")")"

  local heading_object="{\"level\":$level,\"name\":\"$name\"}"

  if [ "$output" == "[" ]; then
    output="$output$heading_object" 
  else
    output="$output,$heading_object"
  fi
 
  # @setex-headings: interrupt paragraph: atx header 
  current_heading_name=""
}

while IFS= read -r line; do
  # check for indented code
  if code_indentation "$line"; then
    # @setex-headings: interrupt paragraph: code indentation
    current_heading_name=""

    continue
  fi

  trimmed_line="$(trim "$line")"

  # Note: code fences do not start if they are indented like code,
  #       hence this is checked after the indentation
  if $currently_in_code_fence; then
    # check whether it ends on this line
    if [ "$trimmed_line" = "$starting_code_fence" ]; then
      currently_in_code_fence=false
    fi
    continue
  else
    # check whether a code fence starts here
    check_for_code_fence_start "$trimmed_line"
  fi
  
  # atx headings
  if check_atx_heading "$trimmed_line" = true; then
    generate_output_for_current_heading
  fi

  # setex headings
  if check_setex_heading "$trimmed_line" = true; then
    generate_output_for_current_heading
    continue
  fi

  check_setex_heading_reset  
done < "${1:-/dev/stdin}"

# End the output
output="$output]"
echo -n "$output"
