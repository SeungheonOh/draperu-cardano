use cardano/transaction as tx
use cardano/assets
use cardano/address
use aiken/collection/list
use aiken/collection/dict
use aiken/crypto.{
  VerificationKeyHash
}
use aiken/crypto.{
  Blake2b_256, Hash
}

validator lapis(uniqRefHash: Hash<Blake2b_256, tx.Transaction>, uniqRefIdx: Int) {
  mint(_redeemer: Void, ownPolicy: assets.PolicyId, self: tx.Transaction) {
    let usesUniqRef =
      self.inputs |> list.any(fn (input) {
        input.output_reference == tx.OutputReference(uniqRefHash, uniqRefIdx)
      })
    if usesUniqRef { True }
    else {
      expect [inputFromValidator] =
        self.inputs
        |> list.filter(fn(input) { input.output.address.payment_credential == address.Script(ownPolicy)})
      expect [outputFromValidator] =
        self.outputs
        |> list.filter(fn(output) { output.address.payment_credential == address.Script(ownPolicy)})
      expect tx.InlineDatum(inputDatumRaw) = inputFromValidator.output.datum
      expect inputDatum: List<Data> = inputDatumRaw
      expect tx.InlineDatum(outputDatumRaw) = outputFromValidator.datum
      expect outputDatum: List<Data> = outputDatumRaw

      let inputLength = list.length(inputDatum)
      let outputLength = list.length(outputDatum)

      and {
        inputLength + 1 == outputLength,
        list.take(inputDatum, inputLength) == list.take(outputDatum, inputLength),
        assets.quantity_of(inputFromValidator.output.value, ownPolicy, "") == 1,
        assets.quantity_of(outputFromValidator.value, ownPolicy, "") == 1,
      }
    }
  }
  spend(_datum: Option<Void>, _redeemer: Void, ownRef: tx.OutputReference, self: tx.Transaction) {
    expect Some(ownInput) =
      self.inputs |> list.find(fn(input) { input.output_reference == ownRef })
    expect address.Script(ownScriptHash) = ownInput.output.address.payment_credential

    expect [ticketMint] = self.mint |> assets.tokens(ownScriptHash) |> dict.to_pairs

    ticketMint.2nd == -1
  }
}

validator always_fail {
  spend(_datum: Option<Void>, _redeemer: Void, _ownRef: tx.OutputReference, _self: tx.Transaction) {
    error
  }
}
