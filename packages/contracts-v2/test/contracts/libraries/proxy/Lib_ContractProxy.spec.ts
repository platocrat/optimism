import { expect } from '../../../setup'

/* External Imports */
import { ethers } from '@nomiclabs/buidler'
import { Signer, Contract, ContractFactory } from 'ethers'

/* Internal Imports */
import { getMockContract } from '../../../test-helpers/buidler-tools/contract-mocks'
import { ZERO_ADDRESS } from '../../../test-helpers/constants'

describe('Lib_ContractProxy', () => {
  let signer: Signer
  before(async () => {
    ;[signer] = await ethers.getSigners()
  })

  let Mock__ProxyTarget: Contract
  let Mock__Lib_ContractProxyManager: Contract
  beforeEach(async () => {
    Mock__ProxyTarget = await getMockContract(
      [
        {
          functionName: 'doSomething',
          inputTypes: [],
          outputTypes: [],
          returnValues: [],
        },
      ],
      signer
    )

    Mock__Lib_ContractProxyManager = await getMockContract(
      [
        {
          functionName: 'getTarget',
          inputTypes: ['address'],
          outputTypes: ['address'],
          returnValues: [Mock__ProxyTarget.address],
        },
      ],
      signer
    )
  })

  let Factory__Lib_ContractProxy: ContractFactory
  before(async () => {
    Factory__Lib_ContractProxy = await ethers.getContractFactory(
      'Lib_ContractProxy'
    )
  })

  let Lib_ContractProxy: Contract
  beforeEach(async () => {
    Lib_ContractProxy = await Factory__Lib_ContractProxy.deploy(
      Mock__Lib_ContractProxyManager.address
    )
  })

  describe('fallback()', () => {
    it('should forward calls to the target when it exists', async () => {
      const calldata = Mock__ProxyTarget.interface.encodeFunctionData(
        'doSomething'
      )

      await Lib_ContractProxy.fallback({
        data: calldata,
      })

      expect(
        await Mock__Lib_ContractProxyManager.getCallCount('getTarget(address)')
      ).to.equal(1)

      expect(
        await Mock__ProxyTarget.getCallData('doSomething()', 0)
      ).to.deep.equal([])
    })

    it('should revert when the target has not been set', async () => {
      Mock__Lib_ContractProxyManager = await getMockContract(
        [
          {
            functionName: 'getTarget',
            inputTypes: ['address'],
            outputTypes: ['address'],
            returnValues: [ZERO_ADDRESS],
          },
        ],
        signer
      )

      Lib_ContractProxy = await Factory__Lib_ContractProxy.deploy(
        Mock__Lib_ContractProxyManager.address
      )

      const calldata = Mock__ProxyTarget.interface.encodeFunctionData(
        'doSomething'
      )

      await expect(
        Lib_ContractProxy.fallback({
          data: calldata,
        })
      ).to.be.revertedWith('Proxy does not have a target.')
    })
  })
})
