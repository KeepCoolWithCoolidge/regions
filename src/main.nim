import
  regions, block_list, globals, strutils

proc test_init*()
proc check*(result: bool)
proc test_typical_cases*()
proc test_edge_cases*()
proc test_special_cases*()
proc free_remaining_blocks*(blocks: openarray[pointer]): bool
proc print_results*()
var tests_failed*: cint

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
    printf("Failure\n")
    inc(tests_failed)

proc test_typical_cases*() =
  var size: uint16 = 1_024
  var blocks: array[128, pointer]
  var `ptr`: ptr block_node
  var location: cushort
  var i: uint16
  var j: uint16

  printf("\x0A====== Begin Testing Typical Cases ======\x0A")

  printf("\x0ANon-multiple-of-8 region size and ralloc size.\x0A")


  ##  non multiple of 8 region size and ralloc size (test rounding)
  check(rinit("Non 8", 1))
  blocks[0] = ralloc(1)
  check(rsize(blocks[0]) == 8)

  rdestroy("Non 8")
  check(rchosen() == nil)

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

  check(rchosen() == nil)

  printf("\x0AMake a typical region and fill with 8 byte blocks\x0A")


  ##  Make 1 typical region
  check(rinit("Typical 1", size))
  check(strcmp(rchosen(), "Typical 1") == 0)


  ##  Fill region with 8 byte blocks
  i = 0
  while i < size div 8:
    blocks[i] = ralloc(1)
    check(nil != blocks[i])
    check(rsize(blocks[i]) == 8)
    inc(i)


  printf("\x0ATry to add to a full region.\x0A")


  ##  Try to add to a full region
  check(ralloc(1) == nil)

  printf("\x0ADelete two blocks in the middle and make a 16 byte block.\x0A")


  ##  Delete two blocks in middle, and make 16 byte block
  check(rfree(blocks[63]))
  check(rsize(blocks[63]) == 0)
  printf("Should be: %d; Is: %d\n", 0, rsize(blocks[63]))
  check(rfree(blocks[64]))
  check(rsize(blocks[64]) == 0)
  printf("Should be: %d; Is: %d\n", 0, rsize(blocks[64]))

  blocks[63] = ralloc(16)
  check(rsize(blocks[63]) == 16)
  printf("Should be: %d; Is: %d\n", 16, rsize(blocks[63]))

  printf("\x0ADelete a block so the region has 8 bytes free, and try to add a block of size 16 (should fail).\x0A")


  ##  Delete a block so the region has 8 bytes free
  ##  and try to add a block of size 16 (should fail)
  check(rfree(blocks[65]))
  check(rsize(blocks[65]) == 0)

  check(ralloc(16) == nil)

  printf("\x0AFree the remaining blocks in the region.\x0A")


  ##  Free the remaining blocks in the region
  check(free_remaining_blocks(blocks))

  printf("\x0ADestroy the region and check that the chosen region is set to NULL.\x0A")


  ##  Destroy region and check that chosen region
  ##  is set to NULL
  rdestroy("Typical 1")
  check(rchosen() == nil)

  printf("\x0AInitialize 10 regions with different sizes, choose each region in turn, then fill all regions with 8 byte blocks, then delete all regions.\x0A")


  ##  Initialize 10 regions with different sizes
  i = 0
  while i < 10:
    check(rinit("Region $1" % $i, size * (i + 1)))
    check(strcmp(rchosen(), "Region $1" % $i) == 0)
    inc(i)


  ##  Choose each region in turn
  i = 0
  while i < 10:
    check(rchoose("Region $1" % $i))
    check(strcmp(rchosen(), "Region $1" % $i) == 0)
    inc(i)


  ##  Fill all regions with 8 byte blocks
  i = 0
  while i < 10:
    check(rchoose("Region $1" % $i))

    j = 0
    while j < size div 8:
      discard ralloc(1)
      inc(j)
    inc(i)


  ##  Destroy each region
  i = 0
  while i < 10:
    check(rchoose("Region $1" % $i))

    rdestroy("Region $1" % $i)
    check(not rchoose("Region $1" % $i))
    check(rchosen() == nil)
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
  printf("Should be: %d; Is: %d\n", 128, rsize(blocks[0]))
  check(rsize(blocks[1]) == 256)
  printf("Should be: %d; Is: %d\n", 256, rsize(blocks[1]))
  check(rsize(blocks[2]) == 128)
  printf("Should be: %d; Is: %d\n", 128, rsize(blocks[2]))

  check(not (ralloc(1) == nil))
  ##  Not enough space
  check(rfree(blocks[1]))
  ##  Free up 256 bytes
  blocks[1] = ralloc(1)
  ##  Inserted right after block 0
  check(rsize(blocks[1]) == 8)

  check(not (ralloc(256) == nil))
  ##  Not enough contiguous space
  blocks[3] = ralloc(8)
  ##  Inserted after block 1
  check(rsize(blocks[3]) == 8)
  printf("Should be: %d; Is: %d\n", 8, rsize(blocks[3]))

  blocks[4] = ralloc(240)
  ##  Inserted right after block 3
  check(rsize(blocks[4]) == 240)
  printf("Should be: %d; Is: %d\n", 240, rsize(blocks[4]))

  check((ralloc(1) == nil))
  ##  Region is full
  check(rfree(blocks[0]))
  ##  Free 128 bytes at beginning
  check(rfree(blocks[2]))
  ##  Free 128 bytes at end
  blocks[0] = ralloc(32)
  ##  Insert 32 bytes at beginning of region
  printf("Should be: %d; Is: %d\n", 32, rsize(blocks[0]))
  check(rsize(blocks[0]) == 32)

  blocks[2] = ralloc(112)
  ##  Insert 112 bytes after block 4
  printf("Should be: %d; Is: %d\n", 112, rsize(blocks[2]))
  check(rsize(blocks[2]) == 112)

  blocks[5] = ralloc(88)
  ##  Insert 88 bytes after block 0
  printf("Should be: %d; Is: %d\n", 88, rsize(blocks[5]))
  check(rsize(blocks[5]) == 88)

  blocks[6] = ralloc(16)
  ##  Insert 16 bytes after block 2
  printf("Should be: %d; Is: %d\n", 16, rsize(blocks[6]))
  check(rsize(blocks[6]) == 16)

  blocks[7] = ralloc(1)
  ##  Insert 8 bytes after block 5
  printf("Should be: %d; Is: %d\n", 8, rsize(blocks[1]))
  check(rsize(blocks[1]) == 8)

  check(not (ralloc(1) == nil))
  ##  Region is full
  rdestroy("Simple Region")

  #[ printf("\x0ACheck to see if when a block is freed then another of the same size is created, that they have the same starting address in memory.\x0A")


  check(rinit("Quud", 256))
  check(ralloc(64) != nil)
  `ptr` = cast[ptr block_node](ralloc(64))
  check(nil != `ptr`)
  check(ralloc(128) != nil)

  location = cast[cushort](`ptr`.block_start)

  check(rfree(`ptr`))
  `ptr` = nil

  `ptr` = cast[ptr block_node](ralloc(64))
  check(nil != `ptr`)

  check(location == cast[cushort](`ptr`.block_start))

  rdestroy("Quud")
  check(rchosen() == nil) ]#

proc test_edge_cases*() =
  var i: cint
  var j: cint
  var blocks: array[8191, pointer]
  var `ptr`: ptr block_node

  printf("\x0A====== Begin Testing Edge Cases. ======\x0A")

  printf("\x0ATest rinit edge cases.\x0A")

  ##  rinit edge cases
  check(rinit("", 1))
  check(strcmp(rchosen(), "") == 0)
  rdestroy("")
  check(rchosen() == nil)

  check(rinit("Negative", cast[uint16](-300)))
  check(strcmp(rchosen(), "Negative") == 0)
  rdestroy("Negative")
  check(rchosen() == nil)

  check(rinit("This is an extremely long string, or at the very least, quite long indeed!",
              1))

  check(strcmp(rchosen(), "This is an extremely long string, or at the very least, quite long indeed!") ==
      0)

  rdestroy("This is an extremely long string, or at the very least, quite long indeed!")

  check(rchosen() == nil)

  printf("\x0ATry to use rchoose() when no region exists.\x0A")


  ##  rchoose when no regions exist
  check(not rchoose("Does not exist"))

  printf("\x0ARun rinit(-1), resulting in a max size of short (65535), then ralloc(-1) to fill the entire region with a huge block.\x0A")


  ##  rinit(-1), resulting in max size of short (65535)
  ##  and ralloc the entire size of the region with ralloc(-1)
  check(rinit("Foo", cast[uint16](-1)))
  check(strcmp(rchosen(), "Foo") == 0)
  `ptr` = cast[ptr block_node](ralloc(cast[uint16](-1)))
  check(`ptr` != nil)
  check(rsize(`ptr`) == 65528)

  rdestroy("Foo")
  check(rchosen() == nil)

  printf("\x0ARalloc with max size (e.g. ralloc(-1)) in a much smaller region.\x0A")


  ##  Ralloc with max size in smaller region
  check(rinit("Bar", 128))
  check(strcmp(rchosen(), "Bar") == 0)

  check(ralloc(cast[uint16](-1)) == nil)
  ##  much too large for region
  rdestroy("Bar")
  check(rchosen() == nil)

  printf("\x0ACreate 10 regions of max size (63328 bytes) and fill them with 8 byte blocks.\x0A")


  ##  Create 10 regions of max size
  ##  and fill them with 8 byte blocks
  i = 0
  while i < 10:
    check(rinit("Region $1" % $i, cast[uint16](-1)))
    check(strcmp(rchosen(), "Region $1" % $i) == 0)

    j = 0
    while j < 65528 div 8:
      check(ralloc(1) != nil)
      inc(j)
    inc(i)


  printf("\x0Archoose() all regions, thus including beginning and end regions (extremes). Then destroy all regions.\x0A")


  ##  rchoose all regions, thus including beginning
  ##  and end regions
  i = 0
  while i < 10:

    check(rchoose("Region $1" % $i))
    inc(i)


  ##  destroy all regions
  i = 0
  while i < 10:

    rdestroy("Region $1" % $i)
    inc(i)


  check(rchosen() == nil)

  printf("\x0AMake 10,000 tiny (8 byte) regions, rchoose all regions from beginning to end, then destroy all 10,000 regions.\x0A")


  ##  Make 10,000 tiny regions
  i = 0
  while i < 10000:

    check(rinit("Region $1" % $i, 1))
    inc(i)


  ##  rchoose all regions, thus including beginning
  ##  and end regions
  i = 0
  while i < 10:

    check(rchoose("Region $1" % $i))
    inc(i)


  ##  destroy all 10,000 regions
  i = 0
  while i < 10000:

    rdestroy("Region $1" % $i)
    inc(i)


  check(rchosen() == nil)

  printf("\x0ACreate one max size (66528 byte) region and fill it with 8 byte blocks, then rfree the blocks manually.\x0A")


  ##  Create one max size region and fill with
  ##  8 byte blocks, and rfree the blocks manually
  check(rinit("rfree test", cast[uint16](-1)))

  i = 0
  while i < 65528 div 8:
    blocks[i] = ralloc(1)
    check(rsize(blocks[i]) == 8)
    inc(i)


  i = 0
  while i < 65528 div 8:
    check(rfree(blocks[i]))
    inc(i)


  rdestroy("rfree test")
  check(rchosen() == nil)

  printf("\x0ATry destroying a non-existent region.\x0A")


  ##  Destroy non-existent region
  rdestroy("FooBar")

  printf("\x0ACreate an empty region, rchoose() it then rdestroy() it.\x0A")

  check(rinit("Baz", 12))
  check(rchoose("Baz"))
  check(strcmp(rchosen(), "Baz") == 0)
  rdestroy("Baz")
  check(rchosen() == nil)

  printf("\x0ACreate a full region, rchoose() it then rdestroy() it.\x0A")

  check(rinit("Qud", 1024))
  check(ralloc(128) != nil)
  check(ralloc(128) != nil)
  check(ralloc(128) != nil)
  check(ralloc(128) != nil)
  check(ralloc(512) != nil)
  check(ralloc(1) == nil)
  ##  Region is full
  check(rchoose("Qud"))
  check(strcmp(rchosen(), "Qud") == 0)
  rdestroy("Qud")
  check(rchosen() == nil)

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

    check(ralloc(0) == nil)

    check(rsize(nil) == 0)

    check(not rfree(nil))

    rdestroy(nil)

    printf("\x0ATry ralloc(1) when no region exists.\x0A")


    ##  Chosen region is NULL. Try:
    check(rchosen() == nil)
    check(ralloc(1) == nil)


  printf("\x0Ardump: (should print nothing)\x0A")

  rdump()
  ##  Should print nothing
  
proc free_remaining_blocks*(blocks: openarray[pointer]): bool =
  var i: cint = 1
  var success: bool = true

  for a_block in blocks:
    if rsize(a_block) > 0'u16:
      check(rfree(a_block))
      if rsize(a_block) != 0'u16:
        success = false
    
  return success

proc print_results*() =
  printf("\x0ATests Failed: %d\x0A", tests_failed)

main()