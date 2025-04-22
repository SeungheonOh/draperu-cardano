import { Lucid, Blockfrost, generateSeedPhrase } from "@lucid-evolution/lucid";
import { load } from 'ts-dotenv';

const {BLOCKFROST_KEY} = load({BLOCKFROST_KEY: String});

const lucid = await Lucid(
  new Blockfrost("https://cardano-preview.blockfrost.io/api/v0", BLOCKFROST_KEY),
  "Preview"
);


const seedPhrase = generateSeedPhrase();

console.log(seedPhrase)

lucid.selectWallet.fromSeed(seedPhrase);

console.log(await lucid.wallet().address());
