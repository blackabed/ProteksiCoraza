#!/bin/bash

# Function to configure domains and IPs
configure_domains_and_ips() {
  read -p "Enter the domain for backend_service1: " backend_service1_domain
  read -p "Enter the IP address for backend_service1: " backend_service1_ip
  read -p "Enter the domain for backend_service2: " backend_service2_domain
  read -p "Enter the IP address for backend_service2: " backend_service2_ip

  # Generate the envoy.yaml configuration
  cat <<EOL > envoy.yaml
stats_config:
  stats_tags:
    - tag_name: phase
      regex: "(_phase=([a-z_]+))"
    - tag_name: rule_id
      regex: "(_ruleid=([0-9]+))"
    - tag_name: authority
      regex: "(_authority=([0-9a-z.:]+))"

static_resources:
  listeners:
    - address:
        socket_address:
          address: 0.0.0.0
          port_value: 443
      filter_chains:
        - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                access_log:
                  - name: envoy.access_loggers.file
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
                      log_format:
                        json_format:
                          authority: '%REQ(:AUTHORITY)%'
                          bytes_received: '%BYTES_RECEIVED%'
                          bytes_sent: '%BYTES_SENT%'
                          connection_termination_details: '%CONNECTION_TERMINATION_DETAILS%'
                          downstream_local_address: '%DOWNSTREAM_LOCAL_ADDRESS%'
                          downstream_remote_address: '%DOWNSTREAM_REMOTE_ADDRESS%'
                          duration: '%DURATION%'
                          method: '%REQ(:METHOD)%'
                          path: '%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%'
                          protocol: '%PROTOCOL%'
                          request_id: '%REQ(X-REQUEST-ID)%'
                          requested_server_name: '%REQUESTED_SERVER_NAME%'
                          response_code: '%RESPONSE_CODE%'
                          response_code_details: '%RESPONSE_CODE_DETAILS%'
                          response_flags: '%RESPONSE_FLAGS%'
                          route_name: '%ROUTE_NAME%'
                          start_time: '%START_TIME%'
                          upstream_cluster: '%UPSTREAM_CLUSTER%'
                          upstream_host: '%UPSTREAM_HOST%'
                          upstream_local_address: '%UPSTREAM_LOCAL_ADDRESS%'
                          upstream_service_time: '%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%'
                          upstream_transport_failure_reason: '%UPSTREAM_TRANSPORT_FAILURE_REASON%'
                          user_agent: '%REQ(USER-AGENT)%'
                          x_forwarded_for: '%REQ(X-FORWARDED-FOR)%'
                      path: /var/log/envoy/access.log
                codec_type: auto
                use_remote_address: true
                normalize_path: true
                merge_slashes: true
                path_with_escaped_slashes_action: UNESCAPE_AND_REDIRECT
                common_http_protocol_options:
                  idle_timeout: 3600s
                  headers_with_underscores_action: REJECT_REQUEST
                stream_idle_timeout: 300s
                request_timeout: 300s
                stat_prefix: ingress_http
                route_config:
                  name: local_route
                  virtual_hosts:
                    - name: backend_service1
                      domains:
                        - "$backend_service1_domain"
                      routes:
                        - match:
                            prefix: "/"
                          route:
                            cluster: backend_service1
                            idle_timeout: 15s
                    - name: backend_service2
                      domains:
                        - "$backend_service2_domain"
                      routes:
                        - match:
                            prefix: "/"
                          route:
                            cluster: backend_service2
                            idle_timeout: 15s
                http_filters:
                  - name: envoy.filters.http.wasm
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
                      config:
                        name: "coraza-filter"
                        root_id: "coraza"
                        configuration:
                          "@type": "type.googleapis.com/google.protobuf.StringValue"
                          value: >
                            {
                              "directives_map": {
                                  "coreruleset": [
                                    "Include @demo-conf",
                                    "Include @crs-setup-conf",
                                    "SecRuleEngine On",
                                    "SecDebugLogLevel 3",
                                    "Include @owasp_crs/*.conf"
                                  ]
                              },
                              "default_directives": "coreruleset"
                            }
                        vm_config:
                          runtime: "envoy.wasm.runtime.v8"
                          vm_id: "coraza"
                          code:
                            local:
                              filename: "/etc/envoy/coraza.wasm"
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
          transport_socket:
            name: envoy.transport_sockets.tls
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
              common_tls_context:
                tls_certificates:
                  - certificate_chain:
                      filename: "/etc/envoy/certificate1.crt"
                    private_key:
                      filename: "/etc/envoy/private1.key"
                  - certificate_chain:
                      filename: "/etc/envoy/certificate2.crt"
                    private_key:
                      filename: "/etc/envoy/private2.key"
                validation_context:
                  trusted_ca:
                    filename: "/etc/envoy/ca_bundle1.crt"
                    filename: "/etc/envoy/ca_bundle2.crt"
                tls_params:
                  tls_minimum_protocol_version: TLSv1_2
                  tls_maximum_protocol_version: TLSv1_3

    - address:
        socket_address:
          address: 0.0.0.0
          port_value: 80
      filter_chains:
        - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: http_redirect
                route_config:
                  name: redirect_route
                  virtual_hosts:
                    - name: redirect_host
                      domains: ["*"]
                      routes:
                        - match:
                            prefix: "/"
                          redirect:
                            https_redirect: true
                http_filters:
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router

  clusters:
    - name: backend_service1
      per_connection_buffer_limit_bytes: 3276
      connect_timeout: 1s
      type: STATIC
      load_assignment:
        cluster_name: backend_service1
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: $backend_service1_ip
                      port_value: 80
    - name: backend_service2
      per_connection_buffer_limit_bytes: 3276
      connect_timeout: 1s
      type: STATIC
      load_assignment:
        cluster_name: backend_service2
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: $backend_service2_ip
                      port_value: 80

admin:
  access_log_path: "/var/log/envoy/error.log"
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 9901

overload_manager:
  refresh_interval: 0.25s
  resource_monitors:
    - name: "envoy.resource_monitors.fixed_heap"
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.resource_monitors.fixed_heap.v3.FixedHeapConfig
        max_heap_size_bytes: 2147483648
  actions:
    - name: "envoy.overload_actions.shrink_heap"
      triggers:
        - name: "envoy.resource_monitors.fixed_heap"
          threshold:
            value: 0.95
    - name: "envoy.overload_actions.stop_accepting_requests"
      triggers:
        - name: "envoy.resource_monitors.fixed_heap"
          threshold:
            value: 0.98

layered_runtime:
  layers:
    - name: static_layer_0
      static_layer:
        envoy:
          resource_limits:
            listener:
              example_listener_name:
                connection_limit: 10000
        overload:
          global_downstream_max_connections: 50000
EOL

  echo "envoy.yaml has been generated."
}

# Function to run the Web Application Firewall
run_waf() {
  docker-compose build
  docker-compose up -d
}

# Function to stop the Web Application Firewall
stop_waf() {
  docker-compose down
}

# Main menu loop
while true; do
  echo "1. Configure Domains and IPs"
  echo "2. Run the Web Application Firewall"
  echo "3. Stop the Web Application Firewall"
  echo "4. Exit"
  read -p "Please enter your choice: " choice

  case $choice in
    1)
      configure_domains_and_ips
      ;;
    2)
      run_waf
      ;;
    3)
      stop_waf
      ;;
    4)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid choice. Please select 1, 2, 3, or 4."
      ;;
  esac
done
