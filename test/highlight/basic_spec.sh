# shellcheck shell=sh
Describe 'highlight'
# <- keyword.function
  Before 'setup'
  # <- keyword.control.hook
  Skip if 'no tool' true
  #    ^ keyword.control

  It 'works'
  # <- keyword.function
    When call true
    # <- keyword
    #    ^ keyword.operator
    The output should eq ''
    # <- keyword
    #          ^ keyword.control
  End
  # <- keyword.control
End
# <- keyword.control

%text
# <- keyword.directive
#|line

if true; then
# <- keyword
  :
fi
