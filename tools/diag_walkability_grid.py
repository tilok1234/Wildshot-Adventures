import base64
import json

p = r"C:\Users\headc\Documents\Wildshot-Adventures\assets\worldforge-packs\small-cold-coastal-pack-dusk"
w = json.load(open(p + r"\walkability.json"))
W, H = w["width"], w["height"]
raw = base64.b64decode(w["grid"])


def walkable(x, y):
    i = y * W + x
    return (raw[i // 8] >> (i % 8)) & 1


tmj = json.load(open(p + r"\resolved\resolved-map.tmj"))
layers = {L["name"]: L["data"] for L in tmj["layers"] if L.get("type") == "tilelayer"}

x0, y0, x1, y1 = 208, 126, 248, 148
print("legend: S=structure(solid) s=structure(WALKABLE) W=wall F=fence")
print("        p=props(solid) P=props(WALKABLE) o=overhang(solid) O=overhang(WALKABLE)")
print("        #=other-solid .=open-walkable   region", (x0, y0), "-", (x1, y1))
print("     " + "".join(str(x % 10) for x in range(x0, x1)))
for y in range(y0, y1):
    row = ""
    for x in range(x0, x1):
        idx = y * W + x
        wk = walkable(x, y)
        ch = "." if wk else "#"
        if layers["structures"][idx]:
            ch = "s" if wk else "S"
        elif layers["wall"][idx]:
            ch = "W"
        elif layers["fence"][idx]:
            ch = "F"
        elif layers["props-overhang"][idx]:
            ch = "O" if wk else "o"
        elif layers["props"][idx]:
            ch = "P" if wk else "p"
        row += ch
    print(f"{y:4d} {row}")
