import wave
import sys

def openWaveAndReadframes(filename):
    wav = wave.open(filename, 'rb')
    frames = wav.readframes(wav.getnframes())
    wav.close()
    return frames

def hex(data):
    return f"\t\tRETLW\t\tH'{data:02X}'" 

def main():
    if len(sys.argv) < 2:
        print("Usage: U8WaveConverter.py <filename>")
        return
    address = 0x20F
    filename = sys.argv[1]
    frames = openWaveAndReadframes(filename)
    for d in frames:
        if address == 0x800:
            print("\t\tORG\t\tH'800'")
        print(hex(d))
        address += 1
    print(hex(0))

if __name__ == "__main__":
    main()
