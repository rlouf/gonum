// Copyright ©2015 The gonum Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//
// Some of the loop unrolling code is copied from:
// http://golang.org/src/math/big/arith_amd64.s
// which is distributed under these terms:
//
// Copyright (c) 2012 The Go Authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

//+build !noasm,!appengine

#include "textflag.h"

// func DaxpyIncTo(dst []float64, incDst, idst uintptr, alpha float64, x, y []float64, n, incX, incY, ix, iy uintptr)
TEXT ·AxpyIncTo(SB), NOSPLIT, $0
	MOVQ   dst+0(FP), R10
	MOVQ   incDst+24(FP), R13
	MOVQ   idst+32(FP), BP
	MOVHPD alpha+40(FP), X7
	MOVLPD alpha+40(FP), X7
	MOVQ   x+48(FP), R8
	MOVQ   y+72(FP), R9
	MOVQ   n+96(FP), DX
	MOVQ   incX+104(FP), R11
	MOVQ   incY+112(FP), R12
	MOVQ   ix+120(FP), SI
	MOVQ   iy+128(FP), DI

	MOVQ SI, AX  // nextX = ix
	MOVQ DI, BX  // nextY = iy
	MOVQ BP, CX  // nextDst = idst
	ADDQ R11, AX // nextX += incX
	ADDQ R12, BX // nextY += incY
	ADDQ R13, CX // nextDst += incDst
	SHLQ $1, R11 // incX *= 2
	SHLQ $1, R12 // incY *= 2
	SHLQ $1, R13 // incDst *= 2

	SUBQ $2, DX // n -= 2
	JL   tail   // if n < 0

loop:  // n >= 0
	// dst[i] = alpha * x[i] + y[i] unrolled 2x.
	MOVHPD 0(R8)(SI*8), X0
	MOVHPD 0(R9)(DI*8), X1
	MOVLPD 0(R8)(AX*8), X0
	MOVLPD 0(R9)(BX*8), X1
	MULPD  X7, X0
	ADDPD  X0, X1
	MOVHPD X1, 0(R10)(BP*8)
	MOVLPD X1, 0(R10)(CX*8)

	ADDQ R11, SI // ix += incX
	ADDQ R12, DI // iy += incY
	ADDQ R13, BP // idst += incDst
	ADDQ R11, AX // nextX += incX
	ADDQ R12, BX // nextY += incY
	ADDQ R13, CX // nextDst += incDst

	SUBQ $2, DX // n -= 2
	JGE  loop   // if n >= 0 goto loop

tail:
	ADDQ $2, DX // n += 2
	JLE  end    // if n <= 0

	// dst[i] = alpha * x[i] + y[i] for the last iteration if n is odd.
	MOVSD 0(R8)(SI*8), X0
	MOVSD 0(R9)(DI*8), X1
	MULSD X7, X0
	ADDSD X0, X1
	MOVSD X1, 0(R10)(BP*8)

end:
	RET