{{/*
templates/_helpers.tpl
*/}}
{{/*
Expand the name of the chart.
*/}}
{{- define "pvpipe.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "pvpipe.fullname" -}}
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
{{- define "pvpipe.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pvpipe.labels" -}}
helm.sh/chart: {{ include "pvpipe.chart" . }}
{{ include "pvpipe.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pvpipe.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pvpipe.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "common.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Generate DATABASE_URL for PgBouncer connection
This helper creates a PostgreSQL URL for services to connect through PgBouncer
*/}}
{{- define "pvpipe.pgbouncerDatabaseUrl" -}}
{{- if and .Values.env.DATABASE_HOST .Values.env.DATABASE_NAME .Values.env.DATABASE_USER .Values.env.DATABASE_PASSWORD }}
{{- $pgbouncerHost := printf "%s-pgbouncer" (include "pvpipe.fullname" .) }}
{{- $pgbouncerPort := .Values.pgbouncer.config.listenPort | default 6432 }}
{{- printf "postgresql://%s:%s@%s:%d/%s" .Values.env.DATABASE_USER .Values.env.DATABASE_PASSWORD $pgbouncerHost $pgbouncerPort .Values.env.DATABASE_NAME }}
{{- else }}
{{- fail "DATABASE_HOST, DATABASE_NAME, DATABASE_USER, and DATABASE_PASSWORD are required for PgBouncer configuration" }}
{{- end }}
{{- end }}

