import { expect } from '../../../setup'

/* External Imports */
import { ethers } from '@nomiclabs/buidler'
import { ContractFactory, Contract } from 'ethers'

/* Internal Imports */
import { ZERO_ADDRESS, NON_ZERO_ADDRESS } from '../../../test-helpers/constants'

const parseAccount = (result: any[]): any => {
  return {
    nonce: result[0].toNumber(),
    balance: result[1].toNumber(),
    storageRoot: result[2],
    codeHash: result[3],
    ethAddress: result[5],
  }
}

describe('OVM_StateManager', () => {
  let Factory__OVM_StateManager: ContractFactory
  before(async () => {
    Factory__OVM_StateManager = await ethers.getContractFactory(
      'OVM_StateManager'
    )
  })

  let OVM_StateManager: Contract
  beforeEach(async () => {
    OVM_StateManager = await Factory__OVM_StateManager.deploy()
  })

  const SAMPLE_ACCOUNT_1 = {
    address: '0x' + '12'.repeat(20),
    data: {
      nonce: 123,
      balance: 456,
      storageRoot: ethers.utils.keccak256('0x1234'),
      codeHash: ethers.utils.keccak256('0x5678'),
      ethAddress: ZERO_ADDRESS,
    },
  }

  const SAMPLE_ACCOUNT_2 = {
    address: '0x' + '21'.repeat(20),
    data: {
      nonce: 321,
      balance: 654,
      storageRoot: ethers.utils.keccak256('0x4321'),
      codeHash: ethers.utils.keccak256('0x8765'),
      ethAddress: NON_ZERO_ADDRESS,
    },
  }

  describe('putAccount()', () => {
    it('should be able to store an OVM account', async () => {
      await expect(
        OVM_StateManager.putAccount(
          SAMPLE_ACCOUNT_1.address,
          SAMPLE_ACCOUNT_1.data
        )
      ).to.not.be.reverted
    })

    it('should be able to overwrite an OVM account', async () => {
      await OVM_StateManager.putAccount(
        SAMPLE_ACCOUNT_1.address,
        SAMPLE_ACCOUNT_1.data
      )

      await expect(
        OVM_StateManager.putAccount(
          SAMPLE_ACCOUNT_1.address,
          SAMPLE_ACCOUNT_2.data
        )
      ).to.not.be.reverted
    })
  })

  describe('getAccount()', () => {
    it('should be able to retrieve an OVM account', async () => {
      await OVM_StateManager.putAccount(
        SAMPLE_ACCOUNT_1.address,
        SAMPLE_ACCOUNT_1.data
      )

      expect(
        parseAccount(
          await OVM_StateManager.getAccount(SAMPLE_ACCOUNT_1.address)
        )
      ).to.deep.equal(SAMPLE_ACCOUNT_1.data)
    })

    it('should be able to retrieve an overwritten OVM account', async () => {
      await OVM_StateManager.putAccount(
        SAMPLE_ACCOUNT_1.address,
        SAMPLE_ACCOUNT_1.data
      )

      await OVM_StateManager.putAccount(
        SAMPLE_ACCOUNT_1.address,
        SAMPLE_ACCOUNT_2.data
      )

      expect(
        parseAccount(
          await OVM_StateManager.getAccount(SAMPLE_ACCOUNT_1.address)
        )
      ).to.deep.equal(SAMPLE_ACCOUNT_2.data)
    })
  })

  describe('hasAccount()', () => {
    it('should return true if an account exists', async () => {
      await OVM_StateManager.putAccount(
        SAMPLE_ACCOUNT_1.address,
        SAMPLE_ACCOUNT_1.data
      )

      expect(
        await OVM_StateManager.hasAccount(SAMPLE_ACCOUNT_1.address)
      ).to.equal(true)
    })

    it('should return false if the account does not exist', async () => {
      expect(
        await OVM_StateManager.hasAccount(SAMPLE_ACCOUNT_1.address)
      ).to.equal(false)
    })
  })

  describe('putContractStorage()', () => {})

  describe('getContractStorage()', () => {})

  describe('getContractCode()', () => {})

  describe('commitAccount()', () => {})

  describe('isUncommittedAccount()', () => {})

  describe('totalUncommittedAccounts()', () => {})

  describe('commitStorage()', () => {})

  describe('isUncommittedStorage()', () => {})

  describe('totalUncommittedStorage()', () => {})
})
