//: > JSON中的key和模型中的Key不对应

import Foundation

let res = """
{
    "name": "Jone",
    "age": 17,
    "born_in": "China"
}
"""
let json = res.data(using: .utf8)!

struct Student: Codable {
    let name: String
    let age: Int
    let bornIn: String

    enum CodingKeys: String, CodingKey {
        case name
        case age
        case bornIn = "born_in"
    }

}


let decoder = JSONDecoder()
let stu = try! decoder.decode(Student.self, from: json)
print(stu)  //Student(name: "Jone", age: 17, bornIn: "China")

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted //输出格式好看点
let data = try! encoder.encode(stu)
print(String(data: data, encoding: .utf8)!)
//{
//    "name" : "Jone",
//    "age" : 17,
//    "born_in" : "China"
//}

