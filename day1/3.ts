import { Lucid, Blockfrost } from "@lucid-evolution/lucid";
import { load } from 'ts-dotenv';

const {BLOCKFROST_KEY, WALLET_SEED} = load({BLOCKFROST_KEY: String, WALLET_SEED: String});

const lucid = await Lucid(
  new Blockfrost("https://cardano-preview.blockfrost.io/api/v0", BLOCKFROST_KEY),
  "Preview"
);

lucid.selectWallet.fromSeed(WALLET_SEED);

const utxos = await lucid.utxosAt("addr_test1wpmcnpr36xjk7exddlg3pcypc8u3hykvzjz0yjq2ldypjzs630u48");
console.log(utxos);
