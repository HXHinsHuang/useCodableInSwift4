//: > 处理带有派生关系的model

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


class Ponit2D: Codable {
    var x = 0.0
    var y = 0.0
    
    private enum CodingKeys: String, CodingKey {
        case x
        case y
    }
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(Double.self, forKey: .x)
        let y = try container.decode(Double.self, forKey: .y)
        self.x = x
        self.y = y
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}

class Ponit3D: Ponit2D {
    var z = 0.0
    
    private enum CodingKeys: String, CodingKey {
        case z
        case point2D
    }
    
    init(x: Double, y: Double, z: Double) {
        super.init(x: x, y: y)
        self.z = z
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let z = try container.decode(Double.self, forKey: .z)
        self.z = z
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try super.encode(to: container.superEncoder(forKey: .point2D))
        try container.encode(z, forKey: .z)
    }
}

let p1 = Ponit3D(x: 2.0, y: 2.0, z: 2.0)
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



