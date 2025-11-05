#!/bin/bash
set -e

# Default app if not specified
APP_NAME=${APP_NAME:-dashboard}

# Check if app directory exists
if [ ! -d "/app/apps/${APP_NAME}" ]; then
    echo "Error: App '${APP_NAME}' not found in /app/apps/"
    echo "Available apps:"
    ls -1 /app/apps/
    exit 1
fi

# Check if app.py exists
if [ ! -f "/app/apps/${APP_NAME}/app.py" ]; then
    echo "Error: app.py not found in /app/apps/${APP_NAME}/"
    exit 1
fi

echo "========================================="
echo "Starting Streamlit App: ${APP_NAME}"
echo "Version: ${APP_VERSION:-1.0.0}"
echo "Environment: ${ENVIRONMENT:-development}"
echo "========================================="

# Change to app directory and run Streamlit
cd "/app/apps/${APP_NAME}"

# Export environment variables for the app
export APP_NAME
export APP_VERSION
export ENVIRONMENT

# Run Streamlit with the app
exec streamlit run app.py \
    --server.port=${STREAMLIT_SERVER_PORT:-8501} \
    --server.address=${STREAMLIT_SERVER_ADDRESS:-0.0.0.0} \
    --server.headless=${STREAMLIT_SERVER_HEADLESS:-true} \
    --browser.gatherUsageStats=${STREAMLIT_BROWSER_GATHER_USAGE_STATS:-false}
