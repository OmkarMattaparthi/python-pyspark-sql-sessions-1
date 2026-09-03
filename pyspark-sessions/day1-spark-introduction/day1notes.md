# Day 1 — Apache Spark & PySpark Introduction

---

## Table of Contents
1. [The Problem Before Spark](#1-the-problem-before-spark)
2. [What is Apache Spark](#2-what-is-apache-spark)
3. [How Spark Works Internally](#3-how-spark-works-internally)
4. [Spark vs Pandas vs Hadoop](#4-spark-vs-pandas-vs-hadoop)
5. [Spark Ecosystem](#5-spark-ecosystem)
6. [Core Concepts You Must Know](#6-core-concepts-you-must-know)
7. [Cluster Architecture](#7-cluster-architecture)
8. [Windows Local Setup](#8-windows-local-setup)
9. [Verify Your Installation](#9-verify-your-installation)

---

## 1. The Problem Before Spark

### Era: Hadoop MapReduce (2006–2012)

Before Spark existed, big data was processed using **Hadoop MapReduce**.

**How MapReduce worked:**
```
Input Data (HDFS)
       |
    MAP phase      → Each node processes its chunk → emits key-value pairs
       |
  Shuffle & Sort   → Data moves across network, grouped by key
       |
  REDUCE phase     → Aggregation / final answer
       |
Output written to HDFS (disk)
```

**The problem:**
- Every intermediate result was written to **disk (HDFS)**
- Multi-step jobs (join → filter → aggregate → another join) wrote to disk between **every step**
- A 10-step ML algorithm = 10× read from disk + 10× write to disk
- Disk I/O is ~100× slower than RAM
- Writing a MapReduce job required Java + boilerplate even for simple tasks
- No support for streaming, interactive queries, or iterative algorithms (ML)

**Real-world pain:**
A logistic regression in Hadoop took hours because each iteration of gradient descent wrote intermediate data to disk. The same algorithm in-memory converges 10–100× faster.

---

## 2. What is Apache Spark

### Origin
- Started as a research project at **UC Berkeley AMPLab in 2009** by Matei Zaharia
- Paper published: "Resilient Distributed Datasets" (RDD) — 2012
- Donated to Apache Software Foundation in 2013
- Apache Spark **1.0** released in **2014**
- Today (2024): Spark **3.5+**, industry standard for large-scale data processing

### What Spark Is
Apache Spark is an **open-source, distributed computing engine** for large-scale data processing.

Key word: **distributed** — it splits your data across many machines and processes them in parallel.

Key word: **engine** — Spark does NOT store data. It reads from wherever data lives (S3, HDFS, databases, local files) and processes it.

### The Core Idea: Keep Data in Memory

```
Hadoop MapReduce:
  Step 1 → write disk → Step 2 → write disk → Step 3 → write disk

Apache Spark:
  Step 1 → Step 2 → Step 3  (all in RAM, disk only at start/end)
```

Spark can be **10–100× faster** than Hadoop MapReduce for iterative workloads (ML, graph processing) because intermediate results stay in RAM.

---

## 3. How Spark Works Internally

### 3.1 The Driver and Executors

```
Your Python Script (PySpark)
          |
       DRIVER
    (your laptop or master node)
    - Analyzes your code
    - Builds a logical plan
    - Optimizes it (Catalyst)
    - Schedules tasks
          |
    ------+------+------+------
    |           |           |
 EXECUTOR    EXECUTOR    EXECUTOR
(worker nodes — actually run the tasks on partitions of data)
```

- **Driver**: the brain — your Python script IS the driver
- **Executors**: the muscle — JVM processes that run on worker nodes
- **Tasks**: the unit of work — one task per partition per stage

### 3.2 Lazy Evaluation — THE Most Important Concept

Spark does **nothing** when you call transformations. It only runs when you call an **action**.

```python
df = spark.read.csv("data.csv")     # no work done yet
df2 = df.filter(df.age > 30)        # no work done yet — just a plan
df3 = df2.select("name", "salary")  # no work done yet — plan grows
df3.show()                          # NOW Spark runs everything in one pass
```

Why? Because Spark can **optimize the whole plan** before running anything.  
Example: if you filter 90% of rows and then join, Spark pushes the filter BEFORE the join — fewer rows to join = massive speedup. This is called **predicate pushdown**.

### 3.3 DAG — Directed Acyclic Graph

Spark converts your code into a **DAG of stages and tasks**.

```
read CSV
    |
  filter
    |
  groupBy
    |
    agg
    |
  show()  ← action triggers the DAG to execute
```

Each arrow is a transformation. The DAG is optimized by the **Catalyst optimizer** before execution.

### 3.4 Transformations vs Actions

| Type | What it does | Example | Triggers execution? |
|---|---|---|---|
| **Transformation** | Returns a new DataFrame | `filter`, `select`, `groupBy`, `join`, `withColumn` | No — lazy |
| **Action** | Returns a result or writes data | `show`, `count`, `collect`, `write` | Yes — runs the DAG |

**Narrow transformation**: each input partition maps to exactly one output partition (no shuffle needed)
- `filter`, `select`, `withColumn`, `map`

**Wide transformation**: output partitions depend on multiple input partitions (causes a shuffle)
- `groupBy`, `join`, `distinct`, `repartition`

Shuffles are expensive (network I/O). Minimize them.

### 3.5 Partitions

Spark splits data into **partitions** — chunks of data processed in parallel.

```
CSV file (1 GB)
  → Partition 1 (128 MB) → processed by Executor 1, Task 1
  → Partition 2 (128 MB) → processed by Executor 2, Task 2
  → Partition 3 (128 MB) → processed by Executor 1, Task 3
  → ...
```

- More partitions = more parallelism (up to a point)
- Too many partitions = overhead of scheduling tiny tasks
- Default: 200 partitions after a shuffle (`spark.sql.shuffle.partitions`)
- For local mode: set this to 4–8 (one per CPU core)

### 3.6 Catalyst Optimizer + Tungsten Engine

**Catalyst**: SQL/DataFrame query optimizer
- Parses your code → logical plan → optimized logical plan → physical plan
- Applies: predicate pushdown, column pruning, constant folding, join reordering

**Tungsten**: execution engine
- Whole-stage code generation (generates JVM bytecode at runtime)
- Off-heap memory management (bypasses Java GC overhead)
- Vectorized columnar execution

Together, these make Spark DataFrames faster than raw RDDs (even though RDDs are lower-level).

---

## 4. Spark vs Pandas vs Hadoop

| Feature | Pandas | Apache Spark | Hadoop MapReduce |
|---|---|---|---|
| **Data scale** | Up to ~10 GB (single machine RAM) | Terabytes to Petabytes | Petabytes |
| **Execution model** | Eager (runs immediately) | Lazy (builds plan, runs on action) | Batch (MapReduce jobs) |
| **Processing location** | Single machine, single core (mostly) | Distributed, multi-node cluster | Distributed, multi-node |
| **Speed** | Fast for small data | Fast for large data (in-memory) | Slow (disk-based between steps) |
| **API style** | Python-native, intuitive | DataFrame API (SQL-like) | Java/Python with boilerplate |
| **Iterative jobs (ML)** | Fine | 10–100× faster than Hadoop | Very slow (disk writes per iteration) |
| **Streaming** | Not built for it | Yes (Structured Streaming) | No |
| **SQL support** | Limited (query-like methods) | Full SQL via `spark.sql()` | Hive (slow) |
| **Setup complexity** | `pip install pandas` | Medium (JVM + Python) | High (full Hadoop cluster) |
| **Best for** | Data analysis, small datasets | Production ETL, large-scale ML | Cold storage batch jobs |

### When to use what?
- **Pandas**: exploration, prototyping, datasets that fit in memory (<10 GB)
- **Spark**: production pipelines, anything > memory, distributed compute
- **Hadoop (HDFS)**: Spark reads FROM Hadoop. MapReduce is largely replaced by Spark.

### Pandas vs Spark API comparison

```python
# Pandas
import pandas as pd
df = pd.read_csv("data.csv")
result = df[df["age"] > 30].groupby("dept")["salary"].mean()

# PySpark (equivalent)
from pyspark.sql import SparkSession
from pyspark.sql.functions import avg
spark = SparkSession.builder.getOrCreate()
df = spark.read.csv("data.csv", header=True, inferSchema=True)
result = df.filter(df.age > 30).groupBy("dept").agg(avg("salary"))
result.show()
```

The APIs look similar. The difference is Pandas runs on your laptop; PySpark runs across a cluster.

---

## 5. Spark Ecosystem

```
+----------------------------------------------------------+
|                    Your Application                       |
+----------------------------------------------------------+
|  Spark SQL  |  Streaming  |   MLlib    |   GraphX        |
+----------------------------------------------------------+
|              Spark Core (RDD, DAG, Scheduler)            |
+----------------------------------------------------------+
|  Local  |  YARN (Hadoop)  |  Kubernetes  |  Mesos       |
+----------------------------------------------------------+
|  HDFS  |  S3  |  Azure Blob  |  GCS  |  Local FS       |
+----------------------------------------------------------+
```

| Component | What it does |
|---|---|
| **Spark Core** | Foundation — scheduling, memory management, fault tolerance |
| **Spark SQL** | SQL queries + DataFrame API + Catalyst optimizer |
| **Structured Streaming** | Real-time stream processing (micro-batch or continuous) |
| **MLlib** | Distributed machine learning library |
| **GraphX** | Graph computation (PageRank, connected components) |

For data engineering: **Spark SQL + Spark Core** are what you'll use 90% of the time.

---

## 6. Core Concepts You Must Know

### 6.1 RDD vs DataFrame vs Dataset

| | RDD | DataFrame | Dataset |
|---|---|---|---|
| **Full name** | Resilient Distributed Dataset | DataFrame | Dataset[T] |
| **Introduced** | Spark 1.0 | Spark 1.3 | Spark 1.6 |
| **Type safety** | Yes (untyped in Python) | No (schema at runtime) | Yes (compile-time in Scala/Java) |
| **Optimization** | No Catalyst | Full Catalyst + Tungsten | Full Catalyst + Tungsten |
| **API** | Functional (map, filter, reduce) | SQL-like (select, filter, groupBy) | SQL-like + typed |
| **Use in PySpark** | Avoid (no type safety AND no optimization) | Default choice | Not available in Python |

**In PySpark, always use DataFrames.** RDDs exist but you will rarely write them directly.

### 6.2 SparkSession

The entry point to Spark. One per application.

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("MyApp") \
    .master("local[*]") \
    .getOrCreate()
```

- `appName`: name shown in Spark UI
- `master("local[*]")`: run locally using all available CPU cores
- `getOrCreate()`: returns existing session if one already exists

### 6.3 Schema

A DataFrame has a **schema** — column names + types. Like a database table definition.

```
root
 |-- name: string (nullable = true)
 |-- age: integer (nullable = true)
 |-- salary: double (nullable = true)
```

Spark can **infer** the schema (slower, reads data twice) or you can **define** it explicitly (faster, recommended in production).

---

## 7. Cluster Architecture

### Local Mode (what we use for learning)

```
Your Laptop
+-------------------------------------------+
|  Driver (your Python process)             |
|  + Executors (simulated in same JVM)      |
|  master = "local[*]" → uses all cores     |
+-------------------------------------------+
```

### Cluster Mode (production)

```
         Client Machine
              |
           Driver
              |
      Cluster Manager
     (YARN / Kubernetes)
      /       |       \
 Executor  Executor  Executor
 (Worker)  (Worker)  (Worker)
```

**Cluster managers:**
- **local[N]**: N threads on your machine (for development)
- **YARN**: Hadoop's resource manager (on-premise clusters)
- **Kubernetes**: container-based clusters (AWS EKS, GKE, AKS)
- **Databricks**: managed Spark (cloud, most common in industry)

---

## 8. Windows Local Setup

### Step 1: Java — Already Available via DBeaver

This machine uses the **JRE bundled with DBeaver** as the Java runtime for Spark.

Path: `C:/Program Files/DBeaver/jre`

No separate Java installation needed. Set `JAVA_HOME` in your script before importing PySpark:

```python
import os
os.environ['JAVA_HOME'] = 'C:/Program Files/DBeaver/jre'
```

This must be set **before** `from pyspark.sql import SparkSession`.

**Verify the JRE exists:**
```powershell
ls "C:\Program Files\DBeaver\jre\bin\java.exe"
```

**Why DBeaver's JRE works:** DBeaver ships a full OpenJDK 11 JRE. PySpark only needs a JRE (not the full JDK) to run in local mode. It is the same Java 11 that Spark expects.

### Step 2: Python Path

This machine uses Python 3.11 at:
```
C:\Users\hariom\AppData\Local\Programs\Python\Python311\python.exe
```

Set in your script:
```python
os.environ['PYSPARK_PYTHON']        = r'C:\Users\hariom\AppData\Local\Programs\Python\Python311\python.exe'
os.environ['PYSPARK_DRIVER_PYTHON'] = r'C:\Users\hariom\AppData\Local\Programs\Python\Python311\python.exe'
```

### Step 3: Install Python 3.9+

If not already installed:
1. Download from python.org → Windows installer (64-bit)
2. Check "Add Python to PATH" during install
3. Verify: `python --version`

### Step 4: Install PySpark

```powershell
pip install pyspark
```

This installs PySpark **and** bundles a copy of Spark — you do NOT need a separate Spark download for local mode.

Verify:
```powershell
python -c "import pyspark; print(pyspark.__version__)"
```

### Step 5: Install winutils (Windows-specific requirement)

Spark on Windows needs `winutils.exe` — a small binary that simulates Hadoop filesystem calls.

1. Download from: https://github.com/cdarlint/winutils
   - Match the Hadoop version bundled with your PySpark (usually Hadoop 3.x)
   - Download `winutils.exe` and `hadoop.dll`
2. Create folder: `C:\hadoop\bin\`
3. Put `winutils.exe` and `hadoop.dll` in that folder
4. Set environment variable:
   - Variable name: `HADOOP_HOME`
   - Variable value: `C:\hadoop`
5. Add to Path: `%HADOOP_HOME%\bin`

**Without winutils**, Spark on Windows will throw:
```
ERROR Shell: Failed to locate the winutils binary in the hadoop binary path
```

### Step 6: Optional — Set PYSPARK_PYTHON

If you have multiple Python versions:
```powershell
$env:PYSPARK_PYTHON = "python"
```
Or set it permanently in System Variables.

### Step 7: Install useful extras

```powershell
pip install pandas pyarrow jupyter
```

- `pandas`: for converting Spark DataFrames to Pandas for small-data work
- `pyarrow`: fast Arrow-based data transfer between Spark and Pandas
- `jupyter`: to run PySpark in notebooks

---

## 9. Verify Your Installation

### Quick verification script

Create a file `verify_spark.py`:

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("VerifyInstall") \
    .master("local[*]") \
    .getOrCreate()

spark.sparkContext.setLogLevel("WARN")

data = [("Alice", 30), ("Bob", 25), ("Carol", 35)]
df = spark.createDataFrame(data, ["name", "age"])

df.show()
df.printSchema()
print(f"Row count: {df.count()}")

spark.stop()
print("Spark is working correctly!")
```

Run:
```powershell
python verify_spark.py
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
Spark is working correctly!
```

### Spark UI

When a Spark job runs, a web UI is available at:
```
http://localhost:4040
```
It shows DAG visualization, stages, tasks, and executor metrics. Only active while the session is running.

### Common Windows errors and fixes

| Error | Fix |
|---|---|
| `JAVA_HOME is not set` | Set JAVA_HOME in System Variables and open a new terminal |
| `Failed to locate winutils` | Download winutils.exe, put in `C:\hadoop\bin\`, set HADOOP_HOME |
| `Permission denied on temp folder` | Run PowerShell as Administrator or change `spark.local.dir` |
| `Port 4040 already in use` | Previous Spark session still running — call `spark.stop()` or kill the Python process |
| `py4j.protocol.Py4JError` | Java not found — check JAVA_HOME and Path are set correctly |

---

## Key Takeaways

1. Spark was born to fix Hadoop MapReduce's disk-I/O problem — it keeps data in RAM
2. Lazy evaluation means Spark builds a plan and optimizes it before running
3. Transformations are lazy; actions trigger execution
4. DataFrames are the right abstraction in PySpark — not RDDs
5. Catalyst optimizer makes declarative DataFrame code faster than hand-tuned code
6. Local mode (`local[*]`) runs everything on your laptop — no cluster needed for learning
7. PySpark's DataFrame API looks like Pandas but scales to terabytes
