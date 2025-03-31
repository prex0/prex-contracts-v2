// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPolicyErrors {
    // 不正なポリシー
    error InvalidPolicy();

    // 無効化されているポリシー
    error InactivePolicy();

    // 不正なアプリオーナー
    error InvalidAppOwner();

    // 不正なポリシーオーナー
    error InvalidPolicyOwner();

    // クレジット不足
    error InsufficientCredit();

    // 不正なハンドラー
    error InvalidHandler();
}
