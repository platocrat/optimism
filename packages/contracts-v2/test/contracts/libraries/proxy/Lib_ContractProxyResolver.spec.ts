import { expect } from '../../../setup'

/* External Imports */
import { ethers } from '@nomiclabs/buidler'
import { ContractFactory, Contract, Signer } from 'ethers'
import { getMockContract } from '../../../test-helpers/buidler-tools/contract-mocks'
import { NON_ZERO_ADDRESS } from '../../../test-helpers/constants'

describe('Lib_ContractProxyResolver', () => {
  let signer: Signer
  before(async () => {
    ;[signer] = await ethers.getSigners()
  })

  let Mock__Lib_ContractProxyManager: Contract
  beforeEach(async () => {
    Mock__Lib_ContractProxyManager = await getMockContract(
      [
        {
          functionName: 'getProxy',
          inputTypes: ['string memory'],
          outputTypes: ['address'],
          returnValues: [NON_ZERO_ADDRESS],
        },
      ],
      signer
    )
  })

  let Factory__Lib_ContractProxyResolver: ContractFactory
  before(async () => {
    Factory__Lib_ContractProxyResolver = await ethers.getContractFactory(
      'Lib_ContractProxyResolver'
    )
  })

  let Lib_ContractProxyResolver: Contract
  beforeEach(async () => {
    Lib_ContractProxyResolver = await Factory__Lib_ContractProxyResolver.deploy(
      Mock__Lib_ContractProxyManager.address
    )
  })

  describe('resolve()', () => {
    it('should resolve an address when given a name', async () => {
      expect(
        await Lib_ContractProxyResolver.resolve('SomeContractName')
      ).to.equal(NON_ZERO_ADDRESS)

      expect(
        Mock__Lib_ContractProxyManager.getCallData('getProxy(string)', 0)
      ).to.deep.equal(['SomeContractName'])
    })
  })
})
