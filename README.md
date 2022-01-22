# orc
Orca exercise

The service uses PostgreSQL as a datastore and expects the URL and the credentials to be passed in the DATABASE_URL environment variable. 
The service itself has 2 endpoints (in app.py),   
one for the service itself and the other one for the healthcheck.

---

## Solution steps 
1. Define the high level architecture and tools
2. Run project locally on docker
    - fix dependencies:
      - missing psycopg2
    - fix many local issues on my machine :(
3. prepare  required resources on AWS using terraform
   - pulumi looks like a nice option as well.
4. setup github action to 
   1. build and push the application docker to AWS ECR
   2. deploy to AWS fargate

## Considerations
 - for some preferred learning/practising new tools on best practise:
      - fargate over EKS
      - github and github actions over Jenkins/AWS tools
 - fully automated solution
   - infra as code
  
## todos
  - security:
    - move postgresql credential in AWS secret manager after DB creation
    - replace DB credentials as environment variables with AWS secret manager
    - IAM hardening (key permissions, do not use root, etc.)
    - disable access for rds outside the VPC
  - separate modules to different projects (single project only for exercise readability):
    - infrastructure separation from application
    - RDS: as it should not depend on the application state
    - ECS service/ task definition
  - add loggings, monitoring, and alerts
  - Dockerfile and CI:
    - use a slim image version for runtime
    - add tests, lint etc. to the multi-stage Dockerfile and CI

---

### packaging
- docker (multi stage)

### CI
- gihub action
  - multi stage dockerfile
  - push image to registry

### CD
- gihub action
  - deploy to fargate

### infra as code
- terraform

