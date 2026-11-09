# Keep the upstream ansible-operator binary and its curated Python dependency
# set, but do not inherit its UBI9 runtime layer.  The upstream v1.42.3 image
# is based on UBI9 and its RPM CVEs remain visible to image scanners even after
# a downstream microdnf update.
FROM quay.io/operator-framework/ansible-operator:v1.42.3 AS upstream

# UBI10 is the runtime layer.  This removes the vulnerable UBI9 curl/OpenSSL/
# glibc/SQLite package stream while preserving the upstream operator payload.
FROM registry.access.redhat.com/ubi10/python-312-minimal:latest

ARG SECURITY_REFRESH=manual
USER 0

RUN echo "Security refresh: ${SECURITY_REFRESH}" \
 && microdnf --refresh -y --nodocs \
      --setopt=install_weak_deps=0 \
      --setopt=keepcache=0 \
      update \
 && microdnf clean all \
 && rm -rf /var/cache/yum /var/cache/dnf

ENV HOME=/opt/ansible \
    USER_NAME=ansible \
    USER_UID=1001 \
    ANSIBLE_CONFIG=/etc/ansible/ansible.cfg \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1

# Import only the application payload from the upstream image, never its UBI9
# filesystem.  The two site-packages locations are used by the upstream
# multi-architecture image.
COPY --from=upstream /usr/local/lib64/python3.12/site-packages /usr/local/lib64/python3.12/site-packages
COPY --from=upstream /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=upstream /usr/local/bin/ansible* /usr/local/bin/
COPY --from=upstream /tini /tini

RUN chmod +x /usr/local/bin/ansible-operator /tini \
 && mkdir -p /etc/ansible ${HOME}/.ansible/tmp \
 && printf '%s\n' 'localhost ansible_connection=local' > /etc/ansible/hosts \
 && printf '%s\n' '[defaults]' 'roles_path = /opt/ansible/roles' 'library = /usr/share/ansible/openshift' > /etc/ansible/ansible.cfg \
 && printf 'ansible:x:%s:0:ansible user:%s:/sbin/nologin\n' "${USER_UID}" "${HOME}" >> /etc/passwd \
 && chown -R ${USER_UID}:0 ${HOME} \
 && chmod -R ug+rwx ${HOME}

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible \
 && rm -f ${HOME}/requirements.yml

COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/
RUN chown -R ${USER_UID}:0 ${HOME} \
 && chmod -R ug+rwx ${HOME}

WORKDIR ${HOME}
USER ${USER_UID}

ENTRYPOINT ["/tini", "--", "/usr/local/bin/ansible-operator", "run", "--watches-file=./watches.yaml", "--reconcile-period=0s"]
