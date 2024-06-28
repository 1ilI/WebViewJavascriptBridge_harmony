/*
 * Copyright (c) Yue 2024.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Created by Yue on 2024/6/24.
 */

import {
  WebViewJavascriptBridgeBase,
  WVJBDelegate,
  WVJBHandler,
  WVJBResponseCallback
} from './WebViewJavascriptBridgeBase';
import { FetchQueueJS } from './WebViewJavascriptBridge_JS';

export interface SendParams {
  data: Object,
  responseCallback: WVJBResponseCallback,
}

export interface CallParams {
  data?: Object,
  handlerName: string,
  responseCallback?: WVJBResponseCallback,
}

export class WebViewJavascriptBridge implements WVJBDelegate {
  private _base: WebViewJavascriptBridgeBase = new WebViewJavascriptBridgeBase();
  private _webController: WebviewController | undefined;

  constructor(forWebController: WebviewController) {
    this._base.delegate = this;
    this._webController = forWebController;
  }

  public static enableLogging() {
    WebViewJavascriptBridgeBase.enableLogging();
  }

  public bridgeInterceptWithURL(url: string): boolean {
    if (this._base.isBridgeLoadedURL(url)) {
      this._base.injectJavascriptFile();
      return true;
    } else if (this._base.isQueueMessageURL(url)) {
      this._flushMessageQueue();
      return true;
    }
    return false;
  }

  public registerHandler(handlerName: string, handler: WVJBHandler) {
    this._base.messageHandlers.set(handlerName, handler);
  }

  public removeHandler(handlerName: string) {
    if (this._base.messageHandlers.has(handlerName)) {
      this._base.messageHandlers.delete(handlerName);
    }
  }

  public send(params: SendParams) {
    this._base.sendData(params?.data, params?.responseCallback, undefined);
  }

  public callHandler(params: CallParams) {
    this._base.sendData(params?.data, params?.responseCallback, params?.handlerName);
  }

  public reset() {
    this._base.reset();
  }

  evaluateJavascript(javascriptCommand: string): void {
    if (this._webController) {
      this._webController.runJavaScriptExt(javascriptCommand, (error, result) => {
      });
    } else {
      console.log('❌ WebViewJavascriptBridge 未初始化');
    }
  }

  private _flushMessageQueue() {
    if (this._webController) {
      this._webController.runJavaScriptExt(FetchQueueJS, (error, result) => {
        if (error) {
          console.log('❌执行 js 方法 _fetchQueue 出错' + error.message);
        }
        this._base.flushMessageQueue(result.getString());
      })
    } else {
      console.log('❌ WebViewJavascriptBridge 未初始化');
    }
  }
}