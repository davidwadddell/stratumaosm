{{- define "stratum.initContainer" }}
      initContainers:
       - name: init-registration
         image: {{ .Values.init_container_image }}
         imagePullPolicy: {{ .Values.global.imagePullPolicy }}
         command: ["/bin/sh","-c"]
         args:
          - url01=https://ems01:8443/OAM/restapi/status;
            url02=https://ems02:8443/OAM/restapi/status;
            params='?login=rest&password=restpass';
            until  timeout 2 curl -I -f -k -s ${url01}${params}  || timeout 2 curl -I -f -k -s ${url02}${params}  ; do
              echo $(date +"%b %d %H:%M:%S") "Waiting for the EMS registration server at $url01 or url02";
              sleep 5;
            done
         resources:
{{ toYaml $.Values.initContainers.resources | indent 12 }}
{{- end }}
