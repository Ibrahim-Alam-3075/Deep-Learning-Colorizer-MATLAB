# backend.py
import numpy as np
import cv2
import os
import sys

# 1. Get arguments from MATLAB (Input Path and Output Path)
if len(sys.argv) < 3:
    print("Error: Usage: python backend.py <input_path> <output_path>")
    sys.exit(1)

input_path = sys.argv[1]
output_path = sys.argv[2]

# 2. Setup Paths
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
PROTOTXT = os.path.join(CURRENT_DIR, "model", "colorization_deploy_v2.prototxt")
POINTS = os.path.join(CURRENT_DIR, "model", "pts_in_hull.npy")
MODEL = os.path.join(CURRENT_DIR, "model", "colorization_release_v2.caffemodel")

# 3. Load Model
net = cv2.dnn.readNetFromCaffe(PROTOTXT, MODEL)
pts = np.load(POINTS)

class8 = net.getLayerId("class8_ab")
conv8 = net.getLayerId("conv8_313_rh")
pts = pts.transpose().reshape(2, 313, 1, 1)
net.getLayer(class8).blobs = [pts.astype("float32")]
net.getLayer(conv8).blobs = [np.full([1, 313], 2.606, dtype="float32")]

# 4. Process Image
image = cv2.imread(input_path)
if image is None:
    print("Error: Could not read image")
    sys.exit(1)

scaled = image.astype("float32") / 255.0
lab = cv2.cvtColor(scaled, cv2.COLOR_BGR2LAB)

resized = cv2.resize(lab, (224, 224))
L = cv2.split(resized)[0]
L -= 50

net.setInput(cv2.dnn.blobFromImage(L))
ab = net.forward()[0, :, :, :].transpose((1, 2, 0))

ab = cv2.resize(ab, (image.shape[1], image.shape[0]))

L = cv2.split(lab)[0]
colorized = np.concatenate((L[:, :, np.newaxis], ab), axis=2)

colorized = cv2.cvtColor(colorized, cv2.COLOR_LAB2BGR)
colorized = np.clip(colorized, 0, 1)
colorized = (255 * colorized).astype("uint8")

# 5. Save the result for MATLAB to read
cv2.imwrite(output_path, colorized)
print("Success")