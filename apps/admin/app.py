import streamlit as st
import os

# Set page configuration
st.set_page_config(
    page_title="Admin App",
    page_icon="⚙️",
    layout="wide"
)

# Get configuration from environment or config
app_config = {
    "app_name": os.getenv("APP_NAME", "Admin"),
    "environment": os.getenv("ENVIRONMENT", "development"),
    "version": os.getenv("APP_VERSION", "1.0.0"),
    "admin_email": os.getenv("ADMIN_EMAIL", "admin@example.com")
}

# Main title
st.title(f"⚙️ {app_config['app_name']} Application")

# Display app info with security indicator
col1, col2, col3 = st.columns(3)

with col1:
    st.metric("Environment", app_config['environment'])
with col2:
    st.metric("Version", app_config['version'])
with col3:
    st.metric("Security", "🔒 Secured")

st.divider()

# Admin content
st.header("Administration Panel")

st.markdown("""
This is the **Admin** application - centralized system administration and management.

### Admin Features:
- 👥 User management
- 🔐 Security settings
- 📝 System configuration
- 📊 Resource monitoring
""")

# Warning banner
st.warning("⚠️ This is a protected area. Admin access required.")

# Admin tools
st.subheader("Admin Tools")

tabs = st.tabs(["Users", "Settings", "Monitoring", "Logs"])

with tabs[0]:
    st.subheader("User Management")

    user_action = st.selectbox(
        "Select action:",
        ["View Users", "Add User", "Edit User", "Delete User"]
    )

    if user_action == "Add User":
        with st.form("add_user_form"):
            username = st.text_input("Username")
            email = st.text_input("Email")
            role = st.selectbox("Role", ["Admin", "User", "Viewer"])
            submitted = st.form_submit_button("Add User")

            if submitted:
                st.success(f"✅ User '{username}' added successfully with role: {role}")

with tabs[1]:
    st.subheader("System Settings")

    st.checkbox("Enable email notifications", value=True)
    st.checkbox("Enable two-factor authentication", value=True)
    st.checkbox("Enable audit logging", value=True)

    st.slider("Session timeout (minutes)", 15, 120, 30)
    st.slider("Max concurrent users", 10, 1000, 100)

    if st.button("Save Settings"):
        st.success("✅ Settings saved successfully!")

with tabs[2]:
    st.subheader("System Monitoring")

    col1, col2, col3, col4 = st.columns(4)

    with col1:
        st.metric("CPU Usage", "45%", "-5%")
    with col2:
        st.metric("Memory", "2.1 GB", "+0.2 GB")
    with col3:
        st.metric("Active Users", "23", "+3")
    with col4:
        st.metric("Uptime", "99.9%", "+0.1%")

    st.info("System is running normally. All services operational.")

with tabs[3]:
    st.subheader("System Logs")

    log_level = st.selectbox("Log Level", ["All", "Info", "Warning", "Error"])

    st.code("""
[2024-01-15 10:30:45] INFO: User 'john.doe' logged in
[2024-01-15 10:31:12] INFO: Dashboard accessed by 'jane.smith'
[2024-01-15 10:32:00] WARNING: High memory usage detected
[2024-01-15 10:33:15] INFO: Configuration updated by admin
[2024-01-15 10:34:22] INFO: Backup completed successfully
    """, language="log")

# System status
st.divider()
st.subheader("System Status")

status_col1, status_col2, status_col3 = st.columns(3)

with status_col1:
    st.success("✅ Database: Connected")
    st.success("✅ Cache: Running")
with status_col2:
    st.success("✅ API: Operational")
    st.success("✅ Queue: Processing")
with status_col3:
    st.success("✅ Storage: Available")
    st.success("✅ Network: Stable")

# Footer
st.divider()
st.caption(f"Admin App v{app_config['version']} | Environment: {app_config['environment']} | Contact: {app_config['admin_email']}")
