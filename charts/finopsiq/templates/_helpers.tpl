{{- define "finopsiq.commonEnv" -}}
{{- range $name, $value := .Values.config.env }}
- name: {{ $name }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}

{{- define "finopsiq.configMapName" -}}
{{- default (printf "%s-env" .Values.config.secretName) .Values.config.configMapName -}}
{{- end -}}

{{- define "finopsiq.workloadIdentityEnv" -}}
- name: AZURE_CLIENT_ID
  value: {{ .clientId | quote }}
{{- end }}
