#include <jni.h>
#include <string>
#include "include/openssl/types.h"
#include "include/openssl/evp.h"

extern "C" JNIEXPORT jstring JNICALL
Java_com_an_cipher_hasher_Hasher_stringFromJNI(
        JNIEnv* env,
        jobject /* this */) {
    std::string hello = "Hello from C++";
    return env->NewStringUTF(hello.c_str());
}

extern "C" JNIEXPORT int JNICALL
        Java_com_an_cipher_crypto_Hasher_hash(JNIEnv *env, jobject thiz, jint algorithm,
                                       jbyteArray input, jbyteArray output){

    const int MD5 = 0;
    const int SHA1 = 1;
    const int SHA256 = 2;

    //Input length
    long input_size = env->GetArrayLength(input);
    if(input_size < 0) return -1;

    unsigned char *_input = new unsigned char[input_size];
    env->GetByteArrayRegion(input, 0, input_size, reinterpret_cast<jbyte *>(_input));

    EVP_MD_CTX *mdctx;
    unsigned char digest[EVP_MAX_MD_SIZE];
    unsigned int digest_len;

    if ((mdctx = EVP_MD_CTX_new()) == NULL) {
        return -1;
    }

    switch (algorithm) {
        case MD5:
            if (EVP_DigestInit_ex(mdctx, EVP_md5(), NULL) != 1){
                return -1;
            }
            break;
        case SHA1:
            if (EVP_DigestInit_ex(mdctx, EVP_sha1(), NULL) != 1) {
                return -1;
            }
            break;
        case SHA256:
            if (EVP_DigestInit_ex(mdctx, EVP_sha256(), NULL) != 1) {
                return -1;
            }
            break;
        default:
            return -1;
    }

    if (EVP_DigestUpdate(mdctx, _input, input_size) != 1) {
        return -1;
    }

    if (EVP_DigestFinal_ex(mdctx, digest, &digest_len) != 1) {
        return -1;
    }

    env->SetByteArrayRegion(output, 0, digest_len, reinterpret_cast<const jbyte *>(digest));

    EVP_MD_CTX_free(mdctx);
    delete[] _input;

    return 0;
}