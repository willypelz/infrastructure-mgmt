# Grafana Dashboards

This directory contains Grafana dashboard JSON files that will be automatically imported.

## Available Dashboards

To add pre-built dashboards, you can download them from https://grafana.com/grafana/dashboards/

### Recommended Dashboards:

1. **Docker Container & Host Metrics** (ID: 179)
   - Download: `curl -o docker-monitoring.json https://grafana.com/api/dashboards/179/revisions/9/download`

2. **Traefik 2** (ID: 11462)
   - Download: `curl -o traefik-dashboard.json https://grafana.com/api/dashboards/11462/revisions/1/download`

3. **Node Exporter Full** (ID: 1860)
   - Download: `curl -o node-exporter.json https://grafana.com/api/dashboards/1860/revisions/27/download`

4. **Loki Logs Dashboard** (ID: 13639)
   - Download: `curl -o loki-logs.json https://grafana.com/api/dashboards/13639/revisions/2/download`

## Usage

1. Download the dashboard JSON files to this directory
2. Restart Grafana container: `docker-compose restart grafana`
3. Dashboards will be automatically imported

Alternatively, you can manually import dashboards through the Grafana UI at https://grafana.yourdomain.com
