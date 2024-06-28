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

import { HashMap } from '@kit.ArkTS'

export class WebViewJavascriptBridgeTools {
  /**
   * 判断数据是否为空
   * @param value
   * @returns
   */
  public static isEmpty(value: Object | null | undefined): boolean {
    if (value === null || value === undefined || value === '') {
      return true
    }
    if (Array.isArray(value)) {
      return value.length === 0
    }
    if (value instanceof Map || value instanceof Set) {
      return value.size === 0
    }
    if (value?.toLocaleString() === '[object Object]') {
      return JSON.stringify(value) === "{}"
    }
    return false
  }

  /**
   * 任意类型转 json 字符串，不能转的返回空字符串 ""
   * @param json
   * @returns
   */
  public static jsonStringify(json: Object | undefined | null): string {
    if (json instanceof Map) {
      let obj: object = WebViewJavascriptBridgeTools.mapToObject(json);
      return JSON.stringify(obj);
    }
    try {
      let jsonStr = JSON.stringify(json);
      return (jsonStr.length > 0) ? jsonStr : "";
    } catch (e) {
      return "";
    }
  }

  /// json 转 字典 Map<string, Object>
  public static jsonToMap(obj: Object | undefined | null): Map<string, Object> {
    let result: Map<string, Object> = new Map<string, Object>();
    // 传入的 obj 为空
    if (obj === undefined || obj === null) {
      return result;
    }

    // 传入的是 字符串
    if (typeof obj === 'string') {
      // 尝试用 json 对象接收
      try {
        let jsonObj: Object = JSON.parse(obj);
        // json 对象 是 字典
        if (jsonObj instanceof Map) {
          let jsonMap: Map<Object, Object> = jsonObj;
          jsonMap.forEach((value, key) => {
            result.set(key.toString(), value);
          });
        }
        // json 对象 不是 字典
        else {
          try {
            let resultMap: Map<string, Object> = new Map<string, Object>();
            let objMap: Map<Object, Object> = new Map<Object, Object>(Object.entries(obj));
            objMap.forEach((value, key) => {
              resultMap.set(key.toString(), value);
            });
            return resultMap;
          } catch (e) {
          }
        }
      } catch (e) {
      }
    }
    // 传入的本身就是 map
    else if (obj instanceof Map) {
      let objMap: Map<Object, Object> = obj;
      objMap.forEach((value, key) => {
        result.set(key.toString(), value);
      });
    }
    // 其他情况
    else {
      try {
        let resultMap: Map<string, Object> = new Map<string, Object>();
        let objMap: Map<Object, Object> = new Map<Object, Object>(Object.entries(obj));
        objMap.forEach((value, key) => {
          resultMap.set(key.toString(), value);
        });
        return resultMap;
      } catch (e) {
      }
    }
    return result;
  }

  /**
   * json 转 数组 Array<Object>
   * @param obj 任意类型数据 Object
   * @returns 数组 Array<Object>
   */
  public static jsonToObjArr(obj: Object | undefined | null): Array<Object> {
    let result: Array<Object> = new Array();
    // 传入的 obj 为空
    if (obj === undefined || obj === null) {
      return result;
    }

    // 传入的是 字符串
    if (typeof obj === 'string') {
      // 尝试用 json 对象接收
      try {
        let jsonObj: Object = JSON.parse(obj);
        // json 对象 是 数组
        if (jsonObj instanceof Array) {
          result = jsonObj;
        }
        // json 对象 是 字符串
        else if (typeof jsonObj === "string") {
          jsonObj = JSON.parse(jsonObj);
          if (jsonObj instanceof Array) {
            result = jsonObj;
          } else if (typeof jsonObj === "string") {
            jsonObj = JSON.parse(jsonObj);
            if (jsonObj instanceof Array) {
              result = jsonObj;
            }
          }
        } else {

        }
      } catch (e) {
      }
    }
    // 传入的本身就是 arr
    else if (obj instanceof Array) {
      result = obj;
    }
    // 其他情况
    else {
      try {
        let resultArr: Array<Object> = new Array<Object>();
        let objArr: Array<Object> = new Array<Object>(Object.values(obj));
        objArr.forEach((value, index) => {
          resultArr.push(value);
        });
        return resultArr;
      } catch (e) {
      }
    }
    return result;
  }

  /**
   * 传入任意 Object 类型，获得 字符串 类型
   * @param obj 任意类型数据
   * @param def 默认值
   * @returns 字符串
   */
  public static objToStr(obj: Object | undefined | null, def?: string): string {
    let result: string = def ?? "";
    // 传入的 obj 为空
    if (obj === undefined || obj === null || obj === '') {
      return result;
    }

    // 传入的是 字符串
    if (typeof obj === 'string') {
      return obj;
    }
    // 是 bool 类型的，true 为 转为 "1"， 否则为 "0"
    else if (typeof obj === 'boolean') {
      return obj === true ? "1" : "0";
    }
    // 是 number 类型的
    else if (typeof obj === 'number') {
      return obj.toString();
    }
    // 若是 Map 类型的
    else if (obj instanceof Map) {
      let jsonStr = WebViewJavascriptBridgeTools.jsonStringify(obj);
      return (jsonStr.length > 0) ? jsonStr : result;
    }
    // 若是 Array 类型
    else if (obj instanceof Array) {
      let jsonStr = WebViewJavascriptBridgeTools.jsonStringify(obj);
      return (jsonStr.length > 0) ? jsonStr : result;
    }
    // 其他情况
    else {
      let jsonStr = WebViewJavascriptBridgeTools.jsonStringify(obj);
      return (jsonStr.length > 0) ? jsonStr : result;
    }
  }

  /**
   * 传入任意 Object 类型，获得 boolean 布尔 类型
   * @param obj 任意类型数据
   * @param def 默认值
   * @returns 字符串
   */
  public static objToBool(obj: Object | undefined | null, def?: boolean): boolean {
    let result: boolean = def ?? false;
    // 传入的 obj 为空
    if (obj === undefined || obj === null) {
      return result;
    }

    // 传入的是 字符串
    if (typeof obj === 'boolean') {
      return obj;
    }
    // 是 字符串 类型的，"1"、"true"、"TRUE"、"yes"、"YES"  为 true
    else if (typeof obj === 'string') {
      return (obj === "1" || obj.toLowerCase() === "true" || obj.toLowerCase() === "yes") ? true : result;
    }
    // 是 number 类型的 (仅为 1 时才是 true)
    else if (typeof obj === 'number') {
      // 仅为 1 时才是 true
      return (obj === 1 || obj === 1.0) ? true : result;
      // // 非 0 即是 true
      // return (obj !== 0 || obj !== 0.0) ? true : result;
    }
    // 其他情况
    else {

    }
    return result;
  }

  /**
   * 传入任意 Object 类型，获得 number 数值 类型
   * @param obj 任意类型数据
   * @param def 默认值
   * @returns number 数值
   */
  public static objToNum(obj: Object | undefined | null, def?: number): number {
    let result: number = def ?? 0;
    // 传入的 obj 为空
    if (obj === undefined || obj === null) {
      return result;
    }

    // 传入的是 字符串
    if (typeof obj === 'number') {
      return obj;
    }
    // 是 字符串 类型的，"1"、"true"、"TRUE"、"yes"、"YES"  为 true
    else if (typeof obj === 'string') {
      return Number(obj).valueOf();
    }
    // 是 number 类型的
    else if (typeof obj === 'boolean') {
      return (obj === true) ? 1 : result;
    }
    // 其他情况
    else {

    }
    return result;
  }

  /**
   * 传入任意 Object 类型，获得 Map<Object, Object> 字典类型
   * @param obj 任意类型数据
   * @param def 默认值
   * @returns Map<string, Object> 字典类型
   */
  public static objToObjMap(obj: Object | undefined | null, def?: Map<Object, Object>): Map<Object, Object> {
    let result: Map<Object, Object> = def ?? new Map<Object, Object>();
    // 传入的 obj 为空
    if (obj === undefined || obj === null) {
      return result;
    }

    // 是 Map 类型的
    if (obj instanceof Map || obj instanceof HashMap) {
      let resultMap: Map<Object, Object> = new Map<Object, Object>();
      let objMap: Map<Object, Object> = obj as Map<Object, Object>;
      objMap.forEach((value, key) => {
        resultMap.set(key, value);
      });
      return resultMap;
    }
    // 是 字符串类型
    else if (typeof obj === 'string') {
      return (obj.length > 0) ? WebViewJavascriptBridgeTools.jsonToMap(obj) : result;
    }
    // 其他类型
    else {
      try {
        return new Map<Object, Object>(Object.entries(obj));
      } catch (e) {
      }
    }
    return result;
  }

  /**
   * 传入任意 Object 类型，获得 Map<string, Object> 字典类型
   * @param obj 任意类型数据
   * @param def 默认值
   * @returns Map<string, Object> 字典类型
   */
  public static objToStrKeyMap(obj: Object | undefined | null, def?: Map<string, Object>): Map<string, Object> {
    let result: Map<string, Object> = def ?? new Map<string, Object>();
    // 传入的 obj 为空
    if (obj === undefined || obj === null) {
      return result;
    }

    // 是 Map 类型的
    if (obj instanceof Map) {
      let resultMap: Map<string, Object> = new Map<string, Object>();
      let objMap: Map<Object, Object> = obj as Map<Object, Object>;
      objMap.forEach((value, key) => {
        resultMap.set(key.toString(), value);
      });
      return resultMap;
    }
    // 是 字符串类型
    else if (typeof obj === 'string') {
      return (obj.length > 0) ? WebViewJavascriptBridgeTools.jsonToMap(obj) : result;
    }
    // 其他类型
    else {
      try {
        let resultMap: Map<string, Object> = new Map<string, Object>();
        let objMap: Map<Object, Object> = new Map<Object, Object>(Object.entries(obj));
        objMap.forEach((value, key) => {
          resultMap.set(key.toString(), value);
        });
        return resultMap;
      } catch (e) {
      }
    }
    return result;
  }

  /// 获取一个 Map 里面 的 原始值，可能是空 undefined，支持 aaa/bbb/ccc 多级取值
  public static getMapOriginValue(map: Map<Object, Object> | undefined, key: string): Object | undefined {
    // map 无数据
    if (map === undefined || map === null) {
      return undefined;
    }
    // map 有数据
    if (key.match('/')) {
      const keyList = key.split('/');
      return WebViewJavascriptBridgeTools._mapGetValue(map, keyList);
    } else {
      return map.get(key);
    }
  }

  /// 获取一个 Map 里面 string 类型的值
  public static getMapStringValue(map: Map<Object, Object> | undefined, key: string, def?: string): string {
    let value = WebViewJavascriptBridgeTools.getMapOriginValue(map, key);
    if (value === undefined || value === null) {
      return def ?? "";
    } else {
      return WebViewJavascriptBridgeTools.objToStr(value, def);
    }
  }

  /// 获取一个 Map 里面 number 类型的值
  public static getMapNumberValue(map: Map<Object, Object> | undefined, key: string, def?: number): number {
    let value = WebViewJavascriptBridgeTools.getMapOriginValue(map, key)
    if (value === undefined || value === null) {
      return def ?? 0;
    } else {
      return WebViewJavascriptBridgeTools.objToNum(value, def);
    }
  }

  /// 获取一个 Map 里面 number 类型的值
  public static getMapBoolValue(map: Map<Object, Object> | undefined, key: string, def?: boolean): boolean {
    let value = WebViewJavascriptBridgeTools.getMapOriginValue(map, key)
    if (value === undefined || value === null) {
      return def ?? false;
    } else {
      return WebViewJavascriptBridgeTools.objToBool(value, def);
    }
  }

  /**
   * Map 转 Object
   * @param map
   * @returns
   */
  public static mapToObject(map: Map<object, Object>): object {
    let obj: object = new Object();
    if (map instanceof Map) {
      map.forEach((value: Object, key: Object) => {
        if (value instanceof Map) {
          obj[key.toString()] = WebViewJavascriptBridgeTools.mapToObject(value);
        } else {
          obj[key.toString()] = value;
        }
      });
    }
    return obj;
  }

  /**
   * 内部方法，获取一个 字典 下，对应 keys 顺序的 值
   * @param map map 对象
   * @param keys [aaa, bbb, ccc] 多级 key 拆分的数组
   * @returns 结果
   */
  private static _mapGetValue(map: Object | undefined, keys: Array<string>): Object | undefined {
    // map 无数据
    if (map === undefined || map === null) {
      return undefined;
    }
    // map 转 newMap
    const newMap = WebViewJavascriptBridgeTools.objToObjMap(map);
    // newMap 无数据
    if (newMap.size === 0) {
      return undefined;
    }
    // newMap 有数据
    let tmpMap = newMap;
    for (let index = 0; index < keys.length; index++) {
      const key = keys[index];
      const getValue = tmpMap.get(key);
      // 最后一个了
      if (index == keys.length - 1) {
        return getValue;
      } else {
        if (getValue === undefined || getValue === null) {
          return undefined;
        }
        tmpMap = WebViewJavascriptBridgeTools.objToObjMap(getValue);
      }
    }
    return undefined;
  }
}