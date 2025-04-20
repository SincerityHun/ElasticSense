# 추가가 필요한 firewall rule - 예시
firewall_rules = {
  #   "allow-ssh" = {
  #     protocol         = "tcp"
  #     ports            = ["22"]
  #     priority         = "1000"
  #     description      = "Allow SSH access"
  #     tags             = ["ssh"]
  #     source_ip_ranges = ["10.0.0.0/8"]
  #   }
  #   "allow-kubeflow-ui" = {
  #     protocol         = "tcp"
  #     ports            = ["30080", "30100-30110"]
  #     description      = "Kubeflow dashboard"
  #     tags             = ["kubeflow-ui"]
  #     source_ip_ranges = ["0.0.0.0/0"]
  #   }
  #   "allow-internal-all" = {
  #     protocol         = "all"
  #     description      = "Allow all traffic inside 10.200.0.0/16"
  #     source_ip_ranges = ["10.200.0.0/16"]
  #   }
  # Prometheus Rule
  # Grafana Rule
  # Kubeflow Dashboard Rule
  # Interanl Rule
  "allow-custom-svc" = {
    protocol         = "tcp"
    ports            = ["30000","31000","32000", "32687","30318"] # Prometheus, Grafana, AlertManager, kubeflow dashboard(http, https)
    description      = "Allow all traffic inside"
    priority         = "900"
    source_ip_ranges = ["0.0.0.0/0"] # 외부
  }
  "allow-internal-default" = {
    protocol         = "all"
    description      = "Allow all traffic inside"
    priority         = "900"
    source_ip_ranges = ["10.10.0.0/20"] # 서브넷 IP 대역
  }
}
