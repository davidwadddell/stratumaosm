{{- define "stratum.adm.ss" }}
{{/* This definition of the adm stateful set is included for each.regionData.namein a site  */}}
---
kind: StatefulSet
apiVersion: apps/v1
metadata:
  name: {{ .Values.global.site }}-{{ .regionData.name}}-{{ .Values.adm.stfl_set_name }}
  namespace: {{ .Release.Namespace }}
spec:
  podManagementPolicy: Parallel
  replicas: {{ .Values.adm.replicas }}
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      name: {{ .Values.adm.pod_name }}
  serviceName: {{ .Values.global.headlessService.name }}
  template:
    metadata:
      labels:
        name: {{ .Values.adm.pod_name }}
        app:  {{ .Values.global.headlessService.selectorAppName }}
        ssname: {{ .Values.global.site }}-{{ .regionData.name}}-{{ .Values.adm.stfl_set_name }}
    spec:
      nodeSelector: 
{{- if .Values.adm.nodeSelector }} 
{{ toYaml .Values.adm.nodeSelector | indent 8 }}
{{- end }}
      volumes:
        - name: keys-v
          secret:
              secretName: {{ .Values.global.ssh_Secrets | default .Values.global.ssh_SecretsName }}
              defaultMode: 0600 
                
      affinity:
{{- template "stratum.affinities" .regionData  }}
{{ template "dns.config" $ }}
      securityContext:
        runAsUser: 1401
        fsGroup: 401
      {{- if .Values.global.imagePullSecrets }}
      imagePullSecrets: {{ toYaml .Values.global.imagePullSecrets | nindent 8 }}
      {{- end }}
{{ template "stratum.initContainer" $ }}
      containers:
       - name: {{ .Values.adm.ctr_name }}
         image: {{ .Values.adm.image | default (print .Values.global.imagesRegistry "/stratum_fe:" .Chart.Version ) }}
         imagePullPolicy: {{ .Values.global.imagePullPolicy }}
{{- if  .Values.global.multiWorkerNode   }}         
         resources:
           limits:         
             cpu: '{{ .Values.adm.cpu_limit }}'
             memory: {{ .Values.adm.mem_limit }}
           requests:
             cpu: '{{ .Values.adm.cpu_request }}'
             memory: {{ .Values.adm.mem_request }} 
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
         readinessProbe:
           exec:  
             command: [ "/bin/sh",  "-c", "/opt/opwv/adm_readiness_check.sh {{ .Values.adm.readiness_ipc_timeout_secs }} {{ .Values.adm.readiness_ipc_port }}" ]
           timeoutSeconds: {{ .Values.adm.readinessProbeTimeout }}
         livenessProbe:
           exec:
             command: [ "/bin/sh",  "-c", "pgrep -f adm_server" ]
           timeoutSeconds: {{ .Values.adm.livenessProbeTimeout }}
           failureThreshold: {{ .Values.adm.livenessFailureThreshold }}
           periodSeconds: {{ .Values.adm.livenessProbePeriod }}
         startupProbe:
           exec:
             command: [ "/bin/sh",  "-c", "/opt/opwv/adm_readiness_check.sh {{ .Values.adm.readiness_ipc_timeout_secs }} {{ .Values.adm.readiness_ipc_port }}" ]
           timeoutSeconds: {{ .Values.adm.startupProbeTimeout }}
           failureThreshold: {{ .Values.adm.startupFailureThreshold }}
           periodSeconds: {{ .Values.adm.startupProbePeriod }}           
         lifecycle:
           preStop:
             exec:
               command: ["/bin/sh","-c"," /etc/init.d/oamsca-v* stop"]
         env:
         - name: TZ
           value: {{ .Values.global.timezone }}
         - name: FE_TYPE
           value: ADM
         - name: CONTAINER_TYPE
           value: APP
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
           value: "{{ .Values.process_pinning_enabled }}"
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
         args: ["-c", "/opt/opwv/run.sh"]
         volumeMounts:
{{- if .Values.adm.createDdmVolumes }}
         - name: ddmvol
           mountPath: "/opt/opwv/sdmce/ddm"
{{- end }}
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
       - name: {{ .Values.adm.ctr_name }}-aggregator
         image: {{ .Values.adm.image | default (print .Values.global.imagesRegistry "/stratum_fe:" .Chart.Version ) }}
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
           timeoutSeconds: {{ .Values.adm.livenessProbeTimeout }}
           failureThreshold: {{ .Values.adm.livenessFailureThreshold }}
           periodSeconds: {{ .Values.adm.livenessProbePeriod }}
         lifecycle:
           preStop:
             exec:
               command: ["/bin/sh","-c"," /etc/init.d/oamsca-v* stop"]
         env:
         - name: TZ
           value: {{ .Values.global.timezone }}
         - name: FE_TYPE
           value: ADM-AGGREGATOR
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
{{- if .Values.adm.createDdmVolumes }}
  - metadata:
      name: ddmvol
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "{{ .Values.global.storageClass }}"
      resources:
        requests:
         storage: {{ .Values.adm.ddm_vol_request }}
{{- end }}
{{- if .Values.global.createCoreVolumes }}         
  - metadata:
      name: corevol
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "{{ .Values.global.storageClass }}"
      resources:
        requests:
         storage: {{ .Values.adm.cores_vol_request }}
{{- end }}
  - metadata:
      name: logsvol
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "{{ .Values.global.storageClass }}"
      resources:
        requests:
         storage: {{ .Values.adm.logs_vol_request }}
{{- if .Values.adm.podDisruptionBudget }} 
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ .Values.global.site }}-{{ .regionData.name}}-{{ .Values.adm.stfl_set_name }}-pdb
spec:
{{ toYaml .Values.adm.podDisruptionBudget | indent 2 }}
  selector:
    matchLabels:
      ssname: {{ .Values.global.site }}-{{ .regionData.name}}-{{ .Values.adm.stfl_set_name }}
{{- end }}
{{- end }}
