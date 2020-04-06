const SimpleStorage = artifacts.require('SimpleStorage');
const { takeSnapshot } = require('./support/helpers.js');

contract('SimpleStorage', (accounts) => {
  beforeEach(async () => {
    simpleStorage = await SimpleStorage.new({ from: accounts[0] });
  });

  it.only('should revert the nonce when a revert is called', async () => {
    const nonceBefore = await web3.eth.getTransactionCount(accounts[0], 'pending')
    snapShot = await takeSnapshot();
    snapshotId = snapShot['result'];
    await simpleStorage.set(`0x${"11".repeat(16)}` , { from: accounts[0] });
    await revertToSnapShot(snapshotId)
    const nonceAfter = await web3.eth.getTransactionCount(accounts[0], 'pending')
    console.log(`Transaction count in test ${await web3.eth.getTransactionCount(
      "0x627306090abaB3A6e1400e9345bC60c78a8BEf57",
      "pending"
    )}`)
    assert.equal(nonceBefore, nonceAfter)
  });

  it('should set a value after revert', async () => {
    console.log("first set")
    await simpleStorage.set(`0x${"11".repeat(32)}`, { from: accounts[0] });
    await revertToSnapShot(snapshotId)
    console.log("second set")
    await simpleStorage.set(`0x${"11".repeat(32)}`, { from: accounts[0] });
  });

  // it.only('should get a value after revert', async () => {
  //   await simpleStorage.set(`0x${"11".repeat(32)}`, { from: accounts[0] });
  //   await revertToSnapShot(snapshotId)
  //   await simpleStorage.get.call();
  // });
});
