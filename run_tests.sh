original_IFS=$IFS
# must be one character or it won't work correctly
mydelimiter="|"

verbose=false
if [ "$1" = "--verbose" ]; then
  verbose=true
fi

function test_generator {
  local generator="$1"
  local test_file="$2"

  IFS="$mydelimiter"
  local markdown=($(jq -j '.[].markdown | "\(.)'"$mydelimiter"'"' "$test_file"))
# local validities=($(jq -j 'if .[].valid == true then 0 else 1 end | "\(.)'"$mydelimiter"'"' "$test_file"))
  local validities=($(jq -j '.[].valid | "\(.)'"$mydelimiter"'"' "$test_file"))

  nr_of_passed_tests=0
  nr_of_failed_tests=0

  for index in ${!markdown[*]}
  do
    local generator_output="$(echo "${markdown[$index]}" | sh "$generator")"
    
    if [ "$generator_output" = "[]" ]; then
      # no header recognized
      if ${validities[$index]}; then
        nr_of_failed_tests=$(($nr_of_failed_tests + 1))
        echo Test $index failed: Did not recognize any headings

        if $verbose; then
          echo content: \<"${markdown[$index]}"\>
        fi
      else
        nr_of_passed_tests=$(($nr_of_passed_tests + 1))
      fi
    else
      # header recognized

      # TODO: check whether the headings are actually correct, not just that there are some
      if ${validities[$index]}; then
        nr_of_passed_tests=$(($nr_of_passed_tests + 1))
      else
        nr_of_failed_tests=$(($nr_of_failed_tests + 1))
        echo Test $index failed: Falsely recognized the following headings: "$generator_output"
      fi
    fi
  done

  echo All tests completed. Correct: "$nr_of_passed_tests". Failed: "$nr_of_failed_tests"
  if [ $nr_of_failed_tests != 0 ] && ! $verbose ; then
    echo To get more information about failed tests use the option --verbose
  fi
}

# test gen-commonmark.sh
test_generator "analysers/commonmark.sh" "tests/commonmark-0.29.json"


IFS=$original_IFS
