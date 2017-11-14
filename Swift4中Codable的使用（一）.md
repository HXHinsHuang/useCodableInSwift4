#Swift4中Codable的使用（一）

###前言
自Swift4发布以来已有一段时间了，各种新特性为我们提供更加高效的开发效率，其中在Swift4中使用Codable协议进行模型与json数据之间的映射提供更加便利的方式。在Swift3中，对于从服务器获取到的json数据后，我们要进行一系列繁琐的操作才能将数据完整的转化成模型，举个🌰，我们从服务器获取了一段这样的json数据：

```JSON
{
    "student": {
        "name": "Jone",
        "age": 18,
        "finger": {
            "count": 10
        }
    }
}
```

然后我们用`JSONSerialization`来解析数据，得到的是一个`Any`类型。当我们要读取count时就要采取以下操作：

```Swift
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
```
难过不难过...在日常用Swift编写代码时，就我而言，我喜欢使用SwiftyJSON或则ObjectMapper来进行json转模型，因为相比原生的，使用这些第三方会给我们带来更高的效率。于是在Swift4中，Apple官方就此提供了自己原生的方法，在本篇文章中，我将介绍其基本的用法。

---

###Codable的简单使用
首先，我们来对最简单的json数据进行转模型，现在我们有以下一组json数据：

```Swift
let res = """
{
    "name": "Jone",
    "age": 17
}
"""
let data = res.data(using: .utf8)!
```
然后我们定义一个`Student`结构体作为数据的模型，并遵守`Codable`协议：

```Swift
struct Student: Codable {
    let name: String
    let age: Int
}
```
而关于`Codable`协议的描述我们可以点进去看一下：

```Swift
public typealias Codable = Decodable & Encodable

public protocol Encodable {
    public func encode(to encoder: Encoder) throws
}

public protocol Decodable {
    public init(from decoder: Decoder) throws
}
```
其实就是遵守一个关于解码的协议和一个关于编码的协议，只要遵守这些协议才能进行json与模型之间的编码与解码。
接下来我们就可以进行讲json解码并映射成模型：

```Swift
let decoder = JSONDecoder()
let stu = try! decoder.decode(Student.self, from: data)
print(stu) //Student(name: "Jone", age: 17)
```

然后，我们可以将刚才得到的模型进行编码成json：

```Swift
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted //输出格式好看点
let data = try! encoder.encode(stu)
print(String(data: data, encoding: .utf8)!)
//{
//    "name" : "Jone",
//    "age" : 17
//}
```
就是这么简单~~~

> 这里对`encode`和`decode`使用`try!`是为了减少文章篇幅，正常使用时要对错误进行处理，而常见的错误会在最后讲到。

---

###json中的key和模型中的Key不对应
通常，我们从服务器获取到的json里面的key命名方式和我们是有区别的，后台对一些key的命名方式喜欢用下划线来分割单词，而我们更习惯于使用驼峰命名法，例如这样的情况：

```Swift
let res = """
{
    "name": "Jone",
    "age": 17,
    "born_in": "China"
}
"""
let data = res.data(using: .utf8)!

struct Student: Codable {
    let name: String
    let age: Int
    let bornIn: String
}
```
显然，在映射成模型的过程中会因为json中key与属性名称对不上而报错，而此时我们就可以使用`CodingKey`这个protocol来规确定属性名和json中的key的映射规则，我们现在看看这个协议：

```swift
public protocol CodingKey {
    public var stringValue: String { get }
    public init?(stringValue: String)
    public var intValue: Int? { get }
    public init?(intValue: Int)
}
```
而实现这个功能最简单的方式是使用一个`enum`来遵守这个协议并且会自动实现这个protocol里的方法，使用`case`来指定映射规则：

```Swift
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
```
现在就能很好的工作了

```swift
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
```

---

### 处理JSON中的日期格式，浮点数，base64编码，URL
#### 日期格式
现在我们就上个模型做一些简化，并添加一个新的属性用于表示入学的注册时间：

```swift
struct Student: Codable {
    let registerTime: Date
    
    enum CodingKeys: String, CodingKey {
        case registerTime = "register_time"
    }
}

let stu = Student(registerTime: Date())
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let encodedData = try encoder.encode(stu)
print(String(data: encodedData, encoding: .utf8)!)
//{
//    "register_time" : 532248572.46527803
//}
```
如果我们不想时间以浮点数的形式来出现，我们可以对encoder的dateEncodingStrategy属性进行一些设置：

```swift
encoder.dateEncodingStrategy = .iso8601
// "register_time" : "2017-11-13T06:48:40Z"
```

```swift
let formatter = DateFormatter()
formatter.dateFormat = "MMM-dd-yyyy HH:mm:ss zzz"
encoder.dateEncodingStrategy = .formatted(formatter)
// "register_time" : "Nov-13-2017 14:55:30 GMT+8"
```

#### 浮点数
有时服务器返回一个数据是一些特殊值时，例如返回的学生高度的数值是一个`NaN`，这时我们对decoder的`nonConformingFloatDecodingStrategy`属性进行设置：

```swift
struct Student: Codable {
    let height: Float
}

let res = """
{
    "height": "NaN"
}
"""
let json = res.data(using: .utf8)!
let decoder = JSONDecoder()
decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "+∞", negativeInfinity: "-∞", nan: "NaN")
print((try! decoder.decode(Student.self, from: json)).height) //nan
```

#### base64编码
有时服务器返回一个base64编码的数据时，我们队decoder的`dataDecodingStrategy`属性进行设置：

```swift
struct Student: Codable {
    let blog: Data
}

let res = """
{
    "blog": "aHR0cDovL3d3dy5qaWFuc2h1LmNvbS91c2Vycy8zMjhmNWY5ZDBiNTgvdGltZWxpbmU="
}
"""
let json = res.data(using: .utf8)!
let decoder = JSONDecoder()
decoder.dataDecodingStrategy = .base64
let stu = try! decoder.decode(Student.self, from: json)
print(String(data: stu.blog, encoding: .utf8)!)
// http://www.jianshu.com/users/328f5f9d0b58/timeline
```

#### URL
而对于URL来说，直接映射就可以了

```swift
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
print(try! decoder.decode(Student.self, from: json).blogUrl)
// http://www.jianshu.com/users/328f5f9d0b58/timeline
```

---

### 处理常见的JSON嵌套结构
在此之前，因为在json和模型之间转换的过程是类似的，为了节约时间，先定义两个泛型函数用于encode和decode：

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

#### 用对象封装数组
对于使用一个对象来封装了一数组的json：

```swift
let res = """
{
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
```
对于这类json，我们只需要定义一个类型，该类型包含一个数组，数组类型就是这些内嵌类型

```swift
struct Classes: Codable {
    let students: [Student]
    
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
let c = try! decode(of: res, type: Classes.self)
dump(c)
try! encode(of: c)
```


#### 数组作为JSON根对象
如果服务器返回来的数据如果是一个数组，而数组里面的是一个个对象的字典：

```swift
let res = """
[
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
"""
```
对于这种类型，我们也将它转化了一个数组，数组的类型就是json数组中字典所代表的对象类型

```swift
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

let stu = try! decode(of: res, type: [Student].self)
dump(stu)
try! encode(of: stu)
```

#### 纯数组中的对象带有唯一Key
如果数据是由多个字典组成的数组，字典里又有一组键值对，这种格式可以看成是前两种的组合：

```swift
let res = """
[
    {
        "student": {
            "name": "ZhangSan",
            "age": 17,
            "sex": "male",
            "born_in": "China"
        }
    },
    {
        "student": {
            "name": "LiSi",
            "age": 18,
            "sex": "male",
            "born_in": "Japan"
        }
    },
    {
        "student": {
            "name": "WangWu",
            "age": 16,
            "sex": "male",
            "born_in": "USA"
        }
    }
]
"""
```
解析这种数据，我们像第二种方式一样，对于外围的数组我们只需要在内层的类型中加上一个中括号就可以了，而里面的类型这里我们需要定义成`Dictionary<String, Student>`：

```swift
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
let stu = try! decode(of: res, type: [Dictionary<String, Student>].self)
dump(stu)
try! encode(of: stu)
```


#### 更一般的复杂情况
接下来我们看一种类型，对于这种类型相对之前更复杂，但处理起来也是很简单，日常开发中也是接触最多这种情况：

```swift
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
```
我们按照老套路一个一个来定制模型其实也是很简单的：

```swift
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
```

---

> 至此，我们对`Codable`的基本使用已经熟悉了，只要遵守了`Codable`协议就能享受其带来的编码与解码的便利，若我们需要制定key和属性名的对应规则我们就需要使用`CodingKey`协议，对于日常开发中能满足我们大部分的需求，但也只是大部分，因为还有时候我们需要对数据进行一些处理，这是我们就需要自定义其编码与解码的过程了，下一篇我将介绍更多`Codable`协议的内容。

[参考文献(不过需要收费观看)](https://boxueio.com/series/what-is-new-in-swift-4)
[本文Demo]()

