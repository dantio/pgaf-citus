#!/bin/sh

set -e

if [ -n "$WAIT_FOR_IT" ]; then
  wait-for-it.sh "$WAIT_FOR_IT"
fi

# Run the main container command.
exec pg_autoctl create "$@"