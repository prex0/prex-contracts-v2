#!/bin/bash

OUTPUT_PATH="$1"

sh abi.sh TransferRequestHandler $OUTPUT_PATH
sh abi.sh DropHandler $OUTPUT_PATH
sh abi.sh LinkTransferHandler $OUTPUT_PATH
sh abi.sh LotteryHandler $OUTPUT_PATH
sh abi.sh PaymentRequestHandler $OUTPUT_PATH
sh abi.sh SwapHandler $OUTPUT_PATH

sh abi.sh BuyPrexPointHandler $OUTPUT_PATH
sh abi.sh BuyLoyaltyPointHandler $OUTPUT_PATH

sh abi.sh IssueCreatorTokenHandler $OUTPUT_PATH
sh abi.sh IssueTokenHandler $OUTPUT_PATH
sh abi.sh IssueLoyaltyTokenHandler $OUTPUT_PATH

sh abi.sh PrexTokenFactory $OUTPUT_PATH
sh abi.sh CreatorTokenFactory $OUTPUT_PATH

sh abi.sh ProfileRegistryV2 $OUTPUT_PATH
sh abi.sh TokenRegistry $OUTPUT_PATH
sh abi.sh OrderExecutor $OUTPUT_PATH

sh abi.sh PumHook $OUTPUT_PATH

