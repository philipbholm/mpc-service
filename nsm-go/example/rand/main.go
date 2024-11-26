package main

import (
    "fmt"
    "errors"
    "github.com/hf/nsm"
    "github.com/hf/nsm/request"
)

func generateRandomBytes() ([]byte, error) {
    sess, err := nsm.OpenDefaultSession()
    defer sess.Close()

    if nil != err {
        return nil, err
    }

    res, err := sess.Send(&request.GetRandom{})
    if nil != err {
        return nil, err
    }

    if res.Error != "" {
        return nil, errors.New(string(res.Error))
    }

    return res.GetRandom.Random, nil
}

func main() {
	fmt.Println("[nsm-go, example, rand] main starting")
	randomBytes, err := generateRandomBytes()
	if nil != err {
		panic(err)
	}

	fmt.Printf("[nsm-go, example, rand] random bytes generated: %v\n", randomBytes)
	fmt.Println("[nsm-go, example, rand] main finished")
}
