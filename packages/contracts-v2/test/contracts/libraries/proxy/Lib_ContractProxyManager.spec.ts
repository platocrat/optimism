import { expect } from '../../../setup'

/* External Imports */
import { ethers } from '@nomiclabs/buidler'
import { ContractFactory, Contract } from 'ethers'

describe('Lib_ContractProxyManager', () => {
  let Factory__Lib_ContractProxyManager: ContractFactory
  before(async () => {
    Factory__Lib_ContractProxyManager = await ethers.getContractFactory(
      'Lib_ContractProxyManager'
    )
  })

  let Lib_ContractProxyManager: Contract
  beforeEach(async () => {
    Lib_ContractProxyManager = await Factory__Lib_ContractProxyManager.deploy()
  })

  const CONTRACT_NAME = 'Sample Contract Name'
  const CONTRACT_PROXY_1 = '0x' + '10'.repeat(20)
  const CONTRACT_PROXY_2 = '0x' + '11'.repeat(20)
  const CONTRACT_TARGET_1 = '0x' + '20'.repeat(20)
  const CONTRACT_TARGET_2 = '0x' + '22'.repeat(20)

  describe('setProxy()', () => {
    it('should be able to set the proxy for a given name', async () => {
      await expect(
        Lib_ContractProxyManager.setProxy(CONTRACT_NAME, CONTRACT_PROXY_1)
      ).to.not.be.reverted
    })

    it('should be able to overwrite proxy for a given name', async () => {
      await Lib_ContractProxyManager.setProxy(CONTRACT_NAME, CONTRACT_PROXY_1)

      await expect(
        Lib_ContractProxyManager.setProxy(CONTRACT_NAME, CONTRACT_PROXY_2)
      ).to.not.be.reverted
    })
  })

  describe('getProxy()', () => {
    it('should be able to get the proxy for a given name', async () => {
      await Lib_ContractProxyManager.setProxy(CONTRACT_NAME, CONTRACT_PROXY_1)

      expect(await Lib_ContractProxyManager.getProxy(CONTRACT_NAME)).to.equal(
        CONTRACT_PROXY_1
      )
    })

    it('should be able to get the overwritten proxy for a given name', async () => {
      await Lib_ContractProxyManager.setProxy(CONTRACT_NAME, CONTRACT_PROXY_1)

      await Lib_ContractProxyManager.setProxy(CONTRACT_NAME, CONTRACT_PROXY_2)

      expect(await Lib_ContractProxyManager.getProxy(CONTRACT_NAME)).to.equal(
        CONTRACT_PROXY_2
      )
    })
  })

  describe('setTarget()', () => {
    it('should be able to set the target for a given name', async () => {
      await expect(
        Lib_ContractProxyManager.setTarget(CONTRACT_NAME, CONTRACT_TARGET_1)
      ).to.not.be.reverted
    })

    it('should be able to overwrite target for a given name', async () => {
      await Lib_ContractProxyManager.setTarget(CONTRACT_NAME, CONTRACT_TARGET_1)

      await expect(
        Lib_ContractProxyManager.setTarget(CONTRACT_NAME, CONTRACT_TARGET_1)
      ).to.not.be.reverted
    })
  })

  describe('getTarget()', () => {
    it('should be able to get the target for a given name', async () => {
      await Lib_ContractProxyManager.setTarget(CONTRACT_NAME, CONTRACT_TARGET_1)

      expect(await Lib_ContractProxyManager.getTarget(CONTRACT_NAME)).to.equal(
        CONTRACT_PROXY_1
      )
    })

    it('should be able to get the overwritten target for a given name', async () => {
      await Lib_ContractProxyManager.setTarget(CONTRACT_NAME, CONTRACT_TARGET_1)

      await Lib_ContractProxyManager.setTarget(CONTRACT_NAME, CONTRACT_TARGET_2)

      expect(await Lib_ContractProxyManager.getTarget(CONTRACT_NAME)).to.equal(
        CONTRACT_TARGET_2
      )
    })
  })
})
