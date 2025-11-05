# Multi-Tier Serverless Web Application on AWS

A fully serverless multi-tier web application built using **AWS Lambda**, **API Gateway**, **Amazon S3**, and **DynamoDB** — designed to deliver a scalable, cost-efficient, and infrastructure-free deployment model.  

This project demonstrates modern cloud-native architecture by replacing traditional backend servers with managed AWS services and Infrastructure-as-Code provisioning using **Terraform**.

---

## 🚀 Project Overview

This application follows a **multi-tier architecture**:

- **Presentation Layer:** A static website hosted on **Amazon S3**, served publicly.
- **Application Layer:** A **Lambda** function deployed via **API Gateway** to handle business logic and API requests.
- **Data Layer:** A **DynamoDB** table for storing and retrieving dynamic content.

All infrastructure is defined and deployed using **Terraform**, ensuring repeatability and version control.

---

## ⚙️ Tech Stack

| Layer | Technology Used | Purpose |
|-------|-----------------|----------|
| Frontend | Amazon S3 | Host static web content (HTML, CSS ) |
| Backend | AWS Lambda (Python) | Handle dynamic requests & logic |
| API | Amazon API Gateway | Route and secure HTTP endpoints |
| Database | DynamoDB | Store structured data |
| IaC | Terraform | Automate infrastructure setup |

---

## 📂 Project Structure

multi-tier-serverless/
│
├── lambda_function.py # Backend Lambda logic (Python)
├── lambda.zip # Packaged Lambda deployment bundle
├── index.html # Frontend web page hosted on S3
├── main.tf # Terraform root configuration
├── variables.tf # Input variables
├── outputs.tf # Resource outputs
├── provider.tf # AWS provider configuration
└── README.md # Project documentation

---

## 🪜 Step-by-Step Deployment

```yaml
1️⃣ Prerequisites:
  - AWS Account with Free Tier access
  - AWS CLI configured with credentials
  - Terraform ≥ 1.3.0 installed
  - Python 3.x installed
  - IAM user with access to Lambda, API Gateway, S3, and DynamoDB

---

2️⃣ Package Lambda Function:
  - Run the following command from project root:
      - zip -r lambda.zip lambda_function.py

---

3️⃣ Initialize & Deploy Infrastructure:
  - Run:
      - terraform init
      - terraform plan
      - terraform apply

  ✅ Terraform will automatically:
      - Create an S3 bucket for static website hosting
      - Deploy the AWS Lambda function
      - Set up the API Gateway endpoint
      - Create a DynamoDB table
      - Output the API Gateway invoke URL and S3 website endpoint

---

4️⃣ Upload Frontend Files to S3:
  - Command:
      - aws s3 cp index.html s3://<your-s3-bucket-name>/ --acl public-read

---

5️⃣ Access the Application:
  - Frontend URL: http://<your-s3-bucket-name>.s3-website-<region>.amazonaws.com
  - Backend API URL: (Output from Terraform → api_gateway_invoke_url)


##🧠 Key Features

⚡ Fully Serverless: No EC2 or manual servers to manage.
📈 Scalable: Automatically scales with user demand.
💰 Cost-Effective: Pay only for usage; ideal for free-tier experimentation.
🧩 Infrastructure as Code: Version-controlled and reproducible deployments.
🔐 Secure: IAM-based access control with least privilege configuration.

## Example Use Cases

Contact form or feedback submission system
Serverless CRUD API with web interface
Dynamic portfolio or data-driven dashboard

## 🧑‍💻 Author

Kalyani Mishra
Cloud & DevOps Enthusiast
Linkedin: https://www.linkedin.com/in/kalyani-mishra-a05267234/
📧 Email: kalyanimishra60120@gmail.com



