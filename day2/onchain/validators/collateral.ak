use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/transaction as tx
use cardano/assets

pub type CollateralRedeemer {
  Redeem
  Liquidate
}

pub type CollateralDatum {
  stableCoinPolicyId: assets.PolicyId,
  collateralOwner: VerificationKeyHash,
  stableCoinAmount: Int,
}

validator collateral {
  spend(datum: Option<CollateralDatum>, redeemer: CollateralRedeemer, _ownRef: tx.OutputReference, self: tx.Transaction) {
    expect Some(collateralDatum) = datum
    let burnAll =
      (self.mint |> assets.quantity_of(collateralDatum.stableCoinPolicyId, ""))
      == -collateralDatum.stableCoinAmount
    let haveOwnerSignature = self.extra_signatories |> list.has(collateralDatum.collateralOwner)

    when redeemer is {
      Redeem -> burnAll? && haveOwnerSignature?
      Liquidate -> burnAll?
    }
  }
}
