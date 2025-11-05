import streamlit as st
import os

# Set page configuration
st.set_page_config(
    page_title="Dashboard App",
    page_icon="📊",
    layout="wide"
)

# Get configuration from environment or config
app_config = {
    "app_name": os.getenv("APP_NAME", "Dashboard"),
    "environment": os.getenv("ENVIRONMENT", "development"),
    "version": os.getenv("APP_VERSION", "1.0.0")
}

# Main title
st.title(f"📊 {app_config['app_name']} Application")

# Display app info
col1, col2, col3 = st.columns(3)

with col1:
    st.metric("Environment", app_config['environment'])
with col2:
    st.metric("Version", app_config['version'])
with col3:
    st.metric("Status", "🟢 Running")

st.divider()

# Dashboard content
st.header("Welcome to the Dashboard")

st.markdown("""
This is the **Dashboard** application - one of multiple Streamlit apps deployed via GitOps.

### Features:
- 📈 Real-time metrics and analytics
- 📊 Interactive visualizations
- 🔄 Auto-updating data
- 🎯 Performance monitoring
""")

# Interactive section
st.subheader("Quick Stats")

col1, col2, col3, col4 = st.columns(4)
with col1:
    st.metric("Total Users", "1,234", "+12%")
with col2:
    st.metric("Active Sessions", "89", "-3%")
with col3:
    st.metric("Response Time", "45ms", "-8%")
with col4:
    st.metric("Success Rate", "99.8%", "+0.2%")

# User input
st.divider()
st.subheader("Dashboard Settings")

time_range = st.selectbox(
    "Select time range:",
    ["Last hour", "Last 24 hours", "Last 7 days", "Last 30 days"]
)

if st.button("Refresh Data"):
    st.success(f"Dashboard data refreshed for: {time_range}")
    st.balloons()

# Footer
st.divider()
st.caption(f"Dashboard App v{app_config['version']} | Environment: {app_config['environment']}")
