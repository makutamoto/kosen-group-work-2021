import json
from PIL import Image

# open bmp file and convert it to PIL image
def openImage(fileName):
    image = Image.open(fileName)
    return image

# Read json file and return a list of filepaths
# json contains a list of filepaths in the root
def readDefinitionJson(filename):
    with open(filename) as json_file:
        data = json.load(json_file)
    return data

# get a tilename from filepath and upper case it
def getTilename(filepath):
    tilename = filepath.split("/")[-1]
    tilename = tilename.split(".")[0]
    tilename = tilename.upper()
    return tilename

# Generate a tile from an image
# image: 6 x 6 PIL image
# tileName: name of the tile
# return: generated tile string
#
# the format of the tile is:
# TILE_{name}
# 		IMAGE_LOADER
# 		IMAGE	    {color name}, {color name}, {color name}, {color name}, {color name}, {color name}
# 		IMAGE	    {color name}, {color name}, {color name}, {color name}, {color name}, {color name}
# 		IMAGE	    {color name}, {color name}, {color name}, {color name}, {color name}, {color name}
# 		IMAGE	    {color name}, {color name}, {color name}, {color name}, {color name}, {color name}
# 		IMAGE	    {color name}, {color name}, {color name}, {color name}, {color name}, {color name}
# 		IMAGE	    {color name}, {color name}, {color name}, {color name}, {color name}, {color name}
# 
# the color names corresponding to color codes is:
# BLACK = 0
# DARKBLUE = 1
# DARKGREEN = 2
# DARKCYAN = 3
# DARKRED = 4
# DARKPURPLE = 5
# DARKYELLOW = 6
# LIGHTGREY = 7
# DARKGREY = 8
# BLUE = 9
# GREEN = 10
# CYAN = 11
# RED = 12
# PURPLE = 13
# YELLOW = 14
# WHITE = 15
def generateTile(image, tileName):
    label = "TILE_" + tileName
    tile = label + "\n"
    tile += "\t\tIMAGE_LOADER\t    {label}\n".format(label=label)
    for y in range(6):
        tile += "\t\tIMAGE\t    "
        for x in range(6):
            color = image.getpixel((x, y))
            color = (color & 0b1010) | ((color & 0b0100) >> 2) | ((color & 0b0001) << 2)
            if color == 0:
                tile += "BLACK, "
            elif color == 1:
                tile += "DARKBLUE, "
            elif color == 2:
                tile += "DARKGREEN, "
            elif color == 3:
                tile += "DARKCYAN, "
            elif color == 4:
                tile += "DARKRED, "
            elif color == 5:
                tile += "DARKPURPLE, "
            elif color == 6:
                tile += "DARKYELLOW, "
            elif color == 7:
                tile += "LIGHTGREY, "
            elif color == 8:
                tile += "DARKGREY, "
            elif color == 9:
                tile += "BLUE, "
            elif color == 10:
                tile += "GREEN, "
            elif color == 11:
                tile += "CYAN, "
            elif color == 12:
                tile += "RED, "
            elif color == 13:
                tile += "PURPLE, "
            elif color == 14:
                tile += "YELLOW, "
            elif color == 15:
                tile += "WHITE, "
        tile = tile[:-2]
        tile += "\n"
    return tile

# generate MPASM code that stores tile images
# address: start address string of tiles in the program memory (hex)
# filename: definition json file
# return: MPASM code string
# address is printed in the head of code as "\t\tORG H'{address}'"
def generateTileCode(address, filename):
    table = ""
    table += "\t\tORG H'{address}'\n".format(address=address)
    table += "TILE_TABLE\n"
    table += "\t\tADDWF\t    PCL, F\n"
    code = ""
    definitions = readDefinitionJson(filename)
    for filepath in definitions:
        tilename = getTilename(filepath)
        image = openImage(filepath)
        table += "\t\tGOTO\t    TILE_{tilename}\n".format(tilename=tilename)
        code += generateTile(image, tilename)
    for i in range(63 - len(definitions)):
        table += "\t\tRETURN\n"
    return table + code

# get necessary information from terminal and generate MPASM code and save it to a file
if __name__ == "__main__":
    import sys
    import argparse
    parser = argparse.ArgumentParser(description='Generate tiles from ping files')
    parser.add_argument('--address', type=str, help='start address of tiles in the program memory (hex)')
    parser.add_argument('--definition', type=str, help='definition json file')
    parser.add_argument('--output', type=str, help='output file')
    args = parser.parse_args()
    if args.address is None:
        print("Please specify the start address of tiles in the program memory")
        sys.exit(1)
    if args.definition is None:
        print("Please specify the definition json file")
        sys.exit(1)
    if args.output is None:
        print("Please specify the output file")
        sys.exit(1)
    with open(args.output, "w") as f:
        f.write(generateTileCode(args.address, args.definition))
