import matlab.engine
eng = matlab.engine.start_matlab()
x = 10
eng.workspace['x'] = x
a = eng.eval('sqrt(x)')
print(a)
