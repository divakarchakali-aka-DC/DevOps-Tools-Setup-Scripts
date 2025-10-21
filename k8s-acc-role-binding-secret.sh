# create the namespace = webapps

kubectl create namespace webapps

# create account

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: webapps

# create role

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  # The role will be named 'app-role'
  name: app-role
  # This Role is scoped to the 'webapps' namespace (a Role is namespace-specific)
  namespace: webapps
rules:
# Start of the list of rules
- apiGroups:
  # Core API Group ("") and common API Groups (apps, autoscaling, etc.)
  - ""
  - apps
  - autoscaling
  - batch
  - extensions
  - policy
  - rbac.authorization.k8s.io
  resources:
  # List of resources this Role can act upon
  - pods
  - componentstatuses
  - configmaps
  - daemonsets
  - deployments
  - events
  - endpoints
  - horizontalpodautoscalers
  - ingress
  - jobs
  - limitranges
  - namespaces
  - nodes
  - persistentvolumes
  - persistentvolumeclaims
  - resourcequotas
  - replicasets
  - replicationcontrollers
  - serviceaccounts
  - services
  verbs:
  # List of actions allowed on the resources
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete

# create role binding for account with role

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-rolebinding
  namespace: webapps
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: app-role
subjects:
- kind: ServiceAccount
  name: jenkins
  namespace: webapps

# Create secret for account

---
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: mysecret
  namespace: webapps
  annotations:
    kubernetes.io/service-account.name: jenkins