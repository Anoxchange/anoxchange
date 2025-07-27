pragma circom 2.0.6;

include "../circomlib/circuits/poseidon.circom";
include "../circomlib/circuits/bitify.circom";
include "../circomlib/circuits/verify_merkle_path.circom";

template Mixer(levels) {
    signal input leaf;
    signal input pathElements[levels];
    signal input pathIndices[levels];
    signal input expectedRoot;

    component pathVerifier = VerifyMerklePath(levels);
    pathVerifier.leaf <== leaf;
    pathVerifier.root <== expectedRoot;

    for (var i = 0; i < levels; i++) {
        pathVerifier.pathElements[i] <== pathElements[i];
        pathVerifier.pathIndices[i] <== pathIndices[i];
    }

    // Можно вернуть результат для тестов
    signal output root;
    root <== pathVerifier.computedRoot;
}

component main = Mixer(32);