#!/usr/bin/env python
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
    #im = pyoidn.run_oidn(im)

    # scale and convert to uint8
    im = (im*255).round().astype(np.uint8)

    # write out the result
    imageio.imwrite(outfile, im)

def main(argv):
    ifilename = argv[0]
    ofilename = argv[1]
    denoiseFile(ifilename, ofilename)

if __name__ == "__main__":
    args = sys.argv
    #help(pyoidn.run_oidn)
    if len(args) != 3:
        print("Usage: ", args[0], " inputfile outputfile")
    else:
        main(sys.argv[1:])
