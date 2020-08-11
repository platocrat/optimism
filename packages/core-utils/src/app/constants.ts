import { EVMOpcode, Opcode } from '../types'
import { ZERO, BigNumber } from './number'

export const ZERO_ADDRESS = '0x' + '00'.repeat(20)
export const INVALID_ADDRESS = '0xdeaDDeADDEaDdeaDdEAddEADDEAdDeadDEADDEaD'

export const DEFAULT_UNSAFE_OPCODES: EVMOpcode[] = [
  Opcode.ADDRESS,
  Opcode.BALANCE,
  Opcode.BLOCKHASH,
  Opcode.CALL,
  Opcode.CALLCODE,
  Opcode.CHAINID,
  Opcode.COINBASE,
  Opcode.CREATE,
  Opcode.CREATE2,
  Opcode.DELEGATECALL,
  Opcode.DIFFICULTY,
  Opcode.EXTCODESIZE,
  Opcode.EXTCODECOPY,
  Opcode.EXTCODEHASH,
  Opcode.GASLIMIT,
  Opcode.GASPRICE,
  Opcode.NUMBER,
  Opcode.ORIGIN,
  Opcode.SELFBALANCE,
  Opcode.SELFDESTRUCT,
  Opcode.SLOAD,
  Opcode.SSTORE,
  Opcode.STATICCALL,
  Opcode.TIMESTAMP,
]

export const DEFAULT_SAFE_OPCODES: EVMOpcode[] = Opcode.ALL_OP_CODES.filter(
  (x) => DEFAULT_UNSAFE_OPCODES.indexOf(x) < 0
)

const calculateMask = (opcodes) => {
  // console.log(
  //   `Generating mask for opcodes: ${opcodes.map((x) => x.name).join(',')}`
  // )
  let maskHex: string = opcodes
    .map((x) => new BigNumber(2).pow(new BigNumber(x.code)))
    .reduce((prev: BigNumber, cur: BigNumber) => prev.add(cur), ZERO)
    .toString('hex')
  if (maskHex.length !== 64) {
    maskHex = '0'.repeat(64 - maskHex.length) + maskHex
  }
  // console.log(`mask: 0x${maskHex}`)
  return '0x' + maskHex
}

// const GATED_OPCODES = Opcode.HALTING_OP_CODES.push(Opcode.CALLER)
// calculateMask(GATED_OPCODES) //Calculate gated opcode mask
export const DEFAULT_OPCODE_WHITELIST_MASK = calculateMask(DEFAULT_SAFE_OPCODES)
