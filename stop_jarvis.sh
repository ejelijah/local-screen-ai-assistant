#!/bin/bash

set -u

PROJECT_DIR="/Users/elijahakpan/developer/OpenJarvis"
BACKEND_PORT=8000
FRONTEND_PORT=5173

choice=$(/usr/bin/osascript <<'APPLESCRIPT'
try
	display dialog "Stop OpenJarvis AI?" ¬
		with title "OpenJarvis" ¬
		buttons {"Cancel", "Stop OpenJarvis"} ¬
		default button "Stop OpenJarvis"
	return button returned of result
on error number -128
	return "Cancel"
end try
APPLESCRIPT
)

if [ "$choice" != "Stop OpenJarvis" ]; then
	exit 0
fi

get_pids() {
	/usr/sbin/lsof -tiTCP:"$1" -sTCP:LISTEN 2>/dev/null | sort -u
}

pids=""
for port in "$BACKEND_PORT" "$FRONTEND_PORT"; do
	while IFS= read -r pid; do
		[ -n "$pid" ] && pids="$pids $pid"
	done < <(get_pids "$port")
done

if [ -z "$pids" ]; then
	/usr/bin/osascript -e 'display dialog "OpenJarvis is not running." with title "OpenJarvis" buttons {"OK"} default button "OK"'
	exit 0
fi

for pid in $pids; do
	/bin/kill "$pid" 2>/dev/null || true
done

/usr/bin/osascript -e 'tell application "OpenJarvis" to quit' >/dev/null 2>&1 || true
/usr/bin/osascript -e 'display dialog "OpenJarvis services stopped." with title "OpenJarvis" buttons {"OK"} default button "OK"'
