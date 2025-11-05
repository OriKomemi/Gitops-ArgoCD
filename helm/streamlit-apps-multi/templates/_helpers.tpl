{{/*
Expand the name of the chart.
*/}}
{{- define "streamlit-apps-multi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "streamlit-apps-multi.fullname" -}}
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
{{- define "streamlit-apps-multi.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "streamlit-apps-multi.labels" -}}
helm.sh/chart: {{ include "streamlit-apps-multi.chart" . }}
{{ include "streamlit-apps-multi.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "streamlit-apps-multi.selectorLabels" -}}
app.kubernetes.io/name: {{ include "streamlit-apps-multi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "streamlit-apps-multi.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "streamlit-apps-multi.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create app-specific fullname
Usage: {{ include "streamlit-apps-multi.appFullname" (dict "appName" "dashboard" "context" .) }}
*/}}
{{- define "streamlit-apps-multi.appFullname" -}}
{{- $appName := .appName -}}
{{- $context := .context -}}
{{- printf "%s-%s" (include "streamlit-apps-multi.fullname" $context) $appName | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create app-specific labels
Usage: {{ include "streamlit-apps-multi.appLabels" (dict "appName" "dashboard" "context" .) }}
*/}}
{{- define "streamlit-apps-multi.appLabels" -}}
{{- $appName := .appName -}}
{{- $context := .context -}}
{{ include "streamlit-apps-multi.labels" $context }}
app.kubernetes.io/component: {{ $appName }}
app: {{ $appName }}
{{- end }}

{{/*
Create app-specific selector labels
Usage: {{ include "streamlit-apps-multi.appSelectorLabels" (dict "appName" "dashboard" "context" .) }}
*/}}
{{- define "streamlit-apps-multi.appSelectorLabels" -}}
{{- $appName := .appName -}}
{{- $context := .context -}}
{{ include "streamlit-apps-multi.selectorLabels" $context }}
app.kubernetes.io/component: {{ $appName }}
app: {{ $appName }}
{{- end }}

{{/*
Get image repository for an app
Usage: {{ include "streamlit-apps-multi.imageRepository" (dict "app" .Values.apps.dashboard "context" .) }}
*/}}
{{- define "streamlit-apps-multi.imageRepository" -}}
{{- $app := .app -}}
{{- $context := .context -}}
{{- if $app.image.repository -}}
{{- $app.image.repository }}
{{- else -}}
{{- $context.Values.global.image.repository }}
{{- end }}
{{- end }}

{{/*
Get image tag for an app
Usage: {{ include "streamlit-apps-multi.imageTag" (dict "app" .Values.apps.dashboard "context" .) }}
*/}}
{{- define "streamlit-apps-multi.imageTag" -}}
{{- $app := .app -}}
{{- $context := .context -}}
{{- if $app.image.tag -}}
{{- $app.image.tag }}
{{- else -}}
{{- $context.Values.global.image.tag | default $context.Chart.AppVersion }}
{{- end }}
{{- end }}

{{/*
Get image pull policy for an app
Usage: {{ include "streamlit-apps-multi.imagePullPolicy" (dict "app" .Values.apps.dashboard "context" .) }}
*/}}
{{- define "streamlit-apps-multi.imagePullPolicy" -}}
{{- $app := .app -}}
{{- $context := .context -}}
{{- if $app.image.pullPolicy -}}
{{- $app.image.pullPolicy }}
{{- else -}}
{{- $context.Values.global.image.pullPolicy }}
{{- end }}
{{- end }}

{{/*
Generate subdomain URL
Usage: {{ include "streamlit-apps-multi.subdomainURL" (dict "subdomain" "dashboard" "context" .) }}
*/}}
{{- define "streamlit-apps-multi.subdomainURL" -}}
{{- $subdomain := .subdomain -}}
{{- $context := .context -}}
{{- printf "%s.%s" $subdomain $context.Values.global.domain }}
{{- end }}
