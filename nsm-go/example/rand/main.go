package main

import (
    "crypto/rand"
    "fmt"
    "math/big"
    "github.com/hf/nsm"
)

func generateBigPrime() (*big.Int, error) {
    sess, err := nsm.OpenDefaultSession()
    defer sess.Close()

    if nil != err {
        return nil, err
    }

    return rand.Prime(sess, 512)
}

func main() {
	prime, err := generateBigPrime()
	if nil != err {
		panic(err)
	}

	fmt.Println(prime)
}
