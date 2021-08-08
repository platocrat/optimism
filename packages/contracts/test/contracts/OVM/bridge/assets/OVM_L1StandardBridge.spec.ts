import { expect } from '../../../../setup'

/* External Imports */
import { ethers } from 'hardhat'
import { Signer, ContractFactory, Contract, constants } from 'ethers'
import { Interface } from 'ethers/lib/utils'
import { smockit, MockContract, smoddit } from '@eth-optimism/smock'

/* Internal Imports */
import { NON_NULL_BYTES32, NON_ZERO_ADDRESS } from '../../../../helpers'
import { getContractInterface, predeploys } from '../../../../../src'

const ERR_INVALID_MESSENGER = 'OVM_XCHAIN: messenger contract unauthenticated'
const ERR_INVALID_X_DOMAIN_MSG_SENDER =
  'OVM_XCHAIN: wrong sender of cross-domain message'
const ERR_ALREADY_INITIALIZED = 'Contract has already been initialized.'
const DUMMY_L2_ERC20_ADDRESS = ethers.utils.getAddress('0x' + 'abba'.repeat(10))
const DUMMY_L2_ERC721_ADDRESS = ethers.utils.getAddress(
  '0x' + 'baab'.repeat(10)
)
const DUMMY_L2_BRIDGE_ADDRESS = ethers.utils.getAddress(
  '0x' + 'acdc'.repeat(10)
)

const INITIAL_TOTAL_L1_SUPPLY = 5000
const FINALIZATION_GAS = 1_200_000

describe('OVM_L1StandardBridge', () => {
  // init signers
  let l1MessengerImpersonator: Signer
  let alice: Signer
  let bob: Signer
  let bobsAddress
  let aliceAddress

  // we can just make up this string since it's on the "other" Layer
  let Mock__OVM_ETH: MockContract
  let Factory__L1ERC20: ContractFactory
  let Factory__L1ERC721: ContractFactory
  let IL2ERC20Bridge: Interface
  let IL2ERC721Bridge: Interface
  before(async () => {
    ;[l1MessengerImpersonator, alice, bob] = await ethers.getSigners()

    Mock__OVM_ETH = await smockit(await ethers.getContractFactory('OVM_ETH'))

    // deploy an ERC20 contract on L1
    Factory__L1ERC20 = await smoddit(
      '@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20'
    )

    // deploy an ERC721 contract on L1
    Factory__L1ERC721 = await smoddit(
      'contracts/test-helpers/TestERC721.sol:TestERC721'
    )

    // get an L2ER20Bridge and L2ERC721Bridge Interface
    IL2ERC20Bridge = getContractInterface('iOVM_L2ERC20Bridge')
    IL2ERC721Bridge = getContractInterface('iOVM_L2ERC721Bridge')

    aliceAddress = await alice.getAddress()
    bobsAddress = await bob.getAddress()
  })

  let L1ERC20: Contract
  let L1ERC721: Contract
  let OVM_L1StandardBridge: Contract
  let Mock__OVM_L1CrossDomainMessenger: MockContract
  beforeEach(async () => {
    // Get a new mock L1 messenger
    Mock__OVM_L1CrossDomainMessenger = await smockit(
      await ethers.getContractFactory('OVM_L1CrossDomainMessenger'),
      { address: await l1MessengerImpersonator.getAddress() } // This allows us to use an ethers override {from: Mock__OVM_L2CrossDomainMessenger.address} to mock calls
    )

    // Deploy the contract under test
    OVM_L1StandardBridge = await (
      await ethers.getContractFactory('OVM_L1StandardBridge')
    ).deploy()
    await OVM_L1StandardBridge.initialize(
      Mock__OVM_L1CrossDomainMessenger.address,
      DUMMY_L2_BRIDGE_ADDRESS
    )

    L1ERC20 = await Factory__L1ERC20.deploy('L1ERC20', 'ERC')
    await L1ERC20.smodify.put({
      _totalSupply: INITIAL_TOTAL_L1_SUPPLY,
      _balances: {
        [aliceAddress]: INITIAL_TOTAL_L1_SUPPLY,
      },
    })

    L1ERC721 = await Factory__L1ERC721.deploy()
    await L1ERC721.mint(aliceAddress, 0)
  })

  describe('initialize', () => {
    it('Should only be callable once', async () => {
      await expect(
        OVM_L1StandardBridge.initialize(
          ethers.constants.AddressZero,
          DUMMY_L2_BRIDGE_ADDRESS
        )
      ).to.be.revertedWith(ERR_ALREADY_INITIALIZED)
    })
  })

  describe('ETH deposits', () => {
    const depositAmount = 1_000

    it('depositETH() escrows the deposit amount and sends the correct deposit message', async () => {
      const depositer = await alice.getAddress()
      const initialBalance = await ethers.provider.getBalance(depositer)

      // alice calls deposit on the bridge and the L1 bridge calls transferFrom on the token
      await OVM_L1StandardBridge.connect(alice).depositETH(
        FINALIZATION_GAS,
        NON_NULL_BYTES32,
        {
          value: depositAmount,
          gasPrice: 0,
        }
      )

      const depositCallToMessenger =
        Mock__OVM_L1CrossDomainMessenger.smocked.sendMessage.calls[0]

      const depositerBalance = await ethers.provider.getBalance(depositer)

      expect(depositerBalance).to.equal(initialBalance.sub(depositAmount))

      // bridge's balance is increased
      const bridgeBalance = await ethers.provider.getBalance(
        OVM_L1StandardBridge.address
      )
      expect(bridgeBalance).to.equal(depositAmount)

      // Check the correct cross-chain call was sent:
      // Message should be sent to the L2 bridge
      expect(depositCallToMessenger._target).to.equal(DUMMY_L2_BRIDGE_ADDRESS)
      // Message data should be a call telling the L2ETHToken to finalize the deposit

      // the L1 bridge sends the correct message to the L1 messenger
      expect(depositCallToMessenger._message).to.equal(
        IL2ERC20Bridge.encodeFunctionData('finalizeDeposit', [
          constants.AddressZero,
          predeploys.OVM_ETH,
          depositer,
          depositer,
          depositAmount,
          NON_NULL_BYTES32,
        ])
      )
      expect(depositCallToMessenger._gasLimit).to.equal(FINALIZATION_GAS)
    })

    it('depositETHTo() escrows the deposit amount and sends the correct deposit message', async () => {
      // depositor calls deposit on the bridge and the L1 bridge calls transferFrom on the token
      const initialBalance = await ethers.provider.getBalance(aliceAddress)

      await OVM_L1StandardBridge.connect(alice).depositETHTo(
        bobsAddress,
        FINALIZATION_GAS,
        NON_NULL_BYTES32,
        {
          value: depositAmount,
          gasPrice: 0,
        }
      )
      const depositCallToMessenger =
        Mock__OVM_L1CrossDomainMessenger.smocked.sendMessage.calls[0]

      const depositerBalance = await ethers.provider.getBalance(aliceAddress)
      expect(depositerBalance).to.equal(initialBalance.sub(depositAmount))

      // bridge's balance is increased
      const bridgeBalance = await ethers.provider.getBalance(
        OVM_L1StandardBridge.address
      )
      expect(bridgeBalance).to.equal(depositAmount)

      // Check the correct cross-chain call was sent:
      // Message should be sent to the L2 bridge
      expect(depositCallToMessenger._target).to.equal(DUMMY_L2_BRIDGE_ADDRESS)
      // Message data should be a call telling the L2ETHToken to finalize the deposit

      // the L1 bridge sends the correct message to the L1 messenger
      expect(depositCallToMessenger._message).to.equal(
        IL2ERC20Bridge.encodeFunctionData('finalizeDeposit', [
          constants.AddressZero,
          predeploys.OVM_ETH,
          aliceAddress,
          bobsAddress,
          depositAmount,
          NON_NULL_BYTES32,
        ])
      )
      expect(depositCallToMessenger._gasLimit).to.equal(FINALIZATION_GAS)
    })

    it('cannot depositETH from a contract account', async () => {
      expect(
        OVM_L1StandardBridge.depositETH(FINALIZATION_GAS, NON_NULL_BYTES32, {
          value: depositAmount,
          gasPrice: 0,
        })
      ).to.be.revertedWith('Account not EOA')
    })
  })

  describe('ETH withdrawals', () => {
    it('onlyFromCrossDomainAccount: should revert on calls from a non-crossDomainMessenger L1 account', async () => {
      // Deploy new bridge, initialize with random messenger
      await expect(
        OVM_L1StandardBridge.connect(alice).finalizeETHWithdrawal(
          constants.AddressZero,
          constants.AddressZero,
          1,
          NON_NULL_BYTES32,
          {
            from: aliceAddress,
          }
        )
      ).to.be.revertedWith(ERR_INVALID_MESSENGER)
    })

    it('onlyFromCrossDomainAccount: should revert on calls from the right crossDomainMessenger, but wrong xDomainMessageSender (ie. not the L2ETHToken)', async () => {
      OVM_L1StandardBridge = await (
        await ethers.getContractFactory('OVM_L1StandardBridge')
      ).deploy()
      await OVM_L1StandardBridge.initialize(
        Mock__OVM_L1CrossDomainMessenger.address,
        DUMMY_L2_BRIDGE_ADDRESS
      )

      Mock__OVM_L1CrossDomainMessenger.smocked.xDomainMessageSender.will.return.with(
        '0x' + '22'.repeat(20)
      )

      await expect(
        OVM_L1StandardBridge.finalizeETHWithdrawal(
          constants.AddressZero,
          constants.AddressZero,
          1,
          NON_NULL_BYTES32,
          {
            from: Mock__OVM_L1CrossDomainMessenger.address,
          }
        )
      ).to.be.revertedWith(ERR_INVALID_X_DOMAIN_MSG_SENDER)
    })

    it('should credit funds to the withdrawer and not use too much gas', async () => {
      // make sure no balance at start of test
      expect(await ethers.provider.getBalance(NON_ZERO_ADDRESS)).to.be.equal(0)

      const withdrawalAmount = 100
      Mock__OVM_L1CrossDomainMessenger.smocked.xDomainMessageSender.will.return.with(
        () => DUMMY_L2_BRIDGE_ADDRESS
      )

      // thanks Alice
      await OVM_L1StandardBridge.connect(alice).depositETH(
        FINALIZATION_GAS,
        NON_NULL_BYTES32,
        {
          value: ethers.utils.parseEther('1.0'),
          gasPrice: 0,
        }
      )

      await OVM_L1StandardBridge.finalizeETHWithdrawal(
        NON_ZERO_ADDRESS,
        NON_ZERO_ADDRESS,
        withdrawalAmount,
        NON_NULL_BYTES32,
        {
          from: Mock__OVM_L1CrossDomainMessenger.address,
        }
      )

      expect(await ethers.provider.getBalance(NON_ZERO_ADDRESS)).to.be.equal(
        withdrawalAmount
      )
    })
  })

  describe('ERC20 deposits', () => {
    const depositAmount = 1_000

    beforeEach(async () => {
      await L1ERC20.connect(alice).approve(
        OVM_L1StandardBridge.address,
        depositAmount
      )
    })

    it('depositERC20() escrows the deposit amount and sends the correct deposit message', async () => {
      // alice calls deposit on the bridge and the L1 bridge calls transferFrom on the token
      await OVM_L1StandardBridge.connect(alice).depositERC20(
        L1ERC20.address,
        DUMMY_L2_ERC20_ADDRESS,
        depositAmount,
        FINALIZATION_GAS,
        NON_NULL_BYTES32
      )

      const depositCallToMessenger =
        Mock__OVM_L1CrossDomainMessenger.smocked.sendMessage.calls[0]

      const depositerBalance = await L1ERC20.balanceOf(aliceAddress)

      expect(depositerBalance).to.equal(INITIAL_TOTAL_L1_SUPPLY - depositAmount)

      // bridge's balance is increased
      const bridgeBalance = await L1ERC20.balanceOf(
        OVM_L1StandardBridge.address
      )
      expect(bridgeBalance).to.equal(depositAmount)

      // Check the correct cross-chain call was sent:
      // Message should be sent to the L2 bridge
      expect(depositCallToMessenger._target).to.equal(DUMMY_L2_BRIDGE_ADDRESS)
      // Message data should be a call telling the L2DepositedERC20 to finalize the deposit

      // the L1 bridge sends the correct message to the L1 messenger
      expect(depositCallToMessenger._message).to.equal(
        IL2ERC20Bridge.encodeFunctionData('finalizeDeposit', [
          L1ERC20.address,
          DUMMY_L2_ERC20_ADDRESS,
          aliceAddress,
          aliceAddress,
          depositAmount,
          NON_NULL_BYTES32,
        ])
      )
      expect(depositCallToMessenger._gasLimit).to.equal(FINALIZATION_GAS)
    })

    it('depositERC20To() escrows the deposit amount and sends the correct deposit message', async () => {
      // depositor calls deposit on the bridge and the L1 bridge calls transferFrom on the token
      await OVM_L1StandardBridge.connect(alice).depositERC20To(
        L1ERC20.address,
        DUMMY_L2_ERC20_ADDRESS,
        bobsAddress,
        depositAmount,
        FINALIZATION_GAS,
        NON_NULL_BYTES32
      )
      const depositCallToMessenger =
        Mock__OVM_L1CrossDomainMessenger.smocked.sendMessage.calls[0]

      const depositerBalance = await L1ERC20.balanceOf(aliceAddress)
      expect(depositerBalance).to.equal(INITIAL_TOTAL_L1_SUPPLY - depositAmount)

      // bridge's balance is increased
      const bridgeBalance = await L1ERC20.balanceOf(
        OVM_L1StandardBridge.address
      )
      expect(bridgeBalance).to.equal(depositAmount)

      // Check the correct cross-chain call was sent:
      // Message should be sent to the L2DepositedERC20 on L2
      expect(depositCallToMessenger._target).to.equal(DUMMY_L2_BRIDGE_ADDRESS)
      // Message data should be a call telling the L2DepositedERC20 to finalize the deposit

      // the L1 bridge sends the correct message to the L1 messenger
      expect(depositCallToMessenger._message).to.equal(
        IL2ERC20Bridge.encodeFunctionData('finalizeDeposit', [
          L1ERC20.address,
          DUMMY_L2_ERC20_ADDRESS,
          aliceAddress,
          bobsAddress,
          depositAmount,
          NON_NULL_BYTES32,
        ])
      )
      expect(depositCallToMessenger._gasLimit).to.equal(FINALIZATION_GAS)
    })

    it('cannot depositERC20 from a contract account', async () => {
      expect(
        OVM_L1StandardBridge.depositERC20(
          L1ERC20.address,
          DUMMY_L2_ERC20_ADDRESS,
          depositAmount,
          FINALIZATION_GAS,
          NON_NULL_BYTES32
        )
      ).to.be.revertedWith('Account not EOA')
    })

    describe('Handling ERC20.transferFrom() failures that revert ', () => {
      let MOCK__L1ERC20: MockContract

      before(async () => {
        // Deploy the L1 ERC20 token, Alice will receive the full initialSupply
        MOCK__L1ERC20 = await smockit(
          await Factory__L1ERC20.deploy('L1ERC20', 'ERC')
        )
        MOCK__L1ERC20.smocked.transferFrom.will.revert()
      })

      it('depositERC20(): will revert if ERC20.transferFrom() reverts', async () => {
        await expect(
          OVM_L1StandardBridge.connect(alice).depositERC20(
            MOCK__L1ERC20.address,
            DUMMY_L2_ERC20_ADDRESS,
            depositAmount,
            FINALIZATION_GAS,
            NON_NULL_BYTES32
          )
        ).to.be.revertedWith('SafeERC20: low-level call failed')
      })

      it('depositERC20To(): will revert if ERC20.transferFrom() reverts', async () => {
        await expect(
          OVM_L1StandardBridge.connect(alice).depositERC20To(
            MOCK__L1ERC20.address,
            DUMMY_L2_ERC20_ADDRESS,
            bobsAddress,
            depositAmount,
            FINALIZATION_GAS,
            NON_NULL_BYTES32
          )
        ).to.be.revertedWith('SafeERC20: low-level call failed')
      })

      it('depositERC20To(): will revert if the L1 ERC20 has no code or is zero address', async () => {
        await expect(
          OVM_L1StandardBridge.connect(alice).depositERC20To(
            ethers.constants.AddressZero,
            DUMMY_L2_ERC20_ADDRESS,
            bobsAddress,
            depositAmount,
            FINALIZATION_GAS,
            NON_NULL_BYTES32
          )
        ).to.be.revertedWith('Address: call to non-contract')
      })
    })

    describe('Handling ERC20.transferFrom failures that return false', () => {
      let MOCK__L1ERC20: MockContract
      before(async () => {
        MOCK__L1ERC20 = await smockit(
          await Factory__L1ERC20.deploy('L1ERC20', 'ERC')
        )
        MOCK__L1ERC20.smocked.transferFrom.will.return.with(false)
      })

      it('deposit(): will revert if ERC20.transferFrom() returns false', async () => {
        await expect(
          OVM_L1StandardBridge.connect(alice).depositERC20(
            MOCK__L1ERC20.address,
            DUMMY_L2_ERC20_ADDRESS,
            depositAmount,
            FINALIZATION_GAS,
            NON_NULL_BYTES32
          )
        ).to.be.revertedWith('SafeERC20: ERC20 operation did not succeed')
      })

      it('depositTo(): will revert if ERC20.transferFrom() returns false', async () => {
        await expect(
          OVM_L1StandardBridge.depositERC20To(
            MOCK__L1ERC20.address,
            DUMMY_L2_ERC20_ADDRESS,
            bobsAddress,
            depositAmount,
            FINALIZATION_GAS,
            NON_NULL_BYTES32
          )
        ).to.be.revertedWith('SafeERC20: ERC20 operation did not succeed')
      })
    })
  })

  describe('ERC20 withdrawals', () => {
    it('onlyFromCrossDomainAccount: should revert on calls from a non-crossDomainMessenger L1 account', async () => {
      await expect(
        OVM_L1StandardBridge.connect(alice).finalizeERC20Withdrawal(
          L1ERC20.address,
          DUMMY_L2_ERC20_ADDRESS,
          constants.AddressZero,
          constants.AddressZero,
          1,
          NON_NULL_BYTES32
        )
      ).to.be.revertedWith(ERR_INVALID_MESSENGER)
    })

    it('onlyFromCrossDomainAccount: should revert on calls from the right crossDomainMessenger, but wrong xDomainMessageSender (ie. not the L2DepositedERC20)', async () => {
      Mock__OVM_L1CrossDomainMessenger.smocked.xDomainMessageSender.will.return.with(
        '0x' + '22'.repeat(20)
      )

      await expect(
        OVM_L1StandardBridge.finalizeERC20Withdrawal(
          L1ERC20.address,
          DUMMY_L2_ERC20_ADDRESS,
          constants.AddressZero,
          constants.AddressZero,
          1,
          NON_NULL_BYTES32,
          {
            from: Mock__OVM_L1CrossDomainMessenger.address,
          }
        )
      ).to.be.revertedWith(ERR_INVALID_X_DOMAIN_MSG_SENDER)
    })

    it('should credit funds to the withdrawer and not use too much gas', async () => {
      // First Alice will 'donate' some tokens so that there's a balance to be withdrawn
      const withdrawalAmount = 10
      await L1ERC20.connect(alice).approve(
        OVM_L1StandardBridge.address,
        withdrawalAmount
      )

      await OVM_L1StandardBridge.connect(alice).depositERC20(
        L1ERC20.address,
        DUMMY_L2_ERC20_ADDRESS,
        withdrawalAmount,
        FINALIZATION_GAS,
        NON_NULL_BYTES32
      )

      expect(await L1ERC20.balanceOf(OVM_L1StandardBridge.address)).to.be.equal(
        withdrawalAmount
      )

      // make sure no balance at start of test
      expect(await L1ERC20.balanceOf(NON_ZERO_ADDRESS)).to.be.equal(0)

      Mock__OVM_L1CrossDomainMessenger.smocked.xDomainMessageSender.will.return.with(
        () => DUMMY_L2_BRIDGE_ADDRESS
      )

      await OVM_L1StandardBridge.finalizeERC20Withdrawal(
        L1ERC20.address,
        DUMMY_L2_ERC20_ADDRESS,
        NON_ZERO_ADDRESS,
        NON_ZERO_ADDRESS,
        withdrawalAmount,
        NON_NULL_BYTES32,
        { from: Mock__OVM_L1CrossDomainMessenger.address }
      )

      expect(await L1ERC20.balanceOf(NON_ZERO_ADDRESS)).to.be.equal(
        withdrawalAmount
      )
    })
  })

  describe('ERC721 deposits', () => {
    const tokenId = 0

    beforeEach(async () => {
      await L1ERC721.connect(alice).approve(
        OVM_L1StandardBridge.address,
        tokenId
      )
    })

    it('depositERC721() escrows the deposited NFT and sends the correct deposit message', async () => {
      // alice calls deposit on the bridge and the L1 bridge calls transferFrom on the token
      await OVM_L1StandardBridge.connect(alice).depositERC721(
        L1ERC721.address,
        DUMMY_L2_ERC721_ADDRESS,
        tokenId,
        FINALIZATION_GAS,
        NON_NULL_BYTES32
      )

      const depositCallToMessenger =
        Mock__OVM_L1CrossDomainMessenger.smocked.sendMessage.calls[0]

      const depositerBalance = await L1ERC721.balanceOf(aliceAddress)

      expect(depositerBalance).to.equal(0)

      // bridge's balance is increased
      const bridgeBalance = await L1ERC721.balanceOf(
        OVM_L1StandardBridge.address
      )
      expect(bridgeBalance).to.equal(1)

      const nftOwner = await L1ERC721.ownerOf(tokenId)

      expect(nftOwner).to.equal(OVM_L1StandardBridge.address)

      // Check the correct cross-chain call was sent:
      // Message should be sent to the L2 bridge
      expect(depositCallToMessenger._target).to.equal(DUMMY_L2_BRIDGE_ADDRESS)
      // Message data should be a call telling the L2DepositedERC721 to finalize the deposit

      // the L1 bridge sends the correct message to the L1 messenger
      expect(depositCallToMessenger._message).to.equal(
        IL2ERC721Bridge.encodeFunctionData('finalizeERC721Deposit', [
          L1ERC721.address,
          DUMMY_L2_ERC721_ADDRESS,
          aliceAddress,
          aliceAddress,
          tokenId,
          NON_NULL_BYTES32,
        ])
      )
      expect(depositCallToMessenger._gasLimit).to.equal(FINALIZATION_GAS)
    })

    it('depositERC721To() escrows the deposited NFT and sends the correct deposit message', async () => {
      // alice calls deposit on the bridge and the L1 bridge calls transferFrom on the token
      await OVM_L1StandardBridge.connect(alice).depositERC721To(
        L1ERC721.address,
        DUMMY_L2_ERC721_ADDRESS,
        bobsAddress,
        tokenId,
        FINALIZATION_GAS,
        NON_NULL_BYTES32
      )

      const depositCallToMessenger =
        Mock__OVM_L1CrossDomainMessenger.smocked.sendMessage.calls[0]

      const depositerBalance = await L1ERC721.balanceOf(aliceAddress)

      expect(depositerBalance).to.equal(0)

      // bridge's balance is increased
      const bridgeBalance = await L1ERC721.balanceOf(
        OVM_L1StandardBridge.address
      )
      expect(bridgeBalance).to.equal(1)

      const nftOwner = await L1ERC721.ownerOf(tokenId)

      expect(nftOwner).to.equal(OVM_L1StandardBridge.address)

      // Check the correct cross-chain call was sent:
      // Message should be sent to the L2 bridge
      expect(depositCallToMessenger._target).to.equal(DUMMY_L2_BRIDGE_ADDRESS)
      // Message data should be a call telling the L2DepositedERC721 to finalize the deposit

      // the L1 bridge sends the correct message to the L1 messenger
      expect(depositCallToMessenger._message).to.equal(
        IL2ERC721Bridge.encodeFunctionData('finalizeERC721Deposit', [
          L1ERC721.address,
          DUMMY_L2_ERC721_ADDRESS,
          aliceAddress,
          bobsAddress,
          tokenId,
          NON_NULL_BYTES32,
        ])
      )
      expect(depositCallToMessenger._gasLimit).to.equal(FINALIZATION_GAS)
    })

    it('cannot depositERC721 from a contract account', async () => {
      expect(
        OVM_L1StandardBridge.depositERC721(
          L1ERC721.address,
          DUMMY_L2_ERC721_ADDRESS,
          tokenId,
          FINALIZATION_GAS,
          NON_NULL_BYTES32
        )
      ).to.be.revertedWith('Account not EOA')
    })

    describe('Handling ERC721.safeTransferFrom() failures that revert ', () => {
      let MOCK__L1ERC721: MockContract

      before(async () => {
        // Deploy the L1 ERC721 token and mint one token to Alice
        MOCK__L1ERC721 = await smockit(await Factory__L1ERC721.deploy())
        await MOCK__L1ERC721.connect(alice).mint(aliceAddress, tokenId)
        MOCK__L1ERC721.smocked[
          'safeTransferFrom(address,address,uint256)'
        ].will.revert()
      })

      it('depositERC721(): will revert if ERC721.safeTransferFrom() reverts', async () => {
        await expect(
          OVM_L1StandardBridge.connect(alice).depositERC721(
            MOCK__L1ERC721.address,
            DUMMY_L2_ERC721_ADDRESS,
            tokenId,
            FINALIZATION_GAS,
            NON_NULL_BYTES32
          )
        ).to.be.reverted
      })

      it('depositERC721To(): will revert if ERC721.safeTransferFrom() reverts', async () => {
        await expect(
          OVM_L1StandardBridge.connect(alice).depositERC721To(
            MOCK__L1ERC721.address,
            DUMMY_L2_ERC721_ADDRESS,
            bobsAddress,
            tokenId,
            FINALIZATION_GAS,
            NON_NULL_BYTES32
          )
        ).to.be.reverted
      })

      it('depositERC721To(): will revert if the L1 ERC721 has no code or is zero address', async () => {
        await expect(
          OVM_L1StandardBridge.connect(alice).depositERC721To(
            ethers.constants.AddressZero,
            DUMMY_L2_ERC721_ADDRESS,
            bobsAddress,
            tokenId,
            FINALIZATION_GAS,
            NON_NULL_BYTES32
          )
        ).to.be.reverted
      })
    })
  })

  describe('ERC721 withdrawals', () => {
    it('onlyFromCrossDomainAccount: should revert on calls from a non-crossDomainMessenger L1 account', async () => {
      await expect(
        OVM_L1StandardBridge.connect(alice).finalizeERC721Withdrawal(
          L1ERC721.address,
          DUMMY_L2_ERC721_ADDRESS,
          constants.AddressZero,
          constants.AddressZero,
          1,
          NON_NULL_BYTES32
        )
      ).to.be.revertedWith(ERR_INVALID_MESSENGER)
    })

    it('onlyFromCrossDomainAccount: should revert on calls from the right crossDomainMessenger, but wrong xDomainMessageSender (ie. not the L2DepositedERC721)', async () => {
      Mock__OVM_L1CrossDomainMessenger.smocked.xDomainMessageSender.will.return.with(
        '0x' + '22'.repeat(20)
      )

      await expect(
        OVM_L1StandardBridge.finalizeERC721Withdrawal(
          L1ERC721.address,
          DUMMY_L2_ERC721_ADDRESS,
          constants.AddressZero,
          constants.AddressZero,
          1,
          NON_NULL_BYTES32,
          {
            from: Mock__OVM_L1CrossDomainMessenger.address,
          }
        )
      ).to.be.revertedWith(ERR_INVALID_X_DOMAIN_MSG_SENDER)
    })

    it('should credit the NFT to the withdrawer and not use too much gas', async () => {
      // First Alice will 'donate' one NFT so that there's a NFT to be withdrawn
      const tokenId = 0

      await L1ERC721.connect(alice).approve(
        OVM_L1StandardBridge.address,
        tokenId
      )

      await OVM_L1StandardBridge.connect(alice).depositERC721(
        L1ERC721.address,
        DUMMY_L2_ERC721_ADDRESS,
        tokenId,
        FINALIZATION_GAS,
        NON_NULL_BYTES32
      )

      expect(
        await L1ERC721.balanceOf(OVM_L1StandardBridge.address)
      ).to.be.equal(1)

      // make sure no balance at start of test
      expect(await L1ERC721.balanceOf(NON_ZERO_ADDRESS)).to.be.equal(0)

      Mock__OVM_L1CrossDomainMessenger.smocked.xDomainMessageSender.will.return.with(
        () => DUMMY_L2_BRIDGE_ADDRESS
      )

      await OVM_L1StandardBridge.finalizeERC721Withdrawal(
        L1ERC721.address,
        DUMMY_L2_ERC721_ADDRESS,
        NON_ZERO_ADDRESS,
        NON_ZERO_ADDRESS,
        tokenId,
        NON_NULL_BYTES32,
        { from: Mock__OVM_L1CrossDomainMessenger.address }
      )

      expect(await L1ERC721.balanceOf(NON_ZERO_ADDRESS)).to.be.equal(1)
      expect(await L1ERC721.ownerOf(tokenId)).to.be.equal(NON_ZERO_ADDRESS)
    })
  })
})
