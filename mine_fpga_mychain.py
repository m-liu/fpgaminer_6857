import json
import urllib
import urllib2
import hashlib
import struct
import binascii
import requests
import datetime
import sys
import re
import subprocess
import os
import time


##############################
# Configuration parameters
##############################

groupNum = "29"
url_base = "http://6857coin.csail.mit.edu/"
afspath = '/afs/csail.mit.edu/u/m/ml/test/mine/mychain.txt'
genesis = "77a22709b4f6ad7c13c1a5c898cb63872ed00be3eadbd94e6b32482fe7518d51"
#chainPosition = "HEAD"
chainPosition = "AFS"
#chainPosition = "BLOCK"

#groupChain = "000000a5467ade7cb516dbff6411c664c3888ab98f205fe84b4ec19a90d13ab6"
specificBlk= "0000008e859f76b34c4ffe2b32e5f912a2f5dffaed2aa84cfaac61dcabdd74e3" #group 29
#groupChain = "00000000002fa56340caf894bf0c34b785c6b762d87a3e706998f337f36c013b" #split head at blk 1765
#groupChain =  "00000000003fba3ceb3b372a61470aed0b4db3262d43fddaf09367e92d40bded"
#specificBlk = "00000000007e48a67791c2ebcc480b69d1f6bd61116b203a526af6b8c6f971c8"

proc = 0


def getJson (reqType):
	global specificBlk, genesis
	print "getting json at ", reqType
	if reqType=="HEAD":
		url = url_base + "head"
		jsonurl = urllib.urlopen(url)
		jsonread = jsonurl.read()
	elif reqType=="NEXT":
		url = url_base + "next/" + specificBlk
		jsonurl = urllib.urlopen(url)
		jsonread = jsonurl.read()
	elif reqType=="GENESIS":
		url = url_base + "block/" + genesis
		jsonurl = urllib.urlopen(url)
		jsonread = jsonurl.read()
	elif reqType=="BLOCK": 
		url = url_base + "block/" + specificBlk
		jsonurl = urllib.urlopen(url)
		jsonread = jsonurl.read()
	elif reqType=="AFS":
		#send to afs too
		afsfile = open(afspath, 'r')
		jsonread = afsfile.readline()
		afsfile.close()
	else: 
		print "ERROR: getJson wrong request type"
	return json.loads(jsonread)

def andStr(xs, ys):
	ret = [x & y for x, y in zip(xs, ys)]
	return ret
	#return ''.join(chr(ord(a) ^ ord(b)) for a,b in zip(s1,s2))



def runProcess(exe):    
	global proc
	proc = subprocess.Popen(exe, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
	while(True):
		retcode = proc.poll() #returns None while subprocess is running
		line = proc.stdout.readline()
		yield line
		if(retcode is not None):
			break






def constructNewHash(jsonblk, jsonblkHeader, nonce):
	#prevHash = jsonblk["PrevHash"].encode('ascii').decode('hex')
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
	#check = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
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
	jsonraw = json.dumps(values)
	print jsonraw
	headers = {'content-type': 'application/json'}
	r = requests.post(url, data=jsonraw, headers=headers)
	print r.text
	#send to afs too
	afsfile = open(afspath, 'w')
	afsfile.write(jsonraw)
	afsfile.close()
	

def getHeader(nblk):
	prevHash = nblk["PrevHash"].encode('ascii').decode('hex')
	#print "prevHash:", binascii.hexlify(prevHash)
	contents = nblk["Contents"].encode('ascii')
	#print "contents:", binascii.hexlify(contents)
	nonce_l = long(nblk["Nonce"])
	nonce_hex = '%016x' % nonce_l
	nonce = nonce_hex.decode('hex')
	#print "nonce:", binascii.hexlify(nonce)
#nonce = struct.pack('>q', nblk["Nonce"])
#nonce = struct.pack('>q', nblk["Nonce"])
#print "nonce:", binascii.hexlify(nonce), type(nonce)
	length = struct.pack('>I', nblk["Length"])
	#print "length:", binascii.hexlify(length), type(length)
	finalHash = prevHash + contents + nonce + length
	#print binascii.hexlify(finalHash)
	sha = hashlib.sha256()
	sha.update(finalHash)
	digest = sha.hexdigest()
	#print "Get header:", digest
	return digest




#nblk = getJson("NEXT", genesis)
#nblk = getJson("BLOCK", groupChain)
#print nblk
#nblk_header = getHeader(nblk)
#print "blkid=", nblk_header

#print nblk["PrevHash"], type(nblk["PrevHash"])
#contents = bytes(nblk["Contents"])
#print bytes(prevHash)
print "------------------------"
print "MINING BEGINS!!"


#get head of blockchain

#stri="abc"
#print stri[0]

#solution: Nonce= 31033877

#for all nounces
#nonce=31000000
#nonce=1900323040
#nonce=9223372286203492004

nonce = 0
blkhead = getJson(chainPosition);
print "json blk=", blkhead
#blkhead = getJson("BLOCK", groupChain)
blkheader = getHeader(blkhead).decode('hex')
print "json blk header=", binascii.hexlify(blkheader)
prevblkheader = blkheader
diff = getDifficulty(blkhead["Length"]+1)
print "difficulty=", diff
sys.stdout.flush()

blksFound=0
while True:

	header = constructNewHash(blkhead, blkheader, 0)
	cmd = './ubuntu.exe ' + binascii.hexlify(header) + ' ' + str(diff)
	print "cmd=", cmd
	for line in runProcess(cmd.split()):
		print "UNBUNTU.EXE:", line,
		matchGold = re.match(r'gold nonce: ([0-9]*)', line, re.M|re.I)
		matchDebug = re.match(r'Debug', line, re.M|re.I)
		if (matchGold or matchDebug):
			if matchGold: 
				hwnonce = int(matchGold.group(1))
				print "##### GOLD NONCE FOUND!! HWnonce=", hwnonce
				#double check and send
				success=False
				for nonce in range(hwnonce-800, hwnonce):
					header = constructNewHash(blkhead, blkheader, nonce) #margin of error
					#compute hash
					h = hashlib.sha256(header).digest()
					#print "Hash=", binascii.hexlify(h)

					#check if number of starting 0's match difficulty
					if (checkHash(h, diff)):
						print "checking nonce =", nonce, " Header=", binascii.hexlify(header)
						print "Hash=", binascii.hexlify(h)
						print "SUCCESS!!! Nonce=", nonce
						sendPost(blkhead, nonce)
						blksFound = blksFound + 1
						print "Num blks found=", blksFound
						success=True
						break
				if (not success):
					print "***ERROR: HW gold nonce found but not verified!"
				sys.stdout.flush()
				time.sleep(3) #wait for server to update head

			#ask for new work
			print "getting new work time=", datetime.datetime.now()
			#blkhead = getJson("BLOCK", groupChain)
			blkhead = getJson(chainPosition)
			print "json blk=", blkhead
			blkheader = getHeader(blkhead).decode('hex')
			print "json blk header=", binascii.hexlify(blkheader)
			if (blkheader!=prevblkheader):
				print "****GOT NEW WORK..ARGH*********"
				print "PYTHON: killing process"
				proc.kill()
				prevblkheader = blkheader
				diff = getDifficulty(blkhead["Length"]+1)
				print "difficulty=", diff
				break
			else: 
				print "no new work..whew"
			print "Num blks found=", blksFound
			sys.stdout.flush()













#
#nonce=0
#while nonce < 0x10000000000000000:
#	#periodically update to see if any new blocks appeared
#	if (nonce%0x1000000==0):
#		print "getting new work, curr nonce=", nonce, " time=", datetime.datetime.now()
#
#		#blkhead = getJson("BLOCK", groupChain)
#		blkhead = getJson("HEAD")
#
#		blkheader = getHeader(blkhead).decode('hex')
#		if (blkheader!=prevblkheader):
#			print "****GOT NEW WORK..ARGH*********"
#			nonce = 0
#			prevblkheader = blkheader
#			print blkhead
#			diff = getDifficulty(blkhead["Length"]+1)
#			print "difficulty=", diff
#		else: 
#			print "no new work..whew"
#		sys.stdout.flush()
#
#	#construct new hash
#	header = constructNewHash(blkhead, blkheader, nonce)
#	#if (nonce>>8==0):
#	print "nonce =", nonce, " Header=", binascii.hexlify(header)
#	#compute hash
#	h = hashlib.sha256(header).digest()
#	print "Hash=", binascii.hexlify(h)
#
#	#check if number of starting 0's match difficulty
#	if (checkHash(h, diff)):
#		print "Hash=", binascii.hexlify(h)
#		print "SUCCESS!!! Nonce=", nonce
#		sendPost(blkhead, nonce)
#		break
#	nonce+=1




	
#new header: 0000000000086fb37f7d575a2ae929fb7200a3d96655b642e72beeea63acb38232390000000000000000000006ce
#block hash: 0000008e859f76b34c4ffe2b32e5f912a2f5dffaed2aa84cfaac61dcabdd74e3
