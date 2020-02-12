file = 'DontGo80003'

f = open(f'{file}.raw', 'rb').read()
out = open('un4d', 'wb')
for byte in f:
    out.write(bytes([byte >> 4, byte & 0b1111]))
out.close()
f.close()
