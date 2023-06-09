kubectl create secret generic git-ssh-credentials --type=kubernetes.io/ssh-auth \
--from-file=ssh-privatekey=$HOME/.ssh/id_ed25519 \
--from-file=known_hosts=$HOME/.ssh/known_hosts
kubectl annotate secret git-ssh-credentials tekton.dev/git-0=github.com