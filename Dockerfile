FROM envoyproxy/envoy:v1.29.2

COPY coraza.wasm /etc/envoy/coraza.wasm
COPY envoy.yaml /etc/envoy/envoy.yaml
COPY certificate1.crt /etc/envoy/certificate1.crt
COPY private1.key /etc/envoy/private1.key
COPY ca_bundle1.crt /etc/envoy/ca_bundle1.crt
COPY certificate2.crt /etc/envoy/certificate2.crt
COPY private2.key /etc/envoy/private2.key
COPY ca_bundle2.crt /etc/envoy/ca_bundle2.crt

CMD ["/usr/local/bin/envoy", "-c", "/etc/envoy/envoy.yaml"]
