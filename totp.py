import hmac, base64, struct, hashlib, time, sys

secret = sys.argv[1]
key = base64.b32decode(secret, True)
msg = struct.pack(">Q", int(time.time())//30)
h = hmac.new(key, msg, hashlib.sha1).digest()
o = h[19] & 15
h = (struct.unpack(">I", h[o:o+4])[0] & 0x7fffffff) % 1000000
x = str(h)
while len(x) != 6:
    x += '0'

print(x)
