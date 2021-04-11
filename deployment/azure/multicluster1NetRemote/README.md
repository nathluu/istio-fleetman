This module is used to install istio multicluster primary-remote model. The topology includes two clusters cluster1 and cluster2 belong to the same network. We will install the control plane on cluster1 and create an east-west gateway to expose control plane to cluster2.

Notes:
Today (versiion 1.9.1), the remote profile will install an istiod server in the remote cluster which will be used for CA and webhook injection for workloads in that cluster. Service discovery, however, will be directed to the control plane in the primary cluster.

Future releases will remove the need for having an istiod in the remote cluster altogether. Stay tuned!