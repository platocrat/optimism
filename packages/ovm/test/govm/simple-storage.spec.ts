import '../setup'

/* External Imports */
import { Address } from '@eth-optimism/rollup-core'
import { getWallets } from 'ethereum-waffle'
import { getLogger, add0x } from '@eth-optimism/core-utils'
import { Contract, ContractFactory, ethers } from 'ethers'
import { TransactionReceipt, JsonRpcProvider } from 'ethers/providers'
import * as ethereumjsAbi from 'ethereumjs-abi'

/* Contract Imports */
import * as StateManager from '../../build/contracts/StateManager.json'
import * as ExecutionManager from '../../build/contracts/ExecutionManager.json'
import * as SimpleStorage from '../../build/contracts/SimpleStorage.json'

/* Internal Imports */
import {
  ensureGovmIsConnected,
  manuallyDeployOvmContract,
  getUnsignedTransactionCalldata,
  executeTransaction,
} from '../helpers'
import { CHAIN_ID, GAS_LIMIT } from '../../src/app'

const log = getLogger('simple-storage', true)

/*********
 * TESTS *
 *********/

describe('SimpleStorage', () => {
  const provider = new JsonRpcProvider()
  const [wallet] = getWallets(provider)
  // Create pointers to our execution manager & simple storage contract
  let executionManager: Contract
  let simpleStorage: ContractFactory
  let simpleStorageOvmAddress: Address
  const setStorageMethodId: string = ethereumjsAbi
    .methodID('setStorage', [])
    .toString('hex')
  const getStorageMethodId: string = ethereumjsAbi
    .methodID('getStorage', [])
    .toString('hex')

  /* Deploy contracts before each test */
  beforeEach(async () => {
    await ensureGovmIsConnected(provider)
    // Before each test let's deploy a fresh ExecutionManager and SimpleStorage
    // Deploy ExecutionManager the normal way
    executionManager = new ethers.Contract(
      process.env.EXECUTION_MANAGER_ADDRESS,
      ExecutionManager.abi,
      wallet
    )

    // Deploy SimpleStorage with the ExecutionManager
    simpleStorageOvmAddress = await manuallyDeployOvmContract(
      wallet,
      provider,
      executionManager,
      SimpleStorage,
      [executionManager.address]
    )
    // Also set our simple storage ethers contract so we can generate unsigned transactions
    simpleStorage = new ContractFactory(
      SimpleStorage.abi as any, // For some reason the ABI type definition is not accepted
      SimpleStorage.bytecode
    )
  })

  const setStorage = async (slot, value): Promise<TransactionReceipt> => {
    const innerCallData: string = add0x(`${setStorageMethodId}${slot}${value}`)
    return executeTransaction(
      executionManager,
      wallet,
      simpleStorageOvmAddress,
      innerCallData,
      true
    )
  }

  describe('setStorage', async () => {
    it('properly sets storage for the contract we expect', async () => {
      // create calldata vars
      const slot: string = '99'.repeat(32)
      const value: string = '01'.repeat(32)

      const reciept = await setStorage(slot, value)
    })
  })

  describe('getStorage', async () => {
    it.only('correctly loads a value after we store it', async () => {
      const slot = '99'.repeat(32)
      const value = '01'.repeat(32)
      const reciept = await setStorage(slot, value)
      const innerCallData: string = add0x(`${getStorageMethodId}${slot}`)
      const stateManagerAddress = await executionManager.getStateManagerAddress()
      const stateManager = new Contract(stateManagerAddress, StateManager.abi, wallet)
      const nonce = await stateManager.getOvmContractNonce(wallet.address)
      const transaction = {
        nonce,
        gasLimit: GAS_LIMIT,
        gasPrice: 0,
        to: simpleStorageOvmAddress,
        value: 0,
        data: innerCallData,
        chainId: CHAIN_ID,
      }
      const signedMessage = await wallet.sign(transaction)
      const [v, r, s] = ethers.utils.RLP.decode(signedMessage).slice(-3)
      // const callData = getUnsignedTransactionCalldata(
      //   executionManager,
      //   'executeEOACall',
      //   [0, 0, transaction.nonce, transaction.to, transaction.data, v, r, s]
      // )
      //
      // const result = await executionManager.provider.call({
      //   to: executionManager.address,
      //   data: add0x(callData),
      //   gasLimit: 6_700_000,
      // })
      // Fails with:
      // AssertionError: expected '0x08c379a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002054696d657374616d70206d7573742062652067726561746572207468616e2030' to equal '0x0101010101010101010101010101010101010101010101010101010101010101'
      // + expected - actual
      //
      // -0x08c379a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002054696d657374616d70206d7573742062652067726561746572207468616e2030
      // +0x0101010101010101010101010101010101010101010101010101010101010101

      const executionManager2Abi = [
        {
            "constant": true,
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "_timestamp",
                    "type": "uint256"
                },
                {
                    "internalType": "uint256",
                    "name": "_queueOrigin",
                    "type": "uint256"
                },
                {
                    "internalType": "uint256",
                    "name": "_nonce",
                    "type": "uint256"
                },
                {
                    "internalType": "address",
                    "name": "_ovmEntrypoint",
                    "type": "address"
                },
                {
                    "internalType": "bytes",
                    "name": "_callBytes",
                    "type": "bytes"
                },
                {
                    "internalType": "uint8",
                    "name": "_v",
                    "type": "uint8"
                },
                {
                    "internalType": "bytes32",
                    "name": "_r",
                    "type": "bytes32"
                },
                {
                    "internalType": "bytes32",
                    "name": "_s",
                    "type": "bytes32"
                }
            ],
            "name": "executeEOACall",
            "outputs": [],
            "payable": false,
            "stateMutability": "pure",
            "type": "function"
        }
      ]
      const executionManager2 = new Contract(
        executionManager.address,
        ["function executeEOACall(uint256,uint256,uint256,address,bytes,uint8,bytes32,bytes32) constant"],
        wallet

      )
      const result = executionManager2.executeEOACall(
        0, 0, transaction.nonce, transaction.to, transaction.data, v, r, s
      )
      result.should.equal(add0x(value))
      // Fails with
      //
      // AssertionError: expected {} to equal '0x0101010101010101010101010101010101010101010101010101010101010101'
    })
  })
})
