##       Copyright (c) 2013, Ryan Lemieux
## 
##       Permission to use, copy, modify, and/or distribute this software for any purpose
##       with or without fee is hereby granted, provided that the above copyright notice
##       and this permission notice appear in all copies.
## 
##       THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD
##       TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN
##       NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
##       DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER
##       IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
##       CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

const
  BLOCK_ALIGNMENT* = 8'u16
  REGION_T_MAX* = 65_528'u16
  ONE_HUNDRED* = 100

type
  region_size_t* = cushort

proc strcmp*(str1: cstring, str2: cstring): cint {.importc, header:"<string.h>".}
proc strcpy*(dest: cstring, src: cstring): cstring {.importc, header:"<string.h>".}
proc printf*(fmt: cstring) {.varargs, importc, header:"<stdio.h>".}
proc sprintf*(buf: cstring, fmt: cstring): cint {.varargs, importc, header:"<string.h>".}
proc memset*(str: pointer, c: int, n: csize): pointer {.importc, header:"<string.h>".}
proc malloc*(size: cint): pointer {.importc, header:"<stdlib.h>".}
proc free*(point: pointer) {.importc, header:"<stdlib.h>".}
proc calloc*(nitems: csize, size: csize): pointer {.importc, header:"<stdlib.h>".}