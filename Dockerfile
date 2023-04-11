#Previously used only ubuntu-22.04, now pinned Azure PowerShell version
FROM mcr.microsoft.com/azure-powershell:9.6.0-ubuntu-22.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    git \
    iputils-ping \
    jq \
    lsb-release \
    software-properties-common \
    gpg \
    dirmngr \
    gpg-agent \
    wget \
    unzip \
    openssh-client

# Add apt key
# Add Mono to sources list
# Install Mono
# Download the latest stable `nuget.exe` to `/usr/local/bin`
RUN DEBIAN_FRONTEND=noninteractive apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install mono-devel -y -qq --no-install-recommends && \
    curl -o /usr/local/bin/nuget.exe https://dist.nuget.org/win-x86-commandline/latest/nuget.exe

# Add Microsoft gpg key
# Specify an arch as Microsoft repository supports armhf and arm64 as well
# Install Microsoft Edge
# Install Microsoft Edge Webdriver
# Create Microsoft Edge Webdriver directory
# Get Microsoft Edge version
# Create Microsoft Edge Webdriver download url
# Convert a resulting file to normal UTF-8
# Unzip file, make it executable and create link
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft-edge.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list && \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install --no-install-recommends microsoft-edge-stable -y && \
    mkdir -p /usr/local/share/edge_driver && \
    export EDGE_VERSION=$(microsoft-edge --version | cut -d' ' -f 3) && \
    export EDGE_VERSION_MAJOR=$(echo $EDGE_VERSION | cut -d'.' -f 1) && \
    export EDGE_DRIVER_VERSION_URL="https://msedgedriver.azureedge.net/LATEST_RELEASE_${EDGE_VERSION_MAJOR}_LINUX" && \
    export EDGE_DRIVER_LATEST_VERSION=$(curl -s "$EDGE_DRIVER_VERSION_URL" | iconv -f utf-16 -t utf-8 | tr -d '\r') && \
    export EDGEDRIVER_URL="https://msedgedriver.azureedge.net/${EDGE_DRIVER_LATEST_VERSION}/edgedriver_linux64.zip" && \
    curl $EDGEDRIVER_URL -4 -sL -o "/tmp/edgedriver_linux64.zip" && \
    unzip -qq /tmp/edgedriver_linux64.zip -d /usr/local/share/edge_driver && \
    chmod +x /usr/local/share/edge_driver/msedgedriver && \
    ln -s /usr/local/share/edge_driver/msedgedriver /usr/bin

# Set environment variable
ENV EDGEWEBDRIVER=/usr/local/share/edge_driver

## Install git
# Git version 2.35.2 introduces security fix that breaks action\checkout https://github.com/actions/checkout/issues/760
# Install git-lfs
# Install git-ftp
# Remove source repo's
RUN GIT_REPO="ppa:git-core/ppa" && \
    GIT_LFS_REPO="https://packagecloud.io/install/repositories/github/git-lfs" && \
    DEBIAN_FRONTEND=noninteractive add-apt-repository ${GIT_REPO} -y && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install git -y && \
    printf "[safe]\n        directory = *" >> /etc/gitconfig && \
    curl -s ${GIT_LFS_REPO}/script.deb.sh | bash && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y git-lfs && \
    DEBIAN_FRONTEND=noninteractive apt-get install git-ftp -y && \
    DEBIAN_FRONTEND=noninteractive add-apt-repository --remove ${GIT_REPO} && \
    rm /etc/apt/sources.list.d/github_git-lfs.list

# Change permissions
RUN echo "chmod -R 777 /opt" && \
    chmod -R 777 /opt && \
    echo "chmod -R 777 /usr/share" && \
    chmod -R 777 /usr/share

# Set the ACCEPT_EULA variable to Y value to confirm your acceptance of the End-User Licensing Agreement
ENV ACCEPT_EULA=Y

# Change to pwsh
SHELL [ "pwsh", "-command" ]

# Install Selenium.WebDriver
RUN $seleniumInstallResult = mono /usr/local/bin/nuget.exe install Selenium.WebDriver -NonInteractive -OutputDirectory /usr/share -Version 4.8.2; \
    $seleniumVersion = $seleniumInstallResult.ForEach({if ($PSItem.StartsWith("Added package")) {$PSItem.Substring($PSItem.IndexOf("'") + 1, ($PSItem.IndexOf("'", $PSItem.IndexOf("'") + 1) - $PSItem.IndexOf("'") - 1))}}); \
    Get-ChildItem -Path (Join-Path -Path /usr/share -ChildPath (Join-Path -Path $seleniumVersion -ChildPath "lib" -AdditionalChildPath "net6.0") -AdditionalChildPath "WebDriver.dll") | Copy-Item -Destination "/usr/share/Selenium.WebDriver.dll"

# Set environment variable
ENV SELENIUMWEBDRIVER=/usr/share/Selenium.WebDriver.dll

# Install PnP.PowerShell Module
RUN Install-Module -Name PnP.PowerShell -Repository PSGallery -Scope AllUsers -Force

# Can be 'linux-x64', 'linux-arm64', 'linux-arm', 'rhel.6-x64'.
ENV TARGETARCH=linux-x64

WORKDIR /azp

COPY ./start.sh .

ENTRYPOINT [ "./start.sh" ]
