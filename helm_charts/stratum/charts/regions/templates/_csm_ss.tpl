{{- define "stratum.csm.ss" }}
{{/* This definition of the csm stateful set is included for each.regionData.namein a site  */}}
---
kind: StatefulSet
apiVersion: apps/v1
metadata:
  name: {{ .Values.global.site }}-{{ .regionData.name}}-{{ .Values.csm.stfl_set_name }}
  namespace: {{ .Release.Namespace }}
spec:
  podManagementPolicy: Parallel
  replicas: {{ .Values.csm.replicas }}
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      name: {{ .Values.csm.pod_name }}
  serviceName: {{ .Values.global.headlessService.name }}
  template:
    metadata:
      labels:
        name: {{ .Values.csm.pod_name }}
        app: {{ .Values.global.headlessService.selectorAppName }}
        ssname: {{ .Values.global.site }}-{{ .regionData.name}}-{{ .Values.csm.stfl_set_name }}        
    spec:
      nodeSelector:
{{- if .Values.csm.nodeSelector }}
{{ toYaml .Values.csm.nodeSelector | indent 8 }}
{{- end }}
      hostAliases: 
{{- range $host := .Values.csm.otherRegionCSMs }}      
      - ip: "{{ $host.ip }}"
        hostnames:
          - {{ $host.hostname }}
{{- end }}
      volumes:
         - name: keys-v
           secret:
                secretName: {{ .Values.global.ssh_Secrets | default .Values.global.ssh_SecretsName }}
                defaultMode: 0600
{{ template "dns.config" $ }}
      securityContext:
        runAsUser: 1401
        fsGroup: 401
{{- if  .Values.global.multiWorkerNode   }}         
      affinity:
{{- template "stratum.affinities" .regionData  }}
{{- end }}
      {{- if .Values.global.imagePullSecrets }}
      imagePullSecrets: {{ toYaml .Values.global.imagePullSecrets | nindent 8 }}
      {{- end }}
{{ template "stratum.initContainer" $ }}
      containers:
       - name: csm
         image: {{ .Values.csm.image | default (print .Values.global.imagesRegistry "/stratum_fe:" .Chart.Version ) }}
         imagePullPolicy: {{ .Values.global.imagePullPolicy }}
{{- if  .Values.global.multiWorkerNode   }}
         resources:
           limits:
             cpu: '{{ .Values.csm.cpu_limit }}'
             memory: {{ .Values.csm.mem_limit }}
           requests:
             cpu: '{{ .Values.csm.cpu_request }}'
             memory: {{ .Values.csm.mem_request }}
{{- end }}
         securityContext:
          capabilities:
            add:
            - NET_BIND_SERVICE
            - SYS_PTRACE
            - AUDIT_WRITE
            - SYS_CHROOT
            - NET_RAW
            - NET_ADMIN
            - SYS_NICE
            # SYS_ADMIN required for running BPF tools (BPF capability only supported in later Linux versions)
            - SYS_ADMIN
#   readiness probe cannot be used with SS, as stratum requires minimum of 3 to form cluster - and k8s won't launch next pod in SS until first is 'ready'
#   update : it can work with spec.podManagementPolicy=Parallel; but that may need review when it comes to patching/upgrade use cases
         readinessProbe:
           exec:
             command: [ "/bin/sh",  "-c", "pgrep -f csm_server" ]
           timeoutSeconds: {{ .Values.csm.readinessProbeTimeout }}
         livenessProbe:
           exec:
             command: [ "/bin/sh",  "-c", "pgrep -f csm_server" ]
           timeoutSeconds: {{ .Values.livenessProbeTimeout }}
           failureThreshold: {{ .Values.csm.livenessFailureThreshold }}
           periodSeconds: {{ .Values.csm.livenessProbePeriod }}
         startupProbe:
           exec:
             command: [ "/bin/sh",  "-c", "pgrep -f csm_server" ]
           timeoutSeconds: {{ .Values.csm.startupProbeTimeout }}
           failureThreshold: {{ .Values.csm.startupFailureThreshold }}
           periodSeconds: {{ .Values.csm.startupProbePeriod }}
         lifecycle:
           preStop:
             exec:
               command: ["/bin/sh","-c","/etc/init.d/oamsca-v* stop"]
         env:
         - name: TZ
           value: {{ .Values.global.timezone }}
         - name: FE_TYPE
           value: CSM
         - name: CONTAINER_TYPE
           value: APP
         - name: REGION
           value: {{ .Values.global.site }}{{ .regionData.name}}
         - name: SITE
           value: {{ .Values.global.site }}
{{- if  .Values.global.useConfigProxies   }}
         - name: CS_HOSTNAME_ENV
           value: {{ .regionData.name}}-{{ .Values.cpx.stfl_set_name}}-0
         - name: CS_OTHER_HOSTNAME_ENV
           value: {{ .regionData.name}}-{{ .Values.cpx.stfl_set_name}}-1
{{- else }}
         - name: CS_HOSTNAME_ENV
           value: ems01
         - name: CS_OTHER_HOSTNAME_ENV
           value: ems02
{{- end }}
         - name: PROCESS_PINNING_ENABLED
           value: "{{ .Values.process_pinning_enabled }}"
         - name:  HOSTS_FILE_UPDATE_INTERVAL
           value: "{{ .Values.hostsFileUpdateInterval }}"
         - name:  NETDATA_PORT
           value: "{{ .Values.netdataConnectionMonitor.port }}"
         - name:  NETDATA_CONNECTION_MONITOR_INTERVAL
           value: "{{ .Values.netdataConnectionMonitor.interval }}"
         - name:  NETDATA_MAXIMUM_CONNECTION_FAILURES
           value: "{{ .Values.netdataConnectionMonitor.maxFailures }}"
         command: ["/bin/sh"]
         args: ["-c", "/opt/opwv/run.sh"]
         volumeMounts:
         - name: logsvol
           mountPath: "/var/opt/opwv/logs"
         - name: keys-v
           mountPath: "/root/.ssh/id_rsa"
           subPath: "id_rsa"
         - name: keys-v
           mountPath: "/root/.ssh/id_rsa.pub"
           subPath: "id_rsa.pub"
         - name: keys-v
           mountPath: "/root/.ssh/id_dsa"
           subPath: "id_dsa"
         - name: keys-v
           mountPath: "/root/.ssh/id_dsa.pub"
           subPath: "id_dsa.pub"
{{- if .Values.global.createCoreVolumes }}
         - name: corevol
           mountPath: "/var/opt/opwv/cores"
{{- end }}
       - name: {{ .Values.csm.ctr_name }}-aggregator
         image: {{ .Values.csm.image | default (print .Values.global.imagesRegistry "/stratum_fe:" .Chart.Version ) }}
         imagePullPolicy: {{ .Values.global.imagePullPolicy }}
{{- if  .Values.global.multiWorkerNode   }}         
         resources:
           limits:         
             cpu: 0.25
             memory: 1024Mi
           requests:
             cpu: 0.25
             memory: 1024Mi
{{- end }}           
         securityContext:
          capabilities:
            add:
            - NET_BIND_SERVICE
            - SYS_NICE
            - SYS_PTRACE
            - AUDIT_WRITE
            - SYS_CHROOT
            - NET_RAW
            - NET_ADMIN
            # SYS_ADMIN required for running BPF tools (BPF capability only supported in later Linux versions)
            - SYS_ADMIN
#   readiness probe cannot be used with SS, as stratum requires minimum of 3 to form cluster - and k8s won't launch next pod in SS until first is 'ready'
#   update : it can work with spec.podManagementPolicy=Parallel; but that may need review when it comes to patching/upgrade use cases
         livenessProbe:
           exec:
             command: [ "/bin/sh",  "-c", "pgrep -f AggregatorService" ]
           timeoutSeconds: {{ .Values.csm.livenessProbeTimeout }}
           failureThreshold: {{ .Values.csm.livenessFailureThreshold }}
           periodSeconds: {{ .Values.csm.livenessProbePeriod }}
         lifecycle:
           preStop:
             exec:
               command: ["/bin/sh","-c"," /etc/init.d/oamsca-v* stop"]
         env:
         - name: TZ
           value: {{ .Values.global.timezone }}
         - name: FE_TYPE
           value: CSM-AGGREGATOR
         - name: CONTAINER_TYPE
           value: AGGREGATOR
         - name: REGION
           value: {{ .Values.global.site }}{{ .regionData.name}}
{{- if  .Values.global.useConfigProxies   }}
         - name: CS_HOSTNAME_ENV
           value: {{ .regionData.name}}-{{ .Values.cpx.stfl_set_name}}-0
         - name: CS_OTHER_HOSTNAME_ENV
           value: {{ .regionData.name}}-{{ .Values.cpx.stfl_set_name}}-1
{{- else }}
         - name: CS_HOSTNAME_ENV
           value: ems01
         - name: CS_OTHER_HOSTNAME_ENV
           value: ems02
{{- end }}
         - name: PROCESS_PINNING_ENABLED
           value: "false"
         - name: SITE
           value: {{ .Values.global.site }}
         - name:  HOSTS_FILE_UPDATE_INTERVAL
           value: "{{ .Values.hostsFileUpdateInterval }}"
         - name:  NETDATA_PORT
           value: "{{ .Values.netdataConnectionMonitor.port }}"
         - name:  NETDATA_CONNECTION_MONITOR_INTERVAL
           value: "{{ .Values.netdataConnectionMonitor.interval }}"
         - name:  NETDATA_MAXIMUM_CONNECTION_FAILURES
           value: "{{ .Values.netdataConnectionMonitor.maxFailures }}"
         command: ["/bin/sh"]
         args: ["-c", "/opt/opwv/run-aggregator.sh"]
  volumeClaimTemplates:
{{- if .Values.global.createCoreVolumes }}
  - metadata:
      name: corevol
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "{{ .Values.global.storageClass }}"
      resources:
        requests:
         storage: {{ .Values.csm.cores_vol_request }}
{{- end }}
  - metadata:
      name: logsvol
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "{{ .Values.global.storageClass }}"
      resources:
        requests:
         storage: {{ .Values.csm.logs_vol_request }}
{{- if .Values.csm.podDisruptionBudget }} 
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ .Values.global.site }}-{{ .regionData.name}}-{{ .Values.csm.stfl_set_name }}-pdb
spec:
{{ toYaml $.Values.csm.podDisruptionBudget | indent 2 }}
  selector:
    matchLabels:
      ssname: {{ .Values.global.site }}-{{ .regionData.name}}-{{ .Values.csm.stfl_set_name }}
{{- end }}
{{- end }}
