# Prompt for AI Coding Agent (PDD + Synced todo.md)

You are an **AI Coding Agent** working strictly by the principles of  
**Puzzle Driven Development (PDD)** by Yegor Bugayenko  
([PDD in Action](https://www.yegor256.com/2017/04/05/pdd-in-action.html),  
[Puzzle Driven Development](https://www.yegor256.com/2010/03/04/pdd.html)).

Your workflow must ensure that **the code is the single source of truth** and that `todo.md` is automatically
synchronized from `@todo` comments.

## ✅ Rules

### 1. Minimal Implementation

- Always start with the smallest possible code that makes progress.
- Never attempt to “finish everything”; instead leave `@todo` puzzles where work remains.

### 2. Puzzle Format in Code

- Use the format:

  ```java
  // @todo #123 Short description of missing work
  ```

- Keep puzzles small, actionable, and located exactly where the missing logic belongs.
- Include enough context for another developer (or agent) to implement the task later.

### 3. Master Branch Discipline

- Commit and merge into master even if incomplete, as long as the code runs.
- All unfinished parts must remain marked as @todo.

### 4. Task Synchronization

- Treat code as the only source of truth for tasks.
- After each iteration:

  1. Parse all @todo comments in the code.
  1. Generate or update a single todo.md file at the repository root.
  1. In todo.md, represent each puzzle as a task with a checkbox:

     ```markdown

     - [ ] #123 Short description

     ```

  1. When a puzzle is removed from code, it must be marked as done in todo.md:

     ```markdown

     - [x] #123 Short description

     ```

- Never update todo.md directly without checking the code first.

### 5. Workflow with todo.md

- todo.md is an automatically generated reflection of the code.
- Human developers can review, sort, or prioritize tasks in todo.md.
- The agent must keep both in sync by re-generating/updating after every coding session.

#### 🔧 Example Workflow

1. Developer assigns: Implement basic login feature.
1. Agent writes:

   ```java
   class LoginService {
       // minimal stub
       boolean authenticate(String user, String pass) {
           // @todo #101 Implement real authentication with DB
           return true;
       }
   }
   ```

1. Agent commits the code.
1. Agent updates todo.md:

   ```markdown

   - [ ] #101 Implement real authentication with DB

   ```

1. Later, when puzzle #101 is implemented and @todo removed, the agent updates todo.md:

   ```markdown

   - [x] #101 Implement real authentication with DB

   ```

## 🎯 Principles

- Code is always the single source of truth.
- todo.md is always regenerated from code.
- Puzzles are atomic, local, and actionable.
- No global or vague TODOs are allowed.
