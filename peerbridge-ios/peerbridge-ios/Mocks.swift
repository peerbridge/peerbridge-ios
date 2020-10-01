
import Foundation
import SwiftyRSA

#if DEBUG
extension PEMString {
    static let alicePublicKeyString = """
    -----BEGIN RSA PUBLIC KEY-----
    MIIBCgKCAQEAtHcZLsdGhG186dDmxlgdtNRn8NlLl9rFdXnbiAriuYtgRv9VMxo4
    zKlj61Vj7G7sKRc9u7lM4yUEY8mUX0GRUf/XP4imBfNvqhHq6YXCajB5thsdU/48
    DS2ZKKHOAlhbhD36wAamJsw01oHe+13ST2BGJFRGEmqZU9TeBNzCT17dzjSZnHxo
    mYBwtBFJ3pZrfnCQziGz9lTKAPTWMSi21Mrtu0olr77Uso8qLbX8EMKxy6KXRfNa
    JP4UbJgHPE39Oi1AaCXopbpHe664gIk3htjQJK4eK5fMPBxNRQvGDiyUWE5Cg+90
    amfOGyuwFqJgRL+d0mg/pQqCVUFX9y5QdwIDAQAB
    -----END RSA PUBLIC KEY-----
    """
    
    static let alicePrivateKeyString = """
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAKCAQEAtHcZLsdGhG186dDmxlgdtNRn8NlLl9rFdXnbiAriuYtgRv9V
    Mxo4zKlj61Vj7G7sKRc9u7lM4yUEY8mUX0GRUf/XP4imBfNvqhHq6YXCajB5thsd
    U/48DS2ZKKHOAlhbhD36wAamJsw01oHe+13ST2BGJFRGEmqZU9TeBNzCT17dzjSZ
    nHxomYBwtBFJ3pZrfnCQziGz9lTKAPTWMSi21Mrtu0olr77Uso8qLbX8EMKxy6KX
    RfNaJP4UbJgHPE39Oi1AaCXopbpHe664gIk3htjQJK4eK5fMPBxNRQvGDiyUWE5C
    g+90amfOGyuwFqJgRL+d0mg/pQqCVUFX9y5QdwIDAQABAoIBACCELyDrHg0hbzbw
    AYzudpfNB9dxR7oaXKbQqJooH/b/on7YZeEZ0e8qfEr8bU8+I0Y6HlDzT+PDmTlj
    qlzJgyYru3yCoiuDU/ToWpPuGnwotN13oD6wmeBj/WtBUE3C3uaChmpQKGLoO4MF
    DojrPEg6GBlWp/OMioj8224z2r0TFF6QFbAcRQvC31FlxmLVRniVOmaZuy79uHwi
    CaINH08u37fAak5HG1UFAhFxHpys5poOcu9b+abHPQhiKqPolB/rzJzyMMsUmCoL
    kd55Hn0izxmyelJ0tutanFz9ouoxlZiuzwv7jEIsSFRqaKKoTWq4EaNSEHRCSU9v
    cz/j9CECgYEA8L1L0hupH0O6wqJNUO20HJmmrjQV5btGbrWY1UzpssMWwzVGah6A
    jcDqBAXb5x297EUuK4LYuk14kABgwbNBDXxQTd8tBj+dnfNuVLiC5lvFJjKucxmF
    dyvMU43CWT7v6TQwTLYbeoZn1p5CYqiqRPBScQXWpjI7hSJt7BKenGECgYEAv+et
    H49wJ4wUol4YqA2bB+htKcSLpzE6Aib7JTwpOGsEvUdejo6UH/CsSlx2pggXNC1i
    X4R5ddJoWhSVd7inTZ+1dTOiympq8N1spmEUrjBIwx1mIpF9q1A2I83a352tmbzW
    wqf+384+afYPmQunpzyXI2zZqpFvqebgrKFy29cCgYEAkjtaEBGPRJd+nXW7IzqQ
    moLW1aB74KVGXj9ey8pBdr28WO1GjXVjvzd8rt7kOdo+IIPRTMrZXSlr34TrQR3i
    mQ93NCYpkk8YLfbNgRbnJIiAE/jbML1C7iWjoulMMaviTTTPVfmUbXOxJZPSXV14
    uBGG8nKKdT+0GeXVAX457GECgYAFfMh0iJN6bgUBB5PI6mqudTT55sbfhwbTnO29
    iNTc6iJ+jxXjGayepTEoBzDVWpHfShTwCke22MdnHAOSItOV4qU7rrhO9XANZyd+
    MnR27qaF/cc34dUoGukRaQeDMW0PYlj5w/gDyk/6k7CqfazTmWXw+2HWAMaioxl1
    lkBEjQKBgQDmqQ+2sbcjrDBlouNYKa7rIffLJvni5W++eq2TjudpxSxxEBOz2cb/
    I2rXbqDbs4srRZv00KqJubZiYbqrpPAdqLwaHqKRikYMTGjFIrZIs4Qen/1E2oYm
    iSg0iaeZZx3iD5lL1evrwCjlOPUHufyLmjuu4gj/73QWmtka17y7Vg==
    -----END RSA PRIVATE KEY-----
    """
    
    static let bobPublicKeyString = """
    -----BEGIN RSA PUBLIC KEY-----
    MIIBCgKCAQEAohtqmxU39F7/qaLq5EPCQij1iqPO0L5FLznYYGLjVjPObvD8gKXG
    5mhF3elP7U1ooGtoqFf9/Y9h07gIPryNT87bHrIpjI7dlUxY0rtEhImTIuGvdaFQ
    K7RYLwDFsXcTmb01CIchmgSN4Y8wvtKMl61RrhbYug7jiRilSNqckx9XnS5xwTtn
    XrO0yCs8aQAH8g2wsvs/bU2h/LPHzi8YmgGXlhAM61cVnoewtk8fn79qEy2QcqKa
    ghrJt7k9/iQF39n9GVdjRDi13bREWx2UhtwL9MOH5tKakcvhzxWORF7Fh4Wv6XfP
    mUOOCp6j6sxWWgzU/acLBRNyP2U8vvzg/QIDAQAB
    -----END RSA PUBLIC KEY-----
    """
    
    static let bobPrivateKeyString = """
    -----BEGIN RSA PRIVATE KEY-----
    MIIEowIBAAKCAQEAohtqmxU39F7/qaLq5EPCQij1iqPO0L5FLznYYGLjVjPObvD8
    gKXG5mhF3elP7U1ooGtoqFf9/Y9h07gIPryNT87bHrIpjI7dlUxY0rtEhImTIuGv
    daFQK7RYLwDFsXcTmb01CIchmgSN4Y8wvtKMl61RrhbYug7jiRilSNqckx9XnS5x
    wTtnXrO0yCs8aQAH8g2wsvs/bU2h/LPHzi8YmgGXlhAM61cVnoewtk8fn79qEy2Q
    cqKaghrJt7k9/iQF39n9GVdjRDi13bREWx2UhtwL9MOH5tKakcvhzxWORF7Fh4Wv
    6XfPmUOOCp6j6sxWWgzU/acLBRNyP2U8vvzg/QIDAQABAoIBAC9uVS1mMnaKe0S/
    ufmrB8JC6ME1d7RlD6onQzPEi170DpEwarkbiExvMw4gj3XQAe56Lueew1623rlL
    bgIpOjGhRUTAfV62iIgADDcwevZKqKX6odOJrQL0pB6wm6d2v2Hq1gMWQtMlRPw7
    4NfclC1nFXCaF7Ss2Y+KCgZ8jHaRLBy8R184HpiOPDEDmtRDpTzsiBqV3F6oVd0l
    OwVJTnPxGedmx0/SN7zXroSjW41BaAZV2cfGbyLmAoEbaKSbUUDZjaXuK0/DNOtY
    Olsoayqe0PtUGVvIAQKqFIt+aHlq8/4dET/v9cBQkf5cUgvo6uIkFtnE60wBoKkX
    uTy7yHMCgYEA2htNYdFWgolUhacHtxl0t7tJOEOVb4K832UJwI8T2Pe/bZNyxxIS
    uozgkEdhEozHxQKp4Zq8sH7n3k52W7LzRE5ce/GWxSSxUqaLYrJ4XD2SOElVna62
    6gjYbYiIDBDexozG8fNC2IbH6w1hW7TpqGiXSlrIPbrDY1XRwc7tWUsCgYEAvkVu
    HTiBw2AH76bb2D61r/fxlnBEFUO3bCmTZa/RuZKhkWHQOnWiAEkf7DWGY7yLV8Ty
    P8sV5zfDl5beBndhdcvLPLApiPUB991Nlex0dcHt4aitl/uE9A8TAv10FU+rlFlk
    SCGelznqaEFUKL9NIaL/2EU/TCjq9CRYkTvBydcCgYBLGyvCi3vm57ObcrFNdA6l
    VnEYVu2WwMaZhwmcraiABpB9A1F7C9Y3N1v9UxcydBg213v4nHhtrsXZ39sSKMVs
    uC9Q3xi0OrZ1Z7SIAD1CRlGb4GUDL679WJ5u2Z0/ym9sn/3CQ6q5NXCSmMD1+46a
    16mBiVF7MF0oT90ziDZjkQKBgQCbuygNMprC1m6ob+GwdGMwy7cocmrHHM2b8ct6
    hxUY1jL3Ux+jOXSG11MReh2stD04cTH1lLswrCuifxDqKfvS9iI6YdUdC6u4u6Es
    /IO1fiy9bdnncy22tD/TSq8gYj0FBsVVZG7xR63b9txzHWB8D3VoBgVwyGzFtpnn
    BQnvsQKBgAK9UEK76Ng53wPH/BFYgpz1TcvMx00KL9LZ6L+laPJgf9oUJed2o6IK
    1H7L8CHFAFYf4VV1TSz4hElAITM39A+MEPDTT6vci/ozX6r/9ks8feGMLh3UniAU
    A10qVpjJIed1mAVvaJRmuKILHWSyP6sZTkeNsOjn+77OfKReqZHR
    -----END RSA PRIVATE KEY-----
    """
}

extension PublicKey {
    static let alicePublicKey = try! PublicKey(pemEncoded: PEMString.alicePublicKeyString)
    static let bobPublicKey = try! PublicKey(pemEncoded: PEMString.bobPublicKeyString)
}

extension PrivateKey {
    static let alicePrivateKey = try! PrivateKey(pemEncoded: PEMString.alicePrivateKeyString)
    static let bobPrivateKey = try! PrivateKey(pemEncoded: PEMString.bobPrivateKeyString)
}

extension RSAKeyPair {
    static let aliceKeyPair = try! RSAKeyPair(
        privateKey: .alicePrivateKey, publicKey: .alicePublicKey
    )
    static let bobKeyPair = try! RSAKeyPair(
        privateKey: .bobPrivateKey, publicKey: .bobPublicKey
    )
}

extension AuthenticationEnvironment {
    static let alice = AuthenticationEnvironment(keyPair: .aliceKeyPair)
    static let bob = AuthenticationEnvironment(keyPair: .bobKeyPair)
}

extension Transaction {
    static let example1 = Transaction(
        index: UUID().uuidString,
        sender: .alicePublicKeyString,
        receiver: .bobPublicKeyString,
        data: "garbage".data(using: .utf8)!,
        timestamp: Date(timeIntervalSinceNow: -10000)
    )
    
    static let example2 = Transaction(
        index: UUID().uuidString,
        sender: .bobPublicKeyString,
        receiver: .alicePublicKeyString,
        data: "garbage".data(using: .utf8)!,
        timestamp: Date(timeIntervalSinceNow: -5000)
    )
}

extension Chat {
    static let exampleForAlice = Chat(partner: .bobPublicKeyString, lastTransaction: .example2)
    static let exampleForBob = Chat(partner: .alicePublicKeyString, lastTransaction: .example2)
}

extension Sequence where Element == Chat {
    static var example: [Element] {
        (0...10).map { (i: Int) -> Chat in
            return Chat(
                partner: "Partner \(i)",
                lastTransaction: Transaction(
                    index: UUID().uuidString,
                    sender: .alicePublicKeyString,
                    receiver: .bobPublicKeyString,
                    data: "garbage".data(using: .utf8)!,
                    timestamp: Date().addingTimeInterval(-10000)
                )
            )
        }
    }
}

class MockedTransactionRepository: TransactionRepository {
    init() throws {
        try super.init(location: .inMemory)
    }
    
    override func getLastTimestamp() throws -> Date {
        return Transaction.example2.timestamp
    }
    
    override func getTransactions(withPartner partnerPublicKey: PEMString) throws -> [Transaction] {
        if partnerPublicKey == .bobPublicKeyString || partnerPublicKey == .alicePublicKeyString {
            return [.example1, .example2]
        }
        return []
    }
    
    override func getChats(auth: AuthenticationEnvironment) throws -> [Chat] {
        return try getChats(ownPublicKey: auth.keyPair.publicKeyString)
    }
    
    override func getChats(ownPublicKey: PEMString) throws -> [Chat] {
        if ownPublicKey == .alicePublicKeyString {
            return [.exampleForAlice]
        }
        if ownPublicKey == .bobPublicKeyString {
            return [.exampleForBob]
        }
        return []
    }
}

extension TransactionRepository {
    static let mock = try! MockedTransactionRepository()
}

extension PersistenceEnvironment {
    static let debug = PersistenceEnvironment(transactions: .mock)
}

#endif
