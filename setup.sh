#!/bin/bash

NETWORK=${1:-mainnet}
PAYRAM_FILES="$HOME/payram_files"

# Check if the parameter is either "mainnet" or "testnet"
if [ "$NETWORK" != "mainnet" ] && [ "$NETWORK" != "testnet" ]; then
    echo "Error: Invalid parameter. Please provide 'mainnet' or 'testnet'."
    exit 1
else
    echo "Valid parameter: $NETWORK"
fi

# --- Start of your configuration setup script ---
conf="conf"
db="db"
logs="logs"
# Set the default config filename
default_config="config.yml"

# If the network is "testnet," set the filename to "test_config.yml"
if [ "$NETWORK" == "testnet" ]; then
    config_filename="test_config.yml"
else
    config_filename="$default_config"
fi

config_file="$PAYRAM_FILES/$conf/$config_filename"
if [ -f "$config_file" ]; then
    echo "Reading from config file $config_filename"
else
    echo "Config Error: File not found."
    exit 1
fi

# creating db and logs folder
mkdir -p "$PAYRAM_FILES/$db" "$PAYRAM_FILES/$logs"


# Create the YAML content
# Function to install Docker on Ubuntu
install_docker_ubuntu() {
    echo "Installing Docker on Ubuntu..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
}

# Function to install Docker on Debian
install_docker_debian() {
    echo "Installing Docker on Debian..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
}

# Function to install Docker on Fedora
install_docker_fedora() {
    echo "Installing Docker on Fedora..."
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf -y install docker-ce docker-ce-cli containerd.io
}

# Function to install Docker on Amazon Linux
install_docker_amazon_linux() {
    echo "Installing Docker on Amazon Linux..."
    sudo yum update -y
    sudo yum install docker -y
}

# Placeholder function for Docker installation on macOS
install_docker_mac() {
    echo "Docker installation on macOS should be done manually through https://docs.docker.com/docker-for-mac/install/"
}

# Placeholder function for Docker installation on Windows
install_docker_windows() {
    echo "Docker installation on Windows should be done manually through https://docs.docker.com/docker-for-windows/install/"
}

# Function to check, install, and start Docker
check_install_and_start_docker() {
    if ! [ -x "$(command -v docker)" ]; then
        echo "Docker is not installed. Installing Docker..."
        
        # Determine the OS and install Docker
        os_name="$(uname -s)"
        case "${os_name}" in
            Linux*)     
                distro=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
		echo $distro
                if [[ $distro == *"Ubuntu"* ]]; then
                    install_docker_ubuntu
                elif [[ $distro == *"Debian"* ]]; then
                    install_docker_debian
                elif [[ $distro == *"Fedora"* ]]; then
                    install_docker_fedora
                elif [[ $distro == *"Amazon Linux"* ]]; then
                    install_docker_amazon_linux 
                else
                    echo "Unsupported Linux distribution for automatic installation."
                    return 1
                fi
                ;;
            Darwin*)    
                install_docker_mac
                return 1
                ;;
            CYGWIN*|MINGW32*|MSYS*|MINGW*)
                install_docker_windows
                return 1
                ;;
            *)
                echo "Unsupported OS for automatic installation."
                return 1
                ;;
        esac

        # Start Docker service
        echo "Starting Docker service..."
        sudo systemctl start docker
	sudo systemctl enable docker
	sudo usermod -a -G docker $(whoami)
    else
        echo "Docker is already installed."
    fi
}

# Function to pull Docker image and check success, including error message
pull_docker_image() {
    image=$1
    if output=$(docker pull "$image" 2>&1); then
        echo "Successfully pulled $image."
    else
        echo "Failed to pull $image. Error details: $output"
        exit 1
    fi
}

# Call the function to check, install, and start Docker
check_install_and_start_docker

# Pull the latest images and check if successful
echo "Pulling latest Docker images..."
pull_docker_image buddhasource/payram:latest
pull_docker_image buddhasource/payram-web:latest


# Call the function to check, install, and start Docker
check_install_and_start_docker

# Pull the latest images (remains the same as in your previous script)

# Run the Docker containers and check if successful
start_payram() {
	
	docker run -d --name payram -p 2357:2357 -p 2359:443 -v $PAYRAM_FILES:/payram_files -e PAYRAM_NETWORK_MODE=mainnet buddhasource/payram:latest
	
  	# Check the status of the last executed command (Docker run)
	if [ $? -eq 0 ]; then
	    	echo "Success: Payram container started."
	else
	    	echo "Error: Failed to start the Payram container."
	    	# Log the error. Adjust the path to your preferred log file
     		echo "$(date) : Error in starting Payram container" >> /var/log/docker_error.log
     		exit 1
	fi
 
}

start_payram_web() {
	docker run -d --name payram-web -p 80:2358 -p 443:443 -v $PAYRAM_FILES/cert:/payram_files/cert buddhasource/payram-web:latest
	 # Check the status of the last executed command (Docker run)
	if [ $? -eq 0 ]; then
	    	echo "Success: Payram-web container started."
	else
	    	echo "Error: Failed to start the Payram-web container."
	    	# Log the error. Adjust the path to your preferred log file
	    	echo "$(date) : Error in starting Payram-web container" >> /var/log/docker_error.log
     		exit 1
	fi
}
echo "Running Docker containers..."
start_payram

start_payram_web

echo "Containers are up and running."
