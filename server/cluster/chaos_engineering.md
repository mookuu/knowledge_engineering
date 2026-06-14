# 混沌工程工具

## 什么是混沌工程

**混沌工程（Chaos Engineering）** 是通过主动注入故障来验证系统韧性（Resilience）的实验性方法。核心原则：**提前发现故障，避免线上事故**。

## 主流工具对比

### 开源工具

| 工具                | 语言 | 维护方       | 适用场景          | 特点                                             |
| ------------------- | ---- | ------------ | ----------------- | ------------------------------------------------ |
| **Chaos Mesh**      | Go   | CNCF/PingCAP | Kubernetes        | ✅ CNCF 孵化项目，Dashboard 可视化，故障类型丰富 |
| **Litmus**          | Go   | CNCF         | Kubernetes        | ✅ CNCF 项目，支持自动化工作流，GitOps 集成      |
| **ChaosBlade**      | Go   | 阿里云       | K8s + 主机 + 应用 | ✅ 支持多平台，故障类型最全                      |
| **Toxiproxy**       | Go   | Shopify      | 网络代理          | ✅ 轻量级，适合模拟网络延迟/断连                 |
| **ByteDance Chaos** | Go   | 字节跳动     | Kubernetes        | 字节内部开源，支持混沌工程平台化                 |
| **Mangle**          | Java | VMware       | Java 应用 + K8s   | 支持在 Java 应用层注入故障                       |

### 商业/云平台

| 工具                                  | 提供商      | 特点                                  |
| ------------------------------------- | ----------- | ------------------------------------- |
| **Gremlin**                           | Gremlin Inc | 老牌商业平台，Web UI + 调度 + 报表    |
| **Azure Chaos Studio**                | 微软        | Azure 原生集成，与 Azure 资源深度绑定 |
| **AWS FIS** (Fault Injection Service) | AWS         | AWS 原生托管服务                      |
| **阿里云 AHAS**                       | 阿里云      | 阿里云混沌工程平台                    |

## Chaos Mesh 支持的故障类型

| 故障类型          | 说明                           |
| ----------------- | ------------------------------ |
| **Pod Chaos**     | 删除/杀死 Pod                  |
| **Network Chaos** | 网络延迟、丢包、分区、带宽限制 |
| **DNS Chaos**     | DNS 解析错误                   |
| **HTTP Chaos**    | HTTP 请求故障注入              |
| **IO Chaos**      | 磁盘读写延迟/错误              |
| **Stress Chaos**  | CPU/内存压力注入               |
| **Time Chaos**    | 时间偏移                       |
| **Kernel Chaos**  | 内核故障注入（eBPF）           |

## 如何选择

```
你的场景是什么？
├── 有 Kubernetes 集群
│   ├── 想要可视化 UI → Chaos Mesh
│   ├── 需要 GitOps 工作流 → Litmus
│   └── 需要主机 + 应用层支持 → ChaosBlade
├── 只需要网络故障模拟
│   └── Toxiproxy（最轻量）
└── 使用云平台
    ├── Azure → Azure Chaos Studio
    ├── AWS → AWS FIS
    └── 阿里云 → AHAS / ChaosBlade
```

## 快速入门

### Chaos Mesh（K8s + Helm）

```bash
# 前提：已有 K8s 集群 + Helm 3
helm repo add chaos-mesh https://charts.chaos-mesh.org
kubectl create ns chaos-mesh
helm install chaos-mesh chaos-mesh/chaos-mesh -n=chaos-mesh --version 2.8.2

# 访问 Dashboard
kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333
# 浏览器打开 http://localhost:2333
```

### Toxiproxy（本地网络测试）

```bash
# 安装
go install github.com/Shopify/toxiproxy/v2/cmd/toxiproxy-cli@latest

# 启动 Toxiproxy 服务
toxiproxy-server
```

## 参考资料

- [Chaos Mesh 官方文档](https://chaos-mesh.org/docs/)
- [Litmus 官方文档](https://litmuschaos.io/docs/)
- [ChaosBlade GitHub](https://github.com/chaosblade-io/chaosblade)
- [Toxiproxy GitHub](https://github.com/Shopify/toxiproxy)
- [混沌工程原则（Principles of Chaos Engineering）](https://principlesofchaos.org/)
