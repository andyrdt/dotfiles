# Technical Tool Guidelines
## Jupyter Notebook Editing (NotebookEdit Tool)

### ⚠️ CRITICAL REQUIREMENT - READ THIS FIRST ⚠️
**STOP BEFORE USING NotebookEdit WITH edit_mode="insert"**

The NotebookEdit tool has a **DANGEROUS DEFAULT BEHAVIOR**:
- **WITHOUT cell_id**: Inserts cells at the TOP of the notebook (WRONG!)
- **WITH cell_id**: Inserts cells AFTER the specified cell (CORRECT!)

**This has caused repeated user frustration. You MUST follow the checklist below.**

### 📋 QUICK REFERENCE - Where to Insert?
```
User says...                           → Action Required
─────────────────────────────────────────────────────────────────
"Add cells" (unspecified)              → DEFAULT: Append to END
"Add to the bottom/end"                → Append to END
"Add a test/summary/analysis"          → DEFAULT: Append to END
"Add at the top/beginning"             → Insert after first cell
"Add before section X"                 → Find section X, insert before
"Add after cell Y"                     → Insert after cell Y
─────────────────────────────────────────────────────────────────
RULE: When in doubt → APPEND TO END (never top!)
```

### ✅ PRE-FLIGHT CHECKLIST (Required Before ANY Cell Insertion)
Before calling `NotebookEdit` with `edit_mode="insert"`, you MUST:

- [ ] **Step 1**: Read the notebook or extract cell IDs to understand structure
- [ ] **Step 2**: Identify WHERE you want to insert (beginning, middle, or END)
- [ ] **Step 3**: Get the cell_id of the cell BEFORE your insertion point
- [ ] **Step 4**: Specify that cell_id in the NotebookEdit call
- [ ] **Step 5**: Verify the insertion point makes sense for the user's request

### 🎯 DEFAULT ASSUMPTION
**WHEN IN DOUBT, APPEND TO THE END (not the beginning)**

If the user doesn't explicitly specify where to add cells:
- ✅ **DEFAULT**: Append to the END of the notebook (get last cell ID)
- ❌ **NEVER**: Insert at the beginning (this is almost never what users want)

**Examples of when to append to END** (the default):
- "Add cells to the notebook"
- "Add a generation test"
- "Include analysis cells"
- "Add a summary"

**Only insert at beginning/middle when explicitly stated**:
- "Add cells at the top"
- "Insert before section 3"
- "Add after the model loading cell"

**If user says "add to the bottom/end"**, you MUST get the LAST cell's ID.

### Required Best Practices
1. **Always Get Cell IDs First**
   ```bash
   # Method 1: Extract all cell IDs
   cat notebook.ipynb | jq -r '.cells[] | .id'

   # Method 2: Get last cell ID (for appending to end)
   cat notebook.ipynb | jq -r '.cells[-1] | .id'

   # Method 3: Count cells to understand structure
   cat notebook.ipynb | jq '.cells | length'
   ```

2. **Always Use cell_id Parameter**

   * **NEVER** use `NotebookEdit` with `edit_mode="insert"` without specifying `cell_id`
   * **ALWAYS** target insertion after a specific existing cell
   * Use `cell_id` to control exact placement in notebook structure
   * **If cell IDs are null/undefined**, use Python/jq to restructure the notebook first
3. **Proper Insertion Pattern**
   # CORRECT: Target specific cell for insertion
   NotebookEdit(
       notebook_path="path/to/notebook.ipynb",
       edit_mode="insert", 
       cell_id="existing_cell_id",  # Insert AFTER this cell
       cell_type="markdown",
       new_source="content"
   )
   
   # WRONG: No cell_id specified - will insert at top
   NotebookEdit(
       notebook_path="path/to/notebook.ipynb", 
       edit_mode="insert",  # This will go to the top!
       cell_type="markdown",
       new_source="content"
   )
4. **Before Large Notebook Operations**
   
   * Read file to understand structure and get cell IDs
   * Plan insertion sequence to avoid ordering issues
   * Test with single cell insertion first
   * Consider using fresh/clean notebooks for complex structures

### Why This Matters
Incorrect cell insertion can create notebook structure problems that are difficult to fix, especially with large notebooks that exceed file size reading limits. Following these practices ensures precise control over notebook organization.

### Real Example of What Goes Wrong
**User Request**: "Add generation testing cells" (location not specified → should default to END)

**WRONG Approach** (caused user frustration):
```python
# Did NOT get cell IDs first ❌
# Did NOT specify cell_id ❌
NotebookEdit(
    notebook_path="notebook.ipynb",
    edit_mode="insert",  # NO cell_id - goes to TOP!
    cell_type="markdown",
    new_source="## Generation Test"
)
# Result: Cells inserted at TOP instead of BOTTOM
```

**CORRECT Approach**:
```python
# Step 1: Get last cell ID ✓
cat notebook.ipynb | jq -r '.cells[-1] | .id'
# Output: "cell-24"

# Step 2: Insert AFTER the last cell ✓
NotebookEdit(
    notebook_path="notebook.ipynb",
    edit_mode="insert",
    cell_id="cell-24",  # Insert AFTER this cell
    cell_type="markdown",
    new_source="## Generation Test"
)
# Result: Cell correctly inserted at BOTTOM
```

**Key Lessons**:
1. **When location is unspecified, ALWAYS default to appending at the END**
2. **When user says "bottom/end", you MUST get the last cell's ID first**
3. **NEVER insert at the top unless explicitly requested**