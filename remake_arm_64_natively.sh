#!/usr/bin/env bash

###################################################################
## autor: Jan Grzybek <jan@onspecta.com>
## 
## to run this script use image build from Dockerfile.devel_arm64 for 'ci' project 
## 
## Warning: bazel build from this script works correct on altra,
##     on amper_v sometimes collapse with no reson
##   

set -e
set -x

JOBS=$(grep -c processor /proc/cpuinfo)

if [[ -n $CI_BUILD ]]; then
  JOBS=$((JOBS / 2))
  EXTRA_MEMORY_OPTION="--experimental_local_memory_estimate \
    --discard_analysis_cache \
    --nokeep_state_after_build \
    --notrack_incremental_state"
fi

# TODO: The official TF code generates inaccorate result if 
# HW FP16 is enabled (i.e. ARM_MARCH=armv8.2-a-fp16)
# Temporarilty disable HW FP16 for TF native code for now
# until the issue is identified
ARM_MARCH=armv8.2-a
if [ -n "$HW_FP16" ]; then
  if [ "$HW_FP16" == "0" ]; then
    ARM_MARCH=armv8-a
  fi
fi

TF_COPTS="--copt=-funsafe-math-optimizations \
  --copt=-ftree-vectorize       \
  --copt=-fomit-frame-pointer   \
  --copt=-march=${ARM_MARCH}    \
  --jobs=$JOBS                  \
  --linkopt=-L/usr/local/lib    \
  --config=monolithic		\
  --copt=-DDLS_ARM64"

TF_SERVING_BUILD_OPTIONS="--config=release"
echo "Building with build options: ${TF_SERVING_BUILD_OPTIONS}"
TF_SERVING_BAZEL_OPTIONS=""
echo "Building with Bazel options: ${TF_SERVING_BAZEL_OPTIONS}"

bazel build --color=yes --curses=yes \
    ${EXTRA_MEMORY_OPTION} \
    ${TF_COPTS}	\
    ${TF_SERVING_BAZEL_OPTIONS} \
    --verbose_failures \
    --output_filter=DONT_MATCH_ANYTHING \
    ${TF_SERVING_BUILD_OPTIONS} \
    tensorflow_serving/model_servers:tensorflow_model_server
