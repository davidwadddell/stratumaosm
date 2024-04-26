{{- define "stratum.csm.service" }}
{{/* This definition of the csm services is included for each.regionData.namein a site  */}}
{{- $portStart := $.Values.csmServices.portRange.start  | int  }}
{{- $portEnd := $.Values.csmServices.portRange.end | int }}
{{- range $i, $ip := $.regionData.csmLoadBalancerIPs }}
---
# service to expose remotely {{ $.regionData.name}}-{{ $.Values.csm.stfl_set_name }}-{{$i}}
apiVersion: v1
kind: Service
metadata:
  name: {{ $.Values.global.site}}-{{ $.regionData.name}}-csm-{{ $i }}
  namespace: {{ $.Release.Namespace }}
spec:
  type: LoadBalancer
  loadBalancerIP: {{ $ip }}
  ports:
{{-  range  untilStep $portStart  $portEnd 1 }}
    - protocol: UDP
      name: csm-{{ . }}
      port: {{ . }}
{{- end }} {{/* # end range ports */}}
  selector:
    statefulset.kubernetes.io/pod-name: {{ $.Values.global.site}}-{{ $.regionData.name}}-{{ $.Values.csm.stfl_set_name }}-{{$i}}
{{- end }}

{{- end }}
