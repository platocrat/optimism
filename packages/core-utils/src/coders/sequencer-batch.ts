import { add0x, remove0x, encodeHex } from '../utils'
import { BigNumber } from 'ethers'

export interface BatchContext {
  numSequencedTransactions: number
  numSubsequentQueueTransactions: number
  timestamp: number
  blockNumber: number
}

export interface AppendSequencerBatchParams {
  shouldStartAtBatch: number // 5 bytes -- starts at batch
  totalElementsToAppend: number // 3 bytes -- total_elements_to_append
  contexts: BatchContext[] // total_elements[fixed_size[]]
  transactions: string[] // total_size_bytes[],total_size_bytes[]
}

/**
 * Encodes the calldata necessary to make a call to `appendSequencerBatch`.
 * @param batchParams Parameters to the function call.
 * @return Encoded calldata for the function call. Currently does *not* include the sighash.
 */
export const encodeAppendSequencerBatch = (
  batchParams: AppendSequencerBatchParams
): string => {
  // TODO: Should we include the function signature here?

  // (5 bytes) index of the element we expect to append
  const encodedShouldStartAtBatch = encodeHex(
    batchParams.shouldStartAtBatch,
    10
  )

  // (3 bytes) total number of elements to append
  const encodedTotalElementsToAppend = encodeHex(
    batchParams.totalElementsToAppend,
    6
  )

  // (3 bytes) total number of contexts
  const encodedContextsHeader = encodeHex(batchParams.contexts.length, 6)

  // (? bytes) a series of 16 byte "batch contexts." Each batch context is exactly ** 16 bytes **.
  // The number of contexts comes from the 3 bytes above. Each context has the following structure:
  //    - (3 bytes) number of sequencer transactions that will utilize this batch context.
  //    - (3 bytes) number of queue transactions that will be inserted into the chain after the
  //      the sequencer transactions.
  //    - (5 bytes) timestamp that will be assigned to the sequencer transactions.
  //    - (5 bytes) block number that will be assigned to the sequencer transactions.
  const encodedContexts = batchParams.contexts
    .map((context) => {
      return (
        encodeHex(context.numSequencedTransactions, 6) +
        encodeHex(context.numSubsequentQueueTransactions, 6) +
        encodeHex(context.timestamp, 10) +
        encodeHex(context.blockNumber, 10)
      )
    })
    .join('')

  // (? bytes) a series of dynamically sized transaction data chunks. Each transaction consists of
  // the following information:
  //    - (3 bytes) total size of the coming transaction data in bytes.
  //    - (? bytes) arbitrary data of length equal to that described by the first three bytes.
  const encodedTransactionData = batchParams.transactions
    .map((transaction) => {
      if (transaction.length % 2 !== 0) {
        throw new Error('Unexpected uneven hex string value!')
      }

      const encodedTransactionDataHeader = remove0x(
        BigNumber.from(remove0x(transaction).length / 2).toHexString()
      ).padStart(6, '0')

      return encodedTransactionDataHeader + remove0x(transaction)
    })
    .join('')

  // Join it all up.
  return (
    encodedShouldStartAtBatch +
    encodedTotalElementsToAppend +
    encodedContextsHeader +
    encodedContexts +
    encodedTransactionData
  )
}

export const decodeAppendSequencerBatch = (
  encodedSequencerBatch: string
): AppendSequencerBatchParams => {
  encodedSequencerBatch = remove0x(encodedSequencerBatch)

  // (5 bytes) index of the element we expect to append
  const shouldStartAtBatch = encodedSequencerBatch.slice(0, 10)

  // (3 bytes) total number of elements to append
  const totalElementsToAppend = encodedSequencerBatch.slice(10, 16)

  // (3 bytes) total number of contexts
  const contextHeader = encodedSequencerBatch.slice(16, 22)
  const contextCount = parseInt(contextHeader, 16)

  // Scanning by offset. Initial offset is 5 + 3 + 3 bytes = 22 characters.
  let offset = 22

  const contexts = []
  for (let i = 0; i < contextCount; i++) {
    // (3 bytes)
    const numSequencedTransactions = encodedSequencerBatch.slice(
      offset,
      offset + 6
    )
    offset += 6

    // (3 bytes)
    const numSubsequentQueueTransactions = encodedSequencerBatch.slice(
      offset,
      offset + 6
    )
    offset += 6

    // (5 bytes)
    const timestamp = encodedSequencerBatch.slice(offset, offset + 10)
    offset += 10

    // (5 bytes)
    const blockNumber = encodedSequencerBatch.slice(offset, offset + 10)
    offset += 10

    // Make it pretty.
    contexts.push({
      numSequencedTransactions: parseInt(numSequencedTransactions, 16),
      numSubsequentQueueTransactions: parseInt(
        numSubsequentQueueTransactions,
        16
      ),
      timestamp: parseInt(timestamp, 16),
      blockNumber: parseInt(blockNumber, 16),
    })
  }

  const transactions = []
  for (const context of contexts) {
    for (let i = 0; i < context.numSequencedTransactions; i++) {
      // (3 bytes)
      const size = encodedSequencerBatch.slice(offset, offset + 6)
      offset += 6

      // (`size` bytes)
      const raw = encodedSequencerBatch.slice(
        offset,
        offset + parseInt(size, 16) * 2
      )
      offset += raw.length

      // Make it pretty.
      transactions.push(add0x(raw))
    }
  }

  return {
    shouldStartAtBatch: parseInt(shouldStartAtBatch, 16),
    totalElementsToAppend: parseInt(totalElementsToAppend, 16),
    contexts,
    transactions,
  }
}
