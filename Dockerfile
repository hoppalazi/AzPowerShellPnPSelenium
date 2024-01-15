FROM mcr.microsoft.com/azure-powershell:11.2.0-ubuntu-22.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    curl \
    git \
    gpg \
    jq \
    unzip \
    wget \
    # Add Microsoft gpg key
    && wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft-edge.gpg && \
    # Specify an arch as Microsoft repository supports armhf and arm64 as well
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list && \
    # Install Microsoft Edge
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install --no-install-recommends microsoft-edge-stable -y && \
    # Create Microsoft Edge Webdriver directory
    mkdir -p /usr/local/share/edge_driver && \
    # Get Microsoft Edge version
    EDGE_VERSION=$(microsoft-edge --version | cut -d' ' -f 3) && \
    EDGE_VERSION_MAJOR=$(echo $EDGE_VERSION | cut -d'.' -f 1) && \
    # Create Microsoft Edge Webdriver download url
    EDGE_DRIVER_VERSION_URL="https://msedgedriver.azureedge.net/LATEST_RELEASE_${EDGE_VERSION_MAJOR}_LINUX" && \
    # Convert a resulting file to normal UTF-8
    EDGE_DRIVER_LATEST_VERSION=$(curl -s "$EDGE_DRIVER_VERSION_URL" | iconv -f utf-16 -t utf-8 | tr -d '\r') && \
    EDGEDRIVER_URL="https://msedgedriver.azureedge.net/${EDGE_DRIVER_LATEST_VERSION}/edgedriver_linux64.zip" && \
    curl $EDGEDRIVER_URL -4 -sL -o "/tmp/edgedriver_linux64.zip" && \
    # Unzip file, make it executable and create link
    unzip -qq /tmp/edgedriver_linux64.zip -d /usr/local/share/edge_driver && \
    rm /tmp/edgedriver_linux64.zip && \
    chmod +x /usr/local/share/edge_driver/msedgedriver && \
    ln -s /usr/local/share/edge_driver/msedgedriver /usr/bin && \
    rm -rf /var/lib/apt/lists/* && \
    pwsh \
    -NoLogo \
    -NoProfile \
    -Command " \
    \$ErrorActionPreference = 'Stop' ; \
    \$ProgressPreference = 'SilentlyContinue' ; \
    # Install Microsoft.PowerShell.PSResourceGet to prevent a dependency error with PowerShellGetv2 Install-Package
    Install-Module -Name Microsoft.PowerShell.PSResourceGet -Repository PSGallery -Scope AllUsers -Force -AllowPrerelease ; \
    # Import Microsoft.PowerShell.PSResourceGet Module
    Import-Module -Global -Name Microsoft.PowerShell.PSResourceGet ; \
    # Register NuGet repository
    Register-PSResourceRepository -Name nuget.org -Uri https://api.nuget.org/v3/index.json -Trusted:\$false -Priority 50 ; \
    # Install Selenium.WebDriver package
    Install-PSResource -Name Selenium.WebDriver -Version 4.16.2 -Repository nuget.org -Scope AllUsers -TrustRepository ; \
    # Create symbolic link to Selenium.WebDriver
    New-Item -Path /usr/local/share/ -Name Selenium.WebDriver.dll -ItemType SymbolicLink -Value /usr/local/share/powershell/Modules/Selenium.WebDriver/4.14.1/lib/net6.0/WebDriver.dll | Out-Null ; \
    # Install PnP.PowerShell Module
    Install-PSResource -Name PnP.PowerShell -Version 2.3.0 -Repository PSGallery -Scope AllUsers -TrustRepository ; \
    # Install PSFramework Module
    Install-PSResource -Name PSFramework -Version 1.10.318 -Repository PSGallery -Scope AllUsers -TrustRepository ; \
    # Remove PowerShellGetv3 Module
    Get-Module -Name PowerShellGet -ListAvailable | Where-Object {\$PSItem.Version.Major -eq 3} | Uninstall-Module -Force ; "

# Set environment variable
# Set the ACCEPT_EULA variable to Y value to confirm your acceptance of the End-User Licensing Agreement
# Can be 'linux-x64', 'linux-arm64', 'linux-arm', 'rhel.6-x64'.
ENV EDGEWEBDRIVER=/usr/local/share/edge_driver \
    SELENIUMWEBDRIVER=/usr/local/share/Selenium.WebDriver.dll \
    ACCEPT_EULA=Y \
    TARGETARCH=linux-x64

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x start.sh

ENTRYPOINT [ "./start.sh" ]
