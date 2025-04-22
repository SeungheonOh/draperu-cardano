import { Lucid, Blockfrost } from "@lucid-evolution/lucid";
import { load } from 'ts-dotenv';

const BLOCKFROST_KEY = load({BLOCKFROST_KEY: String}).BLOCKFROST_KEY;

const lucid = await Lucid(
  new Blockfrost("https://cardano-preview.blockfrost.io/api/v0", BLOCKFROST_KEY),
  "Preview"
);

const utxos = await lucid.utxosAt("addr_test1wpmcnpr36xjk7exddlg3pcypc8u3hykvzjz0yjq2ldypjzs630u48");
console.log(utxos);
