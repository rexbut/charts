# EverHome Helm Charts

Collection of Helm charts for the EverHome project, including Home Assistant, Zigbee2MQTT, and Network UPS Tools.

## 📦 Available Charts

- **homeassistant** (v0.5.2) - Open source home automation platform
- **zigbee2mqtt** (v0.1.12) - Zigbee to MQTT bridge
- **network-ups-tools** (v0.1.5) - Network UPS management

## 🚀 Installation

### From GitHub Container Registry (GHCR)

#### Direct installation

```bash
# Home Assistant
helm install homeassistant oci://ghcr.io/rexbut/charts/homeassistant --version 0.5.2

# Zigbee2MQTT
helm install zigbee2mqtt oci://ghcr.io/rexbut/charts/zigbee2mqtt --version 0.1.12

# Network UPS Tools
helm install network-ups-tools oci://ghcr.io/rexbut/charts/network-ups-tools --version 0.1.5
```

#### Installation with custom values

```bash
# Download default values
helm show values oci://ghcr.io/rexbut/charts/homeassistant --version 0.5.2 > homeassistant-values.yaml

# Edit homeassistant-values.yaml according to your needs

# Install with your custom values
helm install homeassistant oci://ghcr.io/rexbut/charts/homeassistant \
  --version 0.5.2 \
  --values homeassistant-values.yaml \
  --namespace homeassistant \
  --create-namespace
```

### From Harbor Registry

```bash
# Login
helm registry login harbor.evercraft.fr --username <username>

# Installation
helm install homeassistant oci://harbor.evercraft.fr/registry/homeassistant --version 0.5.2
helm install zigbee2mqtt oci://harbor.evercraft.fr/registry/zigbee2mqtt --version 0.1.12
helm install network-ups-tools oci://harbor.evercraft.fr/registry/network-ups-tools --version 0.1.5
```

## 🔍 List Available Versions

```bash
# With GHCR (requires login)
helm registry login ghcr.io --username <github-username>

# Search for charts
helm search repo homeassistant
```

## 📥 Download a Chart

```bash
# Download the chart without installing it
helm pull oci://ghcr.io/rexbut/charts/homeassistant --version 0.5.2

# Extract
tar -xzf homeassistant-0.5.2.tgz
```

## ⬆️ Upgrade

```bash
# Upgrade to a new version
helm upgrade homeassistant oci://ghcr.io/rexbut/charts/homeassistant \
  --version 0.5.3 \
  --values homeassistant-values.yaml \
  --namespace homeassistant
```

## 🗑️ Uninstall

```bash
helm uninstall homeassistant --namespace homeassistant
helm uninstall zigbee2mqtt --namespace zigbee2mqtt
helm uninstall network-ups-tools --namespace network-ups-tools
```

## 🛠️ Development

### Lint charts locally

```bash
# Install ct (chart-testing)
pip install yamllint yamale

# Lint all charts
ct lint --charts homeassistant,network-ups-tools,zigbee2mqtt --chart-dirs . --debug
```

### Build and test locally

```bash
# Package a chart
helm package homeassistant/

# Test the template
helm template homeassistant oci://ghcr.io/rexbut/charts/homeassistant --version 0.5.2

# Dry-run installation
helm install homeassistant oci://ghcr.io/rexbut/charts/homeassistant \
  --version 0.5.2 \
  --dry-run \
  --debug
```

## 🔄 CI/CD

Charts are automatically linted and published via GitHub Actions to:
- **GitHub Container Registry**: `ghcr.io/rexbut/charts/`
- **Harbor Registry**: `harbor.evercraft.fr/registry/`

The workflow is triggered automatically on pushes to `main` or `master`.

## 📝 Chart Documentation

- [Home Assistant](./homeassistant/README.md)
- [Zigbee2MQTT](./zigbee2mqtt/README.md)
- [Network UPS Tools](./network-ups-tools/README.md)

## 🔗 Useful Links

- [Helm OCI Documentation](https://helm.sh/docs/topics/registries/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Home Assistant](https://www.home-assistant.io/)
- [Zigbee2MQTT](https://www.zigbee2mqtt.io/)
- [Network UPS Tools](https://networkupstools.org/)