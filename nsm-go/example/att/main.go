package main

import (
	"encoding/base64"
	"errors"
	"fmt"
	"github.com/hf/nsm"
	"github.com/hf/nsm/request"
	"time"
)

func attest(nonce, userData, publicKey []byte) ([]byte, error) {
	sess, err := nsm.OpenDefaultSession()
	defer sess.Close()

	if nil != err {
		return nil, err
	}

	res, err := sess.Send(&request.Attestation{
		Nonce:     nonce,
		UserData:  userData,
		PublicKey: publicKey,
	})
	if nil != err {
		return nil, err
	}

	if "" != res.Error {
		return nil, errors.New(string(res.Error))
	}

	if nil == res.Attestation || nil == res.Attestation.Document {
		return nil, errors.New("NSM device did not return an attestation")
	}

	return res.Attestation.Document, nil
}

func main() {
	att, err :=
		attest(
			[]byte{87, 192, 187, 225, 168, 217, 162, 75, 28, 60, 74, 154, 131, 159, 2, 26, 229, 247, 51, 209},
			[]byte{253, 112, 136, 225, 253, 189, 195, 253, 6, 26, 243, 92, 227, 52, 47, 167, 72, 182, 203, 133, 217, 189, 35, 130, 254, 62, 149, 99, 210, 101, 161, 78},
			[]byte{48, 129, 155, 48, 16, 6, 7, 42, 134, 72, 206, 61, 2, 1, 6, 5, 43, 129, 4, 0, 35, 3, 129, 134, 0, 4, 0, 198, 133, 142, 6, 183, 4, 4, 233, 205, 158, 62, 203, 102, 35, 149, 180, 66, 156, 100, 129, 57, 5, 63, 181, 33, 248, 40, 175, 96, 107, 77, 61, 186, 161, 75, 94, 119, 239, 231, 89, 40, 254, 29, 193, 39, 162, 255, 168, 222, 51, 72, 179, 193, 133, 106, 66, 155, 249, 126, 126, 49, 194, 229, 189, 102, 1, 24, 57, 41, 106, 120, 154, 59, 192, 4, 92, 138, 95, 180, 44, 125, 27, 217, 152, 245, 68, 73, 87, 155, 68, 104, 23, 175, 189, 23, 39, 62, 102, 44, 151, 238, 114, 153, 94, 244, 38, 64, 197, 80, 185, 1, 63, 173, 7, 97, 53, 60, 112, 134, 162, 114, 194, 64, 136, 190, 148, 118, 159, 209, 102, 80},
		)

	fmt.Printf("attestation %v %v\n", base64.StdEncoding.EncodeToString(att), err)

	time.Sleep(5 * time.Minute)
}
