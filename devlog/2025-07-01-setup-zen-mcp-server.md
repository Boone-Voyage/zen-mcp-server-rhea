# Devlog: Setting Up and Debugging the zen-mcp-server

**Date:** 2025-07-01

## Overview

The primary objective was to set up the `zen-mcp-server` using Docker, ensuring it runs persistently with an automatic restart policy. This involved cloning the repository, configuring environment variables, and debugging a series of issues related to the Docker configuration.

## Initial Setup Steps

1.  **Cloned Repository:** The `zen-mcp-server` repository was cloned from GitHub.
2.  **Environment Configuration:** A `.env` file was created with the necessary `OPENAI_API_KEY` and `GEMINI_API_KEY`.
3.  **Persistent Restart:** The `docker-compose.yml` file was modified to include `restart: unless-stopped` to ensure the container would automatically restart.

## Challenges and Solutions

After the initial setup, the Docker container entered a restart loop. The following issues were diagnosed and resolved systematically:

### 1. Challenge: Incorrect Startup Command

-   **Symptom:** The container would start and then immediately exit with code 0.
-   **Diagnosis:** The `Dockerfile`'s `CMD` was `["python", "server.py"]`, which ran the server as a background process and allowed the main container process to exit.
-   **Solution:** The `CMD` in the `Dockerfile` was changed to `["./run-server.sh"]` to use the provided shell script, which is designed to keep the server running in the foreground.

### 2. Challenge: Script Not Executable

-   **Symptom:** The container failed to start with exit code 1 after changing the `CMD`.
-   **Diagnosis:** The `run-server.sh` script did not have execute permissions within the Docker image.
-   **Solution:** A `RUN chmod +x /app/run-server.sh` command was added to the `Dockerfile` to make the script executable.

### 3. Challenge: Read-Only Filesystem

-   **Symptom:** The logs showed `cp: cannot create regular file '.env': Read-only file system`.
-   **Diagnosis:** The `docker-compose.yml` file had `read_only: true` enabled for security, which prevented the startup script from creating necessary configuration files and a virtual environment.
-   **Solution:** The `read_only: true` line was removed from `docker-compose.yml` to allow the first-time setup to complete.

### 4. Challenge: File Permissions for Non-Root User

-   **Symptom:** After disabling the read-only filesystem, the logs showed `Permission denied` errors when trying to create the `.env` file and the virtual environment.
-   **Diagnosis:** The application was running as the non-root user `zenuser`, but the `/app` directory was owned by `root`, preventing `zenuser` from writing to it.
-   **Solution:** The command `RUN chown -R zenuser:zenuser /app` was added to the `Dockerfile` just before the `USER zenuser` instruction to grant the necessary permissions.

## Final Outcome

After applying all the fixes, the `zen-mcp-server` container was successfully built and started. It is now running stably, is accessible for integration, and is configured to restart automatically.

## Claude CLI Integration

After ensuring the Docker container was stable, the final step was to integrate the server with the local Claude Code CLI.

1.  **Configuration Generation:** The `run-server.sh` script was executed with the `-c` flag (`./run-server.sh -c`) to generate the precise command needed for Claude integration.
2.  **Server Registration:** The following command was run to register the `zen-mcp-server` with the Claude CLI:
    ```bash
    claude mcp add zen -s user -- /Users/dshanklinbv/repos/zen-mcp-server/.zen_venv/bin/python /Users/dshanklinbv/repos/zen-mcp-server/server.py
    ```
3.  **Outcome:** The server is now successfully registered as `zen` and is available for use within the Claude Code environment.

## Key Learnings

-   For a Docker container to remain active, its main process must run in the foreground.
-   File permissions are not always preserved when copying files into a Docker image and must be set explicitly with `chmod`.
-   Overly restrictive security settings (`read_only: true`) can conflict with initialization scripts.
-   When running containers with a non-root user, ensure the user has ownership (`chown`) of any directories it needs to write to.
