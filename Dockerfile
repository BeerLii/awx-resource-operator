FROM quay.io/operator-framework/ansible-operator:v1.42.3

# The upstream image is published before the latest UBI errata are available.
# Apply the current UBI updates while building so the image does not retain
# stale system libraries from the base layer.
USER 0
RUN microdnf -y --nodocs --setopt=install_weak_deps=0 --setopt=keepcache=0 update \
 && microdnf clean all \
 && rm -rf /var/cache/yum

# The base image bundles Python dependencies used by ansible-operator. Keep
# them current because they are not managed by the RPM update above.
RUN python3 -m ensurepip --upgrade \
 && python3 -m pip install --no-cache-dir --upgrade \
      certifi==2026.10.23 \
      cryptography==50.0.2 \
      filelock==4.2.9 \
      msgpack==1.2.4 \
      oauthlib==4.0.1 \
      pyasn1==0.6.5 \
      setuptools==84.2.1 \
      urllib3==2.8.0 \
      virtualenv==21.15.5 \
 && rm -rf /root/.cache/pip

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/

ENTRYPOINT ["/tini", "--", "/usr/local/bin/ansible-operator", "run", "--watches-file=./watches.yaml", "--reconcile-period=0s"]
