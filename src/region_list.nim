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
  region_node* = object
    name*: cstring
    size*: RSize
    bytes_used*: RSize
    data*: pointer
    block_list*: ptr block_node
    next*: ptr region_node

##  Global variables
var top*: ptr region_node = nil
var traverse_region*: ptr region_node = nil

proc insert*(): ptr region_node =
  var new_region: ptr region_node = cast[ptr region_node](malloc(sizeof(region_node).cint))
  assert(not new_region.isNil)
  if not new_region.isNil:
    new_region.next = top
    top = new_region
  result = new_region

proc search_region*(target: cstring): bool =
  assert(not target.isNil)
  var found: bool = false
  var current_region: ptr region_node
  if not target.isNil:
    current_region = top
    while not current_region.isNil and not current_region.name.isNil and not found:
      if strcmp(target, current_region.name) == 0:
        assert(strcmp(target, current_region.name) == 0)
        found = true
      current_region = current_region.next
  result = found

proc delete_region*(target: cstring): bool =
  assert(not target.isNil)
  var success: bool
  var deleted: bool = false
  var current_region: ptr region_node
  var previous_region: ptr region_node
  if not target.isNil:
    current_region = top
    previous_region = nil
    success = not current_region.isNil and not current_region.name.isNil and
        not current_region.data.isNil
    assert(success)
    while success and strcmp(target, current_region.name) != 0:
      previous_region = current_region
      current_region = current_region.next
      success = not current_region.isNil and not current_region.name.isNil and
          not current_region.data.isNil
    if success and strcmp(target, current_region.name) == 0:
      if not previous_region.isNil:
        previous_region.next = current_region.next
      else:
        top = current_region.next
      free(current_region.name)
      current_region.name = nil
      success = current_region.name.isNil
      assert(success)
      free(current_region.data)
      current_region.data = nil
      success = success and current_region.data.isNil
      assert(success)
      free(current_region)
      current_region = nil
      success = success and current_region.isNil
      assert(success)
      if success:
        deleted = not search_region(target)
        assert(deleted)
  result = deleted

proc return_region*(target: cstring): ptr region_node =
  assert(not target.isNil)
  var current_region: ptr region_node
  var found: ptr region_node = nil
  if not target.isNil:
    current_region = top
    while not current_region.isNil and not current_region.name.isNil and found.isNil:
      if strcmp(target, current_region.name) == 0:
        assert(strcmp(target, current_region.name) == 0)
        found = current_region
        assert(not found.isNil)
      else:
        assert(strcmp(target, current_region.name) != 0)
        current_region = current_region.next
  result = found

proc first_region*(): ptr region_node =
  if not top.isNil:
    traverse_region = top
  else:
    traverse_region = nil
    assert(traverse_region.isNil)
  result = traverse_region

proc next_region*(): ptr region_node =
  if not traverse_region.isNil:
    traverse_region = traverse_region.next
  result = traverse_region