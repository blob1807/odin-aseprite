from PIL import Image
import os
import shutil
import subprocess as sp
from pathlib import Path


# Set to your Aseprite exe path, needed to make pngs via CLI interface https://www.aseprite.org/docs/cli/
ASE_PATH = 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\Aseprite\\Aseprite.exe'


UTIL_PATH = os.path.dirname(__file__)
TEST_PATH = os.path.dirname(UTIL_PATH)
PATHS = ["asefile", "aseprite", "blob", "community"]

SAVE_CMD = [ASE_PATH, "-b", "", "--save-as", "{title}-frame{frame}.png"]

def main():
    print("Basic Files")
    print("  Making PNG files")
    os.chdir(UTIL_PATH)

    for path in PATHS:
        print(f"    DIR {path}")
        os.makedirs(path, exist_ok=True)
        os.chdir(path)
        for p, _, files in Path(TEST_PATH, path).walk():
            for file in files:
                if not file.endswith((".aseprite", ".ase")):
                    continue
                shutil.copy2(Path(p, file), ".")
                SAVE_CMD[2] = file
                sp.run(SAVE_CMD)
                os.remove(file)
        os.chdir("..")
   
    print("  Making RAW files")
    os.chdir(UTIL_PATH)

    for path in PATHS:
        print(f"    DIR {path}")
        os.chdir(path)
        for p, _, files in Path().walk():
            for file in files:
                if not file.endswith(".png"):
                    continue
                im = Image.open(Path(p, file))
                with open(Path(file).stem + ".raw", "wb") as f:
                    f.write(im.convert("RGBA").tobytes())
                #os.remove(file)
        os.chdir("..")


    print("Sprite Sheets")
    print("  Making PNG & RAW files")
    print("    DIR blob")

    src = str(Path(TEST_PATH).joinpath("blob/marshmallow.aseprite"))

    commands: list[list[str]] = [
        [ # 16x1
            ASE_PATH,
            "-b", src,
            "--color-mode", "rgb",
            "--sheet", "marshmallow-sheet-16x1.png"
        ],
        [ # 16x1 + Trim
            ASE_PATH, 
            "-b", src, "--trim-sprite",  
            "--color-mode", "rgb",
            "--sheet", "marshmallow-sheet-16x1-Trim.png"
        ],
        [ # 4x4
            ASE_PATH, 
            "-b", src,
            "--sheet-columns", "4",  
            "--color-mode", "rgb",
            "--sheet", "marshmallow-sheet-4x4.png"
        ],
        [ # 4x4 + Trim
            ASE_PATH, 
            "-b", src, "--trim-sprite",
            "--color-mode", "rgb", 
            "--sheet-columns", "4", 
            "--sheet", "marshmallow-sheet-4x4-Trim.png"
        ],
    ]
    
    return

if __name__ == "__main__":
    main()

