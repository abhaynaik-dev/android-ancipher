package com.an.cipher

import com.an.cipher.crypto.Hasher

object ANCipher {

    fun hash(algorithm: Config.HashAlgorithm, input: ByteArray): String? {
        return Hasher().hashMe(algorithm, input)
    }

}