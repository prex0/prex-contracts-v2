// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPolicyErrors {
    // 無効化されているアプリ
    error InactiveApp();

    // 不正なポリシー
    error InvalidPolicy();

    // 無効化されているポリシー
    error InactivePolicy();

    // 不正なアプリオーナー
    error InvalidAppOwner();

    // 不正なポリシーオーナー
    error InvalidPolicyOwner();

    // クレジット不足
    error InsufficientCredit(uint256 required, uint256 balance);

    // 不正なハンドラー
    error InvalidHandler();
}
