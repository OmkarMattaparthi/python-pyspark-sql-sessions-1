# Jupyter Notebook Setup for PySpark

---

## Table of Contents
1. [What is Jupyter Notebook](#1-what-is-jupyter-notebook)
2. [Windows Installation](#2-windows-installation)
3. [macOS Installation](#3-macos-installation)
4. [Ubuntu Installation](#4-ubuntu-installation)
5. [Running PySpark inside Jupyter](#5-running-pyspark-inside-jupyter)
6. [Jupyter Basics — Keyboard Shortcuts](#6-jupyter-basics--keyboard-shortcuts)
7. [Recommended Extensions](#7-recommended-extensions)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. What is Jupyter Notebook

Jupyter Notebook is a browser-based interactive environment where you can write and run Python (or PySpark) code one cell at a time and see output immediately below each cell.

### Notebook vs Script

| | Script (.py) | Jupyter Notebook (.ipynb) |
|---|---|---|
| Run style | All at once | Cell by cell |
| Output | Terminal | Inline below cell |
| Best for | Production jobs | Exploration, learning, demos |
| Restart cost | Re-run full file | Re-run only changed cells |

### JupyterLab vs Jupyter Notebook

| | Jupyter Notebook | JupyterLab |
|---|---|---|
| Interface | Single notebook tab | Full IDE-like layout |
| File browser | Basic | Built-in sidebar |
| Extensions | Limited | Rich ecosystem |
| Recommendation | Fine for learning | Better for real work |

We will install **JupyterLab** — it includes the classic notebook UI as well.

---

## 2. Windows Installation

### Step 1 — Activate your PySpark venv

Open PowerShell and navigate to the project folder:

```powershell
cd C:\Users\<your-username>\Downloads\python-pyspark-sql-sessions\pyspark-sessions
.\.venv\Scripts\Activate.ps1
```

You should see `(.venv)` at the start of your prompt.

If you get a script execution error, run this first (one time only):

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 2 — Install JupyterLab

```powershell
pip install jupyterlab
```

### Step 3 — Verify installation

```powershell
jupyter --version
```

Expected output (versions may differ):

```
jupyter_core      : 5.x.x
jupyterlab        : 4.x.x
notebook          : 7.x.x
```

### Step 4 — Launch JupyterLab

```powershell
jupyter lab
```

This opens your browser at `http://localhost:8888/lab`.  
Keep the PowerShell window open — closing it stops the server.

### Step 5 — Create a new notebook

In the JupyterLab launcher tab, click **Python 3 (ipykernel)** under Notebook.  
A new `.ipynb` file opens ready to run code.

### Step 6 — Stop the server

Press `Ctrl + C` twice in PowerShell, or close the PowerShell window.

---

## 3. macOS Installation

### Step 1 — Activate your venv

```bash
cd ~/Downloads/python-pyspark-sql-sessions/pyspark-sessions
source .venv/bin/activate
```

### Step 2 — Install JupyterLab

```bash
pip install jupyterlab
```

### Step 3 — Verify

```bash
jupyter --version
```

### Step 4 — Launch

```bash
jupyter lab
```

Browser opens at `http://localhost:8888/lab`.

### Step 5 — Stop

Press `Ctrl + C` in the terminal, or type `q` when prompted.

---

## 4. Ubuntu Installation

### Step 1 — Activate your venv

```bash
cd ~/python-pyspark-sql-sessions/pyspark-sessions
source .venv/bin/activate
```

### Step 2 — Install JupyterLab

```bash
pip install jupyterlab
```

### Step 3 — Verify

```bash
jupyter --version
```

### Step 4 — Launch

```bash
jupyter lab
```

If the browser does not open automatically, copy the URL printed in the terminal (starts with `http://127.0.0.1:8888/lab?token=...`) and paste it into your browser.

### Step 5 — Stop

`Ctrl + C` in the terminal.

---

## 5. Running PySpark inside Jupyter

### The environment variable problem

PySpark needs `JAVA_HOME` and `PYSPARK_PYTHON` set **before** the Spark import. In a `.py` script you do this at the top of the file. In a notebook, put these in the **first cell** and run it before any other cell.

### Template — first cell of every PySpark notebook

```python
import os
import sys

os.environ['JAVA_HOME']             = 'C:/Program Files/DBeaver/jre'   # Windows
os.environ['PYSPARK_PYTHON']        = sys.executable
os.environ['PYSPARK_DRIVER_PYTHON'] = sys.executable

from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Notebook") \
    .master("local[*]") \
    .config("spark.sql.shuffle.partitions", "4") \
    .config("spark.ui.showConsoleProgress", "false") \
    .getOrCreate()

spark.sparkContext.setLogLevel("ERROR")
print(f"Spark {spark.version} ready")
```

> **Why `sys.executable` for PYSPARK_PYTHON?**  
> When Jupyter is launched from inside your venv, `sys.executable` already points to the venv's Python. This makes the notebook portable — you don't need to hard-code your username or path.

### macOS / Ubuntu — first cell

```python
import os
import sys

os.environ['JAVA_HOME'] = '/usr/lib/jvm/java-11-openjdk-amd64'  # Ubuntu
# os.environ['JAVA_HOME'] = '/usr/local/opt/openjdk@11'          # macOS Homebrew
os.environ['PYSPARK_PYTHON']        = sys.executable
os.environ['PYSPARK_DRIVER_PYTHON'] = sys.executable

from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Notebook") \
    .master("local[*]") \
    .config("spark.sql.shuffle.partitions", "4") \
    .getOrCreate()

spark.sparkContext.setLogLevel("ERROR")
print(f"Spark {spark.version} ready")
```

### Always stop Spark in the last cell

```python
spark.stop()
```

Forgetting this leaves the SparkContext running. If you restart the kernel and create a new session, you may hit "Cannot run multiple SparkContexts" errors.

### Restart kernel = fresh SparkSession

If something goes wrong, go to **Kernel → Restart Kernel and Clear All Outputs**, then re-run from the first cell.

---

## 6. Jupyter Basics — Keyboard Shortcuts

### Two modes

| Mode | Indicator | How to enter |
|---|---|---|
| **Command mode** | Blue cell border | `Esc` |
| **Edit mode** | Green cell border | `Enter` or click inside cell |

### Essential shortcuts

| Shortcut | What it does |
|---|---|
| `Shift + Enter` | Run current cell, move to next |
| `Ctrl + Enter` | Run current cell, stay on it |
| `Alt + Enter` | Run current cell, insert new cell below |
| `A` (command mode) | Insert cell **above** |
| `B` (command mode) | Insert cell **below** |
| `DD` (command mode) | Delete current cell |
| `M` (command mode) | Change cell to Markdown |
| `Y` (command mode) | Change cell to Code |
| `Z` (command mode) | Undo cell deletion |
| `Ctrl + Z` (edit mode) | Undo text edit |
| `Tab` (edit mode) | Autocomplete |
| `Shift + Tab` (edit mode) | Show function signature/docstring |
| `Ctrl + /` (edit mode) | Toggle comment |
| `Ctrl + S` | Save notebook |
| `0 0` (command mode) | Restart kernel |

### Cell types

- **Code** — runs Python / PySpark
- **Markdown** — renders formatted text (headings, bold, tables)
- **Raw** — plain text, not rendered or executed

---

## 7. Recommended Extensions

Install these after `jupyterlab` is installed (still inside your venv):

```bash
pip install jupyterlab-lsp python-lsp-server   # code completion and error hints
pip install nbformat                            # notebook format utilities
```

For a table of contents sidebar (useful for long notebooks):

JupyterLab 4.x has a built-in Table of Contents panel — click the list icon in the left sidebar.

---

## 8. Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `jupyter: command not found` | venv not activated or not installed | Activate venv, then `pip install jupyterlab` |
| Browser does not open | Headless server or WSL | Copy the `http://127.0.0.1:8888/?token=...` URL from terminal and paste in browser |
| `Cannot run multiple SparkContexts` | Previous session not stopped | Kernel → Restart Kernel, re-run first cell |
| `JAVA_HOME not set` | env var missing | Add `os.environ['JAVA_HOME'] = '...'` before the SparkSession import |
| `py4j.protocol.Py4JError` | JVM crashed or wrong Java version | Check `JAVA_HOME` points to Java 8 or 11 (not 17+) |
| Notebook saves but kernel dies | Out of memory | Reduce data size or set `local[2]` instead of `local[*]` |
| Port 8888 already in use | Another Jupyter server running | `jupyter lab --port 8889` or kill the old process |
| `ModuleNotFoundError: pyspark` | Wrong Python kernel | Kernel → Change Kernel → Python (your venv path) |

### Check which Python the kernel is using

Run this in a notebook cell:

```python
import sys
print(sys.executable)
```

It should print the path inside your `.venv` folder. If it shows a system Python path, the kernel is not using your venv — restart Jupyter from inside the activated venv.
