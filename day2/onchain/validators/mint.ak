use aiken/collection/list
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

// This is also 6 decimal
validator stable_coin (params: StableCoinParams) {
  mint(redeemer: StableCoinRedeemer, ownPolicy: assets.PolicyId, self: tx.Transaction) {
    // oracle
    expect Some(oracleIn) =
      self.reference_inputs
      |> list.find(fn (ri) { assets.quantity_of(ri.output.value, params.oracleSTT, "") == 1 })
    expect tx.InlineDatum(oracleDatumRaw) = oracleIn.output.datum
    expect oracleDatum: OracleDatum = oracleDatumRaw

    when redeemer is {
      Minting -> {
        let collateralOut = getCollateralOut(self.outputs, params.collateralValidator)
        expect tx.InlineDatum(collateralDatumRaw) = collateralOut.datum
        expect collateralDatum: CollateralDatum = collateralDatumRaw
        let collateralAmount = assets.lovelace_of(collateralOut.value)

        let mintQuantity = self.mint |> assets.quantity_of(ownPolicy, "")

        let correctCollateralDatum =
          collateralDatum
          == CollateralDatum(ownPolicy, collateralDatum.collateralOwner, mintQuantity)

        let enoughCollateral = collateralAmount > minCollateralAmount(mintQuantity, oracleDatum.exchangeRate, params.collateralMinPercentage)

        and {
          enoughCollateral?,
          correctCollateralDatum?,
          enoughCollateral?,
        }
      }
      Burning -> {
        let collateralIn = getCollateralIn(self.inputs, params.collateralValidator)
        expect tx.InlineDatum(collateralDatumRaw) = collateralIn.output.datum
        expect collateralDatum: CollateralDatum = collateralDatumRaw

        let burnQuantity = self.mint |> assets.quantity_of(ownPolicy, "")
        let haveOwnerSignature = self.extra_signatories |> list.has(collateralDatum.collateralOwner)

        and {
          haveOwnerSignature,
          burnQuantity == -collateralDatum.stableCoinAmount
        }
      }
      Liquidating -> {
        let collateralIn = getCollateralIn(self.inputs, params.collateralValidator)
        expect tx.InlineDatum(collateralDatumRaw) = collateralIn.output.datum
        expect collateralDatum: CollateralDatum = collateralDatumRaw
        let collateralAmount = assets.lovelace_of(collateralIn.output.value)

        let burnQuantity = self.mint |> assets.quantity_of(ownPolicy, "")

        let canLiquidate =
          minCollateralAmount(collateralDatum.stableCoinAmount, oracleDatum.exchangeRate, params.collateralMinPercentage) > collateralAmount

        and {
          canLiquidate,
          burnQuantity == -collateralDatum.stableCoinAmount
        }
      }
    }
  }
}

fn getCollateralIn(inputs: List<tx.Input>, collateralValidator: ScriptHash) -> tx.Input {
  expect [collateralIn] = inputs |> list.filter(fn (input) {
    when input.output.address.payment_credential is {
      address.Script(addr_script_hash) -> collateralValidator == addr_script_hash
      address.VerificationKey(_) -> False
    }
  })
  collateralIn
}

fn getCollateralOut(outputs: List<tx.Output>, collateralValidator: ScriptHash) -> tx.Output {
  expect [collateralOut] = outputs |> list.filter(fn (output) {
    when output.address.payment_credential is {
      address.Script(addr_script_hash) -> collateralValidator == addr_script_hash
      address.VerificationKey(_) -> False
    }
  })
  collateralOut
}

// Returns minimal amount of collateral that is required
fn minCollateralAmount(stableCoinAmount: Int, rate: Int, colMinPercent: Int) -> Int {
  (stableCoinAmount * colMinPercent * 1000000) / (rate * 100)
}
