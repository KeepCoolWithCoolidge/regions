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
  globals, region_list, block_list

var chosen_region*: ptr region_node = nil

##  Forward declaration
proc round_to_block*(input: RSize): RSize

proc rinit*(region_name: cstring; region_size: RSize): bool =
  assert(not region_name.isNil)
  assert(not search_region(region_name))
  assert(region_size > 0'u16)
  var rounded_size: RSize
  var success: bool = false
  if not region_name.isNil and not search_region(region_name) and region_size > 0'u16:
    chosen_region = insert()
    assert(not chosen_region.isNil)
    if not chosen_region.isNil:
      rounded_size = round_to_block(region_size)
      chosen_region.name = cast[cstring](malloc(len(region_name).cint + 1))
      assert(not chosen_region.name.isNil)
      chosen_region.size = rounded_size
      chosen_region.bytes_used = 0
      chosen_region.data = malloc(rounded_size.cint)
      assert(not chosen_region.data.isNil)
      chosen_region.block_list = new_block_list()
      if not chosen_region.name.isNil and not chosen_region.data.isNil and
          not chosen_region.block_list.isNil:
        discard strcpy(chosen_region.name, region_name)
        assert(strcmp(region_name, chosen_region.name) == 0)
        success = true
      else:
        if not chosen_region.block_list.isNil:
          discard destroy_block_list(chosen_region.block_list)
          assert(chosen_region.block_list.isNil)
        free(chosen_region.name)
        free(chosen_region.data)
        free(chosen_region)
        chosen_region = nil
        assert(chosen_region.isNil)
  result = success

proc rchoose*(region_name: cstring): bool =
  assert(not region_name.isNil)
  var chosen_one: ptr region_node
  var success: bool = false
  if not region_name.isNil:
    chosen_one = return_region(region_name)
    if not chosen_one.isNil:
      chosen_region = chosen_one
      success = true
  result = success

proc rchosen*(): cstring =
  var chosen_name: cstring = nil
  if not chosen_region.isNil:
    assert(not chosen_region.name.isNil)
    if not chosen_region.name.isNil:
      chosen_name = chosen_region.name
      assert(strcmp(chosen_name, chosen_region.name) == 0)
  result = chosen_name

proc ralloc*(block_size: RSize): pointer =
  assert(block_size > 0'u16)
  assert(not chosen_region.isNil)
  assert(not chosen_region.block_list.isNil)
  assert(not chosen_region.data.isNil)
  var success: bool = block_size > 0'u16 and not chosen_region.isNil and
      not chosen_region.block_list.isNil and not chosen_region.data.isNil
  var new_block: ptr block_node = nil
  var block_data_start: pointer = nil
  var rounded_size: RSize = round_to_block(block_size)
  if success and
      rounded_size <= (chosen_region.size - chosen_region.bytes_used):
    new_block = add_block(rounded_size, chosen_region.block_list,
                        chosen_region.size, chosen_region.data)
    if not new_block.isNil:
      chosen_region.bytes_used += rounded_size
      block_data_start = new_block.block_start
  result = block_data_start

proc rsize*(block_ptr: pointer): RSize =
  assert(not chosen_region.isNil)
  var search_block: ptr block_node
  var block_size: RSize = 0
  if not block_ptr.isNil and not chosen_region.isNil:
    search_block = find_block(block_ptr, chosen_region.block_list)
    if not search_block.isNil:
      assert(search_block.size > 0'u16)
      if search_block.size > 0'u16:
        block_size = search_block.size
  result = block_size

proc rfree*(block_ptr: pointer): bool =
  assert(not block_ptr.isNil)
  assert(not chosen_region.isNil)
  var success: bool = false
  var current_region: ptr region_node
  var target: ptr block_node = nil
  var block_size: int
  if not chosen_region.isNil and not block_ptr.isNil:
    current_region = first_region()
    while not current_region.isNil and target.isNil:
      target = find_block(block_ptr, current_region.block_list)
      current_region = next_region()
    if not target.isNil:
      block_size = cast[cint](target.size)
    success = delete_block(target, chosen_region.block_list)
    if success:
      dec(chosen_region.bytes_used, block_size)
  result = success

proc rdestroy*(region_name: cstring) =
  assert(not region_name.isNil)
  var success: bool
  var target_region: ptr region_node
  if not region_name.isNil:
    target_region = return_region(region_name)
    if not target_region.isNil:
      success = strcmp(region_name, target_region.name) == 0
      if success:
        success = destroy_block_list(target_region.block_list)
        assert(success)
        if success:
          success = delete_region(region_name)
          assert(success)
          if success:
            if target_region == chosen_region:
              chosen_region = nil
              assert(chosen_region.isNil)
            target_region = nil
            assert(target_region.isNil)

proc rdump*() =
  var current_region: ptr region_node = first_region()
  var current_block: ptr block_node
  var percent: float32

  while not current_region.isNil:
    printf("REGION NAME: \x09%s\x0A", current_region.name)
    printf("SIZE (BYTES): \x09%d\x0A", current_region.size)
    printf("USED (BYTES): \x09%d\x0A", current_region.bytes_used)
    percent = ONE_HUNDRED - ONE_HUNDRED * cast[float32](current_region.bytes_used) / 
      cast[float32](current_region.size) 
    printf("FREE SPACE: \x09%.2f %%\x0A\x0A", percent)
    current_block = first_block(current_region.block_list)
    if not current_block.isNil:
      printf("\x09BLOCKS:\x0A\x0A")
    while not current_block.isNil:
      printf("\x09\x09%p\x0A", current_block.block_start)
      printf("\x09\x09%d bytes\x0A\x0A", current_block.size)
      current_block = current_block.next
    printf("\x0A")
    current_region = next_region()

proc round_to_block*(input: RSize): RSize =
  assert(input > 0'u16)
  var rounded: RSize = input
  if REGION_T_MAX < input:
    rounded = REGION_T_MAX
  elif input > 0'u16 and input mod BLOCK_ALIGNMENT != 0:
    rounded += BLOCK_ALIGNMENT - (input mod BLOCK_ALIGNMENT)
  assert(rounded mod BLOCK_ALIGNMENT == 0)
  result = rounded