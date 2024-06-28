import { webview } from '@kit.ArkWeb';
import {
  WebViewJavascriptBridge,
  WebViewJavascriptBridgeTools,
  WVJBResponseCallback,
} from '@yue/WebViewJavascriptBridge';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  // 是否开启 web debug
  @Prop webDebugging: boolean = true;
  @State selectHasArgs: boolean = true;
  // WebviewController
  private _controller: webview.WebviewController = new webview.WebviewController();
  // WebViewJavascriptBridge 桥接
  private _bridge: WebViewJavascriptBridge | undefined;

  aboutToAppear() {
    // 配置Web开启调试模式
    if (this.webDebugging) {
      webview.WebviewController.setWebDebuggingAccess(this.webDebugging);
    }
  }

  build() {
    Column() {
      this.webView();
      this.actionView();
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private actionView() {
    Column() {
      Row() {
        Text('调用 getH5Info 是否发送参数').onClick(() => {
          this.selectHasArgs = !this.selectHasArgs;
        })
        Checkbox({ name: '包含参数' }).select(this.selectHasArgs).onChange((value) => {
          this.selectHasArgs = value;
        })
      }.margin({ top: 10, bottom: 5 })

      Button('h5注册方法，原生从 h5 获取信息').onClick(() => {
        this._getH5Info();
      })
    }
    .width('100%')
    .height('30%')
    .backgroundColor(Color.Gray)
  }

  @Builder
  private webView() {
    Web({
      src: $rawfile('index.html'),
      controller: this._controller,
    })
      .width('100%')
      .height('70%')
      .zoomAccess(false)// 不允许缩放
      .domStorageAccess(true)
      .onControllerAttached(() => {
        // WebviewController 载入完成后，设置 WebViewJavascriptBridge
        this.setupWebViewJavascriptBridge();
      })
      .onAlert((event) => {
        AlertDialog.show({ message: event?.message })
        return false;
      })
      .onLoadIntercept((event) => {
        const url = event.data.getRequestUrl();
        // 符合 WebViewJavascriptBridge 的链接规则才拦截
        if (this._bridge?.bridgeInterceptWithURL(url)) {
          return true;
        }
        return false;
      });
  }

  /**
   * 设置 jsBridge
   */
  private setupWebViewJavascriptBridge() {
    // 开启调试，控制台打印信息，默认无调试
    WebViewJavascriptBridge.enableLogging();
    // 创建 WebViewJavascriptBridge
    this._bridge = new WebViewJavascriptBridge(this._controller);
    // 创建后，注册相关方法
    this._bridge.registerHandler('getNativeInfo', (data: Object, responseCallback: WVJBResponseCallback) => {
      if (data) {
        this._toast("JS 调用 getNativeInfo \n原生接收到参数：" + WebViewJavascriptBridgeTools.jsonStringify(data));
      } else {
        this._toast("JS 调用 getNativeInfo 没有向原生传递参数");
      }

      let map1 = new Map<string, Map<string, string>>([
        ["deviceInfo", new Map<string, string>([
          ["types", "harmony"],
          ["debug", "1"],
        ])],
        ["userInfo", new Map<string, string>([
          ["userId", "666666"],
          ["member_name", "用户名"],
        ])],
      ]);
      let map2: Record<string, Record<string, string>> = {
        "deviceInfo": {
          "types": "harmony",
          "debug": "1",
        },
        "userInfo": {
          "userId": "666666",
          "member_name": "用户名",
        }
      }
      // map1 和 map2 均可嵌套，生成 json 字符串，返回给 responseCallback
      const jsonStr: string = WebViewJavascriptBridgeTools.jsonStringify(map1);
      // const jsonStr: string = WebViewJavascriptBridgeTools.jsonStringify(map2);
      responseCallback(jsonStr);
    });


    // 原生主动调用 H5 方法，获取 H5 侧的信息
    this._bridge.callHandler({
      handlerName: 'getH5InfoOnStar', responseCallback: (responseData) => {
        this._toast("初始化时原生调用 getH5InfoOnStar \n接收到结果：" +
        WebViewJavascriptBridgeTools.jsonStringify(responseData));
      }
    })

  }

  private _getH5Info() {
    let arg1 = new Map<string, string | Map<string, string>>([
      ["key", "1"],
      ["h5Info", new Map<string, string>([
        ["id", "1111"],
        ["k", "v"],
      ])],
    ]);
    let arg2: Record<string, string | Record<string, string>> = {
      "key": "2",
      "h5Info": { "id": "222", "k2": "v2" }
    }

    if (this.selectHasArgs) {
      this._bridge?.callHandler({
        handlerName: 'getH5Info',
        data: arg2,
        responseCallback: (responseData) => {
          this._toast(WebViewJavascriptBridgeTools.jsonStringify(responseData));
        }
      })
    }
    // 无参数传递
    else {
      this._bridge?.callHandler({
        handlerName: 'getH5Info',
        responseCallback: (responseData) => {
          this._toast(WebViewJavascriptBridgeTools.jsonStringify(responseData));
        }
      })
    }
  }

  private _toast(msg: string) {
    promptAction.showToast({
      message: msg,
      duration: 4000
    });
  }
}