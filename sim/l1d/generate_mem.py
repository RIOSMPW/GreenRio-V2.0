import os
PROJ_ROOT = os.environ["PROJ_ROOT"]
L1D_ROOT = os.environ["L1D_ROOT"]
L1D_SIM_ROOT = os.environ["L1D_SIM_ROOT"]
FAKE_MEM_WIDTH = 16
MEM_FILE_DIR = f"{PROJ_ROOT}/{L1D_SIM_ROOT}/mem"
PAGETABLE_FILE_DIR = f"{PROJ_ROOT}/{L1D_SIM_ROOT}/pagetable"

memfile = open(MEM_FILE_DIR, mode='w')
pagetable_file = open(PAGETABLE_FILE_DIR, mode='w')

PAGE_WIDTH = 12
PTE_WIDTH = 64 / 8
PTE_PER_PAGE = int((2 ** PAGE_WIDTH)/PTE_WIDTH)

SATP = 0x10000000
DATA_BASE_ADDR = 0x80000000
DATA_MAX_ADDR = 0x8000ffff
DATA_RANGE = DATA_MAX_ADDR - DATA_BASE_ADDR
PT_BASE_PPN = SATP >> 12
DATA_BASE_PPN = DATA_BASE_ADDR >> 12

class Pte:
    def __init__(self, ppn, vld, leaf):
        if(vld):
            self.N = 0
            self.PBMT = 0
            self.reserved = 0
            self.PPN = [0, 0, 0]
            self.PPN[2] = ppn >> 18
            self.PPN[1] = (ppn >> 9) & 0x1ff
            self.PPN[0] = ppn & 0x1ff
            self.RSW = 0
            self.D = 1
            self.A = 1
            self.G = 0
            self.U = 1
            self.X = 0
            self.W = 0
            self.R = 0
            if(leaf):
                self.X = 1
                self.W = 1
                self.R = 1
            self.V = 1
        else:
            self.N = 0
            self.PBMT = 0
            self.reserved = 0
            self.PPN = [0, 0, 0]
            self.RSW = 0
            self.D = 0
            self.A = 0
            self.G = 0
            self.U = 0
            self.X = 0
            self.W = 0
            self.R = 0
            self.V = 0

    
    def __str__(self) -> str:
        s = 0
        s += self.N << 63
        s += self.PBMT << 61
        s += self.reserved << 54 
        s += self.PPN[2] << 28
        s += self.PPN[1] << 19
        s += self.PPN[0] << 10
        s += self.RSW << 8
        s += self.D << 7
        s += self.A << 6
        s += self.G << 5
        s += self.U << 4
        s += self.X << 3
        s += self.W << 2
        s += self.R << 1
        s += self.V 
        return "{:016X}".format(s)

    def get_ppn(self):
        return ((self.PPN[2] << 18) + (self.PPN[1] << 9) + self.PPN[0]) 

class Page:
    def __init__(self, init_ppn, vld_num, auto_fill, leaf) -> None:
        self.pte_list = []
        assert(vld_num <= PTE_PER_PAGE)
        if(auto_fill):
            for i in range(0, vld_num):
                self.pte_list.append(Pte(init_ppn + i, True, leaf))
        
        
# # generate data mem
for i in range(0, 2 ** (FAKE_MEM_WIDTH - 2)):
    tmp = "{:08X}".format(i << 2)
    for j in range (0, 4):
        memfile.write(tmp[(3 - j) * 2 : (4 - j) * 2] + " ")

# # generate pagetable mem

l2_vld_pte_lower = (DATA_BASE_ADDR >> 12) >> 18
l2_vld_pte_upper = ((DATA_MAX_ADDR >> 12) >> 18) + 1
l2_vld_pte_num = l2_vld_pte_upper - l2_vld_pte_lower
l2_pte_num = l2_vld_pte_upper
l2_page_num = 1

l1_vld_pte_lower = ((DATA_BASE_ADDR >> 12) >> 9) & 0x1ff
l1_vld_pte_upper = (((DATA_MAX_ADDR >> 12) >> 9) & 0x1ff) + 1
l1_vld_pte_num = l1_vld_pte_upper - l1_vld_pte_lower
l1_pte_num = (l1_vld_pte_upper - l1_vld_pte_lower) * l2_vld_pte_num
l1_page_num = int(l1_pte_num // PTE_PER_PAGE + (1 if (l1_pte_num % PTE_PER_PAGE != 0) else 0))


l0_vld_pte_lower = (DATA_BASE_ADDR >> 12) & 0x1ff
l0_vld_pte_upper = ((DATA_MAX_ADDR >> 12) & 0x1ff) + 1
l0_vld_pte_num = l0_vld_pte_upper - l0_vld_pte_lower
l0_pte_num = (l0_vld_pte_upper - l0_vld_pte_lower) * l1_vld_pte_num
l0_page_num = int(l0_pte_num // PTE_PER_PAGE + (1 if (l0_pte_num % PTE_PER_PAGE != 0) else 0))

page_table = []

print(l2_page_num)
print(l2_pte_num)
print(l1_page_num)
print(l1_vld_pte_num)
print(l0_page_num)
print(l0_vld_pte_num)
print("====page table generate====")
# l2
for page_index in range(0, l2_page_num):
    pte_num = int(PTE_PER_PAGE if ((page_index + 1) * PTE_PER_PAGE < l2_pte_num) else (l2_pte_num % PTE_PER_PAGE))
    for i in range(0, l2_vld_pte_upper):
        if(i % PTE_PER_PAGE == 0) :
            page_table.append(Page(0, 0, 0, 0))
        if(i < l2_vld_pte_lower):
            page_table[-1].pte_list.append(Pte(0, False, False))
        else:
            page_table[-1].pte_list.append(Pte(PT_BASE_PPN + l2_vld_pte_num + i - l2_vld_pte_lower, True, False))

    
# l1
for page_index in range(0, l1_page_num):
    pte_num = (PTE_PER_PAGE if ((page_index + 1) * PTE_PER_PAGE < l1_pte_num) else (l1_pte_num % PTE_PER_PAGE))
    # page_table.append(Page(PT_BASE_PPN + l2_page_num + page_index * PTE_PER_PAGE, pte_num))
    for i in range(0, l1_vld_pte_upper):
        if(i % PTE_PER_PAGE == 0) :
            page_table.append(Page(0, 0, 0, 0))
        if(i < l1_vld_pte_lower):
            page_table[-1].pte_list.append(Pte(0, False, False))
        else:
            page_table[-1].pte_list.append(Pte(PT_BASE_PPN + l1_vld_pte_num + l2_vld_pte_num + i - l1_vld_pte_lower, True, False))



# l0
for page_index in range(0, l0_page_num):
    pte_num = (PTE_PER_PAGE if ((page_index + 1) * PTE_PER_PAGE < l0_pte_num) else (l0_pte_num % PTE_PER_PAGE))
    page_table.append(Page(DATA_BASE_PPN + page_index * PTE_PER_PAGE, pte_num, True, True))


print(len(page_table))
for i in range(0, len(page_table)):
    print("page: " + "{:05X}".format(PT_BASE_PPN + i))
    print(len(page_table[i].pte_list))
    for pte in page_table[i].pte_list:
        print("\tppn:" + "{:05X}".format(pte.get_ppn()) + (" (invalid)" if (pte.V == 0) else ""))
    print("\n")
print("====page table generate done====")

assert(len(page_table) <  2 ** (FAKE_MEM_WIDTH - 2))
for page in page_table:
    for pte in page.pte_list:
        tmp = str(pte)
        print(tmp)
        for j in range(0, 8):
            pagetable_file.write(tmp[(7 - j) * 2 : (8 - j) * 2] + " ")
            # pagetable_file.write(tmp[j * 2 : (j + 1) * 2] + "\n")
    print(f"auto fill {PTE_PER_PAGE - len(page.pte_list)} pte")
    for i in range(0, PTE_PER_PAGE - len(page.pte_list)):
        for j in range(0, 8):
            pagetable_file.write("00 ")

# for i in range(0, 2 ** (FAKE_MEM_WIDTH - 2) - (2 ** 12) * len(page_table)):
#     pagetable_file.write("00\n")
memfile.close()
pagetable_file.close()