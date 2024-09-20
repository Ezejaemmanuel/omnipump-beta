#!/bin/bash

install_package() {
    local package=$1
    while true; do
        echo "Attempting to install $package..."
        if forge install $package --no-commit; then
            echo "$package installed successfully."
            return 0
        else
            echo "Failed to install $package. Retrying in 5 seconds..."
            sleep 5
            clear
        fi
    done
}

while true; do
    if install_package "Uniswap/v3-core" && install_package "Uniswap/v3-periphery" ; then
        echo "Both packages installed successfully!"
        break
    fi
done