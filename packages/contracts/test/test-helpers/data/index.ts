import { create2Tests } from './create2.test.json'
import { rlpTests } from './rlp.test.json'
// import {jsonConcat} from 'json-concat'
import * as fs from 'fs'
import { EvmErrors } from '@eth-optimism/rollup-dev-tools'

export const CREATE2_TEST_JSON = create2Tests
export const RLP_TEST_JSON = rlpTests

// an array of filenames to concat
const files = {}
const sanitizeLibs = (str: string): string => {
  return str
    .split('__$')
    .join('000')
    .split('$__')
    .join('000')
}
const theDirectory = __dirname + '/synthetix-compiled/' // or whatever directory you want to read
console.log(theDirectory)
fs.readdirSync(theDirectory).forEach((fileName) => {
  const obj = JSON.parse(fs.readFileSync(theDirectory + fileName, 'utf8'))
  console.log(fileName)
  // you may want to filter these by extension, etc. to make sure they are JSON files
  files[fileName] = {
    bytecode: '0x' + sanitizeLibs(obj.evm.bytecode.object),
    deployedBytecode: '0x' + sanitizeLibs(obj.evm.deployedBytecode.object),
  }
})
export interface ContractJSON {
  bytecode: string
  deployedBytecode: string
}
export interface SynthetixBytecode {
  [key: string]: ContractJSON
}
export const SYNTHETIX_BYTECODE: SynthetixBytecode = files
