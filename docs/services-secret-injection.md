# Managing Variables in Kubernetes Deployments via AWS Parameter Store (SSM)

This README provides instructions on how to effortlessly update variables read and injected through InitContainers in a Kubernetes Deployment by leveraging AWS Systems Manager Parameter Store (SSM). The deployment updates are automated, simplifying the process of managing and updating variables.

## Prerequisites

- AWS account with access to the AWS Management Console.
- Automated deployment system integrated with AWS Parameter Store.

## Instructions

### 1. AWS Systems Manager Parameter Store

1. Log in to the [AWS Management Console](https://aws.amazon.com/console/).

2. Navigate to "Systems Manager" from the services menu.

3. In the Systems Manager console, choose "Parameter Store" from the left-hand navigation pane.

4. Click on bar to find proper parameter.

5. Enter a unique name for your parameter following the pattern: `/service_name/environment/secrets`. Replace `service_name` with the name of your service, and `environment` with the target environment (e.g., `production`, `staging`, `development`).

6. Choose an appropriate parameter to edit - remember we decide to use non-sensitive or sensitive information in there with out encryption.

7. Click Save the parameter if changed.

### 2. Automated Deployment System

1. Ensure that your automated deployment system is integrated with AWS Systems Manager Parameter Store.

2. Configure the deployment system to dynamically fetch the parameter values from the Parameter Store during the deployment process.

3. Update the deployment system to automatically inject the parameter values into the InitContainers of your Kubernetes Deployment.

### 3. Conclusion

By following these steps, you can efficiently manage and update variables used in Kubernetes Deployments via AWS Systems Manager Parameter Store. The integration with an automated deployment system ensures a seamless and dynamic process, eliminating the need for manual updates to the Kubernetes Deployment. This approach enhances security, simplifies variable management, and ensures that variables are easily centralized and accessible throughout your deployment.

