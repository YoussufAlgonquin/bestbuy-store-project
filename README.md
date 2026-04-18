# BestBuy Store Project

A cloud-native, production-grade e-commerce simulation built as a **polyglot microservices application** and deployed on **Azure Kubernetes Service (AKS)**. Customers can browse products and place orders through a storefront. Employees manage orders and products through a separate admin portal. AI-generated product descriptions and specifications are powered by **Azure OpenAI (GPT-4o)**.

This project was designed to demonstrate real-world cloud engineering practices: containerized services, asynchronous messaging, Infrastructure-as-Code, Helm-based deployments, and auto-scaling on Kubernetes.

---

## Architecture Overview

```
┌─────────────────────┐     ┌─────────────────────┐
│   Store Front        │     │    Store Admin       │
│   (Vue.js)          │     │    (Vue.js)          │
└────────┬────────────┘     └──────────┬──────────┘
         │ HTTP                        │ HTTP
         ▼                             ▼
┌─────────────────────┐     ┌─────────────────────┐
│   Order Service      │     │  Makeline Service   │
│   (Node.js)         │     │  (Go)               │
└────────┬────────────┘     └──────────┬──────────┘
         │ Publish                     │ Subscribe
         ▼                             │
┌─────────────────────┐               │
│     RabbitMQ        │◄──────────────┘
│  (Message Broker)   │
└─────────────────────┘
                                ┌─────────────────────┐
                                │      MongoDB         │
                                │  (Order Persistence) │
                                └─────────────────────┘

┌─────────────────────┐     ┌─────────────────────┐
│  Product Service    │     │    AI Service        │
│  (Java Spring Boot) │     │ (Python FastAPI)     │
│  Product Catalog    │     │  Azure OpenAI GPT-4o │
└─────────────────────┘     └─────────────────────┘
```

**Key design decisions:**

- **Asynchronous order processing** — the Order Service publishes orders to RabbitMQ; the Makeline Service consumes them independently, preventing the customer-facing API from being blocked by processing delays.
- **Separation of concerns** — customer storefront and employee admin portal are decoupled frontends backed by dedicated services.
- **AI integration** — the AI Service wraps Azure OpenAI to generate product descriptions and specs on demand, keeping AI logic isolated and independently scalable.

---

## Tech Stack

| Layer                   | Technology            |
|-------------------------|-----------------------|
| Customer Frontend       | Vue.js                |
| Admin Frontend          | Vue.js                |
| Order API               | Node.js               |
| Order Processing        | Go                    |
| Product Catalog         | Java (Spring Boot)    |
| AI Service              | Python (FastAPI)      |
| Message Broker          | RabbitMQ              |
| Database                | MongoDB               |
| Container Orchestration | Kubernetes (AKS)      |
| IaC Provisioning        | Terraform             |
| Package Management      | Helm                  |
| Cloud Provider          | Microsoft Azure       |
| AI Model                | Azure OpenAI (GPT-4o) |

---

## Microservices

| Service                                                                                  | Language           | Responsibility                                                          | Docker Hub                                  |
|------------------------------------------------------------------------------------------|--------------------|-------------------------------------------------------------------------|---------------------------------------------|
| [store-front-L8](https://github.com/YoussufAlgonquin/store-front-L8)                     | Vue.js             | Customer-facing storefront — browse products, place orders              | `youssufalgonquin/bestbuy-store-front`      |
| [store-admin-L8](https://github.com/YoussufAlgonquin/store-admin-L8)                     | Vue.js             | Employee portal — view/manage orders and products                       | `youssufalgonquin/bestbuy-store-admin`      |
| [bestbuy-order-service](https://github.com/YoussufAlgonquin/bestbuy-order-service)       | Node.js            | Accepts customer orders via REST API and publishes them to RabbitMQ     | `youssufalgonquin/bestbuy-order-service`    |
| [bestbuy-makeline-service](https://github.com/YoussufAlgonquin/bestbuy-makeline-service) | Go                 | Subscribes to the order queue, processes orders, persists to MongoDB    | `youssufalgonquin/bestbuy-makeline-service` |
| [bestbuy-product-service](https://github.com/YoussufAlgonquin/bestbuy-product-service)   | Java (Spring Boot) | Full CRUD for the product catalog                                       | `youssufalgonquin/bestbuy-product-service`  |
| [bestbuy-ai-service](https://github.com/YoussufAlgonquin/bestbuy-ai-service)             | Python (FastAPI)   | Calls Azure OpenAI to generate product descriptions and technical specs | `youssufalgonquin/bestbuy-ai-service`       |

---

## Infrastructure & DevOps

### Kubernetes on AKS

All services run in a dedicated `bestbuy` namespace on Azure Kubernetes Service. Each service has:

- A **Deployment** with resource requests and limits (CPU/memory)
- A **Service** (ClusterIP or LoadBalancer) for internal/external routing
- **Liveness and readiness probes** to ensure only healthy pods receive traffic

### Auto-Scaling

A **Horizontal Pod Autoscaler (HPA)** is configured for the Order Service:

- Scales between **1–5 replicas**
- Triggers when average CPU utilization exceeds **50%**

### Secrets Management
Sensitive values (MongoDB URI, RabbitMQ URI, Azure OpenAI key/endpoint) are stored as **Kubernetes Secrets**, injected into pods as environment variables. Secrets are never hardcoded or committed to version control.

### Monitoring

**Azure Log Analytics** is provisioned alongside the AKS cluster to collect container logs and cluster metrics, visible in the Azure Portal.

---

## Deployment

### Option 1 — Raw Kubernetes Manifests

```bash
kubectl apply -f "Deployment Files/"
```

Applies all manifests in order: namespace, configmaps, secrets, statefulsets, deployments, services, and HPA.

### Option 2 — Helm Chart

```bash
helm install bestbuy ./helm \
  -f helm/values.yaml \
  -f helm/values.secret.yaml
```

The Helm chart parameterizes replica counts, image tags, resource limits, secret values, and HPA thresholds — making it easy to deploy to different environments by swapping `values.yaml` files.

### Option 3 — Provision AKS with Terraform, then Deploy

```bash
# 1. Provision the AKS cluster
cd terraform
terraform init
terraform apply -var-file=terraform.tfvars

# 2. Configure kubectl
az aks get-credentials --resource-group <rg-name> --name <cluster-name>

# 3. Deploy the application
kubectl apply -f "Deployment Files/"
```

Terraform provisions:

- Azure Resource Group
- AKS cluster with a system node pool
- Log Analytics Workspace (linked to AKS for monitoring)

---

## Services and Ports

| Service | Internal Port | Exposure |
| ------- | ------------- | -------- |
| Store Front | 80 | LoadBalancer (public) |
| Store Admin | 80 | LoadBalancer (public) |
| Order Service | 3000 | ClusterIP (internal) |
| Makeline Service | 8081 | ClusterIP (internal) |
| Product Service | 8080 | ClusterIP (internal) |
| AI Service | 5000 | ClusterIP (internal) |
| RabbitMQ | 5672 | ClusterIP (internal) |
| MongoDB | 27017 | ClusterIP (internal) |

Only the two frontends are exposed publicly via Azure Load Balancer. All backend services communicate over the Kubernetes cluster network.

---

## Demo

[YouTube Demo]()
