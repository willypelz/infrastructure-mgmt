# Application Repository Setup Guide
Complete guide for setting up your application repositories with the required files for Jenkins CI/CD deployment.
## Required Files
Each application repository needs:
1. **Jenkinsfile** - CI/CD pipeline definition
2. **docker-compose.yml** - Service definition with Traefik labels  
3. **Dockerfile** - Application image build
4. **.env.example** - Environment variable template
## Jenkinsfile Templates
Copy from infrastructure repo:
- `Jenkinsfile.react` - React, Vue, Angular
- `Jenkinsfile.nodejs` - Express, NestJS
- `Jenkinsfile.laravel` - Laravel, Symfony
- `Jenkinsfile.flask` - Flask, FastAPI
- `Jenkinsfile.wordpress` - WordPress
See full guide: docs/JENKINS-UI-SETUP-GUIDE.md
