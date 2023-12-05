# Docker-Compose Installation and Setup

## Install Docker Compose

1. Install Docker Compose using Homebrew:

    ```bash
    brew install docker-compose
    ```

## Git Pull and Code Changes

2. Clone the main branch of the repository:

    ```bash
    git pull repo main branch
    ```

3. Make changes in the code.

4. Edit the `.env.local` file and save it as `.env`.

## Docker Compose Usage

5. Start the Docker containers using the following command:

    ```bash
    docker-compose up
    ```

    This command will start the container in the terminal with logs, allowing you to see changes on-demand, except for those that require a rebuild.

6. Depending on the project, read from the `docker-compose.yaml` file to find the exposed port. Once the container starts, navigate to:

    [http://localhost:$PORT](http://localhost:$PORT)

    Replace `$PORT` with the actual port number specified in the `docker-compose.yaml` file.

