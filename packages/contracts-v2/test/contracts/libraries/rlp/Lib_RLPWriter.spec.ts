import { expect } from '../../../setup'

/* External Imports */
import { ethers } from '@nomiclabs/buidler'
import { Contract, ContractFactory } from 'ethers'

/* Internal Imports */
import { RLP_TEST_JSON } from '../../../test-helpers'

const encode = async (
  Lib_RLPWriter: Contract,
  input: any
): Promise<string> => {
  if (Array.isArray(input)) {
    const encodedElements = input.map((element) => {
      return encode(Lib_RLPWriter, element)
    })
    return Lib_RLPWriter.encodeList(encodedElements)
  } else if (Number.isInteger(input)) {
    return await Lib_RLPWriter.encodeUint(input)
  } else if (input[0] === '#') {
    return Lib_RLPWriter.encodeInt(input.slice(1))
  } else {
    return Lib_RLPWriter.encodeString(input)
  }
}

describe('Lib_RLPWriter', () => {
  let Factory__Lib_RLPWriter: ContractFactory
  let Lib_RLPWriter: Contract
  before(async () => {
    Factory__Lib_RLPWriter = await ethers.getContractFactory('Lib_RLPWriter')
    Lib_RLPWriter = await Factory__Lib_RLPWriter.deploy()
  })

  describe('Official Ethereum RLP Encoding Tests', async () => {
    for (const test of Object.keys(RLP_TEST_JSON)) {
      it(`should properly encode ${test}`, async () => {
        const input = RLP_TEST_JSON[test].in
        const encodedOutput = await encode(Lib_RLPWriter, input)
        expect(encodedOutput).to.equal(RLP_TEST_JSON[test].out)
      })
    }
  })
})
