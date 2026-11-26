{{/*
Expand the name of the chart.
*/}}
{{- define "filaman.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "filaman.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "filaman.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "filaman.labels" -}}
helm.sh/chart: {{ include "filaman.chart" . }}
{{ include "filaman.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "filaman.selectorLabels" -}}
app.kubernetes.io/name: {{ include "filaman.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "filaman.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "filaman.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the Secret holding the application keys
*/}}
{{- define "filaman.secretName" -}}
{{- .Values.filaman.existingSecret | default (include "filaman.fullname" .) }}
{{- end }}

{{/*
Name of the Secret holding the PostgreSQL credentials
*/}}
{{- define "filaman.postgresql.secretName" -}}
{{- .Values.database.postgresql.existingSecret | default (include "filaman.fullname" .) }}
{{- end }}

{{/*
Name of the Secret holding the external database URL
*/}}
{{- define "filaman.external.secretName" -}}
{{- .Values.database.external.existingSecret | default (include "filaman.fullname" .) }}
{{- end }}

{{/*
Keys of the PostgreSQL credentials in their Secret
*/}}
{{- define "filaman.postgresql.usernameKey" -}}
{{- if .Values.database.postgresql.existingSecret }}{{ .Values.database.postgresql.usernameKey }}{{ else }}db-username{{ end }}
{{- end }}

{{- define "filaman.postgresql.passwordKey" -}}
{{- if .Values.database.postgresql.existingSecret }}{{ .Values.database.postgresql.passwordKey }}{{ else }}db-password{{ end }}
{{- end }}

{{- define "filaman.external.urlKey" -}}
{{- if .Values.database.external.existingSecret }}{{ .Values.database.external.urlKey }}{{ else }}database-url{{ end }}
{{- end }}

{{/*
Whether the chart must create its own Secret
*/}}
{{- define "filaman.createSecret" -}}
{{- $db := .Values.database -}}
{{- if or (not .Values.filaman.existingSecret) (and (eq $db.type "postgresql") (not $db.postgresql.existingSecret)) (and (eq $db.type "external") (not $db.external.existingSecret)) -}}
true
{{- end -}}
{{- end }}

{{/*
Validate the values and fail early with a clear message
*/}}
{{- define "filaman.validate" -}}
{{- $db := .Values.database -}}
{{- if not .Values.filaman.existingSecret }}
{{- $_ := required "filaman.secretKey is required (generate one with: openssl rand -hex 32), or set filaman.existingSecret" .Values.filaman.secretKey }}
{{- $_ := required "filaman.csrfSecretKey is required (generate one with: openssl rand -hex 32), or set filaman.existingSecret" .Values.filaman.csrfSecretKey }}
{{- end }}
{{- if not (has $db.type (list "sqlite" "postgresql" "external")) }}
{{- fail (printf "database.type must be sqlite, postgresql or external (got %q)" $db.type) }}
{{- end }}
{{- if eq $db.type "postgresql" }}
{{- $_ := required "database.postgresql.host is required when database.type=postgresql" $db.postgresql.host }}
{{- if not $db.postgresql.existingSecret }}
{{- $_ := required "database.postgresql.username is required when database.type=postgresql (or set database.postgresql.existingSecret)" $db.postgresql.username }}
{{- $_ := required "database.postgresql.password is required when database.type=postgresql (or set database.postgresql.existingSecret)" $db.postgresql.password }}
{{- end }}
{{- end }}
{{- if and (eq $db.type "external") (not $db.external.existingSecret) }}
{{- $_ := required "database.external.url is required when database.type=external (or set database.external.existingSecret)" $db.external.url }}
{{- end }}
{{- end }}
