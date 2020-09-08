/* External Imports */
import * as rlp from 'rlp'
import seedbytes from 'random-bytes-seed'
import seedfloat from 'seedrandom'
import { BaseTrie } from 'merkle-patricia-tree'

/* Internal Imports */
import { TrieNode, ProofTest, UpdateTest, StateTrieNode, StateTrie, StateTrieMap, AccountStorageProofTest, AccountStorageUpdateTest, StateTrieProofTest, StateTrieUpdateTest } from './trie.types'
import { fromHexString, toHexString } from '../buffer-utils'

/**
 * Utility; generates a random integer.
 * @param seed Seed to the random number generator.
 * @param min Minimum for the RNG.
 * @param max Maximum for the RNG.
 * @returns Random integer between minimum and maximum.
 */
const randomInt = (seed: string, min: number, max: number): number => {
  const randomFloat = seedfloat(seed)
  min = Math.ceil(min)
  max = Math.floor(max)
  return Math.floor(randomFloat() * (max - min + 1)) + min
}

/**
 * Utility; creates a trie object from a list of nodes.
 * @param nodes Nodes to seed the trie with.
 * @returns Trie corresponding to the given nodes.
 */
const makeTrie = async (nodes: TrieNode[]): Promise<BaseTrie> => {
  const trie = new BaseTrie()

  for (const node of nodes) {
    await trie.put(fromHexString(node.key), fromHexString(node.val))
  }

  return trie
}

/**
 * Utility; generates random nodes.
 * @param germ Seed to the random number generator.
 * @param count Number of nodes to generate.
 * @param keySize Size of the key for each node in bytes.
 * @param valSize Size of the value for each node in bytes.
 * @returns List of randomly generated nodes.
 */
const makeRandomNodes = (
  germ: string,
  count: number,
  keySize: number = 32,
  valSize: number = 32
): TrieNode[] => {
  const randomBytes = seedbytes(germ)
  const nodes: TrieNode[] = Array(count)
    .fill({})
    .map(() => {
      return {
        key: randomBytes(keySize).toString('hex'),
        val: randomBytes(valSize).toString('hex'),
      }
    })
  return nodes
}

/**
 * Generates inclusion/exclusion proof test parameters.
 * @param nodes Nodes of the trie, or the trie itself.
 * @param key Key to prove inclusion/exclusion for.
 * @param val Value to prove inclusion/exclusion for.
 * @returns Proof test parameters.
 */
export const makeProofTest = async (
  nodes: TrieNode[] | BaseTrie,
  key: string,
  val?: string
): Promise<ProofTest> => {
  const trie = nodes instanceof BaseTrie ? nodes : await makeTrie(nodes)

  const proof = await BaseTrie.prove(trie, fromHexString(key))
  const ret = val
    ? fromHexString(val)
    : await BaseTrie.verifyProof(trie.root, fromHexString(key), proof)

  return {
    proof: toHexString(rlp.encode(proof)),
    key: toHexString(key),
    val: toHexString(ret),
    root: toHexString(trie.root),
  }
}

/**
 * Automatically generates all possible leaf node inclusion proof tests.
 * @param nodes Nodes to generate tests for.
 * @returns All leaf node tests for the given nodes.
 */
export const makeAllProofTests = async (
  nodes: TrieNode[]
): Promise<ProofTest[]> => {
  const trie = await makeTrie(nodes)
  const tests: ProofTest[] = []

  for (const node of nodes) {
    tests.push(await makeProofTest(trie, node.key))
  }

  return tests
}

/**
 * Generates a random inclusion proof test.
 * @param germ Seed to the random number generator.
 * @param count Number of nodes to create.
 * @param keySize Key size in bytes.
 * @param valSize Value size in bytes.
 * @return Proof test parameters for the randomly generated nodes.
 */
export const makeRandomProofTest = async (
  germ: string,
  count: number,
  keySize: number = 32,
  valSize: number = 32
): Promise<ProofTest> => {
  const nodes = makeRandomNodes(germ, count, keySize, valSize)
  return makeProofTest(nodes, nodes[randomInt(germ, 0, count)].key)
}

/**
 * Generates update test parameters.
 * @param nodes Nodes in the trie.
 * @param key Key to update.
 * @param val Value to update.
 * @returns Update test parameters.
 */
export const makeUpdateTest = async (
  nodes: TrieNode[],
  key: string,
  val: string
): Promise<UpdateTest> => {
  const trie = await makeTrie(nodes)

  const proof = await BaseTrie.prove(trie, fromHexString(key))
  const oldRoot = fromHexString(trie.root)

  await trie.put(fromHexString(key), fromHexString(val))

  return {
    proof: toHexString(rlp.encode(proof)),
    key: toHexString(key),
    val: toHexString(val),
    oldRoot: toHexString(oldRoot),
    newRoot: toHexString(trie.root),
  }
}

/**
 * Generates a random update test.
 * @param germ Seed to the random number generator.
 * @param count Number of nodes to create.
 * @param keySize Key size in bytes.
 * @param valSize Value size in bytes.
 * @return Update test parameters for the randomly generated nodes.
 */
export const makeRandomUpdateTest = async (
  germ: string,
  count: number,
  keySize: number = 32,
  valSize: number = 32
): Promise<UpdateTest> => {
  const nodes = makeRandomNodes(germ, count, keySize, valSize)
  const randomBytes = seedbytes(germ)
  const newKey = randomBytes(keySize).toString('hex')
  const newVal = randomBytes(valSize).toString('hex')
  return makeUpdateTest(nodes, newKey, newVal)
}

const encodeAccountState = (state: StateTrieNode): Buffer => {
  return rlp.encode([
    state.nonce,
    state.balance,
    state.storageRoot,
    state.codeHash,
  ])
}

const decodeAccountState = (state: Buffer): StateTrieNode => {
  const decoded = rlp.decode(state) as any
  return {
    nonce: decoded[0].length ? parseInt(toHexString(decoded[0]), 16) : 0,
    balance: decoded[1].length ? parseInt(toHexString(decoded[1]), 16) : 0,
    storageRoot: decoded[2].length ? toHexString(decoded[2]) : null,
    codeHash: decoded[3].length ? toHexString(decoded[3]) : null,
  }
}

export const makeStateTrie = async (
  state: StateTrieMap
): Promise<StateTrie> => {
  const stateTrie = new BaseTrie()
  const accountTries: { [address: string]: BaseTrie } = {}

  for (const address of Object.keys(state)) {
    const account = state[address]
    accountTries[address] = await makeTrie(account.storage)
    account.state.storageRoot = toHexString(accountTries[address].root)
    await stateTrie.put(fromHexString(address), encodeAccountState(account.state))
  }

  return {
    trie: stateTrie,
    storage: accountTries,
  }
}

export const makeAccountStorageProofTest = async (
  state: StateTrieMap,
  target: string,
  key: string,
  val?: string
): Promise<AccountStorageProofTest> => {
  const stateTrie = await makeStateTrie(state)

  const storageTrie = stateTrie.storage[target]
  const storageTrieWitness = await BaseTrie.prove(storageTrie, fromHexString(key))
  const ret =
    val ||
    (await BaseTrie.verifyProof(
      storageTrie.root,
      fromHexString(key),
      storageTrieWitness
    ))

  const stateTrieWitness = await BaseTrie.prove(
    stateTrie.trie,
    fromHexString(target)
  )

  return {
    address: target,
    key: toHexString(key),
    val: toHexString(ret),
    stateTrieWitness: toHexString(rlp.encode(stateTrieWitness)),
    storageTrieWitness: toHexString(rlp.encode(storageTrieWitness)),
    stateTrieRoot: toHexString(stateTrie.trie.root),
  }
}

export const makeAccountStorageUpdateTest = async (
  state: StateTrieMap,
  target: string,
  key: string,
  val: string,
  accountState?: StateTrieNode
): Promise<AccountStorageUpdateTest> => {
  const stateTrie = await makeStateTrie(state)

  const storageTrie = stateTrie.storage[target]
  const storageTrieWitness = await BaseTrie.prove(storageTrie, fromHexString(key))
  const stateTrieWitness = await BaseTrie.prove(
    stateTrie.trie,
    fromHexString(target)
  )

  if (!accountState) {
    await storageTrie.put(fromHexString(key), fromHexString(val))
    const encodedAccountState = await stateTrie.trie.get(fromHexString(target))
    accountState = decodeAccountState(encodedAccountState)
    accountState.storageRoot = toHexString(storageTrie.root)
  }

  const oldStateTrieRoot = toHexString(stateTrie.trie.root)
  await stateTrie.trie.put(
    fromHexString(target),
    encodeAccountState(accountState)
  )

  return {
    address: target,
    key: toHexString(key),
    val: toHexString(val),
    stateTrieWitness: toHexString(rlp.encode(stateTrieWitness)),
    storageTrieWitness: toHexString(rlp.encode(storageTrieWitness)),
    stateTrieRoot: oldStateTrieRoot,
    newStateTrieRoot: toHexString(stateTrie.trie.root),
  }
}

export const makeStateTrieProofTest = async (
  state: StateTrieMap,
  address: string
): Promise<StateTrieProofTest> => {
  const stateTrie = await makeStateTrie(state)

  const stateTrieWitness = await BaseTrie.prove(
    stateTrie.trie,
    fromHexString(address)
  )

  const ret = await BaseTrie.verifyProof(
    stateTrie.trie.root,
    fromHexString(address),
    stateTrieWitness
  )

  return {
    address,
    encodedAccountState: toHexString(ret),
    stateTrieWitness: toHexString(rlp.encode(stateTrieWitness)),
    stateTrieRoot: toHexString(stateTrie.trie.root),
  }
}

export const makeStateTrieUpdateTest = async (
  state: StateTrieMap,
  address: string,
  accountState: StateTrieNode
): Promise<StateTrieUpdateTest> => {
  const stateTrie = await makeStateTrie(state)

  const stateTrieWitness = await BaseTrie.prove(
    stateTrie.trie,
    fromHexString(address)
  )

  const oldStateTrieRoot = toHexString(stateTrie.trie.root)
  await stateTrie.trie.put(
    fromHexString(address),
    encodeAccountState(accountState)
  )

  return {
    address,
    encodedAccountState: toHexString(encodeAccountState(accountState)),
    stateTrieWitness: toHexString(rlp.encode(stateTrieWitness)),
    stateTrieRoot: oldStateTrieRoot,
    newStateTrieRoot: toHexString(stateTrie.trie.root),
  }
}