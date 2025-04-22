import * as L from "@lucid-evolution/lucid";
import { Lucid, Maestro } from "@lucid-evolution/lucid";
import {
  mintingPolicyToId,
  validatorToAddress,
} from "@lucid-evolution/utils";
import {fromText} from "@lucid-evolution/core-utils";
import { load } from 'ts-dotenv';

const {MAESTRO_KEY, WALLET_SEED} = load({MAESTRO_KEY: String, WALLET_SEED: String});

const lucid = await Lucid(
  new Maestro({
    network: "Preview",
    apiKey: MAESTRO_KEY,
    turboSubmit: false,
  }),
  "Preview"
);

lucid.selectWallet.fromSeed(WALLET_SEED);

const nft = utxo => {
  return {
    type: "PlutusV3",
    script: L.applyParamsToScript(
      "58c501010032323232323232232232253330063232323232533300b3370e900018061baa001132323232330010013758600460226ea8020894ccc04c004528099299980899baf300430133754602c00466e95200033015375201e6602a6ea00352f5c029444cc00c00c004c0580048c04c0054ccc030cdc3a4000601a6ea800c54ccc03cc038dd50018a4c2c2c6eb8c040c034dd50008b1807980800118070009807001180600098041baa00114984d958dd68009bae0015734aae7555cf2ab9f5740ae855d101",
      [utxo.txHash, BigInt(utxo.outputIndex)]
    ),
  }
}


const utxos = await lucid.wallet().getUtxos();
console.log(utxos);

const utxo = utxos[0]
const nftBuilt = nft(utxo)

const nftCurrencySymbol = mintingPolicyToId(nftBuilt)

console.log(nftBuilt)
console.log(nftCurrencySymbol)

const tx = await
lucid.newTx()
  .collectFrom([utxos[0]])
  .mintAssets({[nftCurrencySymbol+fromText("DraperUxCardano 25")]: 1000000000n}, L.Data.to(new L.Constr(0, [])))
  .attach.MintingPolicy(nftBuilt)
  .complete()

console.log(await tx.config().programs.push())

console.log(tx.toCBOR())
console.log(JSON.stringify(tx.toJSON()))

const signed = await tx.sign.withWallet().complete()
const hash = await signed.submit()

console.log(hash);

await lucid.awaitTx(hash, 40_000)
console.log("confirmed")
