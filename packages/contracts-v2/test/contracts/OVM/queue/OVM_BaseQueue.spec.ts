import { expect } from '../../../setup'

/* External Imports */
import { ethers } from '@nomiclabs/buidler'
import { Contract, ContractFactory } from 'ethers'

/* Internal Imports */
import { NULL_BYTES32 } from '../../../test-helpers/constants'

const parseQueueElement = (result: any[]): any => {
  return {
    timestamp: result[0].toNumber(),
    batchRoot: result[1],
    isL1ToL2Batch: result[2],
  }
}

const makeQueueElements = (count: number): any => {
  const elements = []
  for (let i = 0; i < count; i++) {
    elements.push({
      timestamp: Date.now(),
      batchRoot: NULL_BYTES32,
      isL1ToL2Batch: false,
    })
  }
  return elements
}

describe('OVM_BaseQueue', () => {
  let OVM_BaseQueue: ContractFactory
  before(async () => {
    OVM_BaseQueue = await ethers.getContractFactory('OVM_BaseQueue')
  })

  let ovmBaseQueue: Contract
  beforeEach(async () => {
    ovmBaseQueue = await OVM_BaseQueue.deploy()
  })

  describe('size()', () => {
    it('should return zero when no elements are in the queue', async () => {
      const size = await ovmBaseQueue.size()
      expect(size).to.equal(0)
    })

    it('should increase when new elements are enqueued', async () => {
      const elements = makeQueueElements(10)
      for (let i = 0; i < elements.length; i++) {
        await ovmBaseQueue.enqueue(elements[i])
        const size = await ovmBaseQueue.size()
        expect(size).to.equal(i + 1)
      }
    })

    it('should decrease when elements are dequeued', async () => {
      const elements = makeQueueElements(10)
      for (let i = 0; i < elements.length; i++) {
        await ovmBaseQueue.enqueue(elements[i])
      }
      for (let i = 0; i < elements.length; i++) {
        await ovmBaseQueue.dequeue()
        const size = await ovmBaseQueue.size()
        expect(size).to.equal(elements.length - i - 1)
      }
    })
  })

  describe('peek()', () => {
    it('should revert when the queue is empty', async () => {
      await expect(ovmBaseQueue.peek()).to.be.revertedWith('Queue is empty.')
    })

    it('should return the front element if only one exists', async () => {
      const [element] = makeQueueElements(1)
      await ovmBaseQueue.enqueue(element)
      const front = await ovmBaseQueue.peek()
      expect(parseQueueElement(front)).to.deep.equal(element)
    })

    it('should return the front if more than one exists', async () => {
      const elements = makeQueueElements(10)
      for (let i = 0; i < elements.length; i++) {
        await ovmBaseQueue.enqueue(elements[i])
        const front = await ovmBaseQueue.peek()
        expect(parseQueueElement(front)).to.deep.equal(elements[0])
      }
    })

    it('should return the new front when elements are dequeued', async () => {
      const elements = makeQueueElements(10)
      for (let i = 0; i < elements.length; i++) {
        await ovmBaseQueue.enqueue(elements[i])
      }
      for (let i = 0; i < elements.length; i++) {
        const front = await ovmBaseQueue.peek()
        expect(parseQueueElement(front)).to.deep.equal(elements[i + 1])
        await ovmBaseQueue.dequeue()
      }
    })
  })

  describe('enqueue()', () => {
    it('should allow users to enqueue an element', async () => {
      const [element] = makeQueueElements(1)
      await expect(ovmBaseQueue.enqueue(element)).to.not.be.reverted
    })

    it('should allow users to enqueue more than one element', async () => {
      const elements = makeQueueElements(10)
      for (let i = 0; i < elements.length; i++) {
        await expect(ovmBaseQueue.enqueue(elements[i])).to.not.be.reverted
      }
    })
  })

  describe('dequeue()', () => {
    it('should revert if the queue is empty', async () => {
      await expect(ovmBaseQueue.dequeue()).to.be.revertedWith('Queue is empty.')
    })

    it('should allow users to dequeue an element', async () => {
      const [element] = makeQueueElements(1)
      await ovmBaseQueue.enqueue(element)
      await expect(ovmBaseQueue.dequeue()).to.not.be.reverted
    })

    it('should allow users to dequeue more than one element', async () => {
      const elements = makeQueueElements(10)
      for (let i = 0; i < elements.length; i++) {
        await ovmBaseQueue.enqueue(elements[i])
      }
      for (let i = 0; i < elements.length; i++) {
        await expect(ovmBaseQueue.dequeue()).to.not.be.reverted
      }
    })
  })
})
