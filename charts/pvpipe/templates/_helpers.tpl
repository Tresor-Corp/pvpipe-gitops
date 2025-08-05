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
This helper takes a PostgreSQL connection URL and transforms it to use PgBouncer
*/}}
{{- define "pvpipe.pgbouncerDatabaseUrl" -}}
{{- if and .Values.pgbouncer .Values.pgbouncer.enabled }}
{{- if and .Values.env .Values.env.DATABASE_URL }}
{{- $dbUrl := .Values.env.DATABASE_URL }}
{{- if contains "postgresql://" $dbUrl }}
{{- $parsed := regexSplit "[@:/]+" (trimPrefix "postgresql://" $dbUrl) -1 }}
{{- if ge (len $parsed) 5 }}
{{- $user := index $parsed 0 }}
{{- $password := index $parsed 1 }}
{{- $database := index $parsed 4 }}
{{- $pgbouncerHost := printf "%s-pgbouncer" (include "pvpipe.fullname" .) }}
{{- printf "postgresql://%s:%s@%s:5432/%s" $user $password $pgbouncerHost $database }}
{{- else }}
{{- .Values.env.DATABASE_URL }}
{{- end }}
{{- else }}
{{- .Values.env.DATABASE_URL }}
{{- end }}
{{- else }}
{{- "" }}
{{- end }}
{{- else if and .Values.env .Values.env.DATABASE_URL }}
{{- .Values.env.DATABASE_URL }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}

{{/*
Transform DATABASE_URL_READONLY to use PgBouncer
*/}}
{{- define "pvpipe.pgbouncerDatabaseUrlReadonly" -}}
{{- if and .Values.pgbouncer .Values.pgbouncer.enabled }}
{{- if and .Values.env .Values.env.DATABASE_URL_READONLY }}
{{- $dbUrl := .Values.env.DATABASE_URL_READONLY }}
{{- if contains "postgresql://" $dbUrl }}
{{- $parsed := regexSplit "[@:/]+" (trimPrefix "postgresql://" $dbUrl) -1 }}
{{- if ge (len $parsed) 5 }}
{{- $user := index $parsed 0 }}
{{- $password := index $parsed 1 }}
{{- $database := index $parsed 4 }}
{{- $pgbouncerHost := printf "%s-pgbouncer" (include "pvpipe.fullname" .) }}
{{- printf "postgresql://%s:%s@%s:5432/%s_readonly" $user $password $pgbouncerHost $database }}
{{- else }}
{{- .Values.env.DATABASE_URL_READONLY }}
{{- end }}
{{- else }}
{{- .Values.env.DATABASE_URL_READONLY }}
{{- end }}
{{- else }}
{{- "" }}
{{- end }}
{{- else if and .Values.env .Values.env.DATABASE_URL_READONLY }}
{{- .Values.env.DATABASE_URL_READONLY }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}