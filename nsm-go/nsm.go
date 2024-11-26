// Package nsm implements the Nitro Security Module interface.
package nsm

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"sync"
	"syscall"
	"unsafe"

	"github.com/fxamacker/cbor/v2"
	"github.com/hf/nsm/ioc"
	"github.com/hf/nsm/request"
	"github.com/hf/nsm/response"
)

const (
	maxRequestSize  = 0x1000
	maxResponseSize = 0x3000
	ioctlMagic      = 0x0A
)

// FileDescriptor is a generic file descriptor interface that can be closed.
// os.File conforms to this interface.
type FileDescriptor interface {
	// Provide the uintptr for the file descriptor.
	Fd() uintptr

	// Close the file descriptor.
	Close() error
}

// Options for the opening of the NSM session.
type Options struct {
	// A function that opens the NSM device file `/dev/nsm`.
	Open func() (FileDescriptor, error)

	// A function that implements the syscall.Syscall interface and is able to
	// work with the file descriptor returned from `Open` as the `a1` argument.
	Syscall func(trap, a1, a2, a3 uintptr) (r1, r2 uintptr, err syscall.Errno)
}

// DefaultOptions can be used to open the default NSM session on `/dev/nsm`.
var DefaultOptions = Options{
	Open: func() (FileDescriptor, error) {
		return os.Open("/dev/nsm")
	},
	Syscall: syscall.Syscall,
}

// ErrorIoctlFailed is an error returned when the underlying ioctl syscall has
// failed.
type ErrorIoctlFailed struct {
	// Errno is the errno returned by the syscall.
	Errno syscall.Errno
}

// Error returns the formatted string.
func (err *ErrorIoctlFailed) Error() string {
	return fmt.Sprintf("ioctl failed on device with errno %v", err.Errno)
}

// ErrorGetRandomFailed is an error returned when the GetRandom request as part
// of a `Read` has failed with an error code, is invalid or did not return any
// random bytes.
type ErrorGetRandomFailed struct {
	ErrorCode response.ErrorCode
}

// Error returns the formatted string.
func (err *ErrorGetRandomFailed) Error() string {
	if "" != err.ErrorCode {
		return fmt.Sprintf("GetRandom failed with error code %v", err.ErrorCode)
	}

	return "GetRandom response did not include random bytes"
}

var (
	// ErrSessionClosed is returned when the session is in a closed state.
	ErrSessionClosed error = errors.New("Session is closed")
)

// A Session is used to interact with the NSM.
type Session struct {
	fd      FileDescriptor
	options Options
	reqpool *sync.Pool
	respool *sync.Pool
}

type ioctlMessage struct {
	Request  syscall.Iovec
	Response syscall.Iovec
}

func send(options Options, fd uintptr, req []byte, res []byte) ([]byte, error) {
	fmt.Printf("[nsm, send] input req: %v\n", req)
	fmt.Printf("[nsm, send] input req len: %d\n", len(req))
	// fmt.Printf("[nsm, send] input res: %v\n", res)
	fmt.Printf("[nsm, send] input res len: %d\n", len(res))
	// request: [105 71 101 116 82 97 110 100 111 109]
	// fmt.Printf("[nsm, send] request: %v\n", req)

	// request len: 10
	// fmt.Printf("[nsm, send] request len: %d\n", len(req))
	
	// fmt.Printf("[nsm, send] response: %v\n", res[:20])
	
	// Response contains n random bytes and then zeros until 12288 (maxResponseSize)
	// fmt.Printf("[nsm, send] response len: %d\n", len(res))
	iovecReq := syscall.Iovec{
		Base: &req[0],
	}
	iovecReq.SetLen(len(req))

	iovecRes := syscall.Iovec{
		Base: &res[0],
	}
	iovecRes.SetLen(len(res))

	msg := ioctlMessage{
		Request:  iovecReq,
		Response: iovecRes,
	}
	// msg: {{0x4000078000 10} {0x400007a000 12288}}
	fmt.Printf("[nsm, send] msg: %v\n", msg)

	// msg size: 32
	// fmt.Printf("[nsm, send] msg size: %d\n", unsafe.Sizeof(msg))

	_, _, err := options.Syscall(
		syscall.SYS_IOCTL,
		fd,
		uintptr(ioc.Command(ioc.READ|ioc.WRITE, ioctlMagic, 0, uint(unsafe.Sizeof(msg)))),
		uintptr(unsafe.Pointer(&msg)),
	)

	if 0 != err {
		return nil, &ErrorIoctlFailed{
			Errno: err,
		}
	}

	fmt.Printf("[nsm, send] msg.Response.Len: %d\n", msg.Response.Len)
	fmt.Printf("[nsm, send] returning result: %v\n", res[:msg.Response.Len])

	return res[:msg.Response.Len], nil
}

// OpenSession opens a new session with the provided options.
func OpenSession(opts Options) (*Session, error) {
	session := &Session{
		options: opts,
	}

	fd, err := opts.Open()
	if nil != err {
		return session, err
	}

	session.fd = fd
	session.reqpool = &sync.Pool{
		New: func() interface{} {
			return bytes.NewBuffer(make([]byte, 0, maxRequestSize))
		},
	}
	session.respool = &sync.Pool{
		New: func() interface{} {
			return make([]byte, maxResponseSize)
		},
	}

	return session, nil
}

// OpenDefaultSession opens a new session with the default options.
func OpenDefaultSession() (*Session, error) {
	return OpenSession(DefaultOptions)
}

// Close this session. It is not thread safe to Close while other threads are
// Read-ing or Send-ing.
func (sess *Session) Close() error {
	if nil == sess.fd {
		return nil
	}

	err := sess.fd.Close()
	sess.fd = nil
	sess.reqpool = nil
	sess.respool = nil

	return err
}

// Send an NSM request to the device and await its response. It safe to call
// this from multiple threads that are Read-ing or Send-ing, but not Close-ing.
// Each Send and Read call reserves at most 16KB of memory, so having multiple
// parallel sends or reads might lead to increased memory usage.
func (sess *Session) Send(req request.Request) (response.Response, error) {
	reqb := sess.reqpool.Get().(*bytes.Buffer)
	defer sess.reqpool.Put(reqb)

	reqb.Reset()
	encoder := cbor.NewEncoder(reqb)
	err := encoder.Encode(req.Encoded())
	if nil != err {
		return response.Response{}, err
	}

	resb := sess.respool.Get().([]byte)
	defer sess.respool.Put(resb)

	return sess.sendMarshaled(reqb, resb)
}

func (sess *Session) sendMarshaled(reqb *bytes.Buffer, resb []byte) (response.Response, error) {
	fmt.Printf("[nsm, sendMarshaled] input reqb: %v\n", reqb.Bytes())
	fmt.Printf("[nsm, sendMarshaled] input reqb len: %d\n", reqb.Len())
	res := response.Response{}

	if nil == sess.fd {
		return res, errors.New("Session is closed")
	}
	// [nsm, sendMarshaled] reqb: [105 71 101 116 82 97 110 100 111 109]
	// fmt.Printf("[nsm, sendMarshaled] reqb: %v\n", reqb.Bytes())

	// resb is 12288 zeros before send
	// fmt.Printf("[nsm, sendMarshaled] before send resb: %v\n", resb)
	// fmt.Printf("[nsm, sendMarshaled] before send resb len: %d\n", len(resb))
	resb, err := send(sess.options, sess.fd.Fd(), reqb.Bytes(), resb)
	// fmt.Printf("[nsm, sendMarshaled] after send resb: %v\n", resb)
	
	// Always generates 278 random bytes, the same as output from send
	// fmt.Printf("[nsm, sendMarshaled] after send resb len: %d\n", len(resb))
	if nil != err {
		return res, err
	}

	err = cbor.Unmarshal(resb, &res)
	if nil != err {
		return res, err
	}

	if res.GetRandom != nil {
		fmt.Printf("[nsm, sendMarshaled] GetRandom response: %v\n", res.GetRandom.Random)
		fmt.Printf("[nsm, sendMarshaled] GetRandom response len: %d\n", len(res.GetRandom.Random))
	} else {
		fmt.Println("[nsm, sendMarshaled] GetRandom response is nil")
	}

	fmt.Printf("[nsm, sendMarshaled] returning res: %v\n", res)

	return res, nil
}

// Read entropy from the NSM device. It is safe to call this from multiple
// threads that are Read-ing or Send-ing, but not Close-ing.  This method will
// always attempt to fill the whole slice with entropy thus blocking until that
// occurs. If reading fails, it is probably an irrecoverable error.  Each Send
// and Read call reserves at most 16KB of memory, so having multiple parallel
// sends or reads might lead to increased memory usage.
func (sess *Session) Read(into []byte) (int, error) {
	// [nsm, Read] request size: 64
	// fmt.Printf("[nsm, Read] request size: %d\n", len(into))
	reqb := sess.reqpool.Get().(*bytes.Buffer)
	// [nsm, Read] reqb: iGetRandom
	// fmt.Printf("[nsm, Read] reqb: %v\n", reqb.String())
	defer sess.reqpool.Put(reqb)

	getRandom := request.GetRandom{}
	// [nsm, Read] getRandom.Encoded(): GetRandom
	// fmt.Printf("[nsm, Read] getRandom.Encoded(): %v\n", getRandom.Encoded())

	reqb.Reset()
	encoder := cbor.NewEncoder(reqb)
	err := encoder.Encode(getRandom.Encoded())
	// [nsm, Read] reqb after encoding: [105 71 101 116 82 97 110 100 111 109]
	// fmt.Printf("[nsm, Read] reqb after encoding: %v\n", reqb.Bytes())
	if nil != err {
		return 0, err
	}

	resb := sess.respool.Get().([]byte)
	defer sess.respool.Put(resb)

	j := 0
	for i := 0; i < len(into); i += 0 {
		fmt.Printf("[nsm, Read] loop %d calling sendMarshaled\n", j)
		res, err := sess.sendMarshaled(reqb, resb)

		if nil != err {
			fmt.Printf("[nsm, Read] error1: %v\n", err)
			return i, err
		}

		if "" != res.Error || nil == res.GetRandom || nil == res.GetRandom.Random || 0 == len(res.GetRandom.Random) {
			fmt.Printf("[nsm, Read] error2: %v\n", res.Error)
			return i, &ErrorGetRandomFailed{
				ErrorCode: res.Error,
			}
		}
		fmt.Printf("[nsm, Read] before copy(into[i:], res.GetRandom.Random): %v\n", into)
		i += copy(into[i:], res.GetRandom.Random)
		fmt.Printf("[nsm, Read] after copy(into[i:], res.GetRandom.Random): %v\n", into)
		j++
	}

	fmt.Printf("[nsm, Read] returning function with: %d\n", len(into))

	return len(into), nil
}
