{{- define "stratum.affinities" }}
{{- /* this nested template defines affinities for pods  */}}
{{- if ( or (not (empty (.affinities).requiredAffinity ))  (not (empty (.affinities).preferredAffinity))    ) }}
        nodeAffinity:
{{- if ( not (empty .affinities.requiredAffinity )) }}
{{- $parts := split " " .affinities.requiredAffinity }}
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: {{ $parts._0 }}
                operator: {{ $parts._1 }}
                values: [ {{ $parts._2 }} ]
{{- end }}
{{- if ( not (empty .affinities.preferredAffinity )) }}
{{- $parts := split " " .affinities.preferredAffinity }}
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            preference:
              matchExpressions:
              - key:  {{  $parts._0}}
                operator:  {{ $parts._1 }}
                values:  [ {{ $parts._2 }} ]
{{- end }}
{{- end }}
{{- end }}
