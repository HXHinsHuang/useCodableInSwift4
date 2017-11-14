//: > 处理JSON中的日期格式，浮点数，base64编码，URL

import Foundation

//: 日期格式
//struct Student: Codable {
//    let registerTime: Date
//
//    enum CodingKeys: String, CodingKey {
//        case registerTime = "register_time"
//    }
//}
//
//let stu = Student(registerTime: Date())
//let encoder = JSONEncoder()
//encoder.outputFormatting = .prettyPrinted
//let formatter = DateFormatter()
//formatter.dateFormat = "MMM-dd-yyyy HH:mm:ss zzz"
//encoder.dateEncodingStrategy = .formatted(formatter)
//let encodedData = try encoder.encode(stu)
//print(String(data: encodedData, encoding: .utf8)!)



//: 浮点数
//struct Student: Codable {
//    let height: Float
//}
//
//let res = """
//{
//    "height": "NaN"
//}
//"""
//let json = res.data(using: .utf8)!
//let decoder = JSONDecoder()
//decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "+∞", negativeInfinity: "-∞", nan: "NaN")
//print((try! decoder.decode(Student.self, from: json)).height)

//: base64编码
//struct Student: Codable {
//    let blog: Data
//}
//
//let res = """
//{
//    "blog": "aHR0cDovL3d3dy5qaWFuc2h1LmNvbS91c2Vycy8zMjhmNWY5ZDBiNTgvdGltZWxpbmU="
//}
//"""
//let json = res.data(using: .utf8)!
//let decoder = JSONDecoder()
//decoder.dataDecodingStrategy = .base64
//let stu = try! decoder.decode(Student.self, from: json)
//print(String(data: stu.blog, encoding: .utf8)!)
// http://www.jianshu.com/users/328f5f9d0b58/timeline


//: URL
struct Student: Codable {
    let blogUrl: URL
}
let res = """
{
    "blogUrl": "http://www.jianshu.com/users/328f5f9d0b58/timeline"
}
"""
let json = res.data(using: .utf8)!
let decoder = JSONDecoder()
//print(try! decoder.decode(Student.self, from: json).blogUrl)
let stu = try! decoder.decode(Student.self, from: json)


























