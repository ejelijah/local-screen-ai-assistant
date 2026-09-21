#!/bin/bash

set -u

PROJECT_DIR="/Users/elijahakpan/developer/OpenJarvis"
BACKEND_PORT=8000
FRONTEND_PORT=5173
BACKEND_LOG="$PROJECT_DIR/backend.log"
FRONTEND_LOG="$PROJECT_DIR/frontend.log"
UV_BIN="${UV_BIN:-/Users/elijahakpan/.local/bin/uv}"
MODEL="${OPENJARVIS_MODEL:-qwen3.5:4b}"

if [ ! -d "$PROJECT_DIR" ]; then
	/usr/bin/osascript -e 'display alert "OpenJarvis folder not found" message "Check the project path in launch_jarvis.sh." as critical'
	exit 1
fi

cd "$PROJECT_DIR" || exit 1
printf '[%s] Launcher started\n' "$(date '+%Y-%m-%d %H:%M:%S')" >>"$PROJECT_DIR/launcher.log"

port_is_listening() {
	/usr/sbin/lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

if ! port_is_listening "$BACKEND_PORT"; then
	printf '[%s] Starting backend\n' "$(date '+%Y-%m-%d %H:%M:%S')" >>"$PROJECT_DIR/launcher.log"
	nohup "$UV_BIN" run jarvis serve --model "$MODEL" \
		>>"$BACKEND_LOG" 2>&1 < /dev/null &
fi

if ! port_is_listening "$FRONTEND_PORT"; then
	printf '[%s] Starting frontend\n' "$(date '+%Y-%m-%d %H:%M:%S')" >>"$PROJECT_DIR/launcher.log"
	nohup /usr/local/bin/npm run dev --prefix frontend \
		>>"$FRONTEND_LOG" 2>&1 < /dev/null &
fi

for _ in {1..30}; do
		backend_ready=false
		frontend_ready=false
		if /usr/bin/curl -fsS --max-time 2 "http://127.0.0.1:$BACKEND_PORT/health" >/dev/null 2>&1; then
			backend_ready=true
	fi
		if port_is_listening "$FRONTEND_PORT"; then
			frontend_ready=true
		fi
		if $backend_ready && $frontend_ready; then
			printf '[%s] Backend and frontend ready; opening browser\n' "$(date '+%Y-%m-%d %H:%M:%S')" >>"$PROJECT_DIR/launcher.log"
			/usr/bin/open "http://localhost:$FRONTEND_PORT"
			exit 0
		fi
		sleep 1
done

/usr/bin/osascript -e 'display alert "OpenJarvis did not start" message "Check launcher.log, frontend.log, and backend.log in the OpenJarvis folder." as critical'
exit 1
