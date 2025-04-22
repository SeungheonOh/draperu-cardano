use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/transaction as tx
use cardano/assets

// pub type Datum {
//   owner: VerificationKeyHash,
// }

// pub type Redeemer {
//   msg: ByteArray,
// }

validator hello_world {
  spend(
    datum: Option<Void>,
    redeemer: Void,
    _own_ref: tx.OutputReference,
    self: tx.Transaction,
  ) {
    // expect Some(Datum { owner }) = datum
    // let must_say_hello = redeemer.msg == "Hello, World!"
    // let must_be_signed = list.has(self.extra_signatories, owner)
    // must_say_hello && must_be_signed
    trace @"nope"
    fail
  }
  mint(redeemer: Void, myPolicyId: assets.PolicyId, self: tx.Transaction) {
    fail
  }
}