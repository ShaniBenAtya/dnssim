import string
import random

def foo():
	f1 = open("benignNamesE2.txt", "w")

	for i in range(200):
            for j in range(50):
		reqBenign = 'b{}.home.lan.'.format(j)    
		f1.write("{} A\n".format(reqBenign))
	f1.close()

	f2 = open("attackerNamesE2.txt", "w")

	for j in range(200):
		for i in range(50):
			reqAttack = 'attack{}.home.lan.'.format(i)    
			f2.write("{} A\n".format(reqAttack))
	f2.close()

foo()
