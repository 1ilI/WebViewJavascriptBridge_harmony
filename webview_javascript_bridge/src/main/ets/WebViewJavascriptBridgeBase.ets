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

import { WebViewJavascriptBridgeTools } from './WebViewJavascriptBridgeTools';
import { JSON } from '@kit.ArkTS';
import { WebViewJavascriptBridge_JS } from './WebViewJavascriptBridge_JS';

const _LogTAG: string = "[WebViewJavascriptBridge]";
let _logging: boolean = false;
let _logMaxLength: number = 800;

export type WVJBResponseCallback = (responseData: Object) => void;

export type WVJBHandler = (data: Object, responseCallback: WVJBResponseCallback) => void;

export interface WVJBDelegate {
  evaluateJavascript(javascriptCommand: string): void;
}

export class WebViewJavascriptBridgeBase {
  delegate?: WVJBDelegate;
  startupMessageQueue: Array<Map<string, Object>> | undefined;
  responseCallbacks: Map<string, WVJBResponseCallback> = new Map();
  messageHandlers: Map<string, WVJBHandler> = new Map();
  messageHandler?: WVJBHandler;
  private _uniqueId: number = 0;

  constructor() {
    this.startupMessageQueue = [];
  }

  public static enableLogging() {
    _logging = true;
  }

  public static setLogMaxLength(length: number) {
    _logMaxLength = length;
  }

  public reset() {
    this.startupMessageQueue = [];
    this.responseCallbacks.clear();
    this._uniqueId = 0;
  }

  public sendData(data: Object | undefined, responseCallback: WVJBResponseCallback | undefined,
    handlerName: string | undefined): void {
    let message: Map<string, Object> = new Map();
    if (!WebViewJavascriptBridgeTools.isEmpty(data)) {
      message.set("data", data!);
    }
    if (responseCallback) {
      this._uniqueId++;
      let callbackId: string = `harmony_cb_${this._uniqueId}`;
      this.responseCallbacks.set(callbackId, responseCallback);
      message.set("callbackId", callbackId);
    }
    // handlerName
    if (!WebViewJavascriptBridgeTools.isEmpty(handlerName)) {
      message.set("handlerName", handlerName!);
    }
    this._queueMessage(message);
  }

  public flushMessageQueue(messageQueueString: string) {
    if (messageQueueString.length == 0) {
      console.log(_LogTAG, '⚠️ 获取队列消息为空',);
      return;
    }
    const messages = WebViewJavascriptBridgeTools.jsonToObjArr(messageQueueString);
    for (const message of messages) {
      const messageMap = WebViewJavascriptBridgeTools.objToStrKeyMap(message);
      if (!messageMap.size) {
        console.log(_LogTAG, '⚠️ 解析队列消息异常：' + JSON.stringify(message));
        continue;
      }
      this._log("接收", messageMap);

      // 若有 responseId ，则调用 responseCallback
      const responseId: string = WebViewJavascriptBridgeTools.getMapStringValue(messageMap, "responseId");
      if (responseId.length) {
        const responseCallback: WVJBResponseCallback | undefined = this.responseCallbacks.get(responseId);
        if (responseCallback) {
          responseCallback(messageMap.get('responseData') ?? '');
        }
        this.responseCallbacks.delete(responseId);
      }
      // 无 responseId，则看 callbackId
      else {
        let responseCallback: WVJBResponseCallback | undefined;
        // 若有 callbackId ，则处理回调
        const callbackId: string = WebViewJavascriptBridgeTools.getMapStringValue(messageMap, "callbackId");
        if (callbackId.length) {
          responseCallback = (responseData: Object) => {
            const msg: Map<string, Object> = new Map([
              ["responseId", callbackId],
              ["responseData", responseData],
            ]);
            this._queueMessage(msg);
          }
        }
        // 无，则回调不做任何处理
        else {
          responseCallback = (responseData: Object) => {
          }
        }

        // 返回 handler
        const handlerName: string = WebViewJavascriptBridgeTools.getMapStringValue(messageMap, "handlerName");
        const handler: WVJBHandler | undefined = this.messageHandlers.get(handlerName);
        if (!handler) {
          console.log(_LogTAG, '⚠️ WVJBHandler 异常，无相关消息：' + JSON.stringify(message));
          continue;
        }
        handler(messageMap.get('data') ?? '', responseCallback);
      }
    }
  }

  public injectJavascriptFile() {
    this._evaluateJavascript(WebViewJavascriptBridge_JS);
    if (this.startupMessageQueue) {
      let tmpStartupMessageQueue: Array<Map<string, Object>> = [];
      this.startupMessageQueue.forEach((value) => {
        tmpStartupMessageQueue.push(value);
      })
      this.startupMessageQueue = undefined;
      for (const queuedMessage of tmpStartupMessageQueue) {
        this._dispatchMessage(queuedMessage);
      }
    }
  }

  public isQueueMessageURL(url: string) {
    return this._isHttpScheme(url) && url.includes("__wvjb_queue_message__");
  }

  public isBridgeLoadedURL(url: string) {
    return this._isHttpScheme(url) && url.includes("__bridge_loaded__");
  }

  private _isHttpScheme(url: string) {
    return (url.startsWith("http://") || url.startsWith("https://"));
  }

  private _queueMessage(message: Map<string, Object>) {
    if (this.startupMessageQueue) {
      this.startupMessageQueue.push(message);
    } else {
      this._dispatchMessage(message);
    }
  }

  private _dispatchMessage(message: Map<string, Object>) {
    let msgJsonStr = WebViewJavascriptBridgeTools.jsonStringify(message);
    this._log("发送", message);
    msgJsonStr = msgJsonStr.replaceAll("\\", "\\\\");
    msgJsonStr = msgJsonStr.replaceAll("\"", "\\\"");
    msgJsonStr = msgJsonStr.replaceAll("\'", "\\\'");
    msgJsonStr = msgJsonStr.replaceAll("\n", "\\n");
    msgJsonStr = msgJsonStr.replaceAll("\r", "\\r");
    msgJsonStr = msgJsonStr.replaceAll("\f", "\\f");
    msgJsonStr = msgJsonStr.replaceAll("\u2028", "\\u2028");
    msgJsonStr = msgJsonStr.replaceAll("\u2029", "\\u2029");
    let JSCommand = `WebViewJavascriptBridge._handleMessageFromHarmony('${msgJsonStr}');`;
    this._evaluateJavascript(JSCommand);
  }

  private _evaluateJavascript(javascriptCommand: string) {
    this.delegate?.evaluateJavascript(javascriptCommand);
  }

  private _log(action: string, message: Map<string, Object>) {
    if (!_logging) {
      return;
    }
    const msgJsonStr = WebViewJavascriptBridgeTools.jsonStringify(message);
    if (msgJsonStr.length) {
      if (msgJsonStr.length > _logMaxLength) {
        console.log(_LogTAG, `类型：${action}，消息[略]:${msgJsonStr.substring(0, _logMaxLength)}`);
      } else {
        console.log(_LogTAG, `类型：${action}，消息[全]:${msgJsonStr}`);
      }
    }
  }
}