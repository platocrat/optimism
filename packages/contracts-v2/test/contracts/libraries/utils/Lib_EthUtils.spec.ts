import { expect } from '../../../setup'

/* External Imports */
import { ethers } from '@nomiclabs/buidler'
import { Signer, ContractFactory, Contract } from 'ethers'

/* Internal Imports */
import { CREATE2_TEST_JSON, getMockContract } from '../../../test-helpers'

describe('Lib_EthUtils', () => {
  let signer: Signer
  before(async () => {
    ;[signer] = await ethers.getSigners()
  })

  let Lib_RLPWriter: Contract
  before(async () => {
    const Factory__Lib_RLPWriter = await ethers.getContractFactory('Lib_RLPWriter')
    Lib_RLPWriter = await Factory__Lib_RLPWriter.deploy()
  })

  let Mock__Lib_ContractProxyManager: Contract
  before(async () => {
    Mock__Lib_ContractProxyManager = await getMockContract(
      [
        {
          functionName: 'getProxy',
          inputTypes: ['string memory'],
          outputTypes: ['address'],
          returnValues: [Lib_RLPWriter.address]
        }
      ],
      signer
    )
  })

  let Factory__Lib_EthUtils: ContractFactory
  before(async () => {
    Factory__Lib_EthUtils = await ethers.getContractFactory('Lib_EthUtils')
  })

  let Lib_EthUtils: Contract
  before(async () => {
    Lib_EthUtils = await Factory__Lib_EthUtils.deploy(Mock__Lib_ContractProxyManager.address)
  })

  describe('getCode()', () => {})

  describe('getAddressForCREATE()', () => {
    const nonces = [
      1,
      999999999,
      127,
      128,
      129
    ]

    for (const nonce of nonces) {
      it(`should return the expected address with a nonce of ${nonce}`, async () => {
        const expectedAddress = ethers.utils.getContractAddress({
          from: await signer.getAddress(),
          nonce,
        })

        const computedAddress = await Lib_EthUtils.getAddressForCREATE(
          await signer.getAddress(),
          nonce,
        )

        expect(computedAddress).to.equal(expectedAddress)
      })
    }
  })

  describe('getAddressForCREATE2()', () => {
    for (const test of Object.keys(CREATE2_TEST_JSON)) {
      it(`should return the expected address for ${test}`, async () => {
        const { address, salt, init_code, result } = CREATE2_TEST_JSON[test]
        
        const computedAddress = await Lib_EthUtils.getAddressForCREATE2(
          address,
          init_code,
          salt,
        )
        
        expect(computedAddress.toLowerCase()).to.equal(result.toLowerCase())
      })
    }
  })
})
