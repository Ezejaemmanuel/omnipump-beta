#!/bin/bash

run_forge_install() {
    forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
    return $?
}

countdown() {
    local seconds=$1
    while [ $seconds -gt 0 ]; do
        echo -ne "\rWaiting for $seconds seconds..."
        sleep 1
        : $((seconds--))
    done
    echo -e "\rResuming installation attempt...     "
}

attempt=1

while true; do
    echo "Attempt $attempt: Running forge install..."
    if run_forge_install; then
        echo "Forge install successful."
        break
    else
        echo "Forge install failed."
        countdown 30
        : $((attempt++))
    fi
done

echo "Script completed."