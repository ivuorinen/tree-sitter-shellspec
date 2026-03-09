# shellcheck shell=sh

# Sometimes, functions are defined in a single shell script.
# You will want to test it. but you do not want to run the script.
# You want to test only the function, right?
Describe 'sourced return example'
  Include ./count_lines.sh

  Example 'test count_lines with stubbed data'
    Data
      #|1
      #|2
      #|3
      #|4
      #|5
    End

    When call count_lines
    The stdout should eq 5
  End

  Example 'test count_lines with stubbed data'
    Data data
    data() {
      %putsn "line1"
      %putsn "line2"
      %putsn "line3"
      %putsn "line4"
      %puts "line5 (without newline)"
    }

    When call count_lines
    The stdout should eq 5
  End
End
