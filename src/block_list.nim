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
  globals

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
proc new_block_list*(): pointer =
  var head: ptr block_node = cast[ptr block_node](alloc0(sizeof((block_node))))
  head.size = 0
  head.block_start = nil
  head.next = nil

  return head

proc add_block*(block_size: region_size_t; list_top: pointer;
               data_size: region_size_t; data_start: pointer): ptr block_node =
  assert(block_size mod BLOCK_ALIGNMENT == 0)
  assert(nil != list_top)
  assert(data_size > 0'u16)
  assert(nil != data_start)

  top = cast[ptr block_node](list_top)
  var new_block: ptr block_node = cast[ptr block_node](alloc0(sizeof((block_node))))
  assert(nil != new_block)
  var prev_block: ptr block_node

  var success: bool = block_size mod BLOCK_ALIGNMENT == 0 and nil != list_top and
      data_size > 0'u16 and nil != data_start and nil != new_block

  if success:
    new_block.size = block_size

    if nil == top.next:
      new_block.block_start = data_start
      new_block.next = top.next
      top.next = new_block
    else:
      new_block.block_start = first_fit(block_size, data_size, data_start)

      if nil != new_block.block_start:
        new_block.next = get_next_block(new_block.block_start)

        prev_block = get_prev_block(new_block.block_start)
        prev_block.next = new_block
      else:
        dealloc(new_block)
        new_block = nil
        assert(nil == new_block)


  return new_block

proc find_block*(block_start: pointer; list_top: pointer): ptr block_node =
  assert(nil != block_start)
  assert(nil != list_top)

  if nil != block_start and nil != list_top:
    traverse_block = cast[ptr block_node](list_top)

    while nil != traverse_block and block_start != traverse_block.block_start:
      traverse_block = traverse_block.next


  return traverse_block

proc delete_block*(target: var ptr block_node; list_top: pointer): bool =
  var success: bool = nil != target and nil != list_top
  var prev_block: ptr block_node

  if success:
    top = cast[ptr block_node](list_top)
    prev_block = get_prev_block(target.block_start)
    prev_block.next = target.next

    dealloc(target)
    target = nil
    success = nil == target
    assert(success)


  return success

proc destroy_block_list*(list_top: pointer): bool =
  assert(nil != list_top)
  top = cast[ptr block_node](list_top)
  var success: bool = false
  var prev_block: ptr block_node

  if nil != top:
    success = nil != top.next

    if success:
      prev_block = top.next
      traverse_block = prev_block.next

      prev_block.next = nil
      success = prev_block.next == nil
      assert(success)

      dealloc(prev_block)
      prev_block = nil
      top.next = nil
      success = prev_block == nil and top.next == nil
      assert(success)

      while nil != traverse_block:
        prev_block = traverse_block
        traverse_block = traverse_block.next

        prev_block.next = nil
        success = prev_block.next == nil
        assert(success)

        dealloc(prev_block)
        prev_block = nil
        assert(prev_block == nil)


      success = prev_block == nil and traverse_block == nil
      assert(success)

      if success:
        dealloc(top)
        top = nil
        success = top == nil
        assert(success)
    else:
      dealloc(top)
      top = nil
      success = top == nil
      assert(success)


  return success

proc first_fit*(block_size: region_size_t; data_size: region_size_t;
               data_start: pointer): pointer =
  assert(block_size mod BLOCK_ALIGNMENT == 0)
  assert(block_size > 0'u16)
  assert(data_size > 0'u16)
  assert(nil != data_start)

  traverse_block = top.next
  var prev_block: ptr block_node = top
  var block_start: pointer = nil
  var prev_size: cuint

  var success: bool = block_size mod BLOCK_ALIGNMENT == 0 and block_size > 0'u16 and
      data_size > 0'u16 and nil != data_start

  if success:
    prev_size = cast[cuint](data_start)

    while traverse_block != nil and
        (cast[cuint](traverse_block.block_start) - prev_size < block_size):
      prev_block = traverse_block
      traverse_block = traverse_block.next
      prev_size = cast[cuint](prev_block.block_start) +
          cast[cuint](prev_block.size)


    if prev_block.size == 0:
      block_start = data_start
    elif cast[cuint](data_size) - (prev_size - cast[cuint](data_start)) >= cast[cuint](block_size):
      block_start = cast[pointer](cast[cuint](prev_block.block_start) + prev_block.size)


  return block_start

proc first_block*(list_top: pointer): ptr block_node =
  top = cast[ptr block_node](list_top)
  var current_block: ptr block_node = nil

  if nil != list_top:
    current_block = top.next


  return current_block

proc get_next_block*(target: pointer): ptr block_node =
  assert(nil != target)

  if nil != target:
    traverse_block = top

    while nil != traverse_block and (traverse_block.block_start < target):
      traverse_block = traverse_block.next


  return traverse_block

proc get_prev_block*(target: pointer): ptr block_node =
  assert(nil != target)
  var prev: ptr block_node = nil

  if nil != target:
    traverse_block = top

    while nil != traverse_block and traverse_block.block_start < target:
      prev = traverse_block
      traverse_block = traverse_block.next


    assert(prev.block_start < target)


  return prev
