
### Discovered via Audit (discovery_cod_1771889895_8304) - Mon Feb 23 23:39:14 UTC 2026
- [ ] **Refactor `setProjectDirectory` Method**: The method currently reloads the initial state when a new project directory is set. Consider adding a check to only reload if the directory has changed.
  
  (File: coding-reviewer/CodingReviewer/IDE/SourceControlViewModel.swift)

- [ ] **Add Error Handling for Empty Commit Messages**: Ensure that error handling is in place for cases where the commit message is empty, as it currently just sets an error message without preventing the commit.

  (File: coding-reviewer/CodingReviewer/IDE/SourceControlViewModel.swift)

- [ ] **Implement Undo and Redo Functionality**: Add methods to handle undo and redo operations for staged files. This could involve maintaining a history of changes and allowing users to revert or reapply them.

  (File: coding-reviewer/CodingReviewer/IDE/SourceControlViewModel.swift)

- [ ] **Optimize `loadDiff` Method**: The method currently reloads the diff every time it is called, which might be inefficient if the file has not changed. Consider caching the diffs and only reloading when necessary.

  (File: coding-reviewer/CodingReviewer/IDE/SourceControlViewModel.swift)

- [ ] **Add Support for Multiple Branches**: Implement methods to switch between branches and handle operations like merge and rebase. This will enhance the functionality of managing multiple branches in a project.

  (File: coding-reviewer/CodingReviewer/IDE/SourceControlViewModel.swift)

- [ ] **Implement Pull Request Management**: Add features to create, view, and manage pull requests directly from the source control view model. This could involve integrating with a Git hosting service API.

  (File: coding-reviewer/CodingReviewer/IDE/SourceControlViewModel.swift)

- [ ] **Add Support for Submodules**: Implement methods to handle operations related to submodules, such as adding, updating, and removing them.

  (File: coding-reviewer/CodingReviewer/IDE/SourceControlViewModel.swift)

- [ ] **Refactor `handleError` Method**: The method currently handles errors by setting an error message. Consider implementing more sophisticated error handling, such as retrying operations or notifying the user in a more user-friendly way.

  (File: coding-reviewer/CodingReviewer/IDE/SourceControlViewModel.swift)

- [ ] **Add Unit Tests for ViewModel Methods**: Write unit tests to ensure that each method in the `SourceControlViewModel` works as expected. This will help catch bugs and ensure that the code remains robust over time.

  (File: coding-reviewer/CodingReviewer/IDE/SourceControlViewModel.swift)

### Discovered via Audit (discovery_cod_1771890019_2968) - Mon Feb 23 23:42:08 UTC 2026
- [ ] **Refactor `loadInitialState` Method**: The method currently only calls `refreshStatus()`. Consider adding additional initialization logic if needed, such as loading branch names or other relevant state.
  
- [ ] **Implement Error Handling for `setProjectDirectory`**: Ensure that the `setProjectDirectory` method handles errors gracefully. Currently, it simply logs an error and does not provide feedback to the user.

- [ ] **Add Unit Tests for `stageFile` and `unstageFile` Methods**: Write unit tests to verify that these methods correctly stage and unstage files without throwing exceptions.

- [ ] **Implement a Method to Fetch Branches**: Add a method to fetch all branches in the repository and update the UI accordingly. This will help users switch between branches easily.

- [ ] **Refactor `commit` Method for Better Error Handling**: Improve error handling in the `commit` method to provide more detailed feedback on what went wrong during the commit process.

- [ ] **Add a Feature to Show Commit History**: Implement a feature that allows users to view the commit history and select specific commits to revert or cherry-pick.

- [ ] **Refactor `loadDiff` Method for Better Performance**: If the diff loading is slow, consider optimizing the method by caching diffs or using asynchronous operations more efficiently.

- [ ] **Implement a Feature to Show Staged Changes**: Add a feature that displays staged changes side-by-side with uncommitted changes, making it easier for users to review their work before committing.

### Discovered via Audit (discovery_cod_1771890437_2903) - Mon Feb 23 23:48:27 UTC 2026
- [ ] **Refactor `setProjectDirectory` Method**: Ensure that the method properly handles cases where `projectDirectory` is already set to avoid unnecessary state refreshes.
- [ ] **Implement Error Handling for `init` Method**: Add error handling in the `init` method to manage cases where `projectDirectory` cannot be initialized, ensuring the view model does not enter an invalid state.
- [ ] **Add Unit Tests for `refreshStatus` Method**: Write unit tests to verify that the `refreshStatus` method correctly updates the status and branch information when called.
- [ ] **Implement a Loading Indicator for Diff Operations**: Ensure that the `isLoadingDiff` property is properly managed during diff loading operations, providing feedback to the user.
- [ ] **Refactor `commit` Method**: Add validation to ensure that the commit message does not contain only whitespace characters before proceeding with the commit operation.
- [ ] **Implement a Feature for Viewing Commit History**: Add functionality to view the commit history and allow users to select specific commits for viewing or reverting.
- [ ] **Add Support for Multiple Branches**: Implement methods to switch between branches, create new branches, and delete existing branches.
- [ ] **Refactor `handleError` Method**: Improve error handling by providing more detailed error messages that can help developers diagnose issues more effectively.
- [ ] **Implement a Feature for Stashing Changes**: Add functionality to stash changes temporarily when switching branches or performing other operations that require a clean working directory.
