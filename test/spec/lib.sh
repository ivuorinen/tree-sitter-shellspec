# shellcheck shell=sh
# Stub library referenced by 01.very_simple_spec.sh

calc() {
  eval "echo \$(( $1 $2 $3 ))"
}
