//: > Codable的简单使用

import Foundation

//: decode

let res = """
{
    "name": "Jone",
    "age": 17
}
"""
let json = res.data(using: .utf8)!

struct Student: Codable {
    let name: String
    let age: Int
}


let decoder = JSONDecoder()
let stu = try! decoder.decode(Student.self, from: json)
print(stu) //Student(name: "Jone", age: 17)

//: encode

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted //输出格式好看点
let data = try! encoder.encode(stu)
print(String(data: data, encoding: .utf8)!)
//{
//    "name" : "Jone",
//    "age" : 17
//}

