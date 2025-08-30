Here’s a flowchart + diagram description of your **Azure Automation Account File Share Sync** process:

---

## 🔄 Flowchart: File Sync Process

```text
 ┌─────────────────────────────┐
 │ Start (Automation Runbook) │
 └──────────────┬──────────────┘
                │
                ▼
    ┌─────────────────────────────┐
    │ Authenticate with Managed   │
    │ Identity (Connect-AzAccount)│
    └──────────────┬──────────────┘
                   │
                   ▼
     ┌──────────────────────────┐
     │ Load Automation Variables│
     │ (Source/Dest Accounts,   │
     │ Keys, Share, BasePath)   │
     └──────────────┬───────────┘
                    │
                    ▼
      ┌────────────────────────┐
      │ Validate Source Path   │
      │ Exists (try/catch)     │
      └───────┬────────────────┘
              │ Success
              │
              │ Fail
              ▼
     ┌──────────────────────────┐
     │ Log Error & Stop Job     │
     └──────────────────────────┘

              ▼
 ┌─────────────────────────────┐
 │ Ensure Dest Share/Folder    │
 │ (create if missing)         │
 └──────────────┬──────────────┘
                │
                ▼
 ┌─────────────────────────────┐
 │ Copy Files Recursively      │
 │ from Source → Destination   │
 │ (count files copied)        │
 └──────────────┬──────────────┘
                │
                ▼
 ┌─────────────────────────────┐
 │ Cleanup Destination         │
 │ Delete stale files/dirs not │
 │ present in source           │
 │ (count files/dirs deleted)  │
 └──────────────┬──────────────┘
                │
                ▼
 ┌─────────────────────────────┐
 │ Final Summary Output:       │
 │ Files Copied, Deleted,      │
 │ Dirs Deleted                │
 └──────────────┬──────────────┘
                │
                ▼
       ┌──────────────────┐
       │ End of Runbook   │
       └──────────────────┘
```

---

## 🖼️ Diagram: High-Level Architecture

```text
+----------------------------------------------------------+
| Azure Automation Account (Runbook)                       |
|                                                          |
|  • Uses Managed Identity to authenticate to Azure        |
|  • Pulls Variables (Source/Dest, Keys, Path)             |
|  • Runs PowerShell Az.Storage sync script                |
+----------------------------------------------------------+
                 |                                |
                 |                                |
        ┌────────▼────────┐                ┌──────▼────────┐
        │ Source Storage  │                │ Destination   │
        │ Account         │                │ Storage       │
        │ Share           │                │ Account       │
        │ Path: <BasePath>│                │ Share         │
        │                 │                │ Path: <BasePath>│
        └─────────────────┘                └───────────────┘

Process:
1. Validate <BasePath> exists in **Source**.
2. Recursively copy all files/folders → **Destination**.
3. Remove stale files/folders in Destination (sync).
4. Output job summary: ✔ copied / ❌ deleted counts.
```

---

This gives you:

* 📊 A **flowchart** (step-by-step process of the runbook execution).
* 🏗️ A **diagram** (architecture view of how Automation Account interacts with Source & Destination storage accounts).
