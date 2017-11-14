# Swift4中Codable的使用（三）

>本篇是Swift4中Codable的使用系列第三篇，继续上一篇我们学习了如何自定义encode和decode，以及container的使用。本篇我们继续来了解更多Codable的知识。

### 处理带有派生关系的模型
在使用Codable进行json与模型之间转换，对于模型的类型使用struct是没什么问题，而类型是class并且是基类的话，同样也是没问题的，但是模型是派生类的话，则需要额外的处理，例如来看个小场景**（这里的encode和decode方法均采用上一篇的泛型函数）** 

```swift
class Ponit2D: Codable {
    var x = 0.0
    var y = 0.0
}

class Ponit3D: Ponit2D {
    var z = 0.0
}

let p1 = Ponit3D()
try! encode(of: p1)
let res = """
{
    "x" : 1,
    "y" : 1,
    "z" : 1
}
"""
let p2 = try! decode(of: res, type: Ponit3D.self)
dump(p2)
```
接着我们来看看打印结果：

```swift
{
  "x" : 0,
  "y" : 0
}
▿ __lldb_expr_221.Ponit3D #0
  ▿ super: __lldb_expr_221.Ponit2D
    - x: 1.0
    - y: 1.0
  - z: 0.0
```
咦？z去哪了？？？
实际上，默认Codable中的默认encode和decode方法并不能正确处理派生类对象。因此，当我们的模型是派生类时，要自己编写对应的encode和decode的方法。
首先我们先来实现encode：

```swift
class Ponit2D: Codable {
    var x = 0.0
    var y = 0.0
    // 标记为private
    private enum CodingKeys: String, CodingKey {
        case x
        case y
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}

class Ponit3D: Ponit2D {
    var z = 0.0
    // 标记为private
    private enum CodingKeys: String, CodingKey {
        case z
    }
    
    override func encode(to encoder: Encoder) throws {
        //调用父类的encode方法将父类的属性encode
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(z, forKey: .z)
    }
}

let p1 = Ponit3D()
try! encode(of: p1)
//{
//  "x" : 0,
//  "y" : 0,
//  "z" : 0
//}

```
这里需要说明的是，`CodingKeys`需要用private标记，防止被派生类继承。其次，在encode方法中，我们要调用`super.encode`，否则父类的属性将没有进行编码，例如本例中若没有调用`super.encode`，encode`Ponit3D`对象时则会只有z属性被编码，而x和y属性则不会。而调用`super.encode`时，我们直接把encoder传递给基类调用，因此基类和派生类共享一个container。当然你也可以为了区分他们单独创建一个container传递给父类。

```swift
class Ponit3D: Ponit2D {
    var z = 0.0
    
    private enum CodingKeys: String, CodingKey {
        case z
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // 创建一个提供给父类encode的容器来区分父类属性和派生类属性
        try super.encode(to: container.superEncoder())
        try container.encode(z, forKey: .z)
    }
}

let p1 = Ponit3D()
try! encode(of: p1)
//{
//    "super" : {
//        "x" : 0,
//        "y" : 0
//    },
//    "z" : 0
//}
```
如果你不喜欢默认的super来做父类属性的key，也可以单独命名，`container.superEncoder`有一个`forKey`参数，通过`CodingKeys`的case来命名：

```swift
class Ponit3D: Ponit2D {
    var z = 0.0
    
    private enum CodingKeys: String, CodingKey {
        case z
        case point2D //用于父类属性容器的key名
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // 创建一个提供给父类encode的容器来区分父类属性和派生类属性，并将key设为point2D
        try super.encode(to: container.superEncoder(forKey: .Point2D))
        try container.encode(z, forKey: .z)
    }
}

let p1 = Ponit3D()
try! encode(of: p1)
//{
//    "point2D" : {
//        "x" : 0,
//        "y" : 0
//    },
//    "z" : 0
//}
```

派生类encode的方法已经重写好了，接下来我们还要重写decode方法。其实decode方法和encode方法非常类似，通过`init(from decoder: Decoder) throws`方法调用super的方法，传递一个共享容器或则一个单独的容器就可以实现了，这里便不再演示了，有需要的可以查看本文的demo。

---

### model兼容多个版本的API
假如有一个场景，一个app版本迭代，服务器对新版本的数据格式做了修改，例如有两个版本的时间格式：

```json
// version1
{
    "time": "Nov-14-2017 17:25:55 GMT+8"
}

// version2
{
    "time": "2017-11-14 17:27:35 +0800"
}
```
我们要根据版本的不同，上传给服务器的时间格式也不同，这里以encode为例，我们在`Encoder`的protocol中可以找到一个属性：

```swift
public protocol Decoder {
    /// The path of coding keys taken to get to this point in encoding.
    public var codingPath: [CodingKey] { get }
}
```
我们可以使用这个`userInfo`属性在存储版本的信息，在encode的时候再读取版本信息来进行格式处理。而`userInfo`中的key是一个`CodingUserInfoKey`类型，`CodingUserInfoKey`和Dictionary中key的用法很类似。现在我们就有思路了，首先我们创建一个版本控制器来规定版本的信息：

```swift
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
```
接着我们修改调用的encode泛型函数，添加一个`VersionController`类型的参数用于传递版本信息：

```swift
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
```
然后我们来编写我们的模型：

```swift
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
```
最后我们来验证我们的代码：

```swift
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
```
现在我们已经通过`Encoder`中的`userInfo`属性来实现版本控制，对于decode只需在`init`方法对应实现即可。

---

### 处理key个数不确定的json
有一种总很特殊的情况就是我们得到这样一个json数据：

```swift
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
```
json中key的个数不确定，并且以学生的学号作为key，我们不能按照json的数据创建一个个的模型，对于这种情况我们又该如何处理？
其实大致思路是这样的：我们同样创建一个包含id属性和name属性的Student模型，接着创建一个StudentList模型,StudentList中有一`[Student]`类型的属性用于存放Student模型。此时，我们知道系统默认Codable中的方法不能满足我们，我们需要自定义，而使用`enum`的Codingkeys来指定json中的key和属性的映射规则显然也不能满足我们，我们需要一个更灵活的Codingkeys，因此，我们可以使用上篇所提到的用struct类型实现Codingkeys，如果大家忘了话可以先倒回去看一遍其工作方式，这里就不再重复提了。

```swift
struct Student: Codable {
    let id: Int
    let name: String
}

struct StudentList: Codable {
    var students: [Student] = []
    
    init(students: Student ... ) {
        self.students = students
    }
    
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
}
```
现在我们有一个比较灵活的Codingkeys，我们接下来要做在decode中遍历container中所有key，因为key的类型是Codingkeys类型，所以我们可以通过key的`stringValue`属性来读取id，然后创建一个内嵌的keyedContainer来读取key对应的字典，然后再读取name的值，这就是大致的思路：

```swift
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
```
测试一下代码验证时都正确：

```swift
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
```
对于encode的方法，其实就是对着decode的反向来进行，我们只需要方向思考一下就很容易知道如何操作了：

```swift
    func encode(to encoder: Encoder) throws {
        // 指定映射规则
        var container = encoder.container(keyedBy: Codingkeys.self)
        try students.forEach { stu in
            // 用Student的id作为key，然后该key对应的值是一个字典，所以我们创建一个处理字典的子容器
            var keyedContainer = container.nestedContainer(keyedBy: Codingkeys.self, forKey: Codingkeys(stringValue: "\(stu.id)")!)
            try keyedContainer.encode(stu.name, forKey: .name)
        }
    }
```
测试一下代码验证时都正确：

```swift
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

```

---

### Coable中错误的类型(EncodingError & DecodingError)
在本系列的最后，我们来了解一下在Coable中会发生哪些错误。在编码和解码是会出现的错误类型是`DecodingError`和`EncodingError`。我们先来看看DecodingError：

```swift
public enum DecodingError : Error {
    // 在出现错误时通过context来获取错误的详细信息
    public struct Context {
        public let codingPath: [CodingKey]
        // 错误信息中的具体错误描述
        public let debugDescription: String
        public let underlyingError: Error?
        public init(codingPath: [CodingKey], debugDescription: String, underlyingError: Error? = default)
    }
    /// 下面是错误的类型
    // JSON值和model类型不匹配
    case typeMismatch(Any.Type, DecodingError.Context)
    // 不存在的值
    case valueNotFound(Any.Type, DecodingError.Context)
    // 不存在的key
    case keyNotFound(CodingKey, DecodingError.Context)
    // 不合法的JSON格式
    case dataCorrupted(DecodingError.Context)
}
```
相对`DecodingError`，`EncodingError`的错误类型只有一个：

```swift
public enum EncodingError : Error {
    // 在出现错误时通过context来获取错误的详细信息
    public struct Context {
        public let codingPath: [CodingKey]
        // 错误信息中的具体错误描述
        public let debugDescription: String
        public let underlyingError: Error?
        public init(codingPath: [CodingKey], debugDescription: String, underlyingError: Error? = default)
    }
    // 属性的值与类型不合符
    case invalidValue(Any, EncodingError.Context)
}
```

---

>至此，本系列的教学就到此为止了，掌握了`Codable`的使用会为我们带来许多的便利，可以解决大多数情况的json数据。

[参考文献（需要收费观看）](https://boxueio.com/series/what-is-new-in-swift-4)
[本文Demo]()


