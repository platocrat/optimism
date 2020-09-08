/* External Imports */
import { BaseTrie } from 'merkle-patricia-tree'

export interface UpdateTest {
  proof: string
  key: string
  val: string
  oldRoot: string
  newRoot: string
}

export interface ProofTest {
  proof: string
  key: string
  val: string
  root: string
}

export interface AccountStorageProofTest {
  address: string
  key: string
  val: string
  stateTrieWitness: string
  storageTrieWitness: string
  stateTrieRoot: string
}

export interface AccountStorageUpdateTest extends AccountStorageProofTest {
  newStateTrieRoot: string
}

export interface StateTrieProofTest {
  address: string
  encodedAccountState: string
  stateTrieWitness: string
  stateTrieRoot: string
}

export interface StateTrieUpdateTest extends StateTrieProofTest {
  newStateTrieRoot: string
}

export interface TrieNode {
  key: string
  val: string
}

export interface StateTrieNode {
  nonce: number
  balance: number
  storageRoot: string
  codeHash: string
}

export interface StateTrieMap {
  [address: string]: {
    state: StateTrieNode
    storage: TrieNode[]
  }
}

export interface StateTrie {
  trie: BaseTrie
  storage: {
    [address: string]: BaseTrie
  }
}
