$ErrorActionPreference = 'Stop'

$SONAR_SERVER_URL = "https://sonarcloud.io"
#$SONAR_TOKEN = # access token from SonarCloud projet creation page -Dsonar.login=XXXX: set in the environment from the CI
$SONAR_SCANNER_VERSION = "4.6.1.2450" # Find the latest version in the "Windows" link on this page:
                                      # https://sonarcloud.io/documentation/analysis/scan/sonarscanner/
$BUILD_WRAPPER_OUT_DIR = "build_wrapper_output_directory" # Directory where build-wrapper output will be placed

mkdir $HOME/.sonar
$SONAR_SCANNER_HOME = "$HOME/.sonar/sonar-scanner-$SONAR_SCANNER_VERSION-windows"

# Download build-wrapper
$path = "$HOME/.sonar/build-wrapper-win-x86.zip"
rm build-wrapper-win-x86 -Recurse -Force -ErrorAction SilentlyContinue
rm $path -Force -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
(New-Object System.Net.WebClient).DownloadFile("$SONAR_SERVER_URL/static/cpp/build-wrapper-win-x86.zip", $path)
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($path, "$HOME/.sonar")
$env:Path += ";$HOME/.sonar/build-wrapper-win-x86"

# Download sonar-scanner
$path = "$HOME/.sonar/sonar-scanner-cli-$SONAR_SCANNER_VERSION-windows.zip"
rm sonar-scanner -Recurse -Force -ErrorAction SilentlyContinue
rm $path -Force -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
(New-Object System.Net.WebClient).DownloadFile("https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SONAR_SCANNER_VERSION-windows.zip", $path)
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($path, "$HOME/.sonar")
$env:Path += ";$SONAR_SCANNER_HOME\bin"

# Setup the build system
rm build -Recurse -Force -ErrorAction SilentlyContinue
mkdir build
cd build
cmake ..
cd ..

# Build inside the build-wrapper
build-wrapper-win-x86-64 --out-dir $BUILD_WRAPPER_OUT_DIR cmake --build build/ --config Release

# Run sonar scanner
sonar-scanner.bat --define sonar.host.url=$SONAR_SERVER_URL --define sonar.login=$SONAR_TOKEN --define sonar.cfamily.build-wrapper-output=$BUILD_WRAPPER_OUT_DIR
