// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Groth16Verifier.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract P2PManager is Groth16Verifier, Ownable {
    IERC20 public immutable token;

    uint256[7] public allowedAmounts = [0.1 ether, 1 ether, 10 ether, 100 ether, 1000 ether, 10000 ether, 100000 ether];

    mapping(bytes32 => bool) public nullifierHashes;

    struct WithdrawalRequest {
        address recipient;
        uint256 expiresAt;
    }

    mapping(bytes32 => WithdrawalRequest) public withdrawalRequests;

    event Deposit(bytes32 indexed commitment, uint256 amount);
    event Withdraw(address indexed recipient, bytes32 nullifierHash);
    event WithdrawRequested(bytes32 indexed commitment, address indexed recipient, uint256 expiresAt);
    event ExpiredRequestDeleted(bytes32 indexed commitment);

    constructor(IERC20 _token) Ownable(msg.sender){
        token = _token;
    }

    function _isAllowedAmount(uint256 amount) internal view returns (bool) {
        for (uint256 i = 0; i < allowedAmounts.length; i++) {
            if (allowedAmounts[i] == amount) {
                return true;
            }
        }
        return false;
    }

    function deposit(bytes32 commitment, uint256 amount) external {
        require(_isAllowedAmount(amount), "Invalid amount");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        emit Deposit(commitment, amount);
    }

    function cleanExpiredRequests(bytes32[] calldata commitments) external onlyOwner {
        for (uint256 i = 0; i < commitments.length; i++) {
            bytes32 commitment = commitments[i];
            WithdrawalRequest memory req = withdrawalRequests[commitment];

            if (req.expiresAt != 0 && req.expiresAt < block.timestamp) {
                delete withdrawalRequests[commitment];
                emit ExpiredRequestDeleted(commitment);
            }
        }
    }

    function requestWithdraw(bytes32 commitment, address recipient) external {
        WithdrawalRequest memory req = withdrawalRequests[commitment];

        // Если уже есть запись и она истекла — удаляем
        if (req.expiresAt != 0 && req.expiresAt < block.timestamp) {
            delete withdrawalRequests[commitment];
            emit ExpiredRequestDeleted(commitment);
        }

        require(withdrawalRequests[commitment].expiresAt == 0, "Already reserved");

        withdrawalRequests[commitment] =
            WithdrawalRequest({recipient: recipient, expiresAt: block.timestamp + 10 minutes});

        emit WithdrawRequested(commitment, recipient, block.timestamp + 10 minutes);
    }

    function cancelRequestWithdraw(bytes32 commitment) external {
        WithdrawalRequest memory req = withdrawalRequests[commitment];
        require(req.recipient == msg.sender, "Only recipient can cancel");
        require(req.expiresAt >= block.timestamp, "Reservation already expired");

        delete withdrawalRequests[commitment];
    }

    function withdraw(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[1] calldata input,
        bytes32 nullifierHash,
        bytes32 commitment,
        address recipient,
        uint256 amount
    ) external {
        require(!nullifierHashes[nullifierHash], "Note already spent");
        require(_isAllowedAmount(amount), "Invalid amount");
        require(verifyProof(a, b, c, input), "Invalid ZK proof");

        WithdrawalRequest memory req = withdrawalRequests[commitment];
        require(req.expiresAt != 0, "Not reserved");
        require(req.expiresAt >= block.timestamp, "Reservation expired");
        require(req.recipient == recipient, "Only reserved recipient can withdraw");
        // ✅ Удаляем запись после проверки
        delete withdrawalRequests[commitment];
        nullifierHashes[nullifierHash] = true;

        require(token.transfer(recipient, amount), "Transfer failed");

        emit Withdraw(recipient, nullifierHash);
    }
}
