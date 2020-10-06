/* External Imports */
import { ethers } from 'ethers-v4'

interface Layer {
  provider: any
  messengerAddress: string
}

interface WatcherOptions {
  l1: Layer
  l2: Layer
}

export class Watcher {
  public l1: Layer
  public l2: Layer

  constructor(opts: WatcherOptions) {
    this.l1 = opts.l1
    this.l2 = opts.l2
  }

  public async getMessageHashesFromL1Tx(l1TxHash: string): Promise<string[]> {
    return this._getMessageHashesFromTx(true, l1TxHash)
  }
  public async getMessageHashesFromL2Tx(l2TxHash: string): Promise<string[]> {
    return this._getMessageHashesFromTx(false, l2TxHash)
  }

  public getL2TransactionReceipt(l1ToL2MsgHash: string): Promise<any> {
    return this._getLXTransactionReceipt(false, l1ToL2MsgHash)
  }

  public getL1TransactionReceipt(l2ToL1MsgHash: string): Promise<any> {
    return this._getLXTransactionReceipt(true, l2ToL1MsgHash)
  }

  private async _getMessageHashesFromTx(
    isL1: boolean,
    txHash: string
  ): Promise<string[]> {
    const layer = isL1 ? this.l1 : this.l2
    const l1Receipt = await layer.provider.getTransactionReceipt(txHash)
    const filtered = l1Receipt.logs.filter((log: any) => {
      return (
        log.address === layer.messengerAddress &&
        log.topics[0] === ethers.utils.id('SentMessage(bytes32)')
      )
    })
    return filtered.map((log: any) => log.data)
  }

  private async _getLXTransactionReceipt(isL1: boolean, msgHash: string): Promise<any> {
    const layer = isL1 ? this.l1 : this.l2
    const filter = {
      address: layer.messengerAddress,
      topics: [
        ethers.utils.id(`Relayed${isL1 ? 'L2ToL1' : 'L1ToL2'}Message(bytes32)`),
      ],
    }
    const prevLogs = await layer.provider.getLogs(filter)
    console.log('prevlogs!', prevLogs)
    // const matchedLogs = prevL
    // layer.provider.on(filter, (log: any) => {
    //   if (log.data === msgHash) {
    //     callback(log.transactionHash)
    //   }
    // })
  }
}
