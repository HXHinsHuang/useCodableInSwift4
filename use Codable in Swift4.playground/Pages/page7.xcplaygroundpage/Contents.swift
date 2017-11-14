//: > model兼容多个版本的API

import Foundation



let version1Res = """
{
    "time": "Nov-14-2017 17:25:55 GMT+8"
}
"""

let version2Res = """
{
    "time": "2017-11-14 17:27:35 +0800"
}
"""

struct VersionController {
    enum Version {
        case v1
        case v2
    }
    
    let apiVersion: Version
    var formatter: DateFormatter {
        let formatter = DateFormatter()
        switch apiVersion {
        case .v1:
            formatter.dateFormat = "MMM-dd-yyyy HH:mm:ss zzz"
            break
        case .v2:
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            break
        }
        return formatter
    }
    static let infoKey = CodingUserInfoKey(rawValue: "dateFormatter")!
}

func encode<T>(of model: T, optional: VersionController? = nil) throws where T: Codable {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    if let optional = optional {
        // 通过userInfo存储版本信息
        encoder.userInfo[VersionController.infoKey] = optional
    }
    let encodedData = try encoder.encode(model)
    print(String(data: encodedData, encoding: .utf8)!)
}

struct SomeThing: Codable {
    let time: Date
    
    enum CodingKeys: String, CodingKey {
        case time
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // 通过userInfo读取版本信息
        if let versionC = encoder.userInfo[VersionController.infoKey] as? VersionController {
            let dateString = versionC.formatter.string(from: time)
            try container.encode(dateString, forKey: .time)
        } else {
            fatalError()
        }
    }
}

let s = SomeThing(time: Date())

let verC1 = VersionController(apiVersion: .v1)
try! encode(of: s, optional: verC1)
//{
//    "time" : "Nov-14-2017 20:01:55 GMT+8"
//}
let verC2 = VersionController(apiVersion: .v2)
try! encode(of: s, optional: verC2)
//{
//    "time" : "2017-11-14 20:03:47 +0800"
//}











