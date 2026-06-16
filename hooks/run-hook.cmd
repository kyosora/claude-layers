: << 'CMDBLOCK'
@echo off
REM Polyglot wrapper: runs .sh hook scripts cross-platform (CMD + bash).
REM Usage: run-hook.cmd <script-name> [args...]  (script sits beside this file)
REM Windows needs Git for Windows; adjust the path if Git is installed elsewhere.

"C:\Program Files\Git\bin\bash.exe" -l "%~dp0%~1"
exit /b
CMDBLOCK

# Unix shell runs from here
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift
"${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
