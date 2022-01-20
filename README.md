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
    - fix local issues :(
3. prepare **ALL** required resources on AWS
   - pulumi looks like a nice option as well.
4. setup github action to 
   1. build and push the application docker to AWS ECR
   2. Push image AWS fargate

## Considerations
- fully automated solution
- separate CI from CD
- infra as code
  - cloud agnostic
  
## todos
  - separate modules to different projects (single project only for exercise readability):
    - Terraform: infrastructure separation from application
    - RDS: as it should not depend on the application state
  - move postgresql credential in AWS secret manager after DB creation
  - handle versions and upgrades
  - add loggings, monitoring, and alerts
  - add tests, enable tests stage in Dockerfile and CI
  - AWS: IAM improvements (key permissions, do not use root, etc.)
  - many more

---
## packaging
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

