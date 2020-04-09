/* External Imports */
import bodyParser = require('body-parser')

/* Internal Imports */
import { HttpServer } from '../../../types'
import { createProxyMiddleware } from 'http-proxy-middleware';

/**
 * HTTP server that uses Express under the hood.
 */
export class ExpressHttpServer implements HttpServer {
  protected wsApp
  protected app
  private listening = false
  private server
  private onWsUpgrade
  protected wsServer

  /**
   * Creates the server.
   * @param port Port to listen on.
   * @param hostname Hostname to listen on.
   */
  constructor(
    private port: number,
    private hostname: string,
    private wsPort?: number,
    middleware: Function[] = [],
    wsMiddleware: Function[] = [],
  ) {
    const express = require('express')
    this.app = express()
    this.app.use(bodyParser.json({ limit: '50mb' }))
    middleware.map((m) => this.app.use(m))

    if(wsPort) {
      this.wsApp = express()
      wsMiddleware.map(m => this.wsApp.use(m))
    }
    this.initRoutes()
  }

  /**
   * Initializes any app routes.
   * App has no routes by default.
   */
  protected setOnWsUpgrade(onWsUpgrade: Function): void {
    this.onWsUpgrade =  onWsUpgrade
  }

  /**
   * Initializes any app routes.
   * App has no routes by default.
   */
  protected initRoutes(): void {
    return
  }

  /**
   * Starts the server.
   */
  public async listen(): Promise<void> {
    if (this.listening) {
      return
    }

    const appStarted = new Promise<void>((resolve, reject) => {
      this.server = this.app.listen(this.port, this.hostname, () => {
        resolve()
      })
    })

    const wsStarted = new Promise<void>((resolve, reject) => {
      if(this.wsApp) {
        this.wsServer = this.wsApp.listen(this.wsPort, this.hostname, () => {
          resolve()
        })
        this.wsServer.on('upgrade', this.onWsUpgrade)
      }
    })

    await Promise.all([appStarted, wsStarted])
    this.listening = true
  }

  /**
   * Stops the server.
   */
  public async close(): Promise<void> {
    if (!this.listening) {
      return
    }

    await this.server.close()
    this.listening = false
  }
}
