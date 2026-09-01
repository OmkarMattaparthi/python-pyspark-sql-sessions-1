# PySpark Local Setup Guide

Complete step-by-step setup for running PySpark on your local machine.
Follow the section for your operating system.

---

## Table of Contents

- [Windows Setup](#windows-setup)
- [macOS Setup](#macos-setup)
- [Ubuntu / Debian Setup](#ubuntu--debian-setup)
- [Install PySpark (All OS)](#install-pyspark-all-os)
- [Verify Everything Works](#verify-everything-works)
- [Common Errors and Fixes](#common-errors-and-fixes)

---

## Windows Setup

### Step 1 — Install Java (JDK 11)

1. Open your browser and go to:
   **https://adoptium.net/temurin/releases/**

2. Set these filters on the page:
   - Version: **11 (LTS)**
   - OS: **Windows**
   - Architecture: **x64**
   - Package Type: **JDK**
   - File type: **.msi**

3. Click **Download** and run the `.msi` installer.

4. On the installer screen titled **"Custom Setup"**, make sure these two options are checked (they may be off by default):
   - **Set JAVA_HOME variable**
   - **JavaSoft (Oracle) registry keys**

   If you see them — enable them. If you don't see them — continue, you will set JAVA_HOME manually in the next step.

5. Click **Next** through the rest and finish the install.

---

### Step 2 — Find Your Java Installation Path

You need to know exactly where Java was installed.

Open **File Explorer** and check these common locations:

```
C:\Program Files\Eclipse Adoptium\jdk-11.x.x.x-hotspot\
C:\Program Files\Java\jdk-11\
C:\Program Files\Microsoft\jdk-11.x.x.x\
```

To confirm the right folder, look inside it — you should see a `bin` folder containing `java.exe`.

**Or find it automatically — open PowerShell and run:**

```powershell
Get-Command java | Select-Object -ExpandProperty Source
```

This prints something like:
```
C:\Program Files\Eclipse Adoptium\jdk-11.0.23.9-hotspot\bin\java.exe
```

Your Java home is everything **before** `\bin\java.exe`. In this example:
```
C:\Program Files\Eclipse Adoptium\jdk-11.0.23.9-hotspot
```

Write this path down — you need it in the next step.

---

### Step 3 — Set JAVA_HOME Environment Variable

1. Press `Windows + S` and search for **"Edit the system environment variables"** — click it.

2. In the System Properties window, click **"Environment Variables..."** at the bottom.

3. In the **"System variables"** section (bottom half of the window), click **"New..."**

4. Fill in:
   - **Variable name:** `JAVA_HOME`
   - **Variable value:** paste your Java path, e.g. `C:\Program Files\Eclipse Adoptium\jdk-11.0.23.9-hotspot`

5. Click **OK**.

6. Now in the same **"System variables"** section, find the variable named **`Path`** and double-click it.

7. Click **"New"** and add:
   ```
   %JAVA_HOME%\bin
   ```

8. Click **OK** on all open windows.

---

### Step 4 — Verify Java

**Close all open PowerShell / Command Prompt windows** (environment variables only load in new terminals).

Open a **new PowerShell** and run:

```powershell
java -version
```

Expected output:
```
openjdk version "11.0.23" 2024-04-16
OpenJDK Runtime Environment Temurin-11.0.23+9 (build 11.0.23+9)
OpenJDK 64-Bit Server VM Temurin-11.0.23+9 (build 11.0.23+9, mixed mode)
```

```powershell
echo $env:JAVA_HOME
```

Expected output (your path):
```
C:\Program Files\Eclipse Adoptium\jdk-11.0.23.9-hotspot
```

If both commands give the right output — Java is ready.

---

### Step 5 — Install Python 3.11

If Python is not already installed:

1. Go to: **https://www.python.org/downloads/release/python-3119/**
2. Download **"Windows installer (64-bit)"**
3. Run the installer
4. On the first screen, check **"Add Python 3.11 to PATH"** before clicking Install Now
5. After install, open a new PowerShell and verify:

```powershell
python --version
```

Expected: `Python 3.11.x`

Note your Python path — you need it for PySpark config:

```powershell
python -c "import sys; print(sys.executable)"
```

Example output:
```
C:\Users\YourName\AppData\Local\Programs\Python\Python311\python.exe
```

---

### Step 6 — Install PySpark

```powershell
pip install pyspark==3.5.6 pandas==1.5.3 pyarrow==24.0.0 numpy==1.23.5
```

---

### Step 7 — Set Environment Variables in Your Script

At the very top of every PySpark script (before any pyspark import), add:

```python
import os

os.environ['JAVA_HOME']             = r'C:\Program Files\Eclipse Adoptium\jdk-11.0.23.9-hotspot'
os.environ['PYSPARK_PYTHON']        = r'C:\Users\YourName\AppData\Local\Programs\Python\Python311\python.exe'
os.environ['PYSPARK_DRIVER_PYTHON'] = r'C:\Users\YourName\AppData\Local\Programs\Python\Python311\python.exe'
```

Replace the paths with the actual paths you found in Steps 2 and 5.

---

---

## macOS Setup

### Step 1 — Install Homebrew (if not already installed)

Homebrew is the standard package manager for macOS. Open **Terminal** and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the prompts. After install, close and reopen Terminal.

Verify:
```bash
brew --version
```

---

### Step 2 — Install Java 11

```bash
brew install openjdk@11
```

After install, Homebrew will print a message like:

```
For the system Java wrappers to find this JDK, symlink it with
  sudo ln -sfn /opt/homebrew/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
```

Run that `sudo ln -sfn ...` command it shows you.

---

### Step 3 — Find Your JAVA_HOME Path

Run this in Terminal:

```bash
/usr/libexec/java_home -v 11
```

It will print your exact Java home path, for example:

**On Apple Silicon (M1/M2/M3):**
```
/opt/homebrew/opt/openjdk@11
```

**On Intel Mac:**
```
/usr/local/opt/openjdk@11
```

Write this path down.

---

### Step 4 — Set JAVA_HOME Permanently

Find out which shell you use:

```bash
echo $SHELL
```

- If it prints `/bin/zsh` → edit `~/.zshrc`
- If it prints `/bin/bash` → edit `~/.bash_profile`

Open the file (example for zsh):

```bash
nano ~/.zshrc
```

Add these lines at the bottom (replace the path with what you got in Step 3):

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 11)
export PATH="$JAVA_HOME/bin:$PATH"
```

Save: press `Ctrl+X`, then `Y`, then `Enter`.

Apply the changes:

```bash
source ~/.zshrc
# or
source ~/.bash_profile
```

---

### Step 5 — Verify Java

```bash
java -version
echo $JAVA_HOME
```

Expected:
```
openjdk version "11.x.x" ...
/opt/homebrew/opt/openjdk@11    (or your path)
```

---

### Step 6 — Install Python 3.11

Check if Python 3.11 is already installed:

```bash
python3 --version
```

If not, install via Homebrew:

```bash
brew install python@3.11
```

After install:

```bash
python3.11 --version
```

Find your Python path:

```bash
which python3.11
```

Example output:
```
/opt/homebrew/bin/python3.11
```

---

### Step 7 — Install PySpark

```bash
pip3.11 install pyspark==3.5.6 pandas==1.5.3 pyarrow==24.0.0 numpy==1.23.5
```

Or if your pip is already linked to Python 3.11:

```bash
pip install pyspark==3.5.6 pandas==1.5.3 pyarrow==24.0.0 numpy==1.23.5
```

---

### Step 8 — Set Environment Variables in Your Script

At the top of every PySpark script:

```python
import os

os.environ['JAVA_HOME']             = '/opt/homebrew/opt/openjdk@11'   # your path from Step 3
os.environ['PYSPARK_PYTHON']        = '/opt/homebrew/bin/python3.11'   # your path from Step 6
os.environ['PYSPARK_DRIVER_PYTHON'] = '/opt/homebrew/bin/python3.11'
```

---

---

## Ubuntu / Debian Setup

### Step 1 — Update Package List

Open Terminal and run:

```bash
sudo apt update && sudo apt upgrade -y
```

---

### Step 2 — Install Java 11

```bash
sudo apt install -y openjdk-11-jdk
```

Verify:

```bash
java -version
```

Expected:
```
openjdk version "11.x.x" ...
```

---

### Step 3 — Find Your JAVA_HOME Path

```bash
readlink -f $(which java)
```

This gives something like:
```
/usr/lib/jvm/java-11-openjdk-amd64/bin/java
```

Remove `/bin/java` from the end. Your JAVA_HOME is:
```
/usr/lib/jvm/java-11-openjdk-amd64
```

You can also run this to confirm all installed JVMs:

```bash
update-java-alternatives --list
```

---

### Step 4 — Set JAVA_HOME Permanently

Open your shell config file:

```bash
nano ~/.bashrc
```

Add these lines at the bottom:

```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH="$JAVA_HOME/bin:$PATH"
```

Save: `Ctrl+X` → `Y` → `Enter`

Apply:

```bash
source ~/.bashrc
```

Verify:

```bash
echo $JAVA_HOME
java -version
```

---

### Step 5 — Install Python 3.11

Check if already installed:

```bash
python3 --version
```

If not on 3.11, install it:

```bash
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3.11-dev
```

Verify:

```bash
python3.11 --version
```

Find your Python path:

```bash
which python3.11
```

Example:
```
/usr/bin/python3.11
```

---

### Step 6 — Install pip for Python 3.11

```bash
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11
```

Verify:

```bash
python3.11 -m pip --version
```

---

### Step 7 — Install PySpark

```bash
python3.11 -m pip install pyspark==3.5.6 pandas==1.5.3 pyarrow==24.0.0 numpy==1.23.5
```

---

### Step 8 — Set Environment Variables in Your Script

At the top of every PySpark script:

```python
import os

os.environ['JAVA_HOME']             = '/usr/lib/jvm/java-11-openjdk-amd64'   # your path from Step 3
os.environ['PYSPARK_PYTHON']        = '/usr/bin/python3.11'                   # your path from Step 5
os.environ['PYSPARK_DRIVER_PYTHON'] = '/usr/bin/python3.11'
```

---

---

## Install PySpark (All OS)

### Option A — Global install (simplest)

```bash
pip install pyspark==3.5.6 pandas==1.5.3 pyarrow==24.0.0 numpy==1.23.5
```

### Option B — Virtual environment (recommended)

Using a virtual environment keeps this project's dependencies separate from other Python projects.

**Windows:**
```powershell
python -m venv pyspark-venv
pyspark-venv\Scripts\activate
pip install pyspark==3.5.6 pandas==1.5.3 pyarrow==24.0.0 numpy==1.23.5
```

**macOS / Ubuntu:**
```bash
python3.11 -m venv pyspark-venv
source pyspark-venv/bin/activate
pip install pyspark==3.5.6 pandas==1.5.3 pyarrow==24.0.0 numpy==1.23.5
```

To deactivate the venv when done:
```bash
deactivate
```

### Packages and why we install them

| Package | Version | Why |
|---|---|---|
| `pyspark` | 3.5.6 | The Spark engine itself |
| `pandas` | 1.5.3 | Convert Spark DataFrames to Pandas for display |
| `pyarrow` | 24.0.0 | Fast columnar data transfer between Spark and Pandas |
| `numpy` | 1.23.5 | Required by pandas 1.5.3 (newer numpy breaks it) |

---

---

## Verify Everything Works

Create a file called `verify_spark.py` and paste this code — replace the paths with your own from the setup steps above:

```python
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

# --- REPLACE THESE WITH YOUR ACTUAL PATHS ---

# Windows example:
# os.environ['JAVA_HOME']      = r'C:\Program Files\Eclipse Adoptium\jdk-11.0.23.9-hotspot'
# os.environ['PYSPARK_PYTHON'] = r'C:\Users\YourName\AppData\Local\Programs\Python\Python311\python.exe'

# macOS example:
# os.environ['JAVA_HOME']      = '/opt/homebrew/opt/openjdk@11'
# os.environ['PYSPARK_PYTHON'] = '/opt/homebrew/bin/python3.11'

# Ubuntu example:
# os.environ['JAVA_HOME']      = '/usr/lib/jvm/java-11-openjdk-amd64'
# os.environ['PYSPARK_PYTHON'] = '/usr/bin/python3.11'

os.environ['PYSPARK_DRIVER_PYTHON'] = os.environ['PYSPARK_PYTHON']

# ----------------------------------------

from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("VerifyInstall") \
    .master("local[*]") \
    .config("spark.sql.shuffle.partitions", "4") \
    .config("spark.ui.showConsoleProgress", "false") \
    .getOrCreate()

spark.sparkContext.setLogLevel("ERROR")

data = [("Alice", 30), ("Bob", 25), ("Carol", 35)]
df = spark.createDataFrame(data, ["name", "age"])

df.show()
df.printSchema()
print(f"Row count: {df.count()}")
print(f"Spark version: {spark.version}")

spark.stop()
print("PySpark is working correctly!")
```

Run it:

```bash
# Windows
python verify_spark.py

# macOS / Ubuntu
python3.11 verify_spark.py
```

Expected output:
```
+-----+---+
| name|age|
+-----+---+
|Alice| 30|
|  Bob| 25|
|Carol| 35|
+-----+---+

root
 |-- name: string (nullable = true)
 |-- age: integer (nullable = true)

Row count: 3
Spark version: 3.5.6
PySpark is working correctly!
```

---

---

## Common Errors and Fixes

### Error: `JAVA_HOME is not set` or `java not found`

| OS | Fix |
|---|---|
| Windows | Set JAVA_HOME in System Variables (Step 3 above). Open a **new** terminal after setting it. |
| macOS | Add `export JAVA_HOME=...` to `~/.zshrc` and run `source ~/.zshrc` |
| Ubuntu | Add `export JAVA_HOME=...` to `~/.bashrc` and run `source ~/.bashrc` |

Always open a **new terminal** after changing environment variables — existing terminals do not pick up changes.

---

### Error: `No module named 'pyspark'`

PySpark is not installed in the Python environment your script is using.

```bash
pip install pyspark==3.5.6
```

If you are using a virtual environment, make sure it is activated before running your script.

---

### Error: `ValueError: numpy.dtype size changed`

```
ValueError: numpy.dtype size changed, may indicate binary incompatibility
```

This means numpy is too new for the version of pandas installed.

Fix:
```bash
pip install numpy==1.23.5
```

---

### Error: `Port 4040 already in use`

A previous Spark session is still running in another script or notebook.

Fix: Add `spark.stop()` at the end of your scripts. Or restart your terminal / Jupyter kernel.

---

### Error: `Py4JJavaError` or `JVM not found`

Java is not being found at runtime even if installed.

Fix: Set `JAVA_HOME` explicitly in your script before importing pyspark:

```python
import os
os.environ['JAVA_HOME'] = '/your/java/path'   # must be before pyspark import

from pyspark.sql import SparkSession
```

---

### Spark starts slowly (first run takes 30-60 seconds)

This is normal. Spark initialises the JVM and loads its JAR files on the first start. Subsequent runs in the same session are fast.

---

## Quick Reference — Finding Paths

| What | Windows | macOS | Ubuntu |
|---|---|---|---|
| Find Java path | `Get-Command java \| Select -Expand Source` | `/usr/libexec/java_home -v 11` | `readlink -f $(which java)` |
| Find Python path | `python -c "import sys; print(sys.executable)"` | `which python3.11` | `which python3.11` |
| Check JAVA_HOME | `echo $env:JAVA_HOME` | `echo $JAVA_HOME` | `echo $JAVA_HOME` |
| Check PySpark version | `python -c "import pyspark; print(pyspark.__version__)"` | same with `python3.11` | same with `python3.11` |
