#!/bin/bash

# Source the .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo ".env file not found"
    exit 1
fi

# Check if ARBITRUM_SEPOLIA_RPC_URL is set
if [ -z "$ARBITRUM_SEPOLIA_RPC_URL" ]; then
    echo "ARBITRUM_SEPOLIA_RPC_URL is not set in .env file"
    exit 1
fi

# Array of test functions
test_functions=(
    "testTransitionToIntermediatePresale"
    "testTransitionToFinalLaunchFromIntermediate"
    "testDeadlineReachedDuringIntermediate"
    "testMultipleParticipationsInIntermediate"
    "testRefundExcessEthInIntermediate"
    "testBondingCurvePriceIncrease"
    "testBondingCurveCalculations"
    "testPriceIncreaseInIntermediatePresale"
)

# Function to prompt for verbosity level
get_verbosity_level() {
    local default_level="vvvv"
    read -p "Enter verbosity level (1-4) [default: 4]: " verbosity
    verbosity=${verbosity:-4}
    case "$verbosity" in
        1 ) echo "v" ;;
        2 ) echo "vv" ;;
        3 ) echo "vvv" ;;
        4 ) echo "vvvv" ;;
        * ) echo "Invalid input. Using default: $default_level"; echo "$default_level" ;;
    esac
}

# Function to run a single test
run_test() {
    local test_name=$1
    local verbosity=$(get_verbosity_level)
    echo "Running test: $test_name with verbosity level: $verbosity"
    forge test --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --match-test $test_name -$verbosity
    echo "Test completed: $test_name"
}

# Function to prompt user for continuation
prompt_continue() {
    read -p "Do you want to run the next test? (y/n): " choice
    case "$choice" in 
        y|Y ) return 0 ;;
        n|N ) return 1 ;;
        * ) echo "Invalid input. Please enter y or n."; prompt_continue ;;
    esac
}

# Main script
echo "Available test functions:"
for i in "${!test_functions[@]}"; do
    echo "$((i+1)). ${test_functions[$i]}"
done

read -p "Do you want to run all tests or choose specific ones? (all/choose): " run_option

if [[ $run_option == "all" ]]; then
    for test in "${test_functions[@]}"; do
        run_test "$test"
        if ! prompt_continue; then
            break
        fi
    done
elif [[ $run_option == "choose" ]]; then
    while true; do
        read -p "Enter the number of the test you want to run (or 'q' to quit): " test_number
        if [[ $test_number == "q" ]]; then
            break
        elif [[ $test_number =~ ^[0-9]+$ ]] && [ $test_number -ge 1 ] && [ $test_number -le ${#test_functions[@]} ]; then
            run_test "${test_functions[$((test_number-1))]}"
            if ! prompt_continue; then
                break
            fi
        else
            echo "Invalid input. Please enter a number between 1 and ${#test_functions[@]}, or 'q' to quit."
        fi
    done
else
    echo "Invalid option. Please run the script again and choose 'all' or 'choose'."
fi

echo "Script execution completed."