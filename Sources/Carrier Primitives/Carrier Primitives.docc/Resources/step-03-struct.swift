import Carrier_Primitives

struct User {
    var name: String
    var email: String
}

extension User {
    struct ID {
        var _storage: UInt64

        init(_ underlying: consuming UInt64) {
            self._storage = underlying
        }
    }
}
