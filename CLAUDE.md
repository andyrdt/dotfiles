# Technical Tool Guidelines
## Jupyter Notebook Editing (NotebookEdit Tool)
### Critical Known Issue
The NotebookEdit tool has a **default insertion behavior** that inserts new cells at the very top of the notebook when no `cell_id` is specified. This can create ordering problems and notebook structure issues.

### Required Best Practices
1. **Always Get Cell IDs First**
   # Extract cell IDs from any notebook before editing
   cat notebook.ipynb | grep -E '"id": "[^"]*"'
2. **Always Use cell_id Parameter**
   
   * **NEVER** use `NotebookEdit` with `edit_mode="insert"` without specifying `cell_id`
   * **ALWAYS** target insertion after a specific existing cell
   * Use `cell_id` to control exact placement in notebook structure
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