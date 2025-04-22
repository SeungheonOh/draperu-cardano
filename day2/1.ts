import { Lucid, Maestro } from "@lucid-evolution/lucid";
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

const utxos = await lucid.utxosAt("addr_test1wpmcnpr36xjk7exddlg3pcypc8u3hykvzjz0yjq2ldypjzs630u48");
console.log(utxos);
