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

proc round_to_block*(input: region_size_t): region_size_t
proc rinit*(region_name: cstring; region_size: region_size_t): bool =
  assert(nil != region_name)
  assert(not search_region(region_name))
  assert(region_size > 0'u16)
  var rounded_size: region_size_t
  var success: bool = false

  if nil != region_name and not search_region(region_name) and region_size > 0'u16:
    chosen_region = insert()
    assert(nil != chosen_region)

    if nil != chosen_region:
      rounded_size = round_to_block(region_size)

      chosen_region.name = cast[cstring](alloc(len(region_name) + 1))
      assert(nil != chosen_region.name)

      chosen_region.size = rounded_size

      chosen_region.bytes_used = 0

      chosen_region.data = alloc(rounded_size)
      assert(nil != chosen_region.data)

      chosen_region.block_list = new_block_list()

      if nil != chosen_region.name and nil != chosen_region.data and
          nil != chosen_region.block_list:
        discard strcpy(chosen_region.name, region_name)
        assert(strcmp(region_name, chosen_region.name) == 0)
        success = true
      else:
        if nil != chosen_region.block_list:
          discard destroy_block_list(chosen_region.block_list)
          assert(nil == chosen_region.block_list)


        free(chosen_region.name)
        free(chosen_region.data)
        free(chosen_region)
        chosen_region = nil
        assert(nil == chosen_region)


  return success

proc rchoose*(region_name: cstring): bool =
  assert(nil != region_name)
  var chosen_one: ptr region_node
  var success: bool = false

  if nil != region_name:
    chosen_one = return_region(region_name)

    if nil != chosen_one:
      chosen_region = chosen_one
      success = true


  return success

proc rchosen*(): cstring =
  var chosen_name: cstring = nil

  if chosen_region != nil:
    assert(nil != chosen_region.name)

    if nil != chosen_region.name:
      chosen_name = chosen_region.name
      assert(strcmp(chosen_name, chosen_region.name) == 0)


  return chosen_name

proc ralloc*(block_size: region_size_t): pointer =
  assert(block_size > 0'u16)
  assert(nil != chosen_region)
  assert(nil != chosen_region.block_list)
  assert(nil != chosen_region.data)

  var success: bool = block_size > 0'u16 and nil != chosen_region and
      nil != chosen_region.block_list and nil != chosen_region.data

  var new_block: ptr block_node = nil
  var block_data_start: pointer = nil
  var rounded_size: region_size_t = round_to_block(block_size)

  if success and
      rounded_size <= (chosen_region.size - chosen_region.bytes_used):
    new_block = add_block(rounded_size, chosen_region.block_list,
                        chosen_region.size, chosen_region.data)

    if nil != new_block:
      chosen_region.bytes_used += rounded_size

      block_data_start = new_block.block_start


  return block_data_start

proc rsize*(block_ptr: pointer): region_size_t =
  assert(nil != chosen_region)
  var search_block: ptr block_node
  var block_size: region_size_t = 0

  if nil != block_ptr and nil != chosen_region:
    search_block = find_block(block_ptr, chosen_region.block_list)

    if nil != search_block:
      assert(search_block.size > 0'u16)

      if search_block.size > 0'u16:
        block_size = search_block.size


  return block_size

proc rfree*(block_ptr: pointer): bool =
  assert(nil != block_ptr)
  assert(nil != chosen_region)
  var success: bool = false
  var current_region: ptr region_node
  var target: ptr block_node = nil
  var block_size: cint

  if nil != chosen_region and nil != block_ptr:
    current_region = first_region()

    while nil != current_region and nil == target:
      target = find_block(block_ptr, current_region.block_list)
      current_region = next_region()


    if nil != target:
      block_size = cast[cint](target.size)


    success = delete_block(target, chosen_region.block_list)

    if success:
      dec(chosen_region.bytes_used, block_size)


  return success

proc rdestroy*(region_name: cstring) =
  assert(nil != region_name)
  var success: bool
  var target_region: ptr region_node

  if nil != region_name:
    target_region = return_region(region_name)

    if nil != target_region:
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
              assert(chosen_region == nil)


            target_region = nil
            assert(target_region == nil)

proc rdump*() =
  var current_region: ptr region_node = first_region()
  var current_block: ptr block_node
  var percent: cfloat

  while nil != current_region:
    printf("REGION NAME: \x09%s\x0A", current_region.name)
    printf("SIZE (BYTES): \x09%d\x0A", current_region.size)
    printf("USED (BYTES): \x09%d\x0A", current_region.bytes_used)

    percent = ONE_HUNDRED - ONE_HUNDRED * cast[cfloat](current_region.bytes_used) / 
      cast[cfloat](current_region.size) 

    printf("FREE SPACE: \x09%.2f %%\x0A\x0A", percent)

    current_block = first_block(current_region.block_list)

    if nil != current_block:
      printf("\x09BLOCKS:\x0A\x0A")


    while nil != current_block:
      printf("\x09\x09%p\x0A", current_block.block_start)
      printf("\x09\x09%d bytes\x0A\x0A", current_block.size)

      current_block = current_block.next


    printf("\x0A")

    current_region = next_region()

proc round_to_block*(input: region_size_t): region_size_t =
  assert(input > 0'u16)
  var rounded: region_size_t = input

  if REGION_T_MAX < input:
    rounded = REGION_T_MAX
  elif input > 0'u16 and input mod BLOCK_ALIGNMENT != 0:
    rounded += BLOCK_ALIGNMENT - (input mod BLOCK_ALIGNMENT)

  assert(rounded mod BLOCK_ALIGNMENT == 0)

  return rounded