Day 2：安装 Docker Desktop & CLI
🎯 学习目标

理解容器（Container）与镜像（Image）概念

在 macOS 上安装并验证 Docker Desktop

掌握常用 Docker 命令，为 K8s 打下基础

一、🌱 理论理解：为什么要学 Docker

在 Kubernetes 出现之前，Docker 是容器化的代名词。
K8s 虽然是容器编排系统，但其最底层依赖“容器运行时（Container Runtime）”，而 Docker/Containerd 就是其中最常用的实现。

🔹 容器与虚拟机的区别
特性	虚拟机（VM）	容器（Container）
启动速度	慢（分钟）	快（秒级）
资源开销	高，每个VM有独立OS	轻量，共享宿主机内核
可移植性	一般	极强
典型应用	完整系统隔离	微服务、云原生

📘 容器的核心思想：

打包一次，随处运行（Build once, run anywhere）。

二、🔧 安装 Docker Desktop（macOS）
1️⃣ 下载与安装

访问官方页面：https://www.docker.com/products/docker-desktop

选择对应架构版本：

Apple Silicon (M1/M2/M3)：Docker Desktop for Mac (Apple Chip)

Intel 芯片：Docker Desktop for Mac (Intel Chip)

安装步骤：

双击 .dmg 文件

拖动 Docker 图标到 “Applications”

启动应用并完成初次配置

启动后右上角出现🐳图标即表示运行成功。

2️⃣ 验证安装

打开终端，运行以下命令：

docker version


输出示例：

Client:
 Cloud integration: v1.0.35
 Version: 27.1.1
Server:
 Engine:
  Version: 27.1.1
  OS/Arch: linux/amd64


再执行：

docker run hello-world


预期结果：

Hello from Docker!
This message shows that your installation appears to be working correctly.


✅ 若输出以上内容，说明 Docker Desktop 与 CLI 均安装成功。

三、🧩 理解 Docker 的工作机制
Docker 架构包含三个核心组件：
+--------------------+
| Docker CLI (Client)| ← 你运行的命令：docker run、docker ps
+--------------------+
         ↓
+--------------------+
| Docker Daemon (dockerd) |
| 管理镜像、容器、网络、存储 |
+--------------------+
         ↓
+--------------------+
| Container Runtime (containerd) |
| 真正执行容器生命周期 |
+--------------------+


容器运行的过程：

docker run 向守护进程发送请求；

Docker Daemon 从镜像仓库拉取镜像；

containerd 创建容器并运行；

kubelet（在K8s中）未来会通过 CRI 接口与 containerd 通信。

四、🧠 常用命令练习
镜像（Images）
docker pull nginx
docker images
docker rmi nginx

容器（Containers）
docker run -d --name web -p 8080:80 nginx
docker ps
docker exec -it web bash
docker stop web
docker rm web

构建（Build）
echo "FROM nginx:latest" > Dockerfile
docker build -t mynginx:v1 .

清理
docker system prune -a

五、⚠️ 常见问题与解决方案
问题	原因	解决方法
❌ docker: command not found	PATH 未配置	重新安装或执行 brew install docker
❌ Cannot connect to the Docker daemon	Docker Desktop 未启动	打开应用，确保🐳图标显示为“Running”
❌ 网络拉取慢	国内访问受限	配置加速镜像源（如下）
🇨🇳 Docker Hub 加速器（推荐设置）

打开 Docker Desktop → Settings → Docker Engine
在 JSON 中添加：

{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://mirror.ccs.tencentyun.com"
  ]
}


点击 Apply & Restart。

六、🧭 今日小结

✅ 理解了容器与虚拟机的区别；

✅ 完成 Docker Desktop 安装；

✅ 掌握常用 Docker CLI 命令；

✅ 为 Day3 的 kubectl 与 minikube 环境做好准备。

🧪 今日任务清单
任务	状态
安装 Docker Desktop 并验证	✅
运行 docker run hello-world	✅
拉取并运行 Nginx 镜像	✅
记录学习笔记至 ~/k8s-learning/day2/day2.md	✅