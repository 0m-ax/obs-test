#!/usr/bin/env bash
#
# livestream.sh - start/stop a Veo camera livestream
#
# Usage:
#   ./livestream.sh start-auto       Start livestream with AUTO corner selection
#   ./livestream.sh stop             Stop the livestream
#   ./livestream.sh start-manual     Create a stream, then start it with MANUAL corners

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration - edit these to match your setup
# ---------------------------------------------------------------------------

CAMERA_HOST="192.168.0.225:3000"
STREAM_URL="srt://192.168.0.163:1337"
STREAM_PARAMS="stream_key=publish/veocam&latency_ms=125&max_bitrate_kbps=8000&codec=h265"

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
	# Creates a livestream and echoes the cameraStreamSetupId (uuid) to stdout.
	local resp uuid
	resp="$(call CreateLiveStream '{}')"
	uuid="$(printf '%s' "$resp" | sed -n 's/.*"cameraStreamSetupId"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
	if [[ -z "$uuid" ]]; then
		echo "Error: could not parse cameraStreamSetupId from response:" >&2
		echo "$resp" >&2
		exit 1
	fi
	printf '%s\n' "$uuid"
}

cmd_start_manual() {
	echo "Creating livestream..." >&2
	local setup_id
	setup_id="$(cmd_create)"
	echo "Got cameraStreamSetupId=${setup_id}" >&2
	echo "Starting livestream (MANUAL corners)..." >&2
	call SetRecordingStateV2 '{"state": {"recording": {"cornerSelection":{"source": "MANUAL", "cornersRaw":{"nearLeft":'"${NEAR_LEFT}"',"nearRight":'"${NEAR_RIGHT}"',"farLeft":'"${FAR_LEFT}"',"farRight":'"${FAR_RIGHT}"'}, "cameraStreamSetupId":"'"${setup_id}"'"}, "liveStream": {"url": "'"${STREAM_URL}"'", "streamConfigurationParameters": "'"${STREAM_PARAMS}"'"}}}}'
	echo
	echo "Livestream started."
}

usage() {
	sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
}

main() {
	local cmd="${1:-}"
	[[ $# -gt 0 ]] && shift || true
	case "$cmd" in
		start-auto)   cmd_start ;;
		stop)         cmd_stop ;;
		start-manual) cmd_start_manual ;;
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
