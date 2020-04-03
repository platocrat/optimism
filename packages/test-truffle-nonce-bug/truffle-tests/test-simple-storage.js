const SimpleStorage = artifacts.require('SimpleStorage');
const { takeSnapshot } = require('./support/helpers.js');
let HST;

contract('SimpleStorage', (accounts) => {
  beforeEach(async () => {
    snapShot = await takeSnapshot();
    snapshotId = snapShot['result'];
    simpleStorage = await SimpleStorage.new({ from: accounts[0] });
  });

  it('should revert the nonce when a revert is called', async () => {
    const nonceBefore = await web3.eth.getTransactionCount(accounts[0], 'pending')
    await simpleStorage.set(`0x${"11".repeat(16)}` , { from: accounts[0] });
    await revertToSnapShot(snapshotId)
    const nonceAfter = await web3.eth.getTransactionCount(accounts[0], 'pending')
    assert.equal(nonceBefore, nonceAfter)
  });

  it.only('should set a value after revert', async () => {
    await simpleStorage.set(`0x${"11".repeat(32)}`, { from: accounts[0] });
    await revertToSnapShot(snapshotId)
    await simpleStorage.set(`0x${"11".repeat(32)}`, { from: accounts[0] });
  });

  it.only('should get a value after revert', async () => {
    await simpleStorage.set(`0x${"11".repeat(32)}`, { from: accounts[0] });
    await revertToSnapShot(snapshotId)
    await simpleStorage.get.call();
  });
});
