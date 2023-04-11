FROM mcr.microsoft.com/azure-powershell:9.6.0-ubuntu-22.04

# Add Microsoft gpg key
# Specify an arch as Microsoft repository supports armhf and arm64 as well
# Install Microsoft Edge
# Install Microsoft Edge Webdriver
# Create Microsoft Edge Webdriver directory
# Get Microsoft Edge version
# Create Microsoft Edge Webdriver download url
# Convert a resulting file to normal UTF-8
# Unzip file, make it executable and create link
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    curl \
    git \
    gpg \
    jq \
    unzip \
    wget \
    && wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft-edge.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list && \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install --no-install-recommends microsoft-edge-stable -y && \
    mkdir -p /usr/local/share/edge_driver && \
    EDGE_VERSION=$(microsoft-edge --version | cut -d' ' -f 3) && \
    EDGE_VERSION_MAJOR=$(echo $EDGE_VERSION | cut -d'.' -f 1) && \
    EDGE_DRIVER_VERSION_URL="https://msedgedriver.azureedge.net/LATEST_RELEASE_${EDGE_VERSION_MAJOR}_LINUX" && \
    EDGE_DRIVER_LATEST_VERSION=$(curl -s "$EDGE_DRIVER_VERSION_URL" | iconv -f utf-16 -t utf-8 | tr -d '\r') && \
    EDGEDRIVER_URL="https://msedgedriver.azureedge.net/${EDGE_DRIVER_LATEST_VERSION}/edgedriver_linux64.zip" && \
    curl $EDGEDRIVER_URL -4 -sL -o "/tmp/edgedriver_linux64.zip" && \
    unzip -qq /tmp/edgedriver_linux64.zip -d /usr/local/share/edge_driver && \
    chmod +x /usr/local/share/edge_driver/msedgedriver && \
    ln -s /usr/local/share/edge_driver/msedgedriver /usr/bin && \
    rm -rf /var/lib/apt/lists/*

# Change to pwsh
SHELL [ "pwsh", "-command" ]

# Install PowerShellGetv3 to prevent a dependency error with PowerShellGetv2 Install-Package
# Import PowerShellGetv3 Module
# Register NuGet repository
# Install Selenium.WebDriver package
# Get msedgedriver path and create symbolic link
# Create symbolic link to Selenium.WebDriver
# Install PnP.PowerShell Module
RUN Install-Module -Name PowerShellGet -Repository PSGallery -Scope AllUsers -Force -AllowPrerelease; \
    Import-Module -Global -Name PowerShellGet; \
    Register-PSResourceRepository -Name nuget.org -Uri https://api.nuget.org/v3/index.json -Trusted:$false -Priority 50; \
    Install-PSResource -Name Selenium.WebDriver -Version 4.8.2 -Repository nuget.org -Scope AllUsers -TrustRepository; \
    New-Item -Path /usr/local/share/ -Name Selenium.WebDriver.dll -ItemType SymbolicLink -Value /usr/local/share/powershell/Modules/Selenium.WebDriver/4.8.2/lib/net6.0/WebDriver.dll | Out-Null; \
    Install-PSResource -Name PnP.PowerShell -Version 2.1.1 -Repository PSGallery -Scope AllUsers -TrustRepository;

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
