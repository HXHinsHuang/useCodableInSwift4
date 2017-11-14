//: > Coable中错误的类型(EncodingError & DecodingError)

import Foundation

func encode<T>(of model: T) throws where T: Codable {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    do {
        let encodedData = try encoder.encode(model)
        print(String(data: encodedData, encoding: .utf8)!)
    } catch EncodingError.invalidValue(let model, let context) {
        dump(model)
        print(context)
    }
}

func decode<T>(of jsonString: String, type: T.Type) throws -> T where T: Codable {
    let data = jsonString.data(using: .utf8)!
    let decoder = JSONDecoder()
    do {
        let model = try decoder.decode(T.self, from: data)
        return model
    } catch DecodingError.typeMismatch(let type, let context) {
        print(type)
        print(context)
    } catch DecodingError.dataCorrupted(let context) {
        print(context)
    } catch DecodingError.valueNotFound(let type, let context) {
        print(type)
        print(context)
    } catch DecodingError.keyNotFound(let key, let context) {
        print(key)
        print(context)
    }
    fatalError()
}



