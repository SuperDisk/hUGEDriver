for i in range(16):
    print(hex(i), ':', sep='', end='')
    for x in range(25):
        print('-' if (x & i) else '_', end='')
    print()
    print()


# Pointless, but pretty neat:        
'''for i in range(100):
    print(hex(i), ':', sep='', end='')
    for x in range(100):
        print('$' if (x & i) else '.', end='')
    print()
'''
