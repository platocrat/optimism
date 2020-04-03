const EIP20Abstraction = artifacts.require('EIP20');
const { takeSnapshot } = require('./support/helpers.js');
let HST;

contract('EIP20', (accounts) => {
  const tokenName = 'Optipus Coins'
  const tokenSymbol = 'OPT'
  const tokenDecimals = 1

  beforeEach(async () => {
    snapShot = await takeSnapshot();
    snapshotId = snapShot['result'];
    HST = await EIP20Abstraction.new(10000, tokenName, tokenDecimals, tokenSymbol, { from: accounts[0] });
  });

  it.only('transfers: should transfer 10000 to accounts[1] with accounts[0] having 10000', async () => {
    await HST.transfer(accounts[1], 10000, { from: accounts[0] });
    console.log("before revert")
    await revertToSnapShot(snapshotId)
    console.log("after revert")
    await HST.transfer(accounts[1], 10000, { from: accounts[0] });
    // const balance = await HST.balanceOf.call(accounts[1]);
    // console.log("after call")
    // assert.strictEqual(balance.toNumber(), 10000);
  });
});
