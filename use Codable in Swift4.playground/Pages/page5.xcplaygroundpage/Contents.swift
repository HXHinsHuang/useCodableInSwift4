//: > 自定义encoding和decoding

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

//: ## 自定义encoding

//: 重写系统的方法，实现与系统一样的decode和encode效果 和 使用struct来遵守CodingKey来指定映射规则
/*
struct Student: Codable {
    let name: String
    let age: Int
    let bornIn: String
    
    // 映射规则，用来指定属性和json中key两者间的映射的规则
    enum CodingKeys: String, CodingKey {
        case name
        case age
        case bornIn = "born_in"
    }
    
    // 映射规则，用来指定属性和json中key两者间的映射的规则
//    struct CodingKeys: CodingKey {
//        var stringValue: String
//        var intValue: Int? { return nil }
//        init?(intValue: Int) { return nil }
//
//        // 在decode过程中，这里传入的stringValue就是json中对应的key，然后获取该key的值
//        // 在encode过程中，这里传入的stringValue就是生成的json中对应的key，然后设置key的值
//        init?(stringValue: String) {
//            self.stringValue = stringValue
//        }
//        // 相当于enum中的case
//        static let name = CodingKeys(stringValue: "name")!
//        static let age = CodingKeys(stringValue: "age")!
//        static let bornIn = CodingKeys(stringValue: "born_in")!
//    }


    init(name: String, age: Int, bornIn: String) {
        self.name = name
        self.age = age
        self.bornIn = bornIn
    }
    
    // 重写decoding
    init(from decoder: Decoder) throws {
        // 通过指定映射规则来创建解码容器，通过该容器获取json中的数据，因此是个常量
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let age = try container.decode(Int.self, forKey: .age)
        let bornIn = try container.decode(String.self, forKey: .bornIn)
        self.init(name: name, age: age, bornIn: bornIn)
    }
    
    // 重写encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
        try container.encode(bornIn, forKey: .bornIn)
    }
}

let res = """
{
    "name": "Jone",
    "age": 17,
    "born_in": "China"
}
"""
let stu = try! decode(of: res, type: Student.self)
dump(stu)
try! encode(of: stu)
*/


/*
//: 时间格式处理
struct Student: Codable {
    let registerTime: Date
    
    enum CodingKeys: String, CodingKey {
        case registerTime = "register_time"
    }
    
    
//    init(registerTime: Date) {
//        self.registerTime = registerTime
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let registerTime = try container.decode(Date.self, forKey: .registerTime)
//        self.init(registerTime: registerTime)
//    }
    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMM-dd-yyyy HH:mm:ssZ"
//        let stringDate = formatter.string(from: registerTime)
//        try container.encode(stringDate, forKey: .registerTime)
//    }
}

try! encode(of: Student(registerTime: Date()))
*/


/*
//: option值处理

struct Student: Codable {
    var scores: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case scores
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scores, forKey: .scores)
    }
}
try! encode(of: Student())
//{
//    "scores" : null
//}
*/


/*
//: 数组处理
struct Student: Codable {
    let scores: [Int] = [66, 77, 88]
    
    enum CodingKeys: String, CodingKey {
        case scores
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var unkeyedContainer = container.nestedUnkeyedContainer(forKey: .scores)
        try scores.forEach {
            try unkeyedContainer.encode("\($0)分")
        }
    }
}
try! encode(of: Student())
*/



//: ## 自定义decoding

//: 时间格式处理
/*
struct Student: Codable {
    let registerTime: Date
    
    enum CodingKeys: String, CodingKey {
        case registerTime = "register_time"
}

    init(registerTime: Date) {
        self.registerTime = registerTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let registerTime = try container.decode(Date.self, forKey: .registerTime)
//        let dateString = try container.decode(String.self, forKey: .registerTime)
//        let formaater = DateFormatter()
//        formaater.dateFormat = "yyyy-MM-dd HH:mm:ss z"
//        let registerTime = formaater.date(from: dateString)!
        self.init(registerTime: registerTime)
    }
}

let res = """
{
    "register_time": "2017-11-13 22:30:15 +0800"
}
"""
let stu = try! decode(of: res, type: Student.self)
dump(stu)
*/


//: 数组处理
/*
struct Student: Codable {
    let grossScore: Int
    let scores: [Float]
    
    enum CodingKeys: String, CodingKey {
        case grossScore = "gross_score"
        case scores
    }
    
    init(grossScore: Int, scores: [Float]) {
        self.grossScore = grossScore
        self.scores = scores
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let grossScore = try container.decode(Int.self, forKey: .grossScore)
        var scores = [Float]()
        // 处理数组时所使用的容器(UnkeyedContainer)
        var unkeyedContainer = try container.nestedUnkeyedContainer(forKey: .scores)
        // isAtEnd:A Boolean value indicating whether there are no more elements left to be decoded in the container.
        while !unkeyedContainer.isAtEnd {
            let proportion = try unkeyedContainer.decode(Float.self)
            let score = proportion * Float(grossScore)
            scores.append(score)
        }
        self.init(grossScore: grossScore, scores: scores)
    }
}

let res = """
{
    "gross_score": 120,
    "scores": [
        0.65,
        0.75,
        0.85
    ]
}
"""
let stu = try! decode(of: res, type: Student.self)
dump(stu)
*/


//: 扁平化JSON的编码和解码
struct Student: Codable {
    let name: String
    let age: Int
    let bornIn: String
    let grossScore: Int
    let scores: [Float]
    
    enum CodingKeys: String, CodingKey {
        case name
        case age
        case bornIn = "born_in"
        case meta
    }
    
    // 这里要指定嵌套的数据中的映射规则
    enum MetaCodingKeys: String, CodingKey {
        case grossScore = "gross_score"
        case scores
    }


    init(name: String, age: Int, bornIn: String, grossScore: Int, scores: [Float]) {
        self.name = name
        self.age = age
        self.bornIn = bornIn
        self.grossScore = grossScore
        self.scores = scores
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let age = try container.decode(Int.self, forKey: .age)
        let bornIn = try container.decode(String.self, forKey: .bornIn)
        
        // 创建一个对字典处理用的容器 (KeyedDecodingContainer)，并指定json中key和属性名的规则
        let keyedContainer = try container.nestedContainer(keyedBy: MetaCodingKeys.self, forKey: .meta)
        let grossScore = try keyedContainer.decode(Int.self, forKey: .grossScore)
        var unkeyedContainer = try keyedContainer.nestedUnkeyedContainer(forKey: .scores)
        var scores = [Float]()
        while !unkeyedContainer.isAtEnd {
            let proportion = try unkeyedContainer.decode(Float.self)
            let score = proportion * Float(grossScore)
            scores.append(score)
        }
        self.init(name: name, age: age, bornIn: bornIn, grossScore: grossScore, scores: scores)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
        try container.encode(bornIn, forKey: .bornIn)
        
        // 创建一个对字典处理用的容器 (KeyedEncodingContainer)，并指定json中key和属性名的规则
        var keyedContainer = container.nestedContainer(keyedBy: MetaCodingKeys.self, forKey: .meta)
        try keyedContainer.encode(grossScore, forKey: .grossScore)
        var unkeyedContainer = keyedContainer.nestedUnkeyedContainer(forKey: .scores)
        try scores.forEach {
            try unkeyedContainer.encode("\($0)分")
        }
    }
}

let res = """
{
    "name": "Jone",
    "age": 17,
    "born_in": "China",
    "meta": {
        "gross_score": 120,
        "scores": [
            0.65,
            0.75,
            0.85
        ]
    }
}
"""
let stu = try! decode(of: res, type: Student.self)
dump(stu)
try! encode(of: stu)
//▿ __lldb_expr_82.Student
//    - name: "Jone"
//    - age: 17
//    - bornIn: "China"
//    - grossScore: 120
//    ▿ scores: 3 elements
//        - 78.0
//        - 90.0
//        - 102.0
//
//{
//    "age" : 17,
//    "meta" : {
//        "gross_score" : 120,
//        "scores" : [
//        "78.0分",
//        "90.0分",
//        "102.0分"
//        ]
//    },
//    "born_in" : "China",
//    "name" : "Jone"
//}






























