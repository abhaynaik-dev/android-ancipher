package com.an.cipher.crypto

import android.util.Log
import com.an.cipher.util.ANCipherUtil.toHex
import com.an.cipher.Config

class Hasher {

    /**
     * A native method that is implemented by the 'cipher' native library,
     * which is packaged with this application.
     */
    external fun stringFromJNI(): String

    external fun hash(algorithm: Int,input: ByteArray, output: ByteArray) : Int

    val TAG = "Hasher"

    companion object {
        // Used to load the 'cipher' library on application startup.
        init {
            System.loadLibrary("an-cipher")
        }
    }

    fun hashMe(algorithm: Config.HashAlgorithm, input: ByteArray): String? {
        val output: ByteArray
        val outputSize: Int

        when(algorithm) {
            Config.HashAlgorithm.MD5 ->{
                outputSize = 16
                output = ByteArray(outputSize)
                val res = hash(Config.HashAlgorithm.MD5.ordinal, input, output)

                if (res != -1){
                    return output.toHex()
                }
            }
            Config.HashAlgorithm.SHA1 ->{
                outputSize = 20
                output = ByteArray(outputSize)
                val res = hash(Config.HashAlgorithm.SHA1.ordinal, input, output)

                if (res != -1){
                    return output.toHex()
                }
            }
            Config.HashAlgorithm.SHA256 ->{
                outputSize = 32
                output = ByteArray(outputSize)
                val res = hash(Config.HashAlgorithm.SHA256.ordinal, input, output)

                if (res != -1){
                    return output.toHex()
                }
            }
        }

        Log.e(TAG, "Something went wrong.")
        return null
    }
}