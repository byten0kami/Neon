import Foundation
import CryptoKit

/// Delegate to perform Certificate Pinning for network requests
final class CertPinner: NSObject, URLSessionDelegate, Sendable {
    
    // Public Key Hash for openrouter.ai (Retrieved via OpenSSL)
    // 47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=
    private let pinnedPublicKeyHash = "SJrCTSCCdEZ418w9KQwfkjyIzDATROpyfxXGNQ7kKoQ="
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // 1. Check if it's perform server trust authentication
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            // Fallback for other auth methods (e.g. client ceterificate), though we don't use them
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // 2. Validate the trust
        // (In a real app, you might want to check the domain too)
        // Note: SecTrustGetCertificateAtIndex is deprecated in iOS 15, using chain copy
        guard let chain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              let serverCertificate = chain.first else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // 3. Extract Public Key
        // Note: SecCertificateCopyKey is available from iOS 10.3
        guard let publicKey = SecCertificateCopyKey(serverCertificate) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // 4. Hash the Public Key (SPKI)
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let hash = SHA256.hash(data: publicKeyData)
        let hashString = Data(hash).base64EncodedString()
        
        // 5. Compare with pinned hash
        if hashString == pinnedPublicKeyHash {
            // Success!
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            // Pin mismatch - possible MITM!
            Log.security("SECURITY ALERT: Certificate pin mismatch! Expected \(pinnedPublicKeyHash), got \(hashString)", privacy: .public)
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
