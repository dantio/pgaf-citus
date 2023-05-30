#!/bin/sh
set -e

if [ -n "$WAIT_FOR_IT" ]; then
  wait-for-it.sh "$WAIT_FOR_IT"
fi

if [ -n "$HEALTHCHECK_PORT" ]; then
  shell2http -no-index -port="$HEALTHCHECK_PORT" -500 -log=/dev/null -cgi /health pgcheck &
fi

# Run the main container command.
exec pg_autoctl create "$@"