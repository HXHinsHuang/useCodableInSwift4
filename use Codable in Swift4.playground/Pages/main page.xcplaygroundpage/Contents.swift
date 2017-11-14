//: > 在Swift3中，对于从服务器获取到的JSON数据后，我们要进行一系列繁琐的操作才能将数据完整的转化成模型

import Foundation

let res = """
{
    "student": {
        "name": "Jone",
        "age": 18,
        "finger": {
            "count": 10
        }
    }
}
"""
let data = res.data(using: .utf8)!


let json = try! JSONSerialization.jsonObject(with: data, options: [])
if let jsonDic = json as? [String:Any] {
    if let student = jsonDic["student"] as? [String:Any] {
        if let finger = student["finger"] as? [String:Int] {
            if let count = finger["count"] {
                print(count)
            }
        }
    }
}

/*:
 ----
 ## 目录:
 1. [Codable的简单使用](page1)
 1. [JSON中的key和模型中的Key不对应](page2)
 1. [处理JSON中的日期格式，浮点数，base64编码，URL](page3)
 1. [处理常见的JSON嵌套结构](page4)
 1. [自定义encoding和decoding](page5)
 1. [处理带有派生关系的model](page6)
 1. [model兼容多个版本的API](page7)
 1. [处理key个数不确定的json](page8)
 1. [Coable中错误的类型(EncodingError & DecodingError)](page9)
 */

