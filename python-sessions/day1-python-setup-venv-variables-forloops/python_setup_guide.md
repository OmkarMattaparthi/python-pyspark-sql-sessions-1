# Python Setup Guide — Windows (Step by Step)

## 1. Install Python

1. Go to [python.org/downloads](https://www.python.org/downloads/) and download the latest Python 3.x installer.
2. Run the installer.
   - **Check "Add Python to PATH"** before clicking Install Now.
3. Verify the installation:

```powershell
python --version
pip --version
```

---

## 2. Install VS Code (Recommended IDE)

1. Download from [code.visualstudio.com](https://code.visualstudio.com/).
2. Install the **Python extension** (ms-python.python) from the Extensions panel.

---

## 3. Create a Project Folder

```powershell
mkdir my_project
cd my_project
```

---

## 4. Create a Virtual Environment (venv)

A virtual environment isolates your project's dependencies from the global Python installation.

```powershell
python -m venv venv
```

This creates a `venv/` folder inside your project.

---

## 5. Activate the Virtual Environment

**Windows (PowerShell):**
```powershell
.\venv\Scripts\Activate.ps1
```

**Windows (Command Prompt):**
```cmd
venv\Scripts\activate.bat
```

**macOS / Linux:**
```bash
source venv/bin/activate
```

After activation your prompt shows `(venv)` prefix:
```
(venv) PS C:\my_project>
```

---

## 6. Save Dependencies to requirements.txt

```powershell
pip freeze > requirements.txt
```

To re-install later (e.g., on another machine):
```powershell
pip install -r requirements.txt
```

---

## 8. Deactivate the Virtual Environment

```powershell
deactivate
```

---

## 9. Add venv to .gitignore

Never commit the `venv/` folder to Git:

```
# .gitignore
venv/
__pycache__/
*.pyc
.env
```

---

## 10. Quick Reference

| Task | Command |
|------|---------|
| Create venv | `python -m venv venv` |
| Activate (Windows PS) | `.\venv\Scripts\Activate.ps1` |
| Activate (Mac/Linux) | `source venv/bin/activate` |
| Install package | `pip install <package>` |
| Freeze deps | `pip freeze > requirements.txt` |
| Install from file | `pip install -r requirements.txt` |
| Deactivate | `deactivate` |

---

## 11. Clone This Repo (aug-batch branch) from GitHub

### Prerequisites
- Git installed: [git-scm.com/downloads](https://git-scm.com/downloads)
- Verify: `git --version`

### Step 1 — Clone the repository

```powershell
git clone https://github.com/hariom2311/python-pyspark-sql-sessions.git
```

This downloads the repo into a folder called `python-pyspark-sql-sessions/`.

### Step 2 — Move into the project folder

```powershell
cd python-pyspark-sql-sessions
```

### Step 3 — Switch to the aug-batch branch

```powershell
git checkout aug-batch
```

Verify you are on the right branch:

```powershell
git branch
# * aug-batch
```

### Step 4 — (Optional) Clone directly on the aug-batch branch in one command

```powershell
git clone -b aug-batch https://github.com/hariom2311/python-pyspark-sql-sessions.git
cd python-pyspark-sql-sessions
```

### Step 5 — Create and activate a venv inside the cloned folder

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

### Step 6 — Install dependencies (if requirements.txt exists)

```powershell
pip install -r requirements.txt
```

### Step 7 — Stay up to date (pull latest changes)

```powershell
git pull origin aug-batch
```

---

### Clone Quick Reference

| Task | Command |
|------|---------|
| Clone repo (default branch) | `git clone https://github.com/hariom2311/python-pyspark-sql-sessions.git` |
| Clone specific branch | `git clone -b aug-batch https://github.com/hariom2311/python-pyspark-sql-sessions.git` |
| Switch to branch after clone | `git checkout aug-batch` |
| Check current branch | `git branch` |
| Pull latest changes | `git pull origin aug-batch` |
