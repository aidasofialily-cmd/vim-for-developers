# Python & Pylint Troubleshooting Reference

This guide lists common **Pylint** and general Python errors encountered during local development and integration checks, along with standard techniques to resolve or safely suppress them.

## General Pylint Best Practices

1. **Aim for a 10.00/10 Rating**: The repository's CI flow runs `pylint` against all Python files. Any score below 10.00/10 can fail the automated testing sequence.
2. **Prioritize Code Modification Over Suppression**: Modify the variable names, add docstrings, or adjust class hierarchies instead of immediately suppressing warnings.
3. **Use Explicit Suppression Inline**: When a false positive or intentional pattern triggers an alert, suppress it directly on the line of occurrence using a localized comment:
   ```python
   # pylint: disable=invalid-name
   PORT = 8000
   ```

---

## Common Pylint Codes & Fixes

### 1. `C0114` / `C0115` / `C0116` (Missing Docstring)
* **Description**: Missing module, class, or function docstring.
* **The Fix**: Add descriptive triple-quoted strings immediately beneath the target entity.
  ```python
  """
  Module-level description explaining the file's primary purpose.
  """
  ```

### 2. `C0103` (Invalid Name)
* **Description**: Constant/variable/class name doesn't conform to naming conventions (e.g., globals should be UPPERCASE, local variables should be lowercase snake_case).
* **The Fix**: Rename the target variable or add a disable block if it is a module-level variable with global intent (such as `PORT` in scripts):
  ```python
  # pylint: disable=invalid-name
  ```

### 3. `W0718` (Broad Exception Caught)
* **Description**: Catching a broad exception class (like `Exception`) rather than a specific one.
* **The Fix**: Use a more specific error class (such as `ValueError`, `FileNotFoundError`) when possible, or explicitly suppress if all-inclusive recovery is intended:
  ```python
  except Exception as e: # pylint: disable=broad-exception-caught
  ```

### 4. `E1101` (No Member Error)
* **Description**: Occurs when code dynamically accesses an attribute or method that static linting cannot resolve.
* **The Fix**: Double-check import paths and typings. If dynamically injected, use a safe default mapping, or disable the warning.

---

## Local Verification Commands

To check Python quality prior to committing changes, execute:
```bash
pylint emulator.py
```
Ensure that no new linter exceptions are introduced and the repository maintains its clean rating.
