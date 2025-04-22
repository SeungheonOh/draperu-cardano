use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/transaction as tx
use cardano/assets
use cardano/address

type OracleDatum {
  exchangeRate: Int, // exchange rate in USD/ADA in 6 decimal fixed point float
  adminCred: List<VerificationKeyHash>, // Admin key hash
  updateCounter: Int,
}

pub type OracleUpdateRedeemer {
  adminCredIdx: Int,
}

// Oracle STT and validator
validator oracle(uniqRef: tx.OutputReference) {
  mint(_redeemer: Void, ownPolicy: assets.PolicyId, self: tx.Transaction) {
    let mintQuantity = self.mint |> assets.quantity_of(ownPolicy, "")
    let spendsUniqRef = self.inputs |> list.any(fn (input) {
      input.output_reference == uniqRef
    })

    and {
        mintQuantity == 1,
        spendsUniqRef,
    }
  }

  spend(_datum: Option<Void>,
        redeemer: OracleUpdateRedeemer,
        ownRef: tx.OutputReference,
        self: tx.Transaction) {
    expect Some(ownInput) =
      self.inputs |> list.find(fn(input) { input.output_reference == ownRef })
    expect address.Script(ownScriptHash) = ownInput.output.address.payment_credential

    expect Some(ownOutput) = self.outputs |> list.find(fn(out) {
      assets.quantity_of(out.value, ownScriptHash, "") == 1
    })

    expect tx.InlineDatum(ownOutputDatumRaw) = ownOutput.datum
    expect ownOutputDatum: OracleDatum = ownOutputDatumRaw
    expect tx.InlineDatum(ownInputDatumRaw) = ownInput.output.datum
    expect ownInputDatum: OracleDatum = ownInputDatumRaw

    and {
      // Check one got admin signature correctly
      self.extra_signatories |> list.any(fn(sig) {
        expect Some(targetAdmin) = ownInputDatum.adminCred |> list.at(redeemer.adminCredIdx)
        targetAdmin == sig
      }),
      // Check no value is been added or withdrawn
      ownOutput.value == ownInput.output.value,
      // Check "updateCounter" is correctly updated
      ownOutputDatum.updateCounter == ownInputDatum.updateCounter + 1,
    }
  }
}
