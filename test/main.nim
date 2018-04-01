import
  regions, block_list, globals

proc test_init*()
proc check*(result: bool)
proc test_typical_cases*()
proc test_edge_cases*()
proc test_special_cases*()
proc free_remaining_blocks*(blocks: openarray[pointer]): bool
proc print_results*()

var tests_failed*: int
var region_name*: cstring = cast[cstring](malloc(12))

proc main*() =
  test_init()
  test_typical_cases()
  test_edge_cases()
  test_special_cases()
  print_results()
  printf("\x0AEnd of Processing.\x0A")

proc test_init*() =
  printf("Initiating Test.\x0A")
  tests_failed = 0

proc check*(result: bool) =
  if result == false:
    inc(tests_failed)

proc test_typical_cases*() =
  var size: uint16 = 1_024
  var blocks: array[128, pointer]
  var i, j: uint16
  printf("\x0A====== Begin Testing Typical Cases ======\x0A")
  printf("\x0ANon-multiple-of-8 region size and ralloc size.\x0A")
  ##  non multiple of 8 region size and ralloc size (test rounding)
  check(rinit("Non 8", 1))
  blocks[0] = ralloc(1)
  check(rsize(blocks[0]) == 8)
  rdestroy("Non 8")
  check(rchosen().isNil)
  printf("\x0AMake several regions and rchoose() between them.\x0A")
  ##  Try choosing regions and chooisng after deleting regions
  check(rinit("Region A", 112))
  check(rinit("Region B", 136))
  check(rinit("Region C", 352))
  check(rchoose("Region A"))
  check(strcmp(rchosen(), "Region A") == 0)
  check(rchoose("Region C"))
  check(strcmp(rchosen(), "Region C") == 0)
  rdestroy("Region A")
  check(rchoose("Region B"))
  check(strcmp(rchosen(), "Region B") == 0)
  rdestroy("Region B")
  rdestroy("Region C")
  check(rchosen().isNil)
  printf("\x0AMake a typical region and fill with 8 byte blocks\x0A")
  ##  Make 1 typical region
  check(rinit("Typical 1", size))
  check(strcmp(rchosen(), "Typical 1") == 0)
  ##  Fill region with 8 byte blocks
  i = 0
  while i < size div 8:
    blocks[i] = ralloc(1)
    check(not blocks[i].isNil)
    check(rsize(blocks[i]) == 8)
    inc(i)
  printf("\x0ATry to add to a full region.\x0A")
  ##  Try to add to a full region
  check(ralloc(1).isNil)
  printf("\x0ADelete two blocks in the middle and make a 16 byte block.\x0A")
  ##  Delete two blocks in middle, and make 16 byte block
  check(rfree(blocks[63]))
  check(rsize(blocks[63]) == 0)
  check(rfree(blocks[64]))
  check(rsize(blocks[64]) == 0)
  blocks[63] = ralloc(16)
  check(rsize(blocks[63]) == 16)
  printf("\x0ADelete a block so the region has 8 bytes free, and try to add a block of size 16 (should fail).\x0A")
  ##  Delete a block so the region has 8 bytes free
  ##  and try to add a block of size 16 (should fail)
  check(rfree(blocks[65]))
  check(rsize(blocks[65]) == 0)
  check(ralloc(16).isNil)
  printf("\x0AFree the remaining blocks in the region.\x0A")
  ##  Free the remaining blocks in the region
  check(free_remaining_blocks(blocks))
  printf("\x0ADestroy the region and check that the chosen region is set to NULL.\x0A")
  ##  Destroy region and check that chosen region
  ##  is set to NULL
  rdestroy("Typical 1")
  check(rchosen().isNil)
  printf("\x0AInitialize 10 regions with different sizes, choose each region in turn, then fill all regions with 8 byte blocks, then delete all regions.\x0A")
  ##  Initialize 10 regions with different sizes
  i = 0
  while i < 10:
    discard sprintf(region_name, "Region %d", i)
    check(rinit(region_name, size * (i + 1)))
    check(strcmp(rchosen(), region_name) == 0)
    inc(i)
  ##  Choose each region in turn
  i = 0
  while i < 10:
    discard sprintf(region_name, "Region %d", i)
    check(rchoose(region_name))
    check(strcmp(rchosen(), region_name) == 0)
    inc(i)
  ##  Fill all regions with 8 byte blocks
  i = 0
  while i < 10:
    discard sprintf(region_name, "Region %d", i)
    check(rchoose(region_name))
    j = 0
    while j < size div 8:
      discard ralloc(1)
      inc(j)
    inc(i)
  ##  Destroy each region
  i = 0
  while i < 10:
    discard sprintf(region_name, "Region %d", i)
    check(rchoose(region_name))
    rdestroy(region_name)
    check(not rchoose(region_name))
    check(rchosen().isNil)
    inc(i)
  printf("\x0ATest the first fit algorithm.\x0A")
  ##  Test first_fit
  check(rinit("Simple Region", 512))
  check(strcmp(rchosen(), "Simple Region") == 0)
  blocks[0] = ralloc(128)
  blocks[1] = ralloc(256)
  blocks[2] = ralloc(128)
  ##  Region is now full
  check(rsize(blocks[0]) == 128)
  check(rsize(blocks[1]) == 256)
  check(rsize(blocks[2]) == 128)
  check(not (ralloc(1) != nil))
  ##  Not enough space
  check(rfree(blocks[1]))
  ##  Free up 256 bytes
  blocks[1] = ralloc(1)
  ##  Inserted right after block 0
  check(rsize(blocks[1]) == 8)
  check(not (ralloc(256) != nil))
  ##  Not enough contiguous space
  blocks[3] = ralloc(8)
  ##  Inserted after block 1
  check(rsize(blocks[3]) == 8)
  blocks[4] = ralloc(240)
  ##  Inserted right after block 3
  check(rsize(blocks[4]) == 240)
  check(not (ralloc(1) != nil))
  ##  Region is full
  check(rfree(blocks[0]))
  ##  Free 128 bytes at beginning
  check(rfree(blocks[2]))
  ##  Free 128 bytes at end
  blocks[0] = ralloc(32)
  ##  Insert 32 bytes at beginning of region
  check(rsize(blocks[0]) == 32)
  blocks[2] = ralloc(112)
  ##  Insert 112 bytes after block 4
  check(rsize(blocks[2]) == 112)
  blocks[5] = ralloc(88)
  ##  Insert 88 bytes after block 0
  check(rsize(blocks[5]) == 88)
  blocks[6] = ralloc(16)
  ##  Insert 16 bytes after block 2
  check(rsize(blocks[6]) == 16)
  blocks[7] = ralloc(1)
  ##  Insert 8 bytes after block 5
  check(rsize(blocks[1]) == 8)
  check(not (ralloc(1) != nil))
  ##  Region is full
  rdestroy("Simple Region")

proc test_edge_cases*() =
  var i, j: uint16
  var blocks: array[8191, pointer]
  var point: ptr block_node
  printf("\x0A====== Begin Testing Edge Cases. ======\x0A")
  printf("\x0ATest rinit edge cases.\x0A")
  ##  rinit edge cases
  check(rinit("", 1))
  check(strcmp(rchosen(), "") == 0)
  rdestroy("")
  check(rchosen().isNil)
  check(rinit("Negative", cast[uint16](-300)))
  check(strcmp(rchosen(), "Negative") == 0)
  rdestroy("Negative")
  check(rchosen().isNil)
  check(rinit("This is an extremely long string, or at the very least, quite long indeed!",
              1))
  check(strcmp(rchosen(), "This is an extremely long string, or at the very least, quite long indeed!") ==
      0)
  rdestroy("This is an extremely long string, or at the very least, quite long indeed!")
  check(rchosen().isNil)
  printf("\x0ATry to use rchoose() when no region exists.\x0A")
  ##  rchoose when no regions exist
  check(not rchoose("Does not exist"))
  printf("\x0ARun rinit(-1), resulting in a max size of short (65535), then ralloc(-1) to fill the entire region with a huge block.\x0A")
  ##  rinit(-1), resulting in max size of short (65535)
  ##  and ralloc the entire size of the region with ralloc(-1)
  check(rinit("Foo", cast[uint16](-1)))
  check(strcmp(rchosen(), "Foo") == 0)
  point = cast[ptr block_node](ralloc(cast[uint16](-1)))
  check(not point.isNil)
  check(rsize(point) == REGION_T_MAX)
  rdestroy("Foo")
  check(rchosen().isNil)
  printf("\x0ARalloc with max size (e.g. ralloc(-1)) in a much smaller region.\x0A")
  ##  Ralloc with max size in smaller region
  check(rinit("Bar", 128))
  check(strcmp(rchosen(), "Bar") == 0)
  check(ralloc(cast[uint16](-1)).isNil)
  ##  much too large for region
  rdestroy("Bar")
  check(rchosen().isNil)
  printf("\x0ACreate 10 regions of max size (65528 bytes) and fill them with 8 byte blocks.\x0A")
  ##  Create 10 regions of max size
  ##  and fill them with 8 byte blocks
  i = 0
  while i < 10:
    discard sprintf(region_name, "Region %d", i)
    check(rinit(region_name, cast[uint16](-1)))
    check(strcmp(rchosen(), region_name) == 0)
    j = 0
    while j < REGION_T_MAX div 8:
      check(not ralloc(1).isNil)
      inc(j)
    inc(i)
  printf("\x0Archoose() all regions, thus including beginning and end regions (extremes). Then destroy all regions.\x0A")
  ##  rchoose all regions, thus including beginning
  ##  and end regions
  i = 0
  while i < 10:
    discard sprintf(region_name, "Region %d", i)
    check(rchoose(region_name))
    inc(i)
  ##  destroy all regions
  i = 0
  while i < 10:
    discard sprintf(region_name, "Region %d", i)
    rdestroy(region_name)
    inc(i)
  check(rchosen().isNil)
  printf("\x0AMake 10,000 tiny (8 byte) regions, rchoose all regions from beginning to end, then destroy all 10,000 regions.\x0A")
  ##  Make 10,000 tiny regions
  i = 0
  while i < 10000:
    discard sprintf(region_name, "Region %d", i)
    check(rinit(region_name, 1))
    inc(i)
  ##  rchoose all regions, thus including beginning
  ##  and end regions
  i = 0
  while i < 10:
    discard sprintf(region_name, "Region %d", i)
    check(rchoose(region_name))
    inc(i)
  ##  destroy all 10,000 regions
  i = 0
  while i < 10000:
    discard sprintf(region_name, "Region %d", i)
    rdestroy(region_name)
    inc(i)
  check(rchosen().isNil)
  printf("\x0ACreate one max size (66528 byte) region and fill it with 8 byte blocks, then rfree the blocks manually.\x0A")
  ##  Create one max size region and fill with
  ##  8 byte blocks, and rfree the blocks manually
  check(rinit("rfree test", cast[uint16](-1)))
  i = 0
  while i < REGION_T_MAX div 8:
    blocks[i] = ralloc(1)
    check(rsize(blocks[i]) == 8)
    inc(i)
  i = 0
  while i < REGION_T_MAX div 8:
    check(rfree(blocks[i]))
    inc(i)
  rdestroy("rfree test")
  check(rchosen().isNil)
  printf("\x0ATry destroying a non-existent region.\x0A")
  ##  Destroy non-existent region
  rdestroy("FooBar")
  printf("\x0ACreate an empty region, rchoose() it then rdestroy() it.\x0A")
  check(rinit("Baz", 12))
  check(rchoose("Baz"))
  check(strcmp(rchosen(), "Baz") == 0)
  rdestroy("Baz")
  check(rchosen().isNil)
  printf("\x0ACreate a full region, rchoose() it then rdestroy() it.\x0A")
  check(rinit("Qud", 1024))
  check(not ralloc(128).isNil)
  check(not ralloc(128).isNil)
  check(not ralloc(128).isNil)
  check(not ralloc(128).isNil)
  check(not ralloc(512).isNil)
  check(ralloc(1).isNil)
  ##  Region is full
  check(rchoose("Qud"))
  check(strcmp(rchosen(), "Qud") == 0)
  rdestroy("Qud")
  check(rchosen().isNil)

proc test_special_cases*() =
  when defined(NDEBUG):
    printf("\x0A====== Begin Testing Special Cases. ======\x0A")
    printf("\x0ARunning DNDEBUG only tests.\x0A")
    printf("\x0ACreate a duplicate region.\x0A")
    ##  create duplicate region
    check(rinit("Dupe", 16))
    check(not rinit("Dupe", 16))
    rdestroy("Dupe")
    printf("\x0ASend abusive parameters to functions (would normally trip assertions).\x0A")
    ##  Send abusive parameters to functions
    check(not rinit(nil, 1))
    check(not rinit(nil, 0))
    check(not rinit("Foo", 0))
    check(not rchoose(nil))
    check(ralloc(0).isNil)
    check(rsize(nil) == 0)
    check(not rfree(nil))
    rdestroy(nil)
    printf("\x0ATry ralloc(1) when no region exists.\x0A")
    ##  Chosen region is NIL. Try:
    check(rchosen().isNil)
    check(ralloc(1).isNil)
  printf("\x0Ardump: (should print nothing)\x0A")
  rdump()
  ##  Should print nothing
  free(region_name)

proc free_remaining_blocks*(blocks: openarray[pointer]): bool =
  var success: bool = true
  for a_block in blocks:
    if rsize(a_block) > 0'u16:
      check(rfree(a_block))
      if rsize(a_block) != 0'u16:
        success = false
  result = success

proc print_results*() =
  printf("\x0ATests Failed: %d\x0A", tests_failed)

main()