import subprocess
import os

# --- CONFIGURATION ---
# Replace this with your ACTUAL GitHub HTTPS URL
REPO_URL = "https://github.com/JuanMunozEscobar/who-healthcare.git"
COMMIT_MESSAGE = "added who healthcare data cleaning script via python"
# ---------------------

def run_git_command(command):
    try:
        result = subprocess.run(command, check=True, text=True, capture_output=True)
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error running {' '.join(command)}:\n{e.stderr}")
        exit(1)

print("🚀 Starting GitHub upload process via Python...")

if not os.path.exists(".git"):
    run_git_command(["git", "init"])

run_git_command(["git", "add", "."])
run_git_command(["git", "commit", "-m", COMMIT_MESSAGE])
run_git_command(["git", "branch", "-M", "main"])

try:
    subprocess.run(["git", "remote", "add", "origin", REPO_URL], check=True, capture_output=True)
except subprocess.CalledProcessError:
    subprocess.run(["git", "remote", "set-url", "origin", REPO_URL], check=True)

print("Uploading files to GitHub...")
run_git_command(["git", "push", "-u", "origin", "main"])

print("✅ Upload complete! Refresh your GitHub page.")