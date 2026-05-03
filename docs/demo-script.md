# Demo Script (15-Minute PlatformCon Talk)

**Goal:** Prove that "Guardrails are not approval gates. They are automated boundaries built into the platform so teams can move faster with less risk."

### Scene 1: The Fast Feedback of IaC Policies
*(Run: `make iac-bad` or `.\demo.ps1 iac-bad`)*
**Speaker:**
"Here’s a common scenario. A developer wants to provision a database. They draft the Terraform, but they leave public access on and forget to add the mandatory cost-center tags. Normally, this means waiting days for a security review and a manual approval gate. Instead, watch this."
*(Wait for script output)*
**Speaker:**
"Our pipeline runs `conftest`. The developer gets instantaneous feedback right in their terminal or PR. It says exactly what failed: 'public access is not allowed' and 'owner tag is required'. The platform guardrail blocked the change safely."

### Scene 2: The Successful Path
*(Run: `make iac-good` or `.\demo.ps1 iac-good`)*
**Speaker:**
"The developer fixes the code. They add the tags and disable public access. They run the checks again..."
*(Wait for script output)*
**Speaker:**
"It passes. No manual tickets, no waiting. The safe change passed the platform guardrails."

### Scene 3: The Last Line of Defense (Kubernetes)
*(Run: `make k8s-bad` or `.\demo.ps1 k8s-bad`)*
**Speaker:**
"But what happens if a workload skips CI entirely? What if someone runs `kubectl apply` directly, or a GitOps controller tries to sync an unsafe manifest? Let’s try deploying a privileged container with no resource limits."
*(Wait for script output)*
**Speaker:**
"Kyverno acts as our admission controller. It stops the deployment at the API server boundary. It blocked the privileged container, the missing resource limits, and the missing owner label. The platform protects itself automatically."

### Scene 4: The Safe Workload
*(Run: `make k8s-good` or `.\demo.ps1 k8s-good`)*
**Speaker:**
"And when the developer complies with the guardrails? They apply the safe deployment..."
*(Wait for script output)*
**Speaker:**
"It succeeds immediately. The boundary kept them safe, but they didn't have to slow down. That is the power of automated platform guardrails."
