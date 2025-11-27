Day 15：Job 与 CronJob（定时任务与批处理）
🎯 学习目标

理解 Job 与 CronJob 的作用与区别

掌握 Job 的执行机制与重试策略

学会通过 CronJob 实现周期性任务（如数据库备份）

实战：创建一个自动运行的备份 CronJob

一、📖 理论：Job 与 CronJob 是什么？
对象	功能	触发方式	生命周期
Job	一次性批处理任务	手动触发	执行完成即退出
CronJob	定时任务	按时间调度	按周期重复执行

📘 类比：

Deployment：长期运行的服务
Job：一次执行的任务
CronJob：定时执行的任务

二、🧩 Job 工作机制

Job 会创建一个或多个 Pod，直到任务成功完成。
每个 Pod 完成后不会再重启，任务成功后 Job 进入 Completed 状态。

示例：创建一个打印任务

job-echo.yaml

apiVersion: batch/v1
kind: Job
metadata:
  name: echo-job
spec:
  template:
    spec:
      containers:
      - name: echo
        image: busybox
        command: ["sh", "-c", "echo 'Hello, Job from Kubernetes!' && sleep 5"]
      restartPolicy: Never
  backoffLimit: 3


执行：

kubectl apply -f job-echo.yaml
kubectl get jobs


输出：

NAME        COMPLETIONS   DURATION   AGE
echo-job    1/1           5s         1m


查看日志：

kubectl logs job/echo-job


输出：

Hello, Job from Kubernetes!

三、🔁 CronJob 工作机制

CronJob 基于 Linux 的 Cron 表达式（crontab）语法。
可以让 Job 在指定时间自动运行。

📘 语法格式：

┌───────────── 分钟 (0–59)
│ ┌────────── 小时 (0–23)
│ │ ┌─────── 日期 (1–31)
│ │ │ ┌──── 月份 (1–12)
│ │ │ │ ┌── 星期 (0–6)
│ │ │ │ │
│ │ │ │ │
* * * * *  <command>


例如：

*/5 * * * * → 每 5 分钟执行一次

0 2 * * * → 每天凌晨 2 点执行一次

0 */6 * * * → 每 6 小时执行一次

四、📦 实战：创建一个定时备份任务 CronJob

我们模拟一个“每天凌晨 2 点执行数据库备份”的任务。
任务会将备份文件写入 /data/backup/ 目录。

Step 1️⃣：创建本地备份路径
sudo mkdir -p /data/backup

Step 2️⃣：定义 CronJob 文件

cronjob-backup.yaml

apiVersion: batch/v1
kind: CronJob
metadata:
  name: db-backup
spec:
  schedule: "0 2 * * *"         # 每天凌晨 2 点执行
  successfulJobsHistoryLimit: 3 # 保留最近 3 次成功任务
  failedJobsHistoryLimit: 1     # 保留最近 1 次失败任务
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: db-backup
            image: busybox
            command:
            - /bin/sh
            - -c
            - >
              echo "[$(date)] Starting database backup..." &&
              mkdir -p /backup &&
              echo "Backup Data $(date)" > /backup/db-backup-$(date +%F-%H-%M).txt &&
              echo "Backup completed."
            volumeMounts:
            - name: backup-volume
              mountPath: /backup
          restartPolicy: OnFailure
          volumes:
          - name: backup-volume
            hostPath:
              path: /data/backup


执行：

kubectl apply -f cronjob-backup.yaml

Step 3️⃣：验证 CronJob

查看 CronJob：

kubectl get cronjob


输出：

NAME         SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
db-backup    0 2 * * *     False     0        <none>          1m

Step 4️⃣：手动触发执行（调试用）

你可以临时修改执行周期为每分钟：

kubectl edit cronjob db-backup


修改为：

schedule: "*/1 * * * *"


等待 1 分钟后查看：

kubectl get jobs


输出：

NAME                COMPLETIONS   DURATION   AGE
db-backup-289bd     1/1           3s         1m


查看日志：

kubectl logs job/db-backup-289bd


输出：

[Sat Nov 16 02:00:00 UTC 2025] Starting database backup...
Backup completed.

Step 5️⃣：验证备份文件是否生成
sudo ls /data/backup


输出：

db-backup-2025-11-16-02-00.txt


✅ 每次任务都会生成一个新的备份文件。

五、🧠 Job & CronJob 核心参数说明
参数	说明
restartPolicy	Pod 失败后的重启策略（Never / OnFailure）
backoffLimit	最大重试次数
schedule	Cron 表达式
concurrencyPolicy	是否允许并行运行（Allow、Forbid、Replace）
successfulJobsHistoryLimit	保留成功 Job 的数量
failedJobsHistoryLimit	保留失败 Job 的数量
六、📘 可视化理解
       ┌────────────────────────────┐
       │       CronJob (定时器)      │
       │ schedule: 0 2 * * *         │
       └──────────────┬─────────────┘
                      │ 每天触发
                      ↓
       ┌────────────────────────────┐
       │           Job              │
       │   创建 Pod 运行一次任务     │
       └──────────────┬─────────────┘
                      │
                      ↓
       ┌────────────────────────────┐
       │           Pod              │
       │ echo "Backup completed."   │
       └────────────────────────────┘

七、📗 今日任务清单
任务	文件	命令	状态
创建一次性 Job	job-echo.yaml	kubectl apply	✅
创建 CronJob 定时任务	cronjob-backup.yaml	kubectl apply	✅
调整调度周期为每分钟测试	kubectl edit cronjob	✅	
查看任务执行日志	kubectl logs job/<job-name>	✅	
验证备份文件生成	ls /data/backup	✅	
保存学习笔记	~/k8s-learning/day15/day15-job-cronjob.md	✍️	
八、📘 今日总结

✅ 理解 Job 与 CronJob 的区别与用途；

✅ 掌握 Cron 表达式的时间控制；

✅ 学会创建周期性任务并持久化输出结果；

✅ 完成了数据库备份 CronJob 的实战部署。