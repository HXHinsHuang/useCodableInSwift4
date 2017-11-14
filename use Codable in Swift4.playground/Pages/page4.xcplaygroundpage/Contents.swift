//: > 处理常见的JSON嵌套结构

import Foundation

func encode<T>(of model: T) throws where T: Codable {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let encodedData = try encoder.encode(model)
    print(String(data: encodedData, encoding: .utf8)!)
}
func decode<T>(of jsonString: String, type: T.Type) throws -> T where T: Codable {
    let data = jsonString.data(using: .utf8)!
    let decoder = JSONDecoder()
    let model = try! decoder.decode(T.self, from: data)
    return model
}


//: 用对象封装数组
//let res = """
//{
//    "students" : [
//        {
//            "name": "ZhangSan",
//            "age": 17,
//            "sex": "male",
//            "born_in": "China"
//        },
//        {
//            "name": "LiSi",
//            "age": 18,
//            "sex": "male",
//            "born_in": "Japan"
//        },
//        {
//            "name": "WangWu",
//            "age": 16,
//            "sex": "male",
//            "born_in": "USA"
//        }
//    ]
//}
//"""
//struct Classes: Codable {
//    let students: [Student]
//
//    struct Student: Codable {
//        let name: String
//        let age: Int
//        let sex: SexType
//        let bornIn: String
//
//        enum SexType: String, Codable {
//            case male
//            case female
//        }
//
//        enum CodingKeys: String, CodingKey {
//            case name
//            case age
//            case sex
//            case bornIn = "born_in"
//        }
//    }
//}
//let c = try! decode(of: res, type: Classes.self)
//dump(c)
//try! encode(of: c)


//: 数组作为JSON根对象
//let res = """
//[
//    {
//        "name": "ZhangSan",
//        "age": 17,
//        "sex": "male",
//        "born_in": "China"
//    },
//    {
//        "name": "LiSi",
//        "age": 18,
//        "sex": "male",
//        "born_in": "Japan"
//    },
//    {
//        "name": "WangWu",
//        "age": 16,
//        "sex": "male",
//        "born_in": "USA"
//    }
//]
//"""
//
//struct Student: Codable {
//    let name: String
//    let age: Int
//    let sex: SexType
//    let bornIn: String
//
//    enum SexType: String, Codable {
//        case male
//        case female
//    }
//
//    enum CodingKeys: String, CodingKey {
//        case name
//        case age
//        case sex
//        case bornIn = "born_in"
//    }
//}
//
//let stu = try! decode(of: res, type: [Student].self)
//dump(stu)
//try! encode(of: stu)

//: 纯数组中的对象带有唯一Key
//let res = """
//[
//    {
//        "student": {
//            "name": "ZhangSan",
//            "age": 17,
//            "sex": "male",
//            "born_in": "China"
//        }
//    },
//    {
//        "student": {
//            "name": "LiSi",
//            "age": 18,
//            "sex": "male",
//            "born_in": "Japan"
//        }
//    },
//    {
//        "student": {
//            "name": "WangWu",
//            "age": 16,
//            "sex": "male",
//            "born_in": "USA"
//        }
//    }
//]
//"""
//
//struct Student: Codable {
//    let name: String
//    let age: Int
//    let sex: SexType
//    let bornIn: String
//
//    enum SexType: String, Codable {
//        case male
//        case female
//    }
//
//    enum CodingKeys: String, CodingKey {
//        case name
//        case age
//        case sex
//        case bornIn = "born_in"
//    }
//}
//let stu = try! decode(of: res, type: [Dictionary<String, Student>].self)
//dump(stu)
//try! encode(of: stu)

//:更一般的复杂情况
let res = """
{
    "info": {
        "grade": "3",
        "classes": "1112"
    },
    "students" : [
        {
            "name": "ZhangSan",
            "age": 17,
            "sex": "male",
            "born_in": "China"
        },
        {
            "name": "LiSi",
            "age": 18,
            "sex": "male",
            "born_in": "Japan"
        },
        {
            "name": "WangWu",
            "age": 16,
            "sex": "male",
            "born_in": "USA"
        }
    ]
}
"""
struct Response: Codable {
    let info: Info
    let students: [Student]
    
    struct Info: Codable {
        let grade: String
        let classes: String
    }
    
    struct Student: Codable {
        let name: String
        let age: Int
        let sex: SexType
        let bornIn: String
        
        enum SexType: String, Codable {
            case male
            case female
        }
        
        enum CodingKeys: String, CodingKey {
            case name
            case age
            case sex
            case bornIn = "born_in"
        }
    }
}
let response = try! decode(of: res, type: Response.self)
dump(response)
try! encode(of: response)

