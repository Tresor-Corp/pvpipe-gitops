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
Transform DATABASE_URL to use PgBouncer
This helper takes a PostgreSQL connection URL and transforms it to use PgBouncer (mandatory)
*/}}
{{- define "pvpipe.pgbouncerDatabaseUrl" -}}
{{- if and .Values.env .Values.env.DATABASE_URL }}
{{- $dbUrl := .Values.env.DATABASE_URL }}
{{- if contains "postgresql://" $dbUrl }}
{{- $parsed := regexSplit "[@:/]+" (trimPrefix "postgresql://" $dbUrl) -1 }}
{{- if ge (len $parsed) 5 }}
{{- $user := index $parsed 0 }}
{{- $password := index $parsed 1 }}
{{- $database := index $parsed 4 }}
{{- $pgbouncerHost := printf "%s-pgbouncer" (include "pvpipe.fullname" .) }}
{{- $pgbouncerPort := $.Values.pgbouncer.config.listenPort | default 6432 }}
{{- printf "postgresql://%s:%s@%s:%d/%s" $user $password $pgbouncerHost $pgbouncerPort $database }}
{{- else }}
{{- fail "Invalid DATABASE_URL format for PgBouncer transformation" }}
{{- end }}
{{- else }}
{{- fail "DATABASE_URL must be a PostgreSQL URL starting with postgresql://" }}
{{- end }}
{{- else }}
{{- fail "DATABASE_URL is required for PgBouncer configuration" }}
{{- end }}
{{- end }}

{{/*
Transform DATABASE_URL_READONLY to use PgBouncer (mandatory)
*/}}
{{- define "pvpipe.pgbouncerDatabaseUrlReadonly" -}}
{{- if and .Values.env .Values.env.DATABASE_URL_READONLY }}
{{- $dbUrl := .Values.env.DATABASE_URL_READONLY }}
{{- if contains "postgresql://" $dbUrl }}
{{- $parsed := regexSplit "[@:/]+" (trimPrefix "postgresql://" $dbUrl) -1 }}
{{- if ge (len $parsed) 5 }}
{{- $user := index $parsed 0 }}
{{- $password := index $parsed 1 }}
{{- $database := index $parsed 4 }}
{{- $pgbouncerHost := printf "%s-pgbouncer" (include "pvpipe.fullname" .) }}
{{- $pgbouncerPort := $.Values.pgbouncer.config.listenPort | default 6432 }}
{{- printf "postgresql://%s:%s@%s:%d/%s" $user $password $pgbouncerHost $pgbouncerPort $database }}
{{- else }}
{{- fail "Invalid DATABASE_URL_READONLY format for PgBouncer transformation" }}
{{- end }}
{{- else }}
{{- fail "DATABASE_URL_READONLY must be a PostgreSQL URL starting with postgresql://" }}
{{- end }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}