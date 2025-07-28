# 🛡️ P2P ZK Anoxchange

A secure, anonymous, and scalable peer-to-peer token exchange system powered by zkSNARK proofs and on-chain withdrawal rights management.

---

## 🎯 Goal
Build a privacy-preserving P2P exchange (e.g., USDT) that protects users from tracking, using zkSNARK-based zero-knowledge proofs and Merkle tree commitments.

---

## 🧱 Architecture

| Component           | Purpose |
|---------------------|---------|
| **P2PManager.sol**  | Smart contract managing deposits, withdrawals, and P2P requests |
| **verifier.sol**    | Verifies zkSNARK proofs generated on the client side |
| **Merkle Tree**     | Commitments tree (Poseidon hash) stored on-chain |
| **zk-Circuit**      | Groth16 proof system verifying nullifier, secret, recipient |
| **CLI Tools**       | Scripts for deposit, requestWithdraw, and withdraw |
| **note.json**       | Stores note details: nullifier, secret, amount, commitment, root |

---

## 🔐 Privacy with zkSNARK

The Groth16 zkSNARK scheme ensures:

- The user knows the **nullifier** and **secret** for an existing commitment  
- The note has not been used (`nullifierHash` unused)  
- The note belongs to the current **Merkle root**  
- The **recipient** can be chosen freely  

👉 All without revealing the nullifier, secret, amount, or sender.

---

## 🔁 Usage Flow

### 1. Deposit
- User generates a note `{nullifier, secret}`  
- Creates a commitment: `Poseidon(nullifier, secret)`  
- Calls `P2PManager.deposit(commitment, amount)`  
- Commitment is added to Merkle tree and tokens deposited  
- 📝 Note saved in JSON, shareable via private channel  

### 2. P2P Note Transfer
- Send the note to a buyer via Session, QR, or messenger  
- Buyer pays in fiat, USDT, or another method  

### 3. Request Withdraw (Optional)
```ts
requestWithdraw(commitment, recipientAddress)
````

* Locks withdrawal rights for a recipient
* Includes expiration (`expiresAt`) for automatic release if unpaid

### 4. Withdraw

* Buyer generates Merkle proof + zkSNARK proof
* Calls `withdraw()` with proof, root, nullifierHash, recipient
* Contract:

  * Verifies proof via `verifier.sol`
  * Ensures note not spent before
  * Checks reservation (recipient, expiresAt) if set
  * Sends tokens to recipient
  * Marks nullifierHash as spent

---

## ✅ Fraud Protection

| Fraud Attempt                       | Protection                           |
| ----------------------------------- | ------------------------------------ |
| Double-spending a note              | `nullifierHash` valid only once      |
| Linking deposit to withdrawal       | zkSNARK hides all details            |
| Seller attempts to withdraw note    | `requestWithdraw()` locks recipient  |
| Buyer reserves note but doesn’t pay | `expiresAt` auto-expires reservation |

---

## 🧪 Deployment (MVP)

### Step 1. Compile zk-Circuit

```bash
cd circuits/
snarkjs groth16 setup mixer.r1cs pot12_final.ptau mixer.zkey
snarkjs zkey export verificationkey mixer.zkey verification_key.json
snarkjs zkey export solidityverifier mixer.zkey verifier.sol
```

### Step 2. Deploy Contracts

```bash
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Step 3. Generate Note

```bash
ts-node cli/deposit.ts
```

### Step 4. Request Withdraw (Optional)

```bash
ts-node cli/requestWithdraw.ts note.json recipient_address
```

### Step 5. Withdraw Funds

```bash
ts-node cli/withdraw.ts note.json
```

---

## 📦 Project Structure

```
p2p-mixer/
├── contracts/
│   ├── P2PManager.sol
│   └── verifier.sol
├── circuits/
│   └── mixer.circom
├── cli/
│   ├── deposit.ts
│   ├── requestWithdraw.ts
│   └── withdraw.ts
├── notes/
│   └── note_<timestamp>.json
├── test/
│   └── P2P.t.sol
└── README.md
```

---

## 🔜 Upcoming Features

| Feature                       | Status |
| ----------------------------- | ------ |
| 🧾 Note encryption (PGP/QR)   | ⏳      |
| ⌛ Time-lock (cheque system)   | 🔜     |
| ⚖️ Fee via nominal amount     | 🔜     |
| 📱 React GUI + QR support     | 🔜     |
| 🔄 Batch transfers            | 🔜     |
| 🧩 NFT-based ownership proofs | 🔜     |

---

💡 Contributions and ideas are welcome!

```
