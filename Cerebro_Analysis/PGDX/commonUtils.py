#!/usr/bin/env python
import os
import sys
import subprocess
import math
import csv
import collections
import re
from subprocess import Popen

class OrderedSet(collections.MutableSet):
	def __init__(self, iterable=None):
		self.end = end = []
		end += [None, end, end]		 # sentinel node for doubly linked list
		self.map = {}				   # key --> [key, prev, next]
		if iterable is not None:
			self |= iterable

	def __len__(self):
		return len(self.map)

	def __contains__(self, key):
		return key in self.map

	def add(self, key):
		if key not in self.map:
			end = self.end
			curr = end[1]
			curr[2] = end[1] = self.map[key] = [key, curr, end]

	def discard(self, key):
		if key in self.map:
			key, prev, next = self.map.pop(key)
			prev[2] = next
			next[1] = prev

	def __iter__(self):
		end = self.end
		curr = end[2]
		while curr is not end:
			yield curr[0]
			curr = curr[2]

	def __reversed__(self):
		end = self.end
		curr = end[1]
		while curr is not end:
			yield curr[0]
			curr = curr[1]

	def pop(self, last=True):
		if not self:
			raise KeyError('set is empty')
		key = self.end[1][0] if last else self.end[2][0]
		self.discard(key)
		return key

	def __repr__(self):
		if not self:
			return '%s()' % (self.__class__.__name__,)
		return '%s(%r)' % (self.__class__.__name__, list(self))

	def __eq__(self, other):
		if isinstance(other, OrderedSet):
			return len(self) == len(other) and list(self) == list(other)
		return set(self) == set(other)


def eprint(text):
	message = text
	sys.stderr.write(message + "\n")


def runCommand(command):
	"""
	Basic Implementation of Running Unix command through python
		Returns A List of items from stdout
	"""
	proc = Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
	complete = False
	while not complete:
		status = proc.poll()
		if status is None:
			continue

		elif status is not 0:
			eprint("A Fatal Error Has Occurred")
			raise Exception(proc.communicate()[1])

		if status is 0:
			out, err = proc.communicate()
			out = out.splitlines()
			return out


def getHeader(infile):
	"""
	Obtains a list of headers from a file
	:param infile: A file with headers
	:return: A list of headers
	"""
	with open (infile, 'U') as f:
		reader = csv.reader(f, delimiter='\t')
		header = next(reader)
		if len(header) > 0:
			return header
		else:
			message = "No Header Found in {0}".format(infile)
			# eprint(message)
			raise BaseException(eprint(message))


def getCUID(infile):
	"""
	Obtains a list of changeUIDs from a changes sheet. Assumes that CUIDs are always in the first column.
	:Assumptions
		The File Follows Typical Changes File format with CUID in index[0]
		The file is tab-separated
	:param infile: A Changes file
	:return: List of ChangeUIDs
	"""
	cuids = []
	with open(infile, 'U') as f:
		reader = csv.reader(f, delimiter='\t')
		# Skip the header
		header = next(reader)
		for row in reader:
			cuids.append(row[0])
	f.close()
	return cuids

import re

def natural_sort(l):
	convert = lambda text: int(text) if text.isdigit() else text.lower()
	alphanum_key = lambda key: [ convert(c) for c in re.split('([0-9]+)', key) ]
	return sorted(l, key = alphanum_key)