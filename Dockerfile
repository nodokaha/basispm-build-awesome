# syntax=docker/dockerfile:1

# Self-contained build: no local Basis checkout or prebuilt basispm is required.
FROM mcr.microsoft.com/dotnet/sdk:10.0-noble AS build
ARG TARGETARCH
ARG BASIS_REF=long-term-support-20260916
ARG BASIS_REPOSITORY=https://github.com/BasisVR/Basis.git
ARG BASISPM_REPOSITORY=https://github.com/BasisVR/BasisPackageManager.git
ARG TCP_TRANSPORT_REPOSITORY=https://github.com/dooly123/Basis-TCP-Transport-Package.git

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Compile basispm as a self-contained executable for the target architecture.
RUN git clone --depth 1 "${BASISPM_REPOSITORY}" /tmp/BasisPackageManager \
    && dotnet publish /tmp/BasisPackageManager/src/BasisPM.Cli/BasisPM.Cli.csproj \
       --configuration Release --runtime "linux-${TARGETARCH}" --self-contained true \
       --output /opt/basispm

# Clone the official Basis server source in the image build itself.
RUN git clone --depth 1 --branch "${BASIS_REF}" "${BASIS_REPOSITORY}" /src/Basis

# Install the transport through basispm; its lock file pins the package commit.
RUN /opt/basispm/basispm --project /src/Basis server-install "${TCP_TRANSPORT_REPOSITORY}"

WORKDIR "/src/Basis/Basis Server/BasisServerConsole"
RUN dotnet restore ./BasisNetworkConsole.csproj
RUN dotnet publish ./BasisNetworkConsole.csproj \
    --configuration Release --no-restore --output /app/publish

FROM mcr.microsoft.com/dotnet/runtime:10.0-noble AS runtime
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/publish ./

ENV SetPort=4296 \
    HealthCheckPort=10666 \
    PromethusPort=1234 \
    UsingLoggingFile=true \
    EnableStatistics=true \
    EnableConsole=false \
    PeerLimit=1024 \
    NetworkStackId=litenetlib,websocket

EXPOSE 4296/udp
EXPOSE 4296/tcp
EXPOSE 10666/tcp
EXPOSE 1234/tcp

ENTRYPOINT ["dotnet", "BasisNetworkConsole.dll"]
