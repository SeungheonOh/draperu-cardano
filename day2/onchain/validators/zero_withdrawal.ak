use aiken/collection/list
use aiken/collection/pairs
use aiken/crypto.{ScriptHash, VerificationKeyHash}
use cardano/transaction as tx
use cardano/address
use cardano/assets


type OracleDatum {
  exchangeRate: Int, // exchange rate in USD/ADA in 6 decimal fixed point float, essentially USD/Lovelace
  adminCred: VerificationKeyHash, // Admin key hash
  updateCounter: Int,
}

pub type CollateralDatum {
  stableCoinPolicyId: assets.PolicyId,
  collateralOwner: VerificationKeyHash,
  stableCoinAmount: Int,
}

pub type StableCoinParams {
  oracleSTT: ScriptHash,
  collateralValidator: ScriptHash,
  collateralMinPercentage: Int,
}

pub type StableCoinRedeemer {
  Minting
  Burning
  Liquidating
}

pub type MintObserverRedeemer {
  stableTokenPolicy: ScriptHash,
  collateralLockerHash: ScriptHash,

}

pub type StableCoinLogic {
  mint: ScriptHash
}

validator stable_coin_new(params: StableCoinLogic) {
  mint(redeemer: Void, myPolicy: assets.PolicyId, self: tx.Transaction) {
    let correctWithdraw = self.withdraw |> pairs.has_key(tx.Script(params.mint))
    expect Some(mintRedeemer) = self.redeemers |> pairs.get_first(tx.Withdraw(tx.Script(params.mint)))

    and {
      correctWithdraw,
      mintRedeemer.stableTokenPolicy == myPolicy
    }
  }
}

// This is also 6 decimal
validator stable_coin_valid_mint {
  withdraw(redeemer: MintObserverRedeemer, _account: address.Credential, self: tx.Transaction) {
    let collateralOut = getCollateralOut(self.outputs, redeemer.collateralLockerHash)
    expect tx.InlineDatum(collateralOutDatumRaw) = collateralOut.datum
    expect collateralDatum: CollateralDatum = collateralOutDatumRaw
    let collateralAmount = assets.lovelace_of(collateralOut.value)

    let stableTokenMintAmount = self.mint |> assets.quantity_of(redeemer.stableTokenPolicy, "")

    and {
      stableTokenMintAmount > 0,
      collateralDatum.stableCoinAmount == stableTokenMintAmount,
      collateralAmount > minCollateralAmount(stableTokenMintAmount, oracleDatum.exchangeRate, colMinPercentage)
    }
  }
}

pub fn getCollateralIn(inputs: List<tx.Input>, collateralValidator: ScriptHash) -> tx.Input {
  expect [collateralIn] = inputs |> list.filter(fn (input) {
    when input.output.address.payment_credential is {
      address.Script(addr_script_hash) -> collateralValidator == addr_script_hash
      address.VerificationKey(_) -> False
    }
  })
  collateralIn
}

pub fn getCollateralOut(outputs: List<tx.Output>, collateralValidator: ScriptHash) -> tx.Output {
  expect [collateralOut] = outputs |> list.filter(fn (output) {
    when output.address.payment_credential is {
      address.Script(addr_script_hash) -> collateralValidator == addr_script_hash
      address.VerificationKey(_) -> False
    }
  })
  collateralOut
}

// Returns minimal amount of collateral that is required
pub fn minCollateralAmount(stableCoinAmount: Int, rate: Int, colMinPercent: Int) -> Int {
  (stableCoinAmount * colMinPercent * 1000000) / (rate * 100)
}
