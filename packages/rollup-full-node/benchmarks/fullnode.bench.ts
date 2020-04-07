import HDWalletProvider from "truffle-hdwallet-provider";
import {wrapProviderAndStartLocalNode} from "@eth-optimism/ovm-truffle-provider-wrapper";
import {benchmark, setup, run} from "./helpers"
const mnemonic = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";

benchmark("fullnode", async () => {
  let provider
  setup(async () => {
    // provider = wrapProviderAndStartLocalNode(new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 10))
  })

  run(async () => { 
    console.log("running")
  })
})
