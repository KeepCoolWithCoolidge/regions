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
  globals, block_list

##  Memory region node

type
  region_node* {.bycopy.} = object
    name*: cstring
    size*: region_size_t
    bytes_used*: region_size_t
    data*: pointer
    block_list*: ptr block_node
    next*: ptr region_node


var top*: ptr region_node = nil

var traverse_region*: ptr region_node = nil

proc insert*(): ptr region_node =
  var new_region: ptr region_node = cast[ptr region_node](alloc0(sizeof((region_node))))
  assert(nil != new_region)

  if nil != new_region:
    new_region.next = top
    top = new_region


  return new_region

proc search_region*(target: cstring): bool =
  assert(nil != target)

  var found: bool = false
  var current_region: ptr region_node

  if nil != target:
    current_region = top

    while nil != current_region and nil != current_region.name and not found:
      if strcmp(target, current_region.name) == 0:
        assert(strcmp(target, current_region.name) == 0)
        found = true


      current_region = current_region.next


  return found

proc delete_region*(target: cstring): bool =
  assert(nil != target)
  var success: bool
  var deleted: bool = false
  var current_region: ptr region_node
  var previous_region: ptr region_node

  if nil != target:
    current_region = top
    previous_region = nil

    success = nil != current_region and nil != current_region.name and
        nil != current_region.data

    assert(success)

    while success and strcmp(target, current_region.name) != 0:
      previous_region = current_region
      current_region = current_region.next

      success = nil != current_region and nil != current_region.name and
          nil != current_region.data


    if success and strcmp(target, current_region.name) == 0:
      if previous_region != nil:
        previous_region.next = current_region.next
      else:
        top = current_region.next


      dealloc(current_region.name)
      current_region.name = nil
      success = current_region.name == nil
      assert(success)

      dealloc(current_region.data)
      current_region.data = nil
      success = success and current_region.data == nil
      assert(success)

      dealloc(current_region)
      current_region = nil
      success = success and current_region == nil
      assert(success)

      if success:
        deleted = not search_region(target)
        assert(deleted)


  return deleted

proc return_region*(target: cstring): ptr region_node =
  assert(nil != target)
  var current_region: ptr region_node
  var found: ptr region_node = nil

  if nil != target:
    current_region = top

    while nil != current_region and nil != current_region.name and nil == found:
      if strcmp(target, current_region.name) == 0:
        assert(strcmp(target, current_region.name) == 0)
        found = current_region
        assert(nil != found)
      else:
        assert(strcmp(target, current_region.name) != 0)
        current_region = current_region.next


  return found

proc first_region*(): ptr region_node =
  if nil != top:
    traverse_region = top
  else:
    traverse_region = nil
    assert(traverse_region == nil)


  return traverse_region

proc next_region*(): ptr region_node =
  if nil != traverse_region:
    traverse_region = traverse_region.next


  return traverse_region
