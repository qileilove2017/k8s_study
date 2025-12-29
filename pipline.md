pipeline
```
trigger:
  - main  # 触发分支

pool:
  vmImage: 'windows-latest' # 你的 Windows Agent

variables:
  # ================= 配置区域 =================
  # 你的 Service Connection 名称
  azureServiceConnection: 'MyAzureServiceConnection'
  
  # 资源组名称
  resourceGroupName: 'my-resource-group'
  
  # Function App 名称
  functionAppName: 'my-python-function'
  
  # 存储账号名称 (已与 CMK 绑定)
  storageAccountName: 'mystorageaccount'
  
  # 存放部署包的容器名称 (确保该容器已存在，且为 Private 访问级别)
  containerName: 'releases'
  
  # Python 版本 (必须与 Azure Function 设置的一致)
  pythonVersion: '3.9'
  # ===========================================

steps:
  # 1. 设置 Python 环境
  - task: UsePythonVersion@0
    displayName: 'Use Python $(pythonVersion)'
    inputs:
      versionSpec: '$(pythonVersion)'
      addToPath: true

  # 2. 安装依赖 (关键步骤：处理 Windows -> Linux 兼容性)
  # 我们将依赖安装到 .python_packages/lib/site-packages 目录，这是 Azure Function 默认识别的路径
  - script: |
      echo "Installing Linux dependencies on Windows..."
      pip install --target="./.python_packages/lib/site-packages" -r ./requirements.txt --platform manylinux2014_x86_64 --only-binary=:all: --implementation cp --python-version $(pythonVersion)
    displayName: 'Install Linux Dependencies'

  # 3. 打包文件
  # 注意：includeRootFolder: false 确保 host.json 直接位于 Zip 根目录
  - task: ArchiveFiles@2
    displayName: 'Archive files'
    inputs:
      rootFolderOrFile: '$(System.DefaultWorkingDirectory)'
      includeRootFolder: false
      archiveType: 'zip'
      archiveFile: '$(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip'
      replaceExistingArchive: true
      # 排除不必要的文件以减小包体积
      verbose: true 

  # 4. 上传并部署 (使用 Azure CLI 绕过 401)
  - task: AzureCLI@2
    displayName: 'Upload to Storage & Update Function'
    inputs:
      azureSubscription: '$(azureServiceConnection)'
      scriptType: 'ps' # PowerShell Core
      scriptLocation: 'inlineScript'
      inlineScript: |
        $rg = "$(resourceGroupName)"
        $appName = "$(functionAppName)"
        $stAccount = "$(storageAccountName)"
        $container = "$(containerName)"
        $zipPath = "$(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip"
        $blobName = "app-$(Build.BuildId).zip"

        Write-Host "1. Uploading zip to Azure Storage (using Azure AD auth)..."
        # 使用 --auth-mode login 确保使用 Service Principal 权限，而不是 Access Key (CMK 环境下 Key 可能受限)
        az storage blob upload `
          --account-name $stAccount `
          --container-name $container `
          --name $blobName `
          --file $zipPath `
          --auth-mode login `
          --overwrite

        Write-Host "2. Constructing Blob URL..."
        # 构造直连 URL，不带 SAS Token
        $blobUrl = "https://$stAccount.blob.core.windows.net/$container/$blobName"
        Write-Host "Blob URL: $blobUrl"

        Write-Host "3. Updating Function App settings to trigger deployment..."
        # 这一步 100% 绕过 SCM/Basic Auth。Function 会用自己的 Managed Identity 去下载这个 URL。
        az functionapp config appsettings set `
          --resource-group $rg `
          --name $appName `
          --settings WEBSITE_RUN_FROM_PACKAGE="$blobUrl"
```