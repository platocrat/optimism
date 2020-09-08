/* External Imports */
import { ethers } from 'ethers'
import { defaultAccounts } from 'ethereum-waffle'

export const DEFAULT_ACCOUNTS = defaultAccounts
export const DEFAULT_ACCOUNTS_BUIDLER = defaultAccounts.map((account) => {
  return {
    balance: ethers.BigNumber.from(account.balance).toHexString(),
    privateKey: account.secretKey,
  }
})

export const GAS_LIMIT = 1_000_000_000

export const NULL_BYTES32 = '0x' + '00'.repeat(32)
export const ZERO_ADDRESS = '0x' + '00'.repeat(20)
export const NON_ZERO_ADDRESS = '0x' + '11'.repeat(20)
