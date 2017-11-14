//: > 处理key个数不确定的json

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
    let model = try decoder.decode(T.self, from: data)
    return model
}

struct StudentList: Codable {
    var students: [Student] = []
    
    struct Codingkeys: CodingKey {
        var intValue: Int? {return nil}
        init?(intValue: Int) {return nil}
        var stringValue: String //json中的key
        // 根据key来创建Codingkeys，来读取key中的值
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        // 相当于enum中的case
        // 其实就是读取key是name所应对的值
        static let name = Codingkeys(stringValue: "name")!
    }
    
    init(students: Student ... ) {
        self.students = students
    }
    
    init(from decoder: Decoder) throws {
        // 指定映射规则
        let container = try decoder.container(keyedBy: Codingkeys.self)
        var students: [Student] = []
        for key in container.allKeys { //key的类型就是映射规则的类型(Codingkeys)
            if let id = Int(key.stringValue) { // 首先读取key本身的内容
                // 创建内嵌的keyedContainer读取key对应的字典，映射规则同样是Codingkeys
                let keyedContainer = try container.nestedContainer(keyedBy: Codingkeys.self, forKey: key)
                let name = try keyedContainer.decode(String.self, forKey: .name)
                let stu = Student(id: id, name: name)
                students.append(stu)
            }
        }
        self.students = students
    }
    
    func encode(to encoder: Encoder) throws {
        // 指定映射规则
        var container = encoder.container(keyedBy: Codingkeys.self)
        try students.forEach { stu in
            // 用Student的id作为key，然后该key对应的值是一个字典，所以我们创建一个处理字典的子容器
            var keyedContainer = container.nestedContainer(keyedBy: Codingkeys.self, forKey: Codingkeys(stringValue: "\(stu.id)")!)
            try keyedContainer.encode(stu.name, forKey: .name)
        }
    }
    
}

struct Student: Codable {
    let id: Int
    let name: String
}

let stu1 = Student(id: 1, name: "ZhangSan")
let stu2 = Student(id: 2, name: "LiSi")
let stu3 = Student(id: 3, name: "WangWu")
let stuList1 = StudentList(students: stu1, stu2, stu3)
try! encode(of: stuList1)
//{
//    "1" : {
//        "name" : "ZhangSan"
//    },
//    "2" : {
//        "name" : "LiSi"
//    },
//    "3" : {
//        "name" : "WangWu"
//    }
//}

let res = """
{
    "1" : {
        "name" : "ZhangSan"
    },
    "2" : {
        "name" : "LiSi"
    },
    "3" : {
        "name" : "WangWu"
    }
}
"""
let stuList2 = try! decode(of: res, type: StudentList.self)
dump(stuList2)
//▿ __lldb_expr_752.StudentList
//  ▿ students: 3 elements
//    ▿ __lldb_expr_752.Student
//      - id: 2
//      - name: "LiSi"
//    ▿ __lldb_expr_752.Student
//      - id: 1
//      - name: "ZhangSan"
//    ▿ __lldb_expr_752.Student
//      - id: 3
//      - name: "WangWu"


