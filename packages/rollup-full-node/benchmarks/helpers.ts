let setupFn
let runFn

export const benchmark = async (
  name: string,
  f: Function
) => {
  await f()
  await setupFn()
  const start = new Date().getTime()
  await runFn()
  const duration = new Date().getTime() - start
  console.info(`${name}: ${duration}ms`)
  console.log(runFn)
}

export const setup = async (
  f: Function
) => {
  setupFn = f
}

export const run = async (
  f: Function
) => {
  runFn = f
}
