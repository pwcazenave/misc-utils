#!/usr/bin/env python
#
# Fix cases (capitalise first letter of each word) but leave
# certain words lowercase (e.g. of, a, the).
#
# Also removes underscores from file names.
#
# fixcase ./file1.txt ./filen.txt
#
# Pierre Cazenave 2012/05/12


from sys import argv
import os

for file in argv[1:]:

    lowerCount, upperCount, allCount, extraCount = 0, 0, 0, 0

    fileName, ext = os.path.splitext(file)

    baseDir = fileName.split('/')[:-1]

    fileEnd = fileName.split('/')[-1]
    fileEnd = fileEnd.replace('_', ' ')

    for character in fileEnd:
        if character.islower():
            lowerCount += 1
            allCount += 1
        elif character.isupper():
            upperCount += 1
            allCount += 1
        else:
            # Don't care about the other characters
            extraCount += 1
            pass

    if upperCount == 0 and lowerCount > 0:
    #if True:

        fixedCase = fileEnd.title()

        # Fix certain keywords
        keywords = [ 'and', 'the', 'of', 'a', 'an', 'it', 'if', 'is', 'in', 'at', 'for', 'to', 'from' ]
        for word in keywords:
            checkMe = ' ' + word.capitalize() + ' '
            if checkMe in fixedCase:
                # If the keyword follows a hyphen and a space, leave it be
                if '-' + checkMe in fixedCase:
                    pass
                else:
                    fixedCase = fixedCase.replace(word.capitalize(), word)
        
        # Fix possessive apostrophes
        if '\'S' in fixedCase:
            fixedCase = fixedCase.replace('\'S', '\'s')
        # Fix some contractions
        if '\'T' in fixedCase:
            fixedCase = fixedCase.replace('\'T', '\'t')

        newName = '/'.join(['/'.join(baseDir), fixedCase + ext])
        try:
            os.rename(file, newName)
            print 'Rename from %s to %s' % (file, newName)
        except:
            print 'Uh oh, something went wrong!'
    else:
        pass
        #print 'Not renaming'

