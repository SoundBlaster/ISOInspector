import Foundation

extension StructuredPayload {
    struct MatrixDetail: Encodable {
        let a: Double
        let b: Double
        let u: Double
        let c: Double
        let d: Double
        let v: Double
        let x: Double
        let y: Double
        let w: Double
        
        init(matrix: ParsedBoxPayload.TransformationMatrix) {
            self.a = matrix.a
            self.b = matrix.b
            self.u = matrix.u
            self.c = matrix.c
            self.d = matrix.d
            self.v = matrix.v
            self.x = matrix.x
            self.y = matrix.y
            self.w = matrix.w
        }
    }
}
