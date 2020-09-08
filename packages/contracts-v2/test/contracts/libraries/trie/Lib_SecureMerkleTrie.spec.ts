import { expect } from '../../../setup'

/* External Imports */
import { ethers } from '@nomiclabs/buidler'
import { ContractFactory, Contract } from 'ethers'

describe('Lib_SecureMerkleTrie', () => {
  let Factory__Lib_SecureMerkleTrie: ContractFactory
  let Lib_SecureMerkleTrie: Contract
  before(async () => {
    Factory__Lib_SecureMerkleTrie = await ethers.getContractFactory('Lib_SecureMerkleTrie')
    Lib_SecureMerkleTrie = await Factory__Lib_SecureMerkleTrie.deploy()
  })

  describe('verifyInclusionProof()', () => {})

  describe('verifyExclusionProof()', () => {})

  describe('update()', () => {})

  describe('get()', () => {})

  describe('getSingleNodeRootHash()', () => {})
})
