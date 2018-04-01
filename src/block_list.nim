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

import
  globals, memory

##  Block node
type
  block_node* {.bycopy.} = object
    size*: region_size_t
    block_start*: pointer
    next*: ptr block_node

var top*: ptr block_node = nil

var traverse_block*: ptr block_node = nil

proc get_next_block*(target: pointer): ptr block_node
proc get_prev_block*(target: pointer): ptr block_node
proc first_fit*(block_size: region_size_t; data_size: region_size_t; data_start: pointer): pointer
proc new_block_list*(): ptr block_node =
  var head: ptr block_node = cast[ptr block_node](malloc(sizeof(block_node).cint))
  head[].size = 0
  head[].block_start = nil
  head[].next = nil

  return head

proc add_block*(block_size: region_size_t; list_top: ptr block_node;
               data_size: region_size_t; data_start: pointer): ptr block_node =
  assert(block_size mod BLOCK_ALIGNMENT == 0)
  assert(not list_top.isNil)
  assert(data_size > 0'u16)
  assert(not data_start.isNil)

  top = list_top
  var new_block: ptr block_node = cast[ptr block_node](malloc(sizeof(block_node).cint))
  assert(not new_block.isNil)
  var prev_block: ptr block_node

  var success: bool = block_size mod BLOCK_ALIGNMENT == 0 and not list_top.isNil and
      data_size > 0'u16 and not data_start.isNil and not new_block.isNil

  if success:
    new_block[].size = block_size

    if top[].next.isNil:
      new_block[].block_start = data_start
      new_block[].next = top[].next
      top[].next = new_block
    else:
      new_block[].block_start = first_fit(block_size, data_size, data_start)

      if not new_block[].block_start.isNil:
        new_block[].next = get_next_block(new_block[].block_start)

        prev_block = get_prev_block(new_block[].block_start)
        prev_block[].next = new_block
      else:
        free(new_block)
        assert(new_block.isNil)


  return new_block

proc find_block*(block_start: pointer; list_top: ptr block_node): ptr block_node =
  assert(not block_start.isNil)
  assert(not list_top.isNil)

  if not block_start.isNil and not list_top.isNil:
    traverse_block = list_top

    while not traverse_block.isNil and block_start != traverse_block[].block_start:
      traverse_block = traverse_block[].next


  return traverse_block

proc delete_block*(target: var ptr block_node; list_top: ptr block_node): bool =
  var success: bool = not target.isNil and not list_top.isNil
  var prev_block: ptr block_node

  if success:
    top = list_top
    prev_block = get_prev_block(target[].block_start)
    prev_block[].next = target[].next

    free(target)
    target = nil
    success = target.isNil
    assert(success)


  return success

proc destroy_block_list*(list_top: ptr block_node): bool =
  assert(not list_top.isNil)
  top = list_top
  var success: bool = false
  var prev_block: ptr block_node

  if not top.isNil:
    success = not top[].next.isNil

    if success:
      prev_block = top[].next
      traverse_block = prev_block[].next

      prev_block[].next = nil
      success = prev_block[].next.isNil
      assert(success)

      free(prev_block)
      prev_block = nil
      top[].next = nil
      success = prev_block.isNil and top[].next.isNil
      assert(success)

      while not traverse_block.isNil:
        prev_block = traverse_block
        traverse_block = traverse_block[].next

        prev_block[].next = nil
        success = prev_block[].next.isNil
        assert(success)

        free(prev_block)
        prev_block = nil
        assert(prev_block.isNil)


      success = prev_block.isNil and traverse_block.isNil
      assert(success)

      if success:
        free(top)
        top = nil
        success = top.isNil
        assert(success)
    else:
      free(top)
      top = nil
      success = top.isNil
      assert(success)


  return success

proc first_fit*(block_size: region_size_t; data_size: region_size_t;
               data_start: pointer): pointer =
  assert(block_size mod BLOCK_ALIGNMENT == 0)
  assert(block_size > 0'u16)
  assert(data_size > 0'u16)
  assert(not data_start.isNil)

  traverse_block = top[].next
  var prev_block: ptr block_node = top
  var block_start: pointer = nil
  var prev_size: uint32

  var success: bool = block_size mod BLOCK_ALIGNMENT == 0 and block_size > 0'u16 and
      data_size > 0'u16 and not data_start.isNil

  if success:
    prev_size = cast[uint32](data_start)

    while not traverse_block.isNil and (cast[uint32](traverse_block[].block_start) - prev_size) < block_size:
      prev_block = traverse_block
      traverse_block = traverse_block[].next
      prev_size = cast[uint32](prev_block[].block_start) + prev_block[].size


    if prev_block[].size == 0:
      block_start = data_start
    elif (data_size.uint32 - (prev_size - cast[uint32](data_start))) >= block_size.uint32:
      block_start = cast[pointer](cast[uint32](prev_block[].block_start) + prev_block[].size)


  return block_start

proc first_block*(list_top: ptr block_node): ptr block_node =
  top = list_top
  var current_block: ptr block_node = nil

  if not list_top.isNil:
    current_block = top[].next


  return current_block

proc get_next_block*(target: pointer): ptr block_node =
  assert(not target.isNil)

  if not target.isNil:
    traverse_block = top

    while not traverse_block.isNil and (cast[uint32](traverse_block[].block_start) < cast[uint32](target)):
      traverse_block = traverse_block[].next


  return traverse_block

proc get_prev_block*(target: pointer): ptr block_node =
  assert(not target.isNil)
  var prev: ptr block_node = nil

  if not target.isNil:
    traverse_block = top

    while not traverse_block.isNil and (cast[uint32](traverse_block[].block_start) < cast[uint32](target)):
      prev = traverse_block
      traverse_block = traverse_block[].next


    assert(cast[uint32](prev[].block_start) < cast[uint32](target))


  return prev
