#!/usr/bin/env python

"""Script to test the python bindings to OIDN

This script allows the user to print to the console all columns in the
spreadsheet. It is assumed that the input file is some image file, normal or 
albedo is not used in this test. 

There is an alternate (commented out) function to convert an entire directory of image files. 
"""
import imageio
import pyoidn
import numpy as np
import sys
import glob
import os

def denoiseDir(idir, odir):
    files = glob.glob(idir+'/*.png')
    for f in files:
        # /idir/foo.png --> /odir/dfoo.png
        denoiseFile(f, odir+'/d'+os.path.basename(f))

def denoiseFile(infile, outfile):
    # read the image file (noisy)
    im = imageio.imread(infile)

    # remove alpha channel if any
    im = im[:,:,:3]

    # scale and convert to float32
    im = (im/255.0).astype(np.float32)

    #### run the denoiser ###
    im = pyoidn.run_oidn(im, None, None)

    # scale and convert to uint8
    im = (im*255).round().astype(np.uint8)

    # write out the result
    imageio.imwrite(outfile, im)

def main(argv):
    ifilename = argv[0]
    ofilename = argv[1]
    # denoise a single file
    denoiseFile(ifilename, ofilename)
    # denoise all files in the directory
    # denoiseDir(inputDirr, outputDir)

if __name__ == "__main__":
    args = sys.argv
    #help(pyoidn.run_oidn)
    if len(args) != 3:
        print("Usage: ", args[0], " inputfile outputfile")
    else:
        main(sys.argv[1:])
