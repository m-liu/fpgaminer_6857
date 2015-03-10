import json
import urllib
import urllib2
import hashlib
import struct
import binascii
import requests
import datetime
import sys

#group 29

groupNum = "29"
url_base = "http://6857coin.csail.mit.edu/"
genesis = "77a22709b4f6ad7c13c1a5c898cb63872ed00be3eadbd94e6b32482fe7518d51"

groupChain = "000000000037048ce0edbaa972a987d6fafaf191310b64cc3c38f28723b85b2c"

def getJson (reqType, blockHash=""):
	print "getting json"
	if reqType=="HEAD":
		url = url_base + "head"
	elif reqType=="NEXT":
		url = url_base + "next/" + blockHash
	elif reqType=="GENESIS":
		url = url_base + "block/" + genesis
	elif reqType=="BLOCK": 
		url = url_base + "block/" + blockHash
	else: 
		print "ERROR: getJson wrong request type"
	jsonurl = urllib.urlopen(url)
	return json.loads(jsonurl.read())

def andStr(xs, ys):
	ret = [x & y for x, y in zip(xs, ys)]
	return ret
	#return ''.join(chr(ord(a) ^ ord(b)) for a,b in zip(s1,s2))




def constructNewHash(jsonblk, jsonblkHeader, nonce):
	#prev hash is current header of jsonblk
	prevHash = jsonblkHeader
	contents = groupNum.encode('ascii')
	nonceEnc = struct.pack('>Q', nonce)
	newLen = jsonblk["Length"] + 1
	length = struct.pack('>I', newLen)
	finalHash = prevHash + contents + nonceEnc + length
	return finalHash

def getDifficulty(len):
	return int(len/100 + 24)

def checkHash(shaHash, difficulty):
	target_hex = '%064x' % (1<<(256-difficulty))
	target_str = target_hex.decode('hex')
	if (shaHash < target_str):
		return True
	else:
		return False

def sendPost(headblk, goldnonce):
	print "Sending POST to update chain"
	phash = getHeader(headblk)
	values = {"PrevHash": phash,
				"Contents": groupNum,
				"Nonce": goldnonce,
				"Length": headblk['Length']+1,
				}
	url = url_base + "add"
	print url
	print json.dumps(values)

	headers = {'content-type': 'application/json'}
	r = requests.post(url, data=json.dumps(values), headers=headers)
	print r.text
	

def getHeader(nblk):
	prevHash = nblk["PrevHash"].encode('ascii').decode('hex')
	print "prevHash:", binascii.hexlify(prevHash)
	contents = nblk["Contents"].encode('ascii')
	print "contents:", binascii.hexlify(contents)
	nonce_l = long(nblk["Nonce"])
	nonce_hex = '%016x' % nonce_l
	nonce = nonce_hex.decode('hex')
	print "nonce:", binascii.hexlify(nonce)
	length = struct.pack('>I', nblk["Length"])
	print "length:", binascii.hexlify(length), type(length)
	finalHash = prevHash + contents + nonce + length
	print binascii.hexlify(finalHash)
	sha = hashlib.sha256()
	sha.update(finalHash)
	digest = sha.hexdigest()
	print "Get header:", digest
	return digest




#nblk = getJson("NEXT", genesis)
nblk = getJson("BLOCK", groupChain)
print nblk
nblk_header = getHeader(nblk)
print "blkid=", nblk_header

print "------------------------"
print "MINING BEGINS!!"

#get head of blockchain

#blkhead = getJson("HEAD");
blkhead = getJson("BLOCK", groupChain)

blkheader = getHeader(blkhead).decode('hex')
prevblkheader = blkheader
print blkhead
diff = getDifficulty(blkhead["Length"]+1)
print "difficulty=", diff

sys.stdout.flush()

nonce=0
while nonce < 0x10000000000000000:
	#periodically update to see if any new blocks appeared
	if (nonce%0x1000000==0):
		print "getting new work, curr nonce=", nonce, " time=", datetime.datetime.now()

		blkhead = getJson("BLOCK", groupChain)
		#blkhead = getJson("HEAD")

		blkheader = getHeader(blkhead).decode('hex')
		if (blkheader!=prevblkheader):
			print "****GOT NEW WORK..ARGH*********"
			nonce = 0
			prevblkheader = blkheader
			print blkhead
			diff = getDifficulty(blkhead["Length"]+1)
			print "difficulty=", diff
		else: 
			print "no new work..whew"
		sys.stdout.flush()

	#construct new hash
	header = constructNewHash(blkhead, blkheader, nonce)
	#compute hash
	h = hashlib.sha256(header).digest()
	#print "Hash=", binascii.hexlify(h)

	#check if number of starting 0's match difficulty
	if (checkHash(h, diff)):
		print "Hash=", binascii.hexlify(h)
		print "SUCCESS!!! Nonce=", nonce
		sendPost(blkhead, nonce)
		break
	nonce+=1

