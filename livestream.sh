#!/usr/bin/env bash
#
# livestream.sh - start/stop a Veo camera livestream
#
# Usage:
#   ./livestream.sh start            Start livestream with AUTO corner selection
#   ./livestream.sh stop             Stop the livestream
#   ./livestream.sh create           Create a livestream and print its cameraStreamSetupId
#   ./livestream.sh start-manual     Start livestream with MANUAL corners
#                                    (set STREAM_SETUP_ID below, or pass as arg)
#
# Examples:
#   ./livestream.sh start
#   ./livestream.sh create
#   ./livestream.sh start-manual 967f4244-8c3c-44d7-a018-cfac8d1cfdc7

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration - edit these to match your setup
# ---------------------------------------------------------------------------

CAMERA_HOST="192.168.0.225:3000"
STREAM_URL="srt://192.168.0.163:1337"
STREAM_PARAMS="stream_key=publish/veocam&latency_ms=125&max_bitrate_kbps=8000&codec=h265"

# cameraStreamSetupId used by start-manual. Obtain one via `create`.
# Can be overridden by passing it as the first argument to start-manual.
STREAM_SETUP_ID="967f4244-8c3c-44d7-a018-cfac8d1cfdc7"

# Manual corner coordinates [x, y]. Edit as needed.
NEAR_LEFT="[0.0,0.0]"
NEAR_RIGHT="[0.1,0.1]"
FAR_LEFT="[0.2,0.2]"
FAR_RIGHT="[0.3,0.3]"

# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

API_BASE="http://${CAMERA_HOST}/CameraService"

call() {
	# call <endpoint> <json-body>
	curl -fsS -X POST "${API_BASE}/$1" \
		-H "Content-Type: application/json" \
		-d "$2"
}

cmd_start() {
	echo "Starting livestream (AUTO corners)..."
	call SetRecordingStateV2 '{"state": {"recording": {"cornerSelection":{"source": "AUTO"}, "liveStream": {"url": "'"${STREAM_URL}"'", "streamConfigurationParameters": "'"${STREAM_PARAMS}"'"}}}}'
	echo
	echo "Livestream started."
}

cmd_stop() {
	echo "Stopping livestream..."
	call SetRecordingStateV2 '{}'
	echo
	echo "Livestream stopped."
}

cmd_create() {
	echo "Creating livestream..."
	call CreateLiveStream '{}'
	echo
	echo "Use the cameraStreamSetupId above for start-manual."
}

cmd_start_manual() {
	local setup_id="${1:-$STREAM_SETUP_ID}"
	if [[ -z "$setup_id" ]]; then
		echo "Error: no cameraStreamSetupId set. Run 'create' first, then pass it or set STREAM_SETUP_ID." >&2
		exit 1
	fi
	echo "Starting livestream (MANUAL corners, setupId=${setup_id})..."
	call SetRecordingStateV2 '{"state": {"recording": {"cornerSelection":{"source": "MANUAL", "cornersRaw":{"nearLeft":'"${NEAR_LEFT}"',"nearRight":'"${NEAR_RIGHT}"',"farLeft":'"${FAR_LEFT}"',"farRight":'"${FAR_RIGHT}"'}, "cameraStreamSetupId":"'"${setup_id}"'"}, "liveStream": {"url": "'"${STREAM_URL}"'", "streamConfigurationParameters": "'"${STREAM_PARAMS}"'"}}}}'
	echo
	echo "Livestream started."
}

usage() {
	sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
}

main() {
	local cmd="${1:-}"
	[[ $# -gt 0 ]] && shift || true
	case "$cmd" in
		start|start-auto) cmd_start ;;
		stop)             cmd_stop ;;
		create)           cmd_create ;;
		start-manual)     cmd_start_manual "$@" ;;
		-h|--help|help|"") usage ;;
		*)
			echo "Unknown command: $cmd" >&2
			echo >&2
			usage
			exit 1
			;;
	esac
}

main "$@"
