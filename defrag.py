import sys
import subprocess
import os
'''
if __name__ == '__main__':
    argument = sys.argv
    del argument[0]
'''
'''
def read_file (filename, chunksize=4096):
    with open(sys.argv[1], "rb") as f:
        while True:
            chunk = f.read(chunksize)
'''

defragsize=128

frag_degree = open("frag_degree", "w+")
target_file = open(sys.argv[1],"rb+",0)


subprocess.check_call(["filefrag", "-v", sys.argv[1]], stdout=frag_degree)
frag_degree.seek(0)
frag_degree.readline()
line = frag_degree.readline()
filesize = line.split(' ')[5]
frag_degree.readline()


lines = frag_degree.readlines()


bufsize = 0
need = 0
for line in lines[:-1]:
    fragsize = int(line.split(':')[3])
    bufsize += fragsize * 4
    '''print(bufsize)'''
    if bufsize < defragsize:
        need = 1
        continue

    while bufsize >= defragsize:
        if need == 1:
            '''print(need)'''
            data = target_file.read(defragsize*1024)
            target_file.seek(-1*defragsize*1024,1)
            target_file.write(data)

            os.fsync(target_file.fileno())
            need = 0
            target_file.seek(-1*defragsize*1024,1)

        
        target_file.seek(defragsize*1024,1)
        bufsize -= defragsize

'''print(target_file.tell())'''
data = target_file.read(bufsize*1024)
target_file.seek(-1*bufsize*1024,1) 
target_file.write(data)


target_file.flush()
os.fsync(target_file.fileno())

target_file.close()
frag_degree.close()

