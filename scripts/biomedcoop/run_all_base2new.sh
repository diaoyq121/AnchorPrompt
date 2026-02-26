#!/bin/bash

# Script to run base2new training on all datasets (supports parallel execution)
# Usage:
#   Sequential: bash scripts/biomedcoop/run_all_datasets.sh [GPU_ID] [MODEL]
#   Parallel:   bash scripts/biomedcoop/run_all_datasets.sh [GPU_IDS] [MODEL] parallel
# Examples:
#   bash scripts/biomedcoop/run_all_datasets.sh 0 BiomedCLIP
#   bash scripts/biomedcoop/run_all_datasets.sh "2,3" BiomedCLIP parallel

GPU_IDS=${1:-0}
MODEL=${2:-CAPA}
MODE=${3:-sequential}
DATA_ROOT="data"

# List of all datasets
DATASETS=(
    "btmri"
    # "busi"
    "chmnist"
    "covid"
    "ctkidney"
    # "dermamnist"
    "kneexray"
    "kvasir"
    "lungcolon"
    "octmnist"
    "retina"
)

echo "=========================================="
echo "Running base2new training on all datasets"
echo "GPU(s): ${GPU_IDS}"
echo "Model: ${MODEL}"
echo "Mode: ${MODE}"
echo "Data Root: ${DATA_ROOT}"
echo "=========================================="
echo ""

if [ "$MODE" == "parallel" ]; then
    # Parallel execution mode
    echo "Running in PARALLEL mode"
    echo "=========================================="

    # Convert GPU_IDS string to array
    IFS=',' read -ra GPU_ARRAY <<< "$GPU_IDS"
    NUM_GPUS=${#GPU_ARRAY[@]}

    echo "Available GPUs: ${GPU_ARRAY[@]}"
    echo "Number of GPUs: ${NUM_GPUS}"
    echo "Number of datasets: ${#DATASETS[@]}"
    echo ""

    # Create log directory
    LOG_DIR="logs/parallel_runs_$(date +%Y%m%d_%H%M%S)"
    mkdir -p ${LOG_DIR}
    echo "Logs will be saved to: ${LOG_DIR}"
    echo ""

    # Launch jobs in parallel
    gpu_idx=0
    for DATASET in "${DATASETS[@]}"
    do
        # Assign GPU in round-robin fashion
        GPU_ID=${GPU_ARRAY[$gpu_idx]}
        gpu_idx=$(( (gpu_idx + 1) % NUM_GPUS ))

        LOG_FILE="${LOG_DIR}/${DATASET}_gpu${GPU_ID}.log"

        echo "Launching ${DATASET} on GPU ${GPU_ID} (log: ${LOG_FILE})"

        # Run in background
        (
            echo "=========================================="
            echo "Dataset: ${DATASET}"
            echo "GPU: ${GPU_ID}"
            echo "Start time: $(date)"
            echo "=========================================="

            CUDA_VISIBLE_DEVICES=${GPU_ID} bash scripts/biomedcoop/base2new.sh ${DATA_ROOT} ${DATASET} ${MODEL}

            echo ""
            echo "Finished dataset: ${DATASET}"
            echo "End time: $(date)"
            echo "=========================================="
        ) > ${LOG_FILE} 2>&1 &

        # Store the PID
        echo $! >> ${LOG_DIR}/pids.txt
    done

    echo ""
    echo "All jobs launched! Waiting for completion..."
    echo "Monitor progress with: tail -f ${LOG_DIR}/*.log"
    echo ""

    # Wait for all background jobs to complete
    wait

    echo "=========================================="
    echo "All datasets completed!"
    echo "Completion time: $(date)"
    echo "Logs saved in: ${LOG_DIR}"
    echo "=========================================="

else
    # Sequential execution mode (original behavior)
    echo "Running in SEQUENTIAL mode"
    echo "=========================================="
    echo ""

    # Loop through all datasets
    for DATASET in "${DATASETS[@]}"
    do
        echo "=========================================="
        echo "Processing dataset: ${DATASET}"
        echo "Start time: $(date)"
        echo "=========================================="

        CUDA_VISIBLE_DEVICES=${GPU_IDS} bash scripts/biomedcoop/base2new.sh ${DATA_ROOT} ${DATASET} ${MODEL}

        echo ""
        echo "Finished dataset: ${DATASET}"
        echo "End time: $(date)"
        echo ""
    done

    echo "=========================================="
    echo "All datasets completed!"
    echo "Completion time: $(date)"
    echo "=========================================="
fi
