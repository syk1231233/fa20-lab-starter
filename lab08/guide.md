ex1: vm and page
generate reference string(aim access address) -> memory
Progress:
    75 : reference address -> vitural address -> look up tlb
         tlb miss -> look up page table -> page table miss -> allocate a new page table item
         have invalidate page table item -> allocate page 0 frame to it from physical memory
