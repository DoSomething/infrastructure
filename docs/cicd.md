# Project Name

## Continuous Integration and Continuous Deployment (CI/CD) using GitHub Actions

This repository implements a CI/CD workflow using GitHub Actions. The workflow is designed to automate the building, testing, and deployment of the application based on different triggers, such as pushes to specific branches or closed pull requests.

## Workflow Overview

The CI/CD workflow is defined in the `.github/workflows/main.yml` file. It is triggered by manual actions, pushes to branches (excluding 'qa' and 'main'), and closed pull requests on 'main' or 'qa' branches.

## Jobs

### `build-and-test`

This job builds and tests the application. It runs on the `ubuntu-latest` environment and includes the following steps:

1. **Checkout Code:** This step checks out the repository code using `actions/checkout@v3`.

2. **Set up Docker:** Configures Docker using `docker-practice/actions-setup-docker@master`.

3. **Setup PHP with PECL extension:** Uses `shivammathur/setup-php@v2` to set up PHP with specified extensions, including imagick, swoole, mongodb, redis, gd, bcmath, pdo_mysql, gettext, and exif.

4. **Copy .env:** Copies the `.env.example` file to `.env` if it does not exist.

5. **Compose Install Dependencies:** Installs PHP dependencies using Composer.

6. **Use Node.js:** Configures Node.js using `actions/setup-node@v3` with a specified Node.js version.

7. **Setup Python 3.10:** Configures Python 3.10 using `actions/setup-python@v4`.

8. **Install Dependencies:** Installs Node.js dependencies using `npm install`.

9. **Run Tests:** Executes tests using the `npm test` command.

10. **Build Application:** Builds the application using the `npm run build` command.

### `docker-build-and-publish`

This job handles the Docker image building and publishing process. It runs on the `ubuntu-latest` environment and includes the following steps:

1. **Checkout Code:** This step checks out the repository code using `actions/checkout@v3`.

2. **Inject Slug/Short Variables:** Uses `rlespinasse/github-slug-action@v4` to inject slug/short variables.

3. **Set up QEMU:** Configures QEMU using `docker/setup-qemu-action@v2`.

4. **Set up Docker Buildx:** Sets up Docker Buildx using `docker/setup-buildx-action@v2`.

5. **Configure AWS credentials:** Configures AWS credentials using `aws-actions/configure-aws-credentials@v2`.

6. **Login to Amazon ECR:** Logs in to Amazon ECR using `aws-actions/amazon-ecr-login@v1`.

7. **Build and Push Docker Image:** Builds and pushes the Docker image to Amazon ECR using `docker/build-push-action@v4`. Outputs include registry information, Docker username, and Docker password.

### `deploy-dev`

This job deploys the application to the development environment. It runs on the `ubuntu-latest` environment and includes the following steps:

1. **Checkout Code:** This step checks out the repository code using `actions/checkout@v3`.

2. **Inject Slug/Short Variables:** Uses `rlespinasse/github-slug-action@v4` to inject slug/short variables.

3. **Setup Helm:** Sets up Helm using `azure/setup-helm@v3`.

4. **Configure AWS credentials:** Configures AWS credentials using `aws-actions/configure-aws-credentials@v1`.

5. **Update KubeConfig:** Updates the Kubernetes configuration using AWS CLI.

6. **Deploy to DEV:** Deploys the application to the development environment using Helm.

### `deploy-qa`

This job deploys the application to the QA environment. It has similar steps to the `deploy-dev` job but is specific to the QA environment.

### `deploy-qa-queue`

This job deploys a queue component to the QA environment. It has similar steps to the `deploy-qa` job but is specific to the queue component.

### `deploy-prod`

This job deploys the application to the production environment. It has similar steps to the `deploy-dev` job but is specific to the production environment. It is triggered only when changes are pushed to the 'main' branch.

### `deploy-prod-queue`

This job deploys a queue component to the production environment. It has similar steps to the `deploy-prod` job but is specific to the queue component.

## Usage

1. **Manual Trigger:**
   - Navigate to the GitHub repository.
   - Click on the "Actions" tab.
   - Select the "CI/CD" workflow.
   - Click the "Run workflow" button.

2. **Automated Triggers:**
   - The workflow is automatically triggered on pushes to branches and closed pull requests based on the defined rules.

3. **Deployment:**
   - The deployment jobs (`deploy-dev`, `deploy-qa`, `deploy-qa-queue`, `deploy-prod`, `deploy-prod-queue`) are triggered automatically after the successful completion of the `docker-build-and-publish` job.

4. **Environment Variables:**
   - Secrets such as AWS credentials and Kubernetes configuration are stored in GitHub Secrets and used during the workflow execution.

Note: Ensure that the required secrets are properly configured in the GitHub repository settings for successful workflow execution.


