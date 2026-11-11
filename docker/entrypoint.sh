#!/usr/bin/env bash
set -euo pipefail


copy_paho_layer() {
    local args=("$@")
    local i
    for ((i = 0; i < ${#args[@]}; i++)); do
        if [[ "${args[i]}" == "--output" && -n "${args[i+1]:-}" ]]; then
            local out="${args[i+1]}"
            mkdir -p "${out}"
            if [[ ! -f "${out}/paho_layer.zip" ]]; then
                cp "${APP_HOME}/paho_layer.zip" "${out}/paho_layer.zip"
            fi
        fi
    done
}

case "${1:-generate}" in
    generate)
        if [[ $# -gt 0 ]]; then
            shift
        fi
        copy_paho_layer "$@"
        cd "${APP_HOME}/src"
        exec python main.py "$@"
        ;;
    terraform)
        shift
        exec terraform "$@"
        ;;
    *)
        exec "$@"
        ;;
esac