在企业级私有网络（VNet）环境下，实现方案一 (ZipDeploy via Entra Token) 需要解决两个核心挑战：身份鉴权（不使用密码，使用 Service Principal Token）和网络路径（确保 Pipeline 能打通 SCM 内部端点）。

以下是方案一的详细实现步骤：

1. 基础设施要求 (Terraform 配置)
要让方案一工作，你的 Azure Function App 需要满足以下网络和配置条件：

Terraform
```
resource "azurerm_linux_function_app" "app" {
  # ... 其他配置
  
  site_config {
    # 必须开启，确保 SCM (Kudu) 也能在 VNet 内通信
    vnet_route_all_enabled = true
  }

  app_settings = {
    # 1. 必须禁用这个，否则本地磁盘文件会被覆盖，导致 ZipDeploy 失败
    "WEBSITE_RUN_FROM_PACKAGE" = "0"
    
    # 2. 必须设置 PYTHONPATH，否则 Python 找不到你的依赖包
    "PYTHONPATH" = "/home/site/wwwroot/.python_packages/lib/site-packages"
    
    # 3. 告诉 Kudu 已经在 Pipeline 构建好了，不需要远程再 pip install
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "false"
  }
}
```
2. Azure DevOps Pipeline 实现
这个过程分为 Build（生产 Linux 兼容包）和 Deploy（通过 Token 调用 API）两个阶段。

阶段 A：Build (必须使用 Ubuntu Agent)
```
YAML

- job: Build
  pool:
    vmImage: 'ubuntu-latest' # 关键：必须是 Linux，确保下载的 .so 兼容 EP1
  steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '3.11'

    - script: |
        # 1. 安装依赖到特定目录
        python -m pip install --upgrade pip
        pip install -r requirements.txt --target ".python_packages/lib/site-packages"
        
        # 2. 压缩。注意：不要包含父文件夹，直接压内容
        zip -r $(Build.ArtifactStagingDirectory)/app.zip . -x "*.git*"
      displayName: 'Install dependencies and Package'

    - publish: $(Build.ArtifactStagingDirectory)/app.zip
      artifact: drop
```
阶段 B：Deploy (使用 Entra ID Token)
此步骤模拟了 az functionapp deployment 的底层逻辑，但使用了更安全的 Token 方式。

PowerShell
```
# 在 AzureCLI@2 任务中执行
$zipPath = "$(Pipeline.Workspace)/drop/app.zip"

# 1. 获取当前 Service Connection 的 Entra ID Token
$accessToken = az account get-access-token --query accessToken -o tsv

# 2. 构造 Kudu ZipDeploy URL
$scmUrl = "https://<APP_NAME>.scm.azurewebsites.net/api/zipdeploy?isAsync=true"

# 3. 发起 POST 请求
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/zip"
}

Write-Host "Deploying to $scmUrl ..."
Invoke-RestMethod -Uri $scmUrl -Method Post -Headers $headers -InFile $zipPath -ContentType "application/zip"
```
方案B pipeline
```
- stage: Deploy
  dependsOn: Build
  jobs:
  - job: DeployJob
    pool:
      vmImage: 'windows-latest' # 按照你的要求使用 Windows
    steps:
    - download: current
      artifact: drop

    - task: AzureCLI@2
      displayName: 'ZipDeploy via PowerShell'
      inputs:
        azureSubscription: '<你的服务连接名称>'
        scriptType: 'pscore' # 建议使用 PowerShell Core
        scriptLocation: 'inlineScript'
        inlineScript: |
          $zipPath = "$(Pipeline.Workspace)\drop\app.zip"
          
          # 1. 获取 Entra ID Token (Service Principal 身份)
          $accessToken = az account get-access-token --query accessToken -o tsv
          
          # 2. 构造 SCM 部署 URL
          $scmUrl = "https://$(functionAppName).scm.azurewebsites.net/api/zipdeploy?isAsync=true"
          
          # 3. 准备请求头
          $headers = @{
              "Authorization" = "Bearer $accessToken"
          }

          # 4. 执行部署
          Write-Host "Connecting to SCM: $scmUrl"
          try {
              $response = Invoke-RestMethod -Uri $scmUrl `
                                           -Method Post `
                                           -Headers $headers `
                                           -InFile $zipPath `
                                           -ContentType "application/zip" `
                                           -TimeoutSec 300
              Write-Host "Deployment Accepted. Status: $($response.status)"
          } catch {
              Write-Error "Deployment failed: $_"
              exit 1
          }
```
3. 方案一成功的 3 个关键检查点
检查点 1：网络连通性 方案一要求你的 Pipeline Agent 能够解析并访问 <app>.scm.azurewebsites.net。如果你的 SCM 开启了 Private Endpoint，普通的 GitHub/Azure Hosted Agent 是连不上的，你必须使用 Self-hosted Agent（安装在你的 VNet 内部）。

检查点 2：身份权限 执行 Pipeline 的 Service Principal 必须对 Function App 拥有 Contributor (参与者) 或 Website Contributor 权限，否则无法获取有效 Token 进行部署。

检查点 3：只读模式冲突 如果你之前尝试过“方案三 (Run From Package)”，请务必去 Portal 删掉 WEBSITE_RUN_FROM_PACKAGE 这个配置。如果这个配置存在且为 URL，ZipDeploy 虽然会显示成功，但你的代码永远不会更新，因为磁盘被只读挂载挡住了。