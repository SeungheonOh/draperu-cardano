// use aiken/collection/list
// use aiken/crypto.{VerificationKeyHash}
// use cardano/transaction as tx
// use cardano/assets

// // pub type Datum {
// //   owner: VerificationKeyHash,
// // }

// // pub type Redeemer {
// //   msg: ByteArray,
// // }

// validator hello_world {
//   spend(
//     _datum: Option<Void>,
//     _redeemer: Void,
//     _own_ref: tx.OutputReference,
//     _self: tx.Transaction,
//   ) {
//     True
//   }
// }