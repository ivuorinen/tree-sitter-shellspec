# shellcheck shell=sh
Include ./lib.sh
# <- keyword.directive

fDescribe 'focused group'
# <- keyword.function.focused
  xIt 'skipped example'
  # <- keyword.function.skipped
    Pending 'not ready'
    # <- keyword.function.pending
  End

  Mock date
  # <- keyword.function
    echo 2026
  End

  It 'reads data'
    Data
    # <- keyword.function.data
      #|first line
      # <- punctuation.special
      #  ^ string
    End
    Path config=/tmp/config
    # <- keyword
    When I run cat
    #    ^ keyword.operator
    The output should not eq 'first line'
    #   ^ variable.parameter
    #                 ^ keyword.control
    #                     ^ function.method
  End
End
