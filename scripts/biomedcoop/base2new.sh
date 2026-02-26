# #!/bin/bash
# # custom config

DATA=$1
DATASET=$2
MODEL=$3
METHOD=BiomedCoOp
TRAINER=BiomedCoOp_${MODEL}

SHOTS=16
LOADEP=50
CTP=end
CSC=False
NCTX=4
SUB_base=base
SUB_novel=new

for SEED in 42 1024 3407 #42 1024 3407
do
DIR=output/base2new/train_${SUB_base}/${DATASET}/shots_${SHOTS}/${TRAINER}/nctx${NCTX}_csc${CSC}_ctp${CTP}/seed${SEED}
if [ -d "$DIR" ]; then
    echo "Oops! The results exist at ${DIR} (so skip this job)"
else
    python train.py \
    --root ${DATA} \
    --seed ${SEED} \
    --trainer ${TRAINER} \
    --dataset-config-file configs/datasets/${DATASET}.yaml \
    --config-file configs/trainers/${METHOD}/base_to_novel/${DATASET}.yaml \
    --output-dir ${DIR} \
    TRAINER.BIOMEDCOOP.STAGE 2 \
    DATASET.NUM_SHOTS ${SHOTS} \
    DATASET.SUBSAMPLE_CLASSES ${SUB_base}
fi
COMMON_DIR=${DATASET}/shots_${SHOTS}/${TRAINER}/nctx${NCTX}_csc${CSC}_ctp${CTP}/seed${SEED}
MODEL_DIR=output/base2new/train_${SUB_base}/${COMMON_DIR}
DIR=output/base2new/test_${SUB_novel}/${COMMON_DIR}
if [ -d "$DIR" ]; then
    echo "Oops! The results exist at ${DIR} (so skip this job)"
else
    python train.py \
    --root ${DATA} \
    --seed ${SEED} \
    --trainer ${TRAINER} \
    --dataset-config-file configs/datasets/${DATASET}.yaml \
    --config-file configs/trainers/${METHOD}/base_to_novel/${DATASET}.yaml \
    --output-dir ${DIR} \
    --model-dir ${MODEL_DIR} \
    --load-epoch ${LOADEP} \
    --eval-only \
    TRAINER.BIOMEDCOOP.STAGE 2 \
    DATASET.NUM_SHOTS ${SHOTS} \
    DATASET.SUBSAMPLE_CLASSES ${SUB_novel}
fi
done
#!/bin/bash
# custom config

# DATA=$1
# DATASET=$2
# MODEL=$3
# METHOD=BiomedCoOp
# TRAINER=BiomedCoOp_${MODEL}

# SHOTS=16
# FIXSHORT=16     # 用于 Stage 1 训练权重的固定 shot 数
# LOADEP=50     # Stage 1 训练的轮数，通常为 100
# CTP=end
# CSC=False
# NCTX=4
# SUB_base=base
# SUB_novel=new

# for SEED in 42 1024 3407
# do
#     # -----------------------------------------------------------
#     # Stage 1: 训练属性权重 (Attribute Weights)
#     # -----------------------------------------------------------
#     # 注意：Stage 1 通常在 base 类上训练
#     DIR1=output/${DATASET}/shots_${FIXSHORT}/${TRAINER}/stage1_nctx${NCTX}_seed${SEED}
    
#     if [ -d "$DIR1" ]; then
#         echo "Stage 1 already exists at ${DIR1}, skip."
#     else
#         echo "======== Running Stage 1 (attr_weights) ========"
#         python train.py \
#             --root ${DATA} \
#             --seed ${SEED} \
#             --trainer ${TRAINER} \
#             --dataset-config-file configs/datasets/${DATASET}.yaml \
#             --config-file configs/trainers/${METHOD}/few_shot/${DATASET}.yaml \
#             --output-dir ${DIR1} \
#             TRAINER.BIOMEDCOOP.N_CTX ${NCTX} \
#             TRAINER.BIOMEDCOOP.CSC ${CSC} \
#             TRAINER.BIOMEDCOOP.CLASS_TOKEN_POSITION ${CTP} \
#             TRAINER.BIOMEDCOOP.STAGE 1 \
#             DATASET.NUM_SHOTS ${FIXSHORT} \
#             DATASET.SUBSAMPLE_CLASSES ${SUB_base}
#     fi

#     # 获取 Stage 1 的模型路径
#     CKPT1=${DIR1}/prompt_learner/model.pth.tar-${LOADEP}

#     # -----------------------------------------------------------
#     # Stage 2: 训练 Prompt Learner (Base-to-Novel 模式)
#     # -----------------------------------------------------------
#     DIR2=output/base2new/train_${SUB_base}/${DATASET}/shots_${SHOTS}/${TRAINER}/nctx${NCTX}_csc${CSC}_ctp${CTP}/seed${SEED}
    
#     if [ -d "$DIR2" ]; then
#         echo "Stage 2 (Base) already exists at ${DIR2}, skip."
#     else
#         echo "======== Running Stage 2 (Base Training) ========"
#         python train.py \
#             --root ${DATA} \
#             --seed ${SEED} \
#             --trainer ${TRAINER} \
#             --dataset-config-file configs/datasets/${DATASET}.yaml \
#             --config-file configs/trainers/${METHOD}/base_to_novel/${DATASET}.yaml \
#             --output-dir ${DIR2} \
#             TRAINER.BIOMEDCOOP.STAGE 2 \
#             MODEL.INIT_WEIGHTS ${CKPT1} \
#             DATASET.NUM_SHOTS ${SHOTS} \
#             DATASET.SUBSAMPLE_CLASSES ${SUB_base}
#     fi

#     # -----------------------------------------------------------
#     # Stage 2: 在 Novel 类上进行测试
#     # -----------------------------------------------------------
#     COMMON_DIR=${DATASET}/shots_${SHOTS}/${TRAINER}/nctx${NCTX}_csc${CSC}_ctp${CTP}/seed${SEED}
#     MODEL_DIR=output/base2new/train_${SUB_base}/${COMMON_DIR}
#     TEST_DIR=output/base2new/test_${SUB_novel}/${COMMON_DIR}
    
#     if [ -d "$TEST_DIR" ]; then
#         echo "Test results already exist at ${TEST_DIR}, skip."
#     else
#         echo "======== Running Stage 2 (Novel Testing) ========"
#         python train.py \
#             --root ${DATA} \
#             --seed ${SEED} \
#             --trainer ${TRAINER} \
#             --dataset-config-file configs/datasets/${DATASET}.yaml \
#             --config-file configs/trainers/${METHOD}/base_to_novel/${DATASET}.yaml \
#             --output-dir ${TEST_DIR} \
#             --model-dir ${MODEL_DIR} \
#             --load-epoch 50 \
#             --eval-only \
#             TRAINER.BIOMEDCOOP.STAGE 2 \
#             DATASET.NUM_SHOTS ${SHOTS} \
#             DATASET.SUBSAMPLE_CLASSES ${SUB_novel}
#     fi
# done