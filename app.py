import streamlit as st

# Set page configuration
st.set_page_config(
    page_title="Hello OpenShift",
    page_icon="🚀",
    layout="centered"
)

# Main title
st.title("Hello OpenShift with Helm! 🚀")

# Add some description
st.markdown("""
This is a simple Streamlit application deployed on OpenShift using:
- **ArgoCD** for GitOps
- **Helm** for package management
- **OpenShift** for container orchestration
""")

# Add a divider
st.divider()

# Text input for user's name
user_name = st.text_input("Enter your name:", placeholder="Your name here...")

# Show welcome message when name is entered
if user_name:
    st.success(f"👋 Welcome, **{user_name}**! You're successfully running on OpenShift!")
    st.balloons()

    # Additional information
    st.info("""
    🎉 This application demonstrates:
    - GitOps deployment patterns
    - Containerized applications
    - Kubernetes/OpenShift integration
    - Helm chart templating
    """)

# Footer
st.divider()
st.caption("Deployed with ❤️ using GitOps practices")
