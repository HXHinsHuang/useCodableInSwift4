# Swift4中Codable的使用（二）

>继上一篇文章，我们学习了`Codable`协议在json与模型之间编码和解码的基本使用。本篇我们将继续了解该协议，实现自定义模型转json编码和自定义json转模型解码的过程。

---

对于自定义模型转json编码和自定义json转模型解码的过程，我们只需要在该类型中重写`Codable`协议中的编码和解码方法即可：

```swift
public protocol Encodable {
    public func encode(to encoder: Encoder) throws
}
public protocol Decodable {
    public init(from decoder: Decoder) throws
}
public typealias Codable = Decodable & Encodable
```

我们先定义一个Student模型来进行演示：

```swift
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
}
```

---
### 重写系统的方法，实现与系统一样的decode和encode效果

在自定义前，我们先来把这两个方法重写成系统默认的实现来了解一下，对于这两个方法，我们要掌握的是`container`的用法。

```swift
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
        // 通过指定映射规则来创建编码码容器，通过往容器里添加内容最后生成json，因此是个变量
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
        try container.encode(bornIn, forKey: .bornIn)
    }
```
对于编码和解码的过程，我们都是创建一个容器，该容器有一个`keyedBy`的参数，用于指定属性和json中key两者间的映射的规则，因此这次我们传`CodingKeys`的类型过去，说明我们要使用该规则来映射。对于解码的过程，我们使用该容器来进行解码，指定要值的类型和获取哪一个key的值，同样的，编码的过程中，我们使用该容器来指定要编码的值和该值对应json中的key，他们看起来有点像`Dictionary`的用法。还是使用上一篇的泛型函数来进行encode和decode：

```swift
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
```
现在我们来验证我们重写写的是否正确：

```swift
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
//▿ __lldb_expr_1.Student
//  - name: "Jone"
//  - age: 17
//  - bornIn: "China"
//{
//    "name" : "Jone",
//    "age" : 17,
//    "born_in" : "China"
//}
```
打印的结果是正确的，现在我们重写的方法实现了和原生的一样效果。

---
###使用struct来遵守CodingKey来指定映射规则

接着我们倒回去看我们定义的模型，模型中定义的`CodingKeys`映射规则是用`enum`来遵守`CodingKey`协议实现的，其实我们还可以把`CodingKeys`的类型定义一个`struct`来实现`CodingKey`协议：

```swift
    // 映射规则，用来指定属性和json中key两者间的映射的规则
//    enum CodingKeys: String, CodingKey {
//        case name
//        case age
//        case bornIn = "born_in"
//    }
    
    // 映射规则，用来指定属性和json中key两者间的映射的规则
    struct CodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }
        
        // 在decode过程中，这里传入的stringValue就是json中对应的key，然后获取该key的值
        // 在encode过程中，这里传入的stringValue就是生成的json中对应的key，然后设置key的值
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        // 相当于enum中的case
        static let name = CodingKeys(stringValue: "name")!
        static let age = CodingKeys(stringValue: "age")!
        static let bornIn = CodingKeys(stringValue: "born_in")!
    }
```
使用结构体来遵守该协议需要实现该协议的内容，这里因为我们的json中的key是`String`类型，所以用不到`intValue`，因此返回nil即可。重新运行，结果仍然是正确的。不过需要注意的是，如果 **不是** 使用`enum`来遵守`CodingKey`协议的话，例如用`struct`，我们 **必须** 重写`Codable`协议里的编码和解码方法，否者就会报错：

```
cannot automatically synthesize 'Decodable' because 'CodingKeys' is not an enum
cannot automatically synthesize 'Encodable' because 'CodingKeys' is not an enum
```
因此，使用`struct`来遵守`CodingKey`，比用`enum`工程量大。那为什么还要提出这种用法？因为在某些特定的情况下它还是有出场的机会，使用`struct`来指定映射规则更灵活，到后面的一个例子就会讲到使用的场景，这里先明白它的工作方式。

---
### 自定义Encoding
在自定义encode中，我们需要注意的点是对时间格式处理，Optional值处理以及数组处理。
#### 时间格式处理
上一篇文章也提及过关于对时间格式的处理，这里我们有两个方法对时间格式进行自定义encode。
#####方法一：在encode方法中处理

```swift
struct Student: Codable {
    let registerTime: Date
    
    enum CodingKeys: String, CodingKey {
        case registerTime = "register_time"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-dd-yyyy HH:mm:ssZ"
        let stringDate = formatter.string(from: registerTime)
        try container.encode(stringDate, forKey: .registerTime)
    }
}
```

#####方法二: 对泛型函数中对JSONEncoder对象的dateEncodingStrategy属性进行设置

```swift
encoder.dateEncodingStrategy = .custom { (date, encoder) in
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-dd-yyyy HH:mm:ssZ"
        let stringDate = formatter.string(from: date)
        var container = encoder.singleValueContainer()
        try container.encode(stringDate)
    }
```
这里创建的容器是一个`singleValueContainer`，因为这里不像encode方法中那样需要往容器里一直添加值，所以使用一个单值容器就可以了。

```swift
try! encode(of: Student(registerTime: Date()))
//{
//  "register_time" : "Nov-13-2017 20:12:57+0800"
//}
```

#### Optional值处理
如果模型中有属性是可选值，并且为nil，当我进行encode时该值是不会以null的形式写入json中：

```swift
struct Student: Codable {
    var scores: [Int]?
}
try! encode(of: Student())
//{
//
//}
```
因为系统对encode的实现其实不是像我们上面所以写的那样用container调用`encode`方法，而是调用`encodeIfPresent`这个方法，该方法对nil则不进行encode。我们可以强制将friends写入json中：

```swift
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
```


#### 数组处理
有时候，我们想对一个数组类型的属性进行处理后再进行encode，或许你会想，使用一个compute property处理就可以了，但是你只是想将处理后的数组进行encode，原来的数组则不需要，于是你自定义encode来实现，然后！你突然就不想多写一个compute property，只想在encode方法里进行处理，于是我们可以使用container的`nestedUnkeyedContainer(forKey:)`方法创建一个`UnkeyedEncdingContainer`（顾名思义，数组是没有key的）来对于数组进行处理就可以了。

```swift
struct Student: Codable {
    let scores: [Int] = [66, 77, 88]
    
    enum CodingKeys: String, CodingKey {
        case scores
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // 创建一个对数组处理用的容器 (UnkeyedEncdingContainer)
        var unkeyedContainer = container.nestedUnkeyedContainer(forKey: .scores)
        try scores.forEach {
            try unkeyedContainer.encode("\($0)分")
        }
    }
}
try! encode(of: Student())
//{
//    "scores" : [
//    "66分",
//    "77分",
//    "88分"
//    ]
//}
```

---
### 自定义Decoding
对于自定义decode操作上与自定义encode类似，需要说明的点同样也是时间格式处理，数组处理，但Optional值就不用理会了。

#### 时间格式处理
当我们尝试写出一下自定义decode代码时就会抛出一个错误：

```swift
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
        self.init(registerTime: registerTime)
    }
}

let res = """
{
    "register_time": "2017-11-13 22:30:15 +0800"
}
"""
let stu = try! decode(of: res, type: Student.self) ❌
// error: Expected to decode Double but found a string/data instead.
```
因为我们这里时间的格式不是一个浮点数，而是有一定格式化的字符串，因此我们要进行对应的格式匹配，操作也是和自定义encode中的类似，修改`init(from decoder: Decoder`方法:

```swift
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateString = try container.decode(Date.self, forKey: .registerTime)
        let formaater = DateFormatter()
        formaater.dateFormat = "yyyy-MM-dd HH:mm:ss z"
        let registerTime = formaater.date(from: dateString)!
        self.init(registerTime: registerTime)
    }
```
或者我们可以在`JSONDecoder`对象对`dateDncodingStrategy`属性使用custom来修改：

```swift
decoder.dateDecodingStrategy = .custom{ (decoder) -> Date in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter.date(from: dateString)!
    }
```

#### 数组处理
当我们获取这样的数据：

```swift
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
```
gross_score代表该科目的总分数，scores里装的是分数占总分数的比例，我们需要将它们转换成实际的分数再进行初始化。对于数组的处理，我们和自定义encoding时所用的容器都是UnkeyedContainer，通过container的`nestedUnkeyedContainer(forKey: )`方法创建一个`UnkeyedDecodingContainer`，然后从这个unkeyedContainer中不断取出值来decode，并指定其类型。

```swift
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
        // 处理数组时所使用的容器(UnkeyedDecodingContainer)
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
```

---

### 扁平化JSON的编码和解码
现在我们已经熟悉了自定义encoding和decoding的过程了，也知道对数组处理要是container创建的`nestedUnkeyedContainer(forKey: )`创建的unkeyedContainer来处理。现在我们来看一个场景，假设我们有这样一组含嵌套结构的数据：

```swift
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
```
而我们定义的模型的结构却是扁平的：

```swift
struct Student {
    let name: String
    let age: Int
    let bornIn: String
    let grossScore: Int
    let scores: [Float]
}
```
对于这类场景，我们可以使用container的`nestedContainer(keyedBy:, forKey: )`方法创建的KeyedContainer处理，同样是处理内嵌类型的容器，既然有处理像数组这样unkey的内嵌类型的容器，自然也有处理像字典这样有key的内嵌类型的容器，在encoding中是`KeyedEncodingContainer`类型，而在decoding中当然是`KeyedDecodingContainer`类型，因为encoding和decoding中它们是相似的：

```swift
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
```
然后我们验证一下:

```swift
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
```

---
> 现在我们学会了如何自定义encoding和decoding，其中的关键在与掌握`container`的使用，根据不同情况使用不同的container，实际情况千差万别，可是套路总是类似，我们见招拆招就好了。

[参考文献(需要收费观看)](https://boxueio.com/series/what-is-new-in-swift-4)
[本文Demo]()


