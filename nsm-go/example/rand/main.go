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
	fmt.Println("[nsm-go, example, rand] main starting")
	prime, err := generateBigPrime()
	if nil != err {
		panic(err)
	}

	fmt.Printf("[nsm-go, example, rand] prime generated: %v\n", prime)
	fmt.Println("[nsm-go, example, rand] main finished")
}
