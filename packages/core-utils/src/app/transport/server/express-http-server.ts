/* External Imports */
import bodyParser = require('body-parser')

/* Internal Imports */
import { HttpServer } from '../../../types'
import { createProxyMiddleware } from 'http-proxy-middleware';
import * as WebSocket from 'ws';

/**
 * HTTP server that uses Express under the hood.
 */
export class ExpressHttpServer implements HttpServer {
  protected wsApp
  protected app
  protected webSocket
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
    require('express-ws')(this.app)
    this.app.use(bodyParser.json({ limit: '50mb' }))
    middleware.map((m) => this.app.use(m))

    // if(wsPort) {
      this.wsApp = express()
      wsMiddleware.map(m => this.wsApp.use(m))
      this.webSocket = new WebSocket.Server({ server: this.wsApp });
    // }
    this.initRoutes()
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
      if(this.wsPort) {
        this.wsServer = this.wsApp.listen(this.wsPort, this.hostname, () => {
          console.log(`started ws app on port ${this.wsPort}`)
          resolve()
        })
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
